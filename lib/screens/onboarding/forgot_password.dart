import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPassword extends StatefulWidget {
  /// [agent] resets an agent (partner) account via /partner/... instead of
  /// the customer endpoints. The code and new-password screens are shared.
  const ForgotPassword({super.key, this.agent = false});

  final bool agent;

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  void initState() {
    super.initState();
    Provider.of<SharedProvider>(context, listen: false).resetForAgent =
        widget.agent;
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return AbsorbPointer(
      absorbing: sharedProvider.emailVerification,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: ch.surface.withOpacity(0.8),
          toolbarHeight: 45,
        ),
        body: Stack(
          children: [
            Bgw(),
            ListView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                Column(
                  children: [
                    SizedBox(height: 20),

                    Image.asset(
                      AssetsHelper.forgottenPassImage,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 40),

                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.agent
                                ? "Agent Password Reset"
                                : sharedProvider.userData != null
                                ? "Update Your Password"
                                : "Forgot Password ?",
                            textAlign: TextAlign.center,
                            style: ptstyle(
                              size: 25,
                              weight: 600,
                              color: ch.onSurface,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Enter your email address bellow",
                            textAlign: TextAlign.center,
                            style: ptstyle(
                              size: 12,
                              weight: 200,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    OutlineInput(
                      focusNode: sharedProvider.emailFocusNode,
                      enabled: !sharedProvider.emailVerification,
                      label: "Your Email",
                      hintText: "eg: name@example.com ...",
                      controller: sharedProvider.emailEditingController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.isValidEmail) {
                          return "Invalid Email provided";
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 40),
                    SizedBox(
                      height: 47,
                      width: double.infinity,

                      child: SmartButton(
                        enabled: !sharedProvider.emailVerification,
                        loading: sharedProvider.emailVerification,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          sharedProvider.forgottenPassword(context, ch);
                        },
                        child: Text(
                          "Verify Email",
                          style: ptstyle(size: 12, weight: 400),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
