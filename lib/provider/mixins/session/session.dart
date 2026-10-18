import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/mixins/agent/agent.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signin.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flutter/material.dart';

/// Used by [MaterialApp] so an ended session can open the sign-in screen
/// from wherever the app is.
final sessionNavigatorKey = GlobalKey<NavigatorState>();

/// Sign-in tokens last 24 hours, one per role (customer and agent each have
/// their own). This keeps them alive and handles the end of a session:
///  - on app start and when coming back from the background, a token with
///    under 2 hours left is renewed (POST /token/refresh); one with no
///    expiry saved yet is checked with GET /session first
///  - a 401 ends that role's session: its other pending requests are
///    cancelled and the sign-in screen opens once, email kept filled in
///  - a 401 on a request sent with a token that has since been renewed is
///    retried once with the new token
mixin Session on Agent {
  static const _refreshWindow = Duration(hours: 2);
  static const _sessionExtra = "session_call";
  static const _retriedExtra = "session_retried";

  CancelToken _customerCancel = CancelToken();
  CancelToken _partnerCancel = CancelToken();
  final Map<String, bool> _renewedTokens = {}; // old token -> isCustomer
  Future<bool>? _customerRefresh;
  Future<bool>? _partnerRefresh;
  AppLifecycleListener? _lifecycle;

  /// True while the splash (InitScreen) is loading; a session that ends
  /// then is shown by [showPendingSignIn] once Home is open.
  bool sessionStartup = false;
  bool? _pendingSignInCustomer; // null = nothing pending

  void installSession() {
    _lifecycle ??= AppLifecycleListener(onResume: ensureFreshSessions);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (o.extra[_sessionExtra] != true) {
            final t = _bearer(o);
            if (t != null && t == userData?.token) {
              o.cancelToken ??= _customerCancel;
            } else if (t != null && t == partnerData?.token) {
              o.cancelToken ??= _partnerCancel;
            }
          }
          h.next(o);
        },
        onResponse: (r, h) async {
          if (r.statusCode == 401) {
            final retried = await _on401(r.requestOptions, r.data);
            if (retried != null) return h.resolve(retried);
          }
          h.next(r);
        },
        onError: (e, h) async {
          if (e.response?.statusCode == 401) {
            final retried = await _on401(e.requestOptions, e.response?.data);
            if (retried != null) return h.resolve(retried);
          }
          h.next(e);
        },
      ),
    );
  }

  String? _bearer(RequestOptions o) {
    final auth = "${o.headers['Authorization'] ?? o.headers['authorization'] ?? ''}";
    if (!auth.startsWith("Bearer ")) return null;
    final t = auth.substring(7).trim();
    return t.isEmpty || t == "null" ? null : t;
  }

  Options _tokenOptions(String token) => Options(
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    },
    validateStatus: (_) => true,
    extra: {_sessionExtra: true},
  );

  /// Returns the retried response, or null to pass the 401 on unchanged.
  Future<Response?> _on401(RequestOptions o, dynamic body) async {
    if (o.extra[_sessionExtra] == true || o.extra[_retriedExtra] == true) {
      return null;
    }
    final t = _bearer(o);
    if (t == null) return null;
    final code = body is Map ? "${body['code'] ?? ''}" : "";

    if (t == userData?.token) {
      _sessionEnded(customer: true, code: code);
      return null;
    }
    if (t == partnerData?.token) {
      _sessionEnded(customer: false, code: code);
      return null;
    }
    // Sent with a token that was renewed meanwhile: retry once with the new one.
    final wasCustomer = _renewedTokens[t];
    final fresh = wasCustomer == null
        ? null
        : wasCustomer
        ? userData?.token
        : partnerData?.token;
    if (fresh == null) return null;
    o.headers['Authorization'] = "Bearer $fresh";
    o.extra[_retriedExtra] = true;
    o.cancelToken = null;
    try {
      return await dio.fetch(o);
    } on DioException catch (e) {
      return e.response;
    } catch (_) {
      return null;
    }
  }

  @override
  void onPartnerSessionExpired() {
    _pendingSignInCustomer ??= false;
  }

  /// Renews tokens close to expiry. Call on app start and resume.
  Future<void> ensureFreshSessions() async {
    await Future.wait([_ensureFresh(true), _ensureFresh(false)]);
  }

  Future<void> _ensureFresh(bool customer) async {
    final token = customer ? userData?.token : partnerData?.token;
    if (token == null) return;
    var expiresAt = customer ? userData?.expiresAt : partnerData?.expiresAt;

    if (expiresAt == null) {
      // Signed in before the server sent an expiry: ask it.
      try {
        final r = await dio.get(ApiUrls.sessionGET, options: _tokenOptions(token));
        if (r.statusCode == 401) {
          _sessionEnded(customer: customer, code: "${r.data is Map ? r.data['code'] : ''}");
          return;
        }
        if (r.statusCode != 200 || r.data is! Map) return;
        final s = stampExpiry(r.data);
        expiresAt = DateTime.tryParse("${s['expires_at'] ?? ''}");
        if (expiresAt == null) return;
        await _storeToken(customer, token, expiresAt);
        if (r.data['refresh_recommended'] == true) {
          await refreshToken(customer: customer);
          return;
        }
      } catch (_) {
        return; // offline: try again next time
      }
    }

    final left = expiresAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _sessionEnded(customer: customer, code: "token_expired");
    } else if (left < _refreshWindow) {
      await refreshToken(customer: customer);
    }
  }

  /// POST /token/refresh: a new token with a full 24 hours; the old one is
  /// cancelled by the server. Only one refresh per role runs at a time.
  Future<bool> refreshToken({required bool customer}) {
    final running = customer ? _customerRefresh : _partnerRefresh;
    if (running != null) return running;
    final f = _doRefresh(customer).whenComplete(() {
      if (customer) {
        _customerRefresh = null;
      } else {
        _partnerRefresh = null;
      }
    });
    if (customer) {
      _customerRefresh = f;
    } else {
      _partnerRefresh = f;
    }
    return f;
  }

  Future<bool> _doRefresh(bool customer) async {
    final old = customer ? userData?.token : partnerData?.token;
    if (old == null) return false;
    try {
      final r = await dio.post(ApiUrls.tokenRefreshPST, options: _tokenOptions(old));
      debugPrint("=== [tokenRefresh] ${customer ? 'customer' : 'agent'} ${r.statusCode}");
      if (r.statusCode == 200 && r.data is Map && r.data['token'] != null) {
        final s = stampExpiry(r.data);
        final expiresAt = DateTime.tryParse("${s['expires_at'] ?? ''}");
        _renewedTokens[old] = customer;
        await _storeToken(customer, "${s['token']}", expiresAt);
        return true;
      }
      if (r.statusCode == 401) {
        _sessionEnded(customer: customer, code: "${r.data is Map ? r.data['code'] : ''}");
      }
    } catch (e) {
      debugPrint("!!! [tokenRefresh] $e");
    }
    return false;
  }

  /// Saves a role's (new) token and expiry, keeping the rest of its session.
  Future<void> _storeToken(bool customer, String token, DateTime? expiresAt) async {
    final exp = expiresAt?.toUtc().toIso8601String();
    if (customer) {
      final raw = await DS.storage.read(key: "user");
      if (raw == null || userData == null) return;
      final m = Map<String, dynamic>.from(jsonDecode(raw))
        ..['token'] = token
        ..['expires_at'] = exp;
      await DS.storage.write(key: "user", value: jsonEncode(m));
      await getUserDetails();
    } else {
      final p = partnerData;
      if (p == null) return;
      final m = p.toJson()
        ..['token'] = token
        ..['expires_at'] = exp;
      partnerData = PartnerData.fromJson(m);
      await DS.storage.write(key: "partner", value: jsonEncode(m));
      notifyListeners();
    }
  }

  /// The role's token no longer works (expired or signed out elsewhere).
  /// Clears it right away, so the other 401s from the same token don't
  /// repeat this, and opens the sign-in screen once.
  void _sessionEnded({required bool customer, String code = ""}) {
    debugPrint("=== [session] ${customer ? 'customer' : 'agent'} ended ($code)");
    if (customer) {
      if (userData == null) return;
      final email = userData!.data.email;
      _customerCancel.cancel("session ended");
      _customerCancel = CancelToken();
      userData = null;
      emailEditingController.text = email;
      DS.storage.delete(key: "user");
      notifyListeners();
    } else {
      if (partnerData == null) return;
      agentSignInEmailController.text = partnerData!.email;
      emailEditingController.text = partnerData!.email;
      _partnerCancel.cancel("session ended");
      _partnerCancel = CancelToken();
      agentSignOut();
    }
    // A customer sign-in (shared screen) wins over the agent one.
    _pendingSignInCustomer = customer || (_pendingSignInCustomer ?? false);
    if (!sessionStartup) showPendingSignIn();
  }

  /// Opens the sign-in screen for a session that ended (once).
  void showPendingSignIn() {
    final pending = _pendingSignInCustomer;
    final nav = sessionNavigatorKey.currentState;
    if (pending == null || nav == null) return;
    _pendingSignInCustomer = null;

    // Agent session ended but still signed in as a customer: agent sign-in
    // on top of where they are. Otherwise back to Home as a guest, with the
    // shared sign-in screen on top.
    final agentOnly = !pending && userData != null;
    if (agentOnly) {
      nav.push(MaterialPageRoute(builder: (_) => const AgentSignin()));
    } else {
      final ctx = nav.context;
      NavigationHelper.pushAndRemoveUntil(ctx, const HomePage());
      nav.push(MaterialPageRoute(builder: (_) => const EmailSignin()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = sessionNavigatorKey.currentContext;
      if (ctx == null) return;
      SnackbarHelper.danger(
        context: ctx,
        title: "Session Expired",
        message: "Please sign in again to continue.",
      );
    });
  }

  /// "Log Out": cancels both tokens on the server (POST /logout); the
  /// caller then clears the phone's storage.
  Future<void> logoutEverywhere() async {
    final tokens = [userData?.token, partnerData?.token].whereType<String>();
    await Future.wait(
      tokens.map(
        (t) => dio
            .post(ApiUrls.logoutPST, options: _tokenOptions(t))
            .timeout(const Duration(seconds: 8))
            .then((_) {}, onError: (_) {}),
      ),
    );
    await agentSignOut();
  }
}
