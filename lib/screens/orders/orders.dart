import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/helpers/st_values.dart';
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/cash/cash_checkout.dart' show CashReservationScreen;
import 'package:flexiphones/screens/orders/sub_pages/order_details.dart';
import 'package:flexiphones/screens/profile/sub_pages/repayment_calendar.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _bg = Color(0xFFF2F4F7);

/// Orders: a big title, a repayments card for running plans, a sliding
/// filter (All / Placed / Delivered / Cancelled) and one card per order
/// with its status, plan progress and lock / paid-off badges.
class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);

    final List<Order> list = List<Order>.from(
      switch (p.showP) {
        1 => p.ordersStatusPlaced,
        2 => p.ordersStatusCancelled,
        3 => p.ordersStatusDelivered,
        _ => p.orders,
      },
    )..sort(
      (a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
    );
    final running =
        p.orders
            .where((o) => o.isRunningPlan)
            .toList();
    final locked = running.where((o) => o.isDeviceLocked).length;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () => p.getOrders(refresh: true, next: false),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical &&
                n.metrics.extentAfter < 400 &&
                p.oNextPAGE != null &&
                !p.refreshing_) {
              p.moreData(type: RefreshParam.orders, context: context);
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Orders",
                          style: ptstyle(
                            size: 30,
                            weight: 800,
                            color: ch.onSurface,
                          ).copyWith(letterSpacing: -1),
                        ),
                        Text(
                          "${p.orders.length} order${p.orders.length == 1 ? "" : "s"} · ${running.length} running plan${running.length == 1 ? "" : "s"}",
                          style: ptstyle(
                            size: 13,
                            weight: 500,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _RepaymentsCard(
                      running: running.length,
                      locked: locked,
                      onTap: () {
                        p.getRepaymentCL(refresh: true, next: false);
                        NavigationHelper.push(context, RepaymentCalendar());
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _Filter(
                    selected: p.showP,
                    labels: [
                      ("All", p.orders.length),
                      ("Placed", p.ordersStatusPlaced.length),
                      ("Cancelled", p.ordersStatusCancelled.length),
                      ("Delivered", p.ordersStatusDelivered.length),
                    ],
                    onSelect: (i) {
                      HapticFeedback.selectionClick();
                      p.switchOrders(i);
                    },
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyOrders(filtered: p.showP != 0),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder:
                        (_, i) => FadeSlideIn(
                          key: ValueKey("o-${list[i].id}"),
                          delay: Duration(milliseconds: 40 * (i % 6)),
                          child: OrderCard(item: list[i]),
                        ),
                  ),
                ),
              if (p.refreshing_)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
}

class _RepaymentsCard extends StatelessWidget {
  const _RepaymentsCard({
    required this.running,
    required this.locked,
    required this.onTap,
  });

  final int running;
  final int locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1A33), Color(0xFF1B4E9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4E9B).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Repayments",
                    style: ptstyle(size: 16, weight: 700, color: Colors.white),
                  ),
                  Text(
                    locked > 0
                        ? "$locked phone${locked == 1 ? " is" : "s are"} locked · pay to unlock"
                        : running == 0
                        ? "Your payment calendar and history"
                        : "$running plan${running == 1 ? "" : "s"} running · see your days",
                    style: ptstyle(
                      size: 12,
                      weight: 400,
                      color:
                          locked > 0
                              ? const Color(0xFFFFB4B4)
                              : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Segmented control with counts and a sliding white thumb.
class _Filter extends StatelessWidget {
  const _Filter({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<(String, int)> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8) / labels.length;
        return Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ch.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: w * selected,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: ch.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: labels[i].$1,
                                    style: ptstyle(
                                      size: 12.5,
                                      weight: i == selected ? 700 : 500,
                                      color:
                                          i == selected
                                              ? ch.onSurface
                                              : ch.onSurfaceVariant,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " ${labels[i].$2}",
                                    style: ptstyle(
                                      size: 11,
                                      weight: 600,
                                      color:
                                          i == selected
                                              ? _blue
                                              : ch.onSurfaceVariant.withOpacity(
                                                0.6,
                                              ),
                                    ),
                                  ),
                                ],
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

/// One order. Also used on the rating page.
class OrderCard extends StatelessWidget {
  final Order item;
  const OrderCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final ch = Theme.of(context).colorScheme;
    final stageColor = STV.getOrderStageColor(item.stage, ch);
    final total = double.tryParse(item.totalPayment) ?? 0;
    final paid = double.tryParse(item.totalPaid ?? "") ?? 0;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final cash = item.isCash;
    final cashDone = cash && item.isPaid;
    final running = !cash && item.isPaid && item.stage != "cancelled";
    final done = !cash && item.isFullyPaid;
    final locked = !cash && item.isDeviceLocked && !done;
    final date = DateTime.tryParse(item.createdAt);

    return PressScale(
      onTap: () {
        // A cash reservation opens its QR / status, not the plan screens.
        if (cash && (item.cashReference ?? "").isNotEmpty) {
          NavigationHelper.push(
            context,
            CashReservationScreen(reference: item.cashReference!),
          );
          return;
        }
        p.getOrder(item.id);
        NavigationHelper.push(context, OrderDetailsWidget());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              locked
                  ? Border.all(color: const Color(0xFFE5484D).withOpacity(0.5))
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.network(
                    item.product.image,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, _, _) => Opacity(
                          opacity: 0.4,
                          child: Image.asset(AssetsHelper.dummyImage),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titleCase(item.product.fullName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(
                                size: 15,
                                weight: 700,
                                color: ch.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusPill(
                            text:
                                cash
                                    ? (item.stage == "cancelled"
                                        ? "Cancelled"
                                        : cashDone
                                        ? "Collected"
                                        : "Pay at shop")
                                    : locked
                                    ? "Locked"
                                    : done
                                    ? "Paid off"
                                    : item.statusLabel,
                            color:
                                cash
                                    ? (item.stage == "cancelled"
                                        ? const Color(0xFFE5484D)
                                        : cashDone
                                        ? const Color(0xFF30A14E)
                                        : const Color(0xFFFF9F0A))
                                    : locked
                                    ? const Color(0xFFE5484D)
                                    : done
                                    ? const Color(0xFF30A14E)
                                    : stageColor,
                            icon:
                                cash
                                    ? Icons.payments_rounded
                                    : locked
                                    ? Icons.lock_rounded
                                    : done
                                    ? Icons.verified_rounded
                                    : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          item.productStorage.storage,
                          if (item.color.isNotEmpty) titleCase(item.color),
                          if (item.vendor.name.isNotEmpty) item.vendor.name,
                        ].join(" · "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ptstyle(
                          size: 12,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        date == null
                            ? "Order #${item.id}"
                            : "Order #${item.id} · ${date.toLocal().formatDateNoTime()}",
                        style: ptstyle(
                          size: 11,
                          weight: 400,
                          color: ch.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (running && total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder:
                      (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color:
                            locked
                                ? const Color(0xFFE5484D)
                                : const Color(0xFF30A14E),
                        backgroundColor: ch.onSurface.withOpacity(0.07),
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    "GHS ${paid.toCommaSeparated(0, decimalPlaces: 0)} of ${total.toCommaSeparated(0, decimalPlaces: 0)}",
                    style: ptstyle(
                      size: 11.5,
                      weight: 600,
                      color: ch.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (!done)
                    Text(
                      "GHS ${item.dailyPayment}/day",
                      style: ptstyle(size: 11.5, weight: 600, color: _blue),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(text, style: ptstyle(size: 10.5, weight: 700, color: color)),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ch.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 44,
              color: _blue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filtered ? "Nothing here" : "No orders yet",
            style: ptstyle(size: 19, weight: 800, color: ch.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? "No orders match this filter."
                : "When you order a phone it shows up here.",
            textAlign: TextAlign.center,
            style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
