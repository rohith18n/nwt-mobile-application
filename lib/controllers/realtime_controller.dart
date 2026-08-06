import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for managing Supabase realtime subscriptions
class RealtimeController extends GetxController {
  // Store the Supabase channel subscriptions
  RealtimeChannel? _userChannel;
  RealtimeChannel? _accountsChannel;

  // Track MF fetching process statuses
  final RxMap<String, dynamic> mfFetchingStatus =
      <String, dynamic>{
        "mfc_connect": {
          "status": "pending",
          "message": "Contacting MF Central",
        },
        "fetching_data": {
          "status": "pending",
          "message": "Fetching data from MF Central",
        },
        "processing_data": {
          "status": "pending",
          "message": "Processing your data",
        },
        "analyzing_portfolio": {
          "status": "pending",
          "message": "Analyzing your portfolio",
        },
      }.obs;

  // Track MF fetched status
  final RxBool isMfFetched = false.obs;

  // Track if user has skipped MF verification
  final RxBool skipMfc = false.obs;

  // Track remaining adhoc refreshes
  final RxDouble adhocRemaining = 0.0.obs;

  // Callback for refreshing data
  VoidCallback? _refreshDataCallback;

  // Callback for navigating to analysis screen
  VoidCallback? _navigateToAnalysisCallback;

  @override
  void onClose() {
    // Clean up subscriptions when controller is closed
    _userChannel?.unsubscribe();
    _userChannel = null;
    _accountsChannel?.unsubscribe();
    _accountsChannel = null;
    super.onClose();
  }

  /// Set the callback for refreshing data
  void setRefreshDataCallback(VoidCallback callback) {
    _refreshDataCallback = callback;
  }

  /// Set the callback for navigating to analysis screen
  void setNavigateToAnalysisCallback(VoidCallback callback) {
    _navigateToAnalysisCallback = callback;
  }

  /// Public method to trigger a UI refresh via the registered callback
  /// Useful for programmatic refreshes without navigation
  void triggerRefresh() {
    AppLogger.info(
      'RealtimeController: triggerRefresh called',
      tag: 'RealtimeController',
    );
    _refreshData();
  }

