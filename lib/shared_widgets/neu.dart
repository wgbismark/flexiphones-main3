import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

/// Soft-UI (neumorphic) palette and shadows. Surfaces are the same colour
/// as the page; depth comes only from a light shadow top-left and a dark
/// one bottom-right (raised), or the same pair painted inside (pressed in).
class Neu {
  static const _bgLight = Color(0xFFECF0F5);
  static const _bgDark = Color(0xFF1F232A);
  static const blue = Color(0xFF0071E3);

  static bool isDark(BuildContext context) =>
      AdaptiveTheme.of(context).mode.isDark;

  static Color bg(BuildContext context) => isDark(context) ? _bgDark : _bgLight;

  static Color _light(BuildContext c) =>
      isDark(c) ? const Color(0xFF2B3039) : Colors.white;

  static Color _darkShade(BuildContext c) =>
      isDark(c) ? Colors.black.withOpacity(0.55) : const Color(0xFFA6B4C8);

  /// Raised: [depth] 0 (flat) .. 1 (full).
  static List<BoxShadow> raised(
    BuildContext c, {
    double distance = 7,
    double blur = 16,
    double depth = 1,
  }) {
    final d = distance * depth;
    return [
      BoxShadow(
        color: _light(c).withOpacity(isDark(c) ? 0.9 : 0.95),
        offset: Offset(-d, -d),
        blurRadius: blur * depth,
      ),
      BoxShadow(
        color: _darkShade(c).withOpacity(isDark(c) ? 0.55 : 0.55),
        offset: Offset(d, d),
        blurRadius: blur * depth,
      ),
    ];
  }

  static Color shadowDark(BuildContext c) => _darkShade(c);
  static Color shadowLight(BuildContext c) => _light(c);
}

/// A raised soft surface. With [onTap] it sinks in while pressed.
class NeuBox extends StatefulWidget {
  const NeuBox({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.distance = 7,
    this.blur = 16,
    this.color,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double distance;
  final double blur;
  final Color? color;
  final BoxShape shape;

  @override
  State<NeuBox> createState() => _NeuBoxState();
}

class _NeuBoxState extends State<NeuBox> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? Neu.bg(context),
        shape: widget.shape,
        borderRadius:
            widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
        boxShadow: Neu.raised(
          context,
          distance: widget.distance,
          blur: widget.blur,
          depth: _down ? 0.25 : 1,
        ),
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 160),
        child: box,
      ),
    );
  }
}

/// A pressed-in (concave) soft surface: the shadows are painted inside.
class NeuInset extends StatelessWidget {
  const NeuInset({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.depth = 1,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsetPainter(
        radius: radius,
        base: color ?? Neu.bg(context),
        dark: Neu.shadowDark(context),
        light: Neu.shadowLight(context),
        depth: depth,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _InsetPainter extends CustomPainter {
  _InsetPainter({
    required this.radius,
    required this.base,
    required this.dark,
    required this.light,
    required this.depth,
  });

  final double radius;
  final Color base;
  final Color dark;
  final Color light;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = base);
    canvas.save();
    canvas.clipRRect(rrect);
    void shade(Color c, Offset o, double blur) {
      final p =
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(rect.inflate(blur * 3))
            ..addRRect(rrect);
      canvas.drawPath(
        p.shift(o),
        Paint()
          ..color = c
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    final d = 5 * depth;
    shade(dark.withOpacity(0.6), Offset(d, d), 7);
    shade(light, Offset(-d, -d), 7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InsetPainter old) =>
      old.base != base || old.depth != depth || old.radius != radius;
}
