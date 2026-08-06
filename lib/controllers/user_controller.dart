import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/controllers/realtime_controller.dart';
import 'package:nwt_app/screens/mf_switch/analysis_mf.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_star/ucc_creation.dart';
import 'package:nwt_app/screens/bse_star/types/ucc_status_response.dart';

class UserController extends GetxController {
  User? _userData;
  User? get userData => _userData;

  bool _isSupportButtonHidden = false;
  bool get isSupportButtonHidden => _isSupportButtonHidden;

  bool _hasShownSupportGuidance = false;
  bool get hasShownSupportGuidance => _hasShownSupportGuidance;

  final AuthService _authService = AuthService();
  final BseUccCreationService _uccService = BseUccCreationService();
  // Safe access to RealtimeController
  RealtimeController get _realtimeController => Get.find<RealtimeController>();

  // UCC Status Cache
  final Rx<UccStatusResponse?> uccStatusResponse = Rx<UccStatusResponse?>(null);
  DateTime? _lastUccFetchTime;
  final Duration _uccCacheDuration = const Duration(minutes: 5);

  RxBool get isMfFetched => _realtimeController.isMfFetched;

  @override
  void onInit() {
    super.onInit();

    _isSupportButtonHidden = StorageService.read('whatsapp_btn_hidden') ?? false;
    _hasShownSupportGuidance =
        StorageService.read('whatsapp_guidance_shown') ?? false;

    _setupRealtimeController();
    initializeUserData();
  }

  void setSupportButtonHidden(bool hidden) {
    _isSupportButtonHidden = hidden;
    StorageService.write('whatsapp_btn_hidden', hidden);
    update();
  }

  void setGuidanceShown(bool shown) {
    _hasShownSupportGuidance = shown;
    StorageService.write('whatsapp_guidance_shown', shown);
    update();
  }

  void _setupRealtimeController() {
    try {
      final rt = _realtimeController;
      rt.setRefreshDataCallback(_refreshData);
      rt.setNavigateToAnalysisCallback(_navigateToAnalysis);
    } catch (e) {
      Future.delayed(
        const Duration(milliseconds: 100),
        _setupRealtimeController,
      );
    }
  }

  Future<void> initializeUserData() async {
    final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
    AppLogger.info(token.toString(), tag: 'UserController');
    if (token != null) {
      await fetchUserProfile(onLoading: (loading) {});
    } else {
      developer.log('Access token not found. User needs to login.');
    }
  }

  Future<UserDataResponse> fetchUserProfile({
    required Function(bool) onLoading,
  }) async {
    final response = await _authService.getUserProfile(onLoading: onLoading);
    AppLogger.info(response.toString(), tag: 'UserController');
    _userData = response.user;

    if (_userData != null) {
      if (_userData?.id != null) {
        SecureStorage.write("userid", _userData?.id.toString());
      }
      
      // Ensure RealtimeController is registered before setup
      if (Get.isRegistered<RealtimeController>()) {
        final rt = Get.find<RealtimeController>();
        rt.setupUserSubscription(
          _userData!.id,
          _userData!.ismfverified,
        );
        rt.setupAccountsSubscription(
          _userData!.guid?.toString() ?? "",
        );
      }
    }

    update();
    return response;
  }

  void _refreshData() {
    AppLogger.info(
      'Refreshing data in-place on Dashboard (no navigation)',
      tag: 'UserController',
    );

    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // Trigger an in-place dashboard refresh via RealtimeController
    if (Get.isRegistered<RealtimeController>()) {
      final rt = Get.find<RealtimeController>();
      rt.triggerRefresh();
    } else {
      AppLogger.error(
        'RealtimeController not registered; cannot trigger dashboard refresh',
        tag: 'UserController',
      );
    }

    fetchUserProfile(onLoading: (_) {})
        .then((_) {
          update();

          AppLogger.info('Data refreshed successfully', tag: 'UserController');
        })
        .catchError((error) {
          AppLogger.error(
            'Failed to refresh data: $error',
            tag: 'UserController',
          );

          Get.snackbar(
            'Error',
            'Failed to refresh data: $error',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.7),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        });
  }

  void _navigateToAnalysis() {
    AppLogger.info('Navigating to analysis screen', tag: 'UserController');
    Get.to(() => const AnalysisMutualFund());
  }


  void clearUserData() {
    Get.find<RealtimeController>().onClose();

    _userData = null;
    clearUccCache();
    update();
  }

  /// UCC Status Caching Logic
  Future<UccStatusResponse?> checkAndCacheUccStatus({
    bool forceRefetch = false,
  }) async {
    final now = DateTime.now();

    // Check if we have a valid cache
    final currentStatus = uccStatusResponse.value;
    final isAlreadyActive =
        currentStatus != null &&
        currentStatus.status == 'success' &&
        currentStatus.data?.uccStatus == 'ACTIVE';

    if (!forceRefetch && currentStatus != null) {
      // If it's already ACTIVE, return it forever (for this session)
      if (isAlreadyActive) {
        AppLogger.info(
          'Returning cached ACTIVE UCC status (permanent for this session)',
          tag: 'UserController',
        );
        return currentStatus;
      }

      // If not active, but within the 5-minute window, return the cache
      if (_lastUccFetchTime != null &&
          now.difference(_lastUccFetchTime!) < _uccCacheDuration) {
        AppLogger.info(
          'Returning cached pending/incomplete UCC status (within 5 min window)',
          tag: 'UserController',
        );
        return currentStatus;
      }
    }

    AppLogger.info(
      'Fetching fresh UCC status (forceRefetch: $forceRefetch)',
      tag: 'UserController',
    );

    try {
      final response = await _uccService.checkUccStatus();
      uccStatusResponse.value = response;
      _lastUccFetchTime = now;
      return response;
    } catch (e) {
      AppLogger.error('Error fetching UCC status: $e', tag: 'UserController');
      rethrow;
    }
  }

  void clearUccCache() {
    uccStatusResponse.value = null;
    _lastUccFetchTime = null;
  }
}
