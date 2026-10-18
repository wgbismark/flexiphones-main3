import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/utils/colors.dart';
import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required Color backgroundColor,
    IconData? icon,
  }) {
    final snackBar = SnackBar(
      margin: EdgeInsets.all(0),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(icon, color: Colors.white),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ptstyle(
                    size: 12,
                    weight: 400,
                    color: AppColors.appWhite,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  message.toSentenceCase(),
                  style: ptstyle(
                    size: 12,
                    weight: 600,
                    color: AppColors.appWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void info({
    required BuildContext context,
    required String title,
    required String message,
    required ColorScheme ch,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      backgroundColor: ch.primary,
      icon: Icons.info_outline,
    );
  }

  static void success({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color.fromARGB(255, 64, 190, 121),
      icon: Icons.check_circle,
    );
  }

  static void danger({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }
}
