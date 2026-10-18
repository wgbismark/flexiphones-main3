import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/models/price_model.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/product_tile.dart'
    show colorNamesOf, swatchFor, titleCase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

const _blue = Color(0xFF0071E3);
const _green = Color(0xFF30A14E);

/// Opens the "configure your phone" sheet used by both Add to Bag and Buy
/// Now: storage, colour and payment plan, with a live summary and one
/// button pinned at the bottom. It sizes itself to the screen and scrolls,
/// so it never overflows on small phones.
///
/// [onBuyNow] is called (after the sheet closes) when [buyNow] is true.
Future<void> showPurchaseSheet(
  BuildContext context, {
  required bool buyNow,
  ProductStorage? initialStorage,
  required void Function(ProductModel product, ProductStorage storage)
  onBuyNow,
}) async {
  final p = Provider.of<SharedProvider>(context, listen: false);
  final product = p.productData;
  if (product == null || (product.productStorages ?? []).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No storage options for this phone yet.")),
    );
    return;
  }
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _PurchaseSheet(
          buyNow: buyNow,
          initialStorage: initialStorage,
          onBuyNow: onBuyNow,
        ),
  );
}

class _PurchaseSheet extends StatefulWidget {
  const _PurchaseSheet({
    required this.buyNow,
    required this.onBuyNow,
    this.initialStorage,
  });

  final bool buyNow;
  final ProductStorage? initialStorage;
  final void Function(ProductModel, ProductStorage) onBuyNow;

