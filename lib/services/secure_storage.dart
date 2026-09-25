import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/utils/logger.dart';

/// A service for securely storing sensitive data like tokens and credentials
/// Uses flutter_secure_storage which leverages platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
/// - macOS: Keychain
/// - Windows: Windows Data Protection API
/// - Linux: libsecret
/// - Web: localStorage with AES encryption
class SecureStorage {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static bool _isInitialized = false;
  
  // No masking of values in logs as per requirement

  /// Initialize the secure storage service
  static Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // Test storage by writing and reading a test value
      await _secureStorage
          .write(key: '_test_key', value: 'test_value')
          .timeout(const Duration(seconds: 5));
      await _secureStorage
          .read(key: '_test_key')
          .timeout(const Duration(seconds: 5));
      await _secureStorage
          .delete(key: '_test_key')
          .timeout(const Duration(seconds: 5));

      _isInitialized = true;
      AppLogger.info(
        'OPERATION: INIT | STATUS: SUCCESS | MESSAGE: Secure storage initialized',
        tag: 'SECURE_STORAGE',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'OPERATION: INIT | STATUS: FAILED | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );

      // Try one more time with a delay
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _secureStorage
            .write(key: '_test_key', value: 'test_value')
            .timeout(const Duration(seconds: 5));
        await _secureStorage
            .read(key: '_test_key')
            .timeout(const Duration(seconds: 5));
        await _secureStorage
            .delete(key: '_test_key')
            .timeout(const Duration(seconds: 5));

        _isInitialized = true;
        AppLogger.info(
          'OPERATION: INIT | STATUS: SUCCESS | MESSAGE: Secure storage initialized on retry',
          tag: 'SECURE_STORAGE',
        );
        return true;
      } catch (e) {
        AppLogger.error(
          'OPERATION: INIT | STATUS: FAILED | MESSAGE: Failed on retry | ERROR: $e',
          tag: 'SECURE_STORAGE',
        );
        return false;
      }
    }
  }

  /// Write a value to secure storage with error handling
  static Future<void> write(String key, String? value) async {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to write to secure storage before initialization',
        tag: 'SECURE_STORAGE',
      );
      await init();
    }

    try {
      if (value == null) {
        await _secureStorage.delete(key: key);
        AppLogger.info(
          'OPERATION: DELETE | KEY: $key | VALUE: null',
          tag: 'SECURE_STORAGE',
        );
      } else {
        await _secureStorage.write(key: key, value: value);
        AppLogger.info(
          'OPERATION: WRITE | KEY: $key | VALUE: $value',
          tag: 'SECURE_STORAGE',
        );
      }
    } catch (e) {
      AppLogger.error(
        'OPERATION: WRITE | KEY: $key | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );
      rethrow;
    }
  }

  /// Read a value from secure storage with error handling
  static Future<String?> read(String key) async {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to read from secure storage before initialization',
        tag: 'SECURE_STORAGE',
      );
      await init();
    }

    try {
      final value = await _secureStorage.read(key: key);
      AppLogger.info(
        'OPERATION: READ | KEY: $key | VALUE: $value',
        tag: 'SECURE_STORAGE',
      );
      return value;
    } catch (e) {
      AppLogger.error(
        'OPERATION: READ | KEY: $key | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );
      return null;
    }
  }

  /// Remove a value from secure storage with error handling
  static Future<void> remove(String key) async {
    // Log if auth token is being removed
    if (key == StorageKeys.AUTH_TOKEN_KEY) {
      AppLogger.warning(
        '🗑️ AUTH TOKEN BEING REMOVED FROM SECURE STORAGE!',
        tag: 'AuthFlowService',
      );
      AppLogger.info(
        'Stack trace: ${StackTrace.current}',
        tag: 'AuthFlowService',
      );
    }
    
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to remove from secure storage before initialization',
        tag: 'SECURE_STORAGE',
      );
      await init();
    }

    try {
      await _secureStorage.delete(key: key);
      AppLogger.info(
        'OPERATION: REMOVE | KEY: $key | STATUS: SUCCESS',
        tag: 'SECURE_STORAGE',
      );
    } catch (e) {
      AppLogger.error(
        'OPERATION: REMOVE | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );
      rethrow;
    }
  }

  /// Check if a key exists in secure storage
  static Future<bool> hasKey(String key) async {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to check key in secure storage before initialization',
        tag: 'SECURE_STORAGE',
      );
      await init();
    }

    try {
      final value = await _secureStorage.read(key: key);
      final exists = value != null;
      AppLogger.info(
        'OPERATION: HAS_KEY | KEY: $key | EXISTS: $exists',
        tag: 'SECURE_STORAGE',
      );
      return exists;
    } catch (e) {
      AppLogger.error(
        'OPERATION: HAS_KEY | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );
      return false;
    }
  }

  /// Clear all values from secure storage
  static Future<void> clearAll() async {
    AppLogger.warning(
      '🗑️ CLEARALL CALLED - ALL TOKENS BEING CLEARED FROM SECURE STORAGE!',
      tag: 'AuthFlowService',
    );
    AppLogger.info(
      'Stack trace: ${StackTrace.current}',
      tag: 'AuthFlowService',
    );
    
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to clear secure storage before initialization',
        tag: 'SECURE_STORAGE',
      );
      await init();
    }

    try {
      // Get all keys before clearing to log them
      Map<String, String> allValues = {};
      try {
        allValues = await _secureStorage.readAll();
        final keyCount = allValues.length;
        final keyList = allValues.keys.join(', ');
        AppLogger.info(
          'OPERATION: CLEAR_ALL | KEYS_TO_CLEAR: $keyCount | KEY_LIST: $keyList',
          tag: 'SECURE_STORAGE',
        );
      } catch (e) {
        AppLogger.warning(
          'OPERATION: CLEAR_ALL | Could not read keys before clearing: $e',
          tag: 'SECURE_STORAGE',
        );
      }
      
      // Perform the actual deletion
      await _secureStorage.deleteAll();
      AppLogger.info(
        'OPERATION: CLEAR_ALL | STATUS: SUCCESS | MESSAGE: All secure storage cleared',
        tag: 'SECURE_STORAGE',
      );
    } catch (e) {
      AppLogger.error(
        'OPERATION: CLEAR_ALL | STATUS: FAILED | ERROR: $e',
        tag: 'SECURE_STORAGE',
      );
      rethrow;
    }
  }
}
