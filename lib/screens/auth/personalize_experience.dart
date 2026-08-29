import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_browse_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/bse_v2_final_journey.dart';
import 'package:nwt_app/services/profile/investment_readiness_service.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/auth/pan_verified_redirect_screen.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_instructions_screen.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/utils/logger.dart';

class PersonalizeExperience extends StatefulWidget {
  const PersonalizeExperience({super.key});

  @override
  State<PersonalizeExperience> createState() => _PersonalizeExperienceState();
}

/// Order of "What brings you here?" options; index matches selection.
const List<OnboardingFlowType> _flowTypeOrder = [
  OnboardingFlowType.trackMyInvestments,
  OnboardingFlowType.exploreMutualFunds,
  OnboardingFlowType.exploreMutualFunds,
];

class _PersonalizeExperienceState extends State<PersonalizeExperience> {
  int _selectedIndex = -1;
  bool _isSubmitting = false;
  late final Stopwatch _screenStopwatch;
  late final Stopwatch _decisionStopwatch;
  bool _hasMadeDecision = false;
  bool _isCheckingOnboardingStatus = true;
  bool _isPhoneValidated = false;
  bool _isEmailValidated = false;
  bool _needsEmailVerification = false;
  String? _phoneNumber;
  String? _email;

  @override
  void initState() {
    super.initState();
    _screenStopwatch = Stopwatch()..start();
    _decisionStopwatch = Stopwatch()..start();
    
    // Check if user has already completed onboarding
    _checkOnboardingStatus();
    
    // Log screen view with spec parameters
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.personalizeExperienceScreenViewed,
      parameters: {
        AnalyticsParams.screenName: 'personalize_experience',
      },
    );
  }
  
  Future<void> _checkOnboardingStatus() async {
    try {
      final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
      AppLogger.info(
        '🔍 PersonalizeExperience loaded - Token exists: ${token != null}, Length: ${token?.length ?? 0}',
        tag: 'PersonalizeExperience',
      );

      // Use validate API to check verification status
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];

        final panVerified   = data['pan']?['status'] == 'verified';
        final phoneVerified = data['phone']?['status'] == 'verified';
        final emailStatus   = data['email']?['status'] as String?;
        final emailVerified = emailStatus == 'verified';
        final contextData   = data['context'] as Map<String, dynamic>? ?? {};
        final needsEmail    = contextData['needs_email'] == true;

        AppLogger.info(
          '🔍 Validate status — PAN: $panVerified, Phone: $phoneVerified, Email: $emailVerified',
          tag: 'PersonalizeExperience',
        );

        // If PAN + phone + email are all verified → user has completed basic onboarding → go to dashboard
        if (panVerified && phoneVerified && emailVerified) {
          AppLogger.info(
            '✅ PAN + phone + email all verified - Redirecting to dashboard',
            tag: 'PersonalizeExperience',
          );
          if (mounted) {
            Get.offAll(() => const StackedNavbar(selectedIdx: 0));
          }
          return;
        }

        // Cache phone verification status for UniversalPanVerificationWidget
        final userController = Get.isRegistered<UserController>()
            ? Get.find<UserController>()
            : Get.put(UserController());
        final phone = userController.userData?.phonenumber
            ?? userController.userData?.secondaryphonenumber;
        final email = userController.userData?.email;

        if (mounted) {
          setState(() {
            _isPhoneValidated = phoneVerified;
            _isEmailValidated = emailVerified;
            _needsEmailVerification = !emailVerified && (needsEmail || emailStatus == 'pending');
            _phoneNumber = phone;
            _email = email;
          });
        }

      }

      AppLogger.info(
        '🆕 Showing personalization screen',
        tag: 'PersonalizeExperience',
      );

    } catch (e) {
      AppLogger.error(
        'Error checking onboarding status: $e',
        tag: 'PersonalizeExperience',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOnboardingStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _screenStopwatch.stop();
    _decisionStopwatch.stop();
    super.dispose();
  }

  final List<Map<String, dynamic>> _options = [
    {'title': 'Track my investments', 'icon': Icons.trending_up_rounded},
    {'title': 'Explore App', 'icon': Icons.explore_rounded},
    {'title': 'Invest in Mutual Funds', 'icon': Icons.auto_awesome_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding status
    if (_isCheckingOnboardingStatus) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      AnalyticsService.to.logEvent(
                        name: AnalyticsEvents.personalizeExperienceLogoutClicked,
                        parameters: {
                          AnalyticsParams.timeOnScreenSeconds: _screenStopwatch.elapsed.inSeconds,
                        },
                      );
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
            ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'What brings you\nhere?',
                        variant: AppTextVariant.headline1,
                        weight: AppTextWeight.bold,
                        lineHeight: 1.2,
                      ),
                      const SizedBox(height: 12),
                      const AppText(
                        'This helps us personalize your experience.',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      const SizedBox(height: 32),

                      // Selection Options
                      ...List.generate(_options.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () async {
                          final previousIndex = _selectedIndex;
                          final flowType = _flowTypeOrder[index].apiValue;
                          final optionTitle = _options[index]['title'];

                          if (!_hasMadeDecision) {
                            _hasMadeDecision = true;
                            _decisionStopwatch.stop();
                          }

                          // Option Deselected
                          if (previousIndex != -1 && previousIndex != index) {
                            AnalyticsService.to.logEvent(
                              name: AnalyticsEvents.personalizeExperienceOptionDeselected,
                              parameters: {
                                AnalyticsParams.selectedOption: _options[previousIndex]['title'],
                                AnalyticsParams.optionIndex: previousIndex,
                              },
                            );
                          }

                          // Option Selected
                          AnalyticsService.to.logEvent(
                            name: AnalyticsEvents.personalizeExperienceOptionSelected,
                            parameters: {
                              AnalyticsParams.selectedOption: optionTitle,
                              AnalyticsParams.optionIndex: index,
                              AnalyticsParams.flowType: flowType,
                              AnalyticsParams.timeOnScreenSeconds: _screenStopwatch.elapsed.inSeconds,
                            },
                          );

                          // Option Displayed (Visual confirmation)
                          AnalyticsService.to.logEvent(
                            name: AnalyticsEvents.personalizeExperienceOptionDisplayed,
                            parameters: {
                              AnalyticsParams.selectedOption: optionTitle,
                              AnalyticsParams.isDisplayedToUser: true,
                            },
                          );

                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardBG,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white10,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _options[index]['icon'],
                                  color: Colors.white70,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppText(
                                  _options[index]['title'],
                                  variant: AppTextVariant.bodyLarge,
                                  weight:
                                      isSelected
                                          ? AppTextWeight.bold
                                          : AppTextWeight.medium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                    ],
                  ),
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
                vertical: 24,
              ),
              child: AppButton(
                text: 'Continue',
                isFullWidth: true,
                onPressed:
                    (_isSubmitting || _selectedIndex == -1 || _isCheckingOnboardingStatus)
                        ? () {}
                        : () => _onContinue(),
                isDisabled: _selectedIndex == -1 || _isSubmitting || _isCheckingOnboardingStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_selectedIndex < 0 || _selectedIndex >= _flowTypeOrder.length) return;
    setState(() => _isSubmitting = true);
    final flowType = _flowTypeOrder[_selectedIndex].apiValue;
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.personalizeExperienceContinueClicked,
      parameters: {
        AnalyticsParams.selectedFlowType: flowType,
        AnalyticsParams.destinationScreen: _selectedIndex == 0 ? 'pan_verification' : 'dashboard',
        AnalyticsParams.timeToDecisionSeconds: _decisionStopwatch.elapsed.inSeconds,
      },
    );

    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.personalizeExperienceContinueSuccess,
      parameters: {
        AnalyticsParams.selectedFlowType: flowType,
      },
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (_selectedIndex == 0) {
      // Track my investments — open universal PAN verification
      AppLogger.info(
        'Track my investments selected — navigating to UniversalPanVerificationWidget',
        tag: 'PersonalizeExperience',
      );
      Get.to(
        () => UniversalPanVerificationWidget(
          showProgress: false,
          title: 'Track my investments',
          phoneNumber: _phoneNumber,
          isPhoneValidated: _isPhoneValidated,
          isEmailValidated: _isEmailValidated,
          needsEmailVerification: _needsEmailVerification,
          email: _email,
          onSuccess: (panData) {
            final phone = (panData['phone_number'] as String? ?? '').replaceAll('+91', '').trim();
            final pan = panData['pan_number'] as String? ?? '';
            AppLogger.info(
              'PAN verified from PersonalizeExperience — navigating to MFC instructions',
              tag: 'PersonalizeExperience',
            );
            Get.to(
              () => MFCInstructionsScreen(
                panNumber: pan,
                phoneNumber: phone,
                onComplete: () {
                  Get.offAll(
                    () => PanVerifiedRedirectScreen(
                      phoneNumber: phone,
                      panNumber: pan,
                    ),
                    transition: Transition.fadeIn,
                  );
                },
              ),
              transition: Transition.rightToLeft,
            );
          },
        ),
        transition: Transition.rightToLeft,
      );
    } else if (_selectedIndex == 1) {
      // Explore App — skip to dashboard, persist flag
      await StorageService.init();
      StorageService.write(StorageKeys.SKIP_TO_DASHBOARD_KEY, true);
      if (!mounted) return;
      Get.offAll(
        () => const StackedNavbar(selectedIdx: 0),
        transition: Transition.rightToLeft,
      );
    } else if (_selectedIndex == 2) {
      // Invest in Mutual Funds — check verification & UCC readiness first
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      bool panVerified = false;
      bool phoneVerified = false;

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        panVerified = data['pan']?['status'] == 'verified';
        phoneVerified = data['phone']?['status'] == 'verified';
      }

      if (!mounted) return;

      if (!panVerified || !phoneVerified) {
        // PAN or phone not verified — full onboarding, then MF listing
        Get.to(
          () => const BseV2FinalJourney(fromPersonalizeFlow: true),
          transition: Transition.rightToLeft,
        );
      } else {
        // PAN + phone verified — check UCC readiness
        final readinessService = InvestmentReadinessService();
        final readiness = await readinessService.canInvestDirectly();

        if (!mounted) return;

        if (readiness['canInvest'] == true) {
          // Fully ready — go directly to MF listing
          Get.to(
            () => const MutualFundsBrowseScreen(),
            transition: Transition.rightToLeft,
          );
        } else {
          // UCC incomplete — onboarding (skip PAN), then MF listing
          Get.to(
            () => const BseV2FinalJourney(
              fromPersonalizeFlow: true,
              skipPanVerification: true,
            ),
            transition: Transition.rightToLeft,
          );
        }
      }
    }
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
                            AnalyticsService.to.logEvent(name: AnalyticsEvents.personalizeExperienceLogoutConfirmed);
                            // Close the dialog first
                            Navigator.of(context).pop();
                            AuthService().logout();
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
}
