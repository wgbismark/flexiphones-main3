import 'dart:async';

import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flexiphones/models/repayment_info_m.dart';
import 'package:flexiphones/models/standing_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/orders/sub_pages/plan_completed.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flexiphones/shared_widgets/receipt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue = Color(0xFF0071E3);
const _red = Color(0xFFE5484D);

enum _PayStage { loading, loadError, form, waiting, paid, failed, timedOut }

/// "Pay now" for an order's instalments, kept small and calm:
/// one card, a few chips (catch up / N days / full balance), a days
/// stepper, "Pay with", and one button that always shows the amount.
/// 1. GET repayment-info, 2. POST repay-bulk (days / catch_up) or repay
/// (exact amount), 3. poll repayment-status until done, 4. show the receipt.
class PayNowScreen extends StatefulWidget {
  const PayNowScreen({
    super.key,
    required this.orderId,
    this.initialAmount,
    this.selectedDays = const [],
  });

  final int orderId;

  /// Pre-filled amount (e.g. from the payment squares).
  final num? initialAmount;

  /// Days picked on the payment squares: pre-selects that many days.
  final List<DateTime> selectedDays;

  @override
  State<PayNowScreen> createState() => _PayNowScreenState();
}

class _PayNowScreenState extends State<PayNowScreen> {
  static const _pollEvery = Duration(seconds: 3);
  static const _pollFor = Duration(minutes: 4);

  late final SharedProvider _provider;
  final _phoneController = TextEditingController();

  _PayStage _stage = _PayStage.loading;
  RepaymentInfo? _info;
  String _message = "";
  bool _starting = false;
  bool _changePhone = false;
  Receipt? _receipt;
  num? _newBalance;

  // What's being paid: a chip, the stepper (days) or an exact amount.
  SuggestedAmount? _chip;
  int? _stepDays;
  num? _exact;

  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  int? _since;
  bool _polling = false;

  String get _sinceKey => "repay_started_${widget.orderId}";

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<SharedProvider>(context, listen: false);
    _loadInfo();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  /// The standing from repayment-info, else from the order.
  RepaymentStanding? get _standing =>
      _info?.standing ??
      _provider.orders
          .where((o) => o.id == widget.orderId)
          .map((o) => o.standing)
          .firstOrNull;

  int get _missed {
    final info = _info;
    if (info == null) return 0;
    return [
      info.missedDays,
      info.daysOverdue,
      _standing?.missedDays ?? 0,
    ].reduce((a, b) => a > b ? a : b);
  }

  num get _catchUpAmount {
    final info = _info;
    if (info == null) return 0;
    final s = _standing?.amountOverdue ?? 0;
    return info.catchUpAmount > 0 ? info.catchUpAmount : s;
  }

  /// Chips in the server's order; an older server without a catch-up chip
  /// still gets one when days are missed.
  List<SuggestedAmount> get _chips {
    final info = _info;
    if (info == null) return const [];
    final list = [...info.suggestedAmounts];
    final missed = _missed;
    final catchUp = _catchUpAmount;
    if (missed > 0 && catchUp > 0 && !list.any((c) => c.isCatchUp)) {
      list.insert(
        0,
        SuggestedAmount(
          key: "catch_up",
          label: "Catch up $missed day${missed == 1 ? "" : "s"} missed",
          amount: catchUp,
          days: missed,
        ),
      );
    }
    // Never offer catch-up when nothing is missed (the server says 422).
    if (missed <= 0) list.removeWhere((c) => c.isCatchUp);
    return list;
  }

  Future<void> _loadInfo() async {
    setState(() => _stage = _PayStage.loading);
    final result = await _provider.getRepaymentInfo(widget.orderId);
    if (!mounted) return;

    final info = result.info;
    if (info == null) {
      setState(() {
        _stage = _PayStage.loadError;
        _message = result.error ?? "Could not load payment details";
      });
      return;
    }

    _info = info;
    if (_phoneController.text.isEmpty) {
      _phoneController.text = info.defaultPhone ?? "";
    }
    // Pre-select: days from the squares, else the first chip (Catch up
    // when behind, otherwise 1 day).
    _chip = null;
    _stepDays = null;
    _exact = null;
    if (widget.selectedDays.isNotEmpty && info.dayPrice > 0) {
      _stepDays = widget.selectedDays.length.clamp(info.minDays, info.maxDays);
    } else if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _exact = widget.initialAmount;
    } else if (_chips.isNotEmpty) {
      _chip = _chips.first;
    } else if (info.dayPrice > 0) {
      _stepDays = 1;
    }

