import 'package:flutter/material.dart';

class SmartButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  final Widget child;
  final double disabledOpacity;
  final ButtonStyle? style;

  const SmartButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    required this.child,
    this.disabledOpacity = 0.2,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final bool canTap = enabled && !loading;

    return AbsorbPointer(
      absorbing: !canTap,
      child: Opacity(
        opacity: canTap ? 1.0 : disabledOpacity,
        child: FilledButton(
          onPressed: onPressed,
          style:
              style ??
              ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          child:
              loading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                  : child,
        ),
      ),
    );
  }
}
