import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/personal_assets/asset_type.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PersonalAssetsScreen extends StatefulWidget {
  final bool isFamilyMode;

  const PersonalAssetsScreen({super.key, this.isFamilyMode = false});

  @override
  State<PersonalAssetsScreen> createState() => _PersonalAssetsScreen();
}

class _PersonalAssetsScreen extends State<PersonalAssetsScreen> {
  final List<AssetOption> assetOptions = AssetOption.allOptions;

  void _navigateToDetailPage(AssetOption asset) {
    Get.to(() => asset.page, transition: Transition.rightToLeft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Personal Assets",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: AppSizing.scaffoldHorizontalPadding,
          right: AppSizing.scaffoldHorizontalPadding,
          top: 0,
        ),
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: assetOptions.length,
          itemBuilder: (context, index) {
            final asset = assetOptions[index];
            return GestureDetector(
              onTap: () => _navigateToDetailPage(asset),
              child: Container(
                decoration: BoxDecoration(
                  // gradient: _getGradientForAsset(asset.type),
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Enhanced icon container with gradient background
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkButtonBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              asset.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  asset.name,
                                  variant: AppTextVariant.headline5,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                                const SizedBox(height: 2),
                                AppText(
                                  'Personal Asset',
                                  variant: AppTextVariant.caption,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.secondary,
                                ),
                              ],
                            ),
                          ),
                          // Arrow indicator
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description with better formatting
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppText(
                          asset.description,
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.regular,
                          colorType: AppTextColorType.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
