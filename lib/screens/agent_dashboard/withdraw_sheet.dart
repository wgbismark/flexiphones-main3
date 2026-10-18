import 'dart:async';

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_earnings.dart'
    show MomoDialog;
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

const _violet = Color(0xFF7C4DFF);
const _red = Color(0xFFE5484D);
const _green = Color(0xFF30A14E);

String _cedi(num v) => "₵${v.toDouble().toCommaSeparated(0, decimalPlaces: 2)}";

/// Withdraw to Mobile Money in three steps: amount → emailed code →
/// started. [onStarted] runs after a withdrawal is accepted (e.g. to show
/// the Withdrawals tab).
Future<void> showWithdrawSheet(
  BuildContext context, {
  VoidCallback? onStarted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WithdrawSheet(onStarted: onStarted),
  );
}

enum _Step { loading, needMomo, amount, code, done }

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({this.onStarted});
  final VoidCallback? onStarted;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  _Step _step = _Step.loading;
  final _amount = TextEditingController();
  final _code = TextEditingController();
  String? _amountError;
  String? _codeError;
  bool _needNewCode = false;
  bool _busy = false;
  String _codeMessage = "";
  int _resendIn = 0;
  int _expiresMin = 10;
  Timer? _tick;
  double _sentAmount = 0;
  String? _reference;

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _amount.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_p.getWithdrawals(silent: true), _p.getMomoDetails()]);
    if (!mounted) return;
    setState(
      () =>
          _step =
              (_p.momoDetails?.isSet ?? false) ? _Step.amount : _Step.needMomo,
    );
  }

  double get _max => _p.withdrawAvailable ?? _p.partnerWallet?.withdrawable ?? 0;

  Future<void> _sendCode() async {
    final value = double.tryParse(_amount.text.replaceAll(",", "").trim());
    if (value == null || value < 1) {
      setState(() => _amountError = "Enter at least ₵1.00");
      return;
    }
    if (value > _max + 0.0001) {
      setState(() => _amountError = "You can withdraw up to ${_cedi(_max)} right now");
      return;
    }
    setState(() {
      _busy = true;
      _amountError = null;
    });
    final r = await _p.requestWithdrawalCode(value);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      if (r.field == "phone") {
        setState(() => _step = _Step.needMomo);
      }
      setState(() => _amountError = r.message);
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    _sentAmount = value;
    _code.clear();
    setState(() {
      _codeMessage = r.message;
      _expiresMin = r.expiresIn;
      _codeError = null;
      _needNewCode = false;
      _step = _Step.code;
    });
    _startResendTimer(r.resendAfter);
  }

  void _startResendTimer(int seconds) {
    _tick?.cancel();
    setState(() => _resendIn = seconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 999));
      if (_resendIn == 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final r = await _p.requestWithdrawalCode(_sentAmount);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _code.clear();
      setState(() {
        _codeMessage = r.message;
        _codeError = null;
        _needNewCode = false;
      });
      _startResendTimer(r.resendAfter);
    } else {
      setState(() => _codeError = r.message);
    }
  }

  Future<void> _confirm() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    final r = await _p.confirmWithdrawal(_sentAmount, _code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      HapticFeedback.heavyImpact();
      _tick?.cancel();
      setState(() {
        _reference = r.reference;
        _step = _Step.done;
      });
      _p.getPartnerWallet();
      widget.onStarted?.call();
      return;
    }
    HapticFeedback.heavyImpact();
    final m = r.message.toLowerCase();
    setState(() {
      _codeError = r.message;
      // Burned / expired / changed: only a new code helps.
      _needNewCode =
          m.contains("new code") ||
          m.contains("new one") ||
          m.contains("expired") ||
          m.contains("too many");
      if (r.field == "amount" || r.field == "phone") {
        _amountError = r.message;
        _step = _Step.amount;
      }
    });
    _code.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: ch.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder:
                        (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(a),
                            child: c,
                          ),
                        ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        _Step.loading => const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        _Step.needMomo => _needMomo(ch),
                        _Step.amount => _amountStep(ch),
                        _Step.code => _codeStep(ch),
                        _Step.done => _doneStep(ch),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme ch, String title, String sub, {VoidCallback? back}) =>
      Row(
        children: [
          if (back != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: back,
                style: IconButton.styleFrom(
                  backgroundColor: ch.onSurface.withOpacity(0.06),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ptstyle(
                    size: 22,
                    weight: 800,
                    color: ch.onSurface,
                  ).copyWith(letterSpacing: -0.6),
                ),
                Text(
                  sub,
                  style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );

  // ---------------- No MoMo number ----------------
  Widget _needMomo(ColorScheme ch) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(ch, "Add your Mobile Money", "Withdrawals are paid to your MoMo number."),
      const SizedBox(height: 24),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android_rounded, size: 44, color: _violet),
        ),
      ),
      if (_amountError != null) ...[
        const SizedBox(height: 16),
        _errorBox(_amountError!),
      ],
      const SizedBox(height: 24),
      _bigButton(
        "Add MoMo number",
        icon: Icons.add_rounded,
        onTap: () async {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => MomoDialog(current: _p.momoDetails),
          );
          if (!mounted) return;
          await _p.getMomoDetails();
          if (!mounted) return;
          if (_p.momoDetails?.isSet ?? false) {
            setState(() {
              _amountError = null;
              _step = _Step.amount;
            });
          }
        },
      ),
    ],
  );

  // ---------------- Amount ----------------
  Widget _amountStep(ColorScheme ch) {
    final p = Provider.of<SharedProvider>(context);
    final momo = p.momoDetails;
    final max = _max;
    final pending = p.withdrawals.where((w) => w.isPending).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(ch, "Withdraw", "Up to ${_cedi(max)} available now"),
        const SizedBox(height: 26),
        // Big amount
        Center(
          child: IntrinsicWidth(
            child: TextField(
              controller: _amount,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() => _amountError = null),
              style: ptstyle(
                size: 46,
                weight: 800,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "0.00",
                hintStyle: ptstyle(
                  size: 46,
                  weight: 800,
                  color: ch.onSurface.withOpacity(0.15),
                ).copyWith(letterSpacing: -1.5),
                prefixText: "₵ ",
                prefixStyle: ptstyle(
                  size: 30,
                  weight: 700,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (label, f) in [("25%", 0.25), ("50%", 0.5), ("Max", 1.0)])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  onPressed:
                      max <= 0
                          ? null
                          : () {
                            HapticFeedback.selectionClick();
                            final v = (max * f * 100).floor() / 100;
                            setState(() {
                              _amount.text = v.toStringAsFixed(2);
                              _amountError = null;
                            });
                          },
                  label: Text(label, style: ptstyle(size: 12, weight: 700, color: _violet)),
                  backgroundColor: _violet.withOpacity(0.08),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
        if (_amountError != null) ...[
          const SizedBox(height: 14),
          _errorBox(_amountError!),
        ],
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${_cedi(pending.fold<double>(0, (s, w) => s + w.amount))} is already on its way and isn't counted in what's available.",
                    style: ptstyle(size: 11.5, weight: 500, color: ch.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        // Destination
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ch.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _networkColor(momo?.network).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  color: _networkColor(momo?.network),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Paid to",
                      style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
                    ),
                    Text(
                      "${momo?.network ?? ""} · ${momo?.number ?? ""}",
                      style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                    ),
                    if ((momo?.accountName ?? "").isNotEmpty)
                      Text(
                        momo!.accountName!,
                        style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => MomoDialog(current: _p.momoDetails),
                  );
                  if (mounted) _p.getMomoDetails();
                },
                child: Text(
                  "Change",
                  style: ptstyle(size: 12.5, weight: 700, color: _violet),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _bigButton(
          "Send me a code",
          icon: Icons.mail_outline_rounded,
          loading: _busy,
          enabled: max > 0,
          onTap: _sendCode,
        ),
        const SizedBox(height: 10),
        Text(
          "For your safety, every withdrawal needs a code we email to you.",
          textAlign: TextAlign.center,
          style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
        ),
      ],
    );
  }

  // ---------------- Code ----------------
  Widget _codeStep(ColorScheme ch) {
    final box = PinTheme(
      width: 48,
      height: 58,
      textStyle: ptstyle(size: 22, weight: 800, color: ch.onSurface),
      decoration: BoxDecoration(
        color: ch.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          ch,
          "Enter the code",
          "Withdrawing ${_cedi(_sentAmount)}",
          back: () => setState(() => _step = _Step.amount),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _violet.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: _violet),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _codeMessage,
                  style: ptstyle(size: 12.5, weight: 500, color: ch.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Pinput(
            length: 6,
            controller: _code,
            autofocus: true,
            enabled: !_needNewCode && !_busy,
            autofillHints: const [AutofillHints.oneTimeCode],
            forceErrorState: _codeError != null,
            defaultPinTheme: box,
            focusedPinTheme: box.copyDecorationWith(
              border: Border.all(color: _violet, width: 2),
              color: Theme.of(context).colorScheme.surface,
            ),
            errorPinTheme: box.copyDecorationWith(
              border: Border.all(color: _red, width: 1.5),
            ),
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onChanged: (_) {
              if (_codeError != null && !_needNewCode) {
                setState(() => _codeError = null);
              }
            },
            onCompleted: (_) => _confirm(),
          ),
        ),
        if (_codeError != null) ...[
          const SizedBox(height: 14),
          _errorBox(_codeError!),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't get it? ",
              style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
            ),
            TextButton(
              onPressed: _resendIn > 0 || _busy ? null : _resend,
              child: Text(
                _resendIn > 0 ? "Resend in ${_resendIn}s" : "Resend code",
                style: ptstyle(
                  size: 12.5,
                  weight: 700,
                  color: _resendIn > 0 ? ch.onSurfaceVariant : _violet,
                ),
              ),
            ),
          ],
        ),
        Text(
          "The code works once and expires in $_expiresMin minutes. Check your spam folder too.",
          textAlign: TextAlign.center,
          style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _needNewCode
            ? _bigButton(
              "Get a new code",
              icon: Icons.refresh_rounded,
              loading: _busy,
              enabled: _resendIn == 0,
              onTap: _resend,
            )
            : _bigButton(
              "Withdraw ${_cedi(_sentAmount)}",
              icon: Icons.arrow_upward_rounded,
              loading: _busy,
              enabled: _code.text.length == 6,
              onTap: _confirm,
            ),
      ],
    );
  }

  // ---------------- Done ----------------
  Widget _doneStep(ColorScheme ch) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 18),
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF34C759), _green]),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        "Withdrawal started",
        textAlign: TextAlign.center,
        style: ptstyle(size: 24, weight: 800, color: ch.onSurface).copyWith(letterSpacing: -0.6),
      ),
      const SizedBox(height: 6),
      Text(
        "${_cedi(_sentAmount)} is on its way to your Mobile Money. Your wallet is debited once the transfer is confirmed.",
        textAlign: TextAlign.center,
        style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
      ),
      if (_reference != null) ...[
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ch.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "Ref: $_reference",
              style: ptstyle(size: 12, weight: 600, color: ch.onSurfaceVariant),
            ),
          ),
        ),
      ],
      const SizedBox(height: 26),
      _bigButton(
        "Done",
        icon: Icons.check_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );

  // ---------------- Helpers ----------------
  Widget _errorBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: ptstyle(size: 12, weight: 500, color: _red)),
        ),
      ],
    ),
  );

  Widget _bigButton(
    String label, {
    required IconData icon,
    required VoidCallback onTap,
    bool loading = false,
    bool enabled = true,
  }) => SizedBox(
    height: 56,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _violet,
        disabledBackgroundColor: _violet.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: !enabled || loading ? null : onTap,
      child:
          loading
              ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: ptstyle(size: 15.5, weight: 700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Icon(icon, size: 19, color: Colors.white),
                ],
              ),
    ),
  );

  static Color _networkColor(String? n) {
    final s = (n ?? "").toLowerCase();
    if (s.contains("mtn")) return const Color(0xFFFFB300);
    if (s.contains("voda") || s.contains("telecel")) return _red;
    if (s.contains("airtel") || s.contains("tigo")) return const Color(0xFF1E5BD8);
    return _violet;
  }
}
