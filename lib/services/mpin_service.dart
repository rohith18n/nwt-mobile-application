import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/profile/verify_pin.dart';
import 'package:nwt_app/services/secure_storage.dart';

class MPINService extends GetxService {
  static MPINService get to => Get.find<MPINService>();
  
  // Observable to track if PIN is being verified
  final _isVerifying = false.obs;
  bool get isVerifying => _isVerifying.value;

  // Initialize the service
  Future<MPINService> init() async {
    return this;
  }

  // Create a new PIN
  Future<bool> createPIN(String pin) async {
    try {
      await SecureStorage.write(StorageKeys.PIN_KEY, pin);
      await SecureStorage.write(StorageKeys.IS_PIN_SET_KEY, 'true');
      return true;
    } catch (e) {
      debugPrint('Error creating PIN: $e');
      return false;
    }
  }

  // Read the stored PIN
  Future<String?> readPIN() async {
    try {
      return await SecureStorage.read(StorageKeys.PIN_KEY);
    } catch (e) {
      debugPrint('Error reading PIN: $e');
      return null;
    }
  }

  // Check if PIN is set
  Future<bool> hasPIN() async {
    try {
      return await SecureStorage.read(StorageKeys.IS_PIN_SET_KEY) == 'true';
    } catch (e) {
      debugPrint('Error checking PIN status: $e');
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPIN(String enteredPin) async {
    try {
      final storedPin = await readPIN();
      return storedPin == enteredPin;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  // Delete PIN
  Future<bool> deletePIN() async {
    try {
      await SecureStorage.write(StorageKeys.PIN_KEY, null);
      await SecureStorage.write(StorageKeys.IS_PIN_SET_KEY, null);
      return true;
    } catch (e) {
      debugPrint('Error deleting PIN: $e');
      return false;
    }
  }

  // Show PIN verification dialog
  Future<bool> showVerification() async {
    if (_isVerifying.value) {
      return false;
    }

    try {
      _isVerifying.value = true;
      
      // Check if PIN verification is required
      final hasPinSet = await hasPIN();
      final hasToken = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY) != null;

      if (!hasPinSet || !hasToken) {
        return true;
      }

      // Show PIN verification dialog
      final verified = await Get.dialog<bool>(
        const VerifyPin(),
        barrierDismissible: false,
      );

      return verified ?? false;
    } catch (e) {
      debugPrint('Error in PIN verification: $e');
      return false;
    } finally {
      _isVerifying.value = false;
    }
  }
}
