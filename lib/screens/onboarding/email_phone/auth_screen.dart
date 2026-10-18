import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/social_auth.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signup.dart';
import 'package:flexiphones/screens/onboarding/forgot_password.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _bg = Color(0xFFF2F4F7);

enum _SignUpRole { customer, agent }

/// Sign in and sign up on one screen. A pill switch slides between the two
/// forms (or swipe the forms sideways); the illustration and headline
/// follow. Sign up needs the terms ticked before it can continue.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTab = 0});

  /// 0 = sign in, 1 = sign up.
  final int initialTab;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialTab,
  );
  late double _pos = widget.initialTab.toDouble();
  final _signInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // iOS needs its own client id (from GoogleService-Info.plist).
    clientId:
        defaultTargetPlatform == TargetPlatform.iOS
            ? '489413845763-g8dt46psak981ntsrlrq8nqti6gdr54g.apps.googleusercontent.com'
            : null,
    serverClientId:
        '489413845763-k1bdvu40o3n3sqr0ao7574rusa8d98s6.apps.googleusercontent.com',
  );
  bool _showPass = false;
  bool _agreed = false;
  _SignUpRole _signUpRole = _SignUpRole.customer;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      if (_pages.hasClients && _pages.page != null) {
        setState(() => _pos = _pages.page!);
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int tab) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    _pages.animateToPage(
      tab,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  String? _emailCheck(String? v) {
    final e = (v ?? "").trim();
    if (e.isEmpty) return "Enter your email";
    if (!e.isValidEmail) return "That email doesn't look right";
    return null;
  }

  bool _googleBusy = false;
  bool _appleBusy = false;

  Future<void> _handleAppleAuth(BuildContext context) async {
    if (_appleBusy || _googleBusy) return;
    setState(() => _appleBusy = true);
    try {
      final r = await SocialAuth.withApple();
      if (r == null || !context.mounted) return; // cancelled
      // Sign in tab: no side (the server opens the account they have).
      final String? role =
          _pos.round() == 1
              ? (_signUpRole == _SignUpRole.agent ? "agent" : "customer")
              : null;
      await Provider.of<SharedProvider>(context, listen: false).googleSignIn(
        context,
        idToken: r.firebaseToken,
        as: role,
        provider: "apple",
        name: r.name,
      );
    } catch (e) {
      debugPrint("!!! [apple] $e");
      if (context.mounted) _showGoogleError(context, SocialAuth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _appleBusy = false);
    }
  }

  /// Plain words for what can go wrong before our server is even reached.
  String _googleError(Object e) {
    final s = e.toString();
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return "No internet connection. Check it and try again.";
        case 'user-disabled':
          return "This Google account has been disabled.";
        case 'account-exists-with-different-credential':
          return "This email already uses another sign-in method. Sign in with your email and password.";
      }
    }
    if (s.contains("ApiException: 10") || s.contains("DEVELOPER_ERROR")) {
      return "Google sign-in isn't set up for this version of the app yet. Please sign in with your email for now.";
    }
    if (s.contains("ApiException: 7") || s.contains("network_error")) {
      return "No internet connection. Check it and try again.";
    }
    if (s.contains("ApiException: 12500") || s.contains("sign_in_failed")) {
      return "Google sign-in couldn't start. Update Google Play services and try again.";
    }
    if (s.contains("[core/no-app]") || s.contains("No Firebase App")) {
      return "Google sign-in is unavailable right now. Please sign in with your email.";
    }
    return "Google sign-in didn't work. Please try again.";
  }

  /// Short code shown after the message, e.g. "10", to tell setup
  /// problems from network ones without a cable.
  String _errCode(Object e) {
    final s = e.toString();
    final m = RegExp(r"ApiException: (\d+)").firstMatch(s);
    if (m != null) return m.group(1)!;
    if (e is FirebaseAuthException) return e.code;
    if (e is PlatformException) return e.code;
    return e.runtimeType.toString();
  }

  Future<void> _handleGoogleAuth(BuildContext context) async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      // Always offer the account picker (a shared phone may switch people).
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      final googleAuth = await googleUser.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUser = await FirebaseAuth.instance.signInWithCredential(
        googleCredential,
      );
      final firebaseIdToken = await firebaseUser.user?.getIdToken();

      if (firebaseIdToken == null || firebaseIdToken.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase did not return a valid Google ID token.'),
            ),
          );
        }
        return;
      }

      final String? role =
          _pos.round() == 1
              ? (_signUpRole == _SignUpRole.agent ? 'agent' : 'customer')
              : null;
      if (context.mounted) {
        await Provider.of<SharedProvider>(context, listen: false).googleSignIn(
          context,
          idToken: firebaseIdToken,
          googleIdToken: googleAuth.idToken,
          as: role,
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return;
      debugPrint("!!! [google] ${e.code} ${e.message}");
      if (context.mounted) _showGoogleError(context, "${_googleError(e)} (${_errCode(e)})");
    } catch (e) {
      debugPrint("!!! [google] $e");
      if (context.mounted) _showGoogleError(context, "${_googleError(e)} (${_errCode(e)})");
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showGoogleError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE5484D),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final tab = _pos.round();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: SizedBox(
                    height: 44,
                    child:
                        canPop
                            ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                ),
                              ),
                            )
                            : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: tab == 0 ? 160 : 92,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder:
                          (c, a) => FadeTransition(
                            opacity: a,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.9, end: 1.0).animate(a),
                              child: c,
                            ),
                          ),
                      child: Image.asset(
                        tab == 0
                            ? AssetsHelper.signinImage
                            : AssetsHelper.signupImage,
                        key: ValueKey(tab),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Column(
                      key: ValueKey(tab),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab == 0 ? "Welcome back." : "Let's get you started.",
                          style: ptstyle(
                            size: 28,
                            weight: 800,
                            color: ch.onSurface,
                          ).copyWith(letterSpacing: -1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab == 0
                              ? "Sign in to see your orders and payments."
                              : "Create your FlexiPhones account in a minute.",
                          style: ptstyle(
                            size: 13.5,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TabSwitch(position: _pos, onTap: _goTo),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: PageView(
                  controller: _pages,
                  children: [_signIn(ch, p), _signUp(ch, p)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Sign in ----------------
  Widget _signIn(ColorScheme ch, SharedProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      child: Form(
        key: _signInKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              controller: p.emailEditingController,
              icon: Icons.mail_outline_rounded,
              hint: "Email address",
              keyboard: TextInputType.emailAddress,
              validator: _emailCheck,
              enabled: !p.userUDLoading,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: p.passwordController,
              icon: Icons.lock_outline_rounded,
              hint: "Password",
              obscure: !_showPass,
              enabled: !p.userUDLoading,
              validator:
                  (v) => (v ?? "").isEmpty ? "Enter your password" : null,
              trailing: IconButton(
                onPressed: () => setState(() => _showPass = !_showPass),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _showPass
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    key: ValueKey(_showPass),
                    size: 20,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: _ForgotButton(
                onTap:
                    () => NavigationHelper.push(context, ForgotPassword()),
              ),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: "Sign in",
              icon: Icons.arrow_forward_rounded,
              loading: p.userUDLoading,
              onTap: () {
                FocusScope.of(context).unfocus();
                if (_signInKey.currentState!.validate()) {
                  p.emailSignIn(context);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            _GoogleAuthButton(
              onPressed: () => _handleGoogleAuth(context),
              busy: _googleBusy,
              nudge: p.signInRefusals,
            ),
            const SizedBox(height: 10),
            _AppleAuthButton(
              onPressed: () => _handleAppleAuth(context),
              busy: _appleBusy,
            ),
            const SizedBox(height: 12),
            const _AgreeLine(),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () => _goTo(1),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "New to FlexiPhones?  ",
                        style: ptstyle(
                          size: 13,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(
                        text: "Create an account",
                        style: ptstyle(size: 13, weight: 700, color: _blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Sign up ----------------
  Widget _signUp(ColorScheme ch, SharedProvider p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      child: Form(
        key: _signUpKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoleSelector(
              value: _signUpRole,
              onChanged: (value) => setState(() => _signUpRole = value),
            ),
            const SizedBox(height: 16),
            _Field(
              controller: p.emailEditingController,
              focusNode: p.emailFocusNode,
              icon: Icons.mail_outline_rounded,
              hint: "Email address",
              keyboard: TextInputType.emailAddress,
              validator: _emailCheck,
              enabled: !p.emailVerification,
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              key: ValueKey(_shake),
              tween: Tween(begin: _shake == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 450),
              builder:
                  (_, v, child) => Transform.translate(
                    offset: Offset(
                      8 * v * (((v * 10).floor()).isEven ? 1 : -1),
                      0,
                    ),
                    child: child,
                  ),
              child: _TermsTick(
                value: _agreed,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _agreed = v);
                },
                onOpenTerms: () => _showTerms(context),
              ),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: _signUpRole == _SignUpRole.customer
                  ? "Create account"
                  : "Continue as agent",
              icon: _signUpRole == _SignUpRole.customer
                  ? Icons.person_add_alt_1_rounded
                  : Icons.business_center_outlined,
              loading: p.emailVerification,
              dimmed: !_agreed,
              onTap: () {
                FocusScope.of(context).unfocus();
                // Terms first: nothing goes ahead until they are ticked.
                if (!_agreed) {
                  HapticFeedback.heavyImpact();
                  setState(() => _shake++);
                  return;
                }
                if (!_signUpKey.currentState!.validate()) return;
                final email = p.emailEditingController.text.trim();
                if (_signUpRole == _SignUpRole.agent) {
                  p.agentEmailController.text = email;
                  p.agentEmailController.selection = TextSelection.fromPosition(
                    TextPosition(offset: email.length),
                  );
                  NavigationHelper.push(context, const AgentSignup());
                  return;
                }
                p.verifyEmail(context, ch);
              },
            ),
            const SizedBox(height: 8),
            Text(
              "We'll email you a code to confirm it's you.",
              textAlign: TextAlign.center,
              style: ptstyle(
                size: 11.5,
                weight: 400,
                color: ch.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            // Sign up: Google and Apple stay off until the terms are ticked.
            // A tap while off shakes the terms box instead.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  _agreed
                      ? null
                      : () {
                        HapticFeedback.heavyImpact();
                        setState(() => _shake++);
                      },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _agreed ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !_agreed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GoogleAuthButton(
                        onPressed: () => _handleGoogleAuth(context),
                        busy: _googleBusy,
                        nudge: p.signInRefusals,
                      ),
                      const SizedBox(height: 10),
                      _AppleAuthButton(
                        onPressed: () => _handleAppleAuth(context),
                        busy: _appleBusy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _AgreeLine(),
          ],
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ch.surface,
      builder:
          (ctx) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              children: [
                Text(
                  "Terms & Privacy",
                  style: ptstyle(size: 22, weight: 800, color: ch.onSurface),
                ),
                const SizedBox(height: 14),
                for (final (title, body) in _terms) ...[
                  Text(
                    title,
                    style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: ptstyle(
                      size: 13,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _agreed = true);
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      "I agree",
                      style: ptstyle(size: 15, weight: 700),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Short summary shown in the app. Replace with the full legal text (or a
  // link to it) when it's published.
  static const _terms = [
    (
      "Paying for your phone",
      "You pay a down payment, then daily payments for the plan you choose. The phone is yours once the full amount is paid.",
    ),
    (
      "Missed payments",
      "If a payment day is missed, the phone can be locked until you catch up. Paying the amount owed unlocks it.",
    ),
    (
      "Your account",
      "Keep your sign-in details private. You're responsible for activity on your account.",
    ),
    (
      "Your data",
      "We use your details to run your account, process payments and contact you about your orders. We don't sell your data.",
    ),
  ];
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

/// "Sign in | Sign up" pill. The white thumb follows the page as it slides,
/// so dragging the forms moves it too.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.position, required this.onTap});
  final double position;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 10) / 2;
        return Container(
          height: 54,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: ch.onSurface.withOpacity(0.07),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              Positioned(
                left: w * position.clamp(0.0, 1.0),
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, label) in [(0, "Sign in"), (1, "Sign up")])
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Center(
                          child: Text(
                            label,
                            style: ptstyle(
                              size: 14.5,
                              weight: 700,
                              color: Color.lerp(
                                ch.onSurface,
                                ch.onSurfaceVariant.withOpacity(0.7),
                                (position - i).abs().clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final _SignUpRole value;
  final ValueChanged<_SignUpRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final options = [
      ("Customer", _SignUpRole.customer),
      ("Agent", _SignUpRole.agent),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ch.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final (label, role) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: value == role ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: value == role
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ptstyle(
                      size: 13.5,
                      weight: 700,
                      color:
                          value == role
                              ? ch.onSurface
                              : ch.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.validator,
    this.trailing,
    this.enabled = true,
    this.focusNode,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboard;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? trailing;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                _focused
                    ? _blue.withOpacity(0.18)
                    : Colors.black.withOpacity(0.03),
            blurRadius: _focused ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        keyboardType: widget.keyboard,
        obscureText: widget.obscure,
        validator: widget.validator,
        style: ptstyle(size: 15, weight: 500, color: ch.onSurface),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: widget.hint,
          hintStyle: ptstyle(
            size: 14.5,
            weight: 400,
            color: ch.onSurfaceVariant.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 20,
            color: _focused ? _blue : ch.onSurfaceVariant,
          ),
          suffixIcon: widget.trailing,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _blue, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5484D)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.6),
          ),
          errorStyle: ptstyle(
            size: 11.5,
            weight: 500,
            color: const Color(0xFFE5484D),
          ),
        ),
      ),
    );
  }
}

/// "🔑 Forgot password? →" pill that nudges on press.
class _ForgotButton extends StatelessWidget {
  const _ForgotButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2E8BFF), Color(0xFF8E5CFF)],
                ),
              ),
              child: const Icon(Icons.key_rounded, size: 13, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              "Forgot password?",
              style: ptstyle(size: 12.5, weight: 700, color: _blue),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 17, color: _blue),
          ],
        ),
      ),
    );
  }
}

class _TermsTick extends StatelessWidget {
  const _TermsTick({
    required this.value,
    required this.onChanged,
    required this.onOpenTerms,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;

  WidgetSpan _link(String label, String url) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: GestureDetector(
      onTap: () => openLegal(url),
      child: Text(
        label,
        style: ptstyle(size: 13, weight: 700, color: _blue, height: 1.45)
            .copyWith(decoration: TextDecoration.underline),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? _blue.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: value ? _blue.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? _blue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value ? _blue : ch.onSurface.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: value ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "I agree to the FlexiPhones ",
                      style: ptstyle(
                        size: 13,
                        weight: 400,
                        color: ch.onSurface,
                        height: 1.45,
                      ),
                    ),
                    _link("Terms of Use", LegalUrls.terms),
                    TextSpan(
                      text: " and ",
                      style: ptstyle(size: 13, weight: 400, color: ch.onSurface, height: 1.45),
                    ),
                    _link("Privacy Policy", LegalUrls.privacy),
                    TextSpan(
                      text: ", including daily payments and phone locking if I miss a payment.",
                      style: ptstyle(
                        size: 13,
                        weight: 400,
                        color: ch.onSurface,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Continue with Google". Always visible on both tabs. Shows a spinner
/// while signing in, and glows + nudges once when [nudge] changes (after
/// an email/password sign-in is refused).
class _GoogleAuthButton extends StatefulWidget {
  const _GoogleAuthButton({
    required this.onPressed,
    this.busy = false,
    this.nudge = 0,
  });

  final VoidCallback onPressed;
  final bool busy;
  final int nudge;

  @override
  State<_GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<_GoogleAuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didUpdateWidget(covariant _GoogleAuthButton old) {
    super.didUpdateWidget(old);
    if (widget.nudge != old.nudge && widget.nudge > 0) _glow.forward(from: 0);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) {
        final t = _glow.value;
        // Fades in and out once; a small side-to-side nudge at the start.
        final glow = t == 0 ? 0.0 : (1 - (2 * t - 1).abs());
        final dx = t < 0.35 ? 6 * (1 - t / 0.35) * ((t * 40).floor().isEven ? 1 : -1) : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4285F4).withOpacity(0.45 * glow),
                  blurRadius: 22 * glow,
                  spreadRadius: 2 * glow,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: PressScale(
        onTap: widget.busy ? null : widget.onPressed,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.busy
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF4285F4),
                    ),
                  )
                  : SvgPicture.asset(
                    "assets/svg/google_logo.svg",
                    width: 22,
                    height: 22,
                  ),
              const SizedBox(width: 12),
              Text(
                widget.busy ? 'Signing in…' : 'Continue with Google',
                style: ptstyle(size: 15, weight: 700, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      1.75,
      false,
      blue,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.1,
      1.05,
      false,
      red,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      5.3,
      1.15,
      false,
      yellow,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.6,
      1.2,
      false,
      green,
    );

    final bar = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.58,
        size.height * 0.27,
        size.width * 0.22,
        size.height * 0.46,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.dimmed = false,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.4 : 1,
      child: PressScale(
        onTap: loading ? null : onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E8BFF), Color(0xFF0058C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child:
              loading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: ptstyle(
                          size: 16,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 19),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// Black "Continue with Apple" button, same size and place as Google's
/// (App Store guideline 4.8).
class _AppleAuthButton extends StatelessWidget {
  const _AppleAuthButton({required this.onPressed, required this.busy});
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: busy ? null : onPressed,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: SvgPicture.asset(
                    "assets/svg/apple_logo.svg",
                    width: 19,
                    height: 22,
                  ),
                ),
            const SizedBox(width: 10),
            Text(
              busy ? 'Signing in…' : 'Continue with Apple',
              style: ptstyle(size: 15, weight: 700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// "By continuing you agree to the Terms of Use and Privacy Policy".
class _AgreeLine extends StatelessWidget {
  const _AgreeLine();

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final base = ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant, height: 1.4);
    final link = ptstyle(size: 11.5, weight: 700, color: _blue, height: 1.4);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: "By continuing you agree to the "),
          TextSpan(
            text: "Terms of Use",
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => openLegal(LegalUrls.terms),
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy Policy",
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => openLegal(LegalUrls.privacy),
          ),
          const TextSpan(text: "."),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
