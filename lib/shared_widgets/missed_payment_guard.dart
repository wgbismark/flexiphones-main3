import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/ghcard_verification.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _red = Color(0xFFE5484D);

/// Call before any new order (installment or cash). A customer who is
/// behind on a running plan can't order another phone until they catch
/// up: this shows why, with a Pay now button, and returns false.
/// Returns true when they're clear to order.
///
/// The server should enforce the same rule; this keeps people from
/// getting far into checkout first.
Future<bool> ensureNoMissedPayments(BuildContext context) async {
  final p = Provider.of<SharedProvider>(context, listen: false);
  if (p.userData == null) return true;

  // Installment orders need a Ghana Card on file (the server refuses with
  // ghana_card_required); ask before the last step.
  final card = p.userData?.data.ghanaCard;
  if (card == null || "$card".trim().isEmpty) {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ch = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.badge_rounded, size: 52, color: Color(0xFF0071E3)),
              const SizedBox(height: 12),
              Text(
                "Add your Ghana Card",
                textAlign: TextAlign.center,
                style: ptstyle(size: 22, weight: 800, color: ch.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                "To buy a phone on daily payments we need your Ghana Card (GHA-123456789-1). It takes a minute.",
                textAlign: TextAlign.center,
                style: ptstyle(size: 13.5, weight: 400, color: ch.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0071E3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final nav = Navigator.of(ctx);
                    nav.pop();
                    nav.push(
                      CupertinoPageRoute(
                        builder: (_) => GHCardVerification(lateVerification: true),
                      ),
                    );
                  },
                  child: Text("Add Ghana Card", style: ptstyle(size: 15, weight: 700)),
                ),
              ),
            ],
          ),
        );
      },
    );
    return false;
  }
  // Fresh order states (a payment may have just gone through).
  try {
    await Future.wait([
      p.getOrders(refresh: true, next: false),
      p.getOrdersStanding(),
    ]).timeout(const Duration(seconds: 8));
  } catch (_) {}
  // The server's answer (GET /orders/standing) wins; the orders' own
  // standing is the fallback.
  final owing = {
    for (final o in p.ordersStanding?.overdueOrders ?? const []) o.orderId,
  };
  final behind =
      p.orders
          .where((o) => o.hasMissedPayment || owing.contains(o.id))
          .toList();
  if (behind.isEmpty || !context.mounted) return true;

  HapticFeedback.heavyImpact();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MissedPaymentSheet(orders: behind),
  );
  return false;
}

class _MissedPaymentSheet extends StatelessWidget {
  const _MissedPaymentSheet({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ch.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, s, c) => Transform.scale(scale: s, child: c),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock_rounded, size: 42, color: _red),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Catch up first",
                textAlign: TextAlign.center,
                style: ptstyle(size: 24, weight: 800, color: ch.onSurface)
                    .copyWith(letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              Text(
                orders.length == 1
                    ? "You've missed a payment on a phone you're paying for. You can order another phone once you're up to date."
                    : "You've missed payments on ${orders.length} phones you're paying for. You can order another phone once you're up to date.",
                textAlign: TextAlign.center,
                style: ptstyle(size: 13.5, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 20),
              for (final o in orders) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _red.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.network(
                          o.product.image,
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
                            Text(
                              titleCase(o.product.fullName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                            ),
                            Text(
                              o.isDeviceLocked
                                  ? "Locked · GHS ${o.dailyPayment} a day"
                                  : "Payment missed · GHS ${o.dailyPayment} a day",
                              style: ptstyle(size: 12, weight: 600, color: _red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _red,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // The sheet's context goes away on pop: keep
                            // the navigator.
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.push(
                              CupertinoPageRoute(
                                builder: (_) => PayNowScreen(orderId: o.id),
                              ),
                            );
                          },
                          child: Text("Pay now", style: ptstyle(size: 13, weight: 700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Not now",
                  style: ptstyle(size: 14, weight: 600, color: ch.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
