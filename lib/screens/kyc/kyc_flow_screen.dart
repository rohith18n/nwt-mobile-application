import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/kyc/kyc_success_screen.dart';
import 'package:nwt_app/screens/kyc/kyc_webview_screen.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/kyc/kyc_kra_state.dart';
import 'package:nwt_app/services/kyc/kyc_service.dart';
import 'package:nwt_app/services/kyc/kyc_state_helper.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

const String _logTag = 'KycFlowScreen';

enum _KycFlowState {
  idle,
  loading,
  error,
  kycNotRequired,
  webviewOpen,
  navigatingToSuccess,
  waitingForKycCompletion,
  pollingExhausted,
}

class KycFlowScreen extends StatefulWidget {
  /// Optional phone captured by a prerequisite guard. This value should only be persisted
  /// after `/kyc/initiate` succeeds (HTTP 200), to avoid blindly updating phone on backend.
  final String? capturedPhoneNumber;

  const KycFlowScreen({
    super.key,
    this.capturedPhoneNumber,
  });

  @override
  State<KycFlowScreen> createState() => _KycFlowScreenState();
}

class _KycFlowScreenState extends State<KycFlowScreen> {
  final KycService _kycService = KycService();
  final KycStateHelper _stateHelper = KycStateHelper();
  late final UserController _userController;

  _KycFlowState _state = _KycFlowState.idle;
  String _errorMessage = '';
  String _kycNotRequiredReason = '';
  bool _navigatedToSuccess = false;

