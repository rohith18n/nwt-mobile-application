import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/invest_and_services/invest_and_services_screen.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_browse_screen.dart';
import 'package:animate_do/animate_do.dart';

class OnboardingSuccessScreen extends StatefulWidget {
  final String? fundName;
  final String? isin;
  final String? schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;
  final bool showMfBrowse;

  const OnboardingSuccessScreen({
    super.key,
    this.fundName,
    this.isin,
    this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
    this.showMfBrowse = false,
  });

  @override
  State<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState extends State<OnboardingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2SuccessScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2SuccessScreenViewed, tag: 'event');
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    // If showMfBrowse is true, navigate to MF browse screen
    if (widget.showMfBrowse) {
      Get.offAll(
        () => const MutualFundsBrowseScreen(),
        transition: Transition.fadeIn,
      );
      return;
    }

    // If fund details are provided, navigate to CreateOrderV1Screen
    if (widget.fundName != null &&
        widget.isin != null &&
        widget.schemeCode != null) {
      Get.offAll(
        () => CreateOrderV1Screen(
          fundName: widget.fundName!,
          isin: widget.isin!,
          schemeCode: widget.schemeCode!,
          nav: widget.nav,
          fundLogo: widget.fundLogo,
          minAmount: widget.minAmount,
        ),
        transition: Transition.fadeIn,
      );
    } else {
      // Otherwise, navigate to InvestAndServicesScreen
      Get.offAll(
        () => const InvestAndServicesScreen(),
        transition: Transition.fadeIn,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Success text at top
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: AppText(
                  'SUCCESS',
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
              ),

              const Spacer(),

              // Animated success icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF34C759).withOpacity(0.3),
                        const Color(0xFF34C759).withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF34C759), Color(0xFF30D158)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF34C759),
                            blurRadius: 30,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _checkAnimation,
                        child: Icon(
                          Icons.check_rounded,
                          size: 80.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 48.h),

              // Success message
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    AppText(
                      'You are ready to',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      'invest',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom button
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: SizedBox.shrink(),
                  // ElevatedButton(
                  //   onPressed: _navigateToNextScreen,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.white,
                  //     padding: EdgeInsets.symmetric(vertical: 18.h),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12.r),
                  //     ),
                  //   ),
                  //   child: AppText(
                  //     'EXPLORE MUTUAL FUNDS',
                  //     variant: AppTextVariant.bodyLarge,
                  //     weight: AppTextWeight.bold,
                  //     customColor: Colors.black,
                  //   ),
                  // ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
