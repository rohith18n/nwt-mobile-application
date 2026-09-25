import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/logger.dart';

/// Helper class for remote config operations
class RemoteConfigHelper {
  /// Force refresh all remote config values immediately
  /// Call this when you need to get the latest values from Firebase
  static Future<void> forceRefreshAll() async {
    try {
      AppLogger.info('🔄 Force refreshing all remote config values...');
      
      // 1. Force refresh remote config service
      final updated = await RemoteConfigService.to.forceRefresh();
      
      // 2. Update API URLs with new base URL
      await ApiURLs.forceRefresh();
      
      AppLogger.info('✅ Force refresh completed. Updated: $updated');
      
      // Log current values for verification
      final remoteConfig = RemoteConfigService.to;
      AppLogger.info('📊 Current Remote Config Values:');
      AppLogger.info('   Base URL: ${remoteConfig.baseUrl.value}');
      AppLogger.info('   Android Version: ${remoteConfig.minimumAppVersion.value}');
      AppLogger.info('   iOS Version: ${remoteConfig.minimumIosVersion.value}');
      AppLogger.info('   Play Store URL: ${remoteConfig.playStoreUrl.value}');
      AppLogger.info('   App Store URL: ${remoteConfig.appStoreUrl.value}');
      
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error force refreshing remote config: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Quick method to check if remote config values are up to date
  static void logCurrentValues() {
    final remoteConfig = RemoteConfigService.to;
    AppLogger.info('📊 Current Remote Config Values:');
    AppLogger.info('   Base URL: ${remoteConfig.baseUrl.value}');
    AppLogger.info('   Android Version: ${remoteConfig.minimumAppVersion.value}');
    AppLogger.info('   iOS Version: ${remoteConfig.minimumIosVersion.value}');
    AppLogger.info('   API Base URL: ${ApiURLs.baseUrl}');
  }
}
