import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter_dominant_color_container/flutter_dominant_color_container.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/browse/sub_pages.dart/product_details.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// Redesign notes:
/// - `colors` from the API is a JSON array string, e.g.
///   `"[\"Black\",\"Silver\",\"Gold\"]"` — parsed with jsonDecode now, with
///   a fallback to the old comma/brace parsing in case an older endpoint
///   still sends `{Black,Silver,Gold}`.
/// - Added a price pill (cheapest monthly plan) and a rating badge, since
///   the real payload has `product_storages` and `rating` that the old
///   card never showed — that's most of what makes a deal card feel like
///   an actual deal instead of a generic listing.
/// - Color chips are now real color swatches (a small dot in the actual
///   color) instead of plain text pills.
/// - ASSUMPTION: `item.productStorages` is assumed to expose camelCase
///   fields (`cashPrice`, `threeMonthPrice`, `fourMonthPrice`,
///   `fiveMonthPrice`, `sixMonthPrice`) as Strings, matching the default
///   json_serializable conversion of `cash_price` etc. If your model
///   names these differently, rename the references inside
///   `_cheapestMonthly()` and `_cashPrice()` below — they're the only
///   two places that touch pricing.
class PromotionCard extends StatefulWidget {
  final String headerTitle;
  final String promotionTitle;
  final String buttonText;
  final String dealSectionTitle;
  final String seeAllText;
  final String imageUrl;

  const PromotionCard({
    super.key,
    required this.headerTitle,
    required this.promotionTitle,
    required this.buttonText,
    required this.dealSectionTitle,
    required this.seeAllText,
    required this.imageUrl,
  });

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  List<String> _parseColors(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // fall through to legacy parsing below
    }
    return raw
        .replaceAll("{", "")
        .replaceAll("}", "")
        .replaceAll('"', "")
        .replaceAll("[", "")
        .replaceAll("]", "")
        .split(",")
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Color _swatchFor(String name) {
    const map = {
      "BLACK": Colors.black,
      "WHITE": Color(0xFFF5F5F5),
      "SILVER": Color(0xFFC7C9CC),
      "GOLD": Color(0xFFD4AF37),
      "ROSE GOLD": Color(0xFFB76E79),
      "MIDNIGHT": Color(0xFF1D1D2C),
      "STARLIGHT": Color(0xFFF0E6D2),
      "GRAPHITE": Color(0xFF41424C),
      "BLUE": Color(0xFF3B82F6),
      "RED": Color(0xFFEF4444),
      "GREEN": Color(0xFF22C55E),
      "PURPLE": Color(0xFFA855F7),
      "PINK": Color(0xFFEC4899),
      "GRAY": Color(0xFF9CA3AF),
      "GREY": Color(0xFF9CA3AF),
      "YELLOW": Color(0xFFFACC15),
      "ORANGE": Color(0xFFF97316),
      "TEAL": Color(0xFF14B8A6),
      "NAVY": Color(0xFF001F54),
    };
    return map[name] ?? const Color(0xFFB0B3B8);
  }

  String _money(num value) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(",");
    }
    return "GH₵$buf";
  }

  /// Cheapest available monthly plan across this item's storages, or null.
  double? _cheapestMonthly(dynamic item) {
    try {
      final storages = item.productStorages as List;
      if (storages.isEmpty) return null;
      double? min;
      for (final s in storages) {
        for (final raw in [
          s.threeMonthPrice,
          s.fourMonthPrice,
          s.fiveMonthPrice,
          s.sixMonthPrice,
        ]) {
          final v = double.tryParse(raw?.toString() ?? "");
          if (v != null && (min == null || v < min)) min = v;
        }
      }
      return min;
    } catch (_) {
      return null;
    }
  }

  double? _cashPrice(dynamic item) {
    try {
      final storages = item.productStorages as List;
      if (storages.isEmpty) return null;
      return double.tryParse(storages.first.cashPrice?.toString() ?? "");
    } catch (_) {
      return null;
    }
  }

  double? _rating(dynamic item) {
    try {
      return double.tryParse(item.rating?.toString() ?? "");
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final ch = Theme.of(context).colorScheme;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final deals = sharedProvider.hotDeals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ch.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: ch.onPrimaryContainer),
              const SizedBox(width: 5),
              Text(
                "Hot Deals — Pay Less For Your Favorite",
                style:
                    ptstyle(size: 11, weight: 700, color: ch.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            pageSnapping: true,
            onPageChanged: (index, reason) =>
                setState(() => _currentIndex = index),
            aspectRatio: 16 / 8.6,
            viewportFraction: 0.92,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: deals.isEmpty
              ? List.generate(3, (index) => const PromotionCardShimmer())
              : deals.map((item) {
                  final colorNames = _parseColors(item.colors);
                  final monthly = _cheapestMonthly(item);
                  final cash = _cashPrice(item);
                  final rating = _rating(item);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: ch.surfaceContainerLow,
                      elevation: 2,
                      shadowColor: ch.shadow.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          sharedProvider.getProductDetails(item.id, context);
                          NavigationHelper.push(
                            context,
                            ProductDetailsPage(productId: item.id),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ptstyle(
                                        size: 16,
                                        weight: 700,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.deviceSpecification
                                          .toSentenceCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: ptstyle(
                                        size: 12,
                                        weight: 400,
                                        color: ch.onSurfaceVariant,
                                      ),
                                    ),
                                    if (colorNames.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ...colorNames.take(4).map(
                                            (name) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 5),
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: _swatchFor(name),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: ch.outlineVariant,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (colorNames.length > 4)
                                            Text(
                                              "+${colorNames.length - 4}",
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
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (monthly != null)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: ch.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "From ${_money(monthly)}/mo",
                                              style: ptstyle(
                                                size: 11,
                                                weight: 700,
                                                color: ch.onPrimary,
                                              ),
                                            ),
                                          ),
                                        if (cash != null)
                                          Text(
                                            _money(cash),
                                            style: ptstyle(
                                              size: 11,
                                              weight: 600,
                                              color: ch.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ch.primaryContainer
                                          .withOpacity(isDark ? 0.35 : 0.6),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Image.network(
                                      item.image,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (context, error, stack) =>
                                          Opacity(
                                        opacity: isDark ? 0.3 : 0.7,
                                        child: Image.asset(
                                          AssetsHelper.dummyImage,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (rating != null)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: ch.surface,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  ch.shadow.withOpacity(0.15),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 12,
                                                color: Color(0xFFFFB020)),
                                            const SizedBox(width: 2),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: ptstyle(
                                                size: 10,
                                                weight: 700,
                                                color: ch.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            children: List.generate(
              deals.isEmpty ? 3 : deals.length,
              (index) {
                final isActive = _currentIndex == index;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? ch.primary : ch.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class PromotionCardShimmer extends StatelessWidget {
  const PromotionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _shimmerBlock(ch, height: 18, width: 180),
                    const SizedBox(height: 8),
                    _shimmerBlock(ch, height: 12, width: 140),
                    const SizedBox(height: 8),
                    _shimmerBlock(ch, height: 12, width: 100),
                    const SizedBox(height: 12),
                    _shimmerBlock(ch, height: 20, width: 100, radius: 20),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _shimmerBlock(ch, height: 100, width: 100, radius: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBlock(
    ColorScheme ch, {
    required double height,
    required double width,
    double radius = 5,
  }) {
    return Shimmer.fromColors(
      baseColor: ch.surfaceContainerHighest,
      highlightColor: ch.surfaceContainerHigh,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: ch.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}