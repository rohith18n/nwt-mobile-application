import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/services/network/connectivity_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';

/// Custom exception class for network errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  final NetworkErrorType errorType;

  NetworkException({
    required this.message,
    this.statusCode,
    this.body,
    required this.errorType,
  });

  @override
  String toString() =>
      'NetworkException: $message (Status: $statusCode, Type: $errorType)';
}

/// Types of network errors that can occur
enum NetworkErrorType {
  noInternet,
  timeout,
  serverError,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  unknown,
}

/// HTTP client with network interceptor functionality.
///
/// Accepts an optional [refreshUrl] which is the endpoint for token refresh
/// (e.g. `https://api.example.com/api/v1/auth/refresh/`). When provided,
/// a 401 response triggers an automatic token refresh + one retry.
/// This avoids circular imports with AuthService / NetworkAPIHelper.
class NetworkInterceptor {
  final ConnectivityService _connectivityService = ConnectivityService.to;
  final Duration _timeout;
  final String? refreshUrl;

  NetworkInterceptor({Duration? timeout, this.refreshUrl})
    : _timeout = timeout ?? const Duration(seconds: 30);

  /// Perform a GET request with network interceptor
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _executeRequest(
      () => http.get(Uri.parse(url), headers: headers),
      headers: headers,
    );
  }

  /// Perform a POST request with network interceptor
  Future<http.Response> post(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _executeRequest(
      () => http.post(
        Uri.parse(url),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      ),
      headers: headers,
    );
  }

  /// Perform a PUT request with network interceptor
  Future<http.Response> put(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _executeRequest(
      () => http.put(
        Uri.parse(url),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      ),
      headers: headers,
    );
  }

  /// Perform a DELETE request with network interceptor
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return _executeRequest(
      () => http.delete(
        Uri.parse(url),
        headers: headers,
        body: body != null ? (body is String ? body : jsonEncode(body)) : null,
      ),
      headers: headers,
    );
  }

  /// Perform a PATCH request with network interceptor
  Future<http.Response> patch(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _executeRequest(
      () => http.patch(
        Uri.parse(url),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      ),
      headers: headers,
    );
  }

  /// Execute the HTTP request with error handling and connectivity check
  Future<http.Response> _executeRequest(
    Future<http.Response> Function() requestFunction, {
    Map<String, String>? headers,
  }) async {
    // Check network connectivity before making the request
    if (!_connectivityService.isConnected) {
      AppLogger.error('No internet connection', tag: 'NetworkInterceptor');
      throw NetworkException(
        message: 'No internet connection. Please check your network settings.',
        errorType: NetworkErrorType.noInternet,
      );
    }

    try {
      // Execute the request with timeout
      var response = await requestFunction().timeout(_timeout);

      // Handle token expiration (401 Unauthorized) — only if we have an auth header
      // and a refresh URL was provided (i.e., we are NOT already calling the refresh endpoint).
      if (response.statusCode == 401 &&
          headers != null &&
          headers.containsKey('Authorization') &&
          refreshUrl != null) {
        AppLogger.warning(
          'Token expired (401) for ${response.request?.url ?? "unknown URL"}, attempting refresh',
          tag: 'NetworkInterceptor',
        );

        try {
          // Check if we are already refreshing to avoid loops
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            AppLogger.info(
              'Token refreshed successfully, retrying request',
              tag: 'NetworkInterceptor',
            );
            final newToken =
                await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
            if (newToken != null) {
              // Update the original headers map which is used by requestFunction
              headers['Authorization'] = 'Bearer $newToken';
              
              // Re-execute the original request function (GET, POST, etc.)
              response = await requestFunction().timeout(_timeout);
              
              if (response.statusCode == 401) {
                AppLogger.error(
                  'Retried request still failed with 401 after refresh for ${response.request?.url}',
                  tag: 'NetworkInterceptor',
                );
              }
            }
          } else {
            AppLogger.error(
              '❌ Token refresh FAILED — Original request: ${response.request?.url}',
              tag: 'AuthFlowService',
            );
            AppLogger.error(
              '❌ Removing tokens and redirecting to login',
              tag: 'AuthFlowService',
            );
            await SecureStorage.remove(StorageKeys.AUTH_TOKEN_KEY);
            await SecureStorage.remove(StorageKeys.REFRESH_TOKEN_KEY);
            Get.offAll(() => const OnboardingScreen());
          }
        } catch (e) {
          AppLogger.error(
            'Error during token refresh: $e',
            tag: 'NetworkInterceptor',
          );
        }
      }

      return response;
    } on TimeoutException {
      AppLogger.error('Request timeout', tag: 'NetworkInterceptor');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        errorType: NetworkErrorType.timeout,
      );
    } on SocketException catch (e) {
      AppLogger.error(
        'Socket exception: ${e.message}',
        tag: 'NetworkInterceptor',
      );
      throw NetworkException(
        message:
            'Network connection error. Please check your internet connection.',
        errorType: NetworkErrorType.noInternet,
      );
    } on NetworkException {
      rethrow; // Re-throw already formatted network exceptions
    } catch (e) {
      AppLogger.error('Unknown error: $e', tag: 'NetworkInterceptor');
      throw NetworkException(
        message: 'An unexpected error occurred. Please try again.',
        errorType: NetworkErrorType.unknown,
      );
    }
  }

  /// Directly calls POST [refreshUrl] with the stored refresh token.
  /// Uses plain http.post to avoid circular dependency with AuthService/NetworkAPIHelper.
  Future<bool> _attemptTokenRefresh() async {
    if (refreshUrl == null) return false;
    try {
      final refreshToken =
          await SecureStorage.read(StorageKeys.REFRESH_TOKEN_KEY);
      if (refreshToken == null) {
        AppLogger.warning('No refresh token stored', tag: 'NetworkInterceptor');
        return false;
      }

      // We support both 'refresh' and 'refresh_token' keys as some backends vary
      final response = await http
          .post(
            Uri.parse(refreshUrl!),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refresh': refreshToken,
              'refresh_token': refreshToken,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        // Robust parsing: check for 'data.access' (V1 wrapped) or 'access' (standard JWT)
        String? newAccessToken;
        String? newRefreshToken;

        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          newAccessToken = data['access'] as String?;
          newRefreshToken = data['refresh'] as String? ?? data['refresh_token'] as String?;
        }

        // Fallback to flat structure (Standard SimpleJWT)
        newAccessToken ??= body['access'] as String? ?? body['access_token'] as String?;
        newRefreshToken ??= body['refresh'] as String? ?? body['refresh_token'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await SecureStorage.write(StorageKeys.AUTH_TOKEN_KEY, newAccessToken);
          // Also update refresh token if a new one was provided (rotation)
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await SecureStorage.write(
              StorageKeys.REFRESH_TOKEN_KEY,
              newRefreshToken,
            );
          }
          AppLogger.info(
            'Access token refreshed successfully via interceptor',
            tag: 'NetworkInterceptor',
          );
          return true;
        } else {
          AppLogger.error(
            'Token refresh call returned 200 but no access token found in body: ${response.body}',
            tag: 'NetworkInterceptor',
          );
        }
      } else {
        AppLogger.warning(
          'Refresh endpoint returned ${response.statusCode}: ${response.body}',
          tag: 'NetworkInterceptor',
        );
      }
      return false;
    } catch (e) {
      AppLogger.error(
        '_attemptTokenRefresh failed: $e',
        tag: 'NetworkInterceptor',
      );
      return false;
    }
  }
}
