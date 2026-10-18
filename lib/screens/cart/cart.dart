import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/order_confirmation/confirm_order.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/missed_payment_guard.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart'
    show swatchFor, titleCase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _bg = Color(0xFFF2F4F7);

/// The bag: one card per phone (swipe left to remove), a round tick to
/// pick what to check out, and a pinned summary with what's due today and
/// what's paid daily after.
class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  ShoppingCartScreenState createState() => ShoppingCartScreenState();
}

class ShoppingCartScreenState extends State<ShoppingCartScreen> {
  void _open(dynamic item, SharedProvider p) {
    p.getProductDetails(item["id"], context);
    NavigationHelper.push(context, ProductDetailsPage(productId: item["id"]));
  }

  /// This item's chosen plan from its saved breakdowns.
  static Map? _plan(dynamic item) {
    final b = item["breakdowns"];
    if (b is! Map) return null;
    final m = b["${item["service_tenure"]}_months"];
    return m is Map ? m : null;
  }

  static num _n(dynamic v) => num.tryParse("${v ?? ''}") ?? 0;

  static String _money(num v) =>
      v.toDouble().toCommaSeparated(0, decimalPlaces: 2);

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final items = p.cartItems;

    num today = 0, daily = 0;
    for (final it in p.selectedItems) {
      final plan = _plan(it);
      final q = _n(it["quantity"]).clamp(1, 99);
      today += _n(plan?["initial_payment"]) * q;
      daily += _n(plan?["daily_payment"]) * q;
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Bag",
                        style: ptstyle(
                          size: 30,
                          weight: 800,
                          color: ch.onSurface,
                        ).copyWith(letterSpacing: -1),
                      ),
                      Text(
                        items.isEmpty
                            ? "Nothing here yet"
                            : "${items.length} phone${items.length == 1 ? "" : "s"} · ${p.selectedCount} selected",
                        style: ptstyle(
                          size: 13,
                          weight: 500,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  if (p.selectedCount > 0)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        p.removeSelectedItems();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE5484D),
                      ),
                      child: Text(
                        "Remove",
                        style: ptstyle(size: 13, weight: 600),
                      ),
                    ),
                  TextButton(
                    onPressed: () => p.selectAllCartItem(),
                    style: TextButton.styleFrom(foregroundColor: _blue),
                    child: Text(
                      p.selectedCount == items.length ? "Deselect" : "Select all",
                      style: ptstyle(size: 13, weight: 600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child:
                items.isEmpty
                    ? _Empty()
                    : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return FadeSlideIn(
                          key: ValueKey("bag-${item["id"]}-$i"),
                          delay: Duration(milliseconds: 50 * (i % 6)),
                          child: Dismissible(
                            key: ValueKey("d-${item["id"]}-$i-${items.length}"),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              p.removeCartItem(i);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5484D),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                            child: _BagItem(
                              item: item,
                              plan: _plan(item),
                              money: _money,
                              onToggle: () {
                                HapticFeedback.selectionClick();
                                p.selectCartItem(i);
                              },
                              onOpen: () => _open(item, p),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (items.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                16 + MediaQuery.of(context).padding.bottom * 0,
              ),
              decoration: BoxDecoration(
                color: ch.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _total(ch, "Due today", "GHS ${_money(today)}", ch.onSurface),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: ch.onSurface.withOpacity(0.08),
                      ),
                      _total(ch, "Then daily", "GHS ${_money(daily)}", _blue),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: ch.onSurface.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed:
                          !p.checked
                              ? null
                              : () async {
                                HapticFeedback.mediumImpact();
                                if (p.userData == null) {
                                  NavigationHelper.push(context, EmailSignin());
                                  return;
                                }
                                // Behind on a plan? No new phones yet.
                                if (!await ensureNoMissedPayments(context)) {
                                  return;
                                }
                                if (!context.mounted) return;
                                NavigationHelper.push(
                                  context,
                                  OrderConfirmation(items: p.selectedItems),
                                );
                              },
                      child: Text(
                        p.userData == null
                            ? "Sign in to check out"
                            : p.selectedCount == 0
                            ? "Select a phone"
                            : "Check out (${p.selectedCount})",
                        style: ptstyle(size: 15, weight: 700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _total(ColorScheme ch, String label, String value, Color color) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: ptstyle(
                  size: 20,
                  weight: 800,
                  color: color,
                ).copyWith(letterSpacing: -0.5),
              ),
            ),
          ],
        ),
      );
}

class _BagItem extends StatelessWidget {
  const _BagItem({
    required this.item,
    required this.plan,
    required this.money,
    required this.onToggle,
    required this.onOpen,
  });

  final dynamic item;
  final Map? plan;
  final String Function(num) money;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final selected = item["isSelected"] == true;
    final storage =
        item["product_storages"] is Map
            ? "${item["product_storages"]["storage"] ?? ""}"
            : "";
    final color = "${item["color"] ?? ""}";
    final vendor = "${item["vendor"] ?? ""}";
    final today = num.tryParse("${plan?["initial_payment"] ?? ''}");
    final daily = num.tryParse("${plan?["daily_payment"] ?? ''}");

    return GestureDetector(
      onTap: onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? _blue.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _blue : Colors.transparent,
                    border: Border.all(
                      color: selected ? _blue : ch.onSurface.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child:
                      selected
                          ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                          : null,
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.network(
                "${item["image"]}",
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
                    titleCase("${item["productName"]}"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
                  ),
                  if (vendor.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 12,
                          color: ch.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            vendor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 11,
                              weight: 500,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (storage.isNotEmpty) _pill(ch, storage),
                      _pill(ch, "${item["service_tenure"]} months"),
                      if (color.isNotEmpty)
                        _pill(ch, titleCase(color), dot: swatchFor(color)),
                      if (item["package_id"] is int)
                        _pill(ch, "+ Bonus", accent: const Color(0xFFFF375F)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (today != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "GHS ${money(today)} today",
                            style: ptstyle(
                              size: 13,
                              weight: 700,
                              color: ch.onSurface,
                            ),
                          ),
                          if (daily != null)
                            TextSpan(
                              text: "  ·  GHS ${money(daily)}/day",
                              style: ptstyle(
                                size: 12,
                                weight: 500,
                                color: _blue,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(ColorScheme ch, String text, {Color? dot, Color? accent}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (accent ?? ch.onSurface).withOpacity(0.06),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: ch.onSurface.withOpacity(0.15)),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: ptstyle(
                size: 10.5,
                weight: 600,
                color: accent ?? ch.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
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
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                "Your bag is empty",
                style: ptstyle(size: 20, weight: 800, color: ch.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                "Phones you add to your bag show up here.",
                textAlign: TextAlign.center,
                style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
