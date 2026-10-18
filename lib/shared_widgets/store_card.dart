import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';

class StoreCard extends StatelessWidget {
  final String image;
  final String address;
  final String name;
  final String state;
  final String closing;
  final VoidCallback onPressed;

  const StoreCard({
    super.key,
    required this.image,

    required this.address,
    required this.state,
    required this.onPressed,
    required this.name,
    required this.closing,
    this.locations = 1,
  });

  /// Places the shop sells from (main shop + branches); chip when > 1.
  final int locations;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5),

        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                //
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Card(
                    color:
                        AdaptiveTheme.of(context).mode.isDark
                            ? ch.primaryFixed.withOpacity(0.5)
                            : ch.primaryFixed.withOpacity(0.2),
                    elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Opacity(
                              opacity:
                                  AdaptiveTheme.of(context).mode.isDark
                                      ? 0.8
                                      : 0.4,
                              child: Image.asset(
                                AssetsHelper.dummy2Image,
                                fit: BoxFit.cover,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: ptstyle(
                          size: 12,
                          weight: 600,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      if (locations > 1)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0071E3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            "$locations locations",
                            style: ptstyle(
                              size: 9.5,
                              weight: 600,
                              color: const Color(0xFF0071E3),
                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_city_rounded,
                                color: ch.onSurfaceVariant.withOpacity(0.5),
                                size: 15,
                              ),
                              SizedBox(width: 3),
                              Text(
                                address.toString(),
                                style: ptstyle(
                                  size: 10,
                                  weight: 400,
                                  color: ch.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 30,
                            child: FilledButton.tonal(
                              onPressed: onPressed,
                              style: ElevatedButton.styleFrom(
                                shadowColor: Colors.transparent,
                                backgroundColor: ch.primaryFixed.withOpacity(
                                  0.3,
                                ),
                                overlayColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: Text(
                                'View Store',
                                style: ptstyle(size: 10, weight: 400),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  state.toLowerCase().contains("active")
                                      ? Colors.green.withOpacity(0.1)
                                      : ch.surfaceContainerLow,

                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              state.toSentenceCase(),
                              style: ptstyle(
                                size: 10,
                                weight: 600,
                                color:
                                    state.toLowerCase() == "active"
                                        ? Colors.green
                                        : ch.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '•',
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Closes at $closing',
                            style: ptstyle(
                              size: 10,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SDivider(),
          ],
        ),
      ),
    );
  }
}
