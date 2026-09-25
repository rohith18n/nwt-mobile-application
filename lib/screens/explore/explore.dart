import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/family_finance/screens/family_management.dart';
import 'package:nwt_app/screens/personal_assets/personal_assets.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color iconBackgroundColor,
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.darkTextSecondary, size: 22),
            ),
            const SizedBox(height: 16),
            AppText(
              title,
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.link,
              textAlign: TextAlign.center,
            ),
          ],
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
              onTap: () => BackNavigation.backOrHome(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Explore",
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: AppText(
                  "Explore the features of Pivot Money",
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.family_restroom,
                    title: "Family Finance",
                    iconBackgroundColor: AppColors.darkButtonBorder,
                    onTap:
                        () => Get.to(
                          () => const FamilyManagement(),
                          transition: Transition.rightToLeft,
                        ),
                  ),
                  _buildFeatureCard(
                    icon: Icons.money,
                    title: "Personal Assets",
                    iconBackgroundColor: AppColors.darkButtonBorder,
                    onTap:
                        () => Get.to(
                          () => const PersonalAssetsScreen(),
                          transition: Transition.rightToLeft,
                        ),
                  ),
                  // _buildFeatureCard(
                  //   icon: Icons.calendar_today,
                  //   title: "Financial Calendar",
                  //   iconBackgroundColor: AppColors.darkButtonBorder,
                  // ),
                  // _buildFeatureCard(
                  //   icon: Icons.auto_awesome,
                  //   title: "Finance GPT",
                  //   iconBackgroundColor: AppColors.darkButtonBorder,
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
