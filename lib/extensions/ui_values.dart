import 'package:flutter/material.dart';

extension ResponsiveSizeExtensions on num {
  double get w {
    return ((this / 100) * MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width);
  }

  double get h {
    return (this / 100) * MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height;
  }
}