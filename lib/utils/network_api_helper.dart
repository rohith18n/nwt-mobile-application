import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/network/connectivity_service.dart';
import 'package:nwt_app/services/network/network_interceptor.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class NetworkAPIHelper {
  final NetworkInterceptor _interceptor = NetworkInterceptor(
    timeout: const Duration(seconds: 30),
    refreshUrl: ApiURLs.AUTH_REFRESH,
  );

  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
      AppLogger.info(
        'Getting headers - RequiresAuth: $requiresAuth, Token exists: ${token != null}, Token length: ${token?.length ?? 0}',
        tag: 'AuthFlowService',
      );

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        AppLogger.info(
          'Authorization header added to request',
          tag: 'AuthFlowService',
        );
      } else {
        AppLogger.warning(
          '⚠️ Token is NULL - Authorization header NOT added even though requiresAuth=true',
          tag: 'AuthFlowService',
        );
      }
    }

    return headers;
  }

  Future<String?> getAuthToken() async {
    return await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
  }

  Future<http.Response?> get(
    String url, {
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        _handleNoConnectivity();
        return null;
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }
      AppLogger.info('🚀 GET Request: $url', tag: 'NETWORK');
      final response = await _interceptor.get(url, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info(
          '✅ GET Response [$url]: ${response.statusCode}\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      } else {
        final hasAuth = headers.containsKey('Authorization');
        AppLogger.error(
          '❌ GET Response [$url]: ${response.statusCode} (Has Auth: $hasAuth)\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      }
      return response;
    } on NetworkException catch (e, stackTrace) {
      _handleNetworkException(e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('GET Request Error: $e', tag: 'NetworkAPIHelper');
      return null;
    }
  }

  Future<http.Response?> post(
    String url,
    dynamic body, {
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        _handleNoConnectivity();
        return null;
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      AppLogger.info('🚀 POST Request: $url', tag: 'NETWORK');
      AppLogger.info('📦 POST Body: $body', tag: 'NETWORK');

      // Log headers for PAN verification requests
      if (url.contains('pan_verify')) {
        AppLogger.info(
          '🔑 Headers for PAN Verify: $headers',
          tag: 'AuthFlowService',
        );
        AppLogger.info(
          '🔐 Has Authorization: ${headers.containsKey('Authorization')}, RequiresAuth: $requiresAuth',
          tag: 'AuthFlowService',
        );
      }

      // Log headers for MF Central requests
      if (url.contains('mfcentral')) {
        AppLogger.info(
          '🔑 MF Central Request Headers: $headers',
          tag: 'MF_Central',
        );
        AppLogger.info(
          '🔐 MF Central Has Authorization: ${headers.containsKey('Authorization')}, RequiresAuth: $requiresAuth',
          tag: 'MF_Central',
        );
        AppLogger.info('📦 MF Central Request Body: $body', tag: 'MF_Central');
      }

      final response = await _interceptor.post(url, body, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info(
          '✅ POST Response [$url]: ${response.statusCode}\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      } else {
        final hasAuth = headers.containsKey('Authorization');
        AppLogger.error(
          '❌ POST Response [$url]: ${response.statusCode} (Has Auth: $hasAuth)\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      }
      return response;
    } on NetworkException catch (e, stackTrace) {
      _handleNetworkException(e, stackTrace);
      return null;
    } catch (e) {
      AppLogger.error('POST Request Error: $e', tag: 'NetworkAPIHelper');
      return null;
    }
  }

  Future<http.Response?> put(
    String url,
    dynamic body, {
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        _handleNoConnectivity();
        return null;
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      AppLogger.info('🚀 PUT Request: $url', tag: 'NETWORK');
      AppLogger.info('📦 PUT Body: $body', tag: 'NETWORK');
      final response = await _interceptor.put(url, body, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info(
          '✅ PUT Response [$url]: ${response.statusCode}\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      } else {
        final hasAuth = headers.containsKey('Authorization');
        AppLogger.error(
          '❌ PUT Response [$url]: ${response.statusCode} (Has Auth: $hasAuth)\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      }
      return response;
    } on NetworkException catch (e, stackTrace) {
      _handleNetworkException(e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('PUT Request Error: $e', tag: 'NetworkAPIHelper');
      return null;
    }
  }

  Future<http.Response?> patch(
    String url,
    dynamic body, {
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        _handleNoConnectivity();
        return null;
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      AppLogger.info('🚀 PATCH Request: $url', tag: 'NETWORK');
      AppLogger.info('📦 PATCH Body: $body', tag: 'NETWORK');

      final response = await _interceptor.patch(url, body, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info(
          '✅ PATCH Response [$url]: ${response.statusCode}\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      } else {
        final hasAuth = headers.containsKey('Authorization');
        AppLogger.error(
          '❌ PATCH Response [$url]: ${response.statusCode} (Has Auth: $hasAuth)\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      }
      return response;
    } on NetworkException catch (e, stackTrace) {
      _handleNetworkException(e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('PATCH Request Error: $e', tag: 'NetworkAPIHelper');
      return null;
    }
  }

  Future<http.Response?> delete(
    String url, {
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
    dynamic body,
  }) async {
    try {
      if (!_connectivityService.isConnected) {
        _handleNoConnectivity();
        return null;
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      AppLogger.info('🚀 DELETE Request: $url', tag: 'NETWORK');
      if (body != null) {
        AppLogger.info('📦 DELETE Body: $body', tag: 'NETWORK');
      }
      final response = await _interceptor.delete(
        url,
        headers: headers,
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info(
          '✅ DELETE Response [$url]: ${response.statusCode}\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      } else {
        final hasAuth = headers.containsKey('Authorization');
        AppLogger.error(
          '❌ DELETE Response [$url]: ${response.statusCode} (Has Auth: $hasAuth)\nBody: ${response.body}',
          tag: 'NETWORK',
        );
      }
      return response;
    } on NetworkException catch (e, subTrace) {
      _handleNetworkException(e, subTrace);
      return null;
    } catch (e) {
      AppLogger.error('DELETE Request Error: $e', tag: 'NetworkAPIHelper');
      return null;
    }
  }

  void _handleNetworkException(
    NetworkException exception,
    StackTrace? stackTrace,
  ) {
    AppLogger.error(
      'Network Exception: ${exception.message}',
      tag: 'NetworkAPIHelper',
      error: exception,
      stackTrace: stackTrace,
    );

    switch (exception.errorType) {
      case NetworkErrorType.noInternet:
        break;
      case NetworkErrorType.timeout:
        break;
      case NetworkErrorType.unauthorized:
        break;
      case NetworkErrorType.serverError:
        break;
      default:
    }
  }

  void _handleNoConnectivity() {
    AppLogger.warning('No internet connection', tag: 'NetworkAPIHelper');

    Get.snackbar(
      'No Internet Connection',
      'Please check your network settings and try again.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.8),
      colorText: Get.theme.colorScheme.onError,
      mainButton: TextButton(
        onPressed: () async {
          await _connectivityService.checkConnectivity();
        },
        child: const AppText(
          'Retry',
          variant: AppTextVariant.bodySmall,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        ),
      ),
    );
  }
}
