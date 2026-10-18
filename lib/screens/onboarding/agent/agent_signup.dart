import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signin.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Step 1 of 3: agent email -> POST /partner/email-verification.
/// A partner is a separate account from the customer account, so this
/// email only pre-fills from the customer's email; it can be changed.
class AgentSignup extends StatefulWidget {
  const AgentSignup({super.key});

  @override
  State<AgentSignup> createState() => _AgentSignupState();
}

class _AgentSignupState extends State<AgentSignup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SharedProvider>(context, listen: false)
          .prefillAgentFieldsFromUser();
    });
  }

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
                  "Become an Agent",
                  style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
                ),
                SizedBox(height: 6),
                Text(
                  "Step 1 of 3 · Verify your email. Your agent account is separate from your customer account and has its own password.",
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 26),
                Form(
                  key: p.agentEmailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlineInput(
                        controller: p.agentEmailController,
                        enabled: !p.agentLoading,
                        label: "Email",
                        hintText: "eg: name@example.com",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your email";
                          }
                          if (!value.trim().isValidEmail) {
                            return "Invalid email provided";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: SmartButton(
                          enabled: !p.agentLoading,
                          loading: p.agentLoading,
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (p.agentEmailFormKey.currentState!.validate()) {
                              p.agentSendEmailOtp(context);
                            }
                          },
                          child: Text(
                            "Send verification code",
                            style: ptstyle(size: 13, weight: 600),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => NavigationHelper.push(
                            context,
                            const AgentSignin(),
                          ),
                          child: Text(
                            "Already an agent? Sign in",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.primary,
                            ),
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