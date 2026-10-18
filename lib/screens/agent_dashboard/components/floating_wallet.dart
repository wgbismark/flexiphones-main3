import 'dart:math' as math;
import 'dart:ui';

import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_wallet.dart'
    show cedi;
import 'package:flexiphones/screens/agent_dashboard/withdraw_sheet.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A small frosted pill floating over the agent screens with the amount
/// that can be withdrawn now. It bobs gently; drag it anywhere and it
/// snaps to the nearest side. Tap opens the Wallet, long-press goes
/// straight to Withdraw. An orange dot pulses while a withdrawal is on its
/// way.
class FloatingWallet extends StatefulWidget {
  const FloatingWallet({super.key, required this.visible, required this.onOpen});

  final bool visible;
  final VoidCallback onOpen;

  @override
  State<FloatingWallet> createState() => _FloatingWalletState();
}

class _FloatingWalletState extends State<FloatingWallet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  /// Position from the bottom-right (or bottom-left when [_left]).
  double _bottom = 18;
  bool _left = false;
  Offset? _drag; // live position while dragging (top-left)
  final _key = GlobalKey();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final w = p.partnerWallet;
    final pending = p.hasPendingWithdrawal;
    final show = widget.visible && w != null;

    return LayoutBuilder(
      builder: (context, box) {
        final pill = _pill(context, w?.withdrawable ?? 0, pending);
        final child = AnimatedScale(
          scale: show ? 1 : 0,
          duration: const Duration(milliseconds: 380),
          curve: show ? Curves.easeOutBack : Curves.easeIn,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onOpen();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                showWithdrawSheet(context);
              },
              onPanStart: (d) {
                final rb = _key.currentContext?.findRenderObject() as RenderBox?;
                final size = rb?.size ?? const Size(150, 52);
                setState(() {
                  _drag = Offset(
                    _left ? 16 : box.maxWidth - size.width - 16,
                    box.maxHeight - _bottom - size.height,
                  );
                });
              },
              onPanUpdate: (d) => setState(() => _drag = _drag! + d.delta),
              onPanEnd: (_) {
                final rb = _key.currentContext?.findRenderObject() as RenderBox?;
                final size = rb?.size ?? const Size(150, 52);
                final pos = _drag!;
                HapticFeedback.lightImpact();
                setState(() {
                  _left = pos.dx + size.width / 2 < box.maxWidth / 2;
                  _bottom = (box.maxHeight - pos.dy - size.height).clamp(
                    12.0,
                    math.max(12.0, box.maxHeight - size.height - 80),
                  );
                  _drag = null;
                });
              },
              child: AnimatedBuilder(
                animation: _bob,
                builder:
                    (_, c) => Transform.translate(
                      offset: Offset(
                        0,
                        _drag != null ? 0 : -3 * math.sin(_bob.value * 2 * math.pi),
                      ),
                      child: c,
                    ),
                child: pill,
              ),
            ),
          ),
        );

        if (_drag != null) {
          return Stack(
            children: [
              Positioned(left: _drag!.dx, top: _drag!.dy, child: child),
            ],
          );
        }
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              bottom: _bottom,
              right: _left ? null : 16,
              left: _left ? 16 : null,
              child: child,
            ),
          ],
        );
      },
    );
  }

  Widget _pill(BuildContext context, double amount, bool pending) {
    return Container(
      key: _key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A1C8C).withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B0F3B).withOpacity(0.82),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E5CFF), Color(0xFF5B3BE0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    if (pending)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: _PulseDot(controller: _bob),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending ? "ON ITS WAY" : "WITHDRAWABLE",
                      style: ptstyle(
                        size: 8.5,
                        weight: 700,
                        color: Colors.white60,
                      ).copyWith(letterSpacing: 1),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: amount),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder:
                          (_, v, _) => Text(
                            cedi(v),
                            style: ptstyle(
                              size: 15,
                              weight: 800,
                              color: Colors.white,
                            ).copyWith(letterSpacing: -0.3),
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
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = (controller.value * 2) % 1.0;
        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 * (1 + t),
                height: 12 * (1 + t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9F0A).withOpacity(0.5 * (1 - t)),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9F0A),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
