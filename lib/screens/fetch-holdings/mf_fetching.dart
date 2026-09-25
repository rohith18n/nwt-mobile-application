import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/profile/set_pin.dart';
import 'package:nwt_app/screens/profile/biometrics_setup.dart';
import 'package:nwt_app/screens/fetch-holdings/layouts/layouts.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching_polling.dart';
import 'package:nwt_app/services/mf_onboarding/mf_onboarding_service.dart';
import 'package:nwt_app/services/mf_onboarding/mf_fetching_polling.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Status of each MF process step
enum MFProcessStatus {
  pending, // Step is queued
  processing, // Step is in progress
  completed, // Step finished successfully
  error, // Step failed
}

class MutualFundHoldingsJourneyScreen extends StatefulWidget {
  const MutualFundHoldingsJourneyScreen({
    super.key,
    required this.isInitialJourney,
  });
  final bool isInitialJourney;

  @override
  State<MutualFundHoldingsJourneyScreen> createState() =>
      _MutualFundHoldingsJourneyScreenState();
}

class _MutualFundHoldingsJourneyScreenState
    extends State<MutualFundHoldingsJourneyScreen>
    with CodeAutoFill, TickerProviderStateMixin {
  // Debug flag - set to true to stop after portfolio analysis
  final bool _debugMode = false;
  // Services
  final MFOnboardingService _mfOnboardingService = MFOnboardingService();
  final MfFetchingPollingService _mfFetchingPollingService = MfFetchingPollingService();
  final UserController _userController = Get.find<UserController>();

  // MF Fetching Polling
  Timer? _mfPollingTimer;
  final Duration _mfPollingInterval = const Duration(seconds: 1);
  bool _isPollingActive = false;

  // MF Status tracking
  final RxMap<String, dynamic> _mfcStatus = <String, dynamic>{}.obs;
  final RxString _currentProcessingStep = 'analyzing_portfolio'.obs;

  // Process step status
  final Rx<MFProcessStatus> _analyzingPortfolioStatus =
      MFProcessStatus.pending.obs;
  final Rx<MFProcessStatus> _mfcConnectStatus = MFProcessStatus.pending.obs;
  final Rx<MFProcessStatus> _fetchingDataStatus = MFProcessStatus.pending.obs;
  final Rx<MFProcessStatus> _processingDataStatus = MFProcessStatus.pending.obs;

  // State variables
  DecryptedCASDetails? _casDetails;
  String _token = '';
  int _currentStep = 0;
  bool _isAnimating = false;
  String? _errorMessage;
  bool _hasError = false; // Track if there's an error in starting journey

  // OTP related
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<bool> _fieldFilled = List.generate(6, (index) => false);
  int _activeFieldIndex = 0;
  String get _otpCode => _controllers.map((c) => c.text).join();

  // Animation
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  // Timers
  Timer? _resendTimer;
  Timer? _startingJourneyTimer;
  Timer? _loadingMinimumTimer;

  // Timing control
  int _timeLeft = 60;
  bool _canResendOTP = false;

  // Back press handling variables
  DateTime? _lastBackPressTime;
  static const Duration _backPressTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialJourney();
  }

  void _startMfPolling() {
    if (_isPollingActive) return;
    
    _isPollingActive = true;
    _mfPollingTimer = Timer.periodic(_mfPollingInterval, (_) {
      if (mounted && _isPollingActive) {
        _fetchMfStatus();
      } else {
        _stopMfPolling();
      }
    });
    
    AppLogger.info(
      'Started MF fetching polling every ${_mfPollingInterval.inSeconds} second(s)',
      tag: 'MFJourney',
    );
  }

  void _stopMfPolling() {
    _mfPollingTimer?.cancel();
    _mfPollingTimer = null;
    _isPollingActive = false;
    AppLogger.info('Stopped MF fetching polling', tag: 'MFJourney');
  }

  Future<void> _fetchMfStatus() async {
    try {
      final response = await _mfFetchingPollingService.getMfFetchingStatus(
        onLoading: (isLoading) {
          // Handle loading state if needed
        },
      );
      
      if (response != null && response.data != null) {
        _handleMfStatusUpdate(response);
      }
    } catch (e, subtrace) {
      AppLogger.error('Error fetching MF status: $e',stackTrace: subtrace, tag: 'MFJourney');
      
      // Stop polling when there's an error
      _stopMfPolling();
      
      // Set error state for UI to show skip button
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to fetch MF status: ${e.toString()}';
        });
      }
    }
  }

  void _handleMfStatusUpdate(MfFetchingPolling response) {
    try {
      if (response.data == null) return;

      final data = response.data!;
      
      // Create status map from MF fetching polling response
      Map<String, dynamic> statusMap = {
        'otp': {
          'status': data.otp.status,
          'message': data.otp.message,
        },
        'mfc_connect': {
          'status': data.mfcConnect.status,
          'message': data.mfcConnect.message,
        },
        'fetching_data': {
          'status': data.fetchingData.status,
          'message': data.fetchingData.message,
        },
        'processing_data': {
          'status': data.processingData.status,
          'message': data.processingData.message,
        },
        'analyzing_portfolio': {
          'status': data.analyzingPortfolio.status,
          'message': data.analyzingPortfolio.message,
        },
      };

      _updateMfStatus(statusMap);
      
      // Check if there's any error in the process steps
      if (_hasErrorInStatus(statusMap)) {
        AppLogger.info('Error detected in MF process steps, stopping polling', tag: 'MFJourney');
        _stopMfPolling();
        
        // Set error state for UI
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = _getErrorMessage(statusMap);
          });
        }
      }
      
      // Check if process is complete and stop polling
      if (_isProcessComplete(statusMap)) {
        _stopMfPolling();
      }
    } catch (e) {
      AppLogger.error('Error handling MF status update: $e', tag: 'MFJourney');
    }
  }

  bool _isProcessComplete(Map<String, dynamic> statusMap) {
    // Check if all steps are completed or if there's an error
    final steps = ['otp', 'mfc_connect', 'fetching_data', 'processing_data', 'analyzing_portfolio'];
    
    for (final step in steps) {
      final stepStatus = statusMap[step]?['status'];
      if (stepStatus == 'processing' || stepStatus == 'pending') {
        return false; // Still processing
      }
    }
    
    return true; // All steps are either completed or failed
  }

  bool _hasErrorInStatus(Map<String, dynamic> statusMap) {
    // Check if any step has error status
    final steps = ['otp', 'mfc_connect', 'fetching_data', 'processing_data', 'analyzing_portfolio'];
    
    for (final step in steps) {
      final stepStatus = statusMap[step]?['status'];
      if (stepStatus == 'error' || stepStatus == 'failed') {
        return true;
      }
    }
    
    return false;
  }

  String _getErrorMessage(Map<String, dynamic> statusMap) {
    // Get error message from the first step that has an error
    final steps = ['otp', 'mfc_connect', 'fetching_data', 'processing_data', 'analyzing_portfolio'];
    
    for (final step in steps) {
      final stepStatus = statusMap[step]?['status'];
      final stepMessage = statusMap[step]?['message'];
      
      if (stepStatus == 'error' || stepStatus == 'failed') {
        return stepMessage ?? 'Error in $step step';
      }
    }
    
    return 'Unknown error occurred';
  }


  void _updateMfStatus(Map<String, dynamic> statusMap) {
    if (!mounted) return;

    // Log what data is being updated
    AppLogger.info(
      'Updating MF status with new data: ${json.encode(statusMap)}',
      tag: 'MFJourney',
    );

    // Store previous values for logging changes
    final prevAnalyzingPortfolioStatus = _analyzingPortfolioStatus.value;
    final prevMfcConnectStatus = _mfcConnectStatus.value;
    final prevFetchingDataStatus = _fetchingDataStatus.value;
    final prevProcessingDataStatus = _processingDataStatus.value;
    final prevCurrentStep = _currentProcessingStep.value;

    // Debug mode flag to track if we should stop after portfolio analysis completion
    bool shouldStopForDebug = false;

    // Update the status map
    _mfcStatus.value = statusMap;

    // Update individual step statuses - first step is mfc_connect

    // In debug mode, check if portfolio analysis has just been completed
    if (_debugMode &&
        prevAnalyzingPortfolioStatus != MFProcessStatus.completed &&
        _analyzingPortfolioStatus.value == MFProcessStatus.completed) {
      AppLogger.info(
        '[DEBUG MODE] Portfolio analysis has been completed. Stopping further updates.',
        tag: 'MFJourney',
      );
      shouldStopForDebug = true;
    }

    // Only update subsequent steps if not in debug mode or debug mode hasn't triggered a stop
    if (!shouldStopForDebug) {
      _updateStepStatus('mfc_connect', _mfcConnectStatus);
      _updateStepStatus('fetching_data', _fetchingDataStatus);
      _updateStepStatus('processing_data', _processingDataStatus);
      _updateStepStatus('analyzing_portfolio', _analyzingPortfolioStatus);
    }

    // Log any status changes
    if (prevAnalyzingPortfolioStatus != _analyzingPortfolioStatus.value) {
      AppLogger.info(
        'Portfolio analysis status changed: ${prevAnalyzingPortfolioStatus.name} -> ${_analyzingPortfolioStatus.value.name}',
        tag: 'MFJourney',
      );
    }
    if (prevMfcConnectStatus != _mfcConnectStatus.value) {
      AppLogger.info(
        'MFC Connect status changed: ${prevMfcConnectStatus.name} -> ${_mfcConnectStatus.value.name}',
        tag: 'MFJourney',
      );
    }
    if (prevFetchingDataStatus != _fetchingDataStatus.value) {
      AppLogger.info(
        'Fetching Data status changed: ${prevFetchingDataStatus.name} -> ${_fetchingDataStatus.value.name}',
        tag: 'MFJourney',
      );
    }
    if (prevProcessingDataStatus != _processingDataStatus.value) {
      AppLogger.info(
        'Processing Data status changed: ${prevProcessingDataStatus.name} -> ${_processingDataStatus.value.name}',
        tag: 'MFJourney',
      );
    }

    // Determine current processing step - prioritize the earliest incomplete step
    String newCurrentStep;
    if (_mfcConnectStatus.value != MFProcessStatus.completed) {
      newCurrentStep = 'mfc_connect';
    } else if (_fetchingDataStatus.value != MFProcessStatus.completed) {
      newCurrentStep = 'fetching_data';
    } else if (_processingDataStatus.value != MFProcessStatus.completed) {
      newCurrentStep = 'processing_data';
    } else if (_analyzingPortfolioStatus.value != MFProcessStatus.completed) {
      newCurrentStep = 'analyzing_portfolio';
    } else {
      newCurrentStep = 'completed';
      _navigateToStackedNavbar();
    }

    // Update current step if changed
    if (prevCurrentStep != newCurrentStep) {
      _currentProcessingStep.value = newCurrentStep;
      AppLogger.info(
        'Current processing step changed: $prevCurrentStep -> $newCurrentStep',
        tag: 'MFJourney',
      );
    }

    // Update UI based on current step
    _updateUIForCurrentStep();
  }

  void _updateStepStatus(String stepKey, Rx<MFProcessStatus> statusRx) {
    if (!_mfcStatus.containsKey(stepKey)) return;

    final stepData = _mfcStatus[stepKey];
    if (stepData == null || !stepData.containsKey('status')) return;

    final status = stepData['status'];
    switch (status) {
      case 'pending':
        statusRx.value = MFProcessStatus.pending;
        break;
      case 'processing':
        statusRx.value = MFProcessStatus.processing;
        break;
      case 'completed':
        statusRx.value = MFProcessStatus.completed;
        break;
      case 'error':
        statusRx.value = MFProcessStatus.error;
        break;
      default:
        AppLogger.warning(
          'Unknown status value: $status for step $stepKey',
          tag: 'MFJourney',
        );
    }
  }

  void _updateUIForCurrentStep() {
    if (!mounted) return;

    // If we're still on the OTP screen and OTP is completed, move to the next step
    if (_currentStep == 1 &&
        _analyzingPortfolioStatus.value == MFProcessStatus.completed) {
      _navigateToStep(2); // Move to loading layout
    }

    // If we're on the loading screen, update the message based on current step
    if (_currentStep == 2) {
      setState(() {}); // Refresh UI to show current step message
    }
  }

  void _navigateToStackedNavbar() {
    // If in debug mode, don't navigate away from the loading screen
    if (_debugMode) {
      AppLogger.info(
        '[DEBUG MODE] Navigation to dashboard prevented due to debug mode',
        tag: 'MFJourney',
      );
      return;
    }

    // Only navigate if we're not already navigating
    if (_loadingMinimumTimer != null) return;

    // Ensure we wait at least 2 seconds before navigating
    _loadingMinimumTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        if (!widget.isInitialJourney) {
          // Continue with the original flow to dashboard
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        } else {
          // For non-initial journey, navigate to SetPin screen
          _navigateToSetPin();
        }
      }
    });
  }

  // Navigate to SetPin screen with option to skip
  void _navigateToSetPin() {
    // Get the user's phone number from the controller
    final phoneNumber = _userController.userData?.phonenumber ?? '';

    Get.offAll(
      () => SetPin(
        phoneNumber: phoneNumber,
        showSkipOption: true,
        onSkip: () {
          // When skipped, navigate directly to dashboard
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        },
        onComplete: () {
          // After PIN is set, check for biometrics
          _checkBiometrics();
        },
      ),
      transition: Transition.rightToLeft,
    );
  }

  // Check if biometrics should be enabled
  void _checkBiometrics() {
    // Navigate to biometrics setup screen
    Get.to(
      () => BiometricsSetupScreen(
        showSkipOption: true,
        onSkip: () {
          // When skipped, navigate directly to dashboard
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        },
        onComplete: () {
          // When biometrics setup is complete, navigate to dashboard
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        },
      ),
      transition: Transition.rightToLeft,
    );
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      6,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations =
        _animationControllers
            .map(
              (controller) => Tween<double>(begin: 1.0, end: 1.2).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeInOut),
              ),
            )
            .toList();
  }

  void _startInitialJourney() {
    // Show starting layout for 5 seconds
    _startingJourneyTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_hasError) {
        // Only navigate if there's no error
        _navigateToStep(1); // Move to OTP layout
      }
    });
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    // Stop MF polling
    _stopMfPolling();
    
    // Dispose all text editing controllers
    for (final controller in _controllers) {
      controller.dispose();
    }

    // Dispose all focus nodes
    for (final node in _focusNodes) {
      node.dispose();
    }

    // Dispose all animation controllers
    for (final controller in _animationControllers) {
      controller.dispose();
    }

    // Cancel all timers
    _resendTimer?.cancel();
    _startingJourneyTimer?.cancel();
    _loadingMinimumTimer?.cancel();

    // Cancel any pending auto-fill operations
    cancel();
  }

  // OTP Auto-fill
  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      _autoFillOtp(code!);
    }
  }

  void _autoFillOtp(String otp) {
    if (otp.length != 6) return;

    // Clear existing OTP
    for (int i = 0; i < 6; i++) {
      _controllers[i].clear();
      _fieldFilled[i] = false;
    }

    // Fill OTP with animation
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (!mounted) return;

        setState(() {
          _controllers[i].text = otp[i];
          _fieldFilled[i] = true;
          _activeFieldIndex = i;
          _animationControllers[i].forward().then(
            (_) => _animationControllers[i].reverse(),
          );
        });

        // Auto-submit when all fields are filled
        if (i == 5) {
          _verifyOTP(otp);
        }
      });
    }
  }

  // OTP Verification
  Future<void> _verifyOTP(String otp) async {
    if (_casDetails == null || otp.length != 6) return;

    setState(() => _errorMessage = null);

    // Update OTP status to processing
    _analyzingPortfolioStatus.value = MFProcessStatus.processing;

    try {
      final result = await _mfOnboardingService.verifyOTP(
        token: _token,
        casDetails: _casDetails!,
        otp: otp,
        onLoading: (_) {},
        onError:
            (message, statusCode) =>
                _handleVerificationError(message, statusCode),
      );

      if (result?.success == true) {
        // Mark verification as completed
        // Set mfc_connect as the first step in the new flow
        _currentProcessingStep.value = 'mfc_connect';
        _mfcConnectStatus.value = MFProcessStatus.processing;

        // Handle verification success
        _handleVerificationSuccess(result!);
      } else {
        // Mark OTP verification as failed
        _analyzingPortfolioStatus.value = MFProcessStatus.error;
        _handleVerificationError(result?.message, null);
      }
    } catch (e) {
      // Mark OTP verification as failed
      _analyzingPortfolioStatus.value = MFProcessStatus.error;
      _handleVerificationError('An unexpected error occurred', null);

      AppLogger.error('Error during OTP verification: $e', tag: 'MFJourney');
    }
  }

  Future<void> _handleVerificationSuccess(
    MfCentralVerifyOtpResponse result,
  ) async {
    if (!mounted) return;

    // Update UI to show loading layout
    setState(() {
      _currentStep = 2; // Show loading layout
    });

    // Start MF polling now that OTP verification is successful
    _startMfPolling();

    // Log successful OTP verification
    AppLogger.info(
      'OTP verification successful, starting MF data fetching polling',
      tag: 'MFJourney',
    );

    // The navigation to dashboard will now be handled by the MF polling updates
    // based on the processing status of all steps
  }


  void _handleVerificationError(String? message, int? statusCode) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message ?? 'Failed to verify OTP. Please try again.';
      _currentStep = 1; // Go back to OTP screen
    });
  }

  // Navigation
  void _navigateToStep(int step) {
    if (_isAnimating ||
        step == _currentStep ||
        step < 0 ||
        step > 2 ||
        !mounted) {
      return;
    }

    setState(() => _isAnimating = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _currentStep = step;
        _isAnimating = false;
      });

      if (step == 1) {
        _setupSmsListener();
        _startResendTimer();
      }
    });
  }

  // SMS Listener
  Future<void> _setupSmsListener() async {
    try {
      await SmsAutoFill().getAppSignature;
      listenForCode();
    } catch (e) {
      debugPrint('SMS Listener Error: $e');
    }
  }

  // OTP Resend
  void _startResendTimer() {
    if (!mounted) return;

    setState(() {
      _timeLeft = 60;
      _canResendOTP = false;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResendOTP || !mounted) return;

    setState(() => _errorMessage = null);

    try {
      final result = await _mfOnboardingService.sendOTP(
        onLoading: (_) {},
        onError:
            (message, statusCode, stage, panNumber) => setState(() => _errorMessage = message),
      );

      if (mounted && result.data?.decryptedcasdetails != null) {
        setState(() {
          _casDetails = result.data!.decryptedcasdetails;
          _token = result.data!.token;
        });
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to resend OTP');
      }
    }
  }

  // Error handling for starting journey
  void _handleStartingJourneyError() {
    if (mounted) {
      setState(() {
        _hasError = true;
      });
      // Cancel the timer to prevent auto-navigation
      _startingJourneyTimer?.cancel();
    }
  }

  // Success handling for starting journey
  void _handleStartingJourneySuccess(
    DecryptedCASDetails? details,
    String token,
  ) {
    if (details != null && mounted) {
      setState(() {
        _casDetails = details;
        _token = token;
        _hasError = false; // Clear any previous error state
      });
    }
  }

  // Step Navigation Helpers
  void _goToNextStep() {
    if (_currentStep < 2) _navigateToStep(_currentStep + 1);
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) _navigateToStep(_currentStep - 1);
  }

  void _skipToStackedNavbar() {
    // If in debug mode, don't navigate away from the loading screen
    if (_debugMode) {
      AppLogger.info(
        '[DEBUG MODE] Skip to dashboard prevented due to debug mode',
        tag: 'MFJourney',
      );
      return;
    }

    Get.offAll(() => StackedNavbar(selectedIdx: 0));
  }

  // Retry from error - reset error state and restart the journey
  void _retryStartingJourney() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      _startInitialJourney(); // Restart the timer
    }
  }

  // Method to handle back press with double-tap to exit
  Future<bool> _onWillPop() async {
    final DateTime now = DateTime.now();

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > _backPressTimeout) {
      // First back press or timeout exceeded
      _lastBackPressTime = now;

      // Show snackbar message
      Get.showSnackbar(
        GetSnackBar(
          message: 'Press back again to exit',
          duration: _backPressTimeout,
          backgroundColor: Colors.black87,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          snackPosition: SnackPosition.BOTTOM,
        ),
      );

      return false; // Don't exit
    }

    SystemNavigator.pop();
    return true;
  }

  // UI Builders
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(body: SafeArea(child: _buildCurrentStep())),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return StartingJourneyLayout(
          isAnimating: _isAnimating,
          onNext: _goToNextStep,
          onSkip: _skipToStackedNavbar,
          onCasDetailsReceived: _handleStartingJourneySuccess,
          onError:
              _handleStartingJourneyError, // Uncommented - Add error handler
          onRetry: _retryStartingJourney, // Uncommented - Add retry handler
        );
      case 1:
        return OtpVerificationLayout(
          isAnimating: _isAnimating,
          canResendOTP: _canResendOTP,
          timeLeft: _timeLeft,
          activeFieldIndex: _activeFieldIndex,
          fieldFilled: _fieldFilled,
          controllers: _controllers,
          focusNodes: _focusNodes,
          scaleAnimations: _scaleAnimations,
          otpCode: _otpCode,
          onVerifyOTP: _verifyOTP,
          onResendOTP: _resendOTP,
          onPrevious: _goToPreviousStep,
          onNext: _goToNextStep,
          errorMessage: _errorMessage,
          casDetails: _casDetails,
        );
      case 2:
        return LoadingLayout(
          onPrevious: _goToPreviousStep,
          onError: _stopMfPolling,
          currentStep: _currentProcessingStep.value,
          analyzingPortfolioStatus: _analyzingPortfolioStatus.value,
          mfcConnectStatus: _mfcConnectStatus.value,
          fetchingDataStatus: _fetchingDataStatus.value,
          processingDataStatus: _processingDataStatus.value,
          isInitialJourney: widget.isInitialJourney,
          debugMode:
              _debugMode, // Enable debug mode to stop after portfolio analysis
        );
      default:
        return StartingJourneyLayout(
          isAnimating: _isAnimating,
          onNext: _goToNextStep,
          onSkip: _skipToStackedNavbar,
          onCasDetailsReceived: _handleStartingJourneySuccess,
          onError: _handleStartingJourneyError, // Uncommented
          onRetry: _retryStartingJourney, // Uncommented
        );
    }
  }
}
