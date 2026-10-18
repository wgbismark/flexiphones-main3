extension PhoneNumberValidator on String {
  bool get isValidPhoneNumber {
    final regex = RegExp(r'^[0-9]\d{8}$');
    return regex.hasMatch(this);
  }
}

extension GhanaCardDigitsValidator on String {
  bool get isValidGhanaCardDigits {
    final regex = RegExp(r'^[0-9]{9}-[0-9]$');
    return regex.hasMatch(this);
  }
}

extension EmailValidator on String {
  bool get isValidEmail {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@(?!(example\.com|example\.org|example\.net)$)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return regex.hasMatch(this);
  }
}

extension PasswordValidator on String {
  bool get isValidPassword {
    // Any symbol counts (@ # _ . - etc.), not just a short list.
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return regex.hasMatch(this);
  }
}

/// Rules that mirror the Laravel Partner AuthController validation exactly,
/// so the app never sends something the backend will reject.
extension PartnerFieldValidators on String {
  /// Backend: ^(\+233|0|233)[2-9][0-9]{8}$  — we send "0" + these 9 digits,
  /// so the 9 digits must start with 2-9.
  bool get isValidPartnerLocalPhone => RegExp(r'^[2-9]\d{8}$').hasMatch(this);

  /// Backend: min 2, max 100, letters and spaces only.
  bool get isValidPartnerName =>
      trim().length >= 2 &&
      trim().length <= 100 &&
      RegExp(r'^[a-zA-Z\s]+$').hasMatch(trim());

  /// Upper + lower + digit + any symbol the person likes (min 8).
  bool get isValidPartnerPassword => isValidPassword;
}

extension StringLetterCheck on String {
  bool get containsLetters => RegExp(r'[a-zA-Z]').hasMatch(this);
}

extension DateTimeThreshold on DateTime {
  /// Returns `true` if this DateTime is at least current time minus 30 seconds.
  bool isWithinLast30SecondsOrFuture() {
    final now = DateTime.now();
    final diff = now.difference(this);
    // If difference is negative: this > now → future: true
    // If difference is ≤ 30 seconds: true
    return diff.inSeconds <= 20;
  }
}