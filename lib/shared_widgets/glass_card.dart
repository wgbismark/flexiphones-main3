import 'dart:ui';
import 'package:flutter/material.dart';

/// A frosted glass panel. Uses the current ColorScheme so it adapts
/// automatically between light and dark themes — never a hardcoded
/// black or white.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.blur = 18,
    this.opacity = 0.55,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: ch.surface.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: ch.onSurface.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ch.primary.withOpacity(0.10),
                blurRadius: 30,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A soft blurred color orb used behind glass cards to give them
/// something to "catch" light from — that's what sells the glass look.
/// Purely decorative, ignores pointer events.
class GlowOrb extends StatelessWidget {
  const GlowOrb({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}