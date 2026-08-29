import 'dart:ui';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:get/get.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';
import 'package:nwt_app/screens/mf_central/mf_central_trigger.dart';
import 'package:nwt_app/utils/validators.dart';

enum PanCardNextStep {
  /// Default behavior: proceed to phone collection and AA unlock flow.
  unlockInvestments,

  /// Used when PAN verification is required as a prerequisite for some other action.
  /// Returns to the caller so they can continue their original flow.
  returnToCaller,
}

class PanCardV2 extends StatefulWidget {
  final PanCardNextStep nextStep;

  const PanCardV2({
    super.key,
    this.nextStep = PanCardNextStep.unlockInvestments,
  });

  @override
  State<PanCardV2> createState() => _PanCardV2State();
}

class _PanCardV2State extends State<PanCardV2> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isVerifying = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _liveError;

  @override
  void initState() {
    super.initState();
    _fetchExistingPanDetails();
  }

  Future<void> _fetchExistingPanDetails() async {
    setState(() => _isVerifying = true);
    final data = await _authService.getProfilePan(
      onLoading: (_) {}, // handled locally
    );
    if (data != null && mounted) {
      setState(() {
        _panController.text = data['pan_number'] ?? '';
        _nameController.text = data['name'] ?? '';
        _dobController.text = data['dob'] ?? '';
      });
    }
    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }

  void _validateLive(String val) {
    if (val.isEmpty) {
      setState(() {
        _liveError = null;
      });
      return;
    }

    String? error;
    for (int i = 0; i < val.length; i++) {
      String char = val[i].toUpperCase();
      if (i < 5) {
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          error = "First 5 characters must be letters";
          break;
        }
      } else if (i >= 5 && i < 9) {
        if (!RegExp(r'[0-9]').hasMatch(char)) {
          error = "Characters 6-9 must be digits";
          break;
        }
      } else if (i == 9) {
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          error = "Last character must be a letter";
          break;
        }
      }
    }

    if (error == null && val.length > 0 && val.length < 10) {
      // No structural error but incomplete
      // error = "PAN must be 10 characters"; // Maybe too aggressive to show during typing
    }

    setState(() {
      _liveError = error;
    });
  }

  void _handleContinue() async {
    final panErr = AppValidators.validatePanCard(_panController.text);
    final nameErr = AppValidators.validateFirstName(_nameController.text);
    final dobErr = AppValidators.validateISODate(
      _dobController.text,
    ); // Since we format it to YYYY-MM-DD

    if (panErr != null || nameErr != null || dobErr != null) {
      setState(() {
        _hasError = true;
        _errorMessage = panErr ?? nameErr ?? dobErr ?? "Invalid input";
      });
      return;
    }

    try {
      final response = await _authService.verifyPanV1(
        pan: _panController.text,
        name: _nameController.text.trim(),
        dob: _dobController.text, // format YYYY-MM-DD
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              _isVerifying = isLoading;
              if (isLoading) {
                _hasError = false;
                _errorMessage = null;
              }
            });
          }
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.panConsentSuccess);

        if (widget.nextStep == PanCardNextStep.returnToCaller) {
          Get.back(result: true);
          return;
        }

        // User needs to provide/verify phone number before proceeding
        AppLogger.info(
          'PAN verified successfully, navigating to phone number screen',
          tag: 'PanCardV2',
        );

        final phoneNumber = await Get.to<String>(
          () => const PhoneNumberInputScreen(
            mode: PhoneNumberInputMode.collectOnly,
          ),
          transition: Transition.rightToLeft,
        );

        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          AppLogger.info(
            'Phone number collected: $phoneNumber, proceeding to MF Central trigger',
            tag: 'PanCardV2',
          );

          // Navigate to MF Central trigger screen with PAN and phone number
          Get.to(
            () => MFCentralTriggerScreen(
              panNumber: _panController.text.toUpperCase(),
              phoneNumber: phoneNumber,
            ),
            transition: Transition.rightToLeft,
          );
        }
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.panConsentFailed,
          parameters: {AnalyticsParams.errorMessage: response.message},
        );
        setState(() {
          _hasError = true;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      AppLogger.error('PAN Verification Error', error: e, tag: 'PanCardV2');
      setState(() {
        _hasError = true;
        _errorMessage = "Something went wrong";
      });
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    // Title and Subtitle
                    AppText(
                      "Verify your PAN",
                      variant: AppTextVariant.headline1,
                      weight: AppTextWeight.bold,
                    ),
                    SizedBox(height: 12.h),
                    AppText(
                      "We'll use this to fetch your investment\ndetails securely",
                      variant: AppTextVariant.bodyLarge,
                      colorType: AppTextColorType.secondary,
                    ),
                    SizedBox(height: 40.h),

                    _buildField(
                      "PAN Number",
                      "ABCDE1234F",
                      _panController,
                      AppInputFormatters.panCardFormattersLenient(),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: 24.h),

                    _buildField(
                      "Name (As per PAN)",
                      "Rahul Kumar",
                      _nameController,
                      [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\s]'),
                        ),
                      ],
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 24.h),

                    _buildField(
                      "Date of Birth",
                      "YYYY-MM-DD",
                      _dobController,
                      [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      keyboardType: TextInputType.number,
                    ),

                    if (_liveError != null) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: AppText(
                          _liveError!,
                          variant: AppTextVariant.bodySmall,
                          customColor: AppColors.error,
                          weight: AppTextWeight.medium,
                        ),
                      ),
                    ],

                    if (_isVerifying) ...[
                      SizedBox(height: 24.h),
                      _buildStatusCard(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF00C7AC),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                "Verifying details...",
                                variant: AppTextVariant.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_hasError) ...[
                      SizedBox(height: 24.h),
                      _buildStatusCard(
                        borderColor: AppColors.error,
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 24.w,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                _errorMessage ?? "Verification Failed",
                                variant: AppTextVariant.bodyMedium,
                                customColor: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    // Missing PAN Link
                    Center(
                      child: GestureDetector(
                        onTap: () => _showPanOptionsBottomSheet(context),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: "Missing PAN? "),
                              TextSpan(
                                text: "Get PAN 100% digitally now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Info Container
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBG.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildInfoItem(
                            "Your PAN is encrypted and stored securely",
                          ),
                          SizedBox(height: 12.h),
                          _buildInfoItem(
                            "Used only for fetching investment data",
                          ),
                          SizedBox(height: 12.h),
                          _buildInfoItem(
                            "Compliant with RBI and SEBI regulations",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding.w,
                vertical: 16.h,
              ),
              child: AppButton(
                text: "Continue",
                isFullWidth: true,
                onPressed:
                    (_isVerifying ||
                            _panController.text.length < 10 ||
                            _nameController.text.trim().isEmpty ||
                            _dobController.text.length < 10 ||
                            _liveError != null)
                        ? () {}
                        : _handleContinue,
                isDisabled:
                    (_panController.text.length < 10 ||
                        _nameController.text.trim().isEmpty ||
                        _dobController.text.length < 10 ||
                        _liveError != null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding.w,
        vertical: 16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox.shrink(), // Keeps layout balanced if needed, or just removes back button
          GestureDetector(
            onTap: () {
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
    );
  }

  void _showPanOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141414), // matching AppColors.darkCardBG
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Color(0xFF242424), width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // const AppText(
                            //   "Get PAN 100% digitally now",
                            //   variant: AppTextVariant.headline5,
                            //   weight: AppTextWeight.bold,
                            //   customColor: Colors.white,
                            // ),
                            // SizedBox(height: 6.h),
                            const AppText(
                              "Select one of the options below to get your PAN card",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      _buildPanOptionCard(
                        context: sheetContext,
                        title: "Fully digital online self checkout",
                        subtitle: "Instant e-PAN (If you have Aadhaar)",
                        icon: Icons.bolt_rounded,
                        iconBgColor: const Color(0xFF00C7AC).withOpacity(0.15),
                        iconColor: const Color(0xFF00C7AC),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Get.to(
                            () => const AppWebViewScreen(
                              url:
                                  "https://www.incometaxindia.gov.in/tax-services/instant-e-pan",
                              title: "Instant e-PAN",
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildPanOptionCard(
                        context: sheetContext,
                        title: "Assisted application",
                        subtitle: "Meet With Jash Koradia",
                        icon: Icons.headset_mic_rounded,
                        iconBgColor: AppColors.linkColor.withOpacity(0.15),
                        iconColor: AppColors.linkColor,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          SpeakToAdvisor.speakToAdvisor();
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildPanOptionCard(
                        context: sheetContext,
                        title: "Physical + Online",
                        subtitle:
                            "Apply For New PAN Card & Corrections (If you do not have Aadhaar)",
                        // description:
                        //   "Online PAN Card Services - Apply For New PAN Card & Corrections",
                        icon: Icons.assignment_outlined,
                        iconBgColor: Colors.orange.withOpacity(0.15),
                        iconColor: Colors.orange,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Get.to(
                            () => const AppWebViewScreen(
                              url:
                                  "https://onlineservices.proteantech.in/paam/endUserRegisterContact.html",
                              title: "Apply For New PAN / Corrections",
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkInputBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    customColor: Colors.white,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                    weight: AppTextWeight.medium,
                  ),
                  if (description != null) ...[
                    SizedBox(height: 4.h),
                    AppText(
                      description,
                      variant: AppTextVariant.tiny,
                      colorType: AppTextColorType.muted,
                      weight: AppTextWeight.regular,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkTextSecondary,
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.darkCardBG,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.darkInputBorder, width: 1),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(0),
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
                      "Are you sure you want to logout? Your progress will be lost.",
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
                          color: AppColors.darkInputBorder.withValues(
                            alpha: 0.5,
                          ),
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
                          color: AppColors.darkInputBorder.withValues(
                            alpha: 0.5,
                          ),
                        ),

                        // Exit button
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // Close the dialog first
                              Navigator.of(context).pop();
                              _authService.logout();
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
          ),
        );
      },
    );
  }

  Widget _buildStatusCard({
    required Widget child,
    bool isSuccess = false,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ??
              (isSuccess
                  ? const Color(0xFF00C7AC).withValues(alpha: 0.3)
                  : AppColors.darkButtonBorder),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_rounded, color: AppColors.darkTextGray, size: 18.w),
        SizedBox(width: 12.w),
        Expanded(
          child: AppText(
            text,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary,
            weight: AppTextWeight.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    List<TextInputFormatter> formatters, {
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: controller,
          onChanged: (val) {
            if (controller == _panController) _validateLive(val);
            setState(() {
              _hasError = false;
            });
          },
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: controller == _panController ? 2.0 : 1.0,
          ),
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              letterSpacing: controller == _panController ? 2.0 : 1.0,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 20.h,
            ),
            fillColor: AppColors.darkCardBG,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _liveError != null && controller == _panController
                        ? AppColors.error
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _liveError != null && controller == _panController
                        ? AppColors.error
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
