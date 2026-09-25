import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_browse_screen.dart';
import 'package:nwt_app/controllers/mutual_funds/mf_browse_controller.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/constants/colors.dart';

class InvestAndServicesScreen extends StatefulWidget {
  const InvestAndServicesScreen({super.key});

  @override
  State<InvestAndServicesScreen> createState() =>
      _InvestAndServicesScreenState();
}

class InvestmentCardData {
  final String title;
  final String subtitle;
  final String bgAsset;
  final String iconAsset;
  final bool isVisible;
  final VoidCallback onTap;

  InvestmentCardData({
    required this.title,
    required this.subtitle,
    required this.bgAsset,
    required this.iconAsset,
    this.isVisible = true,
    required this.onTap,
  });
}

class ServiceCardData {
  final String title;
  final String subtitle;
  final String iconAsset;
  final String illustrationAsset;
  final List<Color> borderGradientColors;
  final List<double>? borderGradientStops;
  final List<Color> iconGradientColors;
  final Color baseColor;
  final bool isVisible;
  final bool isForNRI;
  final VoidCallback onTap;

  ServiceCardData({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.illustrationAsset,
    required this.borderGradientColors,
    this.borderGradientStops,
    required this.iconGradientColors,
    required this.baseColor,
    this.isVisible = true,
    this.isForNRI = false,
    required this.onTap,
  });
}

class _InvestAndServicesScreenState extends State<InvestAndServicesScreen> {
  String _selectedTab = 'Invest';

  late final List<InvestmentCardData> _investments = [
    InvestmentCardData(
      title: 'Invest in Mutual Funds',
      subtitle: 'Expertly curated',
      bgAsset: 'assets/imgs/advisory/Group 1.png',
      iconAsset: 'assets/imgs/advisory/investIcon.png',
      isVisible: true,
      onTap: _handleMutualFundsTap,
    ),
    InvestmentCardData(
      title: 'Equity Baskets',
      subtitle: 'Curated investment themes',
      bgAsset: 'assets/imgs/advisory/Group  2.png',
      iconAsset: 'assets/imgs/advisory/investIcon-2.png',
      isVisible: false,
      onTap: () {},
    ),
    InvestmentCardData(
      title: 'ETFs',
      subtitle: 'Low-cost diversification',
      bgAsset: 'assets/imgs/advisory/Group 3.png',
      iconAsset: 'assets/imgs/advisory/investIcon-3.png',
      isVisible: false,
      onTap: () {},
    ),
    InvestmentCardData(
      title: 'Stocks',
      subtitle: 'Direct equity investing',
      bgAsset: 'assets/imgs/advisory/Group 4.png',
      iconAsset: 'assets/imgs/advisory/investIcon-6.png',
      isVisible: false,
      onTap: () {},
    ),
    InvestmentCardData(
      title: 'FDs',
      subtitle: 'Stable fixed returns',
      bgAsset: 'assets/imgs/advisory/Group 5.png',
      iconAsset: 'assets/imgs/advisory/investIcon-5.png',
      isVisible: false,
      onTap: () {},
    ),
  ];

  late final List<ServiceCardData> _services = [
    ServiceCardData(
      title: 'Open \nNRE/NRO \nBank Account',
      subtitle: 'Invest in India from \nabroad',
      iconAsset: 'assets/imgs/advisory/Icon.png',
      illustrationAsset: 'assets/imgs/advisory/illustration 4.png',
      isForNRI: true,
      baseColor: const Color(0xFF031C14),
      borderGradientColors: [
        AppColors.darkPrimary.withValues(alpha: 0.05),

        const Color.fromRGBO(102, 102, 102, 0.105),
      ],
      iconGradientColors: [
        AppColors.darkButtonBorder,
        AppColors.darkButtonBorder,
      ],

      onTap:
          () => Get.to(
            () => const AppWebViewScreen(
              url:
                  'https://digital.idfcfirst.bank.in/apply/NRISavingsAccount?utm_source=pivot',
              title: 'Open NRI Savings Account',
            ),
          ),
    ),
    ServiceCardData(
      title: 'Bank Account Opening',
      subtitle: 'Open Resident \naccounts online',
      iconAsset: 'assets/imgs/advisory/Icon-2.png',
      illustrationAsset: 'assets/imgs/advisory/illustration 4-2.png',
      baseColor: const Color(0xFF06101E),
      borderGradientColors: [
        const Color.fromRGBO(44, 127, 255, 0.5),
        const Color.fromRGBO(102, 102, 102, 0.105),
      ],
      iconGradientColors: [const Color(0xFF2C7FFF), const Color(0xFF1A5ACF)],
      isVisible: false,
      onTap: () {},
    ),
    ServiceCardData(
      title: 'Broking Account Opening',
      subtitle: 'Start investing in \nIndian markets',
      iconAsset: 'assets/imgs/advisory/Icon-3.png',
      illustrationAsset: 'assets/imgs/advisory/illustration 4-3.png',
      baseColor: const Color(0xFF13081A),
      borderGradientColors: [
        const Color.fromRGBO(114, 43, 152, 0.5),
        const Color.fromRGBO(94, 54, 116, 0.485),
        const Color.fromRGBO(102, 102, 102, 0.105),
      ],
      borderGradientStops: [0.0, 0.3894, 1.0],
      iconGradientColors: [const Color(0xFFAD46FF), const Color(0xFFF6339A)],
      isVisible: false,
      onTap: () {},
    ),
    ServiceCardData(
      title: 'Consultations with Experts',
      subtitle: 'Wealth planning & \ntax strategy',
      iconAsset: 'assets/imgs/advisory/Icon-4.png',
      illustrationAsset: 'assets/imgs/advisory/Illustration 5.png',
      baseColor: const Color(0xFF1A1108),
      borderGradientColors: [
        const Color.fromRGBO(161, 75, 0, 0.5),
        const Color.fromRGBO(102, 102, 102, 0.105),
      ],
      borderGradientStops: [0.0, 0.9854],
      iconGradientColors: [const Color(0xFFFF6900), const Color(0xFFFE9A00)],
      isVisible: false,
      onTap: () {},
    ),
  ];

