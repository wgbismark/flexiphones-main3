import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/email_phone/init_ss_screen.dart';
import 'package:flexiphones/screens/onboarding/forgot_password.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/phone_no_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PhoneSigninX extends StatefulWidget {
  const PhoneSigninX({super.key});

  @override
  State<PhoneSigninX> createState() => _PhoneSigninXState();
}

class _PhoneSigninXState extends State<PhoneSigninX> {
  final formKey_1 = GlobalKey<FormState>();
  bool showPass = false;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
                Form(
                  key: formKey_1,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
      
                      Image.asset(
                        AssetsHelper.signinImage,
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 10),
      
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Verify Phone No.",
                              textAlign: TextAlign.center,
                              style: ptstyle(
                                size: 25,
                                weight: 600,
                                color: ch.onSurface,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Enter your phone number to sign in to your account",
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
                      CountryCodePhoneInput(
                        controller: sharedProvider.phoneController,
                        hintText: "Enter your phone number",
                        keyboardType: TextInputType.phone,
      
                        onChanged: (value) {},
                      ),
                      SizedBox(height: 20),
                      Text(
                        "We will send you a One Time Password (OTP) to verify your phone number.",
                        textAlign: TextAlign.center,
                        style: ptstyle(
                          size: 12,
                          weight: 200,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height: 47,
                        width: double.infinity,
      
                        child: SmartButton(
                          enabled: !sharedProvider.userUDLoading,
                          loading: sharedProvider.userUDLoading,
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (formKey_1.currentState!.validate()) {
                              sharedProvider.phoneSignin(context);
                            }
                          },
                          child: Text(
                            "Send OTP",
                            style: ptstyle(size: 12, weight: 400),
                          ),
                        ),
                      ),
      
                      SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "- or -",
                            style: ptstyle(
                              size: 12,
                              weight: 600,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              NavigationHelper.push(context, InitUserSSScreen());
                            },
                            child: Text(
                              "Use Email instead ?",
                              style: ptstyle(
                                size: 12,
                                weight: 600,
                                color: ch.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