    if (info.repaymentAllowed && info.inProgress) {
      await _startWaiting(await _savedSince(), "Waiting for your payment…");
      return;
    }
    setState(() => _stage = _PayStage.form);
  }

  num get _amount {
    final info = _info;
    if (info == null) return 0;
    num v;
    if (_chip != null) {
      v = _chip!.amount;
    } else if (_stepDays != null) {
      v = _stepDays! * info.dayPrice;
    } else {
      v = _exact ?? 0;
    }
    if (info.balance > 0 && v > info.balance) v = info.balance;
    return v;
  }

  Future<void> _pay() async {
    final info = _info;
    if (info == null || _starting || _amount <= 0) return;
    HapticFeedback.mediumImpact();

    final chip = _chip;
    final catchUp = chip?.isCatchUp ?? false;
    final days =
        catchUp
            ? null
            : (chip != null && chip.days > 0 ? chip.days : _stepDays);

    setState(() => _starting = true);
    final r = await _provider.startRepayment(
      widget.orderId,
      _amount,
      _phoneController.text.trim(),
      days: chip != null && chip.days <= 0 && !catchUp ? null : days,
      catchUp: catchUp,
    );
    if (!mounted) return;
    setState(() => _starting = false);

    if (r.httpStatus == 202) {
      final since =
          r.startedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _saveSince(since);
      await _startWaiting(since, r.message);
    } else if (r.httpStatus == 409) {
      await _startWaiting(await _savedSince(), r.message);
    } else {
      SnackbarHelper.danger(
        context: context,
        title: "Payment not started",
        message: r.httpStatus == 404 ? "Order not found" : r.message,
      );
    }
  }

  Future<void> _startWaiting(int since, String message) async {
    _since = since;
    _pollStartedAt = DateTime.now();
    _pollTimer?.cancel();
    setState(() {
      _stage = _PayStage.waiting;
      _message = message;
    });
    _pollTimer = Timer.periodic(_pollEvery, (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_polling || _stage != _PayStage.waiting || _since == null) return;
    if (DateTime.now().difference(_pollStartedAt!) > _pollFor) {
      _pollTimer?.cancel();
      setState(() => _stage = _PayStage.timedOut);
      return;
    }

    _polling = true;
    final status = await _provider.getRepaymentStatus(widget.orderId, _since!);
    _polling = false;
    if (!mounted || status == null || _stage != _PayStage.waiting) return;

    if (status.message.isNotEmpty) _message = status.message;
    if (!status.done) {
      setState(() {});
      return;
    }

    _pollTimer?.cancel();
    if (status.isPaid) {
      HapticFeedback.heavyImpact();
      _newBalance = status.balance;
      _receipt = status.receipt;
      setState(() => _stage = _PayStage.paid);
      _refreshAfterPayment();
    } else if (status.isFailed) {
      setState(() => _stage = _PayStage.failed);
    } else {
      await _loadInfo();
    }
  }

  Future<void> _refreshAfterPayment() async {
    try {
      await Future.wait([
        _provider.getOrder(widget.orderId, silent: true),
        _provider.getOrders(refresh: true, next: false),
        _provider.getRepaymentCL(refresh: true, next: false),
        _provider.getNotifications(),
        _provider.getOrdersStanding(),
      ]);
    } catch (e) {
      debugPrint("!!! [payNow] refresh after payment failed: $e");
    }
  }

  Future<void> _saveSince(int since) async {
    try {
      (await SharedPreferences.getInstance()).setInt(_sinceKey, since);
    } catch (_) {}
  }

  Future<int> _savedSince() async {
    final fallback =
        DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch ~/
        1000;
    try {
      return (await SharedPreferences.getInstance()).getInt(_sinceKey) ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _fmt(num v) => NumberFormat("#,##0.00").format(v);

  String _masked(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length < 7) return phone;
    return "${d.substring(0, 3)} ••• ${d.substring(d.length - 4)}";
  }

  String get _deviceName {
    final o = _provider.orders.where((o) => o.id == widget.orderId);
    return o.isEmpty ? "" : titleCase(o.first.product.fullName);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Pay",
          style: ptstyle(size: 16, weight: 600, color: ch.onSurface),
        ),
      ),
      body: SafeArea(child: _body(ch)),
    );
  }

  Widget _body(ColorScheme ch) {
    switch (_stage) {
      case _PayStage.loading:
        return const Center(child: CircularProgressIndicator());
      case _PayStage.loadError:
        return _statusView(
          ch,
          icon: Icons.error_outline,
          color: _red,
          title: "Couldn't load payment details",
          message: _message,
          action: "Try again",
          onAction: _loadInfo,
        );
      case _PayStage.waiting:
        return _statusView(
          ch,
          icon: Icons.phone_iphone_rounded,
          color: _blue,
          title: "Check your phone",
          message:
              _message.isEmpty
                  ? "Approve the Mobile Money prompt to finish paying."
                  : _message,
          busy: true,
        );
      case _PayStage.paid:
        final receipt = _receipt;
        void done() {
          final nav = Navigator.of(context);
          final finished =
              (receipt?.fullyPaid ?? false) ||
              (_newBalance != null && _newBalance! <= 0);
          nav.pop();
          if (finished) {
            nav.push(
              MaterialPageRoute(
                builder:
                    (_) => PlanCompletedScreen(
                      productName: receipt?.device ?? _deviceName,
                    ),
              ),
            );
          }
        }

        if (receipt != null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ReceiptCard(receipt: receipt, onDone: done),
              ),
            ),
          );
        }
        return _statusView(
          ch,
          icon: Icons.check_circle,
          color: const Color(0xFF30A14E),
          title: "Payment received",
          message:
              _newBalance == null
                  ? _message
                  : "$_message\n\nLeft to pay: GHS ${_fmt(_newBalance!)}",
          action: "Done",
          onAction: done,
        );
      case _PayStage.failed:
        return _statusView(
          ch,
          icon: Icons.cancel_outlined,
          color: _red,
          title: "Payment failed",
          message: _message,
          action: "Try again",
          onAction: _loadInfo,
        );
      case _PayStage.timedOut:
        return _statusView(
          ch,
          icon: Icons.hourglass_bottom_rounded,
          color: Colors.orange.shade800,
          title: "Still waiting",
          message: "We'll let you know when it's done.",
          action: "Done",
          onAction: () => Navigator.of(context).pop(),
        );
      case _PayStage.form:
        return _form(ch);
    }
  }

  Widget _form(ColorScheme ch) {
    final info = _info!;
    if (!info.repaymentAllowed) {
      return _statusView(
        ch,
        icon:
            info.balance <= 0
                ? Icons.celebration_rounded
                : Icons.info_outline_rounded,
        color: info.balance <= 0 ? const Color(0xFF30A14E) : _blue,
        title: info.balance <= 0 ? "All paid" : "Not yet",
        message: info.reason ?? "Repayment isn't available for this order yet.",
        action: "Done",
        onAction: () => Navigator.of(context).pop(),
      );
    }

    final chips = _chips;
    // The server decides who is behind (a few hours late = 1 day); the
    // order's standing is used when repayment-info doesn't carry it.
    final orderStanding =
        _provider.orders
            .where((o) => o.id == widget.orderId)
            .map((o) => o.standing)
            .firstOrNull;
    final standing = info.standing ?? orderStanding;
    final missed = [
      info.missedDays,
      info.daysOverdue,
      standing?.missedDays ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    final missedDates =
        standing != null && standing.missedDays > 0
            ? standing.missedDates
            : (missed > 0
                ? List.generate(missed, (i) {
                  final start =
                      DateTime.tryParse(info.nextDue ?? "") ??
                      DateTime.now().subtract(Duration(days: missed));
                  final d0 = DateTime(start.year, start.month, start.day);
                  return d0.add(Duration(days: i));
                })
                : const <DateTime>[]);
    final progress =
        info.totalPayment > 0
            ? (info.totalPaid / info.totalPayment).clamp(0.0, 1.0).toDouble()
            : 0.0;
    final due = DateTime.tryParse(info.nextDue ?? "");
    final amount = _amount;
    final after = (info.balance - amount).clamp(0, double.infinity);
    final device = _deviceName;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              // ---- The plan, in one small card ----
              FadeSlideIn(
                child: _Box(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (device.isNotEmpty)
                        Text(
                          device.toUpperCase(),
                          style: ptstyle(
                            size: 11,
                            weight: 700,
                            color: ch.onSurfaceVariant,
                          ).copyWith(letterSpacing: 1.1),
                        ),
                      const SizedBox(height: 6),
                      if (missed > 0)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You missed $missed day${missed == 1 ? "" : "s"} · GHS ${_fmt(_catchUpAmount)}",
                                style: ptstyle(
                                  size: 15,
                                  weight: 600,
                                  color: _red,
                                ),
                              ),
                            ),
                            Tooltip(
                              triggerMode: TooltipTriggerMode.tap,
                              showDuration: const Duration(seconds: 6),
                              message:
                                  "Pays the days you missed. A payment of N days unlocks the phone and keeps it running for N days from now. Missed days are not extra charges.",
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: ch.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      else if (standing != null && standing.label.isNotEmpty)
                        // The server's own words (Up to date, Due today...).
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: standing.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                standing.label,
                                style: ptstyle(
                                  size: 15,
                                  weight: 600,
                                  color: ch.onSurface,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          due == null
                              ? "Daily payment GHS ${_fmt(info.dailyPayment)}"
                              : "Next payment ${DateFormat("EEE d MMM").format(due)}",
                          style: ptstyle(
                            size: 15,
                            weight: 600,
                            color: ch.onSurface,
                          ),
                        ),
                      if (standing != null &&
                          standing.detail.isNotEmpty &&
                          missed <= 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, left: 16),
                          child: Text(
                            standing.detail,
                            style: ptstyle(
                              size: 12,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                      // The days missed, one red box each.
                      if (missedDates.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final d in missedDates.take(14))
                              _DayCapsule(date: d),
                            if (missedDates.length > 14)
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  "+${missedDates.length - 14}",
                                  style: ptstyle(
                                    size: 12,
                                    weight: 700,
                                    color: _red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder:
                              (_, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 5,
                                color: const Color(0xFF34C759),
                                backgroundColor: const Color(0xFFEDEFF3),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "GHS ${_fmt(info.totalPaid)} paid · GHS ${_fmt(info.balance)} left · GHS ${_fmt(info.dailyPayment)}/day",
                        style: ptstyle(
                          size: 11.5,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- How much ----
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    "Pay for",
                    style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                  ),
                ),
              ),
              if (chips.isNotEmpty)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = chips[i];
                        final sel = identical(_chip, c) ||
                            (_chip != null &&
                                _chip!.key.isNotEmpty &&
                                _chip!.key == c.key);
                        final warn = c.isCatchUp;
                        final tint = warn ? _red : _blue;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _chip = c;
                              _stepDays = null;
                              _exact = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? tint : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    sel
                                        ? tint
                                        : Colors.black.withOpacity(0.07),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.label,
                                  style: ptstyle(
                                    size: 12.5,
                                    weight: 600,
                                    color:
                                        sel
                                            ? Colors.white
                                            : (warn ? _red : ch.onSurface),
                                  ),
                                ),
                                Text(
                                  "GHS ${_fmt(c.amount)}",
                                  style: ptstyle(
                                    size: 11.5,
                                    weight: 400,
                                    color:
                                        sel
                                            ? Colors.white70
                                            : ch.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ---- Or any number of days ----
              if (info.dayPrice > 0) ...[
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _stepDays != null
                                ? _blue
                                : Colors.black.withOpacity(0.07),
                        width: _stepDays != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          "or",
                          style: ptstyle(
                            size: 12.5,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StepBtn(
                          icon: Icons.remove_rounded,
                          onTap: () => _step(-1),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _step(0),
                            child: Text(
                              "${_stepDays ?? 1} day${(_stepDays ?? 1) == 1 ? "" : "s"}",
                              textAlign: TextAlign.center,
                              style: ptstyle(
                                size: 15,
                                weight: 600,
                                color:
                                    _stepDays != null
                                        ? ch.onSurface
                                        : ch.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        _StepBtn(
                          icon: Icons.add_rounded,
                          onTap: () => _step(1),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "= GHS ${_fmt(((_stepDays ?? 1) * info.dayPrice).clamp(0, info.balance > 0 ? info.balance : double.infinity))}",
                          style: ptstyle(
                            size: 13,
                            weight: 600,
                            color:
                                _stepDays != null
                                    ? ch.onSurface
                                    : ch.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],

              // ---- Pay with ----
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: _Box(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child:
                      _changePhone
                          ? TextField(
                            controller: _phoneController,
                            autofocus: true,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            onChanged: (_) => setState(() {}),
                            onSubmitted:
                                (_) => setState(() => _changePhone = false),
                            style: ptstyle(
                              size: 15,
                              weight: 600,
                              color: ch.onSurface,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                              isDense: true,
                              hintText: "MoMo number, e.g. 0244000000",
                              prefixIcon: const Icon(
                                Icons.phone_iphone_rounded,
                                size: 18,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.check_rounded,
                                  color: _blue,
                                ),
                                onPressed:
                                    () => setState(() => _changePhone = false),
                              ),
                            ),
                          )
                          : Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pay with",
                                      style: ptstyle(
                                        size: 11,
                                        weight: 400,
                                        color: ch.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _phoneController.text.isEmpty
                                          ? "Add your MoMo number"
                                          : "MoMo ${_masked(_phoneController.text)}",
                                      style: ptstyle(
                                        size: 14,
                                        weight: 600,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => setState(() => _changePhone = true),
                                child: Text(
                                  "Change",
                                  style: ptstyle(
                                    size: 13,
                                    weight: 600,
                                    color: _blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),

        // ---- One button, always with the amount ----
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          color: const Color(0xFFF5F6F8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    disabledBackgroundColor: _blue.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      amount > 0 &&
                              !_starting &&
                              _phoneController.text.trim().isNotEmpty
                          ? _pay
                          : null,
                  child:
                      _starting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                          : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              "Pay GHS ${_fmt(amount)}",
                              key: ValueKey(amount),
                              style: ptstyle(
                                size: 16,
                                weight: 700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Balance left after: GHS ${_fmt(after)}",
                style: ptstyle(
                  size: 12,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// -1 / +1 on the stepper, 0 just selects it.
  void _step(int delta) {
    final info = _info!;
    HapticFeedback.selectionClick();
    setState(() {
      final now = _stepDays ?? 1;
      _stepDays = (now + (_stepDays == null ? 0 : delta)).clamp(
        info.minDays,
        info.maxDays,
      );
      _chip = null;
      _exact = null;
    });
  }

  Widget _statusView(
    ColorScheme ch, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
    bool busy = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(title),
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 42, color: color),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ptstyle(
                size: 20,
                weight: 700,
                color: ch.onSurface,
              ).copyWith(letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ptstyle(
                size: 13,
                weight: 400,
                color: ch.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (busy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            if (action != null && onAction != null)
              SizedBox(
                width: 220,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onAction,
                  child: Text(action, style: ptstyle(size: 14, weight: 600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18),
    ),
  );
}

/// Red warning shown on the order details page when repayment-info reports
/// the order as overdue.
class OverdueBanner extends StatelessWidget {
  const OverdueBanner({
    super.key,
    required this.daysOverdue,
    required this.catchUpAmount,
  });

  final int daysOverdue;
  final num catchUpAmount;

  @override
  Widget build(BuildContext context) {
    final amount =
        catchUpAmount == catchUpAmount.roundToDouble()
            ? catchUpAmount.toInt().toString()
            : catchUpAmount.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Payment overdue by $daysOverdue day${daysOverdue == 1 ? "" : "s"}. "
              "Pay GHS $amount now to avoid your device being locked.",
              style: ptstyle(size: 11, weight: 600, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// One missed day as a capsule: a red tab on the left (with a small
/// pulsing "!" marker) and the day and date, e.g. "Mon 13 Oct".
class _DayCapsule extends StatefulWidget {
  const _DayCapsule({required this.date});
  final DateTime date;

  @override
  State<_DayCapsule> createState() => _DayCapsuleState();
}

class _DayCapsuleState extends State<_DayCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final d = widget.date;
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 3, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _red.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red tab: "owed".
          AnimatedBuilder(
            animation: _pulse,
            builder:
                (_, _) => Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFE5484D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _red.withOpacity(0.25 + 0.25 * _pulse.value),
                        blurRadius: 4 + 6 * _pulse.value,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat("EEE").format(d),
            style: ptstyle(size: 12, weight: 700, color: _red),
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat("d MMM").format(d),
            style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
          ),
        ],
      ),
    );
  }
}
