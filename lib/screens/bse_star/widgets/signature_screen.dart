import 'package:flutter/material.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/image_compression_helper.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';

/// SignatureScreen widget for capturing or uploading signatures
///
/// **IMPORTANT: All signatures are output in JPEG format only**
/// The API requires jpg/jpeg/tif/tiff format. PNG is NOT supported.
///
/// **Drawn Signatures Process:**
/// 1. Capture from pad (Flutter limitation: temporary PNG format)
/// 2. IMMEDIATELY convert PNG → JPEG (via ImageCompressionHelper)
/// 3. Output: JPEG bytes + base64 string (PNG is never stored or transmitted)
///
/// **Uploaded Signatures Process:**
/// 1. User uploads image (any format: PNG, JPG, etc.)
/// 2. Convert to JPEG format (via ImageCompressionHelper)
/// 3. Output: JPEG bytes + base64 string
///
/// **Final Output:** Always JPEG format - ready for API submission
class SignatureScreen extends StatefulWidget {
  final Future<void> Function(String base64Signature, Uint8List imageBytes)
  onSignatureCaptured;
  final VoidCallback onSignatureCleared;

  const SignatureScreen({
    super.key,
    required this.onSignatureCaptured,
    required this.onSignatureCleared,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _hasSignature = false;
  bool _isSubmitting = false;
  bool _isUploadedSignature = false;

  void _handleDrawStart() {
    if (!_hasSignature) {
      setState(() {
        _hasSignature = true;
      });
      AppLogger.info(
        'Signature drawing started, submit button enabled',
        tag: 'SignatureScreen',
      );
    }
  }

  Future<void> _clearSignature() async {
    AppLogger.info('Clear signature called', tag: 'SignatureScreen');
    _signaturePadKey.currentState!.clear();
    setState(() {
      _hasSignature = false;
      _isUploadedSignature = false;
    });
    AppLogger.info(
      'Signature cleared, submit button disabled',
      tag: 'SignatureScreen',
    );
    widget.onSignatureCleared();
  }

  Future<void> _captureSignature() async {
    if (_hasSignature && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        AppLogger.info(
          'Starting signature capture and JPEG conversion',
          tag: 'SignatureCapture',
        );

        // Step 1: Get signature as UI Image from pad
        final ui.Image signatureImage =
            await _signaturePadKey.currentState!.toImage();

        // Step 2: Extract raw bytes with proper background (Flutter limitation: only PNG format available)
        // Note: This PNG is temporary and will be immediately converted to JPEG
        // Using rawRgba to ensure proper color handling and avoid artifacts
        final ByteData? byteData = await signatureImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        if (byteData == null) {
          throw Exception('Failed to extract signature image data');
        }

        // Convert RGBA to PNG with white background to avoid transparency issues
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        // Draw white background
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            0,
            signatureImage.width.toDouble(),
            signatureImage.height.toDouble(),
          ),
          Paint()..color = Colors.white,
        );

        // Draw the signature on top
        canvas.drawImage(signatureImage, Offset.zero, Paint());

        final ui.Picture picture = recorder.endRecording();
        final ui.Image finalImage = await picture.toImage(
          signatureImage.width,
          signatureImage.height,
        );
        final ByteData? finalByteData = await finalImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final Uint8List tempPngBytes = finalByteData!.buffer.asUint8List();

        AppLogger.info(
          'Signature extracted - Dimensions: ${signatureImage.width}x${signatureImage.height}, Temp size: ${tempPngBytes.length} bytes',
          tag: 'SignatureCapture',
        );

        // Step 3: IMMEDIATELY convert to JPEG format (API requirement: jpg/jpeg/tif/tiff only)
        AppLogger.info(
          'Converting to JPEG format (PNG not supported by API)',
          tag: 'SignatureCapture',
        );
        final jpegBytes = await ImageCompressionHelper.compressFromMemory(
          imageBytes: tempPngBytes,
        );

        AppLogger.info(
          'JPEG conversion complete - Final size: ${jpegBytes.length} bytes',
          tag: 'SignatureCapture',
        );

        // Step 4: Convert JPEG bytes to Base64 string
        final String signatureBase64 = ImageCompressionHelper.convertToBase64(
          jpegBytes,
        );

        AppLogger.info(
          'Base64 encoding complete - JPEG size: ${jpegBytes.length} bytes, Base64 length: ${signatureBase64.length} chars',
          tag: 'SignatureCapture',
        );

        // Step 5: Return JPEG bytes and base64 string
        await widget.onSignatureCaptured(signatureBase64, jpegBytes);

        AppLogger.info(
          'Signature capture callback completed',
          tag: 'SignatureCapture',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error capturing signature: $e',
          tag: 'SignatureCapture',
          error: e,
          stackTrace: stackTrace,
        );
        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error capturing signature: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadSignature() async {
    try {
      AppLogger.info(
        'Opening file picker for signature upload',
        tag: 'SignatureUpload',
      );

      // Pick image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.info('No image selected', tag: 'SignatureUpload');
        return;
      }

      final PlatformFile file = result.files.first;
      AppLogger.info('Image selected: ${file.name}', tag: 'SignatureUpload');

      setState(() {
        _isSubmitting = true;
      });

      // Read image bytes - handle both web and mobile
      Uint8List imageBytes;

      if (file.bytes != null) {
        // Web platform - bytes are directly available
        imageBytes = file.bytes!;
        AppLogger.info(
          'Image loaded from bytes: ${imageBytes.length} bytes',
          tag: 'SignatureUpload',
        );
      } else if (file.path != null) {
        // Mobile platform - read from path
        AppLogger.info(
          'Reading from path: ${file.path}',
          tag: 'SignatureUpload',
        );
        final fileData = await File(file.path!).readAsBytes();
        imageBytes = fileData;
        AppLogger.info(
          'Image loaded from path: ${imageBytes.length} bytes',
          tag: 'SignatureUpload',
        );
      } else {
        AppLogger.error(
          'Could not read file - no bytes or path available',
          tag: 'SignatureUpload',
        );
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not read image file')),
          );
        }
        return;
      }

      // Get original image size info
      final sizeInfo = ImageCompressionHelper.getImageSizeInfo(imageBytes);
      AppLogger.info(
        'Original uploaded image - Size: ${sizeInfo['formatted']}, Valid: ${sizeInfo['isValid']}, Percentage of max: ${sizeInfo['percentageOfMax']}%',
        tag: 'SignatureUpload',
      );

      // Convert to JPEG format (API requirement: jpg/jpeg/tif/tiff only, PNG not supported)
      AppLogger.info(
        'Converting uploaded image to JPEG format',
        tag: 'SignatureUpload',
      );
      final jpegBytes = await ImageCompressionHelper.compressImage(
        imageBytes: imageBytes,
        fileName: file.name,
      );

      // Get JPEG size info
      final jpegSizeInfo = ImageCompressionHelper.getImageSizeInfo(jpegBytes);
      AppLogger.info(
        'JPEG conversion complete - Size: ${jpegSizeInfo['formatted']}, Valid: ${jpegSizeInfo['isValid']}',
        tag: 'SignatureUpload',
      );

      // Convert JPEG to Base64 string
      final String signatureBase64 = ImageCompressionHelper.convertToBase64(
        jpegBytes,
      );

      AppLogger.info(
        'Base64 encoding complete - JPEG size: ${jpegBytes.length} bytes, Base64 length: ${signatureBase64.length} characters',
        tag: 'SignatureUpload',
      );

      // Log FULL base64 string for uploaded image (for debugging)
      AppLogger.info(
        '=== FULL BASE64 FOR UPLOADED JPEG IMAGE ===',
        tag: 'SignatureUpload-FullBase64',
      );
      AppLogger.info(signatureBase64, tag: 'SignatureUpload-FullBase64');
      AppLogger.info(
        '=== END OF FULL BASE64 ===',
        tag: 'SignatureUpload-FullBase64',
      );

      // Return JPEG bytes and base64 string (this navigates to confirmation screen)
      await widget.onSignatureCaptured(signatureBase64, jpegBytes);

      AppLogger.info(
        'Upload signature callback completed',
        tag: 'SignatureUpload',
      );

      // Update state only if widget is still mounted (may have navigated away)
      if (mounted) {
        setState(() {
          _hasSignature = true;
          _isUploadedSignature = true;
          _isSubmitting = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error uploading signature: $e',
        tag: 'SignatureUpload',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadedSignature = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading signature: $e')),
        );
      }
    }
  }

