import 'package:flutter/material.dart';

class STV {
  static Color getDeviceStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == "ready for use") return Colors.green;
    if (s == "locked") return Colors.red;
    if (s == "cancelled") return Colors.red;
    return Colors.indigo;
  }

  static Color getDeliveryStatusColor(String status, ColorScheme ch) {
    final s = status.toLowerCase();
    if (s == "placed") return Colors.indigo;
    if (s == "delivered") return Colors.green;
    if (s == "orders" || s == "all orders") return ch.onSurfaceVariant;
    return Colors.red;
  }

  /// Colour for an order's `order_stage` code.
  static Color getOrderStageColor(String stage, ColorScheme ch) {
    switch (stage.toLowerCase()) {
      case "placed":
        return Colors.indigo;
      case "in_review":
        return Colors.orange.shade800;
      case "confirmed":
        return Colors.teal;
      case "shipped":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return ch.onSurfaceVariant;
    }
  }

  static const waveColors = [
    Color.fromARGB(197, 242, 251, 255),

    Color.fromRGBO(232, 240, 255, 1),
    Color.fromRGBO(192, 213, 255, 0.635),
    Color.fromRGBO(79, 138, 255, 0.706),
  ];
  static const waveColors2 = [
    Color.fromARGB(255, 242, 252, 255),
    Color.fromARGB(151, 223, 241, 255),
    Color.fromARGB(209, 242, 248, 255),
    Color.fromRGBO(252, 253, 255, 1),
  ];

  static const waveColors3 = [
    Color.fromARGB(197, 242, 251, 255),

    Color.fromRGBO(243, 247, 255, 1),
    Color.fromRGBO(243, 247, 255, 0.842),
    Color.fromRGBO(255, 255, 255, 1),
  ];

  static const waveColors33 = [
    Color.fromARGB(255, 242, 252, 255),
    Color.fromARGB(151, 223, 241, 255),
    Color.fromARGB(209, 242, 248, 255),
    Color.fromRGBO(252, 253, 255, 1),
  ];
  static const waveColors33a = [
    Color.fromARGB(255, 251, 255, 253),
    Color.fromARGB(255, 248, 255, 253),
    Color.fromARGB(209, 242, 255, 250),
    Color.fromRGBO(252, 255, 254, 1),
  ];
  static const waveColors33a1 = [
    Color.fromARGB(214, 245, 250, 255),

    Color.fromRGBO(245, 248, 255, 1),
    Color.fromRGBO(251, 252, 255, 0.827),
    Color.fromRGBO(250, 251, 255, 0.87),
  ];

  //!DARK

  static const waveColorsDark = [
    Color.fromARGB(127, 30, 40, 55), // Deep steel blue
    Color.fromRGBO(35, 45, 65, 0.555), // Midnight navy
    Color.fromRGBO(45, 60, 90, 0.459), // Muted blue-grey
    Color.fromRGBO(60, 90, 150, 0.507), // Accent steel blue
  ];

  static const waveColors2Dark = [
    Color.fromARGB(129, 16, 20, 27), // Almost black with a blue hint
    Color.fromARGB(90, 15, 21, 27), // Semi-transparent cool grey
    Color.fromARGB(136, 10, 15, 22), // Slightly brighter dark blue-grey
    Color.fromRGBO(10, 13, 19, 0.568), // Base dark background
  ];

  static const waveColors3Dark = [
    Color.fromARGB(59, 23, 29, 43), // Muted indigo-blue
    Color.fromRGBO(21, 28, 41, 0.275), // Indigo-gray
    Color.fromRGBO(22, 31, 44, 0.247), // Slightly transparent
    Color.fromRGBO(12, 16, 24, 0.22), // Border-line background wave
  ];

  static const waveColors33Dark = [
    Color.fromARGB(148, 25, 32, 45),
    Color.fromARGB(108, 35, 40, 55),
    Color.fromARGB(150, 28, 36, 50),
    Color.fromRGBO(22, 28, 40, 0.678),
  ];

  static const waveColors33aDark = [
    Color.fromARGB(185, 20, 25, 30),
    Color.fromARGB(172, 25, 30, 35),
    Color.fromARGB(150, 30, 38, 44),
    Color.fromRGBO(26, 30, 40, 0.514),
  ];

  static const waveColors33a1Dark = [
    Color.fromARGB(97, 40, 50, 70),
    Color.fromRGBO(45, 55, 80, 0.603),
    Color.fromRGBO(60, 70, 100, 0.438),
    Color.fromRGBO(55, 65, 95, 0.438),
  ];

  static const waveDurations = [7500, 7000, 6500, 6000];

  static const waveHeightPercentages = [0.75, 0.80, 0.85, 0.90];
  static const waveHeightPercentages2 = [0.70, 0.80, 0.85, 0.90];
}
