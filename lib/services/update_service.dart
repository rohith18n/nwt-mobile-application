import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import '../constants/colors.dart';
import '../utils/app_logger.dart';
import 'remote_config/remote_config_service.dart';

class UpdateService extends GetxService {
  static UpdateService get to => Get.find();

  // Method channel for iOS SKOverlay
  static const MethodChannel _channel = MethodChannel('app_store_overlay');

  // Configuration variables
  final RxBool _isUpdateAvailable = false.obs;
  final RxBool _isCriticalUpdate = false.obs;
  final RxString _updateMessage = ''.obs;
  final RxString _currentVersion = ''.obs;
  final RxString _storeVersion = ''.obs;
  final RxString _minimumVersion = ''.obs;

  // Getters
  bool get isUpdateAvailable => _isUpdateAvailable.value;
  bool get isCriticalUpdate => _isCriticalUpdate.value;
  String get updateMessage => _updateMessage.value;
  String get currentVersion => _currentVersion.value;
  String get storeVersion => _storeVersion.value;
  String get minimumVersion => _minimumVersion.value;

  // Remote config service reference
  RemoteConfigService? _remoteConfigService;

  @override
  void onInit() {
    super.onInit();
    _initPackageInfo();
    _initRemoteConfig();
  }

  Future<void> _initRemoteConfig() async {
    try {
      // Get RemoteConfigService instance if available
      if (Get.isRegistered<RemoteConfigService>()) {
        _remoteConfigService = Get.find<RemoteConfigService>();

        // Listen to changes in minimum app version from remote config (platform-specific)
        if (GetPlatform.isIOS) {
          ever(_remoteConfigService!.minimumIosVersion, (String minVersion) {
            _handleVersionUpdate(minVersion, 'iOS');
          });
        } else {
          ever(_remoteConfigService!.minimumAppVersion, (String minVersion) {
            _handleVersionUpdate(minVersion, 'Android');
          });
        }
      } else {
        AppLogger.info(
          'RemoteConfigService not registered, skipping remote config integration',
          tag: 'UpdateService',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error initializing remote config: $e',
        tag: 'UpdateService',
      );
    }
  }

  // Handle version update for platform-specific versions
  void _handleVersionUpdate(String minVersion, String platform) {
    if (minVersion.isNotEmpty) {
      _minimumVersion.value = minVersion;
      AppLogger.info(
        'Minimum $platform version from Remote Config: $minVersion',
        tag: 'UpdateService',
      );

      // Check if current version is below minimum version
      if (_currentVersion.value.isNotEmpty &&
          _isVersionLowerThan(_currentVersion.value, minVersion)) {
        _isUpdateAvailable.value = true;
        _isCriticalUpdate.value = true;
        _updateMessage.value =
            'A critical update is required to continue using the app.';
        AppLogger.info(
          'Critical update required for $platform: Current version ${_currentVersion.value} is below minimum ${_minimumVersion.value}',
          tag: 'UpdateService',
        );
      }
    }
  }

  // Helper method to compare version strings
  bool _isVersionLowerThan(String currentVersion, String minimumVersion) {
    try {
      final current = currentVersion.split('.');
      final minimum = minimumVersion.split('.');

      // Compare major version
      final currentMajor = int.parse(current[0]);
      final minimumMajor = int.parse(minimum[0]);

      if (currentMajor < minimumMajor) return true;
      if (currentMajor > minimumMajor) return false;

      // Compare minor version
      if (current.length > 1 && minimum.length > 1) {
        final currentMinor = int.parse(current[1]);
        final minimumMinor = int.parse(minimum[1]);

        if (currentMinor < minimumMinor) return true;
        if (currentMinor > minimumMinor) return false;

        // Compare patch version
        if (current.length > 2 && minimum.length > 2) {
          final currentPatch = int.parse(current[2]);
          final minimumPatch = int.parse(minimum[2]);

          return currentPatch < minimumPatch;
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('Error comparing versions: $e', tag: 'UpdateService');
      return false;
    }
  }

  Future<void> _initPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion.value = packageInfo.version;
      AppLogger.info(
        'Current app version: ${_currentVersion.value}',
        tag: 'UpdateService',
      );
    } catch (e) {
      AppLogger.error('Error getting package info: $e', tag: 'UpdateService');
    }
  }

  // Initialize the upgrader with custom settings
  Upgrader initUpgrader({
    bool debugDisplayAlways = false,
    bool debugLogging = false,
    bool canDismissDialog = true,
    String? countryCode,
    Duration? durationUntilAlertAgain,
  }) {
    // No custom message needed here, we'll use it directly in the dialog

    final upgrader = Upgrader(
      durationUntilAlertAgain:
          durationUntilAlertAgain ?? const Duration(days: 3),
      debugDisplayAlways: debugDisplayAlways,
      debugLogging: debugLogging,
      countryCode: countryCode ?? 'IN',
    );

    return upgrader;
  }

  // Show a modern bottom sheet for update prompt
  Future<void> showUpdateDialog(
    BuildContext context, {
    bool isCritical = false,
    String? message,
    bool canDismiss = true,
  }) async {
    // Debug: Log current route
    AppLogger.info(
      'Attempting to show update dialog - Current route: ${Get.currentRoute}',
      tag: 'UpdateService',
    );

    // Only show on dashboard screen (check for common dashboard route patterns)
    final currentRoute = Get.currentRoute;
    final isDashboardRoute = currentRoute == '/Dashboard' || 
                            currentRoute == '/dashboard' || 
                            currentRoute.contains('Dashboard') ||
                            currentRoute == '/StackedNavbar' ||
                            currentRoute == '/' ||
                            currentRoute.isEmpty;
    
    if (!isDashboardRoute) {
      AppLogger.warning(
        'Route check failed - Current route: $currentRoute. Showing dialog anyway for critical updates.',
        tag: 'UpdateService',
      );
      // For critical updates, show anyway but log the warning
      if (!isCritical) {
        return;
      }
    }

    _isCriticalUpdate.value = isCritical;
    if (message != null) {
      _updateMessage.value = message;
    }

    _isUpdateAvailable.value = true;

    if (context.mounted) {
      AppLogger.info(
        'Context is mounted, showing update dialog',
        tag: 'UpdateService',
      );
      
      try {
        // Show fullscreen dialog with smooth transition
        await showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.8),
          transitionDuration: const Duration(milliseconds: 400),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // Start from bottom
                end: Offset.zero, // End at center
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          pageBuilder: (context, animation, secondaryAnimation) {
            return WillPopScope(
              onWillPop: () async => false, // Prevent back button
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  child: _buildUpdateBottomSheet(context, isCritical),
                ),
              ),
            );
          },
        );
        
