import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/signature_screen.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';

/// Edit Holder Screen - Edit existing holder details
class EditHolderScreen extends StatefulWidget {
  final Map<String, dynamic> holderData;

  const EditHolderScreen({
    super.key,
    required this.holderData,
  });

  @override
  State<EditHolderScreen> createState() => _EditHolderScreenState();
}

class _EditHolderScreenState extends State<EditHolderScreen> {
  final OnboardingV2Service _service = OnboardingV2Service();
  
  // Editable fields
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tinController = TextEditingController();
  
  String? _selectedResidency;
  final List<String> _residencyOptions = ['Resident', 'NRI-NRE', 'NRI-NRO'];

  String? _selectedRelationship;
  final List<String> _relationshipOptions = [
    'SPOUSE',
    'FATHER',
    'MOTHER',
    'SON',
    'DAUGHTER',
    'SIBLING',
    'OTHER',
  ];

  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
  ];

  bool get _isNRI => _selectedResidency == 'NRI-NRE' || _selectedResidency == 'NRI-NRO';

  bool _isLoading = false;

  // Field validation errors
  String? _emailError;
  String? _phoneError;
  String? _relationshipError;
  String? _residencyError;
  String? _tinError;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    _emailController.text = widget.holderData['email'] ?? '';
    _tinController.text = widget.holderData['tin'] ?? '';
    _selectedResidency = widget.holderData['investor_residency'] ?? 'Resident';
    // Map numerical relationship code to label (HEAD bug fix)
    final rawRelationship = widget.holderData['relationship_to_primary']?.toString();
    if (rawRelationship != null) {
      String normalized = rawRelationship;
      if (RegExp(r'^\d$').hasMatch(rawRelationship)) {
        normalized = '0$rawRelationship';
      }
      if (_relationshipCodeToLabel.containsKey(normalized)) {
        _selectedRelationship = _relationshipCodeToLabel[normalized];
      } else if (_relationshipOptions.contains(rawRelationship.toUpperCase())) {
        _selectedRelationship = rawRelationship.toUpperCase();
      } else {
        _selectedRelationship = rawRelationship;
      }
    }

    // Phone + country code parsing (83dc890 — NRI support)
    String rawPhone = (widget.holderData['phone_number'] ?? '') as String;
    if (rawPhone.isNotEmpty && !rawPhone.startsWith('+') && rawPhone.length > 10) {
      rawPhone = '+$rawPhone';
    }
    String parsedCode = '+91';
    String parsedFlag = '🇮🇳';
    String parsedNumber = rawPhone;
    for (final c in _countries) {
      if (rawPhone.startsWith(c['code']!)) {
        parsedCode = c['code']!;
        parsedFlag = c['flag']!;
        parsedNumber = rawPhone.substring(c['code']!.length);
        break;
      }
    }
    _phoneController.text = parsedNumber;
    _selectedCountryCode = parsedCode;
    _selectedCountryFlag = parsedFlag;
  }

  static const Map<String, String> _relationshipCodeToLabel = {
    '01': 'SPOUSE',
    '02': 'FATHER',
    '03': 'MOTHER',
    '04': 'SON',
    '05': 'DAUGHTER',
    '06': 'SIBLING',
    '11': 'OTHER',
  };

  static const Map<String, String> _relationshipLabelToCode = {
    'SPOUSE': '01',
    'FATHER': '02',
    'MOTHER': '03',
    'SON': '04',
    'DAUGHTER': '05',
    'SIBLING': '06',
    'OTHER': '11',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      // Validate relationship
      if (_selectedRelationship == null) {
        _relationshipError = 'Please select relationship to primary investor';
        isValid = false;
      } else {
        _relationshipError = null;
      }

      // Validate residency
      if (_selectedResidency == null) {
        _residencyError = 'Please select residency status';
        isValid = false;
      } else {
        _residencyError = null;
      }

      // Validate email
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter email address';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
        isValid = false;
      } else {
        _emailError = null;
      }

      // Validate phone
      final phoneDigits = _phoneController.text.trim();
      final minDigits = _selectedCountryCode == '+91' ? 10 : 7;
      if (phoneDigits.isEmpty) {
        _phoneError = 'Please enter phone number';
        isValid = false;
      } else if (phoneDigits.length < minDigits) {
        _phoneError = _selectedCountryCode == '+91'
            ? 'Please enter valid 10-digit phone number'
            : 'Please enter a valid phone number';
        isValid = false;
      } else {
        _phoneError = null;
      }

      // Validate TIN for NRI
      if (_isNRI && _tinController.text.trim().isEmpty) {
        _tinError = 'TIN is required for NRI-NRE/NRI-NRO';
        isValid = false;
      } else {
        _tinError = null;
      }
    });
    return isValid;
  }

  Future<void> _saveChanges() async {
    // Validate all fields
    if (!_validateFields()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final phoneDigits = _phoneController.text.trim();
      final fullPhone = '$_selectedCountryCode$phoneDigits';
      final payload = {
        'email': _emailController.text.trim(),
        'phone_number': fullPhone,
        'investor_residency': _selectedResidency,
        'relationship_to_primary': _relationshipLabelToCode[_selectedRelationship] ?? _selectedRelationship,
        'tin': _isNRI ? _tinController.text.trim() : null,
      };

      AppLogger.info(
        'Updating holder ${widget.holderData['id']} with payload: $payload',
        tag: 'EditHolder',
      );

      final response = await _service.updateHolder(
        holderId: widget.holderData['id'],
        email: payload['email'],
        phoneNumber: payload['phone_number'],
        investorResidency: payload['investor_residency'],
        relationshipToPrimary: payload['relationship_to_primary'],
        tin: payload['tin'],
      );

      if (response != null && response['success'] == true) {
        AppLogger.info('✅ Holder updated successfully', tag: 'EditHolder');

        final updatedHolder = {
          ...widget.holderData,
          ...payload,
        };

        setState(() => _isLoading = false);

        // Check if holder already has a signature
        final existingSignature = widget.holderData['signature'] as String?;
        final hasSignature = existingSignature != null && existingSignature.isNotEmpty;

        if (hasSignature) {
          // Holder already has signature, skip signature screen
          AppLogger.info(
            'Holder ${widget.holderData['id']} already has signature, skipping signature collection',
            tag: 'EditHolder',
          );
          Get.back(result: updatedHolder);
        } else {
          // Navigate to signature collection
          await Get.to(
            () => SignatureScreen(
              onNext: (signature) async {
                await _updateHolderSignature(updatedHolder, signature);
              },
              onBack: () => Get.back(),
            ),
            transition: Transition.rightToLeft,
          );
        }
      } else {
        throw Exception(response?['message'] ?? 'Failed to update holder');
      }
    } catch (e) {
      AppLogger.error('❌ Error updating holder: $e', tag: 'EditHolder');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateHolderSignature(
    Map<String, dynamic> holderData,
    String signature,
  ) async {
    try {
      AppLogger.info(
        'Updating holder signature for ID: ${holderData['id']}',
        tag: 'EditHolder',
      );

      final response = await _service.updateHolderSignature(
        holderId: holderData['id'],
        signature: signature,
      );

      if (response != null && response['success'] == true) {
        AppLogger.info('✅ Holder signature updated successfully', tag: 'EditHolder');

        final holderWithSignature = {
          ...holderData,
          'signature': signature,
          'has_signature': true,
        };

        Get.back(); // Close signature screen
        Get.back(result: holderWithSignature); // Return to holder list
      } else {
        throw Exception(response?['message'] ?? 'Failed to update signature');
      }
    } catch (e) {
      AppLogger.error('❌ Error updating holder signature: $e', tag: 'EditHolder');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving signature: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancel() {
    Get.back();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Select Country',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (_, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                      title: AppText(country['name']!, variant: AppTextVariant.bodyMedium),
                      trailing: AppText(
                        country['code']!,
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
                          _selectedCountryFlag = country['flag']!;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneWithCountryCode() {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.darkInputBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showCountryPicker,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_selectedCountryFlag, style: const TextStyle(fontSize: 20)),
                  SizedBox(width: 6.w),
                  Text(
                    _selectedCountryCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24.h,
            color: AppColors.darkInputBorder,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    if (_selectedCountryCode == '+91') LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedCountryCode == '+91' ? '10-digit number' : 'Phone number',
                    hintStyle: TextStyle(color: AppColors.darkInputHintText, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Edit Holder',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancel,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PAN (Read-only)
                  AppText(
                    'PAN Number',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppInputField(
                    controller: TextEditingController(text: widget.holderData['pan_number']),
                    hintText: 'PAN Number',
                    readOnly: true,
                    fillColor: AppColors.darkInputBackground.withOpacity(0.5),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Name (Read-only)
                  AppText(
                    'Name',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppInputField(
                    controller: TextEditingController(text: widget.holderData['name']),
                    hintText: 'Name',
                    readOnly: true,
                    fillColor: AppColors.darkInputBackground.withOpacity(0.5),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // DOB (Read-only)
                  AppText(
                    'Date of Birth',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppInputField(
                    controller: TextEditingController(text: widget.holderData['dob']),
                    hintText: 'Date of Birth',
                    readOnly: true,
                    fillColor: AppColors.darkInputBackground.withOpacity(0.5),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Email (Editable)
                  AppText(
                    'Email',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  if (_emailError != null) ...[
                    SizedBox(height: 4.h),
                    AppText(
                      _emailError!,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.error,
                    ),
                  ],
                  
                  SizedBox(height: 16.h),
                  
                  // Phone (Editable)
                  AppText(
                    'Phone Number',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  _buildPhoneWithCountryCode(),
                  if (_phoneError != null) ...[
                    SizedBox(height: 4.h),
                    AppText(
                      _phoneError!,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.error,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  
                  // Residency (Editable)
                  AppText(
                    'Residency',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppDropdown(
                    hintText: 'Select residency',
                    value: _selectedResidency,
                    items: _residencyOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedResidency = value;
                        _residencyError = null;
                      });
                    },
                  ),
                  if (_residencyError != null) ...[
                    SizedBox(height: 4.h),
                    AppText(
                      _residencyError!,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.error,
                    ),
                  ],
                  
                  SizedBox(height: 16.h),
                  
                  // Relationship to Primary (Editable)
                  AppText(
                    'Relationship to Primary Investor',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  AppDropdown(
                    hintText: 'Select relationship',
                    value: _selectedRelationship,
                    items: _relationshipOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedRelationship = value;
                        _relationshipError = null;
                      });
                    },
                  ),
                  if (_relationshipError != null) ...[
                    SizedBox(height: 4.h),
                    AppText(
                      _relationshipError!,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.error,
                    ),
                  ],
                  
                  SizedBox(height: 16.h),
                  
                  // TIN (Editable - only for NRI)
                  if (_isNRI) ...[
                    AppText(
                      'TIN (Tax Identification Number)',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                      weight: AppTextWeight.semiBold,
                    ),
                    SizedBox(height: 8.h),
                    AppInputField(
                      controller: _tinController,
                      hintText: 'TIN',
                      onChanged: (_) {
                        if (_tinError != null) setState(() => _tinError = null);
                      },
                    ),
                    if (_tinError != null) ...[  
                      SizedBox(height: 4.h),
                      AppText(
                        _tinError!,
                        variant: AppTextVariant.caption,
                        colorType: AppTextColorType.error,
                      ),
                    ],
                    SizedBox(height: 16.h),
                  ],
                  
                  SizedBox(height: 32.h),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'CANCEL',
                          onPressed: _cancel,
                          variant: AppButtonVariant.outlined,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: AppButton(
                          text: 'SAVE CHANGES',
                          onPressed: _saveChanges,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
