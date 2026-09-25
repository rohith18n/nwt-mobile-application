import 'dart:async';

import 'package:get_storage/get_storage.dart';
import 'package:nwt_app/utils/logger.dart';

class StorageService {
  static final GetStorage _box = GetStorage();
  static bool _isInitialized = false;

  // No masking of values in logs as per requirement

  /// Initialize the storage service with retry mechanism
  static Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // Try to initialize GetStorage with a timeout
      await GetStorage.init().timeout(const Duration(seconds: 5));
      _isInitialized = true;
      AppLogger.info(
        'OPERATION: INIT | STATUS: SUCCESS | MESSAGE: Storage service initialized',
        tag: 'STORAGE',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'OPERATION: INIT | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );

      // Try one more time with a delay
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await GetStorage.init().timeout(const Duration(seconds: 5));
        _isInitialized = true;
        AppLogger.info(
          'OPERATION: INIT | STATUS: SUCCESS | MESSAGE: Storage service initialized on retry',
          tag: 'STORAGE',
        );
        return true;
      } catch (e) {
        AppLogger.error(
          'OPERATION: INIT | STATUS: FAILED | MESSAGE: Failed on retry | ERROR: $e',
          tag: 'STORAGE',
        );
        return false;
      }
    }
  }

  /// Write a value to storage with error handling
  static void write(String key, dynamic value) {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to write to storage before initialization',
        tag: 'STORAGE',
      );
      return;
    }

    try {
      _box.write(key, value);
      AppLogger.info(
        'OPERATION: WRITE | KEY: $key | VALUE: $value',
        tag: 'STORAGE',
      );
    } catch (e) {
      AppLogger.error(
        'OPERATION: WRITE | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );
    }
  }

  /// Read a value from storage with error handling
  static dynamic read(String key) {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to read from storage before initialization',
        tag: 'STORAGE',
      );
      return null;
    }

    try {
      final value = _box.read(key);
      AppLogger.info(
        'OPERATION: READ | KEY: $key | VALUE: $value',
        tag: 'STORAGE',
      );
      return value;
    } catch (e) {
      AppLogger.error(
        'OPERATION: READ | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );
      return null;
    }
  }

  /// Remove a value from storage with error handling
  static void remove(String key) {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to remove from storage before initialization',
        tag: 'STORAGE',
      );
      return;
    }

    try {
      _box.remove(key);
      AppLogger.info(
        'OPERATION: REMOVE | KEY: $key | STATUS: SUCCESS',
        tag: 'STORAGE',
      );
    } catch (e) {
      AppLogger.error(
        'OPERATION: REMOVE | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );
    }
  }

  /// Clear all storage with error handling
  static void clear() {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to clear storage before initialization',
        tag: 'STORAGE',
      );
      return;
    }

    try {
      // Get all keys before clearing to log them
      final keys = _box.getKeys();
      final keyCount = keys.length;
      final keyList = keys.join(', ');

      AppLogger.info(
        'OPERATION: CLEAR_ALL | KEYS_TO_CLEAR: $keyCount | KEY_LIST: $keyList',
        tag: 'STORAGE',
      );

      // Perform the actual deletion
      _box.erase();
      AppLogger.info(
        'OPERATION: CLEAR_ALL | STATUS: SUCCESS | MESSAGE: All storage cleared',
        tag: 'STORAGE',
      );
    } catch (e) {
      AppLogger.error(
        'OPERATION: CLEAR_ALL | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );
    }
  }

  /// Check if a key exists in storage with error handling
  static bool hasKey(String key) {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to check key in storage before initialization',
        tag: 'STORAGE',
      );
      return false;
    }

    try {
      final exists = _box.hasData(key);
      AppLogger.info(
        'OPERATION: HAS_KEY | KEY: $key | EXISTS: $exists',
        tag: 'STORAGE',
      );
      return exists;
    } catch (e) {
      AppLogger.error(
        'OPERATION: HAS_KEY | KEY: $key | STATUS: FAILED | ERROR: $e',
        tag: 'STORAGE',
      );
      return false;
    }
  }
}
