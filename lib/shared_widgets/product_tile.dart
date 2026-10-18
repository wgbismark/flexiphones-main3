import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/models/product_m.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flexiphones/shared_widgets/shop_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Grid shape every product grid uses, so cards look the same everywhere.
const productGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 18,
  crossAxisSpacing: 16,
  childAspectRatio: 0.62,
);

/// Grid card for a phone in soft UI: a raised card with a pressed-in well
/// where the phone floats over its own shadow, a badge (New / Trending),
/// a raised heart, then brand, model, colour dots, "From GHS …" and a
/// round blue arrow. The whole card sinks in when pressed. Used by Home,
/// the store page and Favourites.
class ProductTile extends StatefulWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final bool isFavorite;

  /// Null hides the heart (guests).
  final VoidCallback? onFavorite;

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final dark = Neu.isDark(context);
    final p = widget.product;
    final colors = colorNamesOf(p.colors);
    final price = p.fromPrice;
    final isNew =
        p.createdAt != null &&
        DateTime.now().difference(p.createdAt!).inDays <= 30;
    final trending = !isNew && p.viewsCount >= 100;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.965 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Neu.bg(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: Neu.raised(context, depth: _down ? 0.2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The well
              Expanded(
                // Flat soft stage (no inner shadow).
                child: Container(
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // The photo fills the whole box.
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: AnimatedScale(
                            scale: _down ? 1.03 : 1,
                            duration: const Duration(milliseconds: 160),
                            child:
                                p.image.isEmpty
                                    ? _placeholder(dark)
                                    : Image.network(
                                      p.image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (_, _, _) => _placeholder(dark),
                                      frameBuilder:
                                          (_, child, frame, sync) =>
                                              AnimatedOpacity(
                                                opacity:
                                                    sync || frame != null
                                                        ? 1
                                                        : 0,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                child: child,
                                              ),
                                    ),
                          ),
                        ),
                      ),
                      if (isNew || trending)
                        Positioned(
                          left: 9,
                          top: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isNew
                                        ? const [
                                          Color(0xFFFF9F0A),
                                          Color(0xFFFF6B00),
                                        ]
                                        : const [
                                          Color(0xFFFF375F),
                                          Color(0xFFBF5AF2),
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isNew ? "NEW" : "TRENDING",
                              style: ptstyle(
                                size: 8.5,
                                weight: 700,
                                color: Colors.white,
                              ).copyWith(letterSpacing: 0.6),
                            ),
                          ),
                        ),
                      // Can be bought outright with cash at the shop.
                      if (p.supportsCash)
                        Positioned(
                          left: 9,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1D1F),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.payments_rounded,
                                  size: 10,
                                  color: Color(0xFF34C759),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  p.cashOnly ? "CASH" : "CASH OR DAILY",
                                  style: ptstyle(
                                    size: 8,
                                    weight: 700,
                                    color: Colors.white,
                                  ).copyWith(letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Paid placement, not a discount: a quiet label.
                      if (p.isPromoted)
                        Positioned(
                          left: 9,
                          top: isNew || trending ? 32 : 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              "Promoted",
                              style: ptstyle(
                                size: 8.5,
                                weight: 600,
                                color: const Color(0xFF6E6E73),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onFavorite != null)
                        Positioned(
                          right: 7,
                          top: 7,
                          child: FavoriteButton(
                            size: 30,
                            active: widget.isFavorite,
                            onTap: widget.onFavorite!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 9, 4, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.brand.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 9,
                              weight: 700,
                              color: Neu.blue,
                            ).copyWith(letterSpacing: 1.1),
                          ),
                        ),
                        for (final c in colors.take(4))
                          Container(
                            margin: const EdgeInsets.only(left: 3),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: swatchFor(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ch.onSurface.withOpacity(0.15),
                                width: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titleCase(p.model.isEmpty ? p.fullName : p.model),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ptstyle(
                        size: 13,
                        weight: 600,
                        color: ch.onSurface,
                      ).copyWith(letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 5),
                    _VendorLine(product: p),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price > 0 ? "From" : "Pay daily",
                                style: ptstyle(
                                  size: 9.5,
                                  weight: 500,
                                  color: ch.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                price > 0
                                    ? "GHS ${price.toCommaSeparated(0, decimalPlaces: 0)}"
                                    : "Small small",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ptstyle(
                                  size: 13.5,
                                  weight: 700,
                                  color: ch.onSurface,
                                ).copyWith(letterSpacing: -0.4),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E8BFF), Color(0xFF0058C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Neu.blue.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool dark) => Opacity(
    opacity: dark ? 0.2 : 0.45,
    child: Image.asset(AssetsHelper.dummyImage, fit: BoxFit.contain),
  );
}

/// "● Kofi Mobile ✓" — who sells it, so people know the shop at a glance.
/// Uses the product's own vendor, else the loaded vendor list.
class _VendorLine extends StatelessWidget {
  const _VendorLine({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    var vendor = product.vendor;
    if (vendor == null && product.vendorId != null) {
      final list = Provider.of<SharedProvider>(context, listen: false).vendors;
      for (final v in list) {
        if (v.id == product.vendorId) {
          vendor = v;
          break;
        }
      }
    }
    final name = vendor?.name.trim() ?? "";
    if (name.isEmpty) return const SizedBox(height: 16);
    final verified = vendor?.isVerified ?? false;
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          // The shop's own picture when it has one, else its letter.
          ShopAvatar(name: name, imageUrl: vendor?.image, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ptstyle(size: 10.5, weight: 600, color: ch.onSurfaceVariant),
            ),
          ),
          if (verified) ...[
            const SizedBox(width: 3),
            const Icon(Icons.verified_rounded, size: 12, color: Neu.blue),
          ],
        ],
      ),
    );
  }
}

