import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/screens/profile/set_pin.dart';

class LoadingLayout extends StatefulWidget {
  final VoidCallback onPrevious;
  final VoidCallback? onComplete;
  final VoidCallback? onError;
  final String? token;
  final String currentStep;
  final MFProcessStatus analyzingPortfolioStatus;
  final MFProcessStatus mfcConnectStatus;
  final MFProcessStatus fetchingDataStatus;
  final MFProcessStatus processingDataStatus;
  final bool debugMode;
  final bool isInitialJourney;

  const LoadingLayout({
    super.key,
    required this.onPrevious,
    this.onComplete,
    this.onError,
    this.token,
    this.currentStep = 'mfc_connect',
    this.analyzingPortfolioStatus = MFProcessStatus.pending,
    this.mfcConnectStatus = MFProcessStatus.pending,
    this.fetchingDataStatus = MFProcessStatus.pending,
    this.processingDataStatus = MFProcessStatus.pending,
    this.debugMode = false,
    this.isInitialJourney = false,
  });

  @override
  State<LoadingLayout> createState() => _LoadingLayoutState();
}

class _LoadingLayoutState extends State<LoadingLayout> {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  Timer? _redirectTimer;
  Timer? _timeoutTimer;
  bool _isRedirecting = false;
  bool _dataReceived = false;
  bool _isLoading = false;

  // Auth service for updating user profile
  final _authService = AuthService();

  // Skip button only shown on error
  bool _showSkipButton = false;

  // No need to store previous statuses as we're comparing with oldWidget in didUpdateWidget

  // Messages for each step of the process
  final Map<String, List<String>> _stepMessages = {
    'analyzing_portfolio': ["Evaluating your\ninvestments"],
    'mfc_connect': ["Connecting to\nMF Central"],
    'fetching_data': ["Retrieving your\nportfolio data"],
    'processing_data': ["Building your financial\npersona & advisory"],
    'completed': ["All done!\nPreparing your dashboard"],
  };

  List<String> get _currentStepMessages {
    return _stepMessages[widget.currentStep] ?? _stepMessages['mfc_connect']!;
  }

  String get _currentMessage {
    if (_currentMessageIndex >= _currentStepMessages.length) {
      return _currentStepMessages.last;
    }
    return _currentStepMessages[_currentMessageIndex];
  }

