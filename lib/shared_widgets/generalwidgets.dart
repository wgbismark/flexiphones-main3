import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';

TextStyle ptstyle({
  required double size,
  required int weight,
  color,
  double? height,
  letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
}) {
  FontWeight fontWeight = FontWeight.w400;

  switch (weight) {
    case 300:
      fontWeight = FontWeight.w300;
      break;

    case 400:
      fontWeight = FontWeight.w400;
      break;

    case 500:
      fontWeight = FontWeight.w500;
      break;

    case 600:
      fontWeight = FontWeight.w600;
      break;

    case 700:
      fontWeight = FontWeight.w700;
      break;

    case 800:
      fontWeight = FontWeight.w800;
      break;

    case 900:
      fontWeight = FontWeight.w900;
      break;
  }

  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
  );
}

Container longButton(String title) {
  return Container(
    height: 50,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.darkBlack,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Center(
      child: Text(
        title,
        style: ptstyle(size: 12, weight: 600, color: AppColors.appWhite),
      ),
    ),
  );
}

void appButton(String title) {}

Column regTextField({required String title, required field}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: ptstyle(
          size: 11,
          weight: 400,
          color: const Color.fromRGBO(70, 69, 69, 1),
          height: 1,
        ),
      ),
      const SizedBox(height: 7),
      field,
    ],
  );
}

InputDecoration regFieldDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: ptstyle(size: 11, weight: 400, color: AppColors.darkBlack),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.darkBlack),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red, width: 0.8),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colors.red, width: 1),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.darkBlack, width: 0.4),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: AppColors.darkBlack, width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
  contentPadding: const EdgeInsets.only(top: 22, left: 16, right: 16),
  errorStyle: ptstyle(size: 11, weight: 400),
);

dynamic formStyle() {
  return ptstyle(size: 12, weight: 400, color: AppColors.darkBlack);
}
