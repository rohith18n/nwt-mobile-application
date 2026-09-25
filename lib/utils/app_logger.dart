import 'package:flutter/foundation.dart';

/// A simple logger utility for the app
class AppLogger {
  /// Log an info message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('APP_LOGGER_ℹ️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log an error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('APP_LOGGER_❌ ${tag != null ? '[$tag] ' : ''}$message');
      if (error != null) {
        print('APP_LOGGER_Error: $error');
      }
      if (stackTrace != null) {
        print('APP_LOGGER_Stack trace: $stackTrace');
      }
    }
  }

  /// Log a warning message
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('APP_LOGGER_⚠️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log a success message
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      print('APP_LOGGER_✅ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }
}
