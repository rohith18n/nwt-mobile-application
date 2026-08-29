import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/auth/pan_consent.dart';
import 'package:nwt_app/screens/auth/pan_details.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PanCardVerification extends StatefulWidget {
  const PanCardVerification({super.key});

  @override
  State<PanCardVerification> createState() => _PanCardVerificationState();
}

class _PanCardVerificationState extends State<PanCardVerification> {
  final TextEditingController _panController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  TextInputType _currentKeyboardType = TextInputType.text;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPanFieldEmpty = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.panScreenViewed);
      AppLogger.info(AnalyticsEvents.panScreenViewed, tag: 'event');
    });
    _panController.addListener(() {
      final text = _panController.text;
      final newType =
          (text.length >= 5 && text.length < 9)
              ? TextInputType.number
              : TextInputType.text;

      // Update empty state - hide text as soon as any input is entered
      final isEmpty = text.isEmpty;
      if (_isPanFieldEmpty != isEmpty) {
        setState(() {
          _isPanFieldEmpty = isEmpty;
        });
      }

      if (_currentKeyboardType != newType) {
        setState(() {
          _currentKeyboardType = newType;
        });

        _focusNode.unfocus();
        Future.delayed(const Duration(milliseconds: 50), () {
          _focusNode.requestFocus();
        });
      }
    });
  }

  // Method to verify PAN card
  void _verifyPanCard() async {
    AnalyticsService.to.logEvent(name: AnalyticsEvents.panVerifyButtonClicked);
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate PAN number format
    if (_panController.text.length != 10 ||
        !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(_panController.text)) {
      setState(() {
        _errorMessage = "Please enter a valid PAN number";
      });
      return;
    }

    // Call the PAN verification service
    try {
      final response = await _authService.verifyPanCard(
        panNumber: _panController.text,
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );

      // Check response
      AppLogger.info(
        'PAN Verification completed: ${response.message}',
        tag: 'PanCardVerification',
      );

      if (response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.panVerificationSuccess);
        // Clear any error messages on success
        setState(() {
          _errorMessage = null;
        });

        // Navigate to PAN consent screen with complete response data
        Get.to(
          () => PanConsentScreen(
            fullName: response.data?.registeredName ?? "",
            panVerificationData: response.data,
          ),
          transition: Transition.rightToLeft,
        );
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.panVerificationFailed,
          parameters: {
            AnalyticsParams.errorMessage: response.message,
          },
        );
        // Show modern failure dialog instead of just error message
        _showPanVerificationFailureDialog(context);
      }
    } catch (e) {
      AppLogger.error(
        'PAN Verification Error',
        error: e,
        tag: 'PanCardVerification',
      );
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Method to show PAN verification failure dialog
  void _showPanVerificationFailureDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                child: Column(
                  children: [
                    // Top spacer to center content
                    const Spacer(flex: 1),
                    // Top section with error icon
                    Container(
                      padding: const EdgeInsets.only(top: 32, bottom: 24),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 50,
                        ),
                      ),
                    ),

                    // Title
                    AppText(
                      "Uh-Oh, your PAN Card\nverification has failed!",
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      textAlign: TextAlign.center,
                      lineHeight: 1.3,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    AppText(
                      "Here are the likely reasons for failure",
                      variant: AppTextVariant.bodyLarge,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                      weight: AppTextWeight.medium,
                    ),
                    const SizedBox(height: 32),

                    // Failure reasons
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkInputBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.darkInputBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFailureReason(
                            "Mobile number doesn't match PAN linked number",
                          ),
                          const SizedBox(height: 12),
                          _buildFailureReason(
                            "KYC service is temporarily down",
                          ),
                          const SizedBox(height: 12),
                          _buildFailureReason("Other Technical issue"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText(
                              "Let's try verifying your details again to verify your identity and details.",
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.secondary,
                              lineHeight: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom spacer to center content
                    const Spacer(flex: 2),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: "Re-enter PAN Details",
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        onPressed: () {
                          AnalyticsService.to.logEvent(name: AnalyticsEvents.panManualEntryClicked);
                          Get.offAll(
                            () => PANDetailsScreen(
                              panNumber: _panController.text,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build failure reason text
  Widget _buildFailureReason(String reason) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        AppText(
          reason,
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
          lineHeight: 1.4,
        ),
      ],
    );
  }

  // Method to show exit confirmation dialog
  void _showExitConfirmationDialog(BuildContext context) {
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Exit Verification",
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
                    "Are you sure you want to logout? Your PAN verification progress will be lost.",
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

                            _authService.logout();
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
                            "Logout",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.error,
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

  void _showDontKnowPanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Don't know your PAN?",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              AppText(
                "You can find your PAN here:",
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 16),

              _buildPanSourceItem(
                number: "1",
                title: "Income tax website",
                items: [
                  "Visit www.incometaxindiaefiling.gov.in",
                  "Click \"Know your PAN\" under Quick Links",
                  "Fill in your details",
                  "Enter the OTP sent to your registered mobile",
                  "Add your father's name and submit",
                ],
              ),
              const SizedBox(height: 16),

              _buildPanSourceItem(
                number: "2",
                title: "Payslip",
                items: [
                  "Check your latest payslip (email or company portal)",
                  "Look for PAN number in the tax details section",
                  "Can't find it? Contact your HR team",
                ],
              ),
              const SizedBox(height: 16),

              _buildPanSourceItem(
                number: "3",
                title: "IT-Returns",
                items: [
                  "Look for verification email from www.incometaxindiaefiling.gov.in (sent after filing returns)",
                  "Your PAN will be included in the email details",
                ],
              ),
              const SizedBox(height: 16),

              _buildPanSourceItem(
                number: "4",
                title: "Form 16",
                items: [
                  "Your employer's Form 16 contains your PAN number",
                  "Check your email or company portal to find it",
                ],
              ),
              const SizedBox(height: 16),

              _buildPanSourceItem(
                number: "5",
                title: "Net/Mobile Banking",
                items: [
                  "Log into your bank app or website",
                  "Go to 'Profile' or 'My Profile' section",
                  "Your PAN will be displayed if it's linked to your account",
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showWhyPanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Why PAN",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              _buildInfoItem(
                number: "1",
                title: "Unique Investor Identifier:",
                description:
                    "PAN serves as a unique identifier for all financial investments, including mutual funds, across Asset Management Companies (AMCs) and platforms.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "2",
                title: "Centralized Investment Data:",
                description:
                    "All mutual fund transactions — whether made through a distributor, direct platform, or online aggregator — are recorded against your PAN by Registrar and Transfer Agents (RTAs) such as CAMS and KFintech.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "3",
                title: "Accurate Portfolio Aggregation:",
                description:
                    "Using your PAN, we can securely request data from RTAs to retrieve your mutual fund holdings from all sources, enabling a consolidated and up-to-date view of your portfolio.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "4",
                title: "No Access to Sensitive Data Without Consent:",
                description:
                    "We use PAN only to initiate the data fetch request via official and secure APIs. Your consent is mandatory, and we do not store or misuse your information.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "5",
                title: "Compliance with Regulatory Requirements:",
                description:
                    "PAN-based verification is required as per SEBI regulations to ensure data accuracy, investor protection, and traceability.",
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.darkPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              text,
              variant: AppTextVariant.bodySmall,
              colorType: AppTextColorType.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: AppText(
            number,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.link,
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
              ),
              const SizedBox(height: 4),
              AppText(
                description,
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.secondary,
                lineHeight: 1.4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanSourceItem({
    required String number,
    required String title,
    required List<String> items,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: AppText(
            number,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.link,
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
              ),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        item,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.primary,
                        lineHeight: 1.4,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Opacity(opacity: 0, child: const Icon(Icons.chevron_left, size: 32)),
        centerTitle: true,
        title: AppText(
          "PAN Verification",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          TextButton(
            onPressed: () {
              AnalyticsService.to.logEvent(name: AnalyticsEvents.panScreenLogoutClicked);
              _showExitConfirmationDialog(context);
            },
            child: AppText(
              "Logout",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.error,
              weight: AppTextWeight.semiBold,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSizing.scaffoldHorizontalPadding,
            right: AppSizing.scaffoldHorizontalPadding,
            // bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Lottie.asset('assets/lottie/pan.json'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          AppText(
                            "Enter your PAN number",
                            variant: AppTextVariant.bodyLarge,
                            lineHeight: 1.3,
                            colorType: AppTextColorType.primary,
                            weight: AppTextWeight.bold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              "All investments linked to your PAN & mobile will be fetched.",
                              variant: AppTextVariant.bodySmall,
                              lineHeight: 1.3,
                              colorType: AppTextColorType.secondary,
                              weight: AppTextWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              AnalyticsService.to.logEvent(name: AnalyticsEvents.panWhyClicked);
                              _showWhyPanBottomSheet(context);
                            },
                            child: AppText(
                              "Why do you need my PAN Number?",
                              variant: AppTextVariant.bodySmall,
                              lineHeight: 1.3,
                              colorType: AppTextColorType.link,
                              weight: AppTextWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: AppValidators.validatePanCard,
                        controller: _panController,
                        decoration: InputDecoration(
                          hintText: 'Eg. ABCDE1234F',
                          suffixIcon: _isPanFieldEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    AnalyticsService.to.logEvent(name: AnalyticsEvents.panHelpDontKnowClicked);
                                    _showDontKnowPanBottomSheet(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    child: AppText(
                                      "Don't know my PAN",
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.link,
                                      weight: AppTextWeight.medium,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        focusNode: _focusNode,
                        keyboardType: _currentKeyboardType,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.deny(
                            RegExp(r'[^A-Z0-9]'),
                          ),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            if (newValue.text.length > 10) return oldValue;

                            // Allow backspace
                            if (newValue.text.length < oldValue.text.length) {
                              return newValue;
                            }

                            final text = newValue.text;
                            final position = text.length;

                            // Validate based on position
                            if (position <= 5) {
                              // First 5 chars must be letters
                              if (!RegExp(r'^[A-Z]{1,5}$').hasMatch(text)) {
                                return oldValue;
                              }
                            } else if (position <= 9) {
                              // After first 5 letters, next 4 must be numbers
                              if (!RegExp(
                                r'^[A-Z]{5}[0-9]{1,4}$',
                              ).hasMatch(text)) {
                                return oldValue;
                              }
                            } else {
                              // Last char must be letter
                              if (!RegExp(
                                r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                              ).hasMatch(text)) {
                                return oldValue;
                              }
                            }
                            return newValue;
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedErrorMessage(errorMessage: _errorMessage),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSecurityInfoRow(
                    Icons.verified_user_outlined,
                    "We share your PAN and mobile with MF Central to securely fetch and unify your Mutual Fund holdings",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, color: Color(0xFF2D2D2D)),
                  ),
                  _buildSecurityInfoRow(
                    Icons.security_outlined,
                    "SEBI Registered Investment Advisor: INA0000020396",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, color: Color(0xFF2D2D2D)),
                  ),
                  _buildSecurityInfoRow(
                    Icons.lock_outline,
                    "Your data is encrypted and 100% secure",
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Verify',
                    variant: AppButtonVariant.primary,
                    isLoading: _isLoading,
                    size: AppButtonSize.large,
                    isDisabled: _isLoading || _panController.text.length != 10,
                    onPressed: _verifyPanCard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
