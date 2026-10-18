// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/models/promo_usage_m.dart';
import 'package:flexiphones/provider/mixins/user/user.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_home_shell.dart';
import 'package:flexiphones/screens/agent_dashboard/vendor_onboarding/onboard_vendor_success.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_application_success.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_otp.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_register.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signup.dart';
import 'package:flexiphones/screens/onboarding/agent/become_agent.dart';
import 'package:flexiphones/screens/init_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Partner (agent) side. A partner is a SEPARATE account from a customer:
/// own email/password, own Sanctum token (24h), own storage key ("partner").
///
/// Backend flow (routes/api.php, prefix /api/partner):
///   email-verification -> email-otp-verification -> registration -> (token)
///   login, onboard-vendor, my-vendors, momo-details, wallet,
///   wallet/transactions, update-ghana-card/{id}
mixin Agent on User {
  PartnerData? partnerData;

  bool get isAgentAccount => partnerData != null;

  // ------------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------------
  // `Accept: application/json` matters: Laravel's $request->validate()
  // (used in onboardVendor) REDIRECTS instead of returning 422 JSON without it.
  static const _jsonHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  Options get _publicOptions =>
      Options(headers: _jsonHeaders, validateStatus: (_) => true);

  Options get _authOptions => Options(
        headers: {
          ..._jsonHeaders,
          "Authorization": "Bearer ${partnerData?.token}",
        },
        validateStatus: (_) => true,
      );

  String _apiMessage(dynamic body, String fallback) {
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return "${first.first}";
        return "$first";
      }
      if (body['message'] != null) return "${body['message']}";
    }
    return fallback;
  }

  String _dioMessage(DioException e) =>
      _apiMessage(e.response?.data, e.message ?? "Network error, please try again.");

  /// Token expired/revoked -> drop the partner session.
  bool _handleUnauthorized(Response r) {
    if (r.statusCode == 401) {
      agentSignOut();
      return true;
    }
    return false;
  }

  // ------------------------------------------------------------------
  // session
  // ------------------------------------------------------------------
  Future<void> loadPartnerSession() async {
    try {
      final raw = await DS.storage.read(key: "partner");
      if (raw == null || raw.isEmpty) {
        partnerData = null;
      } else {
        final p = PartnerData.fromJson(jsonDecode(raw));
        if (p.token == null || p.isExpired) {
          await DS.storage.delete(key: "partner");
          partnerData = null;
          // The 24 hours ended while the app was closed: the agent has to
          // sign in again (email kept filled in).
          if (p.token != null) {
            agentSignInEmailController.text = p.email;
            onPartnerSessionExpired();
          }
        } else {
          partnerData = p;
        }
      }
    } catch (_) {
      partnerData = null;
    }
    notifyListeners();
  }

  /// Called when a stored agent session turned out to be expired.
  /// Overridden by the Session mixin.
  void onPartnerSessionExpired() {}

  /// Sign out button: cancels the token on the server too (POST /logout),
  /// then clears it from the phone.
  Future<void> agentLogout() async {
    final token = partnerData?.token;
    await agentSignOut();
    if (token == null) return;
    try {
      await dio
          .post(
            ApiUrls.logoutPST,
            options: Options(
              headers: {..._jsonHeaders, "Authorization": "Bearer $token"},
              validateStatus: (_) => true,
            ),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  @override
  Future<void> saveGoogleAgentSession(Map<String, dynamic> payload) =>
      _saveSession(PartnerData.fromJson(payload));

  Future<void> _saveSession(PartnerData p) async {
    partnerData = p;
    await DS.storage.write(key: "partner", value: jsonEncode(p.toJson()));
    notifyListeners();
  }

  Future<void> agentSignOut() async {
    partnerData = null;
    partnerWallet = null;
    withdrawals = [];
    withdrawAvailable = null;
    withdrawalsHasMore = false;
    partnerTransactions = [];
    agentVendors = [];
    momoDetails = null;
    txHasMore = false;
    partnerEarnings = null;
    pointsHistory = [];
    pointsHasMore = false;
    agentNotifications = [];
    agentUnreadCount = 0;
    agentNotificationSettings = [];
    notifyListeners();
    try {
      await DS.storage.delete(key: "partner");
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // auth form state
  // ------------------------------------------------------------------
  final agentEmailFormKey = GlobalKey<FormState>();
  final agentRegisterFormKey = GlobalKey<FormState>();
  final agentSignInFormKey = GlobalKey<FormState>();

  final agentEmailController = TextEditingController();
  final agentOtpController = TextEditingController();
  final agentNameController = TextEditingController();
  final agentPhoneController = TextEditingController();
  final agentRegionController = TextEditingController();
  final agentAddressController = TextEditingController();
  final agentPasswordController = TextEditingController();
  final agentConfirmPasswordController = TextEditingController();
  final agentSignInEmailController = TextEditingController();
  final agentSignInPasswordController = TextEditingController();

  bool agentLoading = false;
  bool _agentPrefilled = false;

  void prefillAgentFieldsFromUser() {
    if (_agentPrefilled) return;
    final u = userData?.data;
    if (u != null) {
      if (agentEmailController.text.isEmpty) agentEmailController.text = u.email;
      if (agentNameController.text.isEmpty) agentNameController.text = u.name;
      final digits = u.phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (agentPhoneController.text.isEmpty && digits.length >= 9) {
        agentPhoneController.text = digits.substring(digits.length - 9);
      }
    }
    _agentPrefilled = true;
  }

  void resetAgentAuthForms() {
    agentEmailController.clear();
    agentOtpController.clear();
    agentNameController.clear();
    agentPhoneController.clear();
    agentRegionController.clear();
    agentAddressController.clear();
    agentPasswordController.clear();
    agentConfirmPasswordController.clear();
    agentSignInEmailController.clear();
    agentSignInPasswordController.clear();
    agentLoading = false;
    _agentPrefilled = false;
  }

  // ------------------------------------------------------------------
  // step 1: POST /partner/email-verification
  // ------------------------------------------------------------------
  Future<void> agentSendEmailOtp(
    BuildContext context, {
    bool resend = false,
  }) async {
    final email = agentEmailController.text.trim();
    if (!email.isValidEmail) {
      SnackbarHelper.danger(
        context: context,
        title: "Invalid email",
        message: "Please enter a valid email address.",
      );
      return;
    }

    agentLoading = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.partnerEmailVerificationPST,
        data: {"email": email},
        options: _publicOptions,
      );
      agentLoading = false;
      notifyListeners();

      if (!context.mounted) return;
      if (r.statusCode == 200) {
        agentOtpController.clear();
        if (resend) {
          SnackbarHelper.success(
            context: context,
            title: "Code sent",
            message: "A new verification code was sent to $email.",
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AgentOtpScreen()),
          );
        }
      } else {
        // 409 => "Email is already verified and active." (already an agent)
        SnackbarHelper.danger(
          context: context,
          title: r.statusCode == 409 ? "Already an agent" : "Could not send code",
          message: r.statusCode == 409
              ? "This email already has an agent account. Please sign in instead."
              : _apiMessage(r.data, "Something went wrong. Please try again."),
        );
      }
    } on DioException catch (e) {
      agentLoading = false;
      notifyListeners();
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Could not send code",
        message: _dioMessage(e),
      );
    }
  }

  // ------------------------------------------------------------------
  // step 2: POST /partner/email-otp-verification  (5 digit code)
  // ------------------------------------------------------------------
  Future<void> agentVerifyOtp(BuildContext context) async {
    final otp = agentOtpController.text.trim();
    if (otp.length != 5) {
      SnackbarHelper.danger(
        context: context,
        title: "Invalid code",
        message: "Enter the 5 digit code we emailed you.",
      );
      return;
    }

    agentLoading = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.partnerOtpVerificationPST,
        data: {"email": agentEmailController.text.trim(), "otp": otp},
        options: _publicOptions,
      );
      agentLoading = false;
      notifyListeners();

      if (!context.mounted) return;
      if (r.statusCode == 200) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AgentRegister()),
        );
      } else {
        HapticFeedback.vibrate();
        SnackbarHelper.danger(
          context: context,
          title: "Verification failed",
          message: _apiMessage(r.data, "Invalid or expired code."),
        );
      }
    } on DioException catch (e) {
      agentLoading = false;
      notifyListeners();
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Verification failed",
        message: _dioMessage(e),
      );
    }
  }

  // ------------------------------------------------------------------
  // step 3: POST /partner/registration  (returns 201 + token)
  // ------------------------------------------------------------------
  Future<void> agentCompleteRegistration(BuildContext context) async {
    if (!agentRegisterFormKey.currentState!.validate()) return;

    final email = agentEmailController.text.trim();
    final password = agentPasswordController.text;

    agentLoading = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.partnerRegistrationPST,
        data: {
          "email": email,
          "name": agentNameController.text.trim(),
          "phone": "0${agentPhoneController.text.trim()}",
          "region": agentRegionController.text.trim(),
          if (agentAddressController.text.trim().isNotEmpty)
            "address": agentAddressController.text.trim(),
          "password": password,
          "password_confirmation": agentConfirmPasswordController.text,
        },
        options: _publicOptions,
      );

      if (r.statusCode == 200 || r.statusCode == 201) {
        await _saveSession(PartnerData.fromJson(r.data));

        // The registration response has no promo_code; login returns the
        // full partner row, so fetch it once to get it.
        try {
          final full = await dio.post(
            ApiUrls.partnerLoginPST,
            data: {"email": email, "password": password},
            options: _publicOptions,
          );
          if (full.statusCode == 200 && full.data is Map) {
            await _saveSession(PartnerData.fromJson(full.data));
          }
        } catch (_) {}

        agentLoading = false;
        resetAgentAuthForms();
        notifyListeners();

        if (!context.mounted) return;
        final nav = Navigator.of(context);
        nav.popUntil((route) => route.isFirst);
        nav.push(
          MaterialPageRoute(builder: (_) => const AgentApplicationSuccess()),
        );
      } else {
        agentLoading = false;
        notifyListeners();
        if (!context.mounted) return;
        SnackbarHelper.danger(
          context: context,
          title: "Registration failed",
          message: _apiMessage(r.data, "Something went wrong. Please try again."),
        );
      }
    } on DioException catch (e) {
      agentLoading = false;
      notifyListeners();
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Registration failed",
        message: _dioMessage(e),
      );
    }
  }

  // ------------------------------------------------------------------
  // Sign in. One email can be a customer AND an agent: two accounts, two
  // tokens. POST /login with "as" picks which token comes back, and the
  // response's `roles` says what else the person has.
  // ------------------------------------------------------------------
  Future<Response> _loginAs(String email, String password, String as) =>
      dio.post(
        ApiUrls.loginAsPST,
        data: {"email": email, "password": password, "as": as},
        options: _publicOptions,
      );

  /// POST /account-roles — which accounts an email has. Null on failure.
  Future<AccountRoles?> getAccountRoles(String email) async {
    try {
      final r = await dio.post(
        ApiUrls.accountRolesPST,
        data: {"email": email.trim()},
        options: _publicOptions,
      );
      debugPrint("=== [accountRoles] ${r.statusCode}: ${r.data}");
      if (r.statusCode == 200 && r.data is Map) {
        return AccountRoles.fromJson(Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      debugPrint("!!! [accountRoles] $e");
    }
    return null;
  }

  /// Signs in the customer side with the same details and saves it.
  Future<bool> _signInCustomerToo(String email, String password) async {
    try {
      final r = await _loginAs(email, password, "customer");
      debugPrint("=== [agentSignIn] customer side ${r.statusCode}");
      if (r.statusCode != 200 || r.data is! Map) return false;
      await DS.storage.write(
        key: "user",
        value: jsonEncode(stampExpiry(r.data)),
      );
      await getUserDetails();
      return true;
    } catch (e) {
      debugPrint("!!! [agentSignIn] customer side: $e");
      return false;
    }
  }

  Future<void> agentSignIn(BuildContext context) async {
    if (!agentSignInFormKey.currentState!.validate()) return;

    final email = agentSignInEmailController.text.trim();
    final password = agentSignInPasswordController.text;
    agentLoading = true;
    notifyListeners();
    try {
      final r = await _loginAs(email, password, "agent");
      debugPrint("=== [agentSignIn] ${r.statusCode}: ${r.data is Map ? r.data['code'] ?? r.data['role'] : ''}");
      final body = r.data is Map ? r.data as Map : const {};
      final roles =
          body['roles'] is Map
              ? AccountRoles.fromJson(Map<String, dynamic>.from(body['roles']))
              : null;
      if (!context.mounted) return;

      if (r.statusCode == 200 && r.data is Map) {
        await _saveSession(PartnerData.fromJson(r.data));
        // Also a customer? Sign that side in too, so both roles are active.
        final both =
            userData == null &&
            (roles?.customer ?? true) &&
            await _signInCustomerToo(email, password);

        resetAgentAuthForms();
        if (!context.mounted) return;
        if (both) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const InitScreen(openAgent: true)),
            (_) => false,
          );
        } else {
          openAgentShell(context);
        }
      } else if (r.statusCode == 403 && body['code'] == "not_an_agent") {
        // Correct customer password, but no agent account yet.
        await _openBecomeAgent(
          context,
          email,
          password,
          _apiMessage(r.data, "This email is a customer account, not an agent account yet."),
        );
      } else if (r.statusCode == 401) {
        await _explainAgentLoginFailure(context, email);
      } else {
        SnackbarHelper.danger(
          context: context,
          title: "Sign in failed",
          message: _apiMessage(
            r.data,
            r.statusCode == 403
                ? "Your agent account is not active yet."
                : "Something went wrong. Please try again.",
          ),
        );
      }
    } catch (e) {
      debugPrint("!!! [agentSignIn] $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Sign in failed",
          message: "Check your internet connection and try again.",
        );
      }
    } finally {
      agentLoading = false;
      notifyListeners();
    }
  }

  /// `not_an_agent`: sign the customer side in and open the short
  /// Become-an-agent form (it needs the customer token).
  Future<void> _openBecomeAgent(
    BuildContext context,
    String email,
    String password,
    String message,
  ) async {
    final ok = userData != null || await _signInCustomerToo(email, password);
    if (!context.mounted) return;
    SnackbarHelper.info(
      context: context,
      title: "No agent account yet",
      message: ok ? "$message Fill in this short form to become one." : message,
      ch: Theme.of(context).colorScheme,
    );
    if (ok) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const BecomeAgent()));
    }
  }

  /// 401 on the agent side: ask /account-roles what this email actually
  /// is, so the message says what to do instead of just "invalid".
  Future<void> _explainAgentLoginFailure(
    BuildContext context,
    String email,
  ) async {
    final roles = await getAccountRoles(email);
    if (!context.mounted) return;

    if (roles == null || roles.agent) {
      SnackbarHelper.danger(
        context: context,
        title: "Wrong password",
        message:
            "The email or password is incorrect. Tap \"Forgot password?\" to reset it.",
      );
    } else if (!roles.agentSignupFinished && !roles.customer) {
      SnackbarHelper.danger(
        context: context,
        title: "Finish signing up",
        message:
            "You didn't finish signing up as an agent with this email. Please sign up again.",
      );
      agentEmailController.text = email;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AgentSignup()));
    } else if (roles.customer) {
      SnackbarHelper.danger(
        context: context,
        title: "Not an agent yet",
        message:
            "This email is a customer account, not an agent yet, and the password is incorrect. Check your password, then you can become an agent.",
      );
    } else {
      SnackbarHelper.danger(
        context: context,
        title: "No account",
        message: "There's no account with this email. Sign up as an agent.",
      );
    }
  }

  /// Used by the shared email sign-in, so an agent can sign in on the same
  /// screen as customers. 401 / not_an_agent just mean "no agent account
  /// with these details" — the customer result decides what to show then.
  @override
  Future<({bool ok, String? message})> partnerSignIn(
    String email,
    String password,
  ) async {
    try {
      final r = await _loginAs(email, password, "agent");
      debugPrint("=== [partnerSignIn] ${r.statusCode}");
      if (r.statusCode == 200 && r.data is Map) {
        await _saveSession(PartnerData.fromJson(r.data));
        return (ok: true, message: null);
      }
      final code = r.data is Map ? r.data['code'] : null;
      if (r.statusCode == 401 ||
          r.statusCode == 422 ||
          code == "not_an_agent") {
        return (ok: false, message: null);
      }
      return (ok: false, message: _apiMessage(r.data, "Agent sign in failed."));
    } catch (e) {
      debugPrint("!!! [partnerSignIn] ERROR: $e");
      return (ok: false, message: null);
    }
  }

  /// Back to the root (HomePage), then open the agent dashboard on top.
  void openAgentShell(BuildContext context) {
    final nav = Navigator.of(context);
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute(builder: (_) => const AgentHomeShell()));
  }

  // ------------------------------------------------------------------
  // GET /partner/wallet
  // ------------------------------------------------------------------
  PartnerWallet? partnerWallet;
  bool loadingWallet = false;

  Future<void> getPartnerWallet() async {
    loadingWallet = true;
    notifyListeners();
    try {
      final r = await dio.get(ApiUrls.partnerWalletGET, options: _authOptions);
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map) {
        partnerWallet = PartnerWallet.fromJson(Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      debugPrint("!!! [getPartnerWallet] $e");
    } finally {
      loadingWallet = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // GET /partner/wallet/transactions?page=&per_page=   (Laravel paginator)
  // ------------------------------------------------------------------
  List<WalletTransaction> partnerTransactions = [];
  bool loadingTx = false;
  bool txHasMore = false;
  int _txPage = 1;

  Future<void> getPartnerTransactions({bool refresh = true}) async {
    if (!refresh && !txHasMore) return;
    loadingTx = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _txPage + 1;
      final r = await dio.get(
        ApiUrls.partnerTransactionsGET,
        queryParameters: {"page": page, "per_page": 20},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map && r.data['data'] is Map) {
        final p = r.data['data'] as Map;
        final list = (p['data'] as List)
            .map((x) => WalletTransaction.fromJson(Map<String, dynamic>.from(x)))
            .toList();
        partnerTransactions = refresh ? list : [...partnerTransactions, ...list];
        _txPage = page;
        txHasMore = p['next_page_url'] != null;
      }
    } catch (e) {
      debugPrint("!!! [getPartnerTransactions] $e");
    } finally {
      loadingTx = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // GET /partner/my-vendors
  // ------------------------------------------------------------------
  List<PartnerVendor> agentVendors = [];
  bool loadingVendors = false;
  bool vendorsHasMore = false;
  int _vendorsPage = 1;

  /// Page-number paging: `data` + `pagination {current_page, last_page}`.
  /// [refresh] starts again from page 1 (pull-to-refresh); otherwise the
  /// next page is appended ("Load more").
  Future<void> getAgentVendors({bool refresh = true}) async {
    if (!refresh && (!vendorsHasMore || loadingVendors)) return;
    loadingVendors = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _vendorsPage + 1;
      final r = await dio.get(
        ApiUrls.partnerVendorsGET,
        queryParameters: {"page": page, "per_page": 50},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map && r.data['data'] is List) {
        final list =
            (r.data['data'] as List)
                .map((x) => PartnerVendor.fromJson(Map<String, dynamic>.from(x)))
                .toList();
        agentVendors = refresh ? list : [...agentVendors, ...list];
        final pg = r.data['pagination'];
        final last = pg is Map ? int.tryParse("${pg['last_page']}") ?? page : page;
        _vendorsPage = page;
        vendorsHasMore = page < last;
      }
    } catch (e) {
      debugPrint("!!! [getAgentVendors] $e");
    } finally {
      loadingVendors = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // POST /partner/vendors/{id}/resend-invite  (once an hour, 6 emails max)
  // ------------------------------------------------------------------
  /// Vendor ids with a resend in flight (for the button spinner).
  final Set<int> resendingInvites = {};

  Future<bool> resendVendorInvite(BuildContext context, int vendorId) async {
    resendingInvites.add(vendorId);
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.partnerResendInvite(vendorId),
        options: _authOptions,
      );
      debugPrint("=== [resendInvite] ${r.statusCode}: ${r.data}");
      if (_handleUnauthorized(r)) return false;
      final body = r.data is Map ? r.data as Map : const {};

      // Every answer (success and errors) carries the current invite state.
      if (body['invite'] is Map) {
        final invite = VendorInvite.fromJson(
          Map<String, dynamic>.from(body['invite']),
        );
        for (final v in agentVendors) {
          if (v.id == vendorId) v.invite = invite;
        }
      }
      if (!context.mounted) return false;

      switch (r.statusCode) {
        case 200:
          SnackbarHelper.success(
            context: context,
            title: "Invitation sent",
            message: _apiMessage(r.data, "The invitation was sent again."),
          );
          return true;
        case 404:
          SnackbarHelper.danger(
            context: context,
            title: "Vendor not found",
            message: "This vendor isn't on your list.",
          );
        case 409: // already_responded
          SnackbarHelper.info(
            context: context,
            title: "Vendor already set up",
            message: _apiMessage(r.data, "The vendor has already responded."),
            ch: Theme.of(context).colorScheme,
          );
          getAgentVendors();
        case 429: // too_soon | limit_reached
          SnackbarHelper.danger(
            context: context,
            title:
                body['code'] == "limit_reached"
                    ? "Limit reached"
                    : "Please wait",
            message: _apiMessage(r.data, "Please try again later."),
          );
        default:
          SnackbarHelper.danger(
            context: context,
            title: "Not sent",
            message: "The email couldn't be sent right now. Try again later.",
          );
      }
    } catch (e) {
      debugPrint("!!! [resendInvite] $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Not sent",
          message: "Check your internet connection and try again.",
        );
      }
    } finally {
      resendingInvites.remove(vendorId);
      notifyListeners();
    }
    return false;
  }

  // ------------------------------------------------------------------
  // /partner/momo-details  (GET / POST first time / PUT afterwards)
  // ------------------------------------------------------------------
  MomoDetails? momoDetails;
  bool loadingMomo = false;
  bool savingMomo = false;

  Future<void> getMomoDetails() async {
    loadingMomo = true;
    notifyListeners();
    try {
      final r = await dio.get(ApiUrls.partnerMomoDetails, options: _authOptions);
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map) {
        momoDetails = MomoDetails.fromJson(Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      debugPrint("!!! [getMomoDetails] $e");
    } finally {
      loadingMomo = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // MoMo number: the agent only types the number. The network and the
  // wallet's name come from the provider (POST /partner/momo-details/lookup).
  //
  // Misuse guard: a lookup shows whose wallet a number belongs to, so the
  // number can't be swapped freely. Turning down a looked-up name, or
  // saving a number, locks new lookups on this phone for [momoLockTime].
  // ------------------------------------------------------------------
  static const momoLockTime = Duration(minutes: 5);
  int get momoLockMinutes => momoLockTime.inMinutes;
  DateTime? momoLockedUntil;

  String get _momoLockKey => "momo_lock_${partnerData?.id ?? 0}";

  Future<void> loadMomoLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_momoLockKey);
      momoLockedUntil = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      if (momoLockedUntil != null && momoLockedUntil!.isBefore(DateTime.now())) {
        momoLockedUntil = null;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> lockMomo() async {
    momoLockedUntil = DateTime.now().add(momoLockTime);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_momoLockKey, momoLockedUntil!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Time left before a new number can be looked up; zero when free.
  Duration get momoLockLeft {
    final until = momoLockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// POST /partner/momo-details/lookup — nothing is saved.
  Future<
    ({bool ok, String? network, String? name, bool verified, String? message})
  >
  lookupMomo(String number) async {
    try {
      final r = await dio.post(
        ApiUrls.partnerMomoLookupPST,
        data: {"momo_number": number},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) {
        return (ok: false, network: null, name: null, verified: false, message: "Please sign in again.");
      }
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200 && body['data'] is Map) {
        final d = body['data'] as Map;
        return (
          ok: true,
          network: d['momo_network']?.toString(),
          name: d['momo_account_name']?.toString(),
          verified: d['name_verified'] == true,
          message: null,
        );
      }
      return (
        ok: false,
        network: null,
        name: null,
        verified: false,
        message:
            r.statusCode == 429
                ? "Too many checks. Wait a minute and try again."
                : _apiMessage(r.data, "We couldn't check that number."),
      );
    } catch (_) {
      return (
        ok: false,
        network: null,
        name: null,
        verified: false,
        message: "Check your internet connection and try again.",
      );
    }
  }

  /// True when [number] would replace a different saved number (then an
  /// emailed code is needed before saving).
  bool momoChangeNeedsCode(String number) {
    final saved = momoDetails;
    if (saved == null || !saved.isSet) return false;
    String last9(String s) {
      final d = s.replaceAll(RegExp(r'[^0-9]'), '');
      return d.length >= 9 ? d.substring(d.length - 9) : d;
    }
    return last9(saved.number ?? "") != last9(number);
  }

  /// POST /partner/momo-details/code — emails a 6-digit code tied to the
  /// new number. Returns (ok, message, resendAfter seconds).
  Future<({bool ok, String message, int resendAfter})> requestMomoChangeCode(
    String number,
  ) async {
    try {
      final r = await dio.post(
        ApiUrls.partnerMomoCodePST,
        data: {"momo_number": number},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) {
        return (ok: false, message: "Please sign in again.", resendAfter: 0);
      }
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200 || r.statusCode == 201) {
        final d = body['data'] is Map ? body['data'] as Map : const {};
        return (
          ok: true,
          message: "${body['message'] ?? 'We emailed you a 6-digit code.'}",
          resendAfter: int.tryParse("${d['resend_after_seconds'] ?? 30}") ?? 30,
        );
      }
      return (
        ok: false,
        message:
            r.statusCode == 429
                ? "Please wait a moment before asking for another code."
                : _apiMessage(r.data, "Couldn't send the code. Try again."),
        resendAfter: 0,
      );
    } catch (_) {
      return (
        ok: false,
        message: "Check your internet connection and try again.",
        resendAfter: 0,
      );
    }
  }

  /// Saves the number; the server fills in network and name itself.
  /// [code] is needed only when replacing a different saved number.
  /// `needsCode` is true when the server asks for (another) code.
  Future<({bool ok, String? message, bool needsCode})> saveMomoNumber(
    String number, {
    String? code,
  }) async {
    savingMomo = true;
    notifyListeners();
    try {
      final body = {
        "momo_number": number,
        if (code != null && code.isNotEmpty) "code": code,
      };
      final r =
          (momoDetails?.isSet ?? false)
              ? await dio.put(ApiUrls.partnerMomoDetails, data: body, options: _authOptions)
              : await dio.post(ApiUrls.partnerMomoDetails, data: body, options: _authOptions);
      if (_handleUnauthorized(r)) {
        return (ok: false, message: "Please sign in again.", needsCode: false);
      }
      if (r.statusCode == 200 && r.data is Map) {
        momoDetails = MomoDetails.fromJson(Map<String, dynamic>.from(r.data));
        await lockMomo(); // no quick swaps after saving
        return (ok: true, message: null, needsCode: false);
      }
      final m = r.data is Map ? r.data as Map : const {};
      final errors = m['errors'] is Map ? m['errors'] as Map : const {};
      if (m['code'] == 'otp_required' || errors['code'] != null) {
        final e = errors['code'];
        return (
          ok: false,
          message: e is List && e.isNotEmpty ? "${e.first}" : "${m['message'] ?? 'Enter the code we emailed you.'}",
          needsCode: true,
        );
      }
      return (
        ok: false,
        message: _apiMessage(r.data, "Couldn't save the number. Try again."),
        needsCode: false,
      );
    } catch (_) {
      return (
        ok: false,
        message: "Check your internet connection and try again.",
        needsCode: false,
      );
    } finally {
      savingMomo = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  /// POST /partner/become-customer: adds the customer side to this agent
  /// (same email, phone and Ghana Card). If the answer carries a customer
  /// token, that session is saved so the shop opens signed in.
  Future<({bool ok, String message, bool signedIn})> becomeCustomer() async {
    try {
      final r = await dio.post(
        ApiUrls.partnerBecomeCustomer,
        options: _authOptions,
      );
      debugPrint("=== [becomeCustomer] ${r.statusCode}: ${r.data}");
      final m = r.data is Map ? Map<String, dynamic>.from(r.data) : <String, dynamic>{};
      final msg = (m["message"] ?? "").toString();
      final code = r.statusCode ?? 0;
      if (code == 200 || code == 201 || code == 409) {
        final data = m["data"] is Map ? Map<String, dynamic>.from(m["data"]) : null;
        final token = m["token"] ?? data?["token"];
        final user = data?["customer"] ?? data?["user"] ?? data;
        if (token != null && user is Map) {
          await saveCustomerSession({
            "status": "success",
            "message": msg,
            "token": token,
            "expires_in": m["expires_in"] ?? data?["expires_in"],
            "data": user,
          });
          return (ok: true, message: msg, signedIn: true);
        }
        return (ok: true, message: msg, signedIn: false);
      }
      return (ok: false, message: msg.isEmpty ? "Couldn't add the customer side." : msg, signedIn: false);
    } catch (e) {
      return (ok: false, message: "Check your internet connection and try again.", signedIn: false);
    }
  }

  /// Saves an updated agent profile (from profile/update, profile/photo or
  /// GET /partner/profile) and keeps the current sign-in.
  Future<void> applyAgentProfile(Map<String, dynamic> data) async {
    final p = partnerData;
    if (p == null) return;
    final now = p.toJson();
    final merged = <String, dynamic>{
      ...Map<String, dynamic>.from(now["data"] as Map),
      ...data,
    };
    await _saveSession(
      PartnerData.fromJson({
        "token": p.token,
        "expires_at": p.expiresAt?.toUtc().toIso8601String(),
        "data": merged,
      }),
    );
  }

  // GET /partner/approval: banner wording (information only for now).
  AgentApproval? agentApproval;

  Future<void> getAgentApproval() async {
    if (partnerData == null) return;
    try {
      final r = await dio.get(ApiUrls.partnerApproval, options: _authOptions);
      debugPrint("=== [approval] ${r.statusCode}: ${r.data}");
      final d = r.data is Map ? r.data["data"] : null;
      if (r.statusCode == 200 && d is Map) {
        agentApproval = AgentApproval.fromJson(d);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("!!! [approval] $e");
    }
  }

  // ------------------------------------------------------------------
  // POST /partner/update-ghana-card/{partnerId}  { ghana_card: GHA-XXXXXXXXX-X }
  // ------------------------------------------------------------------
  bool ghanaCardSaving = false;

  Future<bool> updateAgentGhanaCard(
    BuildContext context,
    String nineDigitsDashOne,
  ) async {
    final p = partnerData;
    if (p == null) return false;

    ghanaCardSaving = true;
    notifyListeners();
    try {
      final r = await dio.post(
        "${ApiUrls.partnerUpdateGHCard}${p.id}",
        data: {"ghana_card": "GHA-$nineDigitsDashOne"},
        options: _authOptions,
      );
      ghanaCardSaving = false;
      if (_handleUnauthorized(r)) return false;

      if (r.statusCode == 200 && r.data is Map) {
        // keep the current token/expiry, refresh the rest
        final merged = Map<String, dynamic>.from(r.data)
          ..['token'] = p.token
          ..['expires_at'] = p.expiresAt?.toUtc().toIso8601String();
        await _saveSession(PartnerData.fromJson(merged));
        getAgentApproval();
        if (context.mounted) {
          SnackbarHelper.success(
            context: context,
            title: "Ghana Card linked",
            message: "Your Ghana Card was saved.",
          );
        }
        return true;
      }
      notifyListeners();
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Could not link card",
          message: _apiMessage(r.data, "Something went wrong. Please try again."),
        );
      }
      return false;
    } on DioException catch (e) {
      ghanaCardSaving = false;
      notifyListeners();
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Could not link card",
          message: _dioMessage(e),
        );
      }
      return false;
    }
  }

  // ------------------------------------------------------------------
  // POST /partner/onboard-vendor  (JSON, no photo)
  // ------------------------------------------------------------------
  final vendorFormKey = GlobalKey<FormState>();
  final vendorShopNameController = TextEditingController();
  final vendorOwnerNameController = TextEditingController();
  final vendorOwnerEmailController = TextEditingController();
  final vendorPhoneController = TextEditingController();
  final vendorAddressController = TextEditingController();
  final vendorEstimatedDevicesController = TextEditingController();
  bool vendorSubmitting = false;

  void resetVendorForm() {
    vendorShopNameController.clear();
    vendorOwnerNameController.clear();
    vendorOwnerEmailController.clear();
    vendorPhoneController.clear();
    vendorAddressController.clear();
    vendorEstimatedDevicesController.clear();
    vendorSubmitting = false;
  }

  Future<void> submitVendorOnboarding(BuildContext context) async {
    if (!vendorFormKey.currentState!.validate()) return;

    vendorSubmitting = true;
    notifyListeners();
    try {
      final est = int.tryParse(vendorEstimatedDevicesController.text.trim());
      final r = await dio.post(
        ApiUrls.partnerOnboardVendorPST,
        data: {
          "shop_name": vendorShopNameController.text.trim(),
          "owner_name": vendorOwnerNameController.text.trim(),
          "owner_email": vendorOwnerEmailController.text.trim(),
          "phone": "0${vendorPhoneController.text.trim()}",
          "address": vendorAddressController.text.trim(),
          if (est != null) "estimated_monthly_devices": est,
        },
        options: _authOptions,
      );

      vendorSubmitting = false;
      if (_handleUnauthorized(r)) return;

      if (r.statusCode == 200 || r.statusCode == 201) {
        // data: { vendor_id, invite_sent }. invite_sent false = the vendor
        // was saved but the email failed — offer Resend straight away.
        final data =
            r.data is Map && r.data['data'] is Map ? r.data['data'] as Map : const {};
        final vendorId = int.tryParse("${data['vendor_id'] ?? ""}");
        final inviteSent = data['invite_sent'] != false;
        final message = _apiMessage(r.data, "");

        resetVendorForm();
        notifyListeners();
        getAgentVendors();
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => OnboardVendorSuccess(
                  vendorId: vendorId,
                  inviteSent: inviteSent,
                  message: message,
                ),
          ),
        );
      } else {
        notifyListeners();
        if (!context.mounted) return;
        SnackbarHelper.danger(
          context: context,
          title: "Failed To Submit Vendor",
          message: _apiMessage(r.data, "Something went wrong. Please try again."),
        );
      }
    } on DioException catch (e) {
      vendorSubmitting = false;
      notifyListeners();
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed To Submit Vendor",
        message: _dioMessage(e),
      );
    }
  }

  // ------------------------------------------------------------------
  // GET /partner/earnings  (rates, totals, points, promo code)
  // ------------------------------------------------------------------
  PartnerEarnings? partnerEarnings;

  Future<void> getPartnerEarnings() async {
    try {
      final r = await dio.get(ApiUrls.partnerEarningsGET, options: _authOptions);
      debugPrint("=== [partnerEarnings] ${r.statusCode}: ${r.data}");
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map) {
        partnerEarnings = PartnerEarnings.fromJson(
          Map<String, dynamic>.from(r.data),
        );
      }
    } catch (e) {
      debugPrint("!!! [getPartnerEarnings] $e");
    } finally {
      notifyListeners();
    }
  }

  /// Promo code from /earnings (always current), else from the session.
  String? get agentPromoCode {
    final c = partnerEarnings?.promoCode;
    return (c != null && c.isNotEmpty) ? c : partnerData?.promoCode;
  }

  // ------------------------------------------------------------------
  // GET /partner/points?page=&per_page=   (history is a Laravel paginator)
  // ------------------------------------------------------------------
  List<PointsEntry> pointsHistory = [];
  bool loadingPoints = false;
  bool pointsHasMore = false;
  int _pointsPage = 1;

  Future<void> getPartnerPoints({bool refresh = true}) async {
    if (!refresh && !pointsHasMore) return;
    loadingPoints = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _pointsPage + 1;
      final r = await dio.get(
        ApiUrls.partnerPointsGET,
        queryParameters: {"page": page, "per_page": 20},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
      final data = r.data is Map ? r.data['data'] : null;
      if (r.statusCode == 200 && data is Map && data['history'] is Map) {
        final h = data['history'] as Map;
        final list =
            (h['data'] as List? ?? [])
                .whereType<Map>()
                .map((x) => PointsEntry.fromJson(Map<String, dynamic>.from(x)))
                .toList();
        pointsHistory = refresh ? list : [...pointsHistory, ...list];
        _pointsPage = page;
        final last = int.tryParse("${h['last_page'] ?? 1}") ?? 1;
        pointsHasMore = page < last;
      }
    } catch (e) {
      debugPrint("!!! [getPartnerPoints] $e");
    } finally {
      loadingPoints = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // GET /partner/notifications  (vendor decisions, orders, down payments)
  // ------------------------------------------------------------------
  List<AgentNotification> agentNotifications = [];
  int agentUnreadCount = 0;
  bool loadingAgentNotifications = false;
  bool agentNotificationsHasMore = false;
  int _agentNotifPage = 1;

  Future<void> getAgentNotifications({bool refresh = true}) async {
    if (partnerData == null) return;
    if (!refresh && !agentNotificationsHasMore) return;
    loadingAgentNotifications = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _agentNotifPage + 1;
      final r = await dio.get(
        ApiUrls.partnerNotifications,
        queryParameters: {"page": page, "per_page": 20},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map) {
        final list =
            (r.data['data'] as List? ?? [])
                .whereType<Map>()
                .map(
                  (x) => AgentNotification.fromJson(Map<String, dynamic>.from(x)),
                )
                .toList();
        agentNotifications = refresh ? list : [...agentNotifications, ...list];
        agentUnreadCount =
            int.tryParse("${r.data['unread_count'] ?? ""}") ??
            agentNotifications.where((n) => n.isUnread).length;
        final pg = r.data['pagination'];
        final last = pg is Map ? int.tryParse("${pg['last_page']}") ?? 1 : 1;
        _agentNotifPage = page;
        agentNotificationsHasMore = page < last;
      }
    } catch (e) {
      debugPrint("!!! [agentNotifications] $e");
    } finally {
      loadingAgentNotifications = false;
      notifyListeners();
    }
  }

  /// GET /partner/notifications/unread-count — cheap badge poll; reloads
  /// the list only when the count moves.
  Future<void> pollAgentNotifications() async {
    if (partnerData == null) return;
    try {
      final r = await dio.get(ApiUrls.partnerUnreadCount, options: _authOptions);
      if (_handleUnauthorized(r)) return;
      final count =
          r.statusCode == 200 && r.data is Map
              ? int.tryParse("${r.data['unread_count'] ?? ''}")
              : null;
      if (count == null || count != agentUnreadCount) {
        await getAgentNotifications();
      }
    } catch (e) {
      debugPrint("!!! [agentUnreadCount] $e");
    }
  }

  // ------------------------------------------------------------------
  // GET /partner/promo-usage — "has anyone used my promo code?"
  // ------------------------------------------------------------------
  PromoUsage? promoUsage;
  List<PromoUser> promoUsers = [];
  bool loadingPromoUsage = false;

  /// [incremental]: send the last `latest_id` as `after_id` and prepend
  /// only the newer people. Returns how many are new.
  Future<int> getPromoUsage({bool incremental = false}) async {
    if (partnerData == null) return 0;
    final after = incremental ? promoUsage?.latestId : null;
    if (!incremental) {
      loadingPromoUsage = true;
      notifyListeners();
    }
    try {
      final r = await dio.get(
        ApiUrls.partnerPromoUsageGET,
        queryParameters: {"limit": 20, if (after != null) "after_id": after},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return 0;
      if (r.statusCode == 200 && r.data is Map && r.data['data'] is Map) {
        final u = PromoUsage.fromJson(Map<String, dynamic>.from(r.data['data']));
        if (after == null) {
          promoUsers = u.users;
        } else if (u.users.isNotEmpty) {
          final have = promoUsers.map((x) => x.id).toSet();
          promoUsers = [
            ...u.users.where((x) => !have.contains(x.id)),
            ...promoUsers,
          ];
        }
        promoUsage = u;
        return u.newSince ?? 0;
      }
    } catch (e) {
      debugPrint("!!! [promoUsage] $e");
    } finally {
      loadingPromoUsage = false;
      notifyListeners();
    }
    return 0;
  }

  Future<void> markAgentNotificationRead(String id) async {
    try {
      final r = await dio.patch(
        "${ApiUrls.partnerNotifications}/$id/read",
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
    } catch (e) {
      debugPrint("!!! [agentNotificationRead] $e");
    }
    await getAgentNotifications();
  }

  Future<void> markAllAgentNotificationsRead() async {
    try {
      final r = await dio.patch(
        "${ApiUrls.partnerNotifications}/read-all",
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
    } catch (e) {
      debugPrint("!!! [agentNotificationsReadAll] $e");
    }
    await getAgentNotifications();
  }

  // ------------------------------------------------------------------
  // /partner/notification-settings  (per type: in the app, by email)
  // ------------------------------------------------------------------
  List<AgentNotificationSetting> agentNotificationSettings = [];
  bool loadingAgentNotificationSettings = false;

  List<AgentNotificationSetting> _parseSettings(dynamic body) =>
      (body is Map ? body['data'] as List? ?? [] : [])
          .whereType<Map>()
          .map(
            (x) =>
                AgentNotificationSetting.fromJson(Map<String, dynamic>.from(x)),
          )
          .toList();

  Future<void> getAgentNotificationSettings() async {
    loadingAgentNotificationSettings = true;
    notifyListeners();
    try {
      final r = await dio.get(
        ApiUrls.partnerNotificationSettings,
        options: _authOptions,
      );
      debugPrint("=== [agentNotificationSettings] ${r.statusCode}");
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200) agentNotificationSettings = _parseSettings(r.data);
    } catch (e) {
      debugPrint("!!! [agentNotificationSettings] $e");
    } finally {
      loadingAgentNotificationSettings = false;
      notifyListeners();
    }
  }

  /// PUT only the channel that changed, e.g. {key: {"email": true}}.
  Future<bool> updateAgentNotificationSetting(
    BuildContext context,
    String key,
    String channel,
    bool value,
  ) async {
    try {
      final r = await dio.put(
        ApiUrls.partnerNotificationSettings,
        data: {
          "settings": {
            key: {channel: value},
          },
        },
        options: _authOptions,
      );
      debugPrint("=== [agentNotificationSettings] PUT ${r.statusCode}");
      if (_handleUnauthorized(r)) return false;
      if (r.statusCode == 200) {
        agentNotificationSettings = _parseSettings(r.data);
        notifyListeners();
        return true;
      }
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Not saved",
          message: _allErrors(r.data, "Could not save the setting."),
        );
      }
    } catch (e) {
      debugPrint("!!! [agentNotificationSettings] PUT $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Not saved",
          message: "Check your internet connection and try again.",
        );
      }
    }
    return false;
  }

  // ------------------------------------------------------------------
  // A signed-in customer becoming an agent (customer token)
  // ------------------------------------------------------------------
  Options get _customerOptions => Options(
    headers: {..._jsonHeaders, "Authorization": "Bearer ${userData?.token}"},
    validateStatus: (_) => true,
  );

  /// GET /customer/agent-status. Null when not signed in as a customer or
  /// the request failed (the landing page then shows the normal sign-up).
  Future<AgentStatus?> getAgentStatus() async {
    if (userData == null) return null;
    try {
      final r = await dio.get(
        ApiUrls.customerAgentStatusGET,
        options: _customerOptions,
      );
      debugPrint("=== [agentStatus] ${r.statusCode}: ${r.data}");
      if (r.statusCode == 200 && r.data is Map) {
        return AgentStatus.fromJson(Map<String, dynamic>.from(r.data));
      }
    } catch (e) {
      debugPrint("!!! [agentStatus] $e");
    }
    return null;
  }

  /// Every field error from a 422 `errors` map, one per line.
  String _allErrors(dynamic body, String fallback) {
    if (body is Map && body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
      return (body['errors'] as Map).values
          .map((v) => v is List && v.isNotEmpty ? "${v.first}" : "$v")
          .join("\n");
    }
    return _apiMessage(body, fallback);
  }

  /// POST /customer/become-agent with the customer token. Only `region` is
  /// required; name/phone default to the customer's on the server, and a
  /// password is only sent when the agent login should use a different one.
  /// On 201 the returned agent token becomes the partner session and the
  /// customer session stays as it is (two roles, two tokens).
  Future<void> becomeAgent(
    BuildContext context, {
    required String region,
    String? name,
    String? phone,
    String? address,
    String? company,
    String? password,
    String? passwordConfirmation,
  }) async {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();

    agentLoading = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.customerBecomeAgentPST,
        data: {
          "region": region.trim(),
          if (clean(name) != null) "name": clean(name),
          if (clean(phone) != null) "phone": clean(phone),
          if (clean(address) != null) "address": clean(address),
          if (clean(company) != null) "company": clean(company),
          if (password != null && password.isNotEmpty) ...{
            "password": password,
            "password_confirmation": passwordConfirmation ?? "",
          },
        },
        options: _customerOptions,
      );
      debugPrint("=== [becomeAgent] ${r.statusCode}: ${r.data}");
      if (!context.mounted) return;

      switch (r.statusCode) {
        case 200:
        case 201:
          await _saveSession(PartnerData.fromJson(r.data));
          getPartnerEarnings();
          if (!context.mounted) return;
          SnackbarHelper.success(
            context: context,
            title: "Welcome!",
            message: _apiMessage(r.data, "You are now an agent."),
          );
          final nav = Navigator.of(context);
          nav.popUntil((route) => route.isFirst);
          nav.push(
            MaterialPageRoute(builder: (_) => const AgentApplicationSuccess()),
          );
        case 409:
          SnackbarHelper.info(
            context: context,
            title: "Already an agent",
            message:
                "You are already an agent. Sign in to the agent side with the same email.",
            ch: Theme.of(context).colorScheme,
          );
        case 403:
          SnackbarHelper.danger(
            context: context,
            title: "Verify your account",
            message: _apiMessage(r.data, "Please verify your account first"),
          );
        case 422:
          SnackbarHelper.danger(
            context: context,
            title: "Please check the form",
            message: _allErrors(r.data, "Please check the details and try again."),
          );
        case 429:
          SnackbarHelper.danger(
            context: context,
            title: "Too many tries",
            message: "Please wait a minute and try again.",
          );
        default:
          SnackbarHelper.danger(
            context: context,
            title: "Could not become an agent",
            message: _apiMessage(r.data, "Something went wrong. Please try again."),
          );
      }
    } catch (e) {
      debugPrint("!!! [becomeAgent] $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network error",
          message: "Check your internet connection and try again.",
        );
      }
    } finally {
      agentLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // ------------------------------------------------------------------
  // Withdrawals: GET /partner/withdrawals, POST /partner/withdrawals/code,
  // POST /partner/withdrawals. Every withdrawal needs an emailed code.
  // ------------------------------------------------------------------
  List<Withdrawal> withdrawals = [];
  bool loadingWithdrawals = false;
  bool withdrawalsHasMore = false;
  int _withdrawalsPage = 1;

  /// Max for the withdraw screen: withdrawable minus transfers still on
  /// their way (from GET /partner/withdrawals). Null until loaded.
  double? withdrawAvailable;

  bool get hasPendingWithdrawal => withdrawals.any((w) => w.isPending);

  Future<void> getWithdrawals({bool refresh = true, bool silent = false}) async {
    if (partnerData == null || (!refresh && !withdrawalsHasMore)) return;
    if (!silent) {
      loadingWithdrawals = true;
      notifyListeners();
    }
    try {
      final page = refresh ? 1 : _withdrawalsPage + 1;
      final r = await dio.get(
        ApiUrls.partnerWithdrawals,
        queryParameters: {"page": page, "per_page": 20},
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) return;
      if (r.statusCode == 200 && r.data is Map) {
        final list =
            (r.data['data'] as List? ?? [])
                .whereType<Map>()
                .map((x) => Withdrawal.fromJson(Map<String, dynamic>.from(x)))
                .toList();
        withdrawals = refresh ? list : [...withdrawals, ...list];
        withdrawAvailable = double.tryParse("${r.data['available'] ?? ''}");
        final pg = r.data['pagination'];
        final last = pg is Map ? int.tryParse("${pg['last_page']}") ?? 1 : 1;
        _withdrawalsPage = page;
        withdrawalsHasMore = page < last;
      }
    } catch (e) {
      debugPrint("!!! [withdrawals] $e");
    } finally {
      loadingWithdrawals = false;
      notifyListeners();
    }
  }

  /// First error message for [field] in a 422 body, else the top message.
  ({String message, String? field}) _withdrawError(dynamic body, String fallback) {
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final key = errors.keys.first.toString();
        final v = errors[key];
        final first = v is List && v.isNotEmpty ? "${v.first}" : "$v";
        return (message: "${body['message'] ?? first}", field: key);
      }
      if (body['message'] != null) {
        return (message: "${body['message']}", field: null);
      }
    }
    return (message: fallback, field: null);
  }

  /// Step 1: email a 6-digit code for this amount (and phone, if given).
  Future<
    ({
      bool ok,
      String message,
      String? field,
      int resendAfter,
      int expiresIn,
    })
  >
  requestWithdrawalCode(double amount, {String? phone}) async {
    try {
      final r = await dio.post(
        ApiUrls.partnerWithdrawalCodePST,
        data: {
          "amount": amount,
          if (phone != null && phone.isNotEmpty) "phone": phone,
        },
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) {
        return (ok: false, message: "Please sign in again.", field: null, resendAfter: 0, expiresIn: 0);
      }
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 200) {
        final d = body['data'] is Map ? body['data'] as Map : const {};
        return (
          ok: true,
          message: "${body['message'] ?? 'We emailed you a 6-digit code.'}",
          field: null,
          resendAfter: int.tryParse("${d['resend_after_seconds'] ?? 30}") ?? 30,
          expiresIn: int.tryParse("${d['expires_in_minutes'] ?? 10}") ?? 10,
        );
      }
      final e = _withdrawError(
        r.data,
        r.statusCode == 429
            ? "Please wait a moment and try again."
            : "Couldn't send the code. Try again.",
      );
      return (ok: false, message: e.message, field: e.field, resendAfter: 0, expiresIn: 0);
    } catch (_) {
      return (
        ok: false,
        message: "Check your internet connection and try again.",
        field: null,
        resendAfter: 0,
        expiresIn: 0,
      );
    }
  }

  /// Step 2: confirm with the code (same amount and phone as step 1).
  /// 202 = the transfer started; the wallet is debited once it's confirmed.
  Future<({bool ok, String message, String? field, String? reference})>
  confirmWithdrawal(double amount, String code, {String? phone}) async {
    try {
      final r = await dio.post(
        ApiUrls.partnerWithdrawals,
        data: {
          "amount": amount,
          "code": code,
          if (phone != null && phone.isNotEmpty) "phone": phone,
        },
        options: _authOptions,
      );
      if (_handleUnauthorized(r)) {
        return (ok: false, message: "Please sign in again.", field: null, reference: null);
      }
      final body = r.data is Map ? r.data as Map : const {};
      if (r.statusCode == 202 || r.statusCode == 200) {
        final d = body['data'] is Map ? body['data'] as Map : const {};
        // Show it as "On its way" at once.
        await getWithdrawals(silent: true);
        return (
          ok: true,
          message: "${body['message'] ?? 'Withdrawal started.'}",
          field: null,
          reference: d['reference']?.toString(),
        );
      }
      final e = _withdrawError(
        r.data,
        r.statusCode == 429
            ? "Too many tries. Wait a minute and try again."
            : "Couldn't start the withdrawal. Try again.",
      );
      return (ok: false, message: e.message, field: e.field, reference: null);
    } catch (_) {
      return (
        ok: false,
        message: "Check your internet connection and try again.",
        field: null,
        reference: null,
      );
    }
  }

  Future<void> refreshAgentData() async {
    await Future.wait([
      getWithdrawals(silent: true),
      getPartnerWallet(),
      getPartnerTransactions(),
      getAgentVendors(),
      getMomoDetails(),
      getPartnerEarnings(),
      getPartnerPoints(),
      getAgentNotifications(),
    ]);
  }
}