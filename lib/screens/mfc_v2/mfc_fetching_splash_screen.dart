import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/mf_central/mf_central_status_controller.dart';
import 'package:nwt_app/services/mf_central/mf_central_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class MFCFetchingSplashScreen extends StatefulWidget {
  final String qrCodeBase64;
  final String? reqId;
  final String? clientRefNo;
  final VoidCallback? onComplete;

  const MFCFetchingSplashScreen({
    super.key,
    required this.qrCodeBase64,
    this.reqId,
    this.clientRefNo,
    this.onComplete,
  });

  @override
  State<MFCFetchingSplashScreen> createState() =>
      _MFCFetchingSplashScreenState();
}

class _MFCFetchingSplashScreenState extends State<MFCFetchingSplashScreen>
    with TickerProviderStateMixin {
  static const String _logTag = 'MFCFetchingSplash';

  late List<AnimationController> _dotControllers;
  late AnimationController _pulseController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dotControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }

    _navigationTimer = Timer(const Duration(seconds: 2), () async {
      // Call sync API to finalize portfolio storage
      await _syncMFCentralData();

      // Poll the MFC status API to get the latest result before going to dashboard
      if (Get.isRegistered<MFCentralStatusController>()) {
        await MFCentralStatusController.to.fetchAndUpdateStatus();
      }
      if (mounted) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Get.offAll(
            () => StackedNavbar(selectedIdx: 0),
            transition: Transition.fadeIn,
          );
        }
      }
    });
  }

  Future<void> _syncMFCentralData() async {
    try {
      AppLogger.info('Calling MF_CENTRAL_SYNC API...', tag: _logTag);

      // Check if we have a reqId, otherwise sync won't work properly
      if (widget.reqId == null) {
        AppLogger.warning(
          'Missing reqId - cannot sync portfolio properly',
          tag: _logTag,
        );
        return;
      }

      final response = await MFCentralService().syncPortfolio(
        reqId: widget.reqId!,
        qrBase64: widget.qrCodeBase64,
        clientRefNo: widget.clientRefNo,
      );

      if (response.success) {
        AppLogger.info(
          'MF_CENTRAL_SYNC successful - PortfolioID: ${response.portfolioId}',
          tag: _logTag,
        );
      } else {
        AppLogger.warning(
          'MF_CENTRAL_SYNC failed: ${response.message}',
          tag: _logTag,
        );
      }
    } catch (e) {
      AppLogger.error('MF_CENTRAL_SYNC error: $e', tag: _logTag);
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLoadingCircle(),
                    SizedBox(height: 32.h),
                    AppText(
                      'Fetching your funds ....',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      'Your holdings will be fetched soon',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 32.h),
                child: AppText(
                  'Please do not press back or close',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.muted,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCircle() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1C1C1E).withOpacity(
              0.7 + _pulseController.value * 0.3,
            ),
          ),
          child: Center(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++) _buildDot(i),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotControllers[index],
      builder: (context, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(
              0.6 + _dotControllers[index].value * 0.4,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
