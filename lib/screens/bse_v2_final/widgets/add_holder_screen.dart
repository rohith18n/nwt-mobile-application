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
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/signature_screen.dart';
import 'package:nwt_app/controllers/user_controller.dart';

/// PAN formatter: enforces AAAAA9999A pattern and auto-uppercases.
class _PanInputFormatter extends TextInputFormatter {
  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    final filtered = StringBuffer();

    for (int i = 0; i < upper.length && i < 10; i++) {
      final ch = upper[i];
      if (i < 5) {
        // Positions 0-4: letters only
        if (RegExp(r'[A-Z]').hasMatch(ch)) filtered.write(ch);
      } else if (i < 9) {
        // Positions 5-8: digits only
        if (RegExp(r'[0-9]').hasMatch(ch)) filtered.write(ch);
      } else {
        // Position 9: letter only
        if (RegExp(r'[A-Z]').hasMatch(ch)) filtered.write(ch);
      }
    }

    final result = filtered.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  static bool isValid(String pan) => _panRegex.hasMatch(pan.toUpperCase());
}

/// Add Holder Screen - Matches web flow
/// Enter PAN → Fetch Details → Show Details → Save
class AddHolderScreen extends StatefulWidget {
  const AddHolderScreen({super.key});

  @override
  State<AddHolderScreen> createState() => _AddHolderScreenState();
}

class _AddHolderScreenState extends State<AddHolderScreen> {
  final OnboardingV2Service _service = OnboardingV2Service();
  final _panController = TextEditingController();
  
  // Editable fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
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

  // Relationship code ↔ label mapping (HEAD bug fix)
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

  // Country code selection (83dc890 — NRI support)
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
  bool _isFetchingHolder = false; // Separate flag for fetch button
  bool _isSavingHolder = false; // Separate flag for save button
  bool _isFetched = false;
  Map<String, dynamic>? _holderData;

