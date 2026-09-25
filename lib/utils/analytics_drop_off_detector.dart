import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/analytics.dart';
import '../services/analytics/analytics_service.dart';

/// Utility class for detecting user drop-offs and tracking abandonment
class AnalyticsDropOffDetector {
  static final Map<String, Timer> _activeTimers = {};
  static final Map<String, DateTime> _screenStartTimes = {};

  /// Start tracking a screen for drop-off detection
  static void startScreenTracking(String screenName, {Duration? timeout}) {
    final effectiveTimeout = timeout ?? const Duration(minutes: 2);
    
    // Cancel any existing timer for this screen
    _activeTimers[screenName]?.cancel();
    
    // Record screen start time
    _screenStartTimes[screenName] = DateTime.now();
    
    // Start timeout timer
    _activeTimers[screenName] = Timer(effectiveTimeout, () {
      _handleScreenTimeout(screenName);
    });
  }

  /// Stop tracking a screen (user completed or navigated away normally)
  static void stopScreenTracking(String screenName, {bool completed = false}) {
    _activeTimers[screenName]?.cancel();
    _activeTimers.remove(screenName);
    
    final startTime = _screenStartTimes[screenName];
    if (startTime != null) {
      final timeOnScreen = DateTime.now().difference(startTime).inSeconds;
      _screenStartTimes.remove(screenName);
      
      if (!completed) {
        _handleScreenAbandonment(screenName, timeOnScreen);
      }
    }
  }

  /// Handle screen timeout (user spent too long without action)
  static void _handleScreenTimeout(String screenName) {
    _activeTimers.remove(screenName);
    _screenStartTimes.remove(screenName);
    
    final eventName = _getTimeoutEventName(screenName);
    if (eventName != null) {
      AnalyticsService.to.logEvent(
        name: eventName,
        parameters: {
          'screen_name': screenName,
          'time_limit_exceeded': '2_minutes',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Handle screen abandonment (user left the screen)
  static void _handleScreenAbandonment(String screenName, int timeOnScreen) {
    final eventName = _getAbandonmentEventName(screenName);
    if (eventName != null) {
      AnalyticsService.to.logEvent(
        name: eventName,
        parameters: {
          'screen_name': screenName,
          'time_on_screen': timeOnScreen.toString(),
          'reason': 'screen_exit',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Get the timeout event name for a screen
  static String? _getTimeoutEventName(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'welcome':
        return AnalyticsEvents.welcomeScreenTimeExceeded;
      case 'phone_verification':
        return AnalyticsEvents.otpScreenAbandoned; // Reuse for timeout
      case 'pan_verification':
        return AnalyticsEvents.panVerificationTimeout;
      case 'bse_v2_holder_details':
        return AnalyticsEvents.bseV2JourneyTimeout;
      case 'dashboard':
        return AnalyticsEvents.dashboardFirstSessionShort;
      default:
        return '${screenName}_time_exceeded';
    }
  }

  /// Get the abandonment event name for a screen
  static String? _getAbandonmentEventName(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'welcome':
        return AnalyticsEvents.welcomeScreenAbandoned;
      case 'phone_verification':
        return AnalyticsEvents.phoneScreenAbandoned;
      case 'otp_verification':
        return AnalyticsEvents.otpScreenAbandoned;
      case 'email_verification':
        return AnalyticsEvents.emailScreenAbandoned;
      case 'pan_verification':
        return AnalyticsEvents.panScreenAbandoned;
      case 'personalization':
        return AnalyticsEvents.personalizeScreenAbandoned;
      case 'bse_v2_journey':
        return AnalyticsEvents.bseV2JourneyAbandoned;
      case 'dashboard':
        return AnalyticsEvents.dashboardFirstVisitAbandoned;
      case 'data_fetch':
        return AnalyticsEvents.dataFetchAbandoned;
      case 'investments':
        return 'investments_screen_abandoned';
      case 'paper_trading':
        return 'paper_trading_abandoned';
      case 'transactions':
        return 'transactions_screen_abandoned';
      case 'search':
        return 'search_abandoned';
      case 'family_management':
        return 'family_management_abandoned';
      case 'orders':
        return 'orders_screen_abandoned';
      case 'personal_assets':
        return 'personal_assets_abandoned';
      default:
        return '${screenName}_abandoned';
    }
  }

  /// Track specific user actions that might indicate drop-off risk
  static void trackDropOffRisk(String screenName, String riskType, Map<String, dynamic>? additionalParams) {
    AnalyticsService.to.logEvent(
      name: '${screenName}_${riskType}_risk',
      parameters: {
        'screen_name': screenName,
        'risk_type': riskType,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Clean up all active timers (call when app is backgrounded/closed)
  static void cleanup() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _screenStartTimes.clear();
  }
}

/// Mixin to easily add drop-off tracking to any StatefulWidget
mixin DropOffTrackingMixin<T extends StatefulWidget> on State<T> {
  String get screenName;
  Duration? get timeout => null;

  @override
  void initState() {
    super.initState();
    AnalyticsDropOffDetector.startScreenTracking(screenName, timeout: timeout);
    _trackScreenView();
  }

  @override
  void dispose() {
    AnalyticsDropOffDetector.stopScreenTracking(screenName);
    super.dispose();
  }

  void _trackScreenView() {
    AnalyticsService.to.logEvent(
      name: '${screenName}_viewed',
      parameters: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Call this when user completes the screen successfully
  void trackScreenCompletion() {
    AnalyticsDropOffDetector.stopScreenTracking(screenName, completed: true);
    AnalyticsService.to.logEvent(
      name: '${screenName}_completed',
      parameters: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Extension for easier tracking in State classes
extension DropOffTrackingExtension on State {
  void trackScreenAction(String action, {Map<String, dynamic>? parameters}) {
    final screenName = widget.runtimeType.toString().toLowerCase();
    AnalyticsService.to.logEvent(
      name: '${screenName}_${action}',
      parameters: {
        'screen_name': screenName,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
  }
}
