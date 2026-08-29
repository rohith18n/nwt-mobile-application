import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/screens/fetch-holdings/layouts/import_mf.dart';

import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/types/auth/pan_verfication.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';

class PanConsentScreen extends StatefulWidget {
  final String fullName;
  final Data? panVerificationData;

  const PanConsentScreen({
    super.key,
    required this.fullName,
    this.panVerificationData,
  });

  @override
  State<PanConsentScreen> createState() => _PanConsentScreenState();
}

class _PanConsentScreenState extends State<PanConsentScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _confirmDetails() async {
    if (widget.panVerificationData == null) {
      AppLogger.error('PAN verification data is null', tag: 'PanConsentScreen');
      return;
    }

    try {
      final response = await _authService.verifyPanV1(
        pan: widget.panVerificationData!.pan,
        name: widget.fullName,
        dob: widget.panVerificationData!.dob ?? "",
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );

      AppLogger.info(
        'PAN Consent Response: ${response.statusCode} - ${response.message}',
        tag: 'PanConsentScreen',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.panConsentSuccess);
        final flowType = Get.isRegistered<UserController>()
            ? Get.find<UserController>().userData?.onboardingFlowType?.apiValue
            : null;
        if (flowType != null && flowType.isNotEmpty) {
          await _authService.updateOnboardingProgress(
            flowType: flowType,
            status: 'in_progress',
          );
        }
        // If user has no primary phone (e.g. email signup), show phone screen before MF/import
        final user = Get.isRegistered<UserController>()
            ? Get.find<UserController>().userData
            : null;
        final hasNoPrimaryPhone = user?.phonenumber == null ||
            (user?.phonenumber ?? '').trim().isEmpty;
        if (user != null &&
            (user.email ?? '').trim().isNotEmpty &&
            hasNoPrimaryPhone) {
          Get.to(
            () => const PhoneNumberInputScreen(unlockInvestmentsMode: true),
            transition: Transition.rightToLeft,
          );
          return;
        }
        // Check for service outage
        final isMfcWorking = RemoteConfigService.to.isMfcWorking.value;

        if (!isMfcWorking) {
          Get.offAll(() => const StackedNavbar(selectedIdx: 0));
        } else {
          Get.to(() => const ImportMf(), transition: Transition.rightToLeft);
        }
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.panConsentFailed,
          parameters: {AnalyticsParams.errorMessage: response.message},
        );
        // Handle error - show error message or dialog
        AppLogger.error(
          'PAN consent confirmation failed: ${response.message}',
          tag: 'PanConsentScreen',
        );
        // You can show a snackbar or dialog here
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error confirming PAN consent',
        error: e,
        tag: 'PanConsentScreen',
      );
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _correctDetails() {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.panConsentCorrectClicked,
    );
    // Handle correction logic here
    // Navigate back to previous screen or show correction options
    Get.back();
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.primary,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.darkInputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkInputBorder, width: 1),
          ),
          child: AppText(
            value,
            variant: AppTextVariant.bodyLarge,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fire panConsentShown event once when screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.panConsentShown);
      AppLogger.info(AnalyticsEvents.panConsentShown, tag: 'event');
    });
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(
            Icons.chevron_left,
            color: AppColors.darkPrimary,
            size: 28,
          ),
        ),
        centerTitle: true,
        title: AppText(
          "Confirm Your Details",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.darkPrimary,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Search animation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Lottie.asset('assets/lottie/pan.json'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Title
                      AppText(
                        "Based on your PAN, we found:",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      _buildInfoField("Name", widget.fullName),
                      const SizedBox(height: 20),

                      // Date of Birth field
                      if (widget.panVerificationData?.dob != null &&
                          widget.panVerificationData!.dob!.isNotEmpty)
                        _buildInfoField(
                          "Date of Birth",
                          widget.panVerificationData!.dob!,
                        ),
                      if (widget.panVerificationData?.dob != null &&
                          widget.panVerificationData!.dob!.isNotEmpty)
                        const SizedBox(height: 20),

                      // Address field
                      if (widget.panVerificationData?.full_address != null &&
                          widget.panVerificationData!.full_address!.isNotEmpty)
                        _buildInfoField(
                          "Address as per PAN",
                          widget.panVerificationData!.full_address!,
                        ),
                      if (widget.panVerificationData?.full_address != null &&
                          widget.panVerificationData!.full_address!.isNotEmpty)
                        const SizedBox(height: 20),

                      // City field
                      if (widget.panVerificationData?.city != null &&
                          widget.panVerificationData!.city!.isNotEmpty)
                        _buildInfoField(
                          "City",
                          widget.panVerificationData!.city!,
                        ),
                      if (widget.panVerificationData?.city != null &&
                          widget.panVerificationData!.city!.isNotEmpty)
                        const SizedBox(height: 20),

                      // State field
                      if (widget.panVerificationData?.state != null &&
                          widget.panVerificationData!.state!.isNotEmpty)
                        _buildInfoField(
                          "State",
                          widget.panVerificationData!.state!,
                        ),
                      if (widget.panVerificationData?.state != null &&
                          widget.panVerificationData!.state!.isNotEmpty)
                        const SizedBox(height: 20),

                      // Country field
                      if (widget.panVerificationData?.country != null &&
                          widget.panVerificationData!.country!.isNotEmpty)
                        _buildInfoField(
                          "Country",
                          widget.panVerificationData!.country!,
                        ),
                      if (widget.panVerificationData?.country != null &&
                          widget.panVerificationData!.country!.isNotEmpty)
                        const SizedBox(height: 20),

                      // PIN Code field
                      if (widget.panVerificationData?.pin_code != null &&
                          widget.panVerificationData!.pin_code!.isNotEmpty)
                        _buildInfoField(
                          "PIN Code",
                          widget.panVerificationData!.pin_code!,
                        ),
                      if (widget.panVerificationData?.pin_code != null &&
                          widget.panVerificationData!.pin_code!.isNotEmpty)
                        const SizedBox(height: 20),
                      const SizedBox(height: 40),

                      // Verification message
                      AppText(
                        "Please verify that these details are correct before proceeding.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.4,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              Column(
                children: [
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: "Yes, that's me",
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed: _isLoading ? () {} : _confirmDetails,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Correction button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? () {} : _correctDetails,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: AppText(
                        "No, this isn't correct",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
