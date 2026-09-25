import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/fetch-holdings/layouts/error_layout.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_flow_retry.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching.dart';
import 'package:nwt_app/services/mf_onboarding/mf_onboarding_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class StartingJourneyLayout extends StatefulWidget {
  final bool isAnimating;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final Function(DecryptedCASDetails?, String)? onCasDetailsReceived;
  final VoidCallback? onError;
  final VoidCallback? onRetry;

  const StartingJourneyLayout({
    super.key,
    required this.isAnimating,
    required this.onNext,
    this.onSkip,
    this.onCasDetailsReceived,
    this.onError,
    this.onRetry,
  });

  @override
  State<StartingJourneyLayout> createState() => _StartingJourneyLayoutState();
}

class _StartingJourneyLayoutState extends State<StartingJourneyLayout>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorStage;
  int? _statusCode;
  String? _panNumber;
  bool _showStartingScreen = true;
  bool _apiCompleted = false;
  bool _hasError = false;
  DecryptedCASDetails? _casDetails;
  final MFOnboardingService _mfOnboardingService = MFOnboardingService();

  late List<AnimationController> _dotControllers;
  static const int _minStartingScreenTime = 5000;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted && _dotControllers[i].isAnimating == false) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }

    _sendOTP();

    Future.delayed(Duration(milliseconds: _minStartingScreenTime), () {
      if (mounted) {
        setState(() {
          _showStartingScreen = false;
        });
        _checkAndProceed();
      }
    });
  }

  void _checkAndProceed() {
    if (_apiCompleted && !_hasError && _casDetails != null) {
      widget.onNext();
    }
  }

  Future<void> _sendOTP() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _errorStage = null;
        _statusCode = null;
        _hasError = false;
        _apiCompleted = false;
      });
    }

    final result = await _mfOnboardingService.sendOTP(
      forcePrimary: !MFOnboardingService.hasRetryInfo(), // Only force primary if no retry info exists
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
      onError: (message, statusCode, stage, panNumber) {
        if (mounted) {
          setState(() {
            _errorMessage = message;
            _errorStage = stage;
            _statusCode = statusCode;
            _panNumber = panNumber;
            _isLoading = false;
            _hasError = true;
            _apiCompleted = true;
            _showStartingScreen = false;
          });
          widget.onError?.call();
        }
      },
    );

    if (mounted) {
      if (result.data?.decryptedcasdetails != null) {
        setState(() {
          _casDetails = result.data?.decryptedcasdetails;
          _isLoading = false;
          _errorMessage = null;
          _errorStage = null;
          _hasError = false;
          _apiCompleted = true;
        });

        if (widget.onCasDetailsReceived != null) {
          widget.onCasDetailsReceived!(_casDetails, result.data?.token ?? '');
        }

        if (!_showStartingScreen) {
          widget.onNext();
        }
      } else {
        setState(() {
          // _errorMessage = 'Failed to fetch CAS details';
          _isLoading = false;
          _hasError = true;
          _apiCompleted = true;
          _showStartingScreen = false;
        });
        widget.onError?.call();
      }
    }
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _showStartingScreen = true;
    });
    widget.onRetry?.call();
    _sendOTP();
  }

  @override
  void dispose() {
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _errorMessage != null) {
      // Check if stage is "failed" - redirect to Dashboard
      if (_errorStage == "failed") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.off(
            () => const StackedNavbar(selectedIdx: 0),
            transition: Transition.rightToLeft,
          );
        });
        // Return empty container while navigation is happening
        return Container();
      }
      
      // Check for specific error condition to redirect to MF Flow Retry screen
      if (_errorMessage!.contains("Invalid PAN/Phone combination") &&
          (_errorStage == "secondary" || _errorStage == "tertiary")) {
        // Navigate to MF Flow Retry screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.off(
            () => MFFlowRetryScreen(
              initialPan: _panNumber,
              currentStage: _errorStage,
            ),
            transition: Transition.rightToLeft,
          );
        });
        // Return empty container while navigation is happening
        return Container();
      }
      
      return MfFetchingErrorLayout(
        isAnimating: widget.isAnimating,
        errorMessage: _errorMessage,
        onRetry: _handleRetry,
        onSkip: widget.onSkip ?? widget.onNext,
        statusCode: _statusCode,
      );
    }

    if (_showStartingScreen || _isLoading) {
      return widget.isAnimating
          ? FadeOutUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 400),
            child: _buildContent(context),
          )
          : FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 400),
            child: _buildContent(context),
          );
    }

    return widget.isAnimating
        ? FadeOutUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 400),
          child: _buildContent(context),
        )
        : FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 400),
          child: _buildContent(context),
        );
  }

  Widget _buildBottomContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svgs/mf_switch/starting_journey.svg",
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    "Starting your\nMutual Fund Journey!",
                    variant: AppTextVariant.headline3,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: FadeInUp(
              delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  AppText(
                    "Processing your request",
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          _buildAnimatedDot(context, i),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBottomContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(BuildContext context, int index) {
    return AnimatedBuilder(
      animation: _dotControllers[index],
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(
              alpha: 0.6 + (_dotControllers[index].value * 0.4),
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(
                  alpha: 0.3 * _dotControllers[index].value,
                ),
                blurRadius: 8 * _dotControllers[index].value,
                spreadRadius: 2 * _dotControllers[index].value,
              ),
            ],
          ),
        );
      },
    );
  }
}