/// A small raised soft heart that pops when toggled.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 32,
  });

  final bool active;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Clean frosted circle over the photo: no shadow.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.88),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder:
              (child, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                child: child,
              ),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(active),
            size: size * 0.52,
            color: active ? const Color(0xFFFF375F) : const Color(0xFF1D1D1F),
          ),
        ),
      ),
    );
  }
}

/// "{BLACK, SKY BLUE}" -> ["BLACK", "SKY BLUE"].
List<String> colorNamesOf(String raw) =>
    raw
        .replaceAll(RegExp(r'[{}\[\]"]'), "")
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

/// "GALAXY A15" -> "Galaxy A15"; short codes like "S25", "5G" stay as-is.
String titleCase(String s) => s
    .trim()
    .split(RegExp(r"\s+"))
    .map(
      (w) =>
          w.isEmpty
              ? w
              : (w.length <= 3 && w.toUpperCase() == w && RegExp(r'\d').hasMatch(w))
              ? w
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
    )
    .join(" ");

/// Colour name -> swatch, Apple-ish tones; neutral grey when unknown.
Color swatchFor(String name) {
  final n = name.toLowerCase();
  const map = <String, Color>{
    'black': Color(0xFF1D1D1F),
    'white': Color(0xFFF5F5F7),
    'silver': Color(0xFFE3E4E6),
    'gold': Color(0xFFEBD9B4),
    'blue': Color(0xFF3E6AE1),
    'red': Color(0xFFD5432A),
    'green': Color(0xFF4C8C5B),
    'purple': Color(0xFF8C6FB0),
    'pink': Color(0xFFE7B7C4),
    'gray': Color(0xFF8E8E93),
    'grey': Color(0xFF8E8E93),
    'yellow': Color(0xFFE3C468),
    'graphite': Color(0xFF54524F),
    'midnight': Color(0xFF1B1F26),
    'starlight': Color(0xFFF0E6D4),
    'orange': Color(0xFFF08A3C),
    'titanium': Color(0xFFB9B4AD),
  };
  for (final key in map.keys) {
    if (n.contains(key)) return map[key]!;
  }
  return const Color(0xFFB0B0B5);
}
