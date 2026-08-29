import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/screens/auth/personalize_experience.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/screens/auth/email_otp_verification.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class EmailOnboarding extends StatefulWidget {
  const EmailOnboarding({super.key});

  @override
  State<EmailOnboarding> createState() => _EmailOnboardingState();
}

class _EmailOnboardingState extends State<EmailOnboarding> {
  bool _agreed = true;
  bool _isSigningIn = false;

  final AuthService _authService = AuthService();

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
    AppLogger.info('Google Sign-In initiated', tag: 'EmailOnboarding');

    if (!_agreed) {
      AppLogger.warning(
        'Google Sign-In blocked: Terms not accepted',
        tag: 'EmailOnboarding',
      );
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
      AppLogger.info(
        'Initializing Google Sign-In instance',
        tag: 'EmailOnboarding',
      );
      await GoogleSignIn.instance.initialize();

      AppLogger.info(
        'Calling GoogleSignIn.instance.authenticate()',
        tag: 'EmailOnboarding',
      );
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.googleSignInCancelled,
        );
        AppLogger.warning(
          'Google Sign-In cancelled: googleUser is null',
          tag: 'EmailOnboarding',
        );
        return;
      }

      AppLogger.info(
        'Google Sign-In successful, user: ${googleUser.email}',
        tag: 'EmailOnboarding',
      );

      try {
        AppLogger.info(
          'Attempting to get authentication details',
          tag: 'EmailOnboarding',
        );
        final authDetails = googleUser.authentication;

        try {
          final idToken = authDetails.idToken;
          AppLogger.info(
            'ID Token retrieved: ${idToken != null ? "Present (length: ${idToken.length})" : "null"}',
            tag: 'EmailOnboarding',
          );

          if (idToken != null && idToken.isNotEmpty) {
            await _callGoogleAuthService(idToken, googleUser);
          } else {
            AppLogger.error(
              'ID Token is null or empty',
              tag: 'EmailOnboarding',
            );
            throw Exception('ID Token is null or empty');
          }
        } catch (tokenError) {
          AppLogger.error(
            'Error getting ID token: ${tokenError.toString()}',
            tag: 'EmailOnboarding',
            error: tokenError,
          );

          try {
            AppLogger.info(
              'Attempting fallback: awaiting authentication',
              tag: 'EmailOnboarding',
            );
            final futureAuth = await googleUser.authentication;
            final futureIdToken = futureAuth.idToken;

            AppLogger.info(
              'Fallback ID Token: ${futureIdToken != null ? "Present (length: ${futureIdToken.length})" : "null"}',
              tag: 'EmailOnboarding',
            );

            if (futureIdToken != null && futureIdToken.isNotEmpty) {
              await _callGoogleAuthService(futureIdToken, googleUser);
            } else {
              AppLogger.error(
                'Fallback ID Token also null or empty',
                tag: 'EmailOnboarding',
              );
              throw Exception('Future ID Token also null');
            }
          } catch (futureError) {
            AppLogger.error(
              'Fallback authentication failed: ${futureError.toString()}',
              tag: 'EmailOnboarding',
              error: futureError,
            );
            rethrow;
          }
        }
      } catch (e) {
        AppLogger.error(
          'Authentication details extraction failed: ${e.toString()}',
          tag: 'EmailOnboarding',
          error: e,
        );
        rethrow;
      }
    } catch (error) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.googleSignInFailed,
        parameters: {
          AnalyticsParams.errorCode:
              error is FirebaseAuthException ? error.code : 'unknown',
          AnalyticsParams.errorMessage: error.toString(),
        },
      );
      AppLogger.error(
        'Google Sign-In error: ${error.toString()}',
        tag: 'EmailOnboarding',
        error: error,
      );

      if (mounted) {
        String errorMessage = 'Sign in failed. Please try again.';

        if (error is FirebaseAuthException) {
          AppLogger.error(
            'FirebaseAuthException - Code: ${error.code}, Message: ${error.message}',
            tag: 'EmailOnboarding',
          );

          switch (error.code) {
            case 'account-exists-with-different-credential':
              errorMessage =
                  'An account already exists with a different sign-in method.';
              break;
            case 'invalid-credential':
              errorMessage = 'Invalid credentials. Please try again.';
              break;
            case 'operation-not-allowed':
              errorMessage =
                  'Google sign-in is not enabled. Please contact support.';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled.';
              break;
            case 'user-not-found':
              errorMessage = 'No account found. Please try again.';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection.';
              break;
            default:
              errorMessage =
                  'Sign in failed: ${error.message ?? 'Unknown error'}';
          }
        } else {
          AppLogger.error(
            'Non-Firebase error type: ${error.runtimeType}',
            tag: 'EmailOnboarding',
          );
        }
        SnackbarHelper.showError(
          title: 'Sign In Failed',
          message: errorMessage,
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
    // Log Google Sign-In email
    AppLogger.info('Calling Google Auth Service', tag: 'EmailOnboarding');
    AppLogger.info(
      'Google Sign-In Email: ${googleUser.email}',
      tag: 'EmailOnboarding',
    );
    AppLogger.info(
      'Google Sign-In Display Name: ${googleUser.displayName ?? 'null'}',
      tag: 'EmailOnboarding',
    );
    AppLogger.info(
      'Google Sign-In ID: ${googleUser.id}',
      tag: 'EmailOnboarding',
    );
    AppLogger.info(
      'ID Token length: ${idToken.length}',
      tag: 'EmailOnboarding',
    );

    try {
      AppLogger.info(
        'Calling _authService.googleAuth()',
        tag: 'EmailOnboarding',
      );

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

      AppLogger.info(
        'Auth service response: success=${response?.success}, message=${response?.message}',
        tag: 'EmailOnboarding',
      );

      if (response != null && response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.googleSignInSuccess);
        AppLogger.info(
          'Authentication successful, requesting FCM permissions',
          tag: 'EmailOnboarding',
        );

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

        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

          final fcmToken = await FirebaseMessaging.instance.getToken();
          AppLogger.info(
            'FCM Token: ${fcmToken != null ? "Retrieved" : "null"}',
            tag: 'EmailOnboarding',
          );

          AppLogger.info(
            'Email auth successful, navigating to personalize experience',
            tag: 'EmailOnboarding',
          );

          // Token already saved by AuthService, navigate to personalize screen
          Get.offAll(
            () => const PersonalizeExperience(),
            transition: Transition.fadeIn,
          );
        } catch (e) {
          AppLogger.error(
            'Error during post-verification, still navigating to personalize screen',
            tag: 'EmailOnboarding',
            error: e,
          );
          Get.offAll(
            () => const PersonalizeExperience(),
            transition: Transition.fadeIn,
          );
        }
      } else {
        AppLogger.error(
          'Authentication failed - Response: ${response?.message ?? "null response"}',
          tag: 'EmailOnboarding',
        );

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
        'Exception in _callGoogleAuthService: ${e.toString()}',
        tag: 'EmailOnboarding',
        error: e,
      );

      if (mounted) {
        SnackbarHelper.showError(
          title: 'Auth Failed',
          message: 'Authentication failed. Please try again.',
        );
      }
    }
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

              const SizedBox(height: 24),

              // Welcome text
              AppText(
                'Welcome to\nPivot Money',
                variant: AppTextVariant.headline1,
                lineHeight: 1.3,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),

              const SizedBox(height: 12),

              // Subtitle
              AppText(
                'Minimal effort. Maximum potential.',
                variant: AppTextVariant.bodyMedium,
                lineHeight: 1.3,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.secondary,
              ),

              const SizedBox(height: 32),

              // Email onboarding illustration
              Center(
                child: SvgPicture.asset(
                  'assets/svgs/onboarding/email_onboarding.svg',
                  height: MediaQuery.of(context).size.height * 0.35,
                  fit: BoxFit.contain,
                  placeholderBuilder:
                      (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  // Add error handling
                  errorBuilder: (context, error, stackTrace) {
                    print('SVG Error: $error');
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms and Privacy Policy checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (val) {
                    setState(() {
                      _agreed = val ?? true;
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: "Montserrat"),
                      children: [
                        const TextSpan(text: 'I accept the '),
                        TextSpan(
                          text: 'Terms of Use',
                          style: const TextStyle(
                            color: AppColors.info,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap =
                                    () => _launchUrl(
                                      'https://www.pivotmoney.app/termsconditions',
                                    ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: AppColors.info,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap =
                                    () => _launchUrl(
                                      'https://www.pivotmoney.app/privacy-policy',
                                    ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Google Sign-In button
            Obx(
              () =>
                  RemoteConfigService.to.hideGoogleAuth.value
                      ? AppButton(
                        text: 'Continue with Email',
                        isFullWidth: true,
                        variant: AppButtonVariant.primary,
                        onPressed: () {
                          if (!_agreed) {
                            SnackbarHelper.showError(
                              title: 'Sign In',
                              message:
                                  'Please accept the Terms & Conditions and Privacy Policy',
                            );
                            return;
                          }
                          Get.to(
                            () => const EmailOTPVerification(),
                            transition: Transition.rightToLeft,
                          );
                        },
                        leadingIcon: Icons.email_outlined,
                      )
                      : Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isSigningIn
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/svgs/onboarding/google_icon.svg',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
