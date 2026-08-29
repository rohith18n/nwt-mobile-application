import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/services/auth/ucc_service.dart';
import 'package:nwt_app/services/secure_storage.dart';

class SecondarySignatureManagement extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onError;
  final bool shouldSubmit;

  const SecondarySignatureManagement({
    super.key,
    this.onNext,
    this.onBack,
    this.onError,
    this.shouldSubmit = false,
  });

  @override
  State<SecondarySignatureManagement> createState() => _SecondarySignatureManagementState();
}

class _SecondarySignatureManagementState extends State<SecondarySignatureManagement> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _hasSignature = false;
  bool _isSubmitting = false;
  Uint8List? _capturedSignatureBytes;
  String? _uploadError;

  @override
  void initState() {
    super.initState();

    // Listen for shouldSubmit changes from parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _handleMainSubmit();
      }
    });
  }

  @override
  void didUpdateWidget(SecondarySignatureManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMainSubmit();
      });
    }
  }

  void _handleMainSubmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSignature && _capturedSignatureBytes == null) {
        setState(() => _uploadError = "Please provide secondary holder signature.");
        widget.onError?.call();
        return;
      }
      _captureAndUploadSignature();
    });
  }

  Future<void> _captureAndUploadSignature() async {
    try {
      AppLogger.info('Starting secondary signature submission', tag: 'SecondarySignature');
      
      setState(() {
        _isSubmitting = true;
        _uploadError = null;
      });

      Uint8List? bytesToUpload = _capturedSignatureBytes;

      // If user drew something and we haven't captured bytes yet, capture it
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
          _uploadError = "Failed to process secondary signature.";
        });
        widget.onError?.call();
        return;
      }

      // Convert PNG bytes to base64 data URL
      final base64Signature = base64Encode(bytesToUpload);
      final signatureDataUrl = 'data:image/png;base64,$base64Signature';
      
      AppLogger.info(
        'Secondary signature captured, size: ${bytesToUpload.length} bytes',
        tag: 'SecondarySignature',
      );

      // Step 1: Save secondary signature to profile (without submitting)
      AppLogger.info('Step 1: Saving secondary signature to profile', tag: 'SecondarySignature');
      
      final saveSignatureProfile = ProfileService().buildExtendedProfile(
        secondarySignature: signatureDataUrl,
      );

      final saveResponse = await ProfileService().updateProfileDetails(
        extendedProfile: saveSignatureProfile,
        submitProfile: false, // Just save, don't submit yet
      );

      if (saveResponse == null || !saveResponse.success) {
        throw Exception(
          saveResponse?.message ?? 'Failed to save secondary signature',
        );
      }
      
      AppLogger.info('Secondary signature saved to profile', tag: 'SecondarySignature');

      // Step 2: Fetch profile to verify both signatures are present
      AppLogger.info('Step 2: Verifying both signatures in profile', tag: 'SecondarySignature');
      
      final currentProfile = await ProfileService().getProfileDetails();
      if (currentProfile == null || !currentProfile.success) {
        throw Exception('Failed to fetch current profile');
      }
      
      final uccProfile = currentProfile.data?.uccProfile;
      if (uccProfile == null) {
        throw Exception('UCC profile data not found');
      }
      
      // Verify both signatures
      final primarySignature = uccProfile['primary_signature'];
      final secondarySignature = uccProfile['secondary_signature'];
      
      AppLogger.info(
        'Primary signature present: ${primarySignature != null && primarySignature.toString().isNotEmpty}',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Primary signature length: ${primarySignature?.toString().length ?? 0}',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Secondary signature present: ${secondarySignature != null && secondarySignature.toString().isNotEmpty}',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Secondary signature length: ${secondarySignature?.toString().length ?? 0}',
        tag: 'bse_journey_final',
      );
      
      if (primarySignature == null || primarySignature.toString().isEmpty) {
        throw Exception('Primary signature not found in profile');
      }
      
      if (secondarySignature == null || secondarySignature.toString().isEmpty) {
        throw Exception('Secondary signature not saved properly');
      }
      
      AppLogger.info('Both signatures verified in profile', tag: 'SecondarySignature');

      // Step 3: Submit profile to BSE with both signatures (only if not already at ucc)
      final currentStatus = currentProfile.data?.onboardingStatus;
      AppLogger.info('Step 3: Checking if profile submission needed', tag: 'SecondarySignature');
      AppLogger.info(
        'Current onboarding status: $currentStatus',
        tag: 'bse_journey_final',
      );
      
      if (currentStatus != 'ucc') {
        // Status is not ucc yet, so we can submit
        AppLogger.info('Submitting profile to BSE with both signatures', tag: 'SecondarySignature');
        
        final submitProfile = ProfileService().buildExtendedProfile(
          primarySignature: primarySignature.toString(),
          secondarySignature: secondarySignature.toString(),
        );

        AppLogger.info(
          '📤 PROFILE SUBMISSION PAYLOAD:',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Extended Profile Fields:\n${const JsonEncoder.withIndent('  ').convert(submitProfile)}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Submit to BSE: true',
          tag: 'bse_journey_final',
        );

        final profileResponse = await ProfileService().updateProfileDetails(
          extendedProfile: submitProfile,
          submitProfile: true, // Submit profile to BSE (required before UCC creation)
        );

        if (profileResponse == null || !profileResponse.success) {
          throw Exception(
            profileResponse?.message ?? 'Failed to submit profile',
          );
        }
        
        AppLogger.info(
          '✅ PROFILE SUBMISSION RESPONSE:',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Success: ${profileResponse.success}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Message: ${profileResponse.message}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Profile submitted to BSE successfully. Status: profile → ucc',
          tag: 'SecondarySignature',
        );
      } else {
        // Status is already ucc - profile was submitted in a previous step
        // This is a known limitation: backend won't re-submit to BSE once status is ucc
        AppLogger.info(
          '⚠️ Status is already ucc - profile was previously submitted to BSE',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '⚠️ Backend will not re-submit to BSE. Secondary signature may not be at BSE.',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '⚠️ RECOMMENDATION: Reset account status to profile and try again, OR contact backend team to add force re-submit option.',
          tag: 'bse_journey_final',
        );
        
        // For now, we'll continue and try to create UCC anyway
        // The UCC creation will likely fail due to missing secondary signature at BSE
      }

      // Step 4: Extract secondary holder data from profile
      AppLogger.info('Step 4: Extracting secondary holder data', tag: 'SecondarySignature');
      
      // Extract secondary holder data (using uccProfile from Step 2)
      // Build payload according to API documentation
      final secondaryHolder = {
        'first_name': uccProfile['secondary_first_name'],
        'last_name': uccProfile['secondary_last_name'],
        'pan': uccProfile['secondary_pan'],
        'dob': uccProfile['secondary_dob'],
        'email': uccProfile['secondary_email'],
        'mobile': uccProfile['secondary_mobile'],
        'tax_status': uccProfile['secondary_tax_status'] ?? 'Resident',
        'signature': secondarySignature.toString(), // Secondary signature (CRITICAL!)
      };
      
      // Add optional fields if present
      if (uccProfile['secondary_middle_name'] != null && 
          uccProfile['secondary_middle_name'].toString().isNotEmpty) {
        secondaryHolder['middle_name'] = uccProfile['secondary_middle_name'];
      }
      
      if (uccProfile['secondary_gender'] != null) {
        secondaryHolder['gender'] = uccProfile['secondary_gender'];
      }
      
      // For NRI accounts, add country and tax_id
      final taxStatus = uccProfile['secondary_tax_status']?.toString() ?? '';
      if (taxStatus.contains('NRI')) {
        if (uccProfile['secondary_country'] != null) {
          secondaryHolder['country'] = uccProfile['secondary_country'];
        }
        if (uccProfile['secondary_tax_id'] != null) {
          secondaryHolder['tax_id'] = uccProfile['secondary_tax_id'];
        }
      }
      
      AppLogger.info(
        'Secondary holder data prepared for UCC creation',
        tag: 'SecondarySignature',
      );

      // Step 3: Create UCC Account
      AppLogger.info('Step 3: Creating UCC account', tag: 'SecondarySignature');
      
      // Read nominee data from SecureStorage
      final hasNomineesStr = await SecureStorage.read('has_nominees');
      final hasNominees = hasNomineesStr == 'true';
      
      AppLogger.info(
        'Has nominees: $hasNominees',
        tag: 'SecondarySignature',
      );

      final uccService = UCCService();
      
      if (hasNominees) {
        // With nominees flow
        final nomineeDataStr = await SecureStorage.read('nominee_data');
        if (nomineeDataStr == null || nomineeDataStr.isEmpty) {
          throw Exception('Nominee data not found in storage');
        }
        
        final nomineeData = jsonDecode(nomineeDataStr) as Map<String, dynamic>;
        final nominees = nomineeData['nominees'] as List;
        
        AppLogger.info(
          'Creating UCC with ${nominees.length} nominees',
          tag: 'SecondarySignature',
        );
        
        final nomination = {
          'choice': 'provide',
          'nominees': nominees,
        };
        
        // Log final payload
        final finalPayload = {
          'accounts': 'as',
          'nomination': nomination,
          'secondary_holder': secondaryHolder,
        };
        
        AppLogger.info(
          '🚀 FINAL UCC CREATION PAYLOAD (WITH NOMINEES):',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Account Type: as',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Nomination: ${jsonEncode(nomination)}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Secondary Holder: ${jsonEncode(secondaryHolder)}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'FULL PAYLOAD JSON:\n${const JsonEncoder.withIndent('  ').convert(finalPayload)}',
          tag: 'bse_journey_final',
        );
        
        AppLogger.info(
          '🔄 CALLING: UCCService.createAccount()',
          tag: 'bse_journey_final',
        );
        
        final uccResponse = await uccService.createAccount(
          accounts: 'as', // Joint account (AS)
          nomination: nomination,
          secondaryHolder: secondaryHolder,
        );

        AppLogger.info(
          '✅ UCC CREATION RESPONSE (WITH NOMINEES):',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Success: ${uccResponse?.success}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Message: ${uccResponse?.message}',
          tag: 'bse_journey_final',
        );
        if (uccResponse?.data != null) {
          AppLogger.info(
            'Accounts created: ${uccResponse!.data!.accounts.length}',
            tag: 'bse_journey_final',
          );
          for (var acc in uccResponse.data!.accounts) {
            AppLogger.info(
              '  - Client Code: ${acc.clientCode}, Holding Nature: ${acc.holdingNature}',
              tag: 'bse_journey_final',
            );
          }
        }

        if (uccResponse == null || !uccResponse.success) {
          throw Exception(
            uccResponse?.message ?? 'Failed to create UCC account',
          );
        }
        
        // Store client codes for OTP verification
        if (uccResponse.data != null && uccResponse.data!.accounts.isNotEmpty) {
          final clientCodes = uccResponse.data!.accounts
              .map((acc) => acc.clientCode)
              .toList();
          await SecureStorage.write('ucc_client_codes', jsonEncode(clientCodes));
          
          AppLogger.info(
            'UCC created with client codes: $clientCodes',
            tag: 'SecondarySignature',
          );
        }
      } else {
        // Without nominees (opt-out) flow
        AppLogger.info(
          'Creating UCC without nominees',
          tag: 'SecondarySignature',
        );
        
        // Log final payload
        final finalPayload = {
          'accounts': 'as',
          'secondary_holder': secondaryHolder,
        };
        
        AppLogger.info(
          '🚀 FINAL UCC CREATION PAYLOAD (WITHOUT NOMINEES):',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Account Type: as',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Secondary Holder Data:',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - First Name: ${secondaryHolder['first_name']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Last Name: ${secondaryHolder['last_name']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - PAN: ${secondaryHolder['pan']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - DOB: ${secondaryHolder['dob']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Email: ${secondaryHolder['email']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Mobile: ${secondaryHolder['mobile']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Address: ${secondaryHolder['address']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - City: ${secondaryHolder['city']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - State: ${secondaryHolder['state']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Pincode: ${secondaryHolder['pincode']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          '  - Country: ${secondaryHolder['country']}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'FULL PAYLOAD JSON:\n${const JsonEncoder.withIndent('  ').convert(finalPayload)}',
          tag: 'bse_journey_final',
        );
        
        AppLogger.info(
          '🔄 CALLING: UCCService.createAccountWithoutNominee()',
          tag: 'bse_journey_final',
        );
        
        final uccResponse = await uccService.createAccountWithoutNominee(
          accounts: 'as', // Joint account (AS)
          secondaryHolder: secondaryHolder,
        );

        AppLogger.info(
          '✅ UCC CREATION RESPONSE (WITHOUT NOMINEES):',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Success: ${uccResponse?.success}',
          tag: 'bse_journey_final',
        );
        AppLogger.info(
          'Message: ${uccResponse?.message}',
          tag: 'bse_journey_final',
        );
        if (uccResponse?.data != null) {
          AppLogger.info(
            'Accounts created: ${uccResponse!.data!.accounts.length}',
            tag: 'bse_journey_final',
          );
          for (var acc in uccResponse.data!.accounts) {
            AppLogger.info(
              '  - Client Code: ${acc.clientCode}, Holding Nature: ${acc.holdingNature}',
              tag: 'bse_journey_final',
            );
          }
        }

        if (uccResponse == null || !uccResponse.success) {
          throw Exception(
            uccResponse?.message ?? 'Failed to create UCC account',
          );
        }
        
        // Store client codes for OTP verification
        if (uccResponse.data != null && uccResponse.data!.accounts.isNotEmpty) {
          final clientCodes = uccResponse.data!.accounts
              .map((acc) => acc.clientCode)
              .toList();
          await SecureStorage.write('ucc_client_codes', jsonEncode(clientCodes));
          
          AppLogger.info(
            'UCC created (no nominee) with client codes: $clientCodes',
            tag: 'SecondarySignature',
          );
        }
      }

      setState(() => _isSubmitting = false);

      AppLogger.info(
        'UCC account created successfully. Check your email for verification code!',
        tag: 'SecondarySignature',
      );

      // Navigate to OTP verification screen
      if (widget.onNext != null) {
        widget.onNext!();
      }
    } catch (e) {
      AppLogger.error(
        'Error in secondary signature submission',
        error: e,
        tag: 'SecondarySignature',
      );
      
      setState(() {
        _isSubmitting = false;
        _uploadError = "Failed to complete registration: ${e.toString()}";
      });
      
      widget.onError?.call();
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
        // Title and Subtitle
        AppText(
          'Secondary Holder Signature',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),

        const SizedBox(height: 8),
        AppText(
          'The secondary holder must provide their signature',
          variant: AppTextVariant.bodyMedium,
          customColor: Colors.grey,
        ),
        const SizedBox(height: 16),
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
