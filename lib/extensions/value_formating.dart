import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

extension TimeFormatting on DateTime {
  /// date and time, e.g. “Tuesday, June 10, 2025 at 03:45 PM”
  String formatDate() =>
      DateFormat('EEE, MMMM d, yyyy \'at\' hh:mm a').format(this);
  String formatDateNoTime() => DateFormat('MMMM d, yyyy').format(this);

  String toAgoShort() => timeago.format(this, locale: 'en_short');
  String toAgo() => timeago.format(this, locale: 'en');
}

extension HumanReadableString on String {
  String toHumanReadable({int decimalPlaces = 1}) {
    final parsed = double.tryParse(replaceAll(',', ''));
    if (parsed == null) return this; // return original if not a number

    final suffixes = ['K', 'M', 'B', 'T'];
    double value = parsed.abs();
    int i = -1;

    while (value >= 1000 && i < suffixes.length - 1) {
      value /= 1000;
      i++;
    }

    final formatted = value.toStringAsFixed(decimalPlaces);
    final sign = parsed < 0 ? '-' : '';
    return i == -1 ? this : '$sign$formatted${suffixes[i]}';
  }

  String toAmPm() {
    // Expect format "HH:mm:ss"
    final parts = split(":");
    if (parts.length != 3) return this; // return original if format is wrong

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;
    int second = int.tryParse(parts[2]) ?? 0;

    String period = hour >= 12 ? "PM" : "AM";
    int formattedHour = hour % 12 == 0 ? 12 : hour % 12;

    String formattedMinute = minute.toString().padLeft(2, '0');
    String formattedSecond = second.toString().padLeft(2, '0');

    return "$formattedHour:$formattedMinute $period";
  }
}

extension SentenceCaseExtension on String {
  String toSentenceCase() {
    if (trim().isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

extension NumberFormatter on num {
  /// Formats the number with comma separators (e.g., 1234567.89 → "1,234,567.89")
  String toCommaSeparated(int i, {int? decimalPlaces}) {
    // Handle null
    final number =
        decimalPlaces != null
            ? toDouble().toStringAsFixed(decimalPlaces)
            : toString();

    // Split into integer and fractional parts
    final parts = number.split('.');
    final integerPart = parts[0];
    final fractionalPart = parts.length > 1 ? parts[1] : '';

    // Add commas to integer part
    final reversedInt = integerPart.split('').reversed.join();
    final reversedWithCommas = reversedInt.replaceAllMapped(
      RegExp(r'\d{3}(?=\d)'),
      (match) => '${match.group(0)},',
    );
    final formattedInt = reversedWithCommas.split('').reversed.join();

    // Combine with fractional part if exists
    if (fractionalPart.isNotEmpty) {
      return '$formattedInt.$fractionalPart';
    }

    return formattedInt;
  }



}


  extension DateHelpers on DateTime {
  int get dayOfYear {
    final startOfYear = DateTime(year);
    return difference(startOfYear).inDays + 1;
  }
}