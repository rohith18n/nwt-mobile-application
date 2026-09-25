import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/remote_config/remote_config_keys.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';

// Background handler is now managed in lib/notification/firebase_messaging.dart

/// A service that manages Firebase Remote Config functionality
class RemoteConfigService extends GetxService {
  static RemoteConfigService get to => Get.put(RemoteConfigService());

  /// Whether to force production environment regardless of debug mode
  final bool forceProduction = true;

  late final FirebaseRemoteConfig _remoteConfig;
  DateTime? _lastFetchTime;
  static const Duration _minFetchInterval = Duration(
    minutes: 5,
  ); // Minimum 5 minutes between fetches

  // Production defaults
  final Map<String, dynamic> _productionDefaults = {
    RemoteConfigKeys.baseUrl: 'https://app.networthtracker.in/api/v1',
    RemoteConfigKeys.appVersion: '1.0.1',
    RemoteConfigKeys.supabaseUrl: 'https://fkohtewplfaylkisrdyw.supabase.co',
    RemoteConfigKeys.supabaseAnonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrb2h0ZXdwbGZheWxraXNyZHl3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwMjI3MzQsImV4cCI6MjA2MjU5ODczNH0.eFU6BjcwlL8Mkc-_N6K-MtawNzaScTc0HFmXPqE3XM4',
    RemoteConfigKeys.supabaseEventsPerSecond: 10,
    RemoteConfigKeys.appStoreUrl:
        'https://apps.apple.com/us/app/pivot-money-networth-tracker/id6746093850',
    RemoteConfigKeys.playStoreUrl:
        'https://play.google.com/store/apps/details?id=com.app.networthtracker',
    RemoteConfigKeys.ageTillRetirement: 70,
    RemoteConfigKeys.advisorCalendarURL: "https://calendar.google.com/calendar",
    RemoteConfigKeys.isMfcWorking: true,
    RemoteConfigKeys.whatsappNumber: '919819982121',
    RemoteConfigKeys.hideGoogleAuth: false,
    // Meta (Facebook) SDK defaults
    RemoteConfigKeys.metaAppId: '1361832081809128',
    RemoteConfigKeys.metaClientToken: '0e4b37427d112812f9f43eab989a8260',
    RemoteConfigKeys.metaEnabled: true,
  };

  // UAT defaults
  final Map<String, dynamic> _uatDefaults = {
    'UAT_${RemoteConfigKeys.baseUrl}': 'https://lab.networthtracker.in/api/v1',
    'UAT_${RemoteConfigKeys.appVersion}': '1.0.1',
    'UAT_${RemoteConfigKeys.supabaseUrl}':
        'https://wkvaajslvyvvwlafxmqy.supabase.co',
    'UAT_${RemoteConfigKeys.supabaseAnonKey}':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdmFhanNsdnl2dndsYWZ4bXF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyODU2NTEsImV4cCI6MjA2Njg2MTY1MX0.X-YLRtbzuGcUERTaCH8xHLemzKAWRBjlJ2RuuswoRLc',
    'UAT_${RemoteConfigKeys.supabaseEventsPerSecond}': 10,
    'UAT_${RemoteConfigKeys.appStoreUrl}':
        'https://apps.apple.com/us/app/pivot-money-networth-tracker/id6746093850',
    'UAT_${RemoteConfigKeys.playStoreUrl}':
        'https://play.google.com/store/apps/details?id=com.app.networthtracker',
    'UAT_${RemoteConfigKeys.ageTillRetirement}': 70,
    'UAT_${RemoteConfigKeys.testAccounts}': '1111111111',
    'UAT_${RemoteConfigKeys.advisorCalendarURL}':
        "https://calendar.google.com/calendar",
    'UAT_${RemoteConfigKeys.isMfcWorking}': true,
    'UAT_${RemoteConfigKeys.whatsappNumber}': '919429188214',
    'UAT_${RemoteConfigKeys.hideGoogleAuth}': false,
    // Meta (Facebook) SDK UAT defaults
    'UAT_${RemoteConfigKeys.metaAppId}': '1361832081809128',
    'UAT_${RemoteConfigKeys.metaClientToken}': '0e4b37427d112812f9f43eab989a8260',
    'UAT_${RemoteConfigKeys.metaEnabled}': true,
  };

