import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/aa_branding.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/profile/consent_revoke_screen.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class DataProtectionScreen extends StatefulWidget {
  const DataProtectionScreen({super.key});

  @override
  State<DataProtectionScreen> createState() => _DataProtectionScreenState();
}

class _DataProtectionScreenState extends State<DataProtectionScreen> {
  final UserController _userController = Get.find<UserController>();
  bool? _hasConsents;

  @override
  void initState() {
    super.initState();
    _loadConsentsIfFinarkein();
  }

  Future<void> _loadConsentsIfFinarkein() async {
    final user = _userController.userData;
    if (user?.isFinarkeinAa != true) {
      if (mounted) setState(() => _hasConsents = false);
      return;
    }
    try {
      // Force refresh so we use fresh consent list; cache may be empty or stale when opening this screen.
      final list = await FinarkeinConsentsService().getConsents(
        forceRefresh: true,
      );
      if (mounted) setState(() => _hasConsents = list.any((c) => c.isActive));
    } catch (_) {
      if (mounted) setState(() => _hasConsents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
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
                  CupertinoIcons.back,
                  color: AppColors.darkTextPrimary,
                  size: 24.sp,
                ),
              ),
            ),
            Semantics(
              header: true,
              child: AppText(
                "Data Protection",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
            ),
            const WhatsAppSupportButton(size: 20),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Shield Icon
              ExcludeSemantics(
                child: SizedBox(
                  width: 120.w,
                  height: 120.h,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/data_protection.svg',
                      width: 120.w,
                      height: 120.h,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              // Main Description
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AppText(
                  "Pivot Money protects your data\nwith bank level Security",
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.primary,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 30.h),

              // We Are Section
              _buildSectionTitle("We Are:"),
              SizedBox(height: 16.h),

              _buildFeatureCard(
                "Financial Information User (FIU) compliant with Saha-mati, RBI initiative (pending certification)",
                true,
              ),
              SizedBox(height: 12.h),

              _buildFeatureCard(
                "SEBI registered investment advisor (pending approval)",
                true,
              ),
              SizedBox(height: 12.h),

              _buildFeatureCard("DPDPA Compliant", true),
              SizedBox(height: 12.h),

              _buildFeatureCard("ISO certification (pending)", true),

              SizedBox(height: 30.h),

              // We will not Section
              _buildSectionTitle("We will not:"),
              SizedBox(height: 16.h),

              _buildFeatureCard(
                "Store your sensitive data, passwords and account numbers",
                false,
              ),
              SizedBox(height: 12.h),

              _buildFeatureCard(
                "Provide Third party access to your data",
                false,
              ),
              SizedBox(height: 12.h),

              _buildFeatureCard("Share Your Data", false),
              SizedBox(height: 12.h),

              _buildFeatureCard("Sell your Data", false),

              SizedBox(height: 30.h),

              // RBI Account Aggregator Info
              Semantics(
                container: true,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkButtonBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with RBI icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            "Pivot Money",
                            variant: AppTextVariant.headline6,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.primary,
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        "leverages RBI's Account Aggregator platform to give you a secure way to share your bank account information with trusted financial institutions.",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.primary,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Saafe Partner Info
              Semantics(
                container: true,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      AppText(
                        "Our partner directly accesses your bank data and provides it to us in an encrypted format.",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.primary,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Image.asset(AaBranding.logoAssetPath),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              AppText(
                "We use your information solely to help you manage\nyour finances. You can withdraw consent anytime.\nYour data is fully protected.",
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.regular,
                colorType: AppTextColorType.link,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30.h),

              // Delink account (Finarkein only). Show when we have consents or while loading (null);
              // only hide when we know there are no active consents (_hasConsents == false).
              if (_userController.userData?.isFinarkeinAa == true &&
                  _hasConsents != false) ...[
                AppButton(
                  text: 'Delink account',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ConsentRevokeScreen(),
                      ),
                    );
                    _loadConsentsIfFinarkein();
                  },
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  isFullWidth: true,
                  isDisabled: FinarkeinConsentsService.isRevokeInProgress,
                ),
                SizedBox(height: 20.h),
              ],

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: AppText(
          title,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String text, bool isPositive) {
    return Semantics(
      label: '${isPositive ? 'Compliant' : 'We do not'}: $text',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.darkButtonBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            ExcludeSemantics(
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isPositive ? AppColors.success : AppColors.error)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isPositive ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Text
            Expanded(
              child: AppText(
                text,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.primary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