  @override
  State<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends State<_PurchaseSheet> {
  int? _pendingStorageId;

  /// Buy now: the customer confirms they understand the down payment.
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      final product = p.productData!;
      final storages = product.productStorages!;
      final want =
          widget.initialStorage ?? p.selectedStorage ?? storages.first;
      if (p.colorSL.isEmpty || !colorNamesOf(product.colors).contains(p.colorSL)) {
        final colors = colorNamesOf(product.colors);
        p.colorSL = colors.isNotEmpty ? colors.first : "";
      }
      _pickStorage(p, want, force: p.breakDownPrice == null);
    });
  }

  Future<void> _pickStorage(
    SharedProvider p,
    ProductStorage s, {
    bool force = false,
  }) async {
    if (!force && p.selectedStorage?.id == s.id && p.breakDownPrice != null) {
      return;
    }
    setState(() => _pendingStorageId = s.id);
    await p.getProductPB(s.id);
    if (!mounted) return;
    p.selectedStorage = s;
    // Keep the chosen term if this storage offers it, else the first one.
    final months = p.breakDownPrice?.breakdowns.months;
    if (months != null && months.isNotEmpty) {
      final terms =
          months.values
              .map((m) => int.tryParse("${m is Map ? m['tenure_months'] : ''}"))
              .whereType<int>()
              .toList();
      if (terms.isNotEmpty && !terms.contains(p.slTenure)) {
        p.selectTenure(terms.first);
      }
    }
    setState(() => _pendingStorageId = null);
    p.selectTenure(p.slTenure); // notify
  }

  num _n(dynamic v) => num.tryParse("${v ?? ''}") ?? 0;

  String _money(num v, {int dp = 2}) =>
      v.toDouble().toCommaSeparated(0, decimalPlaces: dp);

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final product = p.productData;
    if (product == null) return const SizedBox();
    final storages = product.productStorages ?? [];
    final colors = colorNamesOf(product.colors);
    final selected = p.selectedStorage;
    final months = p.breakDownPrice?.breakdowns.months ?? const {};
    final term = p.selectedTerm;
    final loading = p.loadingPBD || _pendingStorageId != null;
    final financeable = term == null || isFinanceable(term);
    final ready =
        selected != null &&
        !loading &&
        p.breakDownPrice != null &&
        term != null &&
        financeable &&
        (!widget.buyNow || _understood);
    final maxH = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
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
            // Header: the phone and what's chosen so far
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, _, _) => Opacity(
                            opacity: 0.4,
                            child: Image.asset(AssetsHelper.dummyImage),
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleCase(product.fullName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(
                            size: 16,
                            weight: 700,
                            color: ch.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (selected != null) selected.storage,
                            if (p.colorSL.isNotEmpty) titleCase(p.colorSL),
                            if (term != null) "${p.slTenure} months",
                          ].join(" · "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ptstyle(
                            size: 12,
                            weight: 400,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: ch.onSurface.withOpacity(0.06),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: ch.onSurface.withOpacity(0.06)),
            // Options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _label(ch, "Storage"),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in storages)
                        _OptionCard(
                          selected:
                              (_pendingStorageId ?? selected?.id) == s.id,
                          loading: _pendingStorageId == s.id,
                          title: s.storage,
                          subtitle:
                              _n(s.cashPrice) > 0
                                  ? "GHS ${_money(_n(s.cashPrice), dp: 0)}"
                                  : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pickStorage(p, s);
                          },
                        ),
                    ],
                  ),
                  if (colors.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _label(ch, "Colour"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in colors)
                          _ColorChip(
                            name: c,
                            selected: p.colorSL == c,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              p.selectColor(c);
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  _label(ch, "Payment plan"),
                  if (loading && months.isEmpty)
                    _shimmer(ch)
                  else if (months.isEmpty)
                    _note(ch, "Plans aren't available for this storage yet.")
                  else ...[
                    _TermSwitch(
                      terms:
                          months.values
                              .whereType<Map>()
                              .map((m) => int.tryParse("${m['tenure_months']}"))
                              .whereType<int>()
                              .toList(),
                      selected: p.slTenure,
                      onSelect: (t) {
                        HapticFeedback.selectionClick();
                        p.selectTenure(t);
                      },
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child:
                          loading
                              ? _shimmer(ch)
                              : term == null
                              ? _note(ch, "Pick a plan above.")
                              : !financeable
                              ? _note(ch, notFinanceableText, error: true)
                              : _PlanSummary(
                                key: ValueKey("${selected?.id}-${p.slTenure}"),
                                today: _n(term['initial_payment']),
                                daily: _n(term['daily_payment']),
                                total: _n(term['total_price']),
                                days: p.slTenure * 30,
                                money: _money,
                              ),
                    ),
                    if (!loading && term != null && financeable) ...[
                      const SizedBox(height: 12),
                      _HowItWorks(
                        today: _n(term['initial_payment']),
                        daily: _n(term['daily_payment']),
                        total: _n(term['total_price']),
                        days: p.slTenure * 30,
                        money: _money,
                      ),
                      if (widget.buyNow) ...[
                        const SizedBox(height: 12),
                        _UnderstandTick(
                          value: _understood,
                          today: _money(_n(term['initial_payment'])),
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _understood = v);
                          },
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            // Pinned action
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: ch.surface,
                border: Border(
                  top: BorderSide(color: ch.onSurface.withOpacity(0.06)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Pay today",
                          style: ptstyle(
                            size: 11,
                            weight: 500,
                            color: ch.onSurfaceVariant,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            term == null || !financeable
                                ? "—"
                                : "GHS ${_money(_n(term['initial_payment']))}",
                            style: ptstyle(
                              size: 20,
                              weight: 800,
                              color: ch.onSurface,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.buyNow ? _blue : ch.onSurface,
                        foregroundColor: ch.surface,
                        disabledBackgroundColor: ch.onSurface.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed:
                          !ready
                              ? null
                              : () {
                                HapticFeedback.mediumImpact();
                                final product = p.productData!;
                                final storage = p.selectedStorage!;
                                if (widget.buyNow) {
                                  Navigator.of(context).pop();
                                  widget.onBuyNow(product, storage);
                                  return;
                                }
                                p.addToCart(
                                  product,
                                  storage,
                                  p.slTenure,
                                  p.colorSL,
                                  null,
                                  p.breakDownPrice,
                                );
                                final messenger = ScaffoldMessenger.of(
                                  context,
                                );
                                Navigator.of(context).pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      "Added ${titleCase(product.model)} to your bag",
                                    ),
                                  ),
                                );
                              },
                      icon: Icon(
                        widget.buyNow
                            ? Icons.bolt_rounded
                            : Icons.shopping_bag_rounded,
                        size: 19,
                      ),
                      label: Text(
                        widget.buyNow ? "Checkout" : "Add to Bag",
                        style: ptstyle(size: 15, weight: 700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ColorScheme ch, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
    ),
  );

  Widget _note(ColorScheme ch, String text, {bool error = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: (error ? Colors.red : ch.onSurface).withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: ptstyle(
        size: 12,
        weight: 500,
        color: error ? Colors.red.shade700 : ch.onSurfaceVariant,
      ),
    ),
  );

  Widget _shimmer(ColorScheme ch) => Shimmer.fromColors(
    baseColor: ch.onSurface.withOpacity(0.05),
    highlightColor: ch.onSurface.withOpacity(0.1),
    child: Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.loading = false,
  });

  final bool selected;
  final bool loading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.06) : ch.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _blue : ch.onSurface.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: ptstyle(
                      size: 11,
                      weight: 500,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (loading) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.06) : ch.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? _blue : ch.onSurface.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: swatchFor(name),
                shape: BoxShape.circle,
                border: Border.all(color: ch.onSurface.withOpacity(0.15)),
              ),
              child:
                  selected
                      ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color:
                            swatchFor(name).computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Text(
              titleCase(name),
              style: ptstyle(size: 13, weight: 600, color: ch.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented control for 3 / 4 / 5 / 6 months with a sliding thumb.
class _TermSwitch extends StatelessWidget {
  const _TermSwitch({
    required this.terms,
    required this.selected,
    required this.onSelect,
  });

  final List<int> terms;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final i = terms.indexOf(selected).clamp(0, terms.length - 1);
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8) / terms.length;
        return Container(
          height: 48,
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
                left: w * i,
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
                  for (final t in terms)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(t),
                        child: Center(
                          child: Text(
                            "$t mo",
                            style: ptstyle(
                              size: 13,
                              weight: t == selected ? 700 : 500,
                              color:
                                  t == selected
                                      ? ch.onSurface
                                      : ch.onSurfaceVariant,
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

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    super.key,
    required this.today,
    required this.daily,
    required this.total,
    required this.days,
    required this.money,
  });

  final num today;
  final num daily;
  final num total;
  final int days;
  final String Function(num v, {int dp}) money;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    Widget cell(String label, String value, Color color, String foot) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ptstyle(
                  size: 11,
                  weight: 500,
                  color: ch.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
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
              Text(
                foot,
                style: ptstyle(
                  size: 10.5,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ch.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell("Down payment", "GHS ${money(today)}", _green, "paid today"),
              Container(
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: ch.onSurface.withOpacity(0.08),
              ),
              cell("Then daily", "GHS ${money(daily)}", _blue, "for $days days"),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ch.onSurface.withOpacity(0.06)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "Total over the plan",
                style: ptstyle(
                  size: 12,
                  weight: 500,
                  color: ch.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                "GHS ${money(total)}",
                style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Says plainly what the down payment is: the first part of the phone's
/// price (not a fee), taken off the total; the rest is the daily payments.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({
    required this.today,
    required this.daily,
    required this.total,
    required this.days,
    required this.money,
  });

  final num today;
  final num daily;
  final num total;
  final int days;
  final String Function(num v, {int dp}) money;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final rest = (total - today) < 0 ? 0 : total - today;
    final split = total > 0 ? (today / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: _blue, size: 18),
              const SizedBox(width: 8),
              Text(
                "How your payment works",
                style: ptstyle(size: 13.5, weight: 800, color: ch.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // One bar for the whole price: today's part, then the daily part.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (split * 1000).round().clamp(1, 999),
                    child: Container(color: _green),
                  ),
                  Expanded(
                    flex: ((1 - split) * 1000).round().clamp(1, 999),
                    child: Container(color: _blue.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _legend(ch, _green, "Today: GHS ${money(today)}"),
              const Spacer(),
              _legend(ch, _blue.withOpacity(0.45), "Daily: GHS ${money(rest)}"),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: ptstyle(size: 12.5, weight: 400, color: ch.onSurface, height: 1.5),
              children: [
                const TextSpan(text: "Your "),
                TextSpan(
                  text: "GHS ${money(today)} down payment",
                  style: ptstyle(size: 12.5, weight: 800, color: ch.onSurface),
                ),
                const TextSpan(
                  text: " is the first part of the phone's price, not an extra fee. You pay it today and it comes off the total. The rest, ",
                ),
                TextSpan(
                  text: "GHS ${money(rest)}",
                  style: ptstyle(size: 12.5, weight: 800, color: ch.onSurface),
                ),
                TextSpan(text: ", is paid as GHS ${money(daily)} a day for $days days."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(ColorScheme ch, Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(t, style: ptstyle(size: 11, weight: 600, color: ch.onSurfaceVariant)),
    ],
  );
}

/// Buy now: "I understand" before Checkout turns on.
class _UnderstandTick extends StatelessWidget {
  const _UnderstandTick({
    required this.value,
    required this.today,
    required this.onChanged,
  });

  final bool value;
  final String today;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? _green.withOpacity(0.07) : ch.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? _green.withOpacity(0.5) : ch.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? _green : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: value ? _green : ch.onSurface.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "I understand that the GHS $today I pay today is my down payment, part of the phone's price, and that I must keep up my daily payments or the phone can be locked.",
                style: ptstyle(size: 12, weight: 500, color: ch.onSurface, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
