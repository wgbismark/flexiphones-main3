import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

/// Product row used by Browse, Search and the store page, in the spirit of
/// Apple's Store app: a quiet card, the phone on a soft grey stage, a bold
/// name over one light line of detail, colour dots instead of text pills,
/// the price, and a small blue "View" pill. Same constructor as before, so
/// every caller picks the new look up unchanged.
class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String productName, deviceSpecification;
  final String status;
  final String colors;
  final double price;

  final double initialDeposit;
  final VoidCallback onPressed;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.deviceSpecification,
    required this.price,
    required this.initialDeposit,
    required this.onPressed,
    required this.colors,
    required this.status,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // Apple's link/system blue and the light "stage" grey behind products.
  static const _blue = Color(0xFF0071E3);
  static const _stageLight = Color(0xFFF5F5F7);

  bool _pressed = false;

  List<String> get _colorNames =>
      widget.colors
          .replaceAll("{", "")
          .replaceAll("}", "")
          .replaceAll("[", "")
          .replaceAll("]", "")
          .replaceAll('"', "")
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  /// "SAMSUNG GALAXY A15" / "samsung galaxy a15" -> "Samsung Galaxy A15".
  String get _title =>
      widget.productName
          .trim()
          .split(RegExp(r"\s+"))
          .map(
            (w) =>
                w.isEmpty
                    ? w
                    : (w.length <= 3 && w.toUpperCase() == w)
                    ? w // keep short codes like "S25", "5G", "PRO"
                    : w[0].toUpperCase() + w.substring(1).toLowerCase(),
          )
          .join(" ");

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final colors = _colorNames;
    final inStock = widget.status.toLowerCase().contains("available");
    final spec = widget.deviceSpecification.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? ch.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border:
                isDark
                    ? Border.all(color: Colors.white.withOpacity(0.06))
                    : null,
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: Colors.transparent,
              highlightColor: ch.onSurface.withOpacity(0.03),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // The stage
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.05)
                                : _stageLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(10),
                      child:
                          widget.imageUrl.isEmpty
                              ? _placeholder(isDark)
                              : Image.network(
                                widget.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _placeholder(isDark),
                              ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (inStock)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34C759),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "In stock",
                                    style: ptstyle(
                                      size: 10,
                                      weight: 600,
                                      color: const Color(0xFF248A3D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            _title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 15,
                              weight: 700,
                              color: ch.onSurface,
                            ).copyWith(letterSpacing: -0.3, height: 1.15),
                          ),
                          if (spec.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              spec.toSentenceCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(
                                size: 12,
                                weight: 400,
                                color: ch.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                          ],
                          if (colors.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final c in colors.take(5))
                                  Container(
                                    margin: const EdgeInsets.only(right: 5),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _swatch(c),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ch.onSurface.withOpacity(0.15),
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                if (colors.length > 5)
                                  Text(
                                    "+${colors.length - 5}",
                                    style: ptstyle(
                                      size: 10,
                                      weight: 600,
                                      color: ch.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    widget.price > 0
                                        ? Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "From ",
                                                style: ptstyle(
                                                  size: 11,
                                                  weight: 400,
                                                  color: ch.onSurfaceVariant,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    "GHS ${widget.price.toCommaSeparated(0, decimalPlaces: 0)}",
                                                style: ptstyle(
                                                  size: 13,
                                                  weight: 700,
                                                  color: ch.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                        : Text(
                                          "Pay small small",
                                          style: ptstyle(
                                            size: 11,
                                            weight: 500,
                                            color: ch.onSurfaceVariant,
                                          ),
                                        ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  "View",
                                  style: ptstyle(
                                    size: 12,
                                    weight: 600,
                                    color: Colors.white,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) => Opacity(
    opacity: isDark ? 0.2 : 0.45,
    child: Image.asset(AssetsHelper.dummyImage, fit: BoxFit.contain),
  );

  /// Colour name -> swatch, Apple-ish tones; neutral grey when unknown.
  static Color _swatch(String name) {
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
}
