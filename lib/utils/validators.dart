import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppValidators {
  /// Validates phone number - accepts any numeric input and handles prefixes
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Extract only digits from the input
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Handle Indian number with 91 prefix (12 digits total)
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      digitsOnly = digitsOnly.substring(2);
    }

    // Validate that the resulting phone number is exactly 10 digits
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  /// Cleans a phone number by removing non-digits and optional Indian prefix
  static String cleanPhoneNumber(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    // If it's 13 digits and starts with 91, it might be +91... (which becomes 91... after digitsOnly)
    // Actually replaceAll(r'[^\d]') removes the +, so +91 becomes 91.
    return digitsOnly;
  }

  static String? validatePanCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }

    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

    if (!panRegex.hasMatch(value)) {
      return 'Enter a valid PAN number (e.g. ABCDE1234F)';
    }

    return null;
  }

  static String? validateNomineePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }

    final pan = value.toUpperCase();
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

    if (!panRegex.hasMatch(pan)) {
      return 'Enter a valid PAN number (e.g. ABCDE1234F)';
    }

    // For individual nominees/guardians, the 4th character must be 'P'
    if (pan.length >= 4 && pan[3] != 'P') {
      return 'For a nominee or guardian, the 4th character of the PAN should be P (Individual)';
    }

    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }

    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'First name cannot exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
      return 'First name can only contain letters, spaces and hyphens';
    }

    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }

    if (value.length > 50) {
      return 'Last name cannot exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
      return 'Last name can only contain letters, spaces and hyphens';
    }

    return null;
  }

  static String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }

    try {
      final date = DateFormat('dd/MM/yyyy').parse(value);
      final now = DateTime.now();

      if (date.isAfter(now)) {
        return 'Date of birth cannot be in the future';
      }

      final age =
          now.year -
          date.year -
          (now.month > date.month ||
                  (now.month == date.month && now.day >= date.day)
              ? 0
              : 1);

      if (age > 120) {
        return 'Please enter a valid date of birth';
      }
    } catch (e) {
      return 'Enter a valid date in DD/MM/YYYY format';
    }

    return null;
  }

  // Validator specifically for ISO date format (YYYY-MM-DD)
  static String? validateISODate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    try {
      // Parse ISO format: YYYY-MM-DD
      final date = DateFormat('yyyy-MM-dd').parse(value);
      final now = DateTime.now();

      if (date.isAfter(now)) {
        return 'Date cannot be in the future';
      }

      final age =
          now.year -
          date.year -
          (now.month > date.month ||
                  (now.month == date.month && now.day >= date.day)
              ? 0
              : 1);

      if (age > 120) {
        return 'Please enter a valid date';
      }
    } catch (e) {
      return 'Enter a valid date in YYYY-MM-DD format';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  static String? validatePostalCode(String? value, {String countryCode = 'IND'}) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }

    // For India, postal code must be exactly 6 digits
    if (countryCode == 'IND' || countryCode == '91') {
      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
      if (value.length != digitsOnly.length) {
        return 'Only numbers are allowed';
      }
      if (digitsOnly.length != 6) {
        return 'Postal code must be exactly 6 digits';
      }
    }

    // For foreign countries, validation is removed - let user enter what they like
    return null;
  }
}

/// Collection of input formatters for various form fields
class AppInputFormatters {
  /// Input formatter for phone numbers - accepts any digits
  static List<TextInputFormatter> phoneFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];
  }

  /// Input formatter for PAN Card
  static List<TextInputFormatter> panCardFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      LengthLimitingTextInputFormatter(10),
      _UpperCaseTextFormatter(),
    ];
  }

  /// Lenient input formatter for PAN Card - allows any alphanumeric but enforces uppercase and length
  /// Used when we want to show real-time validation messages instead of blocking input
  static List<TextInputFormatter> panCardFormattersLenient() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      LengthLimitingTextInputFormatter(10),
      _UpperCaseTextFormatter(),
    ];
  }

  /// Input formatter for first name
  static List<TextInputFormatter> firstNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
      LengthLimitingTextInputFormatter(50),
      // Capitalize first letter
      _CapitalizeFirstLetterFormatter(),
    ];
  }

  /// Input formatter for last name
  static List<TextInputFormatter> lastNameFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
      LengthLimitingTextInputFormatter(50),
      // Capitalize first letter
      _CapitalizeFirstLetterFormatter(),
    ];
  }

  /// Input formatter for date of birth (DD/MM/YYYY format)
  static List<TextInputFormatter> dobFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
      _DateInputFormatter(),
    ];
  }

  /// Input formatter for postal code (6 digits for India, alphanumeric for others)
  static List<TextInputFormatter> postalCodeFormatters({
    int length = 6,
    bool numericOnly = true,
  }) {
    return [
      if (numericOnly) FilteringTextInputFormatter.digitsOnly,
      if (!numericOnly)
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
      LengthLimitingTextInputFormatter(length),
      if (!numericOnly) _UpperCaseTextFormatter(),
    ];
  }
}

/// Custom formatter to convert text to uppercase
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Custom formatter to capitalize first letter of each word
class _CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize first letter of each word
    final words = newValue.text.split(' ');
    final capitalizedWords = words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1) : '');
        })
        .join(' ');

    return TextEditingValue(
      text: capitalizedWords,
      selection: newValue.selection,
    );
  }
}


/// Custom formatter for date input (DD/MM/YYYY)
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (oldValue.text.length >= text.length) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;

      if (nonZeroIndex == 2 || nonZeroIndex == 4) {
        if (nonZeroIndex < text.length && text[nonZeroIndex] != '/') {
          buffer.write('/');
        }
      }
    }

    var string = buffer.toString();

    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Helper function for min (used in PAN formatter)
int min(int a, int b) => a < b ? a : b;