  @override
  void initState() {
    super.initState();

    // Skip button will only be shown when there's an error

    // No need to initialize previous statuses as we're comparing with oldWidget in didUpdateWidget

    // Log the initial step statuses with timestamp
    _logStepStatus('INITIALIZATION', widget.currentStep, {
      'MFC': widget.mfcConnectStatus,
      'Fetch': widget.fetchingDataStatus,
      'Process': widget.processingDataStatus,
      'Analyze': widget.analyzingPortfolioStatus,
    });

    // Check if any step is already completed
    _checkCompletedSteps();

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          if (_currentMessageIndex < _currentStepMessages.length - 1) {
            _currentMessageIndex++;
          } else {
            // Keep the last message displayed
            _currentMessageIndex = _currentStepMessages.length - 1;
          }
        });
      }
    });
    AppLogger.info(
      'Skip verification option shown - _hasError: $_hasError, _showSkipButton: $_showSkipButton, '
      'mfcConnectStatus: ${widget.mfcConnectStatus}, '
      'fetchingDataStatus: ${widget.fetchingDataStatus}, '
      'processingDataStatus: ${widget.processingDataStatus}, '
      'analyzingPortfolioStatus: ${widget.analyzingPortfolioStatus}',
      tag: 'LoadingLayoussst',
    );

    // Only set timeout timers if we're not already completed
    if (widget.currentStep != 'completed' &&
        widget.processingDataStatus != MFProcessStatus.completed) {
      _redirectTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && !_isRedirecting && !_dataReceived) {
          _logStepStatus('WAITING', widget.currentStep, {
            'MFC': widget.mfcConnectStatus,
            'Fetch': widget.fetchingDataStatus,
            'Process': widget.processingDataStatus,
            'Analyze': widget.analyzingPortfolioStatus,
          });
        }
      });

      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_isRedirecting && !_dataReceived) {
          setState(() {});
          _logStepStatus('TIMEOUT', widget.currentStep, {
            'MFC': widget.mfcConnectStatus,
            'Fetch': widget.fetchingDataStatus,
            'Process': widget.processingDataStatus,
            'Analyze': widget.analyzingPortfolioStatus,
          });
        }
      });
    }
  }

  // Helper method to get formatted timestamp
  String _getFormattedTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
  }

  // Helper method to log step status with timestamp
  void _logStepStatus(
    String event,
    String currentStep,
    Map<String, MFProcessStatus> statuses,
  ) {
    final timestamp = _getFormattedTimestamp();
    AppLogger.info(
      '[$timestamp] $event | Current Step: $currentStep | '
      'MFC: ${statuses['MFC']} | Fetch: ${statuses['Fetch']} | '
      'Process: ${statuses['Process']} | Analyze: ${statuses['Analyze']}',
      tag: 'LoadingLayout',
    );
  }

  // Check if any steps are already completed and update the UI accordingly
  void _checkCompletedSteps() {
    // Mark data as received if processing data is completed
    if (widget.processingDataStatus == MFProcessStatus.completed) {
      _dataReceived = true;
      _logStepStatus('COMPLETED_CHECK', widget.currentStep, {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
    }

    // If current step is 'completed', mark as redirecting
    if (widget.currentStep == 'completed') {
      _isRedirecting = true;
      _logStepStatus('ALL_COMPLETED', 'completed', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
    }

    // Log individual completed steps
    if (widget.mfcConnectStatus == MFProcessStatus.completed) {
      _logStepStatus('STEP_COMPLETED', 'mfc_connect', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
    }

    if (widget.fetchingDataStatus == MFProcessStatus.completed) {
      _logStepStatus('STEP_COMPLETED', 'fetching_data', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _redirectTimer?.cancel();
    _timeoutTimer?.cancel();

    _logStepStatus('DISPOSED', widget.currentStep, {
      'MFC': widget.mfcConnectStatus,
      'Fetch': widget.fetchingDataStatus,
      'Process': widget.processingDataStatus,
      'Analyze': widget.analyzingPortfolioStatus,
    });

    super.dispose();
  }

  @override
  void didUpdateWidget(LoadingLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for status changes and log them
    if (oldWidget.analyzingPortfolioStatus != widget.analyzingPortfolioStatus) {
      _logStepStatus('STATUS_CHANGE', 'analyzing_portfolio', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
      
      // Check if this step changed to error state
      if (widget.analyzingPortfolioStatus == MFProcessStatus.error) {
        _handleError();
      }
    }

    if (oldWidget.mfcConnectStatus != widget.mfcConnectStatus) {
      _logStepStatus('STATUS_CHANGE', 'mfc_connect', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
      
      // Check if this step changed to error state
      if (widget.mfcConnectStatus == MFProcessStatus.error) {
        _handleError();
      }
    }

    if (oldWidget.fetchingDataStatus != widget.fetchingDataStatus) {
      _logStepStatus('STATUS_CHANGE', 'fetching_data', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
      
      // Check if this step changed to error state
      if (widget.fetchingDataStatus == MFProcessStatus.error) {
        _handleError();
      }
    }

    if (oldWidget.processingDataStatus != widget.processingDataStatus) {
      _logStepStatus('STATUS_CHANGE', 'processing_data', {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });
      
      // Check if this step changed to error state
      if (widget.processingDataStatus == MFProcessStatus.error) {
        _handleError();
      }

      // If processing is completed, mark data as received
      if (widget.processingDataStatus == MFProcessStatus.completed) {
        _dataReceived = true;
        _logStepStatus('DATA_RECEIVED', widget.currentStep, {
          'MFC': widget.mfcConnectStatus,
          'Fetch': widget.fetchingDataStatus,
          'Process': widget.processingDataStatus,
          'Analyze': widget.analyzingPortfolioStatus,
        });
      }
    }

    if (oldWidget.currentStep != widget.currentStep) {
      _logStepStatus('STEP_CHANGE', widget.currentStep, {
        'MFC': widget.mfcConnectStatus,
        'Fetch': widget.fetchingDataStatus,
        'Process': widget.processingDataStatus,
        'Analyze': widget.analyzingPortfolioStatus,
      });

      // Reset message index when step changes
      _currentMessageIndex = 0;

      // If current step is 'completed', mark as redirecting
      if (widget.currentStep == 'completed') {
        _isRedirecting = true;
        _logStepStatus('REDIRECTING', 'completed', {
          'MFC': widget.mfcConnectStatus,
          'Fetch': widget.fetchingDataStatus,
          'Process': widget.processingDataStatus,
          'Analyze': widget.analyzingPortfolioStatus,
        });
      }
    }
  }

  // Helper method to check if any process step is in error state
  bool get _hasError {
    AppLogger.info(
      'Checking for errors in loading layout' +
          widget.mfcConnectStatus.toString() +
          widget.fetchingDataStatus.toString() +
          widget.processingDataStatus.toString() +
          widget.analyzingPortfolioStatus.toString(),
      tag: 'LoadingLayout',
    );
    return widget.mfcConnectStatus == MFProcessStatus.error ||
        widget.fetchingDataStatus == MFProcessStatus.error ||
        widget.processingDataStatus == MFProcessStatus.error ||
        widget.analyzingPortfolioStatus == MFProcessStatus.error;
  }

  // Handle error state - stop polling and show skip button
  void _handleError() {
    AppLogger.info('Error detected in MF process, stopping polling', tag: 'LoadingLayout');
    
    // Call the onError callback to stop polling in parent
    if (widget.onError != null) {
      widget.onError!();
    }
    
    // Show skip button
    if (mounted) {
      setState(() {
        _showSkipButton = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Debug panel - only visible in debug mode
            if (widget.debugMode) _buildDebugPanel(),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animation based on current step
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(200 / 2),
                  ),
                  height: 200,
                  width: 200,
                  child: Lottie.asset(
                    _getLottieAssetForStep(widget.currentStep),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress indicators for each step
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator('MFC', widget.mfcConnectStatus),
                      _buildStepConnector(),
                      _buildStepIndicator('Fetch', widget.fetchingDataStatus),
                      _buildStepConnector(),
                      _buildStepIndicator(
                        'Process',
                        widget.processingDataStatus,
                      ),
                      _buildStepConnector(),
                      _buildStepIndicator(
                        'Analyze',
                        widget.analyzingPortfolioStatus,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Current step message
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: AppText(
                          key: ValueKey<String>(
                            '${widget.currentStep}_$_currentMessageIndex',
                          ),
                          _currentMessage,
                          variant: AppTextVariant.headline4,
                          weight: AppTextWeight.bold,
                          textAlign: TextAlign.center,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 500),
                      child: AppText(
                        _getSubtitleForStep(widget.currentStep),
                        variant: AppTextVariant.bodyLarge,
                        colorType: AppTextColorType.muted,
                        textAlign: TextAlign.center,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),

                // Show skip option only if any process step is in error state
                if (_hasError) ...[
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkCardBG
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkInputBorder
                                : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            AppText(
                              "Having trouble with verification?",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          "You can skip this step and continue using the app without MF Central verification.",
                          variant: AppTextVariant.bodySmall,
                          lineHeight: 1.4,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap:
                              _isLoading ? null : () => _skipMFCVerification(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  "Skip Verification",
                                  variant: AppTextVariant.bodySmall,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 16,
                                ),
                                if (_isLoading) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Icons.lock_outline_rounded, size: 20),
                AppText(
                  "Your data is encrypted and 100% secure",
                  variant: AppTextVariant.headline6,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppText(
              "Fetching data from MF Central to analyses your Mutual Funds as a SEBI Registered Investment Advisor - INA000020396",
              variant: AppTextVariant.bodySmall,
              colorType: AppTextColorType.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getLottieAssetForStep(String step) {
    switch (step) {
      case 'mfc_connect':
        return 'assets/lottie/contacting_mfc.json';
      case 'fetching_data':
        return 'assets/lottie/fetching_mfc.json';
      case 'processing_data':
        return 'assets/lottie/processing_mfc.json';
      case 'analyzing_portfolio':
        return 'assets/lottie/analyzing_mfc.json';
      case 'completed':
        return 'assets/lottie/analyzing_mfc.json';
      default:
        return 'assets/lottie/pan.json';
    }
  }

  String _getSubtitleForStep(String step) {
    switch (step) {
      case 'mfc_connect':
        return "Establishing secure connection to MF Central";
      case 'fetching_data':
        return "This may take a few moments";
      case 'processing_data':
        return "Almost there, finalizing your data";
      case 'analyzing_portfolio':
        return "Evaluating your investment performance";
      case 'completed':
        return "Redirecting to dashboard";
      default:
        return "This may take a few moments";
    }
  }

  Widget _buildStepIndicator(String label, MFProcessStatus status) {
    Color color;
    IconData icon;
    bool isCurrentStep = false;

    // Check if this is the current step based on widget.currentStep
    if ((label == 'MFC' && widget.currentStep == 'mfc_connect') ||
        (label == 'Fetch' && widget.currentStep == 'fetching_data') ||
        (label == 'Process' && widget.currentStep == 'processing_data') ||
        (label == 'Analyze' && widget.currentStep == 'analyzing_portfolio')) {
      isCurrentStep = true;
    }

    switch (status) {
      case MFProcessStatus.pending:
        color = Colors.grey;
        icon = Icons.circle_outlined;
        break;
      case MFProcessStatus.processing:
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case MFProcessStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case MFProcessStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
    }

    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (isCurrentStep)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            label,
            variant: AppTextVariant.caption,
            colorType:
                status == MFProcessStatus.pending
                    ? AppTextColorType.muted
                    : AppTextColorType.primary,
            weight:
                isCurrentStep || status == MFProcessStatus.processing
                    ? AppTextWeight.bold
                    : AppTextWeight.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 15,
      height: 1,
      color: Colors.grey.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 15),
    );
  }

  // Debug panel with status information and manual check button
  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'DEBUG MODE ACTIVE',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.error,
              ),
              const Icon(Icons.bug_report, color: Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          const AppText(
            'Debug mode active - monitoring process status.',
            variant: AppTextVariant.bodySmall,
          ),
          const SizedBox(height: 5),
          AppText(
            'Current timestamp: ${_getFormattedTimestamp()}',
            variant: AppTextVariant.caption,
            colorType: AppTextColorType.muted,
          ),
          const SizedBox(height: 10),
          _buildStatusRow('MFC Connect', widget.mfcConnectStatus),
          _buildStatusRow('Fetching Data', widget.fetchingDataStatus),
          _buildStatusRow('Processing Data', widget.processingDataStatus),
          _buildStatusRow(
            'Analyzing Portfolio',
            widget.analyzingPortfolioStatus,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Log current status
                  _logStepStatus('MANUAL_CHECK', widget.currentStep, {
                    'MFC': widget.mfcConnectStatus,
                    'Fetch': widget.fetchingDataStatus,
                    'Process': widget.processingDataStatus,
                    'Analyze': widget.analyzingPortfolioStatus,
                  });

                  // Show status in a snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Status logged. Check console for details.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to skip MFC verification and navigate to appropriate screen
  void _skipMFCVerification() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update user's skipmfc field to true
      final success = await _authService.updateUserField('skipmfc', true);

      if (success) {
        if (widget.isInitialJourney) {
          // Navigate to set pin screen for initial journey
          Get.offAll(
            () => const SetPin(phoneNumber: '', showSkipOption: false),
          );
        } else {
          // Navigate to dashboard for non-initial journey
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error skipping MFC verification',
        error: e,
        tag: 'LoadingLayout',
      );
    }
  }

  // Helper to build status row for debug panel
  Widget _buildStatusRow(String label, MFProcessStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case MFProcessStatus.pending:
        statusColor = Colors.grey;
        statusText = 'Pending';
        break;
      case MFProcessStatus.processing:
        statusColor = Colors.blue;
        statusText = 'Processing';
        break;
      case MFProcessStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case MFProcessStatus.error:
        statusColor = Colors.red;
        statusText = 'Error';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, variant: AppTextVariant.bodySmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: AppText(
              statusText,
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.primary,
              customColor: statusColor, // Override with custom color
              weight: AppTextWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
