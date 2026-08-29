import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/image_compression_helper.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

/// SignatureScreen widget for capturing or uploading signatures
///
/// **IMPORTANT: sAll signaxtures are output in JPEG format only**
/// The API requires jpg/jpeg/tif/tiff format. PNG is NOT supported.
class SignatureScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(String base64Signature) onNext;

  const SignatureScreen({super.key, this.onBack, required this.onNext});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _hasSignature = false;
  bool _isSubmitting = false;

  void _handleDrawStart() {
    if (!_hasSignature) {
      setState(() {
        _hasSignature = true;
      });
      AppLogger.info('Signature drawing started', tag: 'SignatureScreen');
    }
  }

  Future<void> _clearSignature() async {
    AppLogger.info('Clear signature called', tag: 'SignatureScreen');
    _signaturePadKey.currentState!.clear();
    setState(() {
      _hasSignature = false;
    });
  }

  Future<void> _captureSignature() async {
    if (_hasSignature && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        AppLogger.info(
          'Starting signature capture and JPEG conversion',
          tag: 'SignatureScreen',
        );

        // Step 1: Get signature as UI Image from pad
        final ui.Image signatureImage =
            await _signaturePadKey.currentState!.toImage();

        // Step 2: Extract raw bytes with proper background
        final ByteData? byteData = await signatureImage.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );

        if (byteData == null) {
          throw Exception('Failed to extract signature image data');
        }

        // Convert RGBA to PNG with white background
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
          'Signature extracted - Size: ${tempPngBytes.length} bytes',
          tag: 'SignatureScreen',
        );

        // Step 3: Convert to JPEG format
        final jpegBytes = await ImageCompressionHelper.compressFromMemory(
          imageBytes: tempPngBytes,
        );

        AppLogger.info(
          'JPEG conversion complete - Size: ${jpegBytes.length} bytes',
          tag: 'SignatureScreen',
        );

        // Step 4: Convert to Base64 string with data URL prefix
        final String signatureBase64 =
            'data:image/jpeg;base64,${ImageCompressionHelper.convertToBase64(jpegBytes)}';

        AppLogger.info(
          'Base64 encoding complete - Length: ${signatureBase64.length} chars',
          tag: 'SignatureScreen',
        );

        setState(() {
          _isSubmitting = false;
        });

        // Step 5: Return base64 string
        widget.onNext(signatureBase64);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error capturing signature',
          error: e,
          stackTrace: stackTrace,
          tag: 'SignatureScreen',
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2SignatureScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2SignatureScreenViewed, tag: 'event');
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressIndicator(),
                      SizedBox(height: 24.h),
                      _buildTitle(),
                      SizedBox(height: 8.h),
                      _buildSubtitle(),
                      SizedBox(height: 32.h),
                      _buildSignaturePad(),
                      SizedBox(height: 24.h),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Navigator.of(context).pop(),
              child: Tooltip(
                message: 'Back',
                child: Icon(
                  Icons.chevron_left,
                  size: 32.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Semantics(
            header: true,
            child: AppText(
              'SIGNATURE',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Progress step 5 of 5',
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.darkInputBackground,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 5 / 5, // Question 5 of 5
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            'Question 5 of 5',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Semantics(
      header: true,
      child: AppText(
        'Digital Signature',
        variant: AppTextVariant.headline5,
        weight: AppTextWeight.bold,
        colorType: AppTextColorType.primary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AppText(
      'Draw your signature in the box below using your finger or stylus.',
      variant: AppTextVariant.bodyMedium,
      colorType: AppTextColorType.gray,
    );
  }

  Widget _buildSignaturePad() {
    return Semantics(
      label: 'Signature drawing area',
      hint: 'Draw your signature inside this box using your finger or stylus',
      container: true,
      child: Container(
        height: 300.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.darkInputBorder, width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: SfSignaturePad(
            key: _signaturePadKey,
            backgroundColor: Colors.white,
            strokeColor: Colors.black,
            minimumStrokeWidth: 2.0,
            maximumStrokeWidth: 4.0,
            onDrawStart: () {
              _handleDrawStart();
              return false; // Return false to allow drawing (true cancels)
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Semantics(
          button: true,
          label: 'Clear Signature',
          enabled: _hasSignature,
          child: OutlinedButton.icon(
            onPressed: _hasSignature ? _clearSignature : null,
            icon: Icon(
              Icons.clear_rounded,
              size: 22.sp,
              color: _hasSignature ? Colors.white : AppColors.darkTextGray,
            ),
            label: AppText(
              'Clear Signature',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.semiBold,
              customColor:
                  _hasSignature ? Colors.white : AppColors.darkTextGray,
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(
                color: _hasSignature ? Colors.white : AppColors.darkInputBorder,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              (_hasSignature && !_isSubmitting) ? _captureSignature : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: AppColors.darkInputBackground,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child:
              _isSubmitting
                  ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                  : AppText(
                    'NEXT',
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.bold,
                    customColor:
                        (_hasSignature && !_isSubmitting)
                            ? Colors.black
                            : AppColors.darkTextGray,
                  ),
        ),
      ),
    );
  }
}
