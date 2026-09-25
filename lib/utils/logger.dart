import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A utility class for logging messages only in development mode.
/// 
/// This logger ensures that sensitive information is not logged in production builds,
/// while providing detailed logs during development.
class AppLogger {
  /// Log an informational message.
  /// 
  /// Only logs in debug mode, not in release or profile modes.
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'INFO');
    }
  }

  /// Log an error message with optional error object and stack trace.
  /// 
  /// Only logs in debug mode, not in release or profile modes.
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? 'ERROR',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log a warning message.
  /// 
  /// Only logs in debug mode, not in release or profile modes.
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'WARNING');
    }
  }

  /// Log a debug message.
  /// 
  /// Only logs in debug mode, not in release or profile modes.
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'DEBUG');
    }
  }
}
