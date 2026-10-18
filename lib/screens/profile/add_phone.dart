import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue = Color(0xFF0071E3);

/// "Add your phone number" after a Google/Apple sign-up. Advised, never
/// required: Skip just goes on (and is remembered so it isn't asked again).
class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key, required this.agent, this.advice});
  final bool agent;
  final String? advice;

  static String _skipKey(bool agent) => "phone_skipped_${agent ? "a" : "c"}";

  /// Opens it once after sign-up, unless they already skipped it.
  static Future<void> maybeOpen(
    BuildContext context, {
    required bool agent,
    String? advice,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_skipKey(agent)) == true) return;
    } catch (_) {}
    if (!context.mounted) return;
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => AddPhoneScreen(agent: agent, advice: advice),
      ),
    );
  }

  /// Opens it on purpose (banner, or a 422 that needs a phone).
  static Future<bool?> open(BuildContext context, {required bool agent}) =>
      Navigator.of(context).push<bool>(
        CupertinoPageRoute(builder: (_) => AddPhoneScreen(agent: agent)),
      );

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen> {
  final _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AddPhoneScreen._skipKey(widget.agent), true);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(false);
  }

  /// Ghana mobile number: 0 + 9 digits (0241234567), or 233 / +233 + 9
  /// digits. The first digit after the 0 / 233 is 2 to 5.
  static bool _valid(String raw) {
    final d = raw.replaceAll(RegExp(r"[^0-9+]"), "");
    return RegExp(r"^(0|\+?233)[2-5][0-9]{8}$").hasMatch(d);
  }

  String? get _hint {
    final t = _phone.text.trim();
    if (t.isEmpty) return null;
    final digits = t.replaceAll(RegExp(r"[^0-9]"), "");
    if (t.startsWith("0") && digits.length < 10) {
      return "${10 - digits.length} more digit${10 - digits.length == 1 ? "" : "s"}";
    }
    return _valid(t) ? null : "Enter a valid Ghana number, e.g. 0241234567";
  }

  Future<void> _save() async {
    final phone = _phone.text.trim();
    if (!_valid(phone) || _saving) return;
    FocusScope.of(context).unfocus();
    final p = Provider.of<SharedProvider>(context, listen: false);
    final token = widget.agent ? p.partnerData?.token : p.userData?.token;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final r = await p.dio.post(
        widget.agent
            ? ApiUrls.partnerProfileUpdate
            : ApiUrls.customerProfileUpdate,
        data: {"phone": phone},
        options: Options(
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
          validateStatus: (_) => true,
        ),
      );
      debugPrint("=== [addPhone] ${r.statusCode}: ${r.data}");
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200) {
        final d = body["data"];
        if (d is Map) await _store(p, Map<String, dynamic>.from(d));
        HapticFeedback.mediumImpact();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final errs = body["errors"];
      setState(
        () =>
            _error =
                errs is Map && errs["phone"] is List
                    ? "${(errs["phone"] as List).first}"
                    : "${body["message"] ?? "Couldn't save the number."}",
      );
    } catch (_) {
      setState(() => _error = "Check your internet connection and try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _store(SharedProvider p, Map<String, dynamic> data) async {
    if (widget.agent) return p.applyAgentProfile(data);
    try {
      final raw = await DS.storage.read(key: "user");
      if (raw == null) return;
      final saved = Map<String, dynamic>.from(jsonDecode(raw));
      final old =
          saved["data"] is Map
              ? Map<String, dynamic>.from(saved["data"])
              : <String, dynamic>{};
      saved["data"] = {...old, ...data};
      await DS.storage.write(key: "user", value: jsonEncode(saved));
      await p.getUserDetails();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final ready = _valid(_phone.text.trim());
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              "Skip for now",
              style: ptstyle(size: 14, weight: 600, color: ch.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_iphone_rounded,
                color: _blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Add your phone number",
              style: ptstyle(
                size: 24,
                weight: 700,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.6),
            ),
            const SizedBox(height: 8),
            Text(
              widget.advice ??
                  "Add your mobile phone number so we can reach you about your orders and payments. You can skip this and add it later in your profile.",
              style: ptstyle(
                size: 13.5,
                weight: 400,
                color: ch.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _error != null
                          ? const Color(0xFFE5484D)
                          : Colors.black.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                maxLength: 13,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9+]")),
                ],
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _save(),
                style: ptstyle(size: 17, weight: 600, color: ch.onSurface),
                decoration: InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  hintText: "0241234567",
                  prefixIcon: Icon(
                    Icons.call_rounded,
                    size: 20,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (_error == null && _hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _hint!,
                  style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _error!,
                  style: ptstyle(
                    size: 12.5,
                    weight: 600,
                    color: const Color(0xFFE5484D),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: _blue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: ready && !_saving ? _save : null,
                child:
                    _saving
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          "Save",
                          style: ptstyle(
                            size: 15,
                            weight: 700,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
