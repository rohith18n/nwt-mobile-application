import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/theme_controller.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:nwt_app/screens/auth/personalize_experience.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';
import 'package:nwt_app/screens/auth/email_otp_verification.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _agreed = true;
  bool _isSigningIn = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.welcomeScreenViewed);
      AppLogger.info(AnalyticsEvents.welcomeScreenViewed, tag: 'event');
    });
    _startOnboarding();
  }

  Future<void> _startOnboarding() async {
    if (!Get.isRegistered<AuthFlow>()) {
      Get.put(AuthFlow());
    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController());
    }
    final authFlow = Get.find<AuthFlow>();
    await authFlow.setOnboardingInProgress(true);
  }

  Future<void> _launchUrl(String url) async {
    if (url == 'https://www.pivotmoney.app/termsconditions') {
      Get.to(() => const AppWebViewScreen(
        url: 'https://www.pivotmoney.app/termsconditions',
        title: 'Terms & Conditions',
      ));
      return;
    }
    if (url == 'https://www.pivotmoney.app/privacy-policy') {
      Get.to(() => const AppWebViewScreen(
        url: 'https://www.pivotmoney.app/privacy-policy',
        title: 'Privacy Policy',
      ));
      return;
    }
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    AppLogger.info('Google Sign-In initiated', tag: 'OnboardingScreen');

    if (!_agreed) {
      SnackbarHelper.showError(
        title: 'Sign In',
        message: 'Please accept the Terms & Conditions and Privacy Policy',
      );
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.googleSignInCancelled,
        );
        return;
      }

      final authDetails = await googleUser.authentication;
      final idToken = authDetails.idToken;

      if (idToken != null) {
        await _callGoogleAuthService(idToken, googleUser);
      }
    } catch (error) {
      AppLogger.error('Google Sign-In error: $error', tag: 'OnboardingScreen');
      if (mounted) {
        SnackbarHelper.showError(
          title: 'Sign In Failed',
          message: 'Sign in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _callGoogleAuthService(
    String idToken,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      final response = await _authService.googleAuth(
        token: idToken,
        email: googleUser.email,
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              _isSigningIn = isLoading;
            });
          }
        },
      );

      if (response != null && response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.googleSignInSuccess);

        // Identify user in CleverTap
        if (response.data?.user != null) {
          final user = response.data!.user!;
          await AnalyticsService.to.identifyUser(
            userId: user.id,
            phoneNumber: user.phonenumber ?? user.secondaryphonenumber ?? '',
            name: '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim(),
            email: user.email ?? googleUser.email,
          );
        }

        await FirebaseMessaging.instance.requestPermission();
        final fcmToken = await FirebaseMessaging.instance.getToken();

        AppLogger.info(
          'Google auth successful, navigating to personalize screen',
          tag: 'OnboardingScreen',
        );
        Get.offAll(
          () => const PersonalizeExperience(),
          transition: Transition.fadeIn,
        );
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            title: 'Auth Failed',
            message:
                'Authentication failed: ${response?.message ?? 'Unknown error'}',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Exception in _callGoogleAuthService: $e',
        tag: 'OnboardingScreen',
      );
    }
  }

  void _navigateToPhoneEntry() {
    // Get.to(() => const PersonalizeExperience());
    if (!_agreed) {
      SnackbarHelper.showError(
        title: 'Sign In',
        message: 'Please accept the Terms & Conditions and Privacy Policy',
      );
      return;
    }
    AnalyticsService.to.logEvent(name: AnalyticsEvents.getStartedClicked);
    AppLogger.info(AnalyticsEvents.getStartedClicked, tag: 'event');
    AnalyticsService.to.logEvent(name: AnalyticsEvents.phoneNumberEditClicked);
    Get.to(
      () => const PhoneNumberInputScreen(),
      transition: Transition.rightToLeft,
    );
  }

  void _navigateToEmailEntry() {
    if (!_agreed) {
      SnackbarHelper.showError(
        title: 'Sign In',
        message: 'Please accept the Terms & Conditions and Privacy Policy',
      );
      return;
    }
    AnalyticsService.to.logEvent(name: AnalyticsEvents.getStartedClicked);
    AppLogger.info(AnalyticsEvents.getStartedClicked, tag: 'event');
    AnalyticsService.to.logEvent(name: AnalyticsEvents.emailOtpContinueClicked);
    Get.to(
      () => const EmailOTPVerification(),
      transition: Transition.rightToLeft,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildSocialIcon({
    required Widget icon,
    required VoidCallback? onTap,
    required String semanticsLabel,
    bool isLoading = false,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(51), width: 1),
          ),
          child: Center(
            child:
                isLoading
                    ? Semantics(
                      label: 'Loading $semanticsLabel',
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                    : ExcludeSemantics(child: icon),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Semantics(
              explicitChildNodes: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header sparkles
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/onboarding/stars.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Welcome text
                  Semantics(
                    header: true,
                    child: AppText(
                      'Welcome to\nPivot Money',
                      variant: AppTextVariant.headline1,
                      lineHeight: 1.3,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  const AppText(
                    'Minimal effort. Maximum potential.',
                    variant: AppTextVariant.bodyMedium,
                    lineHeight: 1.3,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
                  ),

                  const SizedBox(height: 48),

                  // Illustration
                  Center(
                    child: SvgPicture.asset(
                      'assets/svgs/onboarding/email_onboarding.svg',
                      height: screenHeight * 0.35,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Onboarding illustration',
                      placeholderBuilder:
                          (context) => Container(
                            height: screenHeight * 0.35,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                    ),
                  ),
                ],
              ),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms and Privacy Policy checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Accept terms and conditions',
                  child: Transform.translate(
                    offset: const Offset(-4, 0),
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (val) {
                        setState(() {
                          _agreed = val ?? true;
                        });
                      },
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Semantics(
                            label: 'I accept the Terms of Use',
                            link: true,
                            onTap:
                                () => _launchUrl(
                                  'https://www.pivotmoney.app/termsconditions',
                                ),
                            child: GestureDetector(
                              onTap:
                                  () => _launchUrl(
                                    'https://www.pivotmoney.app/termsconditions',
                                  ),
                              child: const ExcludeSemantics(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'I accept the ',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: 'Terms of Use',

                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.info,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Semantics(
                            label: 'and Privacy Policy',
                            link: true,
                            onTap:
                                () => _launchUrl(
                                  'https://www.pivotmoney.app/privacy-policy',
                                ),
                            child: GestureDetector(
                              onTap:
                                  () => _launchUrl(
                                    'https://www.pivotmoney.app/privacy-policy',
                                  ),
                              child: const ExcludeSemantics(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: ' and ',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.info,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Primary: Continue with Email
            AppButton(
              text: 'Continue with Email',
              isFullWidth: true,
              variant: AppButtonVariant.primary,
              onPressed: _navigateToEmailEntry,
              leadingIcon: Icons.mail_outline_rounded,
            ),

            const SizedBox(height: 32),

            // Subtle divider
            // Row(
            //   children: [
            //     const Expanded(child: Divider(color: Colors.white10)),
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: AppText(
            //         'or continue with',
            //         variant: AppTextVariant.bodySmall,
            //         colorType: AppTextColForType.secondary,
            //       ),
            //     ),
            //     const Expanded(child: Divider(color: Colors.white10)),
            //   ],
            // ),
            const SizedBox(height: 24),

            // Social Login Icons Row - Phone Only
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  icon: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onTap: _navigateToPhoneEntry,
                  semanticsLabel: 'Continue with Phone Number',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
