// import 'package:flexiphones/provider/provider_class.dart';
// import 'package:flexiphones/shared_widgets/generalwidgets.dart';
// import 'package:flexiphones/shared_widgets/input_field.dart';
// import 'package:flexiphones/shared_widgets/smart_button.dart';
// import 'package:flexiphones/shared_widgets/space_divider.dart';
// import 'package:flexiphones/utils/values.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class FilterDrawer extends StatefulWidget {
//   const FilterDrawer({super.key, required this.sfc});
//   final GlobalKey<ScaffoldState> sfc;
//   @override
//   State<FilterDrawer> createState() => _FilterDrawerState();
// }

// class _FilterDrawerState extends State<FilterDrawer> {
//   List<String> regions = <String>[
//     'All',
//     'Ahafo',
//     'Ashanti',
//     'Bono',
//     'Bono East',
//     'Central',
//     'Eastern',
//     'Greater Accra',
//     'North East',
//     'Northern',
//     'Oti',
//     'Savannah',
//     'Upper East',
//     'Upper West',
//     'Volta',
//     'Western',
//     'Western North',
//   ];

//   final Set<String> _selectedDurations = {};

//   @override
//   Widget build(BuildContext context) {
//     var ch = Theme.of(context).colorScheme;
//     final sharedProvider = Provider.of<SharedProvider>(context);

//     return Container(
//       width: 250,
//       color: ch.surface,
//       child: ListView(
//         children: [
//           // Header
//           Container(
//             alignment: Alignment.bottomCenter,
//             padding: EdgeInsets.only(bottom: 20, left: 15),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Text(
//                   "Filter",
//                   style: ptstyle(
//                     size: 25,
//                     weight: 600,
//                     color: ch.onSurfaceVariant.withOpacity(0.2),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           //  SDivider(),
//           // Price Range
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 15),
//             child: Column(
//               children: [
//                 ListTile(
//                   title: Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: Text(
//                       "Price Range (${GlobalValues.ghCurrency})",
//                       style: ptstyle(
//                         size: 12,
//                         weight: 600,
//                         color: ch.onSurfaceVariant,
//                       ),
//                     ),
//                   ),

//                   subtitle: SizedBox(
//                     height: 45,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: FilledInput(
//                             label: "",
//                             hintText: "1000",
//                             controller: sharedProvider.rMinController,
//                           ),
//                         ),

//                         SizedBox(width: 8),
//                         Text("-"),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: FilledInput(
//                             label: "",
//                             hintText: "3000",
//                             controller: sharedProvider.rMaxController,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   contentPadding: EdgeInsets.zero,
//                 ),
//               ],
//             ),
//           ),
//           SDivider(),
//           // Location
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 15),
//             child: Column(
//               children: [
//                 ListTile(
//                   title: Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: Text(
//                       "Location",
//                       style: ptstyle(size: 12, weight: 600),
//                     ),
//                   ),
//                   subtitle: DropdownButton<String>(
//                     isExpanded: true,
//                     value: sharedProvider.locationS,
//                     underline: SizedBox(),
//                     items:
//                         regions.map<DropdownMenuItem<String>>((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(
//                               value,
//                               style: ptstyle(size: 12, weight: 400),
//                             ),
//                           );
//                         }).toList(),
//                     onChanged: (String? newValue) {
//                       // Handle location change

//                       sharedProvider.locationS = newValue!.trim();
//                       sharedProvider.getFilteredProducts(
//                         location: sharedProvider.locationS,
//                       );
//                     },
//                   ),
//                   contentPadding: EdgeInsets.zero,
//                 ),
//               ],
//             ),
//           ),
//           SDivider(),
//           // Payment Duration
//           Padding(
//             padding: EdgeInsets.only(left: 15, right: 5),
//             child: Column(
//               children: [
//                 ListTile(
//                   title: Text(
//                     "Payment Duration",
//                     style: ptstyle(size: 12, weight: 600),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "3 Months",
//                             style: ptstyle(
//                               size: 12,
//                               weight: 400,
//                               color: ch.onSurfaceVariant,
//                             ),
//                           ),
//                           Checkbox(
//                             value: sharedProvider.selectedDurations.contains(
//                               "3 Months",
//                             ),
//                             onChanged: (bool? value) {
//                               sharedProvider.toggleDuration("3 Months");
//                             },
//                           ),
//                         ],
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "6 Months",
//                             style: ptstyle(
//                               size: 12,
//                               weight: 400,
//                               color: ch.onSurfaceVariant,
//                             ),
//                           ),
//                           Checkbox(
//                             value: sharedProvider.selectedDurations.contains(
//                               "6 Months",
//                             ),
//                             onChanged: (bool? value) {
//                               sharedProvider.toggleDuration("6 months");
//                               sharedProvider.getFilteredProducts(
//                                 paymentDuration:
//                                     sharedProvider.selectedDurations,
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   contentPadding: EdgeInsets.zero,
//                 ),
//               ],
//             ),
//           ),
//           SDivider(),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 15),
//             child: Column(
//               children: [
//                 SizedBox(
//                   width: double.infinity,
//                   child: SmartButton(
//                     enabled: !sharedProvider.searchingProduct,
//                     loading: sharedProvider.searchingProduct,
//                     onPressed: () {
//                       sharedProvider.getFilteredProducts(
//                         location: sharedProvider.locationS,
//                         maxPrice: double.parse(
//                           sharedProvider.rMaxController.text.trim(),
//                         ),
//                         minPrice: double.parse(
//                           sharedProvider.rMinController.text.trim(),
//                         ),
//                         paymentDuration: sharedProvider.selectedDurations,
//                       );
//                       widget.sfc.currentState!.closeEndDrawer();
//                     },
//                     child: Text("Search"),
//                   ),
//                 ),

//                 SizedBox(height: 10),
//                 SizedBox(
//                   width: double.infinity,
//                   child: FilledButton.tonal(
//                     onPressed: () {
//                       widget.sfc.currentState!.closeEndDrawer();

//                       sharedProvider.getFilteredProducts(reset: true);
//                     },
//                     style: FilledButton.styleFrom(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: Text("Clear"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
