import 'dart:ui';

import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple banner that advertises becoming a vendor and opens a website when tapped.
class VendorBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback close;

  final BorderRadiusGeometry borderRadius;

  const VendorBanner({
    super.key,

    this.title = 'Become a Vendor',
    this.subtitle = 'Reach more customers — join our marketplace today.',

    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    required this.close,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    !await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ch.surface,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon / visual
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/vendor_ad.png',
                          width: double.infinity,
                          alignment: Alignment.topCenter,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Texts
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: ptstyle(
                                size: 12,
                                weight: 800,
                                color: ch.primary,
                              ),
                            ),

                            Text(
                              subtitle,
                              style: ptstyle(
                                size: 10,
                                weight: 400,
                                color: ch.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),

                            SizedBox(
                              height: 40,
                              child: Row(
                                children: [
                                  OutlinedButton(
                                    onPressed:
                                        () => _openUrl(
                                          context,
                                          "https://flexiphones.app/",
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 1,
                                      ),
                                    ),
                                    child: Text(
                                      "Explore",
                                      style: ptstyle(
                                        size: 10,
                                        weight: 400,
                                        color: ch.onSurface,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed:
                                          () => _openUrl(
                                            context,
                                            "https://api.flexiphones.app/vendor/signup",
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.monetization_on_rounded,

                                        size: 20,
                                      ),
                                      label: Text(
                                        "Start Selling",
                                        style: ptstyle(size: 11, weight: 600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: IconButton.filled(
                    onPressed: close,

                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