  /// Set up a realtime subscription for a specific user
  void setupUserSubscription(String userId, bool initialMfFetchedStatus) {
    // Add debug logging
    AppLogger.info(
      'Setting up realtime subscription for user $userId with initial MF status: $initialMfFetchedStatus',
      tag: 'RealtimeController',
    );

    // Update the initial status
    isMfFetched.value = initialMfFetchedStatus;

    // Fetch initial adhoc remaining value from the database
    _fetchInitialAdhocRemaining(userId);

    // Close any existing subscription
    _userChannel?.unsubscribe();

    final supabase = Supabase.instance.client;

    // Create a new channel for this specific user
    _userChannel = supabase.channel('public:users:id=$userId');
    AppLogger.info(
      'Created channel: public:users:id=$userId',
      tag: 'RealtimeController',
    );

    // Subscribe to changes for this specific user's ismffetched field
    _userChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            // Debug log the payload
            AppLogger.info(
              'Received Supabase update: ${payload.toString()}',
              tag: 'RealtimeController',
            );

            // Check if this is the current user's record
            if (payload.newRecord['id'].toString() == userId.toString()) {
              final newRecord = payload.newRecord;
              AppLogger.info(
                'Received update for current user: $newRecord',
                tag: 'RealtimeController',
              );
              adhocRemaining.value =
                  (newRecord['adhocremaining']?.toDouble() ?? 0.0) as double;
              AppLogger.info(
                'User adhoc remaining updated: ${adhocRemaining.value}',
                tag: 'RealtimeController',
              );
              // Check if the mfcstatus  field exists
              if (newRecord.containsKey('mfcstatus')) {
                try {
                  final fetchingStatus = newRecord['mfcstatus'];
                  if (fetchingStatus != null) {
                    // Handle both string and map types
                    Map<String, dynamic> statusMap;

                    if (fetchingStatus is String) {
                      // Parse the JSON string into a Map
                      statusMap = jsonDecode(fetchingStatus);
                    } else if (fetchingStatus is Map) {
                      // Already a Map, just convert it
                      statusMap = Map<String, dynamic>.from(fetchingStatus);
                    } else {
                      throw TypeError();
                    }

                    // Filter out any OTP part if present and keep only the specified statuses
                    Map<String, dynamic> filteredStatusMap = {};
                    for (String key in statusMap.keys) {
                      if ([
                        'mfc_connect',
                        'fetching_data',
                        'processing_data',
                        'analyzing_portfolio',
                      ].contains(key)) {
                        filteredStatusMap[key] = statusMap[key];
                      }
                    }

                    AppLogger.info(
                      'MF fetching status update received (filtered): $filteredStatusMap',
                      tag: 'RealtimeController',
                    );

                    // Update our local state with the filtered statuses
                    mfFetchingStatus.value = filteredStatusMap;
                  }
                } catch (e) {
                  AppLogger.error(
                    'Error parsing MF fetching status: $e',
                    tag: 'RealtimeController',
                  );
                }
              }

              // Check if the ismffetched field exists and has changed
              if (newRecord.containsKey('ismffetched')) {
                final isMfFetched = newRecord['ismffetched'] as bool?;
                AppLogger.info(
                  'User MF fetch status changed: $isMfFetched (previous: ${this.isMfFetched.value})',
                  tag: 'RealtimeController',
                );

                // Update our local state
                if (isMfFetched != null) {
                  // Check if the value changed from false to true
                  final valueChanged = !this.isMfFetched.value && isMfFetched;
                  AppLogger.info(
                    'Value changed from false to true: $valueChanged',
                    tag: 'RealtimeController',
                  );

                  // Update the value
                  this.isMfFetched.value = isMfFetched;

                  // If the value changed from false to true, show the bottom sheet first
                  if (valueChanged) {
                    AppLogger.info(
                      'MF status changed from false to true - showing bottom sheet first',
                      tag: 'RealtimeController',
                    );

                    // Show the bottom sheet first
                    // _showMutualFundDataRetrievedSheet();

                    // Data will be refreshed when user clicks the refresh button in the bottom sheet
                    // via the _refreshDataCallback
                  }
                }
              }
            }
          },
        )
        .subscribe();

    AppLogger.info('Subscription set up and active', tag: 'RealtimeController');
  }

  /// Refresh data without reloading the app
  void _refreshData() {
    // Close any existing bottom sheets
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    // Call the refresh data callback if it exists
    if (_refreshDataCallback != null) {
      AppLogger.info('Refreshing data via callback', tag: 'RealtimeController');
      _refreshDataCallback!();
    } else {
      AppLogger.warning(
        'No refresh data callback set',
        tag: 'RealtimeController',
      );
    }
  }

  /// Navigate to the analysis screen
  void _navigateToAnalysis() {
    // Close any existing bottom sheets
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    // Call the navigate to analysis callback if it exists
    if (_navigateToAnalysisCallback != null) {
      AppLogger.info(
        'Navigating to analysis via callback',
        tag: 'RealtimeController',
      );
      _navigateToAnalysisCallback!();
    } else {
      AppLogger.warning(
        'No navigate to analysis callback set',
        tag: 'RealtimeController',
      );
    }
  }

  /// Test method to manually trigger the bottom sheet
  /// This is for testing purposes only
  void testShowBottomSheet() {
    AppLogger.info(
      'Test method called to manually show bottom sheet',
      tag: 'RealtimeController',
    );

    // Simulate changing isMfFetched from false to true
    isMfFetched.value = true;
  }

  /// Fetch the initial adhoc remaining value and MF fetching status from the database
  Future<void> _fetchInitialAdhocRemaining(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // Query the user record
      final response =
          await supabase
              .from('users')
              .select('adhocremaining, ismffetched, mfcstatus')
              .eq('id', userId)
              .single();

      AppLogger.info(
        'Fetched initial user data: $response',
        tag: 'RealtimeController',
      );

      if (response['adhocremaining'] != null) {
        // Update the adhoc remaining value
        adhocRemaining.value =
            (response['adhocremaining']?.toDouble() ?? 0.0) as double;

        AppLogger.info(
          'Initial adhoc remaining fetched: ${adhocRemaining.value}',
          tag: 'RealtimeController',
        );
      }

      // Check for initial MF fetching status
      if (response['mfcstatus'] != null) {
        try {
          final fetchingStatus = response['mfcstatus'];
          if (fetchingStatus != null &&
              fetchingStatus is String &&
              fetchingStatus.isNotEmpty) {
            // Parse the JSON string into a Map
            Map<String, dynamic> statusMap = jsonDecode(fetchingStatus);

            // Filter and keep only the specified statuses in the correct order
            Map<String, dynamic> filteredStatusMap = {};
            // Define the order of steps
            final orderedSteps = [
              'mfc_connect',
              'fetching_data',
              'processing_data',
              'analyzing_portfolio',
            ];

            // Add steps in the defined order if they exist in the status map
            for (String step in orderedSteps) {
              if (statusMap.containsKey(step)) {
                filteredStatusMap[step] = statusMap[step];
              }
            }

            AppLogger.info(
              'Initial MF fetching status loaded (filtered): $filteredStatusMap',
              tag: 'RealtimeController',
            );

            // Update our local state with the filtered statuses
            mfFetchingStatus.value = filteredStatusMap;
          }
        } catch (e) {
          AppLogger.error(
            'Error parsing initial MF fetching status: $e',
            tag: 'RealtimeController',
          );
        }
      }

      if (response['ismffetched'] != null) {
        // Update the MF fetched status
        isMfFetched.value = response['ismffetched'] as bool;

        AppLogger.info(
          'Initial MF fetched status: ${isMfFetched.value}',
          tag: 'RealtimeController',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching initial user data: $e',
        tag: 'RealtimeController',
        stackTrace: stackTrace,
      );
    }
  }

  /// Callback for when accounts data changes (legacy single-listener)
  Function(List<Map<String, dynamic>>)? onAccountsChanged;

  /// Multiple listeners support for accounts updates
  final List<Function(List<Map<String, dynamic>>)> _accountsListeners = [];

  void addAccountsListener(Function(List<Map<String, dynamic>>) listener) {
    if (!_accountsListeners.contains(listener)) {
      _accountsListeners.add(listener);
    }
  }

  void removeAccountsListener(Function(List<Map<String, dynamic>>) listener) {
    _accountsListeners.remove(listener);
  }

  /// Set up a realtime subscription for accounts table
  ///
  /// [userGuid] - The GUID of the user whose accounts to monitor
  /// [onDataChanged] - Optional callback that will be called when accounts data changes
  void setupAccountsSubscription(
    String userGuid, {
    Function(List<Map<String, dynamic>>)? onDataChanged,
  }) {
    // Add debug logging
    AppLogger.info(
      'Setting up realtime subscription for accounts of user $userGuid',
      tag: 'RealtimeController',
    );

    // Store the callback (legacy) and also add to listeners list
    if (onDataChanged != null) {
      onAccountsChanged = onDataChanged;
      addAccountsListener(onDataChanged);
    }

    // Close any existing subscription
    _accountsChannel?.unsubscribe();

    final supabase = Supabase.instance.client;

    // Create a new channel for this specific user's accounts
    _accountsChannel = supabase.channel('public:accounts:userguid=$userGuid');
    AppLogger.info(
      'Created channel: public:accounts:userguid=$userGuid',
      tag: 'RealtimeController',
    );

    // Subscribe to changes for this specific user's accounts
    _accountsChannel!
        .onPostgresChanges(
          event:
              PostgresChangeEvent
                  .all, // Listen to all events (insert, update, delete)
          schema: 'public',
          table: 'accounts',
          callback: (payload) {
            // Log detailed information based on event type
            final eventType = payload.eventType;

            // Log specific details for each event type
            switch (eventType) {
              case PostgresChangeEvent.insert:
                developer.log(
                  '🟢 INSERT: New account added - FIP: ${payload.newRecord['fipname']}, Type: ${payload.newRecord['type']}, Status: ${payload.newRecord['fetchstatus']}',
                  name: 'RealtimeController',
                );
                break;
              case PostgresChangeEvent.update:
                developer.log(
                  '🔵 UPDATE: Account modified - FIP: ${payload.newRecord['fipname']}, New Status: ${payload.newRecord['fetchstatus']}, Old Status: ${payload.oldRecord['fetchstatus'] ?? 'unknown'}',
                  name: 'RealtimeController',
                );
                // If fetch status transitioned to 'success', trigger a dashboard refresh via callback
                try {
                  final newStatus =
                      (payload.newRecord['fetchstatus'] ?? '')
                          .toString()
                          .toLowerCase();
                  final oldStatus =
                      (payload.oldRecord['fetchstatus'] ?? '')
                          .toString()
                          .toLowerCase();
                  final belongsToUser =
                      payload.newRecord.containsKey('userguid') &&
                      payload.newRecord['userguid'] == userGuid;
                  if (belongsToUser &&
                      newStatus == 'success' &&
                      oldStatus != 'success') {
                    // Trigger lightweight refresh through registered callback (Dashboard wires this)
                    _refreshData();
                  }
                } catch (_) {
                  // No-op: defensive
                }
                break;
              case PostgresChangeEvent.delete:
                developer.log(
                  '🔴 DELETE: Account removed - GUID: ${payload.oldRecord['guid'] ?? 'unknown'}',
                  name: 'RealtimeController',
                );
                break;
              default:
                developer.log(
                  'Unknown event type: $eventType - Payload: ${payload.toString()}',
                  name: 'RealtimeController',
                );
            }

            // Also log the full payload for debugging
            AppLogger.info(
              'Received Supabase accounts update: ${payload.toString()}',
              tag: 'RealtimeController',
            );

            // Check if this is for the current user's accounts
            if (payload.newRecord.containsKey('userguid') &&
                payload.newRecord['userguid'] == userGuid) {
              // Fetch all accounts for this user to get the current state
              _fetchAllAccountsForUser(userGuid);
            }
          },
        )
        .subscribe();

    _fetchAllAccountsForUser(userGuid);

    AppLogger.info(
      'Accounts subscription set up and active',
      tag: 'RealtimeController',
    );
  }

  /// Fetch all accounts for a specific user
  Future<void> _fetchAllAccountsForUser(String userGuid) async {
    try {
      final supabase = Supabase.instance.client;

      // Query all accounts for this user with specific fields only
      final response = await supabase
          .from('accounts')
          .select(
            'userguid, type, activestatus, fetchstatusupdatedat, guid, fipid, fipname, fetchstatus, balancedatetime',
          )
          .eq('userguid', userGuid);

      // Convert to list of maps
      final accounts = List<Map<String, dynamic>>.from(response);

      AppLogger.info(
        'Fetched ${accounts.length} accounts for user $userGuid',
        tag: 'RealtimeController',
      );

      // Call legacy single callback if it exists
      if (onAccountsChanged != null) {
        onAccountsChanged!(accounts);
      }
      // Notify all registered listeners
      for (final listener in List.of(_accountsListeners)) {
        try {
          listener(accounts);
        } catch (e) {
          AppLogger.error(
            'Error notifying accounts listener: $e',
            tag: 'RealtimeController',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching accounts for user $userGuid: $e',
        tag: 'RealtimeController',
      );
    }
  }
}
