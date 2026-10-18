import 'dart:async';
import 'dart:math' as math;

import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pull-to-refresh with a FlexiPhones feel: as the list is pulled down a
/// phone icon spins and a ring fills; past the threshold the phone gives a
/// light tick and the hint flips to "Release to refresh". On release a
/// floating "Refreshing…" pill shows until [onRefresh] finishes, then
/// "Updated" for a moment.
///
/// [builder] gets the scroll physics to use (bouncing, so the list can be
/// pulled past the top on Android too) and must return the scrollable.
class FlexiPullToRefresh extends StatefulWidget {
  const FlexiPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.builder,
    this.threshold = 90,
  });

  final Future<void> Function() onRefresh;
  final Widget Function(ScrollPhysics physics) builder;
  final double threshold;

  @override
  State<FlexiPullToRefresh> createState() => _FlexiPullToRefreshState();
}

enum _Phase { idle, refreshing, done }

class _FlexiPullToRefreshState extends State<FlexiPullToRefresh> {
  static const _physics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  double _pull = 0;
  bool _armed = false;
  _Phase _phase = _Phase.idle;
  Timer? _doneTimer;

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final pull = math.max(0.0, -n.metrics.pixels);

    if (n is ScrollUpdateNotification) {
      final dragging = n.dragDetails != null;
      if (_phase == _Phase.idle) {
        final armed = pull >= widget.threshold;
        if (dragging && armed && !_armed) HapticFeedback.mediumImpact();
        // Finger lifted while past the threshold: refresh.
        if (!dragging && _armed) {
          _start();
        } else {
          _armed = dragging ? armed : false;
        }
      }
    }
    if (pull != _pull) setState(() => _pull = pull);
    return false;
  }

  Future<void> _start() async {
    _armed = false;
    _doneTimer?.cancel();
    setState(() => _phase = _Phase.refreshing);
    try {
      await widget.onRefresh();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    _doneTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _phase = _Phase.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final progress = (_pull / widget.threshold).clamp(0.0, 1.0);
    final armed = _pull >= widget.threshold;

    return Stack(
      children: [
        // Revealed behind the list as it is pulled down.
        if (_phase == _Phase.idle && _pull > 4)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _pull,
            // Short pulls clip the spinner instead of overflowing.
            child: ClipRect(
              child: OverflowBox(
              maxHeight: double.infinity,
              child: Center(
              child: Opacity(
                opacity: progress,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            color: ch.primary,
                            backgroundColor: ch.primary.withOpacity(0.12),
                          ),
                          Transform.rotate(
                            angle: progress * 2 * math.pi,
                            child: Icon(
                              Icons.phone_iphone_rounded,
                              size: 18,
                              color: ch.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pull > 60) ...[
                      const SizedBox(height: 6),
                      Text(
                        armed ? "Release to refresh" : "Pull to refresh",
                        style: ptstyle(
                          size: 11,
                          weight: 600,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
              ),
            ),
          ),
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.builder(_physics),
        ),
        // Floating status pill while refreshing / just after.
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              offset: _phase == _Phase.idle ? const Offset(0, -2) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _phase == _Phase.idle ? 0 : 1,
                child: Center(
                  child: Material(
                    elevation: 3,
                    shadowColor: Colors.black26,
                    color: ch.surface,
                    shape: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_phase == _Phase.done)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.green,
                            )
                          else
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ch.primary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _phase == _Phase.done ? "Updated" : "Refreshing…",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
