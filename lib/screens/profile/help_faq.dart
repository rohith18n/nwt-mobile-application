import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/strings.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndFAQScreen extends StatefulWidget {
  const HelpAndFAQScreen({super.key});

  @override
  State<HelpAndFAQScreen> createState() => _HelpAndFAQScreenState();
}

class _HelpAndFAQScreenState extends State<HelpAndFAQScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'Back',
              onTap: () => Navigator.pop(context),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.chevron_left,
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                  size: 32,
                ),
              ),
            ),
            Semantics(
              header: true,
              child: AppText(
                "Help & FAQ",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                colorType:
                    isDarkMode
                        ? AppTextColorType.primary
                        : AppTextColorType.primary,
              ),
            ),
            const WhatsAppSupportButton(size: 20),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Data Protection Info Card
                _buildInfoCard(
                  "Pivot Money protects your data with bank level Security",
                  isDarkMode,
                ),

                SizedBox(height: 16.h),

                // Support Portal Section

                // _buildSectionTitle("Support Portal", isDarkMode),
                SizedBox(height: 12.h),

                // _buildSupportPortalCard(isDarkMode),
                SizedBox(height: 16.h),

                // FAQ Section
                _buildSectionTitle("Frequently Asked Questions", isDarkMode),
                SizedBox(height: 12.h),

                _buildFAQList(isDarkMode),

                SizedBox(height: 16.h),

                // Contact Us Section
                _buildSectionTitle("Contact Us", isDarkMode),
                SizedBox(height: 12.h),

                _buildContactCard(isDarkMode),

                SizedBox(height: 16.h),

                // Delete Account Section
                // _buildSectionTitle("Delete Account", isDarkMode),
                SizedBox(height: 12.h),

                // _buildDeleteAccountCard(isDarkMode),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, bool isDarkMode) {
    return Semantics(
      container: true,
      label: 'Security Information',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AppText(
          text,
          variant: AppTextVariant.bodyLarge,
          weight: AppTextWeight.medium,
          colorType:
              isDarkMode ? AppTextColorType.primary : AppTextColorType.primary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Semantics(
      header: true,
      child: AppText(
        title,
        variant: AppTextVariant.headline5,
        weight: AppTextWeight.semiBold,
        colorType:
            isDarkMode ? AppTextColorType.primary : AppTextColorType.primary,
      ),
    );
  }

  Widget _buildSupportPortalCard(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with support icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.support_agent_outlined,
                  size: 20.sp,
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "Need Help?",
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                      colorType:
                          isDarkMode
                              ? AppTextColorType.primary
                              : AppTextColorType.primary,
                    ),
                    SizedBox(height: 2.h),
                    AppText(
                      "Get support from our team",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.regular,
                      colorType:
                          isDarkMode
                              ? AppTextColorType.secondary
                              : AppTextColorType.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Action button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.darkPrimary,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              "Create Ticket",
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.tertiary,
            ),
          ),

          SizedBox(height: 12.h),

          // My Tickets link
          GestureDetector(
            onTap: () {
              // Navigate to tickets or external URL
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  "View My Tickets",
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.link,
                ),
                Icon(Icons.chevron_right, size: 16.sp, color: AppColors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList(bool isDarkMode) {
    final faqData = [
      {
        "question": "Why Pivot Money ?",
        "answer":
            "Pivot Money  helps you consolidate all your financial accounts in one place, giving you a complete view of your financial health. Track your investments, savings, loans, and expenses effortlessly while making informed financial decisions.",
      },
      {
        "question": "How will you keep my data secure ?",
        "answer":
            "We use bank-level security with 256-bit encryption, secure APIs, and follow all regulatory compliance standards including RBI guidelines. Your data is protected with multi-layer security protocols and we never store your login credentials.",
      },
      {
        "question": "What will you need to access my\nfinancial information?",
        "answer":
            "We only need read-only access to your financial accounts through the secure, RBI-approved Account Aggregator framework. This allows us to fetch your account balances and transaction history without ever accessing your login credentials.",
      },
      {
        "question": "How frequently will my data be updated?",
        "answer":
            "Your financial data is updated in real-time whenever you open the app. You can also manually refresh your accounts to get the latest information. We sync with your banks and financial institutions multiple times a day to ensure accuracy.",
      },
      {
        "question": "Can I delete my account and revoke\nmy consent?",
        "answer":
            "Yes, you have complete control over your data. You can delete your account and revoke consent at any time from the app settings. Once deleted, all your data will be permanently removed from our servers within 30 days.",
      },
    ];

    return Semantics(
      label: 'Frequently Asked Questions List',
      child: Column(
        children:
            faqData.map((faq) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                child: CustomAccordion(
                  title: faq["question"]!,
                  backgroundColor:
                      isDarkMode
                          ? AppColors.darkCardBG
                          : const Color(0xFFF8F9FA),
                  borderRadius: 12.r,
                  padding: EdgeInsets.zero,
                  child: Semantics(
                    liveRegion: true,
                    label: 'Answer',
                    child: AppText(
                      faq["answer"]!,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.regular,
                      colorType:
                          isDarkMode
                              ? AppTextColorType.secondary
                              : AppTextColorType.secondary,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContactCard(bool isDarkMode) {
    return Obx(() {
      final remoteConfig = RemoteConfigService.to;
      final config = remoteConfig.supportContactConfig.value;

      // Get email from JSON config
      String supportEmail = SupportContactService.defaultSupportEmail;

      if (config != null) {
        final contextConfig =
            config[SupportContactService.contextKeyGeneralSupport];
        if (contextConfig != null) {
          supportEmail =
              contextConfig[SupportContactService.jsonKeySupportEmail]
                  as String? ??
              SupportContactService.defaultSupportEmail;
        }
      }

      return FutureBuilder<String>(
        future: SupportContactService.getEffectiveContactType(
          SupportContext.generalSupport,
        ),
        builder: (context, snapshot) {
          final contactType =
              snapshot.data ?? SupportContactService.contactTypeEmail;

          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? AppColors.darkCardBG : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contactType == SupportContactService.contactTypeEmail) ...[
                  Semantics(
                    link: true,
                    label: '${AppStrings.emailUsAt} $supportEmail',
                    onTap: () async {
                      try {
                        await SupportContactService.contactSupport(
                          context: SupportContext.generalSupport,
                        );
                      } catch (e) {
                        AppLogger.error(
                          'Unhandled error in contact support: $e',
                          tag: 'HelpFAQ',
                        );
                      }
                    },
                    child: Row(
                      children: [
                        AppText(
                          AppStrings.emailUsAt,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType:
                              isDarkMode
                                  ? AppTextColorType.primary
                                  : AppTextColorType.primary,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          supportEmail,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.link,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Semantics(
                    link: true,
                    label: '${AppStrings.messageUsOn} ${AppStrings.whatsApp}',
                    onTap: () async {
                      try {
                        await SupportContactService.contactSupport(
                          context: SupportContext.generalSupport,
                        );
                      } catch (e) {
                        AppLogger.error(
                          'Unhandled error in contact support: $e',
                          tag: 'HelpFAQ',
                        );
                      }
                    },
                    child: Row(
                      children: [
                        AppText(
                          AppStrings.messageUsOn,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType:
                              isDarkMode
                                  ? AppTextColorType.primary
                                  : AppTextColorType.primary,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          AppStrings.whatsApp,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.link,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                AppText(
                  AppStrings.weWillGetBackToYouPromptly,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType:
                      isDarkMode
                          ? AppTextColorType.primary
                          : AppTextColorType.primary,
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildDeleteAccountCard(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        // Handle delete account navigation
        // Navigator.push(context, MaterialPageRoute(builder: (context) => DeleteAccountScreen()));
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Warning icon
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.delete, size: 20.sp, color: AppColors.error),
            ),

            SizedBox(width: 12.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Delete Account",
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    "Permanently remove your account",
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.regular,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(Icons.chevron_right, color: AppColors.info, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: try launching with mode.externalApplication
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // If mailto doesn't work, show options or copy to clipboard
      // _showEmailOptions(email);
    }
  }
}
