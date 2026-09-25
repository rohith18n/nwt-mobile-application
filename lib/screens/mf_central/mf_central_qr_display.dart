import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/mf_central/mf_central_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/utils/logger.dart';

class MFCentralQRDisplayScreen extends StatefulWidget {
  final String qrBase64;
  final String? reqId;
  final String? clientRefNo;

  const MFCentralQRDisplayScreen({
    super.key,
    required this.qrBase64,
    this.reqId,
    this.clientRefNo,
  });

  @override
  State<MFCentralQRDisplayScreen> createState() => _MFCentralQRDisplayScreenState();
}

class _MFCentralQRDisplayScreenState extends State<MFCentralQRDisplayScreen> {
  bool _isSyncing = false;
  String? _syncMessage;
  bool? _syncSuccess;

  Uint8List _decodeBase64Image() {
    // Remove data:image/png;base64, prefix if present
    String base64String = widget.qrBase64;
    if (base64String.contains(',')) {
      base64String = base64String.split(',')[1];
    }
    return base64Decode(base64String);
  }

  Future<void> _syncPortfolio() async {
    if (widget.reqId == null) {
      setState(() {
        _syncMessage = 'Request ID is missing';
        _syncSuccess = false;
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncMessage = null;
      _syncSuccess = null;
    });

    AppLogger.info(
      '🔄 Starting portfolio sync - ReqID: ${widget.reqId}',
      tag: 'MF_Central',
    );

    final response = await MFCentralService().syncPortfolio(
      reqId: widget.reqId!,
      qrBase64: widget.qrBase64,
      clientRefNo: widget.clientRefNo,
    );

    setState(() {
      _isSyncing = false;
      _syncSuccess = response.success;
      _syncMessage = response.message ?? 
        (response.success ? 'Portfolio synced successfully!' : 'Sync failed');
    });

    if (response.success) {
      AppLogger.info(
        '✅ Portfolio sync successful - PortfolioID: ${response.portfolioId}',
        tag: 'MF_Central',
      );
      
      // Show success dialog
      _showSyncResultDialog(
        success: true,
        message: _syncMessage!,
        portfolioId: response.portfolioId,
      );
    } else {
      AppLogger.error(
        '❌ Portfolio sync failed: $_syncMessage',
        tag: 'MF_Central',
      );
      
      // Show error dialog
      _showSyncResultDialog(
        success: false,
        message: _syncMessage!,
      );
    }
  }

  void _showSyncResultDialog({
    required bool success,
    required String message,
    String? portfolioId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCardBG,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : AppColors.error,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                success ? 'Success!' : 'Sync Failed',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              lineHeight: 1.5,
            ),
            if (portfolioId != null) ...[
              const SizedBox(height: 16),
              AppText(
                'Portfolio ID: $portfolioId',
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.secondary,
              ),
            ],
          ],
        ),
        actions: [
          AppButton(
            text: success ? 'Continue' : 'Close',
            onPressed: () {
              Get.back(); // Close dialog
              if (success) {
                // Navigate to Dashboard with bottom navbar on success
                Get.offAll(
                  () => const StackedNavbar(selectedIdx: 0),
                  transition: Transition.leftToRight,
                );
              }
            },
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppText(
          'MF Central QR Code',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const AppText(
                'Scan this QR code to sync your portfolio',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const AppText(
                'Use the MF Central app to scan this QR code and complete the sync process.',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
                lineHeight: 1.5,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.memory(
                      _decodeBase64Image(),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.reqId != null)
                AppText(
                  'Request ID: ${widget.reqId}',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              if (_syncMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _syncSuccess == true 
                        ? Colors.green.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _syncSuccess == true 
                          ? Colors.green
                          : AppColors.error,
                    ),
                  ),
                  child: AppText(
                    _syncMessage!,
                    variant: AppTextVariant.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: _isSyncing ? 'Syncing...' : 'I have scanned the QR code',
                onPressed: _isSyncing 
                    ? () {} 
                    : () => _syncPortfolio(),
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
