import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/mf_central/mf_central_trigger.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_fetching_splash_screen.dart';

class MFCQRDisplayScreen extends StatefulWidget {
  final String qrCodeBase64;
  final String? reqId;
  final String? clientRefNo;
  final VoidCallback? onComplete;

  const MFCQRDisplayScreen({
    super.key,
    required this.qrCodeBase64,
    this.reqId,
    this.clientRefNo,
    this.onComplete,
  });

  @override
  State<MFCQRDisplayScreen> createState() => _MFCQRDisplayScreenState();
}

class _MFCQRDisplayScreenState extends State<MFCQRDisplayScreen>
    with TickerProviderStateMixin {
  static const String _logTag = 'MFCQRDisplay';

  Uint8List? _qrImageBytes;
  String? _qrImageUrl;
  bool _isUrlImage = false;

  // Progress step visibility (animated in sequence)
  final List<bool> _stepVisible = [false, false, false];
  late List<AnimationController> _stepControllers;
  late List<Animation<double>> _stepAnimations;

  static const _steps = [
    (icon: Icons.home_outlined,      label: 'Fetching your fund holdings'),
    (icon: Icons.show_chart_rounded, label: 'Calculating returns & NAVs'),
    (icon: Icons.dashboard_outlined, label: 'Building your dashboard'),
  ];

  @override
  void initState() {
    super.initState();
    _processQRCode();
    _initStepAnimations();
    _runStepsSequence();
  }

  void _initStepAnimations() {
    _stepControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _stepAnimations = _stepControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
  }

  void _runStepsSequence() {
    const delays = [400, 900, 1400];
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) {
          setState(() => _stepVisible[i] = true);
          _stepControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _processQRCode() {
    try {
      final qrData = widget.qrCodeBase64;
      if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
        _isUrlImage = true;
        _qrImageUrl = qrData;
      } else {
        _isUrlImage = false;
        String base64String = qrData;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        _qrImageBytes = base64Decode(base64String);
        AppLogger.info(
          'QR processed, size: ${_qrImageBytes?.length} bytes',
          tag: _logTag,
        );
      }
    } catch (e) {
      AppLogger.error('Error processing QR: $e', tag: _logTag);
    }
  }

  void _onSeePortfolio() {
    AppLogger.info('Navigating to fetching screen', tag: _logTag);
    Get.off(
      () => MFCFetchingSplashScreen(
        qrCodeBase64: widget.qrCodeBase64,
        reqId: widget.reqId,
        clientRefNo: widget.clientRefNo,
        onComplete: widget.onComplete,
      ),
      transition: Transition.fadeIn,
    );
  }

  void _onRetry() {
    AppLogger.info('Retry — re-triggering MF Central journey', tag: _logTag);
    final userController = Get.find<UserController>();
    final pan   = userController.userData?.pannumber ?? '';
    final phone = userController.userData?.phonenumber ??
                  userController.userData?.secondaryphonenumber ?? '';
    Get.off(
      () => MFCentralTriggerScreen(
        panNumber: pan,
        phoneNumber: phone,
      ),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding.w,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 28.h),

                  // "YOUR PORTFOLIO IS TAKING SHAPE"
                  Text(
                    'YOUR PORTFOLIO IS TAKING SHAPE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // QR Code
                  _buildQRImage(),

                  SizedBox(height: 28.h),

                  // Main heading
                  AppText(
                    "We're pulling in your mutual\nfunds from MF Central",
                    variant: AppTextVariant.headline3,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12.h),

                  // Subheading
                  AppText(
                    'Holdings, NAVs, and transaction history —\nso your dashboard is ready with everything in one place.',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 28.h),

                  // Animated progress steps
                  ..._buildProgressSteps(),

                  SizedBox(height: 32.h),

                  // Buttons at bottom of scrollable content
                  Padding(
                    padding: EdgeInsets.only(bottom: 28.h, top: 8.h),
                    child: Column(
                      children: [
                        // See my portfolio
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: _onSeePortfolio,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Fetch my Mutual Funds',
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montserrat',
                                color: Colors.black,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Retry
                        SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: OutlinedButton(
                            onPressed: _onRetry,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.darkTextSecondary,
                              side: BorderSide(
                                color: AppColors.darkTextSecondary.withOpacity(
                                  0.3,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Montserrat',
                                color: AppColors.darkTextSecondary,
                                height: 1.0,
                              ),
                            ),
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
      ),
    );
  }

  List<Widget> _buildProgressSteps() {
    return List.generate(_steps.length, (i) {
      final step = _steps[i];
      return AnimatedBuilder(
        animation: _stepAnimations[i],
        builder: (context, child) {
          return Opacity(
            opacity: _stepAnimations[i].value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - _stepAnimations[i].value)),
              child: child,
            ),
          );
        },
        child: _stepVisible[i]
            ? Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: [
                      // Step icon
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: _stepIconBg(i),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          size: 18.sp,
                          color: _stepIconColor(i),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Label
                      Expanded(
                        child: AppText(
                          step.label,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                      ),

                      // Checkmark — green
                      Container(
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16.sp,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(height: 62.h), // reserve space while animating in
      );
    });
  }

  Color _stepIconBg(int i) => Colors.white.withOpacity(0.1);

  Color _stepIconColor(int i) => Colors.white.withOpacity(0.85);

  Widget _buildQRImage() {
    Widget imageWidget;

    if (_isUrlImage && _qrImageUrl != null) {
      imageWidget = Image.network(
        _qrImageUrl!,
        width: 200.w,
        height: 200.w,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 200.w,
            height: 200.w,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => _placeholderQR(),
      );
    } else if (_qrImageBytes != null) {
      imageWidget = Image.memory(
        _qrImageBytes!,
        width: 200.w,
        height: 200.w,
        fit: BoxFit.contain,
      );
    } else {
      imageWidget = _placeholderQR();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _placeholderQR() {
    return SizedBox(
      width: 200.w,
      height: 200.w,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
