import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/extensions/ui_values.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// "How FlexiPhones works": a short, swipeable walkthrough shown once on
/// first launch (and from the ⓘ button). One idea per page — a picture on
/// a soft stage, a bold title, one line of text — with Back / Next.
class StepsPage extends StatefulWidget {
  const StepsPage({super.key, this.nit = true});
  final bool nit;
  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  final PageController _controller = PageController();

  static const List<Map<String, String>> steps = [
    {
      "title": "Welcome to FlexiPhones",
      "img": "assets/79877898.png",
      "desc":
          "Get the phone you want today and pay for it a little each day.",
    },
    {
      "title": "Find your phone",
      "img": "assets/1758716384.png",
      "desc":
          "Browse trusted shops near you and pick the phone that suits you best.",
    },
    {
      "title": "Add to bag or buy now",
      "img": "assets/1758717842.png",
      "desc": "Save it in your bag for later, or buy it straight away.",
    },
    {
      "title": "Confirm your order",
      "img": "assets/1758717669.png",
      "desc": "Check the plan, then place your order securely.",
    },
    {
      "title": "Pay the down payment",
      "img": "assets/1758718886.png",
      "desc":
          "Your phone is set up as soon as the down payment is in. We'll keep you posted.",
    },
    {
      "title": "Pick up your phone",
      "img": "assets/1758722254.png",
      "desc": "Collect it from the shop, or have it delivered to you.",
    },
    {
      "title": "Pay small, every day",
      "img": "assets/1758719467.png",
      "desc":
          "Keep your daily payments going. Clear the balance and the phone is yours for good.",
    },
  ];

  int page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int to) => _controller.animateToPage(
    to,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final last = page == steps.length - 1;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(maxWidth: 420, maxHeight: 82.h),
          decoration: BoxDecoration(
            color: isDark ? ch.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar: step count + close
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 10, 0),
                child: Row(
                  children: [
                    Text(
                      "STEP ${page + 1} OF ${steps.length}",
                      style: ptstyle(
                        size: 11,
                        weight: 600,
                        color: ch.onSurfaceVariant,
                      ).copyWith(letterSpacing: 1),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => NavigationHelper.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: ch.onSurfaceVariant,
                      ),
                      child: Text(
                        "Skip",
                        style: ptstyle(size: 13, weight: 500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 46.h < 380 ? 46.h : 380,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: steps.length,
                  onPageChanged: (v) => setState(() => page = v),
                  itemBuilder: (context, i) {
                    final step = steps[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(22),
                              child: Image.asset(
                                step["img"]!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            step["title"]!,
                            style: ptstyle(
                              size: 22,
                              weight: 700,
                              color: ch.onSurface,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step["desc"]!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(
                              size: 13,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SmoothPageIndicator(
                controller: _controller,
                count: steps.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                  spacing: 5,
                  activeDotColor: ch.onSurface,
                  dotColor: ch.onSurface.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: page == 0 ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: page == 0 ? null : () => _go(page - 1),
                          child: Text(
                            "Back",
                            style: ptstyle(size: 14, weight: 500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0071E3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed:
                              last
                                  ? () => NavigationHelper.pop(context)
                                  : () => _go(page + 1),
                          child: Text(
                            last ? "Get started" : "Next",
                            style: ptstyle(size: 15, weight: 600),
                          ),
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
    );
  }
}
