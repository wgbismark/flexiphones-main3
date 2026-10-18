import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/forgot_password.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// POST /partner/login — agent accounts sign in separately from customers.
class AgentSignin extends StatefulWidget {
  const AgentSignin({super.key});

  @override
  State<AgentSignin> createState() => _AgentSigninState();
}

class _AgentSigninState extends State<AgentSignin> {
  bool showPass = false;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);

    return Scaffold(
      backgroundColor: ch.surface,
      body: Stack(
        children: [
          Bgw(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: ch.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(height: 10),
                Text(
                  "Agent sign in",
                  style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
                ),
                SizedBox(height: 6),
                Text(
                  "Use the email and password of your agent account.",
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 26),
                Form(
                  key: p.agentSignInFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlineInput(
                        controller: p.agentSignInEmailController,
                        enabled: !p.agentLoading,
                        label: "Email",
                        hintText: "eg: name@example.com",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.trim().isValidEmail) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.agentSignInPasswordController,
                        enabled: !p.agentLoading,
                        label: "Password",
                        hintText: "Enter your password",
                        keyboardType: TextInputType.text,
                        obscureText: !showPass,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => showPass = !showPass),
                          icon: Icon(
                            showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              p.agentLoading
                                  ? null
                                  : () {
                                    p.emailEditingController.text =
                                        p.agentSignInEmailController.text
                                            .trim();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const ForgotPassword(
                                              agent: true,
                                            ),
                                      ),
                                    );
                                  },
                          child: Text(
                            "Forgot password?",
                            style: ptstyle(size: 12, weight: 600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: SmartButton(
                          enabled: !p.agentLoading,
                          loading: p.agentLoading,
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            p.agentSignIn(context);
                          },
                          child: Text(
                            "Sign in",
                            style: ptstyle(size: 13, weight: 600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}