import 'package:http/http.dart' as http;

/// Common response handler utility for API services
class ResponseHandler {
  /// Handles API response with flexible status code detection
  ///
  /// Tries to get status code from response body first, then falls back to HTTP status.
  /// Also handles message extraction and data parsing safely.
  ///
  /// [response] - The HTTP response object
  /// [jsonData] - Parsed JSON data from response body
  /// [fallbackMessage] - Default message if no message found in response
  /// [dataParser] - Optional function to parse data field
  ///
  /// Returns a response object of type T with proper status code and message
  static T handleResponse<T>(
    http.Response response,
    Map<String, dynamic> jsonData, {
    String? fallbackMessage,
    T Function(Map<String, dynamic>)? responseFactory,
    T Function(int statusCode, String message, dynamic data)? fallbackFactory,
  }) {
    // Try to get status code from response body first, then fall back to HTTP status
    final statusCode = jsonData['statusCode'] ??
        jsonData['status_code'] ??
        response.statusCode;
    // Extract message and handle structured "Validation Error"
    var message = jsonData['message'] ??
        jsonData['error'] ??
        jsonData['detail'] ??
        jsonData['error_description'] ??
        fallbackMessage ??
        'Request completed';

    // If error field contains detail, prioritize it if message is generic
    if ((message.toLowerCase().contains('validation') ||
            message.toLowerCase().contains('bad request') ||
            message.toLowerCase().contains('failure')) &&
        jsonData['error'] != null &&
        jsonData['error'].toString().length > message.length) {
      message = jsonData['error'];
    }

    // If it's a validation error with details, extract the first one
    // Some backends use 'detail', others use 'details' (plural)
    final details = jsonData['details'] ?? jsonData['detail'];
    if (message.toLowerCase().contains('validation error') &&
        details is List &&
        details.isNotEmpty) {
      final firstDetail = details.first;
      if (firstDetail is Map<String, dynamic>) {
        if (firstDetail.containsKey('msg')) {
          var detailMsg = firstDetail['msg'];
          // Prepend field name from 'loc' if available to help translator
          if (firstDetail.containsKey('loc') &&
              firstDetail['loc'] is List &&
              (firstDetail['loc'] as List).isNotEmpty) {
            final fieldName = (firstDetail['loc'] as List).last.toString();
            detailMsg = '$fieldName: $detailMsg';
          }
          message = detailMsg;
        }
      }
    }

    final data = jsonData['data'];

    // Use responseFactory ONLY for successful status codes
    if (isSuccessStatus(statusCode) && responseFactory != null) {
      try {
        return responseFactory(jsonData);
      } catch (e) {
        // If factory fails, use fallback factory
        if (fallbackFactory != null) {
          return fallbackFactory(statusCode, message, null);
        }
        rethrow;
      }
    }

    // For non-success status codes, ALWAYS use fallback factory if available
    if (fallbackFactory != null) {
      return fallbackFactory(statusCode, message, data);
    }

    throw ArgumentError(
      'Either responseFactory or fallbackFactory must be provided',
    );
  }

  /// Creates a fallback response for error cases
  ///
  /// [statusCode] - HTTP status code
  /// [message] - Error message
  /// [data] - Optional data (usually null for errors)
  /// [responseFactory] - Factory function to create response object
  ///
  /// Returns a response object of type T
  static T createFallbackResponse<T>({
    required int statusCode,
    required String message,
    dynamic data,
    required T Function(int statusCode, String message, dynamic data)
    responseFactory,
  }) {
    return responseFactory(statusCode, message, data);
  }

  /// Safely parses JSON response with error handling
  ///
  /// [response] - HTTP response to parse
  ///
  /// Returns parsed JSON data or null if parsing fails
  static Map<String, dynamic>? safeParseJson(http.Response response) {
    try {
      return response.body.isNotEmpty
          ? Map<String, dynamic>.from(
            // Using dart:convert's json decode
            // Note: You'll need to import 'dart:convert' in the calling file
            // This is a placeholder - actual implementation should use json.decode()
            <String, dynamic>{},
          )
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if response indicates success
  ///
  /// [statusCode] - HTTP status code to check
  ///
  /// Returns true if status code indicates success (2xx range)
  static bool isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Extracts error message from response body or uses default
  ///
  /// [jsonData] - Parsed JSON response
  /// [defaultMessage] - Default error message
  ///
  /// Returns error message string
  static String extractErrorMessage(
    Map<String, dynamic> jsonData,
    String defaultMessage,
  ) {
    return jsonData['message'] ??
        jsonData['error'] ??
        jsonData['error_description'] ??
        defaultMessage;
  }
}
