import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';

class UserCredentialPage extends StatefulWidget {
  const UserCredentialPage({super.key});

  @override
  UserCredentialPageState createState() => UserCredentialPageState();
}

class UserCredentialPageState extends State<UserCredentialPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool showPass = false;
  bool showPass1 = false;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final labelStyle = ptstyle(
      size: 12,
      weight: 200,
      color: ch.onSurfaceVariant,
    );
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 20),
      body: Stack(
        children: [
          Bgw(),
          ListView(
            children: [
              Image.asset(
                AssetsHelper.urcImg1,
                height: 180,
                width: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Update Your Details",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 25,
                        weight: 600,
                        color: ch.onSurface,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Fill in the following inputs to continue.",
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: sharedProvider.formKey_2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlineInput(
                        controller: sharedProvider.fullNameController,

                        label: "Full Name",
                        hintText: "eg: John Doe",

                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your full name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      OutlineInput(
                        controller: sharedProvider.locationController,

                        label: "Location",
                        hintText: "eg: City, Country",

                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your location";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          AbsorbPointer(
                            absorbing: sharedProvider.userUDLoading,
                            child: Opacity(
                              opacity: sharedProvider.userUDLoading ? 0.3 : 1,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  padding: EdgeInsets.all(13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.asset(
                                    sharedProvider.countryCodeS.flagUri,
                                    package:
                                        sharedProvider
                                            .countryCodeS
                                            .flagImagePackage,
                                    height: 20,
                                    width: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                onPressed: () async {
                                  final picked = await FlCountryCodePicker(
                                    favorites: ["233"],
                                  ).showPicker(context: context);
                                  FlCountryCodePicker().countryCodes.firstWhere(
                                    (x) => x.dialCode == "+233",
                                  );
                                  // Null check
                                  if (picked != null) {
                                    setState(() {
                                      sharedProvider.countryCodeS= picked;
                                    });
                                  }
                                },
                                label: Row(
                                  children: [
                                    Text(
                                      sharedProvider.countryCodeS.dialCode,
                                      style: ptstyle(
                                        size: 13,
                                        weight: 300,
                                        color: ch.onPrimaryContainer,
                                      ),
                                    ),
                                    SizedBox(width: 7),
                                    Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 15,
                                      color: ch.onPrimaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: OutlineInput(
                              controller: sharedProvider.phoneController,

                              label: "Phone Number",
                              hintText: "eg: 123456789",
                              maxLength: 9,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.isValidPhoneNumber) {
                                  return "Invalid 9 digit phone number";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: sharedProvider.passwordController,

                        label: "Password",
                        hintText: "Enter your password",

                        keyboardType: TextInputType.text,

                        obscureText: !showPass1,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                showPass1 = !showPass1;
                              });
                            },
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.all(0),
                            ),
                            icon: AnimatedSwitcher(
                              duration: Duration(milliseconds: 400),
                              child:
                                  showPass1
                                      ? Icon(Icons.visibility_off_outlined)
                                      : Icon(Icons.visibility_outlined),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a password";
                          }

                          if (value.length < 8) {
                            return " Character length should be 8 or more";
                          }

                          if (!value.isValidPassword) {
                            return "Use 8+ characters with upper & lower case, a number and a symbol (e.g. @ # _)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: sharedProvider.rePasswordController,

                        label: "Re-enter Password",
                        hintText: "Confirm your password",

                        keyboardType: TextInputType.text,
                        obscureText: !showPass,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                showPass = !showPass;
                              });
                            },
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.all(0),
                            ),
                            icon: AnimatedSwitcher(
                              duration: Duration(milliseconds: 400),
                              child:
                                  showPass
                                      ? Icon(Icons.visibility_off_outlined)
                                      : Icon(Icons.visibility_outlined),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != sharedProvider.passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Optional: a friend's code. A wrong code never
                      // blocks sign-up (the server ignores it).
                      OutlineInput(
                        controller: sharedProvider.referralCodeController,
                        label: "Have a referral code? (optional)",
                        hintText: "e.g. FXK7M2QPA",
                        prefixIcon: Icons.card_giftcard_rounded,
                        maxLength: 20,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 47,
                        width: double.infinity,

                        child: SmartButton(
                          enabled: !sharedProvider.userUDLoading,
                          loading: sharedProvider.userUDLoading,
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            sharedProvider.finalRegistration(context);
                          },
                          child: Text(
                            "Continue",
                            style: ptstyle(size: 12, weight: 400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
