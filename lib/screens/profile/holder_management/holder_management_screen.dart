import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/profile/holder_controller.dart';
import 'package:nwt_app/screens/profile/holder_management/holder_detail_screen.dart';
import 'package:nwt_app/types/profile/holder.dart';
import 'package:nwt_app/widgets/common/app_bar.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';

class HolderManagementScreen extends StatelessWidget {
  const HolderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HolderController());

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: CustomAppBar(title: "Secondary Holders", showBackButton: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.darkPrimary),
          );
        }

        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    controller.error.value!,
                    variant: AppTextVariant.bodyLarge,
                    colorType: AppTextColorType.error,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  AppButton(
                    text: "Retry",
                    onPressed: () => controller.fetchHolders(),
                    size: AppButtonSize.small,
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.holders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64.w, color: Colors.grey[700]),
                SizedBox(height: 16.h),
                const AppText(
                  "No Secondary holders added yet.",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding.w),
          itemCount: controller.holders.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final holder = controller.holders[index];
            return _HolderCard(holder: holder);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHolderDialog(context, controller),
        backgroundColor: AppColors.darkPrimary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddHolderDialog(BuildContext context, HolderController controller) {
    final panController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32.h,
              left: 24.w,
              right: 24.w,
              top: 32.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  "Add New Holder",
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                ),
                SizedBox(height: 8.h),
                const AppText(
                  "Provide the PAN number of the secondary holder to verify and add them to your account.",
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.muted,
                ),
                SizedBox(height: 24.h),
                DarkInputField(
                  controller: panController,
                  label: "PAN Number",
                  hintText: "ABCDE1234F",
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: 32.h),
                Obx(
                  () => AppButton(
                    isFullWidth: true,
                    text: "Verify & Add",
                    isLoading: controller.isOperationLoading.value,
                    onPressed: () async {
                      if (panController.text.length != 10) {
                        Get.snackbar(
                          "Invalid PAN",
                          "Please enter a valid 10-digit PAN.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      final success = await controller.addHolder(
                        panController.text,
                      );
                      if (success) {
                        Get.back();
                        Get.snackbar(
                          "Success",
                          controller.operationMessage.value ??
                              "Holder added successfully.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          "Error",
                          controller.operationMessage.value ??
                              "Failed to add holder. Please try again.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _HolderCard extends StatelessWidget {
  final Holder holder;

  const _HolderCard({required this.holder});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => HolderDetailScreen(holderId: holder.id)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppText(
                  holder.name.isNotEmpty ? holder.name[0].toUpperCase() : "?",
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    holder.name,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    holder.panNumber,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
              ),
            ),
            // Icon(
            //   holder.isVerified ? Icons.check_circle : Icons.pending,
            //   color: holder.isVerified ? AppColors.success : AppColors.warning,
            //   size: 20.w,
            // ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20.w),
          ],
        ),
      ),
    );
  }
}
