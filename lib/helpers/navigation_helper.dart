// lib/helpers/navigation_helper.dart

import 'package:flutter/cupertino.dart';

/// Pushes slide in from the right like iOS (the page underneath drifts
/// left, and a swipe from the left edge goes back). Clearing the stack
/// (e.g. splash -> home) uses a soft fade-and-zoom instead.
class NavigationHelper {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push(context, CupertinoPageRoute<T>(builder: (_) => page));
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement(
      context,
      CupertinoPageRoute<T>(builder: (_) => page),
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget page) {
    return Navigator.pushAndRemoveUntil(
      context,
      _fadeZoomRoute<T>(page),
      (route) => false,
    );
  }

  static PageRouteBuilder<T> _fadeZoomRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }
}
