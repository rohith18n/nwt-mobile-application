import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/storage_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/image_compression_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/services/auth/ucc_service.dart';

class SignatureManagement extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onError;
  final bool shouldSubmit;
  final List<dynamic>? existingDocuments;

  const SignatureManagement({
    super.key,
    this.onNext,
    this.onBack,
    this.onError,
    this.shouldSubmit = false,
    this.existingDocuments,
  });

  @override
  State<SignatureManagement> createState() => _SignatureManagementState();
}

class _SignatureManagementState extends State<SignatureManagement> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _hasSignature = false;
  bool _isSubmitting = false;
  Uint8List? _capturedSignatureBytes;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _checkExistingDocuments();

    // Listen for shouldSubmit changes from parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _handleMainSubmit();
      }
    });
  }

  @override
  void didUpdateWidget(SignatureManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMainSubmit();
      });
    }
  }

  void _checkExistingDocuments() {
    if (widget.existingDocuments != null &&
        widget.existingDocuments!.isNotEmpty) {
      // Logic to handle existing signature if needed
    }
  }

  void _handleMainSubmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSignature && _capturedSignatureBytes == null) {
        setState(() => _uploadError = "Please provide your signature.");
        widget.onError?.call();
        return;
      }
      _captureAndUploadSignature();
    });
  }

  Future<void> _captureAndUploadSignature() async {
    try {
      AppLogger.info('Starting signature submission', tag: 'SignatureManagement');
      
      setState(() {
        _isSubmitting = true;
        _uploadError = null;
      });

      Uint8List? bytesToUpload = _capturedSignatureBytes;

      // If user drew something and we haven't captured bytes yet (or to get latest draw), capture it
      if (_hasSignature && _capturedSignatureBytes == null) {
        final ui.Image image = await _signaturePadKey.currentState!.toImage();
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData != null) {
          bytesToUpload = byteData.buffer.asUint8List();
          setState(() {
            _capturedSignatureBytes = bytesToUpload;
          });
        }
      }

      if (bytesToUpload == null) {
        setState(() {
          _isSubmitting = false;
          _uploadError = "Failed to process signature.";
        });
        widget.onError?.call();
        return;
      }

      // Convert PNG bytes to base64 data URL (Profile API requirement)
      final base64Signature = base64Encode(bytesToUpload);
      final signatureDataUrl = 'data:image/png;base64,$base64Signature';
      
      AppLogger.info(
        'Signature captured, size: ${bytesToUpload.length} bytes',
        tag: 'SignatureManagement',
      );

      // Save primary signature to profile
      AppLogger.info('Saving primary signature to profile', tag: 'SignatureManagement');
      
      final extendedProfile = ProfileService().buildExtendedProfile(
        primarySignature: signatureDataUrl,
      );

      final profileResponse = await ProfileService().updateProfileDetails(
        extendedProfile: extendedProfile,
        submitProfile: false, // Don't submit yet, just save signature
      );

      if (profileResponse == null || !profileResponse.success) {
        throw Exception(
          profileResponse?.message ?? 'Failed to save primary signature',
        );
      }
      
      AppLogger.info(
        'Primary signature saved successfully',
        tag: 'SignatureManagement',
      );

      // Check if there's a secondary holder
      final hasSecondaryHolder = await _checkForSecondaryHolder();
      
      AppLogger.info(
        'Has secondary holder: $hasSecondaryHolder',
        tag: 'SignatureManagement',
      );

      setState(() => _isSubmitting = false);

      AppLogger.info(
        hasSecondaryHolder 
          ? 'Primary signature saved! Moving to secondary signature.'
          : 'Signature saved successfully!',
        tag: 'SignatureManagement',
      );

      // Navigate to next screen (either secondary signature or continue with flow)
      if (widget.onNext != null) {
        widget.onNext!();
      }
    } catch (e) {
      AppLogger.error(
        'Error in signature submission',
        error: e,
        tag: 'SignatureManagement',
      );
      
      setState(() {
        _isSubmitting = false;
        _uploadError = "Failed to save signature: ${e.toString()}";
      });
      
      widget.onError?.call();
    }
  }

  Future<bool> _checkForSecondaryHolder() async {
    try {
      final profileResponse = await ProfileService().getProfileDetails();
      if (profileResponse != null && profileResponse.success) {
        final ucc = profileResponse.data?.uccProfile;
        if (ucc != null) {
          final hasSecondary = ucc['secondary_first_name'] != null && 
                              ucc['secondary_first_name'].toString().isNotEmpty;
          return hasSecondary;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking for secondary holder: $e', tag: 'SignatureManagement');
      return false;
    }
  }

  Future<void> _handleUploadLink() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _capturedSignatureBytes = file.bytes;
          _hasSignature = false;
          _uploadError = null;
        });
      }
    }
  }

  void _handleClear() {
    setState(() {
      _capturedSignatureBytes = null;
      _hasSignature = false;
      _signaturePadKey.currentState?.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Indicator and Step Text
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     AppText(
        //       _showConfirmation ? 'CONFIRMATION' : 'PROVIDE YOUR SIGNATURE',
        //       variant: AppTextVariant.bodySmall,
        //       weight: AppTextWeight.bold,
        //       customColor: Colors.white,
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 8),
        // LinearProgressIndicator(
        //   value: 1.0,
        //   backgroundColor: Colors.white.withOpacity(0.1),
        //   valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        //   minHeight: 2,
        // ),
        // const SizedBox(height: 8),
        // AppText(
        //   'Question 7 of 7',
        //   variant: AppTextVariant.bodySmall,
        //   customColor: Colors.grey,
        // ),
        // const SizedBox(height: 24),

        // Title and Subtitle
        AppText(
          'Provide Your Signature',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            AppText(
              'Turn your phone and sign or ',
              variant: AppTextVariant.bodyMedium,
              customColor: Colors.grey,
            ),
            GestureDetector(
              onTap: _handleUploadLink,
              child: AppText(
                'upload here',
                variant: AppTextVariant.bodyMedium,
                customColor: Colors.blue,
                weight: AppTextWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Signature Area
        Container(
          width: double.infinity,
          height: 400.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              _capturedSignatureBytes != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _capturedSignatureBytes!,
                      fit: BoxFit.contain,
                    ),
                  )
                  : SfSignaturePad(
                    key: _signaturePadKey,
                    backgroundColor: Colors.white,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 3,
                    maximumStrokeWidth: 6,
                    onDrawStart: () {
                      if (!_hasSignature) setState(() => _hasSignature = true);
                      return false;
                    },
                  ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _handleClear,
            child: AppText(
              'CLEAR',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.bold,
              customColor: Colors.blue,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Error Message
        if (_uploadError != null) ...[
          const SizedBox(height: 16),
          Center(
            child: AppText(
              _uploadError!,
              variant: AppTextVariant.bodySmall,
              customColor: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }
}
