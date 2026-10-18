// import 'package:flexiphones/helpers/assets_helper.dart';
// import 'package:flexiphones/provider/provider_class.dart';
// import 'package:flexiphones/screens/checkout/sub_pages/payment_confirmation.dart';
// import 'package:flexiphones/screens/checkout/sub_pages/payment_method.dart';
// import 'package:flexiphones/screens/checkout/sub_pages/payment_success.dart';
// import 'package:flexiphones/shared_widgets/smart_button.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class CheckoutPaymentScreen extends StatefulWidget {
//   final List items;
//   final double totalAmount;

//   const CheckoutPaymentScreen({
//     super.key,
//     required this.items,
//     required this.totalAmount,
//   });

//   @override
//   CheckoutPaymentScreenState createState() => CheckoutPaymentScreenState();
// }

// class CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
//   int currentStep = 0; // 0: Payment Method, 1: Confirmation, 2: Success
//   String selectedPaymentMethod = 'mobile-money';
//   final PageController _pageController = PageController();

//   List paymentMethods = [
//     {'id': 'mobile-money', 'name': 'Mobile Money', 'icon': AssetsHelper.mmImg},
//     {'id': 'card', 'name': 'Credit/Debit Card', 'icon': AssetsHelper.cardImg},
//   ];

//   void _previousStep() {
//     if (currentStep > 0) {
//       setState(() {
//         currentStep--;
//       });
//       _pageController.previousPage(
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeIn,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     var ch = Theme.of(context).colorScheme;
//     final sharedProvider = Provider.of<SharedProvider>(context);

//     void nextStep() async {
//       if (currentStep == 0 && selectedPaymentMethod.isNotEmpty) {
//         setState(() {
//           currentStep = 1;
//         });
//         _pageController.nextPage(
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeIn,
//         );
//       } else if (currentStep == 1) {
//         // Simulate payment processing

    

//         Future.delayed(Duration(seconds: 2), () {});

//         setState(() {
//           currentStep = 2;
//         });
//         _pageController.nextPage(
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeIn,
//         );
//       }
//     }

//     return Scaffold(
//       appBar: AppBar(
//         excludeHeaderSemantics: true,
//         backgroundColor: ch.surface,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         title: Text('Checkout'),
//         centerTitle: true,
//         automaticallyImplyLeading: currentStep == 2 ? false : true,
//         leading:
//             currentStep == 1
//                 ? IconButton(
//                   onPressed: _previousStep,
//                   icon: Icon(Icons.arrow_back, size: 20),
//                 )
//                 : currentStep == 2
//                 ? null
//                 : null,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(10),
//         child: Column(
//           children: [
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 physics: NeverScrollableScrollPhysics(),
//                 children: [
//                   PaymentMethod(
//                     selectedPaymentMethod: selectedPaymentMethod,
//                     paymentChanged: (value) {
//                       setState(() {
//                         selectedPaymentMethod = value;
//                       });
//                     },
//                   ),

//                   PaymentConfirmation(
//                     referenceId: "AA09043344",
//                     totalAmount: widget.totalAmount,
//                   ),

//                   OrderPlacedSuccess(),
//                 ],
//               ),
//             ),

//             // Navigation Buttons
//             if (currentStep < 2)
//               SizedBox(
//                 height: 40,
//                 width: double.infinity,
//                 child: SmartButton(
//                   loading: sharedProvider.payLoading,
//                   enabled: currentStep != 2,
//                   onPressed: () => currentStep == 2 ? null : nextStep(),

//                   child: Text(
//                     currentStep == 1 ? 'Pay' : 'Select Payment Method',
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
