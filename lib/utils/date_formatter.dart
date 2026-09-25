import 'package:intl/intl.dart';

/// A utility class for formatting dates in various formats throughout the application.
class DateFormatter {
  /// The offset for Indian Standard Time (IST) from UTC in hours
  static const int _istOffsetHours = 5;

  /// The offset for Indian Standard Time (IST) from UTC in minutes
  static const int _istOffsetMinutes = 30;

  /// Converts a DateTime to Indian Standard Time (IST)
  static DateTime toIST(DateTime dateTime) {
    // If the date is already in local timezone with the correct offset, return it
    if (dateTime.isUtc) {
      return dateTime.toLocal();
    }

    // Otherwise, ensure we're working with the correct IST offset
    final offset = Duration(hours: _istOffsetHours, minutes: _istOffsetMinutes);
    return DateTime.fromMillisecondsSinceEpoch(
      dateTime.millisecondsSinceEpoch,
      isUtc: false,
    ).add(offset - dateTime.timeZoneOffset);
  }

  /// Formats a date to a string in the format 'MMM dd, yyyy' (e.g., "Jun 25, 2025")
  static String formatToReadableDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(toIST(date));
  }

  /// Formats a date to a string in the format 'yyyy-MM-dd' (e.g., "2025-06-25")
  static String formatToApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(toIST(date));
  }

  /// Formats a date to a string in the format 'dd/MM/yyyy' (e.g., "25/06/2025")
  static String formatToDayMonthYear(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(toIST(date));
  }

  /// Formats a date to a string in the format 'MMMM yyyy' (e.g., "June 2025")
  static String formatToMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(toIST(date));
  }

  /// Formats a date to a string in the format 'dd MMM' (e.g., "25 Jun")
  static String formatToDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(toIST(date));
  }

  /// Formats a date to a string in the format 'HH:mm' (e.g., "14:30")
  static String formatToTime(DateTime date) {
    return DateFormat('HH:mm').format(toIST(date));
  }

  /// Formats a date to a string in the format 'dd MMM yyyy, HH:mm' (e.g., "25 Jun 2025, 14:30")
  static String formatToDateTimeString(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(toIST(date));
  }

  /// Formats a date to a string in the format 'dd MMM yyyy, hh:mm a' (e.g., "25 Jun 2025, 02:30 PM")
  static String formatToDateTimeWithAmPm(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(toIST(date));
  }

  /// Formats a date to a relative time string (e.g., "2 days ago", "just now", "in 3 hours")
  static String formatToRelativeTime(DateTime date) {
    final now = DateTime.now();
    date = toIST(date);
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} ${difference.inSeconds == 1 ? 'second' : 'seconds'} ago';
    } else if (difference.inSeconds < 0) {
      // Future date
      final futureDifference = date.difference(now);
      if (futureDifference.inDays > 0) {
        return 'in ${futureDifference.inDays} ${futureDifference.inDays == 1 ? 'day' : 'days'}';
      } else if (futureDifference.inHours > 0) {
        return 'in ${futureDifference.inHours} ${futureDifference.inHours == 1 ? 'hour' : 'hours'}';
      } else if (futureDifference.inMinutes > 0) {
        return 'in ${futureDifference.inMinutes} ${futureDifference.inMinutes == 1 ? 'minute' : 'minutes'}';
      } else {
        return 'in ${futureDifference.inSeconds} ${futureDifference.inSeconds == 1 ? 'second' : 'seconds'}';
      }
    } else {
      return 'just now';
    }
  }

  /// Parses a string date in the format 'yyyy-MM-dd' to a DateTime object in IST
  static DateTime parseApiDate(String dateString) {
    return toIST(DateFormat('yyyy-MM-dd').parse(dateString));
  }

  /// Parses a string date in the format 'yyyy-MM-ddTHH:mm:ss' to a DateTime object in IST
  static DateTime parseApiDateTime(String dateTimeString) {
    return toIST(DateTime.parse(dateTimeString));
  }

  /// Returns the first day of the month for a given date
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the last day of the month for a given date
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Returns the first day of the week (Monday) for a given date
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Returns the last day of the week (Sunday) for a given date
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
}
