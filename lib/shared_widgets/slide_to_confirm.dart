import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Slide to pay": drag the knob to the end to confirm. Springs back if
/// let go early; shows a spinner while [loading]. Taps do nothing, so a
/// payment can't start by accident.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.loading = false,
    this.enabled = true,
    this.color = const Color(0xFF0071E3),
    this.height = 60,
  });

  final String label;
  final Future<void> Function() onConfirmed;
  final bool loading;
  final bool enabled;
  final Color color;
  final double height;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  double _drag = 0; // 0..1
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..addListener(() => setState(() => _drag = _from * (1 - _back.value)));
  double _from = 0;
  bool _done = false;

  @override
  void didUpdateWidget(covariant SlideToConfirm old) {
    super.didUpdateWidget(old);
    // Finished loading (success or error): reset the knob.
    if (old.loading && !widget.loading) _reset();
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _reset() {
    _done = false;
    _from = _drag;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final knob = h - 8;
    final active = widget.enabled && !widget.loading;
    return LayoutBuilder(
      builder: (context, box) {
        final track = box.maxWidth - knob - 8;
        return Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Label fades as the knob passes over it.
                Center(
                  child: Opacity(
                    opacity: (1 - _drag * 1.6).clamp(0, 1),
                    child: Padding(
                      padding: EdgeInsets.only(left: knob * 0.8),
                      child: _Shimmer(
                        active: active && _drag == 0,
                        child: Text(
                          widget.loading ? "Processing…" : widget.label,
                          style: ptstyle(
                            size: 15,
                            weight: 600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4 + track * _drag,
                  child: GestureDetector(
                    onHorizontalDragUpdate:
                        !active || _done
                            ? null
                            : (d) {
                              setState(() {
                                _drag = (_drag + d.delta.dx / track).clamp(
                                  0.0,
                                  1.0,
                                );
                              });
                            },
                    onHorizontalDragEnd:
                        !active || _done
                            ? null
                            : (_) async {
                              if (_drag > 0.88) {
                                setState(() {
                                  _drag = 1;
                                  _done = true;
                                });
                                HapticFeedback.mediumImpact();
                                await widget.onConfirmed();
                                // If the parent never showed loading,
                                // spring back now.
                                if (mounted && !widget.loading) _reset();
                              } else {
                                _reset();
                              }
                            },
                    child: Container(
                      width: knob,
                      height: knob,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            widget.loading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: widget.color,
                                  ),
                                )
                                : Icon(
                                  _done
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_ios_rounded,
                                  color: widget.color,
                                  size: 20,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A light sweep over the label, hinting "slide me".
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child, required this.active});
  final Widget child;
  final bool active;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              final x = _c.value * 3 - 1; // -1..2
              return LinearGradient(
                begin: Alignment(x - 0.6, 0),
                end: Alignment(x + 0.6, 0),
                colors: [
                  Colors.white.withOpacity(0.55),
                  Colors.white,
                  Colors.white.withOpacity(0.55),
                ],
              ).createShader(rect);
            },
            child: child,
          ),
      child: widget.child,
    );
  }
}