  void _handleSubmitPress() {
    AppLogger.info(
      'Next button pressed, _hasSignature: $_hasSignature',
      tag: 'SignatureScreen',
    );
    if (_hasSignature) {
      AppLogger.info(
        'Calling _captureSignature() to capture and proceed to confirmation',
        tag: 'SignatureScreen',
      );
      _captureSignature();
    } else {
      AppLogger.info(
        'No signature detected, button should be disabled',
        tag: 'SignatureScreen',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Provide Your Signature',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AppText(
              'Sign here or ',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.gray,
              weight: AppTextWeight.medium,
            ),
            GestureDetector(
              onTap: _isSubmitting ? null : _uploadSignature,
              child: AppText(
                'upload here',
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.medium,
                colorType:
                    _isSubmitting
                        ? AppTextColorType.gray
                        : AppTextColorType.link,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Signature Pad Container
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.white,
                  strokeColor: Colors.black,
                  minimumStrokeWidth: 2.0,
                  maximumStrokeWidth: 4.0,
                  onDrawStart: () {
                    if (_isUploadedSignature) {
                      // Prevent drawing if signature was uploaded
                      return true; // Return true to cancel the draw
                    }
                    _handleDrawStart();
                    return false;
                  },
                ),
              ),
              if (_isUploadedSignature)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 48, color: Colors.green),
                        const SizedBox(height: 16),
                        AppText(
                          'Signature Uploaded',
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.success,
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          'Click CLEAR to draw a new signature',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.gray,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Next Button
        Container(
          width: double.infinity,
          child: AppButton(
            text: 'NEXT',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            onPressed: _handleSubmitPress,
            isLoading: _isSubmitting,
            isDisabled: !_hasSignature || _isSubmitting,
          ),
        ),
        const SizedBox(height: 16),
        // Clear Button
        Center(
          child: GestureDetector(
            onTap: _isSubmitting ? null : _clearSignature,
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
