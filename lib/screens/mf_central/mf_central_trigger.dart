import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_qr_display_screen.dart';
import 'package:nwt_app/services/mf_central/mf_central_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MFCentralTriggerScreen extends StatefulWidget {
  final String panNumber;
  final String phoneNumber;
  final VoidCallback? onComplete;

  const MFCentralTriggerScreen({
    super.key,
    required this.panNumber,
    required this.phoneNumber,
    this.onComplete,
  });

  @override
  State<MFCentralTriggerScreen> createState() => _MFCentralTriggerScreenState();
}

class _MFCentralTriggerScreenState extends State<MFCentralTriggerScreen>
    with TickerProviderStateMixin {
  // Animated dots controllers
  late List<AnimationController> _dotControllers;
  late AnimationController _pulseController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _redirectUrl;
  String? _reqId;
  String? _clientRefNo;
  WebViewController? _webViewController;
  bool _isExtracting = false;
  bool _qrExtracted = false;

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

    _triggerMFCentral();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _triggerMFCentral() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use verified PAN and phone number from user
      final userPan = widget.panNumber;
      final userPhone = widget.phoneNumber.replaceAll(
        '+91',
        '',
      ); // Remove country code if present

      AppLogger.info(
        '🔄 Using verified credentials - PAN: $userPan, Phone: $userPhone',
        tag: 'MF_Central',
      );

      final response = await MFCentralService().triggerConnect(
        pan: userPan,
        mobile: userPhone,
      );

      if (response.success && response.redirectUrl != null) {
        setState(() {
          _redirectUrl = response.redirectUrl;
          _reqId = response.reqId;
          _clientRefNo = response.clientRefNo;
          _isLoading = false;
        });

        AppLogger.info(
          '✅ MF Central trigger successful - Opening webview with URL: $_redirectUrl',
          tag: 'MF_Central',
        );
        AppLogger.info(
          '📋 Session Info - ReqID: $_reqId, ClientRefNo: $_clientRefNo',
          tag: 'MF_Central',
        );

        _initializeWebView();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to trigger MF Central';
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        '❌ MF Central trigger error',
        error: e,
        tag: 'MF_Central',
      );
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                AppLogger.info('🌐 WebView loading: $url', tag: 'MF_Central');

                // Check if redirecting to login page - means MF Central flow is complete
                if (url.contains('/user/login') ||
                    url.contains('pivotmoney.app/user/login')) {
                  AppLogger.info(
                    '✅ MF Central flow complete - Detected login redirect',
                    tag: 'MF_Central',
                  );
                  // Extract QR code before closing
                  _extractQRCode();
                }
              },
              onPageFinished: (String url) async {
                AppLogger.info('✅ WebView loaded: $url', tag: 'MF_Central');

                // Don't auto-extract if we're on login page
                if (!url.contains('/user/login')) {
                  // Start continuous QR extraction
                  await Future.delayed(const Duration(seconds: 2));
                  _startContinuousExtraction();
                }
              },
              onWebResourceError: (WebResourceError error) {
                AppLogger.error(
                  '❌ WebView error: ${error.description}',
                  tag: 'MF_Central',
                );
              },
            ),
          )
          ..loadRequest(Uri.parse(_redirectUrl!));
  }

  void _startContinuousExtraction() {
    if (_isExtracting || _qrExtracted) return;

    _isExtracting = true;
    AppLogger.info(
      '🔄 Starting continuous QR extraction (every 1 second)',
      tag: 'QRCode',
    );

    _extractQRCodeContinuously();
  }

  Future<void> _extractQRCodeContinuously() async {
    while (!_qrExtracted && mounted) {
      await _extractQRCode();

      if (!_qrExtracted) {
        // Wait 1 second before next attempt
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _extractQRCode() async {
    try {
      // JavaScript to find and extract QR code image as base64
      const script = '''
        (function() {
          // Find the QR code image
          const qrImage = document.querySelector('img[alt*="QR"], img[src*="qr"], canvas');
          if (qrImage) {
            if (qrImage.tagName === 'CANVAS') {
              return qrImage.toDataURL('image/png');
            } else if (qrImage.tagName === 'IMG') {
              const canvas = document.createElement('canvas');
              canvas.width = qrImage.naturalWidth || qrImage.width;
              canvas.height = qrImage.naturalHeight || qrImage.height;
              const ctx = canvas.getContext('2d');
              ctx.drawImage(qrImage, 0, 0);
              return canvas.toDataURL('image/png');
            }
          }
          return null;
        })();
      ''';

      final result = await _webViewController?.runJavaScriptReturningResult(
        script,
      );

      if (result != null &&
          result.toString().isNotEmpty &&
          result.toString() != 'null' &&
          result.toString() != '<null>') {
        final qrBase64 = result.toString().replaceAll('"', '');

        // Check if it's a valid data URL
        if (qrBase64.startsWith('data:image')) {
          // Mark as extracted to stop continuous extraction
          _qrExtracted = true;

          AppLogger.info(
            '✅ QR Code extracted successfully - Length: ${qrBase64.length}',
            tag: 'MF_Central',
          );

          // Log the complete base64 string
          AppLogger.info('QR Code Base64: $qrBase64', tag: 'QRCode');

          AppLogger.info(
            'QR Code preview (first 100 chars): ${qrBase64.substring(0, qrBase64.length > 100 ? 100 : qrBase64.length)}...',
            tag: 'QRCode',
          );

          // Navigate to QR display screen
          if (mounted) {
            Get.off(
              () => MFCQRDisplayScreen(
                qrCodeBase64: qrBase64,
                reqId: _reqId,
                clientRefNo: _clientRefNo,
                onComplete: widget.onComplete,
              ),
              transition: Transition.rightToLeft,
            );
            AppLogger.info(
              '📋 Navigating to QR display screen - ReqID: $_reqId',
              tag: 'MF_Central',
            );
          }
        } else {
          AppLogger.warning(
            '⚠️ Extracted content is not a valid image data URL. Retrying in 1 second',
            tag: 'QRCode',
          );
        }
      } else {
        AppLogger.warning(
          '⚠️ QR Code extraction attempt returned null or empty - Will retry in 1 second',
          tag: 'QRCode',
        );
      }
    } catch (e) {
      AppLogger.error(
        '❌ Error extracting QR code',
        error: e,
        tag: 'MF_Central',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: _buildAppBar(showBack: false),
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
                        'Redirecting to MF Central',
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
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

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: _buildAppBar(showBack: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                const SizedBox(height: 24),
                AppText(
                  _errorMessage!,
                  variant: AppTextVariant.bodyLarge,
                  colorType: AppTextColorType.error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Retry',
                  onPressed: _triggerMFCentral,
                  isFullWidth: true,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.offAll(
                    () => const StackedNavbar(selectedIdx: 0),
                    transition: Transition.leftToRight,
                  ),
                  child: const AppText(
                    'Go to Dashboard',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_redirectUrl != null && _webViewController != null) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: _buildAppBar(showBack: true),
          body: WebViewWidget(controller: _webViewController!),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(showBack: false),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool showBack}) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? GestureDetector(
              onTap: () => Get.offAll(
                () => const StackedNavbar(selectedIdx: 0),
                transition: Transition.leftToRight,
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            )
          : null,
      title: const AppText(
        'MF Central',
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
      ),
      centerTitle: true,
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