  /// Used when initiate returns "already initiated" (no URL, message only).
  String _alreadyInitiatedMessage = '';
  Timer? _pollTimer;
  int _pollAttempts = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserController>()) {
      _userController = Get.find<UserController>();
    } else {
      _userController = Get.put(UserController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  Future<void> _maybeUpdatePhoneAfterInitiateSuccess() async {
    final phone = (widget.capturedPhoneNumber ?? '').trim();
    if (phone.isEmpty) return;

    // Mirror Finarkein behavior: only update if the user is an email user without a primary phone.
    var user = _userController.userData;
    if (user == null) {
      await _userController.fetchUserProfile(onLoading: (_) {});
      user = _userController.userData;
    }
    if (user == null) return;

    final isEmailUserWithoutPhone =
        (user.email ?? '').trim().isNotEmpty &&
        (user.phonenumber == null || (user.phonenumber ?? '').trim().isEmpty);
    if (!isEmailUserWithoutPhone) return;

    final updated = await AuthService().updatePhone(phonenumber: phone);
    if (updated) {
      await _userController.fetchUserProfile(onLoading: (_) {});
      AppLogger.info(
        'KYC: updated primary phone for email user after /kyc/initiate success',
        tag: _logTag,
      );
    } else {
      AppLogger.warning(
        'KYC: updatePhone failed after /kyc/initiate success (non-blocking)',
        tag: _logTag,
      );
    }
  }

  Future<void> _evaluate() async {
    if (!mounted) return;
    setState(() {
      _state = _KycFlowState.loading;
      _errorMessage = '';
    });

    final result = await _kycService.evaluateKycNeed();
    if (!mounted) return;

    if (!result.isKycRequired) {
      setState(() {
        _state = _KycFlowState.kycNotRequired;
        _kycNotRequiredReason = result.reason;
      });
      AppLogger.info('KYC not required: ${result.reason}', tag: _logTag);
      return;
    }

    await _startFlow();
  }

  Future<void> _startFlow() async {
    if (!mounted) return;
    setState(() {
      _state = _KycFlowState.loading;
      _errorMessage = '';
    });

    final result = await _kycService.initiateKyc();
    if (!mounted) return;

    if (result.isAlreadyInitiatedResponse) {
      // `/kyc/initiate` succeeded (HTTP 200) but returned "already initiated".
      // Update phone only after initiate success, then continue.
      await _maybeUpdatePhoneAfterInitiateSuccess();
      await AuthService().updateOnboardingProgress(
        flowType: OnboardingFlowType.completeKyc.apiValue,
        status: 'in_progress',
      );
      _alreadyInitiatedMessage = result.displayMessage;
      // Store in preferences so Dashboard shows "In progress" and KYC banner below app bar.
      _stateHelper.setAlreadyInitiatedInProgress(_alreadyInitiatedMessage);
      setState(() {
        _state = _KycFlowState.waitingForKycCompletion;
        _pollAttempts = 0;
      });
      _startPolling();
      AppLogger.info(
        'KYC already initiated; status stored for dashboard; polling in background',
        tag: _logTag,
      );
      return;
    }

    if (!result.success) {
      final message = result.errorMessage?.trim();
      setState(() {
        _state = _KycFlowState.error;
        _errorMessage = message != null && message.isNotEmpty
            ? message
            : 'Unable to start KYC.';
      });
      AppLogger.warning('KYC initiate failed: $_errorMessage', tag: _logTag);
      return;
    }

    if (!result.hasValidUrl) {
      setState(() {
        _state = _KycFlowState.error;
        _errorMessage = 'Invalid onboarding URL. Please try again.';
      });
      return;
    }

    // `/kyc/initiate` succeeded and returned a valid onboarding URL.
    await _maybeUpdatePhoneAfterInitiateSuccess();
    await AuthService().updateOnboardingProgress(
      flowType: OnboardingFlowType.completeKyc.apiValue,
      status: 'in_progress',
    );

    _stateHelper.setJourneyStartedAt();
    setState(() => _state = _KycFlowState.webviewOpen);
    final journeyUrl = result.kycOnboardingUrl!;
    AppLogger.info(
      'KYC opening WebView urlLength=${journeyUrl.length} scheme=${Uri.tryParse(journeyUrl)?.scheme ?? "invalid"}',
      tag: _logTag,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => KycWebViewScreen(
          journeyUrl: journeyUrl,
          onClose: () {},
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _state = _KycFlowState.navigatingToSuccess);

    final verifyResult = await _kycService.verifyPanStatus();
    if (!mounted) return;

    if (!verifyResult.success) {
      _backToDashboard();
      final verifyErrorMsg = verifyResult.errorMessage?.trim();
      final fallbackMsg = messageForKycKraState(KycKraDisplayState.unknown, forErrorScreen: true);
      SnackbarHelper.showError(
        title: 'KYC',
        message: verifyErrorMsg != null && verifyErrorMsg.isNotEmpty
            ? verifyErrorMsg
            : fallbackMsg,
      );
      return;
    }

    _stateHelper.setLastVerifiedStatus(verifyResult.statusForPersistence);

    if (verifyResult.isKycCompleted) {
      _stateHelper.clearJourneyStartedAt();
      if (!_navigatedToSuccess) {
        _navigatedToSuccess = true;
        Get.to(
          () => KycSuccessScreen(),
          transition: Transition.rightToLeft,
        );
      }
      return;
    }

    _backToDashboard();
    final snackbarMessage = messageForKycKraState(verifyResult.kraDisplayState, forSnackbar: true);
    SnackbarHelper.showInfo(title: 'KYC', message: snackbarMessage);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(kycPollInterval, _onPoll);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _onPoll(Timer timer) {
    if (_pollAttempts >= kycMaxPollAttempts) {
      _stopPolling();
      if (!mounted) return;
      _stateHelper.clearAlreadyInitiatedInProgress();
      setState(() => _state = _KycFlowState.pollingExhausted);
      AppLogger.info('KYC polling stopped: max attempts reached', tag: _logTag);
      return;
    }
    _pollAttempts++;
    _kycService.verifyPanStatus().then((verifyResult) {
      if (!mounted) return;
      if (verifyResult.success) {
        _stateHelper.setLastVerifiedStatus(verifyResult.statusForPersistence);
      }
      if (verifyResult.isValidated) {
        _stopPolling();
        _stateHelper.clearAlreadyInitiatedInProgress();
        _stateHelper.clearJourneyStartedAt();
        if (!_navigatedToSuccess) {
          _navigatedToSuccess = true;
          Get.to(
            () => const KycSuccessScreen(),
            transition: Transition.rightToLeft,
          );
        }
        AppLogger.info('KYC validated via polling (already-initiated flow)', tag: _logTag);
      }
    }).catchError((e) {
      AppLogger.warning('KYC poll error: $e', tag: _logTag);
    });
  }

  void _backToDashboard() {
    _stopPolling();
    Get.offAll(
      () => StackedNavbar(selectedIdx: 0),
      transition: Transition.rightToLeft,
    );
  }

  @override
  void dispose() {
    _stopPolling();
    // Do not use context here - widget may be deactivated; looking up ancestor is unsafe.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCardBG,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _backToDashboard,
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            const AppText(
              'KYC',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _KycFlowState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.lightPrimary),
              SizedBox(height: 16),
              AppText(
                'Checking KYC status...',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
            ],
          ),
        );

      case _KycFlowState.error:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              AppText(
                _errorMessage,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    text: 'Retry',
                    onPressed: () => _startFlow(),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _backToDashboard,
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ],
          ),
        );

      case _KycFlowState.kycNotRequired:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              AppText(
                _kycNotRequiredReason,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Back to Dashboard',
                onPressed: _backToDashboard,
              ),
            ],
          ),
        );

      case _KycFlowState.webviewOpen:
      case _KycFlowState.navigatingToSuccess:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.lightPrimary),
              SizedBox(height: 16),
              AppText(
                'Completing KYC...',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
            ],
          ),
        );

      case _KycFlowState.waitingForKycCompletion:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 48, color: AppColors.lightPrimary),
              const SizedBox(height: 16),
              const AppText(
                "Your KYC was already initiated. We'll notify you when it's verified.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Back to Dashboard',
                onPressed: _backToDashboard,
              ),
            ],
          ),
        );

      case _KycFlowState.pollingExhausted:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 48, color: AppColors.lightPrimary),
              const SizedBox(height: 16),
              const AppText(
                "We're still verifying your KYC. Please check back later.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Back to Dashboard',
                onPressed: _backToDashboard,
              ),
            ],
          ),
        );

      case _KycFlowState.idle:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.lightPrimary),
        );
    }
  }
}
