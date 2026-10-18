import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/provider/mixins/session/session.dart'
    show sessionNavigatorKey;
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _blue = Color(0xFF0071E3);
const _playUrl =
    "https://play.google.com/store/apps/details?id=com.wgghana.flexiphones";

/// The app's version, platform and anonymous device id, sent on every
/// request, plus the "please update" checks.
class AppInfo {
  static String version = "0.0.0";
  static String deviceId = "";

  static String get platform =>
      kIsWeb ? "web" : (Platform.isIOS ? "ios" : "android");

  /// Call once before runApp.
  static Future<void> load() async {
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    deviceId = await _deviceId();
  }

  /// A random id the app makes for itself (UUID v4), kept in encrypted
  /// storage. Never the IMEI, phone number or any hardware/advert id.
  static Future<String> _deviceId() async {
    const storage = FlutterSecureStorage();
    const key = "device_id";
    try {
      final saved = await storage.read(key: key);
      if (saved != null && saved.length >= 8) return saved;
    } catch (_) {}
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final id =
        "${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}";
    try {
      await storage.write(key: key, value: id);
    } catch (_) {}
    return id;
  }

  static Map<String, String> get headers => {
    "X-App-Version": version,
    "X-App-Platform": platform,
    if (deviceId.isNotEmpty) "X-Device-Id": deviceId,
  };
}

/// Adds the headers to every request and catches HTTP 426 (this version
/// is too old) anywhere in the app.
class AppHeadersInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.addAll(AppInfo.headers);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 426) AppUpdate.showBlocked(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 426) {
      AppUpdate.showBlocked(err.response?.data);
    }
    handler.next(err);
  }
}

class UpdateInfo {
  UpdateInfo({
    required this.title,
    required this.message,
    required this.whatsNew,
    required this.required,
    required this.available,
    required this.storeUrl,
  });

  final String title;
  final String message;
  final List<String> whatsNew;
  final bool required;
  final bool available;
  final String storeUrl;

  factory UpdateInfo.fromJson(Map json, {bool forceRequired = false}) {
    final req = forceRequired || json['update_required'] == true;
    final list = json['whats_new'];
    return UpdateInfo(
      title:
          (json['title'] ?? "").toString().trim().isNotEmpty
              ? json['title'].toString()
              : (req
                  ? "Please update FlexiPhones"
                  : "A new version of FlexiPhones is ready"),
      message:
          (json['message'] ?? "").toString().trim().isNotEmpty
              ? json['message'].toString()
              : "A new version of the FlexiPhones app is ready. Please update it to keep access to all features.",
      whatsNew:
          list is List
              ? list
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : const [],
      required: req,
      available: req || json['update_available'] == true,
      storeUrl:
          (json['store_url'] ?? "").toString().isNotEmpty
              ? json['store_url'].toString()
              : _playUrl,
    );
  }
}

class AppUpdate with WidgetsBindingObserver {
  AppUpdate._();
  static final AppUpdate _i = AppUpdate._();
  static final Dio _dio = Dio()..interceptors.add(AppHeadersInterceptor());
  static bool _showing = false;
  static bool _checking = false;

  /// Checks now and again whenever the app comes back to the foreground.
  static void start() {
    WidgetsBinding.instance.addObserver(_i);
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  /// GET /api/app-version (no sign-in needed).
  static Future<void> check() async {
    if (_checking || _showing) return;
    _checking = true;
    try {
      final r = await _dio.get(
        ApiUrls.appVersion,
        queryParameters: {
          "version": AppInfo.version,
          "platform": AppInfo.platform,
        },
        options: Options(
          headers: {"Accept": "application/json"},
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      debugPrint("=== [appVersion] ${r.statusCode}: ${r.data}");
      if (r.statusCode != 200 || r.data is! Map) return;
      final d = (r.data as Map)['data'];
      if (d is! Map) return;
      final info = UpdateInfo.fromJson(d);
      if (info.required) {
        await _open(info);
      } else if (info.available && await _notNaggedToday()) {
        await _open(info);
      }
    } catch (e) {
      debugPrint("!!! [appVersion] $e");
    } finally {
      _checking = false;
    }
  }

  /// A request came back 426: this version is blocked.
  static void showBlocked(dynamic body) {
    final m = body is Map ? body : const {};
    _open(UpdateInfo.fromJson(m, forceRequired: true));
  }

  /// "Optional update" is shown at most once a day.
  static Future<bool> _notNaggedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (prefs.getString("update_nag_day") == today) return false;
      await prefs.setString("update_nag_day", today);
    } catch (_) {}
    return true;
  }

  static Future<void> _open(UpdateInfo info) async {
    if (_showing) return;
    final nav = sessionNavigatorKey.currentState;
    if (nav == null) return;
    _showing = true;
    try {
      await nav.push(
        PageRouteBuilder(
          opaque: true,
          fullscreenDialog: true,
          pageBuilder: (_, __, ___) => UpdateScreen(info: info),
          transitionsBuilder:
              (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } finally {
      _showing = false;
    }
  }

  /// Opens the store page (or the given link).
  static Future<void> openStore([String? url]) async {
    final uri = Uri.parse((url ?? "").isNotEmpty ? url! : _playUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Full-screen "Update now". Can't be dismissed when the update is required.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, required this.info});
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !info.required,
      child: Scaffold(
        backgroundColor: ch.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E8BFF), Color(0xFF0057C2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withOpacity(0.35),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        info.title,
                        textAlign: TextAlign.center,
                        style: ptstyle(
                          size: 26,
                          weight: 800,
                          color: ch.onSurface,
                        ).copyWith(letterSpacing: -0.6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        info.message,
                        textAlign: TextAlign.center,
                        style: ptstyle(
                          size: 14,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      if (info.whatsNew.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ch.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "What's new",
                                style: ptstyle(
                                  size: 15,
                                  weight: 800,
                                  color: ch.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              for (final line in info.whatsNew)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          top: 2,
                                          right: 10,
                                        ),
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          size: 17,
                                          color: _blue,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          line,
                                          style: ptstyle(
                                            size: 13.5,
                                            weight: 500,
                                            color: ch.onSurface,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => AppUpdate.openStore(info.storeUrl),
                    child: Text(
                      "Update now",
                      style: ptstyle(
                        size: 16,
                        weight: 800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!info.required) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Not now",
                      style: ptstyle(
                        size: 14,
                        weight: 600,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
