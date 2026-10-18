import 'package:flexiphones/helpers/snackbar_helper.dart';
import 'package:flutter/material.dart';

class Notify extends ChangeNotifier {
  static void invalidEmail(BuildContext context) => SnackbarHelper.danger(
    context: context,
    title: "Invalid Email",
    message: "Check and re-enter email",
  );
  static void validEmail(BuildContext context, ColorScheme ch) =>
      SnackbarHelper.info(
        context: context,
        title: "OTP Sent!",
        message: "OTP sent to email for verification",
        ch: ch,
      );


  static void invalidOTP(BuildContext context) =>
      SnackbarHelper.danger(
        context: context,
        title: "Invalid OTP",
        message: "Enter the correct OTP or resend",
      );
}
