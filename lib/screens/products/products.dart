import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/advisory/advisory.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/explore/explore.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _selectedIndex = 1; // Products tab selected
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
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Products",
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
            children: [
              const SizedBox(height: 20),
              Center(
                child: SvgPicture.asset("assets/svgs/products/product.svg"),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkInputBorder),
                ),
                child: Column(
                  children: [
                    AppText(
                      "The Products feature will serve as a comprehensive financial marketplace within your app, offering you one-stop access to a wide range of investment and financial products.",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navigate based on the selected index
          if (index == 0) {
            // Home tab
            Get.off(
              () => StackedNavbar(selectedIdx: 0),
              transition: Transition.leftToRight,
            );
          } else if (index == 2) {
            // Advisory tab
            Get.off(
              () => const AdvisoryScreen(),
              transition: Transition.rightToLeft,
            );
          } else if (index == 3) {
            // Explore tab
            Get.off(
              () => const ExploreScreen(),
              transition: Transition.rightToLeft,
            );
          }
        },
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextGray,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: "Products",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded),
            label: "Advisory",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Explore",
          ),
        ],
      ),
    );
  }
}
