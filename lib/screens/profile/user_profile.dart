import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/strings.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/financial_profiling/financial_profiling.dart';
import 'package:nwt_app/screens/profile/data_protection.dart';
import 'package:nwt_app/screens/profile/account_details.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/widgets/common/revoke_consent_first_sheet.dart';
import 'package:nwt_app/screens/profile/help_faq.dart';
import 'package:nwt_app/screens/profile/set_pin.dart';
import 'package:nwt_app/screens/profile/setup_biometrics.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/biometric_service.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/custom_switch.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/whatsapp_utils.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final BiometricService _biometricService = BiometricService.to;
  bool isBiometricEnabled = false;
  bool isNotificationEnabled = false;
  final UserController _userController = Get.find<UserController>();
  bool isBiometricAvailable = false;
  bool _isWhatsAppAvailable = false;
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

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    _checkWhatsAppStatus();
    _userController.checkAndCacheUccStatus();
    // Load biometric enabled state
    isBiometricEnabled = _biometricService.isBiometricEnabled;
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricsAvailable();
    if (!available) {
      setState(() {
        isBiometricAvailable = false;
        isBiometricEnabled = false;
      });
    } else {
      setState(() {
        isBiometricAvailable = true;
      });
    }
  }

  Future<void> _checkWhatsAppStatus() async {
    final available = await WhatsAppUtils.isWhatsAppInstalled();
    if (mounted) {
      setState(() {
        _isWhatsAppAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Back',
              button: true,
              hint: 'Go back to previous screen',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.back(),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(CupertinoIcons.back, semanticLabel: 'Back'),
                ),
              ),
            ),
            AppText(
              "User Profile",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 12,
            children: [
              GetBuilder<UserController>(
                builder: (controller) {
                  final user = controller.userData;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17181A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Avatar(
                          path:
                              _userController.userData?.gender?.toLowerCase() ==
                                      'female'
                                  ? 'assets/svgs/dashboard/female.png'
                                  : 'assets/svgs/dashboard/male.png',
                          width: 40,
                          height: 40,
                          isNetworkImage: false,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                user?.firstname != null
                                    ? "${user?.firstname} ${user?.lastname}"
                                    : "",
                                variant: AppTextVariant.bodyLarge,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                              if (user?.phonenumber != null) ...[
                                const SizedBox(height: 4),
                                AppText(
                                  "+91 ${user?.phonenumber}",
                                  variant: AppTextVariant.bodySmall,
                                  weight: AppTextWeight.regular,
                                  colorType: AppTextColorType.secondary,
                                ),
                              ],
                              Obx(() {
                                final uccData =
                                    controller.uccStatusResponse.value?.data;
                                final clientCode =
                                    uccData?.investor?.clientCode ??
                                    uccData?.uccStatusObject?.clientCode;

                                if (clientCode != null &&
                                    clientCode.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: AppText(
                                      "Client Code: $clientCode",
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.medium,
                                      customColor: AppColors.darkInputHintText,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                            ],
                          ),
                        ),
                        // IconButton(
                        //   icon: const Icon(
                        //     CupertinoIcons.pencil,
                        //     color: Colors.white,
                        //     size: 20,
                        //   ),
                        //   onPressed: () {
                        //     Get.to(
                        //       () => const EditProfile(),
                        //       transition: Transition.rightToLeft,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  );
                },
              ),

              // _buildMenuItem(
              //   leadingIcon: CupertinoIcons.link,
              //   title: 'Manage Connections',
              //   onTap: () {},
              // ),
              // _buildMenuItem(
              //   leadingIcon: CupertinoIcons.chart_bar_alt_fill,
              //   title: 'Financial Profiling',
              //   onTap: () {
              //     AnalyticsService.to.logEvent(
              //       name: AnalyticsEvents.userProfileFinancialProfilingClicked,
              //     );
              //     Get.to(
              //       () => FinancialProfiling(
              //         isUserAnswered:
              //             _userController.userData?.isfpquestionanswered ??
              //             false,
              //       ),
              //       transition: Transition.rightToLeft,
              //     );
              //   },
              // ),
              // _buildMenuItem(
              //   leadingIcon: CupertinoIcons.person_crop_circle_fill,
              //   title: 'Account Details',
              //   onTap: () {
              //     Get.to(
              //       () => const AccountDetailsScreen(),
              //       transition: Transition.rightToLeft,
              //     );
              //   },
              // ),
              _buildMenuItem(
                leadingIcon: CupertinoIcons.lock,
                title: 'Set Pin',
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfileSetPinClicked,
                  );
                  Get.to(
                    () => SetPin(
                      phoneNumber: _userController.userData?.phonenumber ?? '',
                      isBiometricEnabled: _biometricService.isBiometricEnabled,
                      isFromProfile: true,
                    ),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                leadingIcon: CupertinoIcons.question_circle,
                title: 'Help & FAQ',
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfileHelpFaqClicked,
                  );
                  Get.to(
                    () => const HelpAndFAQScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                leadingIcon: CupertinoIcons.shield,
                title: 'Data Protection',
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfileDataProtectionClicked,
                  );
                  Get.to(
                    () => DataProtectionScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              _buildMenuItem(
                leadingIcon: CupertinoIcons.doc_text,
                title: 'Privacy Policy',
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfilePrivacyPolicyClicked,
                  );
                  _launchUrl('https://www.pivotmoney.app/privacy-policy');
                },
              ),
              _buildMenuItem(
                leadingIcon: CupertinoIcons.doc_plaintext,
                title: 'Terms & Conditions',
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfileTermsConditionsClicked,
                  );
                  _launchUrl('https://www.pivotmoney.app/termsconditions');
                },
              ),

              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   height: 55,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFF17181A),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Row(
              //         children: [
              //           const Icon(
              //             CupertinoIcons.bell,
              //             color: Colors.white,
              //             size: 18,
              //           ),
              //           const SizedBox(width: 24),
              //           const AppText(
              //             'Show Notifications',
              //             variant: AppTextVariant.bodyMedium,
              //             weight: AppTextWeight.semiBold,
              //             colorType: AppTextColorType.primary,
              //           ),
              //         ],
              //       ),
              //       CustomSwitch(
              //         value: isNotificationEnabled,
              //         onChanged: (value) {
              //           setState(() {
              //             isNotificationEnabled = value;
              //           });
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              Semantics(
                label: 'Biometric Lock',
                toggled: isBiometricEnabled,
                hint: 'Double tap to toggle biometric authentication',
                container: true,
                child: MergeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF17181A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.lock_shield,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 24),
                            const AppText(
                              'Biometric Lock',
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                          ],
                        ),
                        CustomSwitch(
                          value: isBiometricEnabled,
                          onChanged: (value) async {
                            AnalyticsService.to.logEvent(
                              name:
                                  AnalyticsEvents
                                      .userProfileBiometricLockToggled,
                              parameters: {
                                "action": value ? "enabled" : "disabled",
                              },
                            );
                            if (value) {
                              _showBiometricDialog(context);
                            } else {
                              // Save disabled state to storage and update UI
                              await BiometricService.to.setBiometricEnabled(
                                false,
                              );
                              setState(() {
                                isBiometricEnabled = false;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Support Button toggle
              // GetBuilder<UserController>(
              //   builder: (controller) {
              //     return Container(
              //       padding: const EdgeInsets.symmetric(horizontal: 16),
              //       height: 55,
              //       decoration: BoxDecoration(
              //         color: const Color(0xFF17181A),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Row(
              //             children: [
              //               const Icon(
              //                 CupertinoIcons.chat_bubble_2,
              //                 color: Colors.white,
              //                 size: 18,
              //               ),
              //               const SizedBox(width: 24),
              //               const AppText(
              //                 'Floating Support Button',
              //                 variant: AppTextVariant.bodyMedium,
              //                 weight: AppTextWeight.semiBold,
              //                 colorType: AppTextColorType.primary,
              //               ),
              //             ],
              //           ),
              //           CustomSwitch(
              //             value: !controller.isSupportButtonHidden,
              //             onChanged: (value) {
              //               controller.setSupportButtonHidden(!value);
              //             },
              //           ),
              //         ],
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Obx(() {
              final remoteConfig = RemoteConfigService.to;
              final config = remoteConfig.supportContactConfig.value;

              // Get email from JSON config
              String supportEmail = SupportContactService.defaultSupportEmail;

              if (config != null) {
                final contextConfig =
                    config[SupportContactService.contextKeyDeleteAccount];
                if (contextConfig != null) {
                  supportEmail =
                      contextConfig[SupportContactService.jsonKeySupportEmail]
                          as String? ??
                      SupportContactService.defaultSupportEmail;
                }
              }

              return FutureBuilder<String>(
                future: SupportContactService.getEffectiveContactType(
                  SupportContext.deleteAccount,
                ),
                builder: (context, snapshot) {
                  final contactType =
                      snapshot.data ?? SupportContactService.contactTypeEmail;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contactType ==
                          SupportContactService.contactTypeEmail) ...[
                        Row(
                          children: [
                            AppText(
                              AppStrings.emailUsAt,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                            Semantics(
                              label: supportEmail,
                              link: true,
                              hint: 'Opens email client',
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    if (_userController
                                            .userData
                                            ?.isFinarkeinAa ==
                                        true) {
                                      final list =
                                          await FinarkeinConsentsService()
                                              .getConsents();
                                      if (list.any((c) => c.isActive)) {
                                        showRevokeConsentFirstSheet(context);
                                        return;
                                      }
                                    }
                                    await SupportContactService.contactSupport(
                                      context: SupportContext.deleteAccount,
                                    );
                                  } catch (e) {
                                    AppLogger.error(
                                      'Unhandled error in contact support: $e',
                                      tag: 'UserProfile',
                                    );
                                  }
                                },
                                child: AppText(
                                  supportEmail,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.link,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppText(
                          AppStrings.toDeleteYourAccount,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            AppText(
                              AppStrings.contactUsOn,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                            Semantics(
                              label:
                                  _isWhatsAppAvailable
                                      ? 'Contact on WhatsApp'
                                      : 'Email Support',
                              link: true,
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    if (_userController
                                            .userData
                                            ?.isFinarkeinAa ==
                                        true) {
                                      final list =
                                          await FinarkeinConsentsService()
                                              .getConsents();
                                      if (list.any((c) => c.isActive)) {
                                        showRevokeConsentFirstSheet(context);
                                        return;
                                      }
                                    }
                                    await SupportContactService.contactSupport(
                                      context: SupportContext.deleteAccount,
                                    );
                                  } catch (e) {
                                    AppLogger.error(
                                      'Unhandled error in contact support: $e',
                                      tag: 'UserProfile',
                                    );
                                  }
                                },
                                child: AppText(
                                  _isWhatsAppAvailable
                                      ? AppStrings.whatsApp
                                      : SupportContactService
                                          .defaultSupportEmail,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.link,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppText(
                          AppStrings.toDeleteYourAccount,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ],
                  );
                },
              );
            }),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Logout',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.userProfileLogoutClicked,
                  );
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF17181A),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Logout Confirmation",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Are you sure you want to logout? You'll need to login again to access your account.",
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
                        color: Colors.white.withOpacity(0.1),
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
                          onPressed: () {
                            AnalyticsService.to.logEvent(
                              name: AnalyticsEvents.userProfileLogoutCancelled,
                            );
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: const AppText(
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
                        color: Colors.white.withOpacity(0.1),
                      ),

                      // Logout button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            AnalyticsService.to.logEvent(
                              name: AnalyticsEvents.userProfileLogoutConfirmed,
                            );
                            // Navigator.of(context).pop();
                            // Use AuthService.logout() to properly clear all tokens and storage
                            AuthService().logout();
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
                          child: const AppText(
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

  Widget _buildMenuItem({
    required IconData leadingIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF17181A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: ListTile(
          leading: Icon(leadingIcon, color: Colors.white, size: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minVerticalPadding: 0,
          title: AppText(
            title,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.white,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showPinRequiredDialog(BuildContext context) {
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
                  color: Colors.black.withOpacity(0.2),
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
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_open,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "PIN Required",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Please set up your PIN before enabling biometric authentication. Would you like to set up your PIN now?",
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
                        color: Colors.white.withOpacity(0.1),
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
                          child: const AppText(
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
                        color: Colors.white.withOpacity(0.1),
                      ),

                      // Set PIN button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SetPin(
                                      phoneNumber:
                                          _userController
                                              .userData
                                              ?.phonenumber ??
                                          '',
                                    ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: const AppText(
                            "Set PIN",
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

  void _showBiometricDialog(BuildContext context) async {
    // First check if PIN is set
    final hasPinSet = await MPINService.to.hasPIN();
    if (!hasPinSet) {
      _showPinRequiredDialog(context);
      setState(() {
        isBiometricEnabled = false;
      });
      return;
    }

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
                  color: Colors.black.withOpacity(0.2),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person_crop_circle,
                      color: AppColors.darkButtonPrimaryBackground,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Enable Biometric Lock",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "You'll need to verify your PIN before enabling biometric authentication. Would you like to proceed?",
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
                        color: AppColors.darkInputBorder.withOpacity(0.5),
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
                          child: const AppText(
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
                        color: AppColors.darkInputBorder.withOpacity(0.5),
                      ),

                      // Enable button
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final result = await Get.to(
                              () => const SetupBiometrics(),
                            );
                            if (result == true) {
                              // Save to get_storage and update state
                              await BiometricService.to.setBiometricEnabled(
                                true,
                              );
                              setState(() {
                                isBiometricEnabled = true;
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: const AppText(
                            "Enable",
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
}
