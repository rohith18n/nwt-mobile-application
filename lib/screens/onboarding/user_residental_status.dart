import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/auth/email_onboarding.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/screens/auth/email_otp_verification.dart';

class UserResidentalStatus extends StatefulWidget {
  const UserResidentalStatus({super.key});

  @override
  State<UserResidentalStatus> createState() => _UserResidentalStatusState();
}

class _UserResidentalStatusState extends State<UserResidentalStatus> {
  String? _selectedStatus = 'indian_resident';

  final List<Map<String, String>> _statusOptions = [
    {'title': 'Resident Indian', 'value': 'indian_resident'},
    {'title': 'Non-Resident Indian (NRI)', 'value': 'nri'},
  ];

  void _handleNext() async {
    if (_selectedStatus != null) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.residentialStatusNextClicked,
        parameters: {AnalyticsParams.selectedStatus: _selectedStatus ?? ''},
      );
      final flowType =
          Get.isRegistered<UserController>()
              ? Get.find<UserController>()
                  .userData
                  ?.onboardingFlowType
                  ?.apiValue
              : null;
      if (flowType != null && flowType.isNotEmpty) {
        await AuthService().updateOnboardingProgress(
          flowType: flowType,
          status: 'in_progress',
        );
      }
      if (_selectedStatus == 'indian_resident') {
        // Navigate to PhoneNumberInputScreen for Indian Residents
        Get.to(
          () => const PhoneNumberInputScreen(),
          transition: Transition.rightToLeft,
        );
      } else {
        // For NRI, navigate to Email Onboarding (Google Auth)
        // or directly to Email OTP if Google Auth is hidden.
        if (RemoteConfigService.to.hideGoogleAuth.value) {
          Get.to(
            () => const EmailOTPVerification(),
            transition: Transition.rightToLeft,
          );
        } else {
          Get.to(
            () => const EmailOnboarding(),
            transition: Transition.rightToLeft,
          );
        }
      }
    }
  }

  Widget _buildStatusOption(Map<String, String> option) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = option['value'];
        });
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.residentialStatusSelected,
          parameters: {AnalyticsParams.status: option['value'] ?? ''},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkTextSecondary, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                option['title']!,
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.primary,
              ),
            ),
            Radio<String>(
              value: option['value']!,
              groupValue: _selectedStatus,
              onChanged: (String? value) {
                setState(() {
                  _selectedStatus = value;
                });
                if (value != null) {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.residentialStatusSelected,
                    parameters: {AnalyticsParams.status: value},
                  );
                }
              },
              activeColor: Colors.white,
              fillColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.grey;
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with star icon
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Welcome text
              AppText(
                'Welcome to\nPivot Money',
                variant: AppTextVariant.headline1,
                lineHeight: 1.3,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),

              const SizedBox(height: 16),

              // Subtitle
              AppText(
                'Minimal effort. Maximum potential.',
                variant: AppTextVariant.bodyMedium,
                lineHeight: 1.3,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.secondary,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              // Section title
              AppText(
                'Select your status',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),

              const SizedBox(height: 12),

              // Status options
              ..._statusOptions.map((option) => _buildStatusOption(option)),

              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: AppButton(
          text: 'NEXT',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          onPressed: _selectedStatus != null ? _handleNext : () {},
          isLoading: false,
          isDisabled: _selectedStatus == null,
        ),
      ),
    );
  }
}
