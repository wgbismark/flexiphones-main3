import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/models/standing_m.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two small status rows on the order screen: the phone itself
/// (`phone_state`) and the payments (`repayment_standing`). Red ones get a
/// Catch up button.
class OrderStatusChips extends StatelessWidget {
  const OrderStatusChips({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final phone = order.phoneState;
    final pay = order.standing;
    if (phone == null && pay == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            if (phone != null && phone.label.isNotEmpty)
              _Row(
                icon: Icons.phone_iphone_rounded,
                color: phone.color,
                label: phone.label,
                detail: phone.detail,
              ),
            if (phone != null &&
                phone.label.isNotEmpty &&
                pay != null &&
                pay.label.isNotEmpty &&
                pay.state != "cash")
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 48,
                color: Colors.black.withOpacity(0.08),
              ),
            if (pay != null && pay.label.isNotEmpty && pay.state != "cash")
              _Row(
                icon:
                    pay.isLocked
                        ? Icons.lock_rounded
                        : Icons.calendar_month_rounded,
                color: pay.color,
                label: pay.label,
                detail:
                    pay.isLocked
                        ? "Pay GHS ${pay.amountOverdue.toStringAsFixed(2)} to unlock it straight away."
                        : pay.detail,
                action:
                    pay.isOwing
                        ? () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => PayNowScreen(orderId: order.id),
                          ),
                        )
                        : null,
                actionLabel:
                    "Catch up GHS ${pay.amountOverdue.toStringAsFixed(pay.amountOverdue % 1 == 0 ? 0 : 2)}",
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    required this.detail,
    this.action,
    this.actionLabel,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String detail;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ptstyle(size: 13, weight: 600, color: color),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: ptstyle(
                      size: 11.5,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: action,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        actionLabel ?? "Pay now",
                        style: ptstyle(
                          size: 12,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The first time an order's phone is `ready`: "Your SAMSUNG A15 is ready."
/// Shown once per order.
Future<void> maybeShowPhoneReady(BuildContext context, Order order) async {
  final ps = order.phoneState;
  if (ps == null || ps.key != "ready") return;
  final key = "phone_ready_seen_${order.id}";
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final ch = Theme.of(ctx).colorScheme;
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, s, c) => Transform.scale(scale: s, child: c),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: severityColor("ok").withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_iphone_rounded,
                    size: 36,
                    color: severityColor("ok"),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your ${ps.device.isNotEmpty ? ps.device : "phone"} is ready",
                textAlign: TextAlign.center,
                style: ptstyle(size: 20, weight: 700, color: ch.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                ps.detail.isNotEmpty
                    ? ps.detail
                    : "Collect it from the shop.",
                textAlign: TextAlign.center,
                style: ptstyle(
                  size: 13,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0071E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    "Got it",
                    style: ptstyle(size: 15, weight: 700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