  // Field validation errors
  String? _emailError;
  String? _phoneError;
  String? _relationshipError;
  String? _residencyError;
  String? _tinError;

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  Future<void> _fetchHolderDetails() async {
    final pan = _panController.text.trim();
    if (!_PanInputFormatter.isValid(pan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PAN. Format: ABCDE1234F (5 letters, 4 digits, 1 letter)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prevent adding own PAN
    final userController = Get.find<UserController>();
    final userPan = userController.userData?.pannumber;
    if (userPan != null && pan.toUpperCase() == userPan.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot add yourself as a joint holder.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isFetchingHolder = true);
    
    try {
      final panNumber = _panController.text.trim().toUpperCase();
      
      AppLogger.info('🔍 Fetching holder details for PAN: $panNumber', tag: 'AddHolder');
      
      final response = await _service.addHolder(panNumber: panNumber);
      
      AppLogger.info('✅ Holder API Response: $response', tag: 'AddHolder');
      
      if (response != null && response['success'] == true) {
        // Log the full data structure
        AppLogger.info('📦 Full data object: ${response['data']}', tag: 'AddHolder');
        AppLogger.info('📦 data.holder: ${response['data']['holder']}', tag: 'AddHolder');
        
        final holderData = response['data']['holder'] ?? response['data'];
        
        AppLogger.info('📋 Final Holder Data: $holderData', tag: 'AddHolder');
        AppLogger.info('📋 Name: ${holderData['name']}', tag: 'AddHolder');
        AppLogger.info('📋 DOB: ${holderData['dob']}', tag: 'AddHolder');
        
        String rawPhone = (holderData['phone_number'] ?? '') as String;
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

        setState(() {
          _isFetched = true;
          _holderData = holderData;

          // Populate fields
          _nameController.text = holderData['name'] ?? '';
          _dobController.text = holderData['dob'] ?? '';
          _emailController.text = holderData['email'] ?? '';
          _phoneController.text = parsedNumber;
          _tinController.text = holderData['tin'] ?? '';
          _selectedResidency = holderData['investor_residency'] ?? 'Resident';
          // Map numerical code to label if necessary (HEAD bug fix)
          final rawRelationship = holderData['relationship_to_primary']?.toString();
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
          // Country code from 83dc890 (NRI support)
          _selectedCountryCode = parsedCode;
          _selectedCountryFlag = parsedFlag;
        });
        
        final holderName = holderData['name'] ?? holderData['pan_number'] ?? 'Unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Holder $holderName fetched successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response?['message'] ?? 'Failed to fetch holder details');
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching holder: $e', tag: 'AddHolder');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isFetchingHolder = false);
    }
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

  Future<void> _saveHolder() async {
    if (_holderData != null) {
      // Validate all fields
      if (!_validateFields()) {
        return;
      }

      try {
        setState(() => _isSavingHolder = true);

        // First, update holder details via API
        AppLogger.info(
          'Updating holder ${_holderData!['id']} with email, phone, residency, relationship',
          tag: 'AddHolder',
        );

        final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
        final updateResponse = await _service.updateHolder(
          holderId: _holderData!['id'],
          email: _emailController.text.trim(),
          phoneNumber: fullPhone,
          investorResidency: _selectedResidency,
          relationshipToPrimary: _relationshipLabelToCode[_selectedRelationship] ?? _selectedRelationship,
          tin: _isNRI ? _tinController.text.trim() : null,
        );

        if (updateResponse == null || updateResponse['success'] != true) {
          throw Exception(updateResponse?['message'] ?? 'Failed to update holder details');
        }

        AppLogger.info('✅ Holder details updated successfully', tag: 'AddHolder');

        // Update local holder data
        final updatedHolder = {
          ..._holderData!,
          'email': _emailController.text.trim(),
          'phone_number': fullPhone,
          'investor_residency': _selectedResidency,
          'relationship_to_primary': _relationshipLabelToCode[_selectedRelationship] ?? _selectedRelationship,
          'tin': _isNRI ? _tinController.text.trim() : null,
        };

        setState(() => _isSavingHolder = false);

        // Now navigate to signature collection
        await Get.to(
          () => SignatureScreen(
            onNext: (signature) async {
              await _updateHolderSignature(updatedHolder, signature);
            },
            onBack: () {
              Get.back(); // Go back to this screen
            },
          ),
          transition: Transition.rightToLeft,
        );
      } catch (e) {
        setState(() => _isSavingHolder = false);
        AppLogger.error('❌ Error updating holder: $e', tag: 'AddHolder');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateHolderSignature(
    Map<String, dynamic> holderData,
    String signature,
  ) async {
    try {
      AppLogger.info(
        'Updating holder signature for ID: ${holderData['id']}',
        tag: 'AddHolder',
      );

      final response = await _service.updateHolderSignature(
        holderId: holderData['id'],
        signature: signature,
      );

      if (response != null && response['success'] == true) {
        AppLogger.info('✅ Holder signature updated successfully', tag: 'AddHolder');
        
        // Return holder data with signature to UCC Wizard
        final holderWithSignature = {
          ...holderData,
          'signature': signature,
          'has_signature': true,
        };
        
        Get.back(); // Close signature screen
        Get.back(result: holderWithSignature); // Return to UCC Wizard
      } else {
        throw Exception(response?['message'] ?? 'Failed to update signature');
      }
    } catch (e) {
      AppLogger.error('❌ Error updating holder signature: $e', tag: 'AddHolder');
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Add Holder',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancel,
        ),
      ),
      body: _isLoading && !_isFetchingHolder && !_isSavingHolder
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 32.h),
                  _buildPANSection(),
                  if (_isFetched && _holderData != null) ...[
                    SizedBox(height: 32.h),
                    _buildHolderDetails(),
                    SizedBox(height: 32.h),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: AppText(
            'JOINT ACCOUNT HOLDERS',
            variant: AppTextVariant.caption,
            customColor: AppColors.darkButtonPrimaryBackground,
            weight: AppTextWeight.semiBold,
          ),
        ),
        SizedBox(height: 16.h),
        AppText(
          'Add Holders',
          variant: AppTextVariant.headline4,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.primary,
        ),
        SizedBox(height: 8.h),
        AppText(
          'Add a joint holder by entering their PAN. We fetch their details from income tax records. You can then review and update the information on this page.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
        ),
      ],
    );
  }

  Widget _buildPANSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            _isFetched ? 'ADD A NEW HOLDER' : 'ADD A NEW HOLDER',
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 16.h),
          AppText(
            'HOLDER PAN',
            variant: AppTextVariant.caption,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 8.h),
          AppInputField(
            controller: _panController,
            hintText: 'ABCDE1234F',
            readOnly: _isFetched,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            inputFormatters: [_PanInputFormatter()],
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              if (!_PanInputFormatter.isValid(v)) return 'Format: ABCDE1234F';
              
              final userController = Get.find<UserController>();
              final userPan = userController.userData?.pannumber;
              if (userPan != null && v.toUpperCase() == userPan.toUpperCase()) {
                return 'You cannot add your own PAN';
              }
              return null;
            },
          ),
          if (!_isFetched) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'FETCH HOLDER DETAILS',
                isLoading: _isFetchingHolder,
                onPressed: _isFetchingHolder ? () {} : _fetchHolderDetails,
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildHolderDetails() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: AppText(
                  'Holder ${_holderData?['name']} (${_holderData?['pan_number']}) fetched successfully. Review and update the details below.',
                  variant: AppTextVariant.bodySmall,
                  customColor: Colors.green,
                  weight: AppTextWeight.medium,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Name (Read-only)
          AppText(
            'Name',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.semiBold,
          ),
          SizedBox(height: 8.h),
          AppInputField(
            controller: _nameController,
            hintText: 'Name',
            readOnly: true,
          ),
          
          SizedBox(height: 16.h),
          
          // DOB (Read-only)
          AppText(
            'DOB',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.semiBold,
          ),
          SizedBox(height: 8.h),
          AppInputField(
            controller: _dobController,
            hintText: 'Date of Birth',
            readOnly: true,
          ),
          
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
                _residencyError = null; // Clear error on change
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
          
          // Relationship to Primary (Required for nominees)
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
                _relationshipError = null; // Clear error on change
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
              hintText: 'Enter TIN',
              textCapitalization: TextCapitalization.characters,
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
            hintText: 'Enter email',
            type: AppInputFieldType.email,
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
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancel,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(color: AppColors.darkInputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: AppText(
              'Cancel',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: AppButton(
            text: 'Save Holder',
            isLoading: _isSavingHolder,
            onPressed: _isSavingHolder ? () {} : _saveHolder,
          ),
        ),
      ],
    );
  }
}
