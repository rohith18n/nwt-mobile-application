import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

/// A page that shows a loading animation when data is being fetched
/// and automatically redirects back to the dashboard after a delay
class DataFetchedPage extends StatefulWidget {
  const DataFetchedPage({super.key});

  @override
  State<DataFetchedPage> createState() => _DataFetchedPageState();
}

class _DataFetchedPageState extends State<DataFetchedPage> {
  @override
  void initState() {
    super.initState();

    // Redirect back to dashboard after 2 seconds
    Future.delayed(const Duration(seconds: 4), () {
      AppLogger.info('Redirecting back to dashboard', tag: 'DataFetchedPage');
      Get.off(() => StackedNavbar(selectedIdx: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset('assets/lottie/pan.json', repeat: true),
              ),

              const SizedBox(height: 24),

              // Title
              AppText(
                "Refreshing Data",
                variant: AppTextVariant.headline2,
                colorType: AppTextColorType.white,
              ),

              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AppText(
                  "Your mutual fund data is being refreshed. You'll be redirected automatically.",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
