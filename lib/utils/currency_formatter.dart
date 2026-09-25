import 'package:intl/intl.dart';

/// A utility class for formatting currency values in Indian Rupee format
/// with appropriate suffixes (K, L, Cr) based on the value.
class CurrencyFormatter {
  /// Formats a number as Indian Rupee with the ₹ symbol and appropriate suffix
  ///
  /// Examples:
  /// - 1000 becomes ₹1,000
  /// - 100000 becomes ₹1L
  /// - 10000000 becomes ₹1Cr
  // static String formatRupee(num amount) {
  //   if (amount >= 10000000) {
  //     // 1 Crore
  //     final crores = amount / 10000000;
  //     return '₹${crores.toStringAsFixed(crores.truncateToDouble() == crores ? 0 : 1)}Cr';
  //   } else if (amount >= 100000) {
  //     // 1 Lakh
  //     final lakhs = amount / 100000;
  //     return '₹${lakhs.toStringAsFixed(lakhs.truncateToDouble() == lakhs ? 0 : 1)}L';
  //   } else if (amount >= 1000) {
  //     // 1 Thousand (for 4 and 5 digit numbers)
  //     final thousands = amount / 1000;
  //     return '₹${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
  //   } else {
  //     final formatter = NumberFormat.currency(
  //       locale: 'en_IN',
  //       symbol: '₹',
  //       decimalDigits: 0,
  //     );
  //     return formatter.format(amount);
  //   }
  // }
  static String formatRupee(num amount) {
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();

    String formattedAmount;

    if (absoluteAmount >= 10000000) {
      // 1 Crore
      final crores = absoluteAmount / 10000000;
      final truncated =
          (crores * 10).floor() / 10; // Truncate to 1 decimal place
      final croString = truncated.toString();
      // Remove trailing .0 for display
      formattedAmount =
          croString.endsWith('.0')
              ? croString.substring(0, croString.length - 2)
              : croString;
      formattedAmount += 'Cr';
    } else if (absoluteAmount >= 100000) {
      // 1 Lakh
      final lakhs = absoluteAmount / 100000;
      final truncated =
          (lakhs * 10).floor() / 10; // Truncate to 1 decimal place
      final lakhString = truncated.toString();
      formattedAmount =
          lakhString.endsWith('.0')
              ? lakhString.substring(0, lakhString.length - 2)
              : lakhString;
      formattedAmount += 'L';
    } else if (absoluteAmount >= 1000) {
      // 1 Thousand (for 4 and 5 digit numbers)
      final thousands = absoluteAmount / 1000;
      final truncated =
          (thousands * 10).floor() / 10; // Truncate to 1 decimal place
      final thousandString = truncated.toString();
      formattedAmount =
          thousandString.endsWith('.0')
              ? thousandString.substring(0, thousandString.length - 2)
              : thousandString;
      formattedAmount += 'K';
    } else {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return formatter.format(
        amount,
      ); // Let NumberFormat handle negative numbers
    }
    final latest = CurrencyFormatter.formatRupeeWithCommas(amount);
    return isNegative ? '-$latest' : latest;
  }

  /// Formats a number as Indian Rupee with the ₹ symbol and 2 decimal places
  ///
  /// Example: 1000.50 becomes ₹1,000.50
  static String formatRupeeWithDecimals(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats a number as Indian Rupee with the ₹ symbol and custom decimal places
  /// Maintains all existing formatting logic with flexible decimal control
  ///
  /// Examples:
  /// - formatRupeeWithCustomDecimals(1000.123, 3) becomes ₹1,000.123
  /// - formatRupeeWithCustomDecimals(1000.50, 1) becomes ₹1,000.5
  /// - formatRupeeWithCustomDecimals(1000, 0) becomes ₹1,000
  static String formatRupeeWithCustomDecimals(num amount, int decimalPlaces) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  /// Formats a number with appropriate Indian suffixes (L, Cr)
  ///
  /// Examples:
  /// - 1000 becomes 1K
  /// - 100000 becomes 1L
  /// - 10000000 becomes 1Cr
  static String formatWithSuffix(num amount) {
    if (amount < 1000) {
      return amount.toStringAsFixed(0);
    } else if (amount < 100000) {
      // Convert to K (thousands) for both 4 and 5 digit numbers
      final value = amount / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    } else if (amount < 10000000) {
      // Convert to L (lakhs)
      final value = amount / 100000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}L';
    } else {
      // Convert to Cr (crores)
      final value = amount / 10000000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}Cr';
    }
  }

  /// Formats a number as Indian Rupee with the ₹ symbol and appropriate suffixes (K, L, Cr)
  ///
  /// Examples:
  /// - 1000 becomes ₹1K
  /// - 100000 becomes ₹1L
  /// - 10000000 becomes ₹1Cr
  static String formatRupeeWithSuffix(num amount) {
    return '₹${formatWithSuffix(amount)}';
  }

  /// Formats a number as Indian Rupee with the ₹ symbol and compact notation
  /// This is useful for displaying large numbers in a compact form
  ///
  /// Examples:
  /// - 1000 becomes ₹1K
  /// - 1500 becomes ₹1.5K
  /// - 1000000 becomes ₹1M
  static String formatCompact(num amount) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  /// Formats a number as Indian Rupee with the ₹ symbol and commas only
  /// Does not use any suffixes like K, L, or Cr
  ///
  /// Examples:
  /// - 1000 becomes ₹1,000
  /// - 100000 becomes ₹1,00,000
  /// - 10000000 becomes ₹1,00,00,000
  static String formatRupeeWithCommas(num amount, {int decimals = 0}) {
    final absoluteAmount = amount.abs();
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final formattedAmount = formatter.format(absoluteAmount);
    return formattedAmount;
  }

  /// Formats a number with Indian comma formatting but without currency symbol
  /// Examples:
  /// - 1000 becomes 1,000
  /// - 100000 becomes 1,00,000
  /// - 10000000 becomes 1,00,00,000
  static String formatNumberWithCommas(num amount, {int decimals = 2}) {
    final absoluteAmount = amount.abs();
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimals,
    );
    final formattedAmount = formatter.format(absoluteAmount).trim();
    return formattedAmount;
  }
}
