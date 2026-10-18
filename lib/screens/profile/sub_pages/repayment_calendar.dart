import 'dart:math' as math;

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/models/repayment_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/orders/sub_pages/order_details.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/payment_squares.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _green = Color(0xFF30A14E);
const _red = Color(0xFFE5484D);
const _bg = Color(0xFFF2F4F7);

/// Repayments: a progress ring over everything owed, the green/red day
/// squares (tap red days to pay just those), one card per running plan
/// with a Pay button, and the payment history.
class RepaymentCalendar extends StatefulWidget {
  const RepaymentCalendar({super.key});

  @override
  State<RepaymentCalendar> createState() => _RepaymentCalendarState();
}

class _RepaymentCalendarState extends State<RepaymentCalendar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      p.getRepaymentCL(refresh: true, next: false);
    });
  }

  /// Orders that can take a repayment now.
  List<Order> _payable(SharedProvider p) =>
      p.orders
          .where((o) => o.isRunningPlan) // never cash reservations
          .toList();

  Future<void> _refresh(SharedProvider p) async {
    await Future.wait([
      p.getOrders(refresh: true, next: false),
      p.getRepaymentCL(refresh: true, next: false),
    ]);
    if (mounted) setState(() {}); // reloads the squares too
  }

  Future<void> _openPay(Order o, {List<DateTime> days = const []}) async {
    final daily = num.tryParse(o.dailyPayment) ?? 0;
    await NavigationHelper.push(
      context,
      PayNowScreen(
        orderId: o.id,
        selectedDays: days,
        initialAmount: days.isEmpty || daily <= 0 ? null : daily * days.length,
      ),
    );
    if (mounted) _refresh(Provider.of<SharedProvider>(context, listen: false));
  }

  /// Days picked on the squares: pay them on the only running plan, or
  /// ask which phone when there are several.
  Future<void> _payDays(SharedProvider p, List<DateTime> days) async {
    final orders = _payable(p);
    Order? order = orders.length == 1 ? orders.first : null;
    if (order == null) {
      final ch = Theme.of(context).colorScheme;
      order = await showModalBottomSheet<Order>(
        context: context,
        showDragHandle: true,
        backgroundColor: ch.surface,
        builder:
            (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      "Pay for which phone?",
                      style: ptstyle(size: 18, weight: 700, color: ch.onSurface),
                    ),
                  ),
                  for (final o in orders)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: _Thumb(url: o.product.image, size: 44),
                      title: Text(
                        titleCase(o.product.fullName),
                        style: ptstyle(
                          size: 14,
                          weight: 600,
                          color: ch.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        "GHS ${o.dailyPayment} a day",
                        style: ptstyle(
                          size: 12,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(ctx).pop(o),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
      );
    }
    if (order == null || !mounted) return;
    _openPay(order, days: days);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final plans = _payable(p);
    num total = 0, paid = 0, daily = 0;
    for (final o in plans) {
      total += num.tryParse(o.totalPayment) ?? 0;
      paid += num.tryParse(o.totalPaid ?? "") ?? 0;
      daily += num.tryParse(o.dailyPayment) ?? 0;
    }
    final locked = plans.where((o) => o.isDeviceLocked).length;
    final history = List<RepaymentEntry>.from(p.repaymentCL)
      ..sort((a, b) => b.datePaid.compareTo(a.datePaid));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(p),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            FadeSlideIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  "Repayments",
                  style: ptstyle(
                    size: 30,
                    weight: 800,
                    color: ch.onSurface,
                  ).copyWith(letterSpacing: -1),
                ),
              ),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _Overview(
                total: total,
                paid: paid,
                daily: daily,
                plans: plans.length,
                locked: locked,
              ),
            ),
            const SizedBox(height: 16),
            if (p.orders.isNotEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: PaymentSquares(
                  key: ValueKey("sq-${p.orders.length}-${history.length}"),
                  title: "All my phones",
                  dailyPayment:
                      plans.length == 1
                          ? num.tryParse(plans.first.dailyPayment)
                          : null,
                  onPayDays:
                      plans.isEmpty ? null : (days) => _payDays(p, days),
                ),
              ),
            if (plans.isNotEmpty) ...[
              _title(ch, "Running plans"),
              for (var i = 0; i < plans.length; i++) ...[
                FadeSlideIn(
                  delay: Duration(milliseconds: 160 + 50 * i),
                  child: _PlanCard(
                    order: plans[i],
                    onPay: () => _openPay(plans[i]),
                    onOpen: () {
                      p.getOrder(plans[i].id);
                      NavigationHelper.push(context, OrderDetailsWidget());
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
            _title(ch, "History"),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ch.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  "Payments you make will be listed here.",
                  textAlign: TextAlign.center,
                  style: ptstyle(
                    size: 13,
                    weight: 400,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: ch.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < history.length; i++) ...[
                      _HistoryRow(entry: history[i]),
                      if (i < history.length - 1)
                        Divider(
                          height: 1,
                          indent: 66,
                          color: ch.onSurface.withOpacity(0.06),
                        ),
                    ],
                  ],
                ),
              ),
            if (p.rNextPAGE != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () => p.getRepaymentCL(refresh: false, next: true),
                  child: Text(
                    "Load older payments",
                    style: ptstyle(size: 13, weight: 600, color: _blue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _title(ColorScheme ch, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
    child: Text(
      text,
      style: ptstyle(
        size: 19,
        weight: 800,
        color: ch.onSurface,
      ).copyWith(letterSpacing: -0.5),
    ),
  );
}

/// Dark card with a progress ring: how much of everything is paid.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.total,
    required this.paid,
    required this.daily,
    required this.plans,
    required this.locked,
  });

  final num total;
  final num paid;
  final num daily;
  final int plans;
  final int locked;

  String _m(num v) => v.toDouble().toCommaSeparated(0, decimalPlaces: 0);

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D1D1F), Color(0xFF3A3A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder:
                      (_, v, _) => CustomPaint(
                        painter: _RingPainter(v),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${(v * 100).round()}%",
                                style: ptstyle(
                                  size: 22,
                                  weight: 800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "paid",
                                style: ptstyle(
                                  size: 11,
                                  weight: 500,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LEFT TO PAY",
                      style: ptstyle(
                        size: 10,
                        weight: 700,
                        color: Colors.white54,
                      ).copyWith(letterSpacing: 1.3),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "GHS ${_m(math.max(0, total - paid))}",
                        style: ptstyle(
                          size: 26,
                          weight: 800,
                          color: Colors.white,
                        ).copyWith(letterSpacing: -0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "GHS ${_m(paid)} paid of ${_m(total)}",
                      style: ptstyle(
                        size: 12,
                        weight: 400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _pill("Plans", "$plans"),
              const SizedBox(width: 8),
              _pill("Daily total", "GHS ${_m(daily)}"),
              const SizedBox(width: 8),
              _pill(
                "Locked",
                "$locked",
                warn: locked > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, {bool warn = false}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: warn ? _red.withOpacity(0.25) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ptstyle(size: 10, weight: 500, color: Colors.white60),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: ptstyle(size: 14, weight: 700, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 6,
    );
    final base =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Colors.white.withOpacity(0.12);
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    final arc =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [Color(0xFF30D158), Color(0xFF64D2FF), Color(0xFF30D158)],
          ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.order,
    required this.onPay,
    required this.onOpen,
  });

  final Order order;
  final VoidCallback onPay;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final total = double.tryParse(order.totalPayment) ?? 0;
    final paid = double.tryParse(order.totalPaid ?? "") ?? 0;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final locked = order.isDeviceLocked;
    final due = DateTime.tryParse(order.nextDue ?? "");
    final overdue = due != null && due.isBefore(DateTime.now());

    return PressScale(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: BorderRadius.circular(24),
          border: locked ? Border.all(color: _red.withOpacity(0.5)) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _Thumb(url: order.product.image, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleCase(order.product.fullName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(
                          size: 15,
                          weight: 700,
                          color: ch.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            locked
                                ? Icons.lock_rounded
                                : overdue
                                ? Icons.warning_amber_rounded
                                : Icons.event_rounded,
                            size: 13,
                            color:
                                locked || overdue ? _red : ch.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locked
                                  ? "Locked · pay to unlock"
                                  : due == null
                                  ? "GHS ${order.dailyPayment} a day"
                                  : overdue
                                  ? "Overdue since ${due.toLocal().formatDateNoTime()}"
                                  : "Next due ${due.toLocal().formatDateNoTime()}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(
                                size: 12,
                                weight: 500,
                                color:
                                    locked || overdue
                                        ? _red
                                        : ch.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: locked || overdue ? _red : _blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPay,
                    child: Text("Pay", style: ptstyle(size: 13, weight: 700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 6,
                color: locked ? _red : _green,
                backgroundColor: ch.onSurface.withOpacity(0.07),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  "GHS ${paid.toCommaSeparated(0, decimalPlaces: 0)} of ${total.toCommaSeparated(0, decimalPlaces: 0)}",
                  style: ptstyle(size: 11.5, weight: 600, color: ch.onSurface),
                ),
                const Spacer(),
                Text(
                  "GHS ${order.dailyPayment}/day",
                  style: ptstyle(size: 11.5, weight: 600, color: _blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final RepaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final ok = entry.status.toLowerCase() != "failed";
    final amount = double.tryParse(entry.amountPaid) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (ok ? _green : _red).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.arrow_downward_rounded : Icons.close_rounded,
              size: 18,
              color: ok ? _green : _red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleCase(entry.application.product.fullName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 13.5, weight: 600, color: ch.onSurface),
                ),
                Text(
                  entry.datePaid.toLocal().formatDateNoTime(),
                  style: ptstyle(
                    size: 11.5,
                    weight: 400,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "GHS ${amount.toCommaSeparated(0, decimalPlaces: 2)}",
                style: ptstyle(
                  size: 14,
                  weight: 700,
                  color: ok ? ch.onSurface : _red,
                ),
              ),
              Text(
                ok ? "Paid" : "Failed",
                style: ptstyle(
                  size: 11,
                  weight: 500,
                  color: ok ? _green : _red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder:
            (_, _, _) => Opacity(
              opacity: 0.4,
              child: Image.asset(AssetsHelper.dummyImage),
            ),
      ),
    );
  }
}
