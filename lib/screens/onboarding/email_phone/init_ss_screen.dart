import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/email_phone/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sign up: the shared auth screen opened on its "Sign up" tab. Opening it
/// means nobody is signed in, so anything an earlier account left on the
/// phone is wiped first.
class InitUserSSScreen extends StatefulWidget {
  const InitUserSSScreen({super.key});

  @override
  State<InitUserSSScreen> createState() => _InitUserSSScreenState();
}

class _InitUserSSScreenState extends State<InitUserSSScreen> {
  @override
  void initState() {
    super.initState();
    final p = Provider.of<SharedProvider>(context, listen: false);
    if (p.userData != null) p.clearLocalUserData();
  }

  @override
  Widget build(BuildContext context) => const AuthScreen(initialTab: 1);
}
