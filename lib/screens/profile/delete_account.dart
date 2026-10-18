import 'package:dio/dio.dart';
import 'package:flexiphones/helpers/api_helper.dart';
import 'package:flexiphones/helpers/social_auth.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/withdraw_sheet.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _red = Color(0xFFE5484D);
const _blue = Color(0xFF0071E3);

/// Red "Delete account" text, for the bottom of Profile (customer and agent).
class DeleteAccountLink extends StatelessWidget {
  const DeleteAccountLink({super.key, required this.agent});
  final bool agent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed:
            () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => DeleteAccountScreen(agent: agent),
              ),
            ),
        icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 18),
        label: Text(
          "Delete account",
          style: ptstyle(size: 13, weight: 700, color: _red),
        ),
      ),
    );
  }
}

/// Terms of Use / Privacy Policy / Help & Support rows.
class LegalRows extends StatelessWidget {
  const LegalRows({super.key, this.showSupport = true});
  final bool showSupport;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    Widget row(IconData icon, String label, String url) => InkWell(
      onTap: () => openLegal(url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ch.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: ch.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        if (showSupport)
          row(Icons.support_agent_rounded, "Help & Support", LegalUrls.support),
        row(Icons.description_outlined, "Terms of Use", LegalUrls.terms),
        row(Icons.privacy_tip_outlined, "Privacy Policy", LegalUrls.privacy),
      ],
    );
  }
}

/// Explain → confirm who you are → type DELETE → DELETE /api/account.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, required this.agent});

  /// Which side is deleted: the agent (partner) account or the customer one.
  final bool agent;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

