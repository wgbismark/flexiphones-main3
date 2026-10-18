// import 'package:flutter/material.dart';

// class RegionCitySelector extends StatefulWidget {
//   const RegionCitySelector({Key? key}) : super(key: key);

//   @override
//   _RegionCitySelectorState createState() => _RegionCitySelectorState();
// }

// class _RegionCitySelectorState extends State<RegionCitySelector> {
//   final List<Map<String, dynamic>> ghanaRegions = [
//     {"region": "Greater Accra", "cities": ["Accra", "Tema", "Madina", "Teshie"]},
//     {"region": "Ashanti", "cities": ["Kumasi", "Obuasi", "Ejisu", "Konongo"]},
//     {"region": "Western", "cities": ["Sekondi-Takoradi", "Tarkwa", "Axim"]},
//     {"region": "Eastern", "cities": ["Koforidua", "Nkawkaw", "Akosombo"]},
//     {"region": "Central", "cities": ["Cape Coast", "Mankessim", "Elmina"]},
//     {"region": "Volta", "cities": ["Ho", "Keta", "Aflao", "Hohoe"]},
//     {"region": "Northern", "cities": ["Tamale", "Yendi", "Gushegu"]},
//     {"region": "Upper East", "cities": ["Bolgatanga", "Navrongo", "Bawku"]},
//     {"region": "Upper West", "cities": ["Wa", "Lawra", "Tumu"]},
//     {"region": "Bono", "cities": ["Sunyani", "Berekum", "Dormaa Ahenkro"]},
//     {"region": "Bono East", "cities": ["Techiman", "Atebubu", "Kintampo"]},
//     {"region": "Ahafo", "cities": ["Goaso", "Bechem", "Hwidiem"]},
//     {"region": "Oti", "cities": ["Dambai", "Kadjebi", "Nkwanta"]},
//     {"region": "North East", "cities": ["Nalerigu", "Walewale", "Gambaga"]},
//     {"region": "Savannah", "cities": ["Damongo", "Bole", "Salaga"]},
//     {"region": "Western North", "cities": ["Sefwi Wiawso", "Bibiani", "Enchi"]},
//   ];

//   String? selectedRegion;
//   String? selectedCity;

//   List<String> get currentCities {
//     final region = ghanaRegions.firstWhere(
//       (r) => r['region'] == selectedRegion,
//       orElse: () => {"cities": []},
//     );
//     return List<String>.from(region['cities']);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('Select Region'),
//         DropdownButton<String>(
//           isExpanded: true,
//           value: selectedRegion,
//           hint: const Text("Choose a region"),
//           items: ghanaRegions.map((region) {
//             return DropdownMenuItem<String>(
//               value: region['region'],
//               child: Text(region['region']),
//             );
//           }).toList(),
//           onChanged: (value) {
//             setState(() {
//               selectedRegion = value;
//               selectedCity = null; // Reset city when region changes
//             });
//           },
//         ),
//         const SizedBox(height: 16),
//         const Text('Select City'),
//         DropdownButton<String>(
//           isExpanded: true,
//           value: selectedCity,
//           hint: const Text("Choose a city"),
//           items: currentCities.map((city) {
//             return DropdownMenuItem<String>(
//               value: city,
//               child: Text(city),
//             );
//           }).toList(),
//           onChanged: selectedRegion == null
//               ? null
//               : (value) {
//                   setState(() {
//                     selectedCity = value;
//                   });
//                 },
//         ),
//       ],
//     );
//   }
// }
