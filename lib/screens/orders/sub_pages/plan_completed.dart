import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

/// Shown on `plan_completed` or when an order's balance reaches 0: the
/// phone is released and can never be locked again.
class PlanCompletedScreen extends StatefulWidget {
  const PlanCompletedScreen({super.key, this.productName});

  final String? productName;

  @override
  State<PlanCompletedScreen> createState() => _PlanCompletedScreenState();
}

class _PlanCompletedScreenState extends State<PlanCompletedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      backgroundColor: ch.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30A14E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 68,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              FadeTransition(
                opacity: fade,
                child: Column(
                  children: [
                    Text(
                      "Congratulations!",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 30,
                        weight: 700,
                        color: ch.onSurface,
                      ).copyWith(letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.productName == null
                          ? "Your phone is fully paid."
                          : "Your ${widget.productName} is fully paid.",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 17,
                        weight: 600,
                        color: ch.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "It's yours for good and will never be locked again. "
                      "Thank you for paying with FlexiPhones. We've sent you a thank-you email too.",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 13,
                        weight: 400,
                        color: ch.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Done", style: ptstyle(size: 15, weight: 600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
