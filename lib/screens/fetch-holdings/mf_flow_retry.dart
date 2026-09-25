import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/services/mf_onboarding/mf_onboarding_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class MFFlowRetryScreen extends StatefulWidget {
  final String? initialPan;
  final String? initialPhoneNumber;
  final String? currentStage;

  const MFFlowRetryScreen({
    super.key,
    this.initialPan,
    this.initialPhoneNumber,
    this.currentStage,
  });

  @override
  State<MFFlowRetryScreen> createState() => _MFFlowRetryScreenState();
}

class _MFFlowRetryScreenState extends State<MFFlowRetryScreen> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with initial values if provided
    if (widget.initialPan != null) {
      _panController.text = widget.initialPan!;
    }
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getCurrentStage() {
    // Use the same stage from the error response
    return widget.currentStage ?? "secondary";
  }

  void _retryMutualFundSearch() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate inputs
    if (_panController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your PAN number";
      });
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your phone number";
      });
      return;
    }

    // Validate PAN format
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(_panController.text.trim())) {
      setState(() {
        _errorMessage = "Please enter a valid PAN number";
      });
      return;
    }

    // Validate phone number format (basic validation)
    if (_phoneController.text.trim().length != 10) {
      setState(() {
        _errorMessage = "Please enter a valid 10-digit phone number";
      });
      return;
    }

    // Get the current stage from error response
    final currentStage = _getCurrentStage();
    
    AppLogger.info(
      'Setting retry info - Phone: ${_phoneController.text}, Stage: $currentStage',
      tag: 'MFFlowRetry',
    );

    // Set retry information for subsequent service calls (no API call here)
    MFOnboardingService.setRetryInfo(
      phoneNumber: _phoneController.text.trim(),
      stage: currentStage,
    );
    
    // Navigate back to MF journey to retry with new credentials
    AppLogger.info(
      'Navigating back to MF journey to retry with updated phone number',
      tag: 'MFFlowRetry',
    );
    
    Get.off(
      () => const MutualFundHoldingsJourneyScreen(isInitialJourney: true),
      transition: Transition.rightToLeft,
    );
  }

  void _continueWithoutMutualFunds() {
    AppLogger.info('User chose to continue without Mutual Funds', tag: 'MFFlowRetry');
    
    // Navigate to next step in onboarding or dashboard
    Get.off(
      () => const Dashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppText(
          "Mutual Funds",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight - 
                          200, // Account for bottom navigation bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Search animation using PAN lottie asset
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Lottie.asset('assets/lottie/pan.json'),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: AppText(
                      "No Mutual Funds found for this PAN and Mobile Number",
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: AppText(
                      "Please enter the PAN and Mobile Number linked to your Mutual Funds",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                      lineHeight: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // PAN Input
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "PAN",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _panController,
                          hintText: "Enter your PAN number",
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          type: AppInputFieldType.text,
                          readOnly: widget.initialPan != null,
                          onChanged: (value) {
                            // Clear error when user starts typing
                            if (_errorMessage != null) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Phone Number Input
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Phone number",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _phoneController,
                          hintText: "Enter your phone number",
                          type: AppInputFieldType.phone,
                          maxLength: 10,
                          onChanged: (value) {
                            // Clear error when user starts typing
                            if (_errorMessage != null) {
                              setState(() {
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Error Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(0.0, -0.5), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _errorMessage != null
                        ? Container(
                            key: ValueKey(_errorMessage),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: AppText(
                              _errorMessage!,
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.error,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retry button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              child: AppButton(
                text: "Retry",
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
                onPressed: _isLoading ? () {} : _retryMutualFundSearch,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 12),
            
            // Continue without MF button
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: double.infinity,
              child: AppButton(
                text: "Continue without Mutual Funds",
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: _isLoading ? () {} : _continueWithoutMutualFunds,
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

}