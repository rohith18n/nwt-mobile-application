import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

/// Shown after MFC completes from the "Track my investments" flow.
/// Displays a success state with manual button to start AA (Finarkein/Saafe) flow.
/// User can tap "Skip" to go straight to dashboard.
class PanVerifiedRedirectScreen extends StatefulWidget {
  final String phoneNumber;
  final String panNumber;

  const PanVerifiedRedirectScreen({
    super.key,
    required this.phoneNumber,
    required this.panNumber,
  });

  @override
  State<PanVerifiedRedirectScreen> createState() =>
      _PanVerifiedRedirectScreenState();
}

class _PanVerifiedRedirectScreenState
    extends State<PanVerifiedRedirectScreen>
    with SingleTickerProviderStateMixin {
  bool _navigating = false;
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _startAAFlow() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await AccountAggregatorRouter().openConnection(
      context,
      phoneNumber: widget.phoneNumber,
      showConnectionScreen: false,
      hideBackButton: true,
    );
  }

  void _skipToDashboard() {
    Get.offAll(
      () => const StackedNavbar(selectedIdx: 0),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),

              // Animated check icon
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkAccentGreen.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.darkAccentGreen,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.darkAccentGreen,
                    size: 52.sp,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              AppText(
                'Link your Stocks, ETFs & Bank Accounts',
                variant: AppTextVariant.headline3,
                weight: AppTextWeight.bold,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              AppText(
                "We'll securely fetch your investments from all sources using Account Aggregator. Your data is encrypted and safe.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              const Spacer(),

              // Manual proceed button
              AppButton(
                text: _navigating ? 'Starting...' : 'Start Now',
                isFullWidth: true,
                isLoading: _navigating,
                onPressed: _navigating ? () {} : _startAAFlow,
              ),

              SizedBox(height: 12.h),

              // Skip link
              GestureDetector(
                onTap: _skipToDashboard,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: AppText(
                    'Skip and go to Dashboard',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
