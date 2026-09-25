import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/network/connectivity_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// A widget that shows different content based on network connectivity status
class NetworkSensitive extends StatelessWidget {
  /// Widget to display when online
  final Widget child;

  /// Widget to display when offline (optional)
  final Widget? offlineChild;

  /// Whether to show a default offline message when offlineChild is not provided
  final bool showDefaultOfflineMessage;

  const NetworkSensitive({
    super.key,
    required this.child,
    this.offlineChild,
    this.showDefaultOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectivityService = ConnectivityService.to;
      final isConnected = connectivityService.isConnected;

      if (isConnected) {
        return child;
      } else {
        return offlineChild ?? _buildDefaultOfflineWidget();
      }
    });
  }

  /// Builds the default offline message widget
  Widget _buildDefaultOfflineWidget() {
    if (!showDefaultOfflineMessage) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const AppText(
            "No Internet Connection",
            variant: AppTextVariant.headline4,
            weight: AppTextWeight.semiBold,
          ),
          const SizedBox(height: 8),
          const AppText(
            "Please check your network settings and try again",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.regular,
            colorType: AppTextColorType.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ConnectivityService.to.checkConnectivity();
            },
            icon: const Icon(Icons.refresh),
            label: const AppText(
              "Retry",
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium, full-screen offline overlay screen matching the user mockup design
class OfflineOverlayScreen extends StatelessWidget {
  const OfflineOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connectivityService = ConnectivityService.to;
      final isConnected = connectivityService.isConnected;

      if (isConnected) {
        return const SizedBox.shrink();
      }

      return WillPopScope(
        onWillPop: () async {
          // Allow back navigation to pop underlying screens if possible
          final popped = await Navigator.of(context).maybePop();
          return !popped;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.1),
                radius: 1.0,
                colors: [
                  Color(0xFF242629), // Soft dark greyish center glow
                  Color(0xFF08090A), // Deep black/grey outer
                ],
                stops: [0.0, 0.75],
              ),
            ),
            child: Stack(
              children: [
                // Center Content Illustration and Texts
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Concentric Circles + T Badge Illustration
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer concentric thin ring
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors
                                          .darkButtonPrimaryBackground
                                          .withOpacity(0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Glowing background under outer ring (soft blur effect)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors
                                            .darkButtonPrimaryBackground
                                            .withOpacity(0.12),
                                        blurRadius: 35,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                // Inner solid pink circle with wifi_off icon
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        AppColors.darkButtonPrimaryBackground,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.wifi_tethering_off,
                                      color: Color(0xFF070B13),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Title
                          const Text(
                            "You Are Offline",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF8E9AA7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        "Check your connection and try again.",
                                  ),
                                  TextSpan(text: "\nYour progress is saved"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
