import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_wallet.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

const _agentGold = Color(0xFFCC9A44);

String agentMoney(double v) => "₵${v.toCommaSeparated(0, decimalPlaces: 2)}";

/// The Earnings tab is now the Wallet (balance, withdrawable amount,
/// withdrawals and points). Kept so older links (e.g. notifications) still
/// open it.
class AgentEarnings extends StatelessWidget {
  const AgentEarnings({super.key});

  @override
  Widget build(BuildContext context) => const AgentWallet();
}

class AgentPointsRow extends StatelessWidget {
  const AgentPointsRow({super.key, required this.entry});
  final PointsEntry entry;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _agentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.stars_rounded, size: 18, color: _agentGold),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 13, weight: 600, color: ch.onSurface),
                ),
                Text(
                  entry.createdAt.formatDateNoTime(),
                  style: ptstyle(
                    size: 11,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "+${entry.points}",
            style: ptstyle(size: 13, weight: 700, color: _agentGold),
          ),
        ],
      ),
    );
  }
}

/// One wallet transaction row (used here and on the dashboard).
class AgentTxRow extends StatelessWidget {
  const AgentTxRow({super.key, required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final credit = tx.isCredit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ch.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: credit ? Colors.green : Colors.redAccent,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 13, weight: 600, color: ch.onSurface),
                ),
                Text(
                  [
                    tx.createdAt.formatDateNoTime(),
                    if (tx.kindLabel != null) tx.kindLabel!,
                    if (tx.status.isNotEmpty) tx.status,
                  ].join(" · "),
                  style: ptstyle(
                    size: 11,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${credit ? "+" : "-"}${agentMoney(tx.amount)}",
            style: ptstyle(
              size: 13,
              weight: 700,
              color: credit ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile Money payout number. The agent only types the number; the
/// network and the wallet's name come back from the provider and are shown
/// read-only, with "Is this your number?". Turning a name down, or saving,
/// starts a 5-minute wait before another number can be looked up, so the
/// lookup can't be used to read strangers' names.
class MomoDialog extends StatefulWidget {
  const MomoDialog({super.key, this.current});
  final MomoDetails? current;

  @override
  State<MomoDialog> createState() => _MomoDialogState();
}

enum _MomoState { typing, looking, found, failed }

class _MomoDialogState extends State<MomoDialog> {
  static const _violet = Color(0xFF7C4DFF);
  static const _green = Color(0xFF30A14E);
  static const _red = Color(0xFFE5484D);

  final _number = TextEditingController();
  _MomoState _state = _MomoState.typing;
  String? _network;
  String? _name;
  bool _verified = false;
  String? _error;
  String? _lookedUp;
  Timer? _debounce;
  Timer? _tick;
  bool _saving = false;

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _p.loadMomoLock();
      if (!mounted) return;
      setState(() {});
      _startTicker();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tick?.cancel();
    _resendTimer?.cancel();
    _code.dispose();
    _number.dispose();
    super.dispose();
  }

  /// Redraws the countdown each second while locked.
  void _startTicker() {
    _tick?.cancel();
    if (_p.momoLockLeft == Duration.zero) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
      if (_p.momoLockLeft == Duration.zero) t.cancel();
    });
  }

  /// 0541234567 / 233541234567 / +233541234567.
  static bool _complete(String raw) {
    final s = raw.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^0\d{9}$').hasMatch(s) ||
        RegExp(r'^233\d{9}$').hasMatch(s) ||
        RegExp(r'^\+233\d{9}$').hasMatch(s);
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    setState(() {
      _error = null;
      _state = _MomoState.typing;
    });
    if (!_complete(v)) return;
    // Look it up once the number looks complete (debounced).
    _debounce = Timer(const Duration(milliseconds: 600), () => _lookup(v.trim()));
  }

  Future<void> _lookup(String number) async {
    if (number == _lookedUp && _state == _MomoState.found) return;
    if (_p.momoLockLeft > Duration.zero) return;
    setState(() => _state = _MomoState.looking);
    final r = await _p.lookupMomo(number);
    if (!mounted || _number.text.trim() != number) return;
    if (r.ok) {
      HapticFeedback.mediumImpact();
      setState(() {
        _lookedUp = number;
        _network = r.network;
        _name = r.name;
        _verified = r.verified;
        _state = _MomoState.found;
      });
    } else {
      setState(() {
        _error = r.message;
        _state = _MomoState.failed;
      });
    }
  }

  // Changing a saved number: an emailed 6-digit code tied to the new one.
  bool _codeStep = false;
  final _code = TextEditingController();
  String _codeMessage = "";
  int _resendIn = 0;
  Timer? _resendTimer;

  /// "Yes, save it". A first number saves straight away; replacing a saved
  /// number first emails a code.
  Future<void> _save() async {
    if (_lookedUp == null) return;
    if (_p.momoChangeNeedsCode(_lookedUp!) && !_codeStep) {
      await _sendCode();
      return;
    }
    await _saveWithCode(_codeStep ? _code.text.trim() : null);
  }

  Future<void> _sendCode() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await _p.requestMomoChangeCode(_lookedUp!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    _code.clear();
    setState(() {
      _codeStep = true;
      _codeMessage = r.message;
    });
    _resendTimer?.cancel();
    setState(() => _resendIn = r.resendAfter);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 999));
      if (_resendIn == 0) t.cancel();
    });
  }

  Future<void> _saveWithCode(String? code) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await _p.saveMomoNumber(_lookedUp!, code: code);
    if (!mounted) return;
    setState(() => _saving = false);
    if (r.ok) {
      HapticFeedback.mediumImpact();
      _resendTimer?.cancel();
      Navigator.of(context).pop(true);
      return;
    }
    if (r.needsCode && !_codeStep) {
      // The server wants a code after all: ask for one.
      await _sendCode();
      if (mounted && r.message != null) setState(() => _error = r.message);
      return;
    }
    _code.clear();
    setState(() => _error = r.message);
  }

  /// "No, that's not me": clear it and start the wait.
  Future<void> _reject() async {
    await _p.lockMomo();
    if (!mounted) return;
    _number.clear();
    setState(() {
      _lookedUp = null;
      _name = null;
      _network = null;
      _state = _MomoState.typing;
    });
    _startTicker();
  }

  static Color _networkColor(String? n) {
    final s = (n ?? "").toLowerCase();
    if (s.contains("mtn")) return const Color(0xFFFFB300);
    if (s.contains("voda") || s.contains("telecel")) return _red;
    if (s.contains("airtel") || s.contains("tigo")) return const Color(0xFF1E5BD8);
    return _violet;
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final left = p.momoLockLeft;
    final locked = left > Duration.zero;
    final current = widget.current;
    final found = _state == _MomoState.found;

    return Dialog(
      backgroundColor: ch.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.phone_iphone_rounded, color: _violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Mobile Money",
                    style: ptstyle(size: 19, weight: 800, color: ch.onSurface),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Type your number. We'll find the name on the wallet, you don't need to type it.",
              style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
            ),
            if (current?.isSet ?? false) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ch.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      "Saved: ",
                      style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Text(
                        "${current!.network ?? ""} · ${current.number ?? ""}${(current.accountName ?? "").isEmpty ? "" : " · ${current.accountName}"}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(size: 12, weight: 700, color: ch.onSurface),
                      ),
                    ),
                    if (current.verified)
                      const Icon(Icons.verified_rounded, size: 16, color: _green),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (locked && !found)
              _LockedNote(left: left)
            else ...[
              TextField(
                controller: _number,
                enabled: !found && !_saving,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                onChanged: _onChanged,
                style: ptstyle(size: 18, weight: 700, color: ch.onSurface)
                    .copyWith(letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: "0541234567",
                  hintStyle: ptstyle(
                    size: 18,
                    weight: 500,
                    color: ch.onSurfaceVariant.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: ch.onSurface.withOpacity(0.04),
                  prefixIcon: const Icon(Icons.dialpad_rounded),
                  suffixIcon: switch (_state) {
                    _MomoState.looking => const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    _MomoState.found => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        widthFactor: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _networkColor(_network).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _network ?? "",
                            style: ptstyle(
                              size: 11,
                              weight: 800,
                              color: _networkColor(_network),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ => null,
                  },
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: _red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: ptstyle(size: 12, weight: 500, color: _red),
                      ),
                    ),
                  ],
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: !found ? const SizedBox(width: double.infinity) : _foundCard(ch),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _foundCard(ColorScheme ch) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_verified ? _green : const Color(0xFFFF9F0A)).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _verified
                ? Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: _green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name on this wallet",
                            style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
                          ),
                          Text(
                            "${_name ?? ""}${_network == null ? "" : " ($_network)"}",
                            style: ptstyle(size: 16, weight: 800, color: ch.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : Text(
                  "The network did not return a name for this ${_network ?? ""} wallet. "
                  "If you save it, it will be saved under your own name.",
                  style: ptstyle(size: 12.5, weight: 500, color: ch.onSurface),
                ),
          ),
          if (_codeStep) ..._codeEntry(ch) else ..._confirmButtons(ch),
        ],
      ),
    );
  }

  /// Step shown when replacing a saved number: the emailed 6-digit code.
  List<Widget> _codeEntry(ColorScheme ch) {
    final box = PinTheme(
      width: 44,
      height: 52,
      textStyle: ptstyle(size: 20, weight: 800, color: ch.onSurface),
      decoration: BoxDecoration(
        color: ch.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return [
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _violet.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.mark_email_unread_rounded, color: _violet, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _codeMessage.isEmpty
                    ? "To change your saved number, enter the code we emailed you."
                    : _codeMessage,
                style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Center(
        child: Pinput(
          length: 6,
          controller: _code,
          autofocus: true,
          enabled: !_saving,
          autofillHints: const [AutofillHints.oneTimeCode],
          forceErrorState: _error != null,
          defaultPinTheme: box,
          focusedPinTheme: box.copyDecorationWith(
            border: Border.all(color: _violet, width: 2),
          ),
          errorPinTheme: box.copyDecorationWith(
            border: Border.all(color: _red, width: 1.5),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (c) => _saveWithCode(c),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: ptstyle(size: 12, weight: 600, color: _red),
        ),
      ],
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Code works once, for 10 minutes. ",
            style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
          ),
          TextButton(
            onPressed: _resendIn > 0 || _saving ? null : _sendCode,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(
              _resendIn > 0 ? "Resend in ${_resendIn}s" : "Resend",
              style: ptstyle(
                size: 12,
                weight: 700,
                color: _resendIn > 0 ? ch.onSurfaceVariant : _violet,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _violet,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed:
              _saving || _code.text.length != 6
                  ? null
                  : () => _saveWithCode(_code.text.trim()),
          child:
              _saving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : Text("Change number", style: ptstyle(size: 15, weight: 700)),
        ),
      ),
    ];
  }

  List<Widget> _confirmButtons(ColorScheme ch) {
    final replacing = _lookedUp != null && _p.momoChangeNeedsCode(_lookedUp!);
    return [
          const SizedBox(height: 14),
          Text(
            "Is this your number?",
            textAlign: TextAlign.center,
            style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            replacing
                ? "This replaces your saved number. We'll email you a code to confirm it's you."
                : "If you change it, you'll have to wait ${_p.momoLockMinutes} minutes before checking another number.",
            textAlign: TextAlign.center,
            style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : Text(
                        replacing ? "Yes, email me a code" : "Yes, save it",
                        style: ptstyle(size: 15, weight: 700),
                      ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : _reject,
            child: Text(
              "No, change number",
              style: ptstyle(size: 13.5, weight: 600, color: ch.onSurfaceVariant),
            ),
          ),
    ];
  }
}

class _LockedNote extends StatelessWidget {
  const _LockedNote({required this.left});
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final m = left.inMinutes;
    final s = (left.inSeconds % 60).toString().padLeft(2, "0");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFFF9F0A), size: 30),
          const SizedBox(height: 8),
          Text(
            "$m:$s",
            style: ptstyle(size: 26, weight: 800, color: ch.onSurface)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 4),
          Text(
            "To keep wallets safe, you can check a new number when the timer ends.",
            textAlign: TextAlign.center,
            style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
