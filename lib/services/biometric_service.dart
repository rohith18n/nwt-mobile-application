import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService _instance = BiometricService._();
  static BiometricService get to => _instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GetStorage _storage = GetStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';

  bool get isBiometricEnabled => _storage.read(_biometricEnabledKey) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(_biometricEnabledKey, enabled);
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      if (!isBiometricEnabled) {
        return false;
      }

      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = await _localAuth.isDeviceSupported();

      return canAuthenticateWithBiometrics && canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> authenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return true;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return true;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.message?.contains('dlopen') == true) {
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
