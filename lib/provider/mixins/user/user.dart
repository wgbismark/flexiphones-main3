// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flexiphones/screens/onboarding/signup_code.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/notifications_m.dart';
import 'package:flexiphones/models/referral_m.dart';
import 'package:flexiphones/models/user_m.dart';
import 'package:flexiphones/provider/mixins/user/extra/notify.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/init_screen.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signup.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/onboarding/email_phone/init_ss_screen.dart';
import 'package:flexiphones/screens/onboarding/otp_verification.dart';
import 'package:flexiphones/screens/onboarding/forgot_password.dart';
import 'package:flexiphones/screens/onboarding/password_reset.dart';
import 'package:flexiphones/screens/onboarding/final_registration.dart';
import 'package:flexiphones/screens/onboarding/verification_success.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

  /// Google sign-in passes the Google ID token to the API, along with the
  /// account role chosen on this device. The API returns the FlexiPhones
  /// bearer token and the user profile. This flow does not store the Google
  /// ID token locally; only the app's secure session token is kept.

mixin User on BaseNotifier {
  List<String> notified = [];
  bool validGhCard = false;
  bool ghCardVrLoading = false;
  bool emailVerification = false;
  bool otpLoading = false;
  bool validOTP = false;
  bool userUDLoading = false;
  bool ghCardValidation = false;
  bool readAlLoad = false;
  final emailFocusNode = FocusNode();

  final formKey_2 = GlobalKey<FormState>();
  final formKey_3 = GlobalKey<FormState>();
  Timer? tm;
  var otpEditingController = TextEditingController();
  var ghCardEditingController = TextEditingController();
  var ghCardEditingController2 = TextEditingController();
  var emailEditingController = TextEditingController();
  var fullNameController = TextEditingController();
  var locationController = TextEditingController();
  var phoneController = TextEditingController();
  var passwordController = TextEditingController();
  var rePasswordController = TextEditingController();

  /// "Have a referral code?" at sign-up (optional).
  var referralCodeController = TextEditingController();
  //
  String countryCode = "+233";
  bool phoneInValid = false;

  var countryCodeS = FlCountryCodePicker(
    countryTextStyle: ptstyle(size: 12, weight: 300, color: Colors.black54),
    dialCodeTextStyle: ptstyle(size: 12, weight: 300, color: Colors.black54),
  ).countryCodes.firstWhere((x) => x.dialCode == "+233");

  Future<void> getUserDetails() async {
    var rtDATA = jsonDecode((await DS.storage.read(key: "user")) ?? "{}");

    userData =
        (await DS.storage.read(key: "user")) != null
            ? LoginResponse.fromJson(rtDATA)
            : null;
    notifyListeners();
  }

  Future<void> phoneSignin(BuildContext context) async {
    userUDLoading = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: 2));

    if (phoneController.text.isValidPhoneNumber) {
      phoneInValid = false;
      notifyListeners();
      NavigationHelper.push(
        context,
        OTPScreen(
          email:
              '$countryCode ${phoneController.text.trim()}',
          su: true, 
        ),
      );
    } else {
      SnackbarHelper.danger(
        context: context,
        title: "Invalid Phone Number",
        message: "Please enter a valid phone number excluding the first zero.",
      );
      phoneInValid = true;
      notifyListeners();
    }

    userUDLoading = false;
    notifyListeners();
  }

  /// POST /customer/apply-promo-code (customer token). One code per
  /// customer, ever. The agent gets points later, on this customer's first
  /// down payment. Returns true when the code was applied.
  bool applyingPromo = false;

  /// From GET /customer/my-referral: whether this customer already used a
  /// code (then the promo box is hidden) and the referring agent's name.
  bool? hasReferrer;
  String? myReferrerName;
  String? myReferrerCode;

  Future<void> getMyReferral() async {
    if (userData == null) return;
    try {
      final r = await dio.get(
        ApiUrls.myReferralGET,
        options: Options(
          headers: {
            ..._jsonHeaders,
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (_) => true,
        ),
      );
      debugPrint("=== [myReferral] ${r.statusCode}: ${r.data}");
      if (r.statusCode == 200 && r.data is Map && r.data["data"] is Map) {
        final d = r.data["data"] as Map;
        final agent = d["agent"] is Map ? d["agent"] as Map : null;
        hasReferrer = d["has_referrer"] == true;
        myReferrerName = agent?["name"]?.toString();
        myReferrerCode = agent?["promo_code"]?.toString();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("!!! [myReferral] $e");
    }
  }

  // ------------------------------------------------------------------
  // Friend referral code + points wallet (customer token). Different from
  // the agent promo code: a customer may use one of each.
  // ------------------------------------------------------------------
  ReferralSummary? referral;
  bool loadingReferral = false;
  bool creatingReferralCode = false;
  bool applyingReferral = false;

  Options get _customerAuth => Options(
    headers: {..._jsonHeaders, 'Authorization': 'Bearer ${userData?.token}'},
    validateStatus: (_) => true,
  );

  /// GET /customer/referral — the home card.
  Future<void> getReferral() async {
    if (userData == null) return;
    loadingReferral = true;
    notifyListeners();
    try {
      final r = await dio.get(ApiUrls.referralGET, options: _customerAuth);
      if (r.statusCode == 200 && r.data is Map && r.data['data'] is Map) {
        referral = ReferralSummary.fromJson(
          Map<String, dynamic>.from(r.data['data']),
        );
      }
    } catch (e) {
      debugPrint("!!! [referral] $e");
    } finally {
      loadingReferral = false;
      notifyListeners();
    }
  }

  /// POST /customer/referral-code — safe to repeat; the code never changes.
  Future<void> createReferralCode(BuildContext context) async {
    if (creatingReferralCode) return;
    creatingReferralCode = true;
    notifyListeners();
    try {
      final r = await dio.post(ApiUrls.referralCodePST, options: _customerAuth);
      if (!context.mounted) return;
      if ((r.statusCode == 200 || r.statusCode == 201) &&
          r.data is Map &&
          r.data['data'] is Map) {
        referral = ReferralSummary.fromJson(
          Map<String, dynamic>.from(r.data['data']),
        );
        SnackbarHelper.success(
          context: context,
          title: "Referral Code",
          message: "${r.data['message'] ?? 'Your referral code is ready.'}",
        );
      } else {
        SnackbarHelper.danger(
          context: context,
          title: "Referral Code",
          message: _errorText(r.data, "Could not create your code. Try again."),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      creatingReferralCode = false;
      notifyListeners();
    }
  }

  /// POST /customer/apply-referral-code — once, ever. True when applied.
  Future<bool> applyReferralCode(BuildContext context, String code) async {
    final c = code.trim();
    if (c.isEmpty) {
      SnackbarHelper.danger(
        context: context,
        title: "Referral Code",
        message: "Enter your friend's referral code",
      );
      return false;
    }
    applyingReferral = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.applyReferralCodePST,
        data: {"referral_code": c},
        options: _customerAuth,
      );
      if (!context.mounted) return false;
      final status = r.statusCode ?? 0;
      if (status == 200) {
        SnackbarHelper.success(
          context: context,
          title: "Referral Code Applied",
          message: "${r.data is Map ? r.data['message'] : 'Referral code applied.'}",
        );
        await getReferral();
        return true;
      }
      if (status == 409) await getReferral();
      SnackbarHelper.danger(
        context: context,
        title: switch (status) {
          404 => "Invalid Code",
          409 => "Already Used",
          403 => "Code Not Active",
          429 => "Too Many Tries",
          _ => "Code Not Applied",
        },
        message:
            status == 429
                ? "Please wait a minute and try again"
                : _errorText(r.data, "Check the code and try again"),
      );
      return false;
    } catch (_) {
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
      return false;
    } finally {
      applyingReferral = false;
      notifyListeners();
    }
  }

  /// GET /customer/referrals — friends I referred (first names only).
  List<ReferredFriend> referredFriends = [];
  bool loadingFriends = false;
  bool friendsHasMore = false;
  int _friendsPage = 1;

  Future<void> getReferredFriends({bool refresh = true}) async {
    if (userData == null || (!refresh && !friendsHasMore)) return;
    loadingFriends = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _friendsPage + 1;
      final r = await dio.get(
        ApiUrls.referralsGET,
        queryParameters: {"page": page, "per_page": 20},
        options: _customerAuth,
      );
      final data = r.data is Map ? r.data['data'] : null;
      if (r.statusCode == 200 && data is Map && data['referrals'] is Map) {
        final pg = data['referrals'] as Map;
        final list =
            (pg['data'] as List? ?? [])
                .whereType<Map>()
                .map((x) => ReferredFriend.fromJson(Map<String, dynamic>.from(x)))
                .toList();
        referredFriends = refresh ? list : [...referredFriends, ...list];
        _friendsPage = page;
        friendsHasMore = page < (int.tryParse("${pg['last_page']}") ?? 1);
      }
    } catch (e) {
      debugPrint("!!! [referrals] $e");
    } finally {
      loadingFriends = false;
      notifyListeners();
    }
  }

  /// GET /customer/points — balance + history.
  List<CustomerPointsEntry> customerPoints = [];
  int? customerPointsBalance;
  bool loadingCustomerPoints = false;
  bool customerPointsHasMore = false;
  int _customerPointsPage = 1;

  Future<void> getCustomerPoints({bool refresh = true}) async {
    if (userData == null || (!refresh && !customerPointsHasMore)) return;
    loadingCustomerPoints = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : _customerPointsPage + 1;
      final r = await dio.get(
        ApiUrls.pointsGET,
        queryParameters: {"page": page, "per_page": 20},
        options: _customerAuth,
      );
      final data = r.data is Map ? r.data['data'] : null;
      if (r.statusCode == 200 && data is Map) {
        customerPointsBalance = int.tryParse("${data['points'] ?? ''}");
        final pg = data['history'] is Map ? data['history'] as Map : const {};
        final list =
            (pg['data'] as List? ?? [])
                .whereType<Map>()
                .map(
                  (x) => CustomerPointsEntry.fromJson(Map<String, dynamic>.from(x)),
                )
                .toList();
        customerPoints = refresh ? list : [...customerPoints, ...list];
        _customerPointsPage = page;
        customerPointsHasMore =
            page < (int.tryParse("${pg['last_page'] ?? 1}") ?? 1);
      }
    } catch (e) {
      debugPrint("!!! [points] $e");
    } finally {
      loadingCustomerPoints = false;
      notifyListeners();
    }
  }

  Future<bool> applyPromoCode(BuildContext context, String code) async {
    final promo = code.trim().toUpperCase();
    if (promo.isEmpty) {
      SnackbarHelper.danger(
        context: context,
        title: "Promo Code",
        message: "Enter the agent's promo code",
      );
      return false;
    }
    applyingPromo = true;
    notifyListeners();
    try {
      final r = await dio.post(
        ApiUrls.applyPromoCodePST,
        data: {"promo_code": promo},
        options: Options(
          headers: {
            ..._jsonHeaders,
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (_) => true,
        ),
      );
      debugPrint("=== [applyPromo] ${r.statusCode}: ${r.data}");
      if (!context.mounted) return false;

      final status = r.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        // Show the agent's name (top-level `agent`; older responses only had
        // data.referredByPartner).
        final body = r.data is Map ? r.data as Map : const {};
        final data = body["data"] is Map ? body["data"] as Map : const {};
        final agentMap =
            body["agent"] is Map
                ? body["agent"] as Map
                : data["referredByPartner"] is Map
                ? data["referredByPartner"] as Map
                : body["referredByPartner"] is Map
                ? body["referredByPartner"] as Map
                : const {};
        final agent = agentMap["name"]?.toString() ?? "";
        myReferrerName = agent.isEmpty ? null : agent;
        hasReferrer = true;
        notifyListeners();
        SnackbarHelper.success(
          context: context,
          title: "Promo Code Applied",
          message:
              agent.isEmpty
                  ? "Your promo code was applied."
                  : "You were referred by $agent.",
        );
        return true;
      }
      final (title, message) = switch (status) {
        404 => ("Invalid Code", "Invalid promo code"),
        403 => ("Code Not Active", "This promo code is no longer active"),
        409 => ("Already Used", "You have already used a referral code"),
        422 => (
          "Promo Code Not Applied",
          _errorText(r.data, "You cannot use your own promo code"),
        ),
        429 => ("Too Many Tries", "Please wait a minute and try again"),
        _ => (
          "Promo Code Not Applied",
          _errorText(r.data, "Check the code and try again"),
        ),
      };
      if (status == 409) hasReferrer = true;
      SnackbarHelper.danger(context: context, title: title, message: message);
      return false;
    } catch (e) {
      debugPrint("!!! [applyPromo] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
      return false;
    } finally {
      applyingPromo = false;
      notifyListeners();
    }
  }

  /// Signs the same email/password into the agent (partner) account and
  /// saves that session. Overridden by the Agent mixin; `message` is only
  /// set when the agent account exists but can't sign in (e.g. inactive).
  Future<({bool ok, String? message})> partnerSignIn(
    String email,
    String password,
  ) async => (ok: false, message: null);

  /// One sign-in for customers and agents: both logins are tried with the
  /// same details, and the app opens whichever account(s) exist.
  /// Saves a Google sign-in for the agent role. Overridden by the Agent
  /// mixin (which owns the partner session).
  Future<void> saveGoogleAgentSession(Map<String, dynamic> payload) async {}

  /// Bumped when an email/password sign-in is refused, so the sign-in
  /// screen can draw attention to "Continue with Google" (the server's
  /// message mentions it; we never guess account types).
  int signInRefusals = 0;

  /// Saves a customer session handed over by the agent side.
  Future<void> saveCustomerSession(Map<String, dynamic> payload) async {
    await DS.storage.write(key: "user", value: jsonEncode(stampExpiry(payload)));
    await getUserDetails();
  }

  /// After Google/Apple: the required form (address / region) first, then
  /// the skippable phone screen. Uses the app navigator because the sign-in
  /// screen is already gone.
  /// After a Google/Apple sign-up: ask for the phone number once the
  /// app has finished loading (the loading screen clears every page, so
  /// InitScreen opens it). Skippable; address can be added later.
  ({bool agent, String? advice})? pendingPhonePrompt;

  void _afterSocialSignUp({
    required bool agent,
    required bool needsProfile,
    required bool needsPhone,
    String? advice,
  }) {
    if (needsPhone || needsProfile) {
      pendingPhonePrompt = (agent: agent, advice: advice);
    }
  }

  /// "How do you want to join?" for a new Google/Apple person.
  /// Returns "customer", "agent" or null (closed).
  Future<String?> _askRole(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ch = Theme.of(ctx).colorScheme;
        Widget option(String value, IconData icon, String title, String sub) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(ctx).pop(value),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0071E3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: const Color(0xFF0071E3)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: ptstyle(size: 15, weight: 700, color: ch.onSurface)),
                              Text(sub, style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: ch.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            );
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("How do you want to join?", style: ptstyle(size: 19, weight: 700, color: ch.onSurface)),
                const SizedBox(height: 4),
                Text("This is a new account. You can add the other side later.", style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant)),
                const SizedBox(height: 16),
                option("customer", Icons.phone_iphone_rounded, "I want to buy a phone", "Customer: shop and pay daily"),
                option("agent", Icons.workspace_premium_rounded, "I want to earn as an agent", "Agent: bring shops and customers"),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> googleSignIn(BuildContext context, {
    required String idToken,
    /// null on the plain sign-in button: the server signs them in to the
    /// account they have (one email = one person) or asks "needs_role".
    String? as,
    String? googleIdToken,
    String provider = "google",
    String? name,
  }) async {
    final apple = provider == "apple";
    final label = apple ? "Apple" : "Google";
    if (idToken.trim().isEmpty) {
      SnackbarHelper.danger(
        context: context,
        title: "$label sign-in failed",
        message: "No sign-in token was returned. Please try again.",
      );
      return;
    }

    userUDLoading = true;
    notifyListeners();

    try {
      Future<Response> send(String token, {String? code}) => dio.post(
        apple ? ApiUrls.appleAuthPST : ApiUrls.googleAuthPST,
        data: {
          "id_token": token,
          if (code != null) "code": code,
          if (as != null) "as": as,
          if (apple && (name ?? "").trim().isNotEmpty) "name": name!.trim(),
        },
        options: Options(
          headers: _jsonHeaders,
          validateStatus: (status) => true,
        ),
      );

      // The Firebase ID token first; if the server refuses it, the plain
      // Google ID token (some setups verify that one instead).
      var usedToken = idToken;
      var r = await send(idToken);
      debugPrint("=== [googleAuth] firebase token -> ${r.statusCode}: ${r.data}");
      final first = r.statusCode ?? 0;
      if ((first == 400 || first == 401 || first == 422) &&
          googleIdToken != null &&
          googleIdToken.isNotEmpty &&
          googleIdToken != idToken) {
        usedToken = googleIdToken;
        r = await send(googleIdToken);
        debugPrint("=== [googleAuth] google token -> ${r.statusCode}: ${r.data}");
      }

      if (!context.mounted) return;

      final code = r.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        var body = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
        // Nobody has this Google/Apple account yet: ask who they are, then
        // call again with that side (that creates the account).
        if (body["status"] == "needs_role" || body["needs_role"] == true) {
          userUDLoading = false;
          notifyListeners();
          final pick = await _askRole(context);
          if (pick == null || !context.mounted) return;
          return googleSignIn(
            context,
            idToken: idToken,
            as: pick,
            googleIdToken: googleIdToken,
            provider: provider,
            name: name,
          );
        }
        // A NEW account: the server emailed a 6-digit code first (anti-bot).
        // Same request again with `code`; nothing is created until then.
        if (body["status"] == "needs_code" || body["needs_code"] == true) {
          userUDLoading = false;
          notifyListeners();
          final tokenForCode = usedToken;
          final done = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder:
                  (_) => SignupCodeScreen(
                    info: body,
                    submit: (c) => send(tokenForCode, code: c),
                    resend: () => send(tokenForCode),
                  ),
            ),
          );
          if (done == null || !context.mounted) return;
          body = done;
          userUDLoading = true;
          notifyListeners();
        }
        // Trust the side the server signed them in to, not the one asked.
        final role = body["role"]?.toString();
        final isAgent =
            role == null ? as == "agent" : (role == "partner" || role == "agent");
        if (body["role_switched"] == true &&
            (body["message"] ?? "").toString().isNotEmpty) {
          SnackbarHelper.success(
            context: context,
            title: isAgent ? "Signed in as an agent" : "Signed in as a customer",
            message: body["message"].toString(),
          );
        }
        final authData = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
        final token = authData['token'] ?? body['token'];
        final userPayload = authData['user'] is Map ? Map<String, dynamic>.from(authData['user'] as Map) : authData;

        if (token == null || token.toString().isEmpty) {
          SnackbarHelper.danger(
            context: context,
            title: "Sign-in incomplete",
            message: _errorText(r.data, "$label sign-in returned no FlexiPhones token."),
          );
          return;
        }

        final payload = {
          'status': body['status'] ?? 'success',
          'message': body['message'] ?? 'Logged in with Google.',
          'token': token,
          'expires_in': authData['expires_in'] ?? body['expires_in'],
          'data': userPayload,
        };

        final needsProfile = body['needs_profile'] == true;
        final needsPhone = body['needs_phone'] == true;
        final advice = body['phone_advice']?.toString();
        // An agent token is a partner session, not a customer one.
        if (isAgent) {
          await saveGoogleAgentSession(payload);
          if (!context.mounted) return;
          NavigationHelper.pushAndRemoveUntil(
            context,
            const InitScreen(openAgent: true),
          );
          _afterSocialSignUp(
            agent: true,
            needsProfile: needsProfile,
            needsPhone: needsPhone,
            advice: advice,
          );
          return;
        }

        await DS.storage.write(key: "user", value: jsonEncode(stampExpiry(payload)));
        await getUserDetails();

        if (!context.mounted) return;
        NavigationHelper.pushAndRemoveUntil(context, InitScreen());
        _afterSocialSignUp(
          agent: false,
          needsProfile: needsProfile,
          needsPhone: needsPhone,
          advice: advice,
        );
        return;
      }

      SnackbarHelper.danger(
        context: context,
        title: as == "agent" ? "Agent sign-in failed" : "Sign-in failed",
        message:
            "${_errorText(r.data, "$label sign-in could not continue.")} (server $code)",
      );
    } catch (e) {
      debugPrint("!!! [googleSignIn] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      userUDLoading = false;
      notifyListeners();
    }
  }

  Future<void> emailSignIn(BuildContext context) async {
    await DS.storage.deleteAll();
    userUDLoading = true;
    notifyListeners();

    final email = emailEditingController.text.trim();
    final password = passwordController.text.trim();

    try {
      final results = await Future.wait([
        // "as": "customer" so someone who is both gets the customer token
        // here; the agent token comes from partnerSignIn alongside.
        dio.post(
          ApiUrls.loginAsPST,
          data: {"email": email, "password": password, "as": "customer"},
          options: Options(
            headers: _jsonHeaders,
            validateStatus: (status) => true,
          ),
        ),
        partnerSignIn(email, password),
      ]);
      final response = results[0] as Response;
      final partner = results[1] as ({bool ok, String? message});
      debugPrint(
        "=== [signIn] customer=${response.statusCode} agent=${partner.ok}",
      );
      if (!context.mounted) return;

      if (response.statusCode == 200 || partner.ok) {
        if (response.statusCode == 200) {
          await DS.storage.write(key: "user", value: jsonEncode(stampExpiry(response.data)));
          await getUserDetails();
        }
        if (!context.mounted) return;
        // Agent-only account: go straight to the agent dashboard.
        NavigationHelper.pushAndRemoveUntil(
          context,
          InitScreen(openAgent: response.statusCode != 200),
        );

        Timer(Duration(seconds: 3), () {
          emailEditingController.clear();
          passwordController.clear();
          rePasswordController.clear();
          fullNameController.clear();
          locationController.clear();
          phoneController.clear();
        });
      } else {
        // Same answer for every failure (the server never says why);
        // show its message as is and point at "Continue with Google".
        signInRefusals++;
        SnackbarHelper.danger(
          context: context,
          title: "Failed to sign in",
          message:
              partner.message ??
              _errorText(response.data, "Invalid email or password."),
        );
      }
    } catch (e) {
      debugPrint("!!! [signIn] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      userUDLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmail(BuildContext context, ColorScheme ch) async {
    emailFocusNode.unfocus();
    // Android keyboards often append a trailing space after autocomplete,
    // which made the untrimmed text fail validation.
    final email = emailEditingController.text.trim();
    emailEditingController.text = email;
    if (!email.isValidEmail) {
      if (email.isEmpty) {
        emailFocusNode.requestFocus();
        SnackbarHelper.danger(
          context: context,
          title: "Email Required",
          message: "Enter your email to sign up",
        );
      } else {
        Notify.invalidEmail(context);
      }
      return;
    }
    otpEditingController.clear();
    emailVerification = true;
    notifyListeners();

    debugPrint("=== [verifyEmail] REQUEST ===");
    debugPrint("URL: ${ApiUrls.emailVerificationPST}");
    debugPrint("Data: {email: $email}");

    try {
      var response = await dio.post(
        ApiUrls.emailVerificationPST,
        data: {"email": email},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint("=== [verifyEmail] RESPONSE ===");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.data}");

      if (!context.mounted) return;
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        Notify.validEmail(context, ch);
        NavigationHelper.push(context, OTPScreen(email: email, su: true));
      } else {
        // The body is not always JSON (e.g. an HTML error page), so indexing
        // it blindly threw and the tap looked like it did nothing.
        final body = response.data;
        final message = body is Map && body["message"] != null
            ? "${body["message"]}"
            : "Could not verify email (error $status). Please try again.";
        SnackbarHelper.info(
          context: context,
          title: status == 422 ? "Email Registered" : "Sign Up Failed",
          message: message,
          ch: ch,
        );
      }
    } catch (e) {
      debugPrint("!!! [verifyEmail] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      emailVerification = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP(BuildContext context, {required bool su}) async {
    if (!su) return _verifyResetOTP(context);
    otpLoading = true;
    notifyListeners();
    try {
      var response = await dio.post(
        ApiUrls.otpVerificationPST,
        data: {
          "email": emailEditingController.text.trim(),
          "otp": otpEditingController.text,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        validOTP = true;
        notifyListeners();
        SnackbarHelper.success(
          context: context,
          title: "OTP Verified!",
          message: "Email verified successfully.",
        );

        if (su) {
          NavigationHelper.push(context, UserCredentialPage());
        } else {
          NavigationHelper.pushAndRemoveUntil(context, ResetPassword());
        }
      } else {
        validOTP = false;
        notifyListeners();
        HapticFeedback.vibrate();
        Notify.invalidOTP(context);
      }

      otpLoading = false;
      notifyListeners();
    } catch (e) {
      otpLoading = false;
      notifyListeners();
    }
  }

  Future<void> finalRegistration(BuildContext context) async {
    userUDLoading = true;
    notifyListeners();
    Response response;

    if (formKey_2.currentState!.validate()) {
      response = await dio.post(
        ApiUrls.finalRegistrationPST,
        data: {
          "email": emailEditingController.text.trim(),
          "name": fullNameController.text.trim(),
          "phone": "0${phoneController.text.trim()}",
          "address": locationController.text.trim(),
          "password": passwordController.text.trim(),
          "password_confirmation": rePasswordController.text.trim(),
          // Optional; a wrong code is ignored by the server.
          if (referralCodeController.text.trim().isNotEmpty)
            "referral_code": referralCodeController.text.trim(),
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => true,
        ),
      );
      userUDLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        await DS.storage.write(key: "user", value: jsonEncode(stampExpiry(response.data)));

        // Ghana Card linking is optional at sign-up; customers can do it
        // later from their profile (GHCardVerification(lateVerification)).
        NavigationHelper.pushAndRemoveUntil(context, InitScreen());

        Timer(Duration(seconds: 3), () {
          emailEditingController.clear();
          passwordController.clear();
          rePasswordController.clear();
          fullNameController.clear();
          locationController.clear();
          phoneController.clear();
        });

        return;
      }

      if (response.data["message"].contains("already completed")) {
        await getUserDetails();
        NavigationHelper.push(context, EmailSignin());
        userUDLoading = false;
        notifyListeners();
        return;
      }
      SnackbarHelper.danger(
        context: context,
        title: "Registration Failed",
        message: "${response.data["message"]}",
      );
    }

    userUDLoading = false;
    notifyListeners();
  }

  Future<void> validateGHC(BuildContext context) async {
    ghCardVrLoading = true;
    notifyListeners();

    try {
      var response = await dio.post(
        "${ApiUrls.updateGHCard}${userData!.data.id}",
        data: {
          "ghana_card":
              "GHA-${ghCardEditingController.text.trim()}-${ghCardEditingController2.text.trim()}",
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        var newData = {
          "status": response.data["status"],
          "message": response.data["message"],
          "token": userData?.token,
          "expires_at": userData?.expiresAt?.toUtc().toIso8601String(),
          "data": response.data["data"],
        };

        await DS.storage.write(key: "user", value: jsonEncode(newData));
        await getUserDetails();

        SnackbarHelper.success(
          context: context,
          title: "Ghana Card Updated",
          message: "You've successfully verified your ghana card",
        );

        NavigationHelper.pushAndRemoveUntil(context, VerificationSuccess());
      }
    } catch (_) {}

    ghCardVrLoading = false;
    notifyListeners();
  }

  /// FIX:
  /// - No longer assumes response.data["data"] exists in exactly that
  ///   shape. Some endpoints wrap the updated record under "data",
  ///   some under "customer", some return it flat at the top level.
  ///   We try each in order; if none match, we still know the update
  ///   itself succeeded (status 200), so we patch the name locally
  ///   from what we sent rather than silently failing.
  /// - Real try/catch branches (DioException + generic) instead of a
  ///   bare `catch (_) {}` — every failure path now shows a Snackbar
  ///   and logs to console, so this can never again look like "nothing
  ///   happened" when it actually errored.
  /// - Pops the dialog itself on success instead of stacking a whole
  ///   separate InitScreen splash/reload flow on top of an open modal.
  Future<void> updateName(BuildContext context) async {
    dialogueLoading = true;
    notifyListeners();

    debugPrint("=== [updateName] REQUEST ===");
    debugPrint("URL: ${ApiUrls.updateUSER}");
    debugPrint("Data: {name: ${fullNameController.text.trim()}}");
    debugPrint("=============================");

    try {
      var response = await dio.post(
        ApiUrls.updateUSER,
        data: {"name": fullNameController.text.trim()},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint("=== [updateName] RESPONSE ===");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.data}");
      debugPrint("==============================");

      if (response.statusCode == 200) {
        Map<String, dynamic>? updated;
        final body = response.data;
        if (body is Map<String, dynamic>) {
          if (body["data"] is Map<String, dynamic>) {
            updated = body["data"];
          } else if (body["customer"] is Map<String, dynamic>) {
            updated = body["customer"];
          } else if (body["name"] != null) {
            updated = body;
          }
        }

        if (updated == null) {
          debugPrint(
            "!!! [updateName] 200 OK but couldn't find the updated user object "
            "in the response body — falling back to a local name patch.",
          );
          updated = userData!.data.toJson();
          updated["name"] = fullNameController.text.trim();
        }

        var newData = {
          "status": userData!.status,
          "message": userData!.message,
          "token": userData?.token,
          "expires_at": userData?.expiresAt?.toUtc().toIso8601String(),
          "data": updated,
        };

        await DS.storage.write(key: "user", value: jsonEncode(newData));
        await getUserDetails();
        fullNameController.clear();

        if (!context.mounted) return;
        Navigator.of(context).pop();

        SnackbarHelper.success(
          context: context,
          title: "Profile updated",
          message: "Your Name has been updated successfully.",
        );
      } else {
        String message = "Something went wrong. Please try again.";
        final body = response.data;
        if (body is Map && body["message"] != null) {
          message = "${body["message"]}";
        }
        debugPrint(
          ">>> [updateName] FAILED — status ${response.statusCode}, message: $message",
        );

        if (!context.mounted) return;
        SnackbarHelper.danger(
          context: context,
          title: "Failed Update",
          message: message,
        );
      }
    } on DioException catch (e) {
      debugPrint("!!! [updateName] DioException");
      debugPrint("!!! URL: ${e.requestOptions.uri}");
      debugPrint("!!! Status: ${e.response?.statusCode}");
      debugPrint("!!! Body: ${e.response?.data}");
      debugPrint("!!! Message: ${e.message}");

      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed Update",
        message:
            e.response?.data is Map
                ? "${e.response?.data["message"] ?? e.message}"
                : "${e.message ?? "Network error, please try again."}",
      );
    } catch (e) {
      debugPrint("!!! [updateName] Unexpected error: $e");
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed Update",
        message: "Something went wrong. Please try again.",
      );
    }

    dialogueLoading = false;
    notifyListeners();
  }

  /// Same shape as [updateName] above, for the phone number field.
  /// Sends the number the same way finalRegistration does — a leading
  /// "0" instead of the "+233" country code — since that's the format
  /// the backend already accepts elsewhere in this app.
  Future<void> updatePhone(BuildContext context) async {
    dialogueLoading = true;
    notifyListeners();

    debugPrint("=== [updatePhone] REQUEST ===");
    debugPrint("URL: ${ApiUrls.updateUSER}");
    debugPrint("Data: {phone: 0${phoneController.text.trim()}}");
    debugPrint("==============================");

    try {
      var response = await dio.post(
        ApiUrls.updateUSER,
        data: {"phone": "0${phoneController.text.trim()}"},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (status) => true,
        ),
      );

      debugPrint("=== [updatePhone] RESPONSE ===");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.data}");
      debugPrint("===============================");

      if (response.statusCode == 200) {
        Map<String, dynamic>? updated;
        final body = response.data;
        if (body is Map<String, dynamic>) {
          if (body["data"] is Map<String, dynamic>) {
            updated = body["data"];
          } else if (body["customer"] is Map<String, dynamic>) {
            updated = body["customer"];
          } else if (body["phone"] != null) {
            updated = body;
          }
        }

        if (updated == null) {
          debugPrint(
            "!!! [updatePhone] 200 OK but couldn't find the updated user object "
            "in the response body — falling back to a local phone patch.",
          );
          updated = userData!.data.toJson();
          updated["phone"] = "0${phoneController.text.trim()}";
        }

        var newData = {
          "status": userData!.status,
          "message": userData!.message,
          "token": userData?.token,
          "expires_at": userData?.expiresAt?.toUtc().toIso8601String(),
          "data": updated,
        };

        await DS.storage.write(key: "user", value: jsonEncode(newData));
        await getUserDetails();
        phoneController.clear();
        phoneInValid = false;

        if (!context.mounted) return;
        Navigator.of(context).pop();

        SnackbarHelper.success(
          context: context,
          title: "Profile updated",
          message: "Your phone number has been updated successfully.",
        );
      } else {
        String message = "Something went wrong. Please try again.";
        final body = response.data;
        if (body is Map && body["message"] != null) {
          message = "${body["message"]}";
        }
        debugPrint(
          ">>> [updatePhone] FAILED — status ${response.statusCode}, message: $message",
        );

        if (!context.mounted) return;
        SnackbarHelper.danger(
          context: context,
          title: "Failed Update",
          message: message,
        );
      }
    } on DioException catch (e) {
      debugPrint("!!! [updatePhone] DioException");
      debugPrint("!!! URL: ${e.requestOptions.uri}");
      debugPrint("!!! Status: ${e.response?.statusCode}");
      debugPrint("!!! Body: ${e.response?.data}");
      debugPrint("!!! Message: ${e.message}");

      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed Update",
        message:
            e.response?.data is Map
                ? "${e.response?.data["message"] ?? e.message}"
                : "${e.message ?? "Network error, please try again."}",
      );
    } catch (e) {
      debugPrint("!!! [updatePhone] Unexpected error: $e");
      if (!context.mounted) return;
      SnackbarHelper.danger(
        context: context,
        title: "Failed Update",
        message: "Something went wrong. Please try again.",
      );
    }

    dialogueLoading = false;
    notifyListeners();
  }

  Future<void> checkValidGhCard() async {
    final prefs = await SharedPreferences.getInstance();
    validGhCard = prefs.getBool("gh-card-verified") ?? false;
  }

  // ── Forgot password ─────────────────────────────────────────────────────
  // 1. forgot-password emails a 5-digit code (valid 10 minutes)
  // 2. verify-reset-otp checks it without using it up
  // 3. create-new-password needs the same code again, and uses it up
  // Status codes: 400 wrong code, 410 code expired/used/cancelled after
  // 5 wrong tries (start again), 422 field errors, 429 rate limited.

  static const _jsonHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  /// True while resetting an agent (partner) password: same three steps,
  /// /partner/... endpoints. Set by [ForgotPassword].
  bool resetForAgent = false;

  String get _forgotUrl =>
      resetForAgent
          ? ApiUrls.partnerForgotPasswordPST
          : ApiUrls.forgotPasswordPST;
  String get _verifyResetUrl =>
      resetForAgent
          ? ApiUrls.partnerVerifyResetOtpPST
          : ApiUrls.verifyResetOtpPST;
  String get _newPasswordUrl =>
      resetForAgent
          ? ApiUrls.partnerResetPasswordPST
          : ApiUrls.resetPasswordPST;

  /// First message of each field in a Laravel 422 `errors` map, else
  /// the top-level `message`.
  String _errorText(dynamic body, String fallback) {
    if (body is Map) {
      final errors = body["errors"];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .map((v) => v is List && v.isNotEmpty ? "${v.first}" : "$v")
            .join("\n");
      }
      if (body["message"] != null) return "${body["message"]}";
    }
    return fallback;
  }

  /// Code expired, used up or cancelled: send the customer back to step 1.
  void _restartReset(BuildContext context, String message) {
    otpEditingController.clear();
    SnackbarHelper.danger(
      context: context,
      title: "Code Expired",
      message: message,
    );
    NavigationHelper.pushAndRemoveUntil(
      context,
      ForgotPassword(agent: resetForAgent),
    );
  }

  /// Step 1. With [openOtp] false (Resend on the code screen) the code
  /// screen isn't pushed again.
  Future<void> forgottenPassword(
    BuildContext context,
    ColorScheme ch, {
    bool openOtp = true,
  }) async {
    emailFocusNode.unfocus();
    final email = emailEditingController.text.trim();
    emailEditingController.text = email;
    if (!email.isValidEmail) {
      email.isEmpty
          ? emailFocusNode.requestFocus()
          : Notify.invalidEmail(context);
      return;
    }
    otpEditingController.clear();
    emailVerification = true;
    notifyListeners();

    try {
      var response = await dio.post(
        _forgotUrl,
        data: {"email": email},
        options: Options(headers: _jsonHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [forgotPassword] ${response.statusCode}: ${response.data}");
      if (!context.mounted) return;

      switch (response.statusCode) {
        case 200:
          Notify.validEmail(context, ch);
          if (openOtp) {
            NavigationHelper.push(context, OTPScreen(email: email, su: false));
          }
        case 422:
          SnackbarHelper.danger(
            context: context,
            title: "Account Not Found",
            message: "There is no account with that email",
          );
        case 403:
          // New backend: email verified but sign-up never finished, so
          // signing up again lets them finish. The current backend still
          // sends "account is not active" for 403, which must NOT redirect
          // (customer sign-up clears the saved login). Decide by the message.
          final message = _errorText(
            response.data,
            "Your account is not active yet",
          );
          final unfinished = message.toLowerCase().contains("sign up");
          SnackbarHelper.danger(
            context: context,
            title: unfinished ? "Finish Signing Up" : "Account Not Active",
            message: message,
          );
          if (unfinished) {
            NavigationHelper.push(
              context,
              resetForAgent ? const AgentSignup() : const InitUserSSScreen(),
            );
          }
        case 429:
          SnackbarHelper.danger(
            context: context,
            title: "Too Many Requests",
            message: "Please wait a minute and try again",
          );
        default:
          SnackbarHelper.danger(
            context: context,
            title: "Email Not Sent",
            message: "We couldn't send the code. Please try again.",
          );
      }
    } catch (e) {
      debugPrint("!!! [forgotPassword] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      emailVerification = false;
      notifyListeners();
    }
  }

  /// Step 2. Checks the code; it stays in [otpEditingController] for step 3.
  Future<void> _verifyResetOTP(BuildContext context) async {
    otpLoading = true;
    notifyListeners();
    try {
      final body = {
        "email": emailEditingController.text.trim(),
        "otp": otpEditingController.text.trim(),
      };
      var response = await dio.post(
        _verifyResetUrl,
        data: body,
        options: Options(headers: _jsonHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [verifyResetOtp] ${response.statusCode}: ${response.data}");

      // verify-reset-otp isn't on the server until the backend update is
      // deployed (it 404s). Until then, behave as before: customers check
      // the code with email-otp-verification; agents go straight to the
      // new-password step (create-new-password still checks the code).
      if (response.statusCode == 404) {
        if (resetForAgent) {
          response = Response(
            requestOptions: response.requestOptions,
            statusCode: 200,
          );
        } else {
          response = await dio.post(
            ApiUrls.otpVerificationPST,
            data: body,
            options: Options(
              headers: _jsonHeaders,
              validateStatus: (_) => true,
            ),
          );
          debugPrint(
            "=== [verifyResetOtp] fallback ${response.statusCode}: ${response.data}",
          );
        }
      }
      if (!context.mounted) return;

      validOTP = response.statusCode == 200;
      switch (response.statusCode) {
        case 200:
          SnackbarHelper.success(
            context: context,
            title: "Code Accepted",
            message: "Now choose a new password.",
          );
          NavigationHelper.push(context, ResetPassword());
        case 410:
          _restartReset(
            context,
            _errorText(response.data, "This code has expired. Request a new one."),
          );
        case 429:
          SnackbarHelper.danger(
            context: context,
            title: "Too Many Attempts",
            message: "Please wait a minute and try again",
          );
        case 422:
          HapticFeedback.vibrate();
          SnackbarHelper.danger(
            context: context,
            title: "Invalid Code",
            message: _errorText(response.data, "The code must be 5 digits"),
          );
        default: // 400 wrong code
          HapticFeedback.vibrate();
          Notify.invalidOTP(context);
      }
    } catch (e) {
      debugPrint("!!! [verifyResetOtp] ERROR: $e");
      validOTP = false;
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      otpLoading = false;
      notifyListeners();
    }
  }

  /// Step 3. Sends the code from step 2 again with the new password.
  Future<void> resetPassword(BuildContext context, ColorScheme ch) async {
    if (!formKey_3.currentState!.validate()) return;
    userUDLoading = true;
    notifyListeners();

    try {
      var response = await dio.post(
        _newPasswordUrl,
        data: {
          "email": emailEditingController.text.trim(),
          "otp": otpEditingController.text.trim(),
          "password": passwordController.text.trim(),
          "password_confirmation": rePasswordController.text.trim(),
        },
        options: Options(headers: _jsonHeaders, validateStatus: (_) => true),
      );
      debugPrint("=== [resetPassword] ${response.statusCode}: ${response.data}");
      if (!context.mounted) return;

      switch (response.statusCode) {
        case 200:
          SnackbarHelper.success(
            context: context,
            title: "Password Changed!",
            message: "You've successfully reset your password.",
          );
          otpEditingController.clear();
          userData == null
              ? NavigationHelper.pushAndRemoveUntil(context, EmailSignin())
              : NavigationHelper.pushAndRemoveUntil(
                context,
                HomePage(initScreen: 4),
              );
          Timer(Duration(seconds: 3), () {
            passwordController.clear();
            rePasswordController.clear();
          });
        case 400:
        case 410:
          // The code on this screen can't be edited, so a bad or expired
          // code means starting over with a new one.
          _restartReset(
            context,
            _errorText(
              response.data,
              "Your code is no longer valid. Request a new one.",
            ),
          );
        case 429:
          SnackbarHelper.danger(
            context: context,
            title: "Too Many Requests",
            message: "Please wait a minute and try again",
          );
        default:
          SnackbarHelper.danger(
            context: context,
            title: "Password Not Changed",
            message: _errorText(response.data, "Please check and try again"),
          );
      }
    } catch (e) {
      debugPrint("!!! [resetPassword] ERROR: $e");
      if (context.mounted) {
        SnackbarHelper.danger(
          context: context,
          title: "Network Error",
          message: "Check your internet connection and try again",
        );
      }
    } finally {
      userUDLoading = false;
      notifyListeners();
    }
  }

  /// Customer notifications are page-numbered (10 per page, fixed).
  int notificationsPage = 1;
  bool notificationsHasMore = false;
  bool loadingMoreNotifications = false;

  /// Appends the next (older) page of notifications.
  Future<void> loadMoreNotifications() async {
    if (!notificationsHasMore || loadingMoreNotifications) return;
    loadingMoreNotifications = true;
    notifyListeners();
    try {
      final next = notificationsPage + 1;
      final response = await dio.get(
        ApiUrls.userNotifications,
        queryParameters: {"page": next},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode == 200) {
        final parsed = NotificationResponse.fromJson(response.data);
        final have = notifications.map((n) => n.id).toSet();
        notifications = [
          ...notifications,
          ...parsed.data.where((n) => !have.contains(n.id)),
        ];
        notificationsPage = next;
        notificationsHasMore =
            parsed.pagination.currentPage < parsed.pagination.lastPage;
        unreadCount = parsed.unreadCount ?? unreadCount;
      }
    } catch (e) {
      debugPrint("!!! [loadMoreNotifications] $e");
    } finally {
      loadingMoreNotifications = false;
      notifyListeners();
    }
  }

  Future<void> getNotifications() async {
    try {
      var response = await dio.get(
        ApiUrls.userNotifications,

        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final parsed = NotificationResponse.fromJson(response.data);
        // This is page 1 (newest 10). Keep any older pages already loaded
        // with "Load more" instead of throwing them away on every refresh.
        final fresh = parsed.data;
        final freshIds = fresh.map((n) => n.id).toSet();
        final older =
            notificationsPage > 1
                ? notifications.where((n) => !freshIds.contains(n.id)).toList()
                : <NotificationData>[];
        notifications = [...fresh, ...older];
        if (notificationsPage <= 1) {
          notificationsHasMore =
              parsed.pagination.currentPage < parsed.pagination.lastPage;
        }
        unreadCount = parsed.unreadCount;

        for (var dt in unreadNTF) {
          if (DateTime.parse(dt.createdAt).isWithinLast30SecondsOrFuture() &&
              !notified.contains(dt.id)) {
            notified.add(dt.id);

            await showLocalNotification(
              id: dt.id.hashCode,
              title: dt.data.title,
              body: "${dt.data.message.split(" ").take(2).join(" ")}...",
            );
          }
        }

        notifyListeners();
      }
    } catch (_) {}
  }

  /// GET /v1/notifications/unread-count — the cheap bell-badge poll. The
  /// full list is only fetched when the count moves.
  Future<void> pollNotifications() async {
    if (userData == null) return;
    try {
      final r = await dio.get(
        ApiUrls.userUnreadCount,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer ${userData?.token}',
          },
          validateStatus: (_) => true,
        ),
      );
      final count =
          r.statusCode == 200 && r.data is Map
              ? int.tryParse("${r.data['unread_count'] ?? ''}")
              : null;
      // Older server without the route: fall back to the full list.
      if (count == null) return getNotifications();
      if (count != unreadCount) await getNotifications();
    } catch (_) {}
  }

  Future<void> readNotification(uid) async {
    var res = await dio.patch(
      "${ApiUrls.userNotifications}/$uid/read",

      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    await getNotifications();
  }

  Future<void> readAllNotification() async {
    readAlLoad = true;
    notifyListeners();
    await dio.patch(
      "${ApiUrls.userNotifications}/read-all",

      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${userData?.token}',
        },
        validateStatus: (status) => true,
      ),
    );

    await getNotifications();
    readAlLoad = false;
    notifyListeners();
  }

  bool adSeenThisWeek = false;

  Future<void> hasSeenAdThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentWeek = ((now.dayOfYear - now.weekday + 10) / 7).floor();
    final currentYear = now.year;

    final storedData = prefs.getString('showAd') ?? '';
    final parts = storedData.split('-');

    if (parts.length == 3) {
      final lastYear = int.tryParse(parts[0]) ?? 0;
      final lastWeek = int.tryParse(parts[1]) ?? 0;
      final hasSeen = parts[2] == 'true';

      adSeenThisWeek =
          (lastYear == currentYear && lastWeek == currentWeek && hasSeen);
      notifyListeners();
      return;
    }

    adSeenThisWeek = false;
    notifyListeners();
  }

  /// Marks the ad as shown for this week
  Future<void> markAdAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final currentWeek = ((now.dayOfYear - now.weekday + 10) / 7).floor();
    final currentYear = now.year;

    await prefs.setString('showAd', '$currentYear-$currentWeek-true');

    adSeenThisWeek = true;
    notifyListeners();
  }

  void markAdAsNotShown() {
    adSeenThisWeek = false;
    notifyListeners();
  }
}