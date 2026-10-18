import 'package:flexiphones/models/order_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/orders/sub_pages/pay_now.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart' show titleCase;
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _red = Color(0xFFE5484D);

/// Floating "Pay" pill for anyone on a running plan, so paying today (or
/// catching up missed days) is always one tap away. Red when behind.
/// Hidden when there's no plan to pay.
class QuickPayButton extends StatelessWidget {
  const QuickPayButton({super.key});

  static Future<void> open(BuildContext context) async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final plans = p.orders.where((o) => o.isRunningPlan).toList()
      ..sort(
        (a, b) =>
            (b.hasMissedPayment ? 1 : 0).compareTo(a.hasMissedPayment ? 1 : 0),
      );
    if (plans.isEmpty) return;
    final nav = Navigator.of(context);
    void go(Order o) => nav.push(
      CupertinoPageRoute(builder: (_) => PayNowScreen(orderId: o.id)),
    );
    if (plans.length == 1) return go(plans.first);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ch = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
             child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ch.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Which phone?",
                  style: ptstyle(size: 18, weight: 700, color: ch.onSurface),
                ),
                const SizedBox(height: 12),
                for (final o in plans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          go(o);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color:
                                      o.hasMissedPayment
                                          ? _red
                                          : const Color(0xFF34C759),
                                  shape: BoxShape.circle,
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
                                      style: ptstyle(
                                        size: 14,
                                        weight: 600,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                    Text(
                                      o.standing?.label.isNotEmpty == true
                                          ? o.standing!.label
                                          : (o.hasMissedPayment
                                              ? "Behind: catch up now"
                                              : "Tap to pay"),
                                      style: ptstyle(
                                        size: 12,
                                        weight: 400,
                                        color:
                                            o.hasMissedPayment
                                                ? _red
                                                : ch.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((o.standing?.amountOverdue ?? 0) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    "GHS ${o.standing!.amountOverdue}",
                                    style: ptstyle(
                                      size: 13,
                                      weight: 700,
                                      color: _red,
                                    ),
                                  ),
                                ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: ch.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final plans = p.orders.where((o) => o.isRunningPlan).toList();
    final behind = plans.any((o) => o.hasMissedPayment);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (c, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
            child: c,
          ),
      child:
          plans.isEmpty
              ? const SizedBox.shrink(key: ValueKey("none"))
              : PressScale(
                key: ValueKey(behind),
                onTap: () {
                  HapticFeedback.selectionClick();
                  open(context);
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          behind
                              ? const [Color(0xFFFF5A5F), Color(0xFFD7263D)]
                              : const [Color(0xFF2E8BFF), Color(0xFF0058C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: (behind ? _red : _blue).withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        behind
                            ? Icons.error_outline_rounded
                            : Icons.bolt_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        behind ? "Catch up" : "Pay today",
                        style: ptstyle(
                          size: 14,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
