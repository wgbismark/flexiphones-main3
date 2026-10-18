// import 'dart:async';

// import 'package:fl_country_code_picker/fl_country_code_picker.dart';

// import 'package:flexiphones/extensions/value_validation.dart';
// import 'package:flexiphones/helpers/assets_helper.dart';
// import 'package:flexiphones/helpers/navigation_helper.dart';
// import 'package:flexiphones/helpers/snackbar_helper.dart';
// import 'package:flexiphones/screens/onboarding/otp_verification.dart';
// import 'package:flexiphones/shared_widgets/generalwidgets.dart';
// import 'package:flexiphones/shared_widgets/input_field.dart';
// import 'package:flexiphones/shared_widgets/smart_button.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class Signup extends StatefulWidget {
//   const Signup({super.key});

//   @override
//   State<Signup> createState() => _SignupState();
// }

// class _SignupState extends State<Signup> {
//   var phoneNumberEditingController = TextEditingController();

//   bool phoneNumberValidation = false;
//   bool loading = false;
//   Timer? tm;
//   //
//   var countryCode = FlCountryCodePicker(
//     countryTextStyle: ptstyle(size: 12, weight: 300, color: Colors.black54),
//     dialCodeTextStyle: ptstyle(size: 12, weight: 300, color: Colors.black54),

//   ).countryCodes.firstWhere(
//     (x) => x.dialCode == "+233",
//   );

//   //dummy phoneNumber Auth
//   void validatePhoneNumber(ColorScheme ch) async {
//     setState(() {
//       loading = true;
//     });
//     await Future.delayed(Duration(seconds: 5));

//     Timer(
//       Duration(seconds: 5),
//       () => setState(() {
//         loading = false;
//       }),
//     );
//     if (!mounted) return;
//     SnackbarHelper.info(
//       context: context,
//       title: "OTP Sent!",
//       message:
//           "${countryCode.dialCode} ${phoneNumberEditingController.text} will receive the OTP for verification",
//       ch: ch,
//     );

//     NavigationHelper.push(
//       context,
//       OTPScreen(
//         phoneNumber:
//             "${countryCode.dialCode} ${phoneNumberEditingController.text}",
//       ),
//     );
//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   void dispose() {
//     phoneNumberEditingController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var ch = Theme.of(context).colorScheme;
//     return Scaffold(
//       body: ListView(
//         padding: EdgeInsets.all(20),
//         children: [
//           SizedBox(height: 100),
//           Image.asset(
//             AssetsHelper.signupImage,
//             height: 200,
//             width: 200,
//             fit: BoxFit.contain,
//           ),
//           SizedBox(height: 60),

//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   "Sign up with your phone number",
//                   textAlign: TextAlign.center,
//                   style: ptstyle(size: 25, weight: 600, color: ch.onSurface),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   "We will send you a confirmation code",
//                   textAlign: TextAlign.center,
//                   style: ptstyle(size: 12, weight: 200, color: ch.onSurfaceVariant),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 20),

//           SizedBox(
//             height: 45,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 AbsorbPointer(
//                   absorbing: loading,
//                   child: Opacity(
//                     opacity: loading ? 0.3 : 1,
//                     child: ElevatedButton.icon(
//                       style: ButtonStyle(
//                         elevation: WidgetStatePropertyAll(0.2),
//                         padding: WidgetStatePropertyAll(EdgeInsets.all(13)),
//                         shape: WidgetStatePropertyAll(
//                           RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                       icon: ClipRRect(
//                         borderRadius: BorderRadius.circular(5),
//                         child: Image.asset(
//                           countryCode.flagUri,
//                           package: countryCode.flagImagePackage,
//                           height: 20,
//                           width: 30,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                       onPressed: () async {
//                         final picked = await FlCountryCodePicker().showPicker(
//                           context: context,
//                         );
//                         FlCountryCodePicker().countryCodes.firstWhere(
//                           (x) => x.dialCode == "+233",
//                         );
//                         // Null check
//                         if (picked != null) {
//                           setState(() {
//                             countryCode = picked;
//                           });
//                         }
//                       },
//                       label: Row(
//                         children: [
//                           Text(
//                             countryCode.dialCode,
//                             style: ptstyle(size: 13, weight: 300, color: ch.onPrimaryContainer),
//                           ),
//                           SizedBox(width: 7),
//                           Icon(CupertinoIcons.chevron_down, size: 15, color: ch.onPrimaryContainer),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),

//                 SizedBox(width: 20),
//                 Expanded(
//                   child: OutlineInput(
//                     enabled: !loading,
//                     label: "Phone Number",
//                     hintText: "eg 01234567",
//                     controller: phoneNumberEditingController,
//                     keyboardType: TextInputType.number,
//                     onchange: (x) {
//                       setState(() {
//                         phoneNumberValidation =
//                             x.isEmpty ? false : !x.isValidPhoneNumber;
//                       });
//                     },
//                     error: phoneNumberValidation,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: 40),
//           SizedBox(
//             height: 47,

//             child: SmartButton(
//               enabled:
//                   !phoneNumberValidation &&
//                   phoneNumberEditingController.text.isNotEmpty,
//               loading: loading,
//               onPressed: () => {validatePhoneNumber(ch)},
//               child: Text("Send Code", style: ptstyle(size: 12, weight: 400)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
