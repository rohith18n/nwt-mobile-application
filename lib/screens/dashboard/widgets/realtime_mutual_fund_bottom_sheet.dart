import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// A bottom sheet that appears when mutual fund data is retrieved via realtime updates
class RealtimeMutualFundBottomSheet extends StatelessWidget {
  /// Callback when the refresh data button is pressed
  final VoidCallback onRefreshPressed;

  /// Callback when the check now button is pressed
  final VoidCallback onCheckNowPressed;

  /// Constructor
  const RealtimeMutualFundBottomSheet({
    super.key,
    required this.onRefreshPressed,
    required this.onCheckNowPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Title
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Your ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  TextSpan(
                    text: "Mutual Fund",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.linkColor,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  TextSpan(
                    text: " data is ready!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),

            // Animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Lottie.asset('assets/lottie/mf_loading.json'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Savings text
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Switch to ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  TextSpan(
                    text: "potentially save ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  TextSpan(
                    text: CurrencyFormatter.formatRupee(
                      StorageService.read(StorageKeys.MF_SAVINGS_KEY) ?? 0,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Description
            AppText(
              "Your data has been automatically refreshed. Check out our expert analysis & advisory",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // View Analysis button (primary action)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'View Analysis',
                onPressed: () {
                  Navigator.pop(context);
                  onCheckNowPressed();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Refresh Again button (secondary action)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Refresh',
                onPressed: () {
                  Navigator.pop(context);
                  // This will trigger the _refreshData method in UserController
                  // which navigates to the DataFetchedPage and refreshes data
                  onRefreshPressed();
                },
                variant: AppButtonVariant.secondary,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