  /// Handle Mutual Funds card tap - go directly to browse screen.
  /// PAN/onboarding gate is handled at the "Invest Now" tap level inside MutualFundsBrowseScreen.
  void _handleMutualFundsTap() {
    AppLogger.info(
      'MF Card Tap - navigating to MF browse screen',
      tag: 'InvestAndServices',
    );
    Get.to(
      () => const MutualFundsBrowseScreen(),
      transition: Transition.rightToLeft,
    );
  }

  @override
  void initState() {
    super.initState();
    // Pre-fetch mutual fund filter options and initial schemes for the listing screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Get.isRegistered<MFBrowseController>()
              ? Get.find<MFBrowseController>()
              : Get.put(MFBrowseController());

      controller.fetchFilterOptions();
      controller.fetchInitialSchemes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 1),

      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: DefaultTabController(
          length: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                _buildHeaderArea(),
                const SizedBox(height: 24),
                _buildTabContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: AppText(
                  "Invest",
                  variant: AppTextVariant.headline2,
                  weight: AppTextWeight.bold,
                ),
              ),
              const WhatsAppSupportButton(
                size: 20,
                color: AppColors.darkPrimary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            "Build & Grow Your Wealth",
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
          const SizedBox(height: 24),
          Container(
            height: 46.h,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _selectedTab = index == 0 ? 'Invest' : 'Services';
                });
              },
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              tabs: const [Tab(text: "Invest"), Tab(text: "Services")],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 'Invest') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.7, // Taller cards to match Figma
          children:
              _investments
                  .where((investment) => investment.isVisible)
                  .map((investment) => _buildInvestmentCard(investment))
                  .toList(),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children:
              _services
                  .where((service) => service.isVisible)
                  .map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildServiceCard(service),
                    ),
                  )
                  .toList(),
        ),
      );
    }
  }

  Widget _buildServiceCard(ServiceCardData service) {
    final semanticLabel =
        '${service.title.replaceAll('\n', ' ')}, ${service.subtitle.replaceAll('\n', ' ')}${service.isForNRI ? ', For NRIs' : ''}';
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: service.onTap,
        child: Container(
          height: 220.h,
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(28),
          ),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              radius: 28,
              strokeWidth: 1.5,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkPrimary.withValues(alpha: 0.3),
                  AppColors.darkPrimary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  // Illustration at bottom right (decorative)
                  // Positioned(
                  //   right: 0,
                  //   bottom: 0,
                  //   child: Opacity(
                  //     opacity: 0.15,
                  //     child: ClipRRect(
                  //       borderRadius: const BorderRadius.only(
                  //         bottomRight: Radius.circular(32),
                  //       ),
                  //       child: Image.asset(
                  //         service.illustrationAsset,
                  //         height: 160.h,
                  //         width: 160.h,
                  //         fit: BoxFit.contain,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Badge at top right
                  if (service.isForNRI)
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkButtonBorder,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.darkPrimary.withValues(alpha: 0.3),

                            width: 1,
                          ),
                        ),
                        child: const AppText(
                          "For NRIs",
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.bold,
                          customColor: AppColors.darkPrimary,
                        ),
                      ),
                    ),
                  // Content Row
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon Container
                        Container(
                          width: 72.w,
                          height: 72.w,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: service.iconGradientColors,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            service.iconAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Text Content
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                service.title,
                                variant: AppTextVariant.headline3,
                                weight: AppTextWeight.bold,
                                customColor: Colors.white,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                service.subtitle,
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.medium,
                                customColor: Colors.white60,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Chevron
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentCardData investment) {
    return Semantics(
      label: '${investment.title}, ${investment.subtitle}',
      button: true,
      child: GestureDetector(
        onTap: investment.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(24),
          ),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              radius: 24,
              strokeWidth: 2,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkPrimary.withValues(alpha: 0.3),
                  AppColors.darkPrimary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  // Top Left Icon
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Image.asset(
                        investment.iconAsset,
                        width: 24.w,
                        height: 24.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Bottom Texts
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          investment.title,
                          textAlign: TextAlign.start,
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          customColor: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        AppText(
                          investment.subtitle,
                          textAlign: TextAlign.start,
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.medium,
                          customColor: Colors.white60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint =
        Paint()
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..shader = gradient.createShader(rect);

    final RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