  /// Get the appropriate defaults based on debug mode
  Map<String, dynamic> get _defaults =>
      (kDebugMode && !forceProduction) ? _uatDefaults : _productionDefaults;

  // Observable values
  final Rx<String> baseUrl = ''.obs;
  final Rx<String> minimumAppVersion = ''.obs;
  final Rx<String> minimumIosVersion = ''.obs;
  final Rx<String> supabaseUrl = ''.obs;
  final Rx<String> supabaseAnonKey = ''.obs;
  final Rx<int> supabaseEventsPerSecond = 10.obs;
  final Rx<String> appStoreUrl = ''.obs;
  final Rx<String> playStoreUrl = ''.obs;
  final Rx<int> ageTillRetirement = 70.obs;
  final Rx<String> testAccounts = '1111111111'.obs;

  final Rx<String> advisorCalendarURL = ''.obs;
  final Rx<bool> isMfcWorking = true.obs;
  final Rx<String> whatsappNumber = '919429188214'.obs;
  final Rx<bool> hideGoogleAuth = false.obs;
  // Support Contact Config
  final Rx<Map<String, dynamic>?> supportContactConfig =
      Rx<Map<String, dynamic>?>(null);

  // Meta (Facebook) SDK Config
  final Rx<String> metaAppId = '1361832081809128'.obs;
  final Rx<String> metaClientToken = '0e4b37427d112812f9f43eab989a8260'.obs;
  final Rx<bool> metaEnabled = true.obs;

