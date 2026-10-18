import 'package:flexiphones/screens/onboarding/email_phone/auth_screen.dart';
import 'package:flutter/material.dart';

/// Sign in: the shared auth screen opened on its "Sign in" tab.
class EmailSignin extends StatelessWidget {
  const EmailSignin({super.key});

  @override
  Widget build(BuildContext context) => const AuthScreen(initialTab: 0);
}
