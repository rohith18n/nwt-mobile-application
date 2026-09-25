import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/services/mf_onboarding/skip_mfc.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class MfFetchingErrorLayout extends StatefulWidget {
  final bool isAnimating;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  final int? statusCode;

  const MfFetchingErrorLayout({
    super.key,
    required this.isAnimating,
    required this.errorMessage,
    required this.onRetry,
    required this.onSkip,
    required this.statusCode,
  });

  @override
  State<MfFetchingErrorLayout> createState() => _MfFetchingErrorLayoutState();
}

class _MfFetchingErrorLayoutState extends State<MfFetchingErrorLayout> {
  final SkipMfcService _skipMfcService = SkipMfcService();
  bool _isLoading = false;
  Timer? _autoSkipTimer;
  int _autoSkipCountdown = 3;
  bool _hasRetriedOnce = false;

  @override
  void initState() {
    super.initState();

    // Log the status code for debugging
    AppLogger.info(
      'MfFetchingErrorLayout initialized with status code: ${widget.statusCode}',
      tag: 'ErrorLayout',
    );

    // Check if user has already retried once in this specific error flow
    _checkRetryStatus();
  }

  void _checkRetryStatus() async {
    // For 404 errors, always start auto-skip timer immediately
    if (widget.statusCode == 404) {
      AppLogger.info(
        '404 error detected, starting auto-skip timer immediately',
        tag: 'ErrorLayout',
      );
      _startAutoSkipTimer();
      return;
    }

    // For other errors, check retry status
    final currentErrorFlowKey =
        'mf_error_current_flow_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Per minute
    final hasRetriedInCurrentFlow =
        StorageService.read(currentErrorFlowKey) as bool? ?? false;

    setState(() {
      _hasRetriedOnce = hasRetriedInCurrentFlow;
    });

    // Only start auto-skip timer if user has retried once in this specific error flow
    if (_hasRetriedOnce) {
      AppLogger.info(
        'User has already retried once in current error flow, starting auto-skip timer',
        tag: 'ErrorLayout',
      );
      _startAutoSkipTimer();
    } else {
      AppLogger.info(
        'First encounter with error in current flow, showing retry button',
        tag: 'ErrorLayout',
      );
    }
  }

  @override
  void dispose() {
    _autoSkipTimer?.cancel();
    super.dispose();
  }

  void _startAutoSkipTimer() {
    _autoSkipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoSkipCountdown > 0) {
        setState(() {
          _autoSkipCountdown--;
        });
      } else {
        timer.cancel();
        _skipMFCVerification();
      }
    });
  }

  void _handleRetry() {
    if (_hasRetriedOnce) {
      // If already retried once, skip directly
      _skipMFCVerification();
    } else {
      // Mark as retried in current error flow and call the original retry function
      final currentErrorFlowKey =
          'mf_error_current_flow_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Per minute
      StorageService.write(currentErrorFlowKey, true);
      setState(() {
        _hasRetriedOnce = true;
      });

      AppLogger.info(
        'User clicked retry for the first time in current flow, marking as retried',
        tag: 'ErrorLayout',
      );

      widget.onRetry();
    }
  }

  void _skipMFCVerification() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Reset retry state to default when skipping
      final currentErrorFlowKey =
          'mf_error_current_flow_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Per minute
      StorageService.remove(currentErrorFlowKey);
      AppLogger.info(
        'Retry state reset to default after skip action',
        tag: 'ErrorLayout',
      );

      // Update user's skipmfc field to true using SkipMfcService
      final response = await _skipMfcService.skipMfc(
        onLoading: (isLoading) {
          // Loading is already handled by _isLoading state
        },
      );

      if (response != null && response.statusCode == 200) {
        // Navigate to next screen
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
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
        tag: 'OtpVerificationLayout',
      );
    }
  }

  void _showSkipConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top icon section
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.info,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Skip to Dashboard",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Are you sure you want to skip?",
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Action buttons with divider
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Cancel",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),

                      // Vertical divider
                      Container(
                        height: 52,
                        width: 1,
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                      ),

                      // Exit button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // _skipMFCVerification();
                            // Get.offAll(() => const OnboardingScreen());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Skip",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Opacity(opacity: 0, child: const Icon(Icons.chevron_left, size: 32)),
        centerTitle: true,
        title: AppText(
          "Mutual Funds",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          // TextButton(
          //   onPressed: () => _showSkipConfirmationDialog(context),
          //   child: AppText(
          //     "Skip",
          //     variant: AppTextVariant.bodyMedium,
          //     colorType: AppTextColorType.link,
          //     weight: AppTextWeight.semiBold,
          //   ),
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Lottie.asset("assets/lottie/failure.json")],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AppText(
                          widget.statusCode == 404
                              ? widget.errorMessage ?? ""
                              : "Something went wrong!",
                          variant: AppTextVariant.headline3,
                          weight: AppTextWeight.bold,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AppText(
                      _hasRetriedOnce
                          ? "Redirecting to dashboard..."
                          : "We're currently unable to complete your request. Please try again shortly.",
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.regular,
                      textAlign: TextAlign.center,
                      colorType: AppTextColorType.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hide retry button if user has already retried once OR if it's a 404 error
                    if (!_hasRetriedOnce && widget.statusCode != 404)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Retry',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed: _handleRetry,
                            ),
                          ),
                        ],
                      ),

                    // Show manual skip option if user has already retried once OR if it's a 404 error
                    if (_hasRetriedOnce || widget.statusCode == 404)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: AppButton(
                              text:
                                  _autoSkipCountdown > 0
                                      ? 'Skip to Dashboard ($_autoSkipCountdown)'
                                      : 'Skip to Dashboard',
                              variant: AppButtonVariant.secondary,
                              size: AppButtonSize.large,
                              isDisabled: _autoSkipCountdown > 0,
                              onPressed: () {
                                if (_autoSkipCountdown <= 0) {
                                  _autoSkipTimer?.cancel();
                                  _skipMFCVerification();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
