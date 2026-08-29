import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'dart:typed_data';
import 'dart:convert';

class SignatureConfirmationScreen extends StatefulWidget {
  final String signatureBase64;
  final Uint8List signatureBytes;
  final Function(String) onConfirm;
  final VoidCallback onClear;

  const SignatureConfirmationScreen({
    super.key,
    required this.signatureBase64,
    required this.signatureBytes,
    required this.onConfirm,
    required this.onClear,
  });

  @override
  State<SignatureConfirmationScreen> createState() =>
      _SignatureConfirmationScreenState();
}

class _SignatureConfirmationScreenState
    extends State<SignatureConfirmationScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Log signature info
    AppLogger.info(
      'SignatureConfirmationScreen initialized - Base64 length: ${widget.signatureBase64.length} characters, Image size: ${widget.signatureBytes.length} bytes',
      tag: 'SignatureConfirmation',
    );
    AppLogger.info(
      'Base64 preview: ${widget.signatureBase64.substring(0, widget.signatureBase64.length > 50 ? 50 : widget.signatureBase64.length)}...',
      tag: 'SignatureConfirmation',
    );
  }

  Future<void> _handleConfirm() async {
    AppLogger.info(
      '=== SIGNATURE CONFIRMATION SUBMIT STARTED ===',
      tag: 'SignatureConfirmation',
    );
    AppLogger.info('Confirm button pressed', tag: 'SignatureConfirmation');

    if (_isSubmitting) {
      AppLogger.info(
        'Already submitting, skipping',
        tag: 'SignatureConfirmation',
      );
      return;
    }

    AppLogger.info(
      'Setting _isSubmitting to true',
      tag: 'SignatureConfirmation',
    );
    setState(() {
      _isSubmitting = true;
    });

    try {
      AppLogger.info(
        '=== SIGNATURE DATA DETAILS ===',
        tag: 'SignatureConfirmation',
      );
      AppLogger.info(
        'Base64 length: ${widget.signatureBase64.length} characters',
        tag: 'SignatureConfirmation',
      );
      AppLogger.info(
        'Image bytes length: ${widget.signatureBytes.length} bytes',
        tag: 'SignatureConfirmation',
      );
      AppLogger.info(
        'Base64 first 100 chars: ${widget.signatureBase64.substring(0, widget.signatureBase64.length > 100 ? 100 : widget.signatureBase64.length)}',
        tag: 'SignatureConfirmation',
      );

      AppLogger.info(
        'Calling parent onConfirm callback...',
        tag: 'SignatureConfirmation',
      );

      // Call parent callback with base64 string
      await widget.onConfirm(widget.signatureBase64);

      AppLogger.info(
        '=== SIGNATURE SUBMISSION COMPLETED SUCCESSFULLY ===',
        tag: 'SignatureConfirmation',
      );

      // Reset loading state after successful submission
      if (mounted) {
        AppLogger.info(
          'Widget still mounted, resetting loading state',
          tag: 'SignatureConfirmation',
        );
        setState(() {
          _isSubmitting = false;
        });
      } else {
        AppLogger.warning(
          'Widget not mounted after submission',
          tag: 'SignatureConfirmation',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '=== ERROR IN SIGNATURE SUBMISSION ===',
        tag: 'SignatureConfirmation-ERROR',
      );
      AppLogger.error(
        'Error type: ${e.runtimeType}',
        tag: 'SignatureConfirmation-ERROR',
      );
      AppLogger.error(
        'Error message: $e',
        tag: 'SignatureConfirmation-ERROR',
        error: e,
      );
      AppLogger.error(
        'Full stack trace:',
        tag: 'SignatureConfirmation-ERROR',
        stackTrace: stackTrace,
      );
      AppLogger.error(
        'Base64 length at error: ${widget.signatureBase64.length}',
        tag: 'SignatureConfirmation-ERROR',
      );
      AppLogger.error(
        'Image bytes length at error: ${widget.signatureBytes.length}',
        tag: 'SignatureConfirmation-ERROR',
      );

      if (mounted) {
        AppLogger.info(
          'Widget mounted, showing error to user',
          tag: 'SignatureConfirmation-ERROR',
        );
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting signature: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        AppLogger.warning(
          'Widget not mounted, cannot show error snackbar',
          tag: 'SignatureConfirmation-ERROR',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Confirm Your Signature',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppText(
              'Please review and confirm your signature below',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.gray,
              weight: AppTextWeight.medium,
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Signature Display Container
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                widget.signatureBytes.isNotEmpty
                    ? Image.memory(
                      widget.signatureBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.error(
                          'Error displaying signature: $error',
                          tag: 'SignatureConfirmation',
                          error: error,
                          stackTrace: stackTrace,
                        );
                        return Container(
                          alignment: Alignment.center,
                          child: AppText(
                            'Error displaying signature',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.gray,
                          ),
                        );
                      },
                    )
                    : Container(
                      alignment: Alignment.center,
                      child: AppText(
                        'No signature data',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.gray,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        // Signature info text
        Center(
          child: AppText(
            'This signature will be used for your investment documents',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.medium,
          ),
        ),
        const SizedBox(height: 32),
        // Submit Button
        Container(
          width: double.infinity,
          child: AppButton(
            text: 'SUBMIT',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            onPressed: _handleConfirm,
            isLoading: _isSubmitting,
            isDisabled: _isSubmitting,
          ),
        ),
        const SizedBox(height: 16),
        // Clear Button
        Center(
          child: GestureDetector(
            onTap: _isSubmitting ? null : widget.onClear,
            child: AppText(
              'CLEAR',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType:
                  _isSubmitting ? AppTextColorType.gray : AppTextColorType.link,
            ),
          ),
        ),
      ],
    );
  }
}