        AppLogger.info(
          'Update dialog displayed successfully',
          tag: 'UpdateService',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error showing update dialog: $e',
          error: e,
          stackTrace: stackTrace,
          tag: 'UpdateService',
        );
      }
    } else {
      AppLogger.error(
        'Context is not mounted, cannot show update dialog',
        tag: 'UpdateService',
      );
    }
  }

  // Helper method to build animated widgets with staggered delays
  Widget _buildAnimatedWidget({
    required int delay,
    required int duration,
    required Curve curve,
    required Widget child,
    Offset? slideOffset,
    bool scale = false,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(opacity: 0.0, child: child);
        }
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: duration),
          curve: curve,
          builder: (context, value, _) {
            // Ensure value is always within valid range
            final clampedValue = value.clamp(0.0, 1.0);
            Widget animatedChild = child;
            
            // Apply slide animation if specified
            if (slideOffset != null) {
              animatedChild = Transform.translate(
                offset: Offset(
                  slideOffset.dx * (1 - clampedValue),
                  slideOffset.dy * (1 - clampedValue),
                ),
                child: animatedChild,
              );
            }
            
            // Apply scale animation if specified
            if (scale) {
              animatedChild = Transform.scale(
                scale: clampedValue,
                child: animatedChild,
              );
            }
            
            // Apply fade animation with clamped value
            return Opacity(
              opacity: clampedValue,
              child: animatedChild,
            );
          },
        );
      },
    );
  }

  // Build a modern update bottom sheet
  Widget _buildUpdateBottomSheet(BuildContext context, bool isCritical) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: double.infinity,
      color: AppColors.darkCardBG,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacer
              const Spacer(flex: 1),

              // Update icon with staggered animation
              _buildAnimatedWidget(
                delay: 0,
                duration: 600,
                curve: Curves.easeOutBack,
                scale: true,
                child: Container(
                  width: 160,
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonPrimaryBackground
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkButtonPrimaryBackground
                            .withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 80,
                      color: AppColors.darkButtonPrimaryBackground,
                    ),
                  ),
                ),
              ),

              // Update title with staggered animation
              _buildAnimatedWidget(
                delay: 200,
                duration: 600,
                curve: Curves.easeOutQuart,
                slideOffset: const Offset(0, 20),
                child: Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Update message with staggered animation
              _buildAnimatedWidget(
                delay: 400,
                duration: 600,
                curve: Curves.easeOutQuart,
                slideOffset: const Offset(0, 20),
                child: Text(
                  _updateMessage.value.isNotEmpty
                      ? _updateMessage.value
                      : 'A new version of Networth Tracker is available with exciting new features and improvements!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Bottom spacer
              const Spacer(flex: 1),

              // Action buttons with staggered animation
              _buildAnimatedWidget(
                delay: 600,
                duration: 600,
                curve: Curves.easeOutQuart,
                slideOffset: const Offset(0, 40),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    children: [
                      // Later button (only if not critical)
                      if (!isCritical)
                        Expanded(
                          child: AppButton(
                            text: 'Later',
                            onPressed: () => Navigator.of(context).pop(),
                            variant: AppButtonVariant.secondary,
                          ),
                        ),

                      // Spacing between buttons
                      if (!isCritical) const SizedBox(width: 16),

                      // Update now button
                      Expanded(
                        flex: isCritical ? 2 : 1,
                        child: AppButton(
                          text: 'Update Now',
                          onPressed: () async {
                            AppLogger.info(
                              'User accepted update - launching app store',
                              tag: 'UpdateService',
                            );
                            _launchAppStore();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check for updates without showing UI
  Future<bool> checkForUpdates() async {
    try {
      // Check if we have a minimum version from Remote Config (platform-specific)
      if (_remoteConfigService != null && _minimumVersion.value.isNotEmpty) {
        // Refresh remote config to get latest minimum version
        await _remoteConfigService!.fetchAndActivate();

        // Get platform-specific minimum version
        String platformMinVersion;
        String platform;
        if (GetPlatform.isIOS) {
          platformMinVersion = _remoteConfigService!.minimumIosVersion.value;
          platform = 'iOS';
        } else {
          platformMinVersion = _remoteConfigService!.minimumAppVersion.value;
          platform = 'Android';
        }

        // Compare current version with platform-specific minimum version
        if (_currentVersion.value.isNotEmpty &&
            platformMinVersion.isNotEmpty &&
            _isVersionLowerThan(_currentVersion.value, platformMinVersion)) {
          _isUpdateAvailable.value = true;
          _isCriticalUpdate.value = true;
          _storeVersion.value = platformMinVersion;

          AppLogger.info(
            'Critical update required for $platform: Current version ${_currentVersion.value} is below minimum $platformMinVersion',
            tag: 'UpdateService',
          );

          return true;
        }
      }

      // Normal update check using upgrader package
      final upgrader = initUpgrader(debugLogging: false);
      await upgrader.initialize();
      final shouldUpdate = upgrader.shouldDisplayUpgrade();
      _isUpdateAvailable.value = shouldUpdate;
      _storeVersion.value = upgrader.currentAppStoreVersion ?? '';

      // If store version is higher than current but not critical
      if (shouldUpdate) {
        _isCriticalUpdate.value = false;
      }

      AppLogger.info(
        'Update check: available=${_isUpdateAvailable.value}, '
        'store version=${_storeVersion.value}, '
        'critical=${_isCriticalUpdate.value}',
        tag: 'UpdateService',
      );

      return shouldUpdate;
    } catch (e) {
      AppLogger.error('Error checking for updates: $e', tag: 'UpdateService');
      return false;
    }
  }

  // Launch the app store based on platform
  Future<void> _launchAppStore() async {
    try {
      final remoteConfig = Get.find<RemoteConfigService>();
      String? url;

      if (GetPlatform.isAndroid) {
        url = remoteConfig.playStoreUrl.value;
        
        // Try native Android in-app update first
        try {
          AppLogger.info('Attempting native Android in-app update', tag: 'UpdateService');
          final info = await InAppUpdate.checkForUpdate();
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            await InAppUpdate.performImmediateUpdate();
            return; // Success, don't fallback to URL
          }
        } catch (e) {
          AppLogger.warning('Native Android in-app update not available: $e', tag: 'UpdateService');
        }
      } else if (GetPlatform.isIOS) {
        url = remoteConfig.appStoreUrl.value;
        
        // Try native iOS SKOverlay
        if (url.contains('id')) {
          try {
            final String appId = url.split('id').last.split('?').first;
            AppLogger.info('Attempting native iOS SKOverlay for appId: $appId', tag: 'UpdateService');
            final bool result = await _channel.invokeMethod('showOverlay', {'appId': appId});
            if (result) return; // Success, don't fallback to URL
          } catch (e) {
            AppLogger.warning('Native iOS SKOverlay failed: $e', tag: 'UpdateService');
          }
        }
      }

      // Fallback to external browser if native methods fail or on other platforms
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          AppLogger.success('Launched app store via external application: $url', tag: 'UpdateService');
        } else {
          AppLogger.error(
            'Could not launch app store URL: $url',
            tag: 'UpdateService',
          );
        }
      } else {
        AppLogger.error(
          'No store URL available for platform: ${GetPlatform.isAndroid ? 'Android' : 'iOS'}',
          tag: 'UpdateService',
        );
      }
    } catch (e) {
      AppLogger.error('Error launching app store: $e', tag: 'UpdateService');
    }
  }
}
