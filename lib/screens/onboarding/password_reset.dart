import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  bool _show1 = false, _show2 = false;

  Widget _eye(bool on, VoidCallback tap) => IconButton(
    onPressed: tap,
    icon: Icon(on ? Icons.visibility_off_rounded : Icons.visibility_rounded),
  );

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: sharedProvider.formKey_3,
          child: ListView(
            children: [
              SizedBox(height: 60),

              Image.asset(
                AssetsHelper.resetPassImage,
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
                      "Reset Password",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 25,
                        weight: 700,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Enter & confirm new password",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 12,
                        weight: 300,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ch.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Text(
                        sharedProvider.emailEditingController.text.trim(),
                        textAlign: TextAlign.center,
                        style: ptstyle(size: 15, weight: 500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              OutlineInput(
                label: "New Password",
                hintText: "....",
                controller: sharedProvider.passwordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: !_show1,
                suffixIcon: _eye(_show1, () => setState(() => _show1 = !_show1)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a password";
                  }

                  if (value.length < 8) {
                    return " Character length should be 8 or more";
                  }                  if (!value.isValidPartnerPassword) {
                    return "Use upper & lower case, a number and a symbol (e.g. @ # _)";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              OutlineInput(
                label: "Confirm New Password",
                hintText: "....",
                controller: sharedProvider.rePasswordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: !_show2,
                suffixIcon: _eye(_show2, () => setState(() => _show2 = !_show2)),
                validator: (value) {
                  if (value != sharedProvider.passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,

                child: SmartButton(
                  loading: sharedProvider.userUDLoading,
                  enabled: !sharedProvider.userUDLoading,
                  onPressed:
                      () => {
                        FocusScope.of(context).unfocus(),
                        sharedProvider.resetPassword(context, ch),
                      },

                  child: const Text(
                    "Save & Continue",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