enum _Method { password, google, apple }

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late _Method _method = switch (SocialAuth.currentProvider()) {
    'apple' => _Method.apple,
    'google' => _Method.google,
    _ => _Method.password,
  };
  bool _showPass = false;
  bool _busy = false;
  String? _error;

  // Fresh Google/Apple sign-in, done just before deleting.
  SocialResult? _social;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _typedDelete => _confirm.text.trim() == "DELETE";

  bool get _ready =>
      _typedDelete &&
      !_busy &&
      (_method == _Method.password
          ? _password.text.isNotEmpty
          : _social != null);

  Future<void> _reauth() async {
    setState(() => _error = null);
    try {
      final r =
          _method == _Method.apple
              ? await SocialAuth.withApple()
              : await SocialAuth.withGoogle();
      if (r == null) return; // cancelled
      setState(() => _social = r);
    } catch (e) {
      setState(() => _error = SocialAuth.friendlyError(e));
    }
  }

  Future<void> _delete() async {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    final p = Provider.of<SharedProvider>(context, listen: false);
    final token = widget.agent ? p.partnerData?.token : p.userData?.token;
    if (token == null) {
      setState(() => _error = "You're not signed in.");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await p.dio.delete(
        ApiUrls.deleteAccountDEL,
        data: {
          "confirm": "DELETE",
          if (_method == _Method.password) "password": _password.text,
          if (_method != _Method.password) ...{
            "id_token": _social!.firebaseToken,
            "provider": _method == _Method.apple ? "apple" : "google",
          },
        },
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          validateStatus: (_) => true,
        ),
      );
      debugPrint("=== [deleteAccount] ${r.statusCode}: ${r.data}");
      if (!mounted) return;
      final code = r.statusCode ?? 0;
      final body = r.data is Map ? r.data as Map : const {};
      final message = (body['message'] ?? "").toString();
      final errCode = (body['code'] ?? "").toString();

      if (code >= 200 && code < 300) {
        await _finish(p);
        return;
      }
      if (errCode == 'plan_unpaid') {
        _blocked(
          title: "Finish your plan first",
          message:
              message.isNotEmpty
                  ? message
                  : "You still have a phone plan to pay off. You can delete your account once it's paid.",
          action: "Pay now",
          onAction: () {
            final running = p.orders.where((o) => o.isRunningPlan).toList();
            if (running.isEmpty) return;
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => PayNowScreen(orderId: running.first.id),
              ),
            );
          },
        );
        return;
      }
      if (errCode == 'wallet_not_empty') {
        _blocked(
          title: "Empty your wallet first",
          message:
              message.isNotEmpty
                  ? message
                  : "You still have money in your wallet or a withdrawal on its way.",
          action: "Withdraw",
          onAction: () => showWithdrawSheet(context),
        );
        return;
      }
      if (errCode == 'reauth_required') {
        setState(() {
          _method = _Method.google;
          _social = null;
          _error =
              "This account has no password. Confirm with Google or Apple instead.";
        });
        return;
      }
      if (errCode == 'reauth_failed') {
        setState(() {
          _social = null;
          _error =
              message.isNotEmpty
                  ? message
                  : (_method == _Method.password
                      ? "That password isn't right."
                      : "That isn't the account you signed up with. Try again.");
        });
        return;
      }
      setState(
        () =>
            _error =
                message.isNotEmpty
                    ? message
                    : "Something went wrong and nothing was deleted. Try again, or contact support.",
      );
    } catch (e) {
      debugPrint("!!! [deleteAccount] $e");
      if (mounted) {
        setState(
          () => _error = "Check your internet connection and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(SharedProvider p) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
    nav.push(MaterialPageRoute(builder: (_) => const EmailSignin()));
    await SocialAuth.cleanupAfterDelete(appleAuthCode: _social?.appleAuthCode);
    await p.clearLocalUserData();
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("Your account was deleted."),
      ),
    );
  }

  void _blocked({
    required String title,
    required String message,
    required String action,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ch = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: ptstyle(size: 20, weight: 800, color: ch.onSurface)),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: ptstyle(size: 13.5, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onAction();
                    },
                    child: Text(action, style: ptstyle(size: 15, weight: 700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final side = widget.agent ? "agent" : "customer";
    final other = widget.agent ? "customer" : "agent";

    Widget card(Widget child) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );

    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: ch.onSurfaceVariant, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text("Delete account", style: ptstyle(size: 16, weight: 700)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: _red, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              "This can't be undone",
              textAlign: TextAlign.center,
              style: ptstyle(size: 22, weight: 800, color: ch.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              "Deleting your account is permanent. We delete your profile and your order history.",
              textAlign: TextAlign.center,
              style: ptstyle(size: 13.5, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 18),
            card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good to know", style: ptstyle(size: 14, weight: 700, color: ch.onSurface)),
                  const SizedBox(height: 10),
                  bullet("This deletes only your $side account. If you also have a $other account with this email, it stays."),
                  if (!widget.agent)
                    bullet("If you still have a phone plan to pay off, finish paying it first.")
                  else
                    bullet("If there's money in your wallet or a withdrawal on its way, withdraw it first."),
                  bullet("Cash reservations and finished plans don't stop you deleting."),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final (label, url) in [
                        ("Terms of Use", LegalUrls.terms),
                        ("Privacy Policy", LegalUrls.privacy),
                        ("Help", LegalUrls.deleteHelp),
                      ])
                        TextButton(
                          onPressed: () => openLegal(url),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(label, style: ptstyle(size: 12.5, weight: 700, color: _blue)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text("1. Confirm it's you", style: ptstyle(size: 15, weight: 800, color: ch.onSurface)),
            const SizedBox(height: 10),
            SegmentedButton<_Method>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Method.password, label: Text("Password")),
                ButtonSegment(value: _Method.google, label: Text("Google")),
                ButtonSegment(value: _Method.apple, label: Text("Apple")),
              ],
              selected: {_method},
              onSelectionChanged:
                  (s) => setState(() {
                    _method = s.first;
                    _social = null;
                    _error = null;
                  }),
            ),
            const SizedBox(height: 12),
            if (_method == _Method.password)
              TextField(
                controller: _password,
                obscureText: !_showPass,
                keyboardType: TextInputType.visiblePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Your password",
                  filled: true,
                  fillColor: ch.surfaceContainerLow,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPass = !_showPass),
                    icon: Icon(
                      _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _reauth,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(
                      color: _social != null ? const Color(0xFF30A14E) : ch.outlineVariant,
                      width: 1.4,
                    ),
                  ),
                  icon: _social != null
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF30A14E))
                      : SvgPicture.asset(
                        _method == _Method.apple
                            ? "assets/svg/apple_logo.svg"
                            : "assets/svg/google_logo.svg",
                        width: 20,
                        height: 20,
                        colorFilter: _method == _Method.apple
                            ? ColorFilter.mode(ch.onSurface, BlendMode.srcIn)
                            : null,
                      ),
                  label: Text(
                    _social != null
                        ? "Confirmed"
                        : "Sign in with ${_method == _Method.apple ? "Apple" : "Google"} again",
                    style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Text("2. Type DELETE", style: ptstyle(size: 15, weight: 800, color: ch.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: _confirm,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              style: ptstyle(size: 16, weight: 800, color: ch.onSurface).copyWith(letterSpacing: 2),
              decoration: InputDecoration(
                hintText: "DELETE",
                filled: true,
                fillColor: ch.surfaceContainerLow,
                suffixIcon:
                    _typedDelete
                        ? const Icon(Icons.check_circle_rounded, color: _red)
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!, style: ptstyle(size: 12.5, weight: 600, color: _red)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _red,
                  disabledBackgroundColor: _red.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _ready ? _delete : null,
                child:
                    _busy
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                        : Text(
                          "Delete my account",
                          style: ptstyle(size: 15.5, weight: 800, color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
