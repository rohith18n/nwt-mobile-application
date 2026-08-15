import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/advisory/tax_advisory.dart';
import 'package:nwt_app/screens/dashboard/components/dashboard_bottom_nav.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class AdvisoryCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  AdvisoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  final int _selectedIndex = 2; // Advisory tab selected

  final List<AdvisoryCard> _advisoryCards = [
    AdvisoryCard(
      title: "Mutual Fund Tax",
      description: "Simplify taxation insights on mutual fund holdings.",
      icon: Icons.calculate_outlined,
      color: Color(0xffB29CE2),
      gradient: [
        Color(0xffB29CE2).withValues(alpha: 0.1),
        Color(0xffB29CE2).withValues(alpha: 0.05),
      ],
    ),
    // AdvisoryCard(
    //   title: "Portfolio Simulator",
    //   description: "Simulate and optimize your investment portfolio strategies.",
    //   icon: Icons.assessment_outlined,
    //   color: Color(0xffA28676),
    //   gradient: [
    //     Color(0xffA28676).withValues(alpha: 0.1),
    //     Color(0xffA28676).withValues(alpha: 0.05),
    //   ],
    // ),
    // AdvisoryCard(
    //   title: "Mutual Fund Switch",
    //   description: "Switch between mutual funds seamlessly and efficiently.",
    //   icon: Icons.swap_horiz_outlined,
    //   color: Color(0xff48AEE4),
    //   gradient: [
    //     Color(0xff48AEE4).withValues(alpha: 0.1),
    //     Color(0xff48AEE4).withValues(alpha: 0.05),
    //   ],
    // ),
    // AdvisoryCard(
    //   title: "Goals",
    //   description: "Set and track your financial goals effectively.",
    //   icon: Icons.flag_outlined,
    //   color: Color(0xffCD907F),
    //   gradient: [
    //     Color(0xffCD907F).withValues(alpha: 0.1),
    //     Color(0xffCD907F).withValues(alpha: 0.05),
    //   ],
    // ),
    //  AdvisoryCard(
    //   title: "Bank Advisory",
    //   description: "Get expert advice on banking products and services.",
    //   icon: Icons.account_balance_outlined,
    //   color: Color(0xffCEE29C),
    //   gradient: [
    //     Color(0xffCEE29C).withValues(alpha: 0.1),
    //     Color(0xffCEE29C).withValues(alpha: 0.05),
    //   ],
    // ),
    //  AdvisoryCard(
    //   title: "Will & Succession Planning",
    //   description: "Plan your legacy and succession strategies effectively.",
    //   icon: Icons.gavel_outlined,
    //   color: Color(0xff485DE4),
    //   gradient: [
    //     Color(0xff485DE4).withValues(alpha: 0.1),
    //     Color(0xff485DE4).withValues(alpha: 0.05),
    //   ],
    // ),
  ];
  Widget _buildAdvisoryCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            Get.to(() => const TaxAdvisoryScreen());
          },
          borderRadius: BorderRadius.circular(16),

          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  top: -30,
                  right: 90,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.02),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 100,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 5,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              title,
                              variant: AppTextVariant.headline5,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                              maxLines: 2,
                            ),
                            SizedBox(height: 4),
                            AppText(
                              description,
                              variant: AppTextVariant.tiny,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: color.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.offAll(() => StackedNavbar(selectedIdx: 0),
              transition: Transition.rightToLeft,
              ),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Advisory",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                spacing: 12,
                children: [
                  ..._advisoryCards.map(
                    (card) => _buildAdvisoryCard(
                      title: card.title,
                      description: card.description,
                      icon: card.icon,
                      color: card.color,
                      gradient: card.gradient,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _selectedIndex = index;
      //     });

      //     // Navigate based on the selected index
      //     if (index == 0) { // Home tab
      //       Get.off(() => const StackedNavbar(), transition: Transition.leftToRight);
      //     } else if (index == 1) { // Products tab
      //       Get.off(() => const ProductsScreen(), transition: Transition.leftToRight);
      //     } else if (index == 3) { // Explore tab
      //       Get.off(() => const ExploreScreen(), transition: Transition.rightToLeft);
      //     }
      //   },
      //   selectedItemColor: AppColors.darkPrimary,
      //   unselectedItemColor: AppColors.darkTextGray,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home_rounded),
      //       label: "Home",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.category_rounded),
      //       label: "Products",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.smart_toy_rounded),
      //       label: "Advisory",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.dashboard_rounded),
      //       label: "Explore",
      //     ),
      //   ],
      // ),
    );
  }
}