  /// Initialize the Remote Config service
  Future<RemoteConfigService> init() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure fetch settings with shorter intervals for faster updates
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode
                  ? const Duration(
                    seconds: 10,
                  ) // 10 seconds in debug mode for faster testing
                  : const Duration(
                    minutes: 5,
                  ), // 5 minutes in production for faster updates
        ),
      );

      // Only fetch if we haven't fetched recently
      if (_shouldFetch()) {
        await fetchAndActivate();
      } else {
        // Use cached values
        _updateValues();
        AppLogger.info(
          'Using cached Remote Config values to avoid throttling',
          tag: 'RemoteConfig',
        );
      }

      return this;
    } catch (e) {
      AppLogger.error(
        'Failed to initialize Remote Config: $e',
        tag: 'RemoteConfig',
      );
      _setDefaultValues();
      return this;
    }
  }

  /// Check if we should fetch based on throttling rules
  bool _shouldFetch() {
    if (_lastFetchTime == null) {
      return true; // First fetch
    }

    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    final shouldFetch = timeSinceLastFetch >= _minFetchInterval;

    AppLogger.info(
      'Fetch check - Last fetch: $_lastFetchTime, Time since: ${timeSinceLastFetch.inMinutes} minutes, Should fetch: $shouldFetch',
      tag: 'RemoteConfig',
    );

    return shouldFetch;
  }

  /// Fetch and activate remote config values with throttling protection
  Future<bool> fetchAndActivate() async {
    try {
      // Check throttling before attempting fetch
      if (!_shouldFetch()) {
        AppLogger.info(
          'Skipping fetch due to throttling (last fetch was ${DateTime.now().difference(_lastFetchTime!).inMinutes} minutes ago)',
          tag: 'RemoteConfig',
        );
        return false;
      }

      _lastFetchTime = DateTime.now();
      final updated = await _remoteConfig.fetchAndActivate();
      _updateValues();
      AppLogger.info('Remote Config updated: $updated', tag: 'RemoteConfig');
      return updated;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching Remote Config: $e',
        tag: 'RemoteConfig',
        stackTrace: stackTrace,
      );
      // Reset last fetch time on error to allow retry
      _lastFetchTime = null;
      return false;
    }
  }

  /// Force refresh remote config values (bypasses throttling)
  Future<bool> forceRefresh() async {
    try {
      AppLogger.info(
        'Force refreshing Remote Config (bypassing throttling)',
        tag: 'RemoteConfig',
      );

      _lastFetchTime = DateTime.now();
      await _remoteConfig.fetch();
      final updated = await _remoteConfig.activate();
      _updateValues();

      AppLogger.info(
        'Force refresh completed, updated: $updated',
        tag: 'RemoteConfig',
      );

      return updated;
    } catch (e) {
      AppLogger.error(
        'Error forcing Remote Config refresh: $e',
        tag: 'RemoteConfig',
      );
      // Reset last fetch time on error to allow retry
      _lastFetchTime = null;
      return false;
    }
  }

  /// Get the appropriate remote config key with UAT_ prefix in debug mode
  String _getConfigKey(String key) {
    if (!kDebugMode || forceProduction) return key;

    final uatKey = 'UAT_$key';
    // Check if the UAT-prefixed key is actually set on the server
    if (_remoteConfig.getValue(uatKey).source == ValueSource.valueRemote) {
      return uatKey;
    }

    // Fallback to production key if UAT key is not set
    return key;
  }

  /// Update observable values from Remote Config
  void _updateValues() {
    try {
      baseUrl.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.baseUrl),
      );
      minimumAppVersion.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.appVersion),
      );
      minimumIosVersion.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.iosVersion),
      );
      supabaseUrl.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.supabaseUrl),
      );
      supabaseAnonKey.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.supabaseAnonKey),
      );
      supabaseEventsPerSecond.value = _remoteConfig.getInt(
        _getConfigKey(RemoteConfigKeys.supabaseEventsPerSecond),
      );

      appStoreUrl.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.appStoreUrl),
      );
      playStoreUrl.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.playStoreUrl),
      );
      ageTillRetirement.value = _remoteConfig.getInt(
        _getConfigKey(RemoteConfigKeys.ageTillRetirement),
      );
      testAccounts.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.testAccounts),
      );
      advisorCalendarURL.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.advisorCalendarURL),
      );
      isMfcWorking.value = _remoteConfig.getBool(
        _getConfigKey(RemoteConfigKeys.isMfcWorking),
      );
      whatsappNumber.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.whatsappNumber),
      );
      hideGoogleAuth.value = _remoteConfig.getBool(
        _getConfigKey(RemoteConfigKeys.hideGoogleAuth),
      );
      AppLogger.info(
        'Fetched hideGoogleAuth: ${hideGoogleAuth.value} (Key: ${_getConfigKey(RemoteConfigKeys.hideGoogleAuth)})',
        tag: 'RemoteConfig',
      );

      // Meta (Facebook) SDK Config
      metaAppId.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.metaAppId),
      );
      metaClientToken.value = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.metaClientToken),
      );
      metaEnabled.value = _remoteConfig.getBool(
        _getConfigKey(RemoteConfigKeys.metaEnabled),
      );
      AppLogger.info(
        'Fetched Meta SDK config - AppId: ${metaAppId.value}, Enabled: ${metaEnabled.value}',
        tag: 'RemoteConfig',
      );

      // Parse supportContactConfig JSON if available
      final supportConfigJson = _remoteConfig.getString(
        _getConfigKey(RemoteConfigKeys.supportContactConfig),
      );
      if (supportConfigJson.isNotEmpty) {
        try {
          supportContactConfig.value =
              jsonDecode(supportConfigJson) as Map<String, dynamic>;
          AppLogger.info(
            'Parsed supportContactConfig: ${supportContactConfig.value}',
            tag: 'RemoteConfig',
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error parsing supportContactConfig JSON: $e',
            tag: 'RemoteConfig',
            stackTrace: stackTrace,
          );
          supportContactConfig.value = null;
        }
      } else {
        supportContactConfig.value = null;
      }

      // Use defaults if values are empty
      if (baseUrl.value.isEmpty) {
        AppLogger.info(
          'Using default value for baseUrl: ${baseUrl.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.baseUrl)]}',
          tag: 'RemoteConfig',
        );
        baseUrl.value = _defaults[_getConfigKey(RemoteConfigKeys.baseUrl)];
      }
      if (whatsappNumber.value.isEmpty) {
        whatsappNumber.value =
            _defaults[_getConfigKey(RemoteConfigKeys.whatsappNumber)];
      }
      if (minimumAppVersion.value.isEmpty) {
        AppLogger.info(
          'Using default value for minimumAppVersion: ${minimumAppVersion.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.appVersion)]}',
          tag: 'RemoteConfig',
        );
        minimumAppVersion.value =
            _defaults[_getConfigKey(RemoteConfigKeys.appVersion)];
      }
      if (minimumIosVersion.value.isEmpty) {
        AppLogger.info(
          'Using default value for minimumIosVersion: ${minimumIosVersion.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.iosVersion)]}',
          tag: 'RemoteConfig',
        );
        minimumIosVersion.value =
            _defaults[_getConfigKey(RemoteConfigKeys.iosVersion)];
      }
      if (supabaseUrl.value.isEmpty) {
        AppLogger.info(
          'Using default value for supabaseUrl: ${supabaseUrl.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.supabaseUrl)]}',
          tag: 'RemoteConfig',
        );
        supabaseUrl.value =
            _defaults[_getConfigKey(RemoteConfigKeys.supabaseUrl)];
      }
      if (supabaseAnonKey.value.isEmpty) {
        AppLogger.info(
          'Using default value for supabaseAnonKey: ${supabaseAnonKey.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.supabaseAnonKey)]}',
          tag: 'RemoteConfig',
        );
        supabaseAnonKey.value =
            _defaults[_getConfigKey(RemoteConfigKeys.supabaseAnonKey)];
      }
      if (appStoreUrl.value.isEmpty) {
        AppLogger.info(
          'Using default value for appStoreUrl: ${appStoreUrl.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.appStoreUrl)]}',
          tag: 'RemoteConfig',
        );
        appStoreUrl.value =
            _defaults[_getConfigKey(RemoteConfigKeys.appStoreUrl)];
      }
      if (playStoreUrl.value.isEmpty) {
        AppLogger.info(
          'Using default value for playStoreUrl: ${playStoreUrl.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.playStoreUrl)]}',
          tag: 'RemoteConfig',
        );
        playStoreUrl.value =
            _defaults[_getConfigKey(RemoteConfigKeys.playStoreUrl)];
      }
      if (ageTillRetirement.value == 0) {
        AppLogger.info(
          'Using default value for ageTillRetirement: ${ageTillRetirement.value}_____ ${kDebugMode ? 'UAT_' : ''} ${_defaults[_getConfigKey(RemoteConfigKeys.ageTillRetirement)]}',
          tag: 'RemoteConfig',
        );
        ageTillRetirement.value =
            _defaults[_getConfigKey(RemoteConfigKeys.ageTillRetirement)];
      }
      if (testAccounts.value.isEmpty) {
        AppLogger.info(
          'Using default value for testAccounts: ${testAccounts.value}_____ ${_defaults[_getConfigKey(RemoteConfigKeys.testAccounts)]}',
          tag: 'RemoteConfig',
        );
        testAccounts.value =
            _defaults[_getConfigKey(RemoteConfigKeys.testAccounts)];
      }
      if (advisorCalendarURL.value.isEmpty) {
        AppLogger.info(
          'Using default value for advisorCalendarURL: ${advisorCalendarURL.value}_____ ${kDebugMode ? 'UAT_' : ''} ${_defaults[_getConfigKey(RemoteConfigKeys.advisorCalendarURL)]}',
          tag: 'RemoteConfig',
        );
        advisorCalendarURL.value =
            _defaults[_getConfigKey(RemoteConfigKeys.advisorCalendarURL)];
      }
      if (metaAppId.value.isEmpty) {
        AppLogger.info(
          'Using default value for metaAppId',
          tag: 'RemoteConfig',
        );
        metaAppId.value =
            _defaults[_getConfigKey(RemoteConfigKeys.metaAppId)];
      }
      if (metaClientToken.value.isEmpty) {
        AppLogger.info(
          'Using default value for metaClientToken',
          tag: 'RemoteConfig',
        );
        metaClientToken.value =
            _defaults[_getConfigKey(RemoteConfigKeys.metaClientToken)];
      }
      AppLogger.info(
        'isMfcWorking: ${isMfcWorking.value}, Meta SDK Enabled: ${metaEnabled.value}',
        tag: 'RemoteConfig',
      );

      SpeakToAdvisor.initialize(advisorCalendarURL.value);

      AppLogger.info(
        'Updated Remote Config values - baseUrl: ${baseUrl.value}, minimumAppVersion: ${minimumAppVersion.value}, supabaseUrl: ${supabaseUrl.value}, eventsPerSecond: ${supabaseEventsPerSecond.value}, appStoreUrl: ${appStoreUrl.value}, playStoreUrl: ${playStoreUrl.value}, ageTillRetirement: ${ageTillRetirement.value}, advisorCalendarURL: ${advisorCalendarURL.value}',
        tag: 'RemoteConfig',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error parsing APP_CONFIG: $e',
        tag: 'RemoteConfig',
        stackTrace: stackTrace,
      );
      _setDefaultValues();
    }
  }

  /// Set empty values for observables
  void _setDefaultValues() {
    baseUrl.value = _defaults[_getConfigKey(RemoteConfigKeys.baseUrl)];
    minimumAppVersion.value =
        _defaults[_getConfigKey(RemoteConfigKeys.appVersion)];
    minimumIosVersion.value =
        _defaults[_getConfigKey(RemoteConfigKeys.iosVersion)];
    supabaseUrl.value = _defaults[_getConfigKey(RemoteConfigKeys.supabaseUrl)];
    supabaseAnonKey.value =
        _defaults[_getConfigKey(RemoteConfigKeys.supabaseAnonKey)];
    supabaseEventsPerSecond.value =
        _defaults[_getConfigKey(RemoteConfigKeys.supabaseEventsPerSecond)];

    ageTillRetirement.value =
        _defaults[_getConfigKey(RemoteConfigKeys.ageTillRetirement)];
    testAccounts.value =
        _defaults[_getConfigKey(RemoteConfigKeys.testAccounts)];
    advisorCalendarURL.value =
        _defaults[_getConfigKey(RemoteConfigKeys.advisorCalendarURL)];
    isMfcWorking.value =
        _defaults[_getConfigKey(RemoteConfigKeys.isMfcWorking)];
    whatsappNumber.value =
        _defaults[_getConfigKey(RemoteConfigKeys.whatsappNumber)];
    hideGoogleAuth.value =
        _defaults[_getConfigKey(RemoteConfigKeys.hideGoogleAuth)];
    metaAppId.value =
        _defaults[_getConfigKey(RemoteConfigKeys.metaAppId)];
    metaClientToken.value =
        _defaults[_getConfigKey(RemoteConfigKeys.metaClientToken)];
    metaEnabled.value =
        _defaults[_getConfigKey(RemoteConfigKeys.metaEnabled)];
    AppLogger.info(
      'Using default values - baseUrl: ${baseUrl.value}, minimumAppVersion: ${minimumAppVersion.value}, supabaseUrl: ${supabaseUrl.value}, eventsPerSecond: ${supabaseEventsPerSecond.value}, ageTillRetirement: ${ageTillRetirement.value}, testAccounts: ${testAccounts.value}, metaEnabled: ${metaEnabled.value}',
      tag: 'RemoteConfig',
    );
  }
}
