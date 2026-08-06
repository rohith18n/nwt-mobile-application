// lib/screens/onboarding/incomplete_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class IncompleteOnboardingScreen extends StatefulWidget {
  const IncompleteOnboardingScreen({super.key});

  @override
  State<IncompleteOnboardingScreen> createState() =>
      _IncompleteOnboardingScreenState();
}

class _IncompleteOnboardingScreenState
    extends State<IncompleteOnboardingScreen> {
  final UserController _userController = Get.find<UserController>();

  double get _completionPercentage {
    int completedSteps = 1;
    if (_userController.userData!.ispanverified) completedSteps++;
    if (_userController.userData!.ismfverified) completedSteps++;
    return completedSteps / 3; // Returns a value between 0 and 1
  }

  String get _formattedPercentage {
    return '${(_completionPercentage * 100).toInt()}'; // Converts 0.333 to "33"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                (AppSizing.scaffoldHorizontalPadding * 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 30),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _completionPercentage,
                      strokeWidth: 8,
                      backgroundColor: AppColors.darkButtonBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Inner content
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      size: 50,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  // Progress percentage
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _completionPercentage,
                      strokeWidth: 8,
                      backgroundColor: AppColors.lightPrimary.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Title with emphasis
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: AppText(
                      "Almost There!",
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description with better formatting
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: AppText(
                  "You're $_formattedPercentage% done with your setup.\nLet's complete your profile and get started!",
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.regular,
                  textAlign: TextAlign.center,
                  colorType: AppTextColorType.muted,
                ),
              ),

              const SizedBox(height: 50),

              // Feature highlights
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.lightPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppText(
                      "What's waiting for you:",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: AppText(
                            "Personalized experience",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.muted,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: AppText(
                            "Seamless sync across devices",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.muted,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action buttons with modern layout
              Column(
                children: [
                  // Primary button
                  AppButton(
                    text: 'Complete Setup Now',
                    onPressed: () {
                      Get.back(result: true);
                    },
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),

                  const SizedBox(height: 16),

                  // Secondary action as a clean link
                  GestureDetector(
                    onTap: () {
                      Get.back(result: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          const AppText(
                            'Start from beginning',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.muted,
                            weight: AppTextWeight.medium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
