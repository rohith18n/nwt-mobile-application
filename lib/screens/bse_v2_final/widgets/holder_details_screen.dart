import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/utils/logger.dart';

class HolderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> holderData;
  final Function(Map<String, dynamic> address) onNext;
  final VoidCallback? onBack;
  final String validateMode; // 'address' | 'ri_address' | 'nri_address'
  final Map<String, dynamic> validateContext;

  const HolderDetailsScreen({
    super.key,
    required this.holderData,
    required this.onNext,
    this.onBack,
    this.validateMode = 'address',
    this.validateContext = const {},
  });

  @override
  State<HolderDetailsScreen> createState() => _HolderDetailsScreenState();
}

class _HolderDetailsScreenState extends State<HolderDetailsScreen> {
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String? _selectedCountryCode;
  String _selectedCountryName = 'India';
  String? _selectedGender;

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2HolderDetailsScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2HolderDetailsScreenViewed, tag: 'event');
    });
    _populateAddressFields();
    _addressLine1Controller.addListener(_validateForm);
    _stateController.addListener(_validateForm);
    _cityController.addListener(_validateForm);
    _pincodeController.addListener(_validateForm);
  }

  void _populateAddressFields() {
    final holder = widget.holderData['holder'];

    // For ri_address: user must enter Indian address — reset form to India defaults
    // For nri_address: user must enter overseas address — leave country open
    // For address: normal PAN360 prefill
    if (widget.validateMode == 'ri_address') {
      // Must enter Indian address — default country to India
      _selectedCountryName = 'India';
      _selectedCountryCode = 'IND';
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
      return;
    }

    if (widget.validateMode == 'nri_address') {
      // Must enter overseas address — leave country blank so user picks it
      _selectedCountryName = '';
      _selectedCountryCode = null;
      _stateController.clear();
      _cityController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
      return;
    }

    // Check for pan_source_address first, then ucc_profile, then fall back to address
    final panSourceAddress = holder?['pan_source_address'];
    final uccProfile = holder?['ucc_profile'];
    final address = holder?['address'];

    // Populate Address Line 1
    if (panSourceAddress != null && panSourceAddress['full_address'] != null) {
      _addressLine1Controller.text = panSourceAddress['full_address'];
    } else if (uccProfile != null && uccProfile['address_line_1'] != null) {
      _addressLine1Controller.text = uccProfile['address_line_1'];
    } else if (panSourceAddress?['street'] != null) {
      _addressLine1Controller.text = panSourceAddress['street'];
    } else if (address?['line1'] != null) {
      _addressLine1Controller.text = address['line1'];
    }

    // Populate Country
    final countryName =
        panSourceAddress?['country'] ??
        uccProfile?['country'] ??
        address?['country'] ??
        'India';

    _selectedCountryName = countryName;
    // Map country names/codes to ISO3 codes
    _selectedCountryCode = _mapCountryToCode(countryName);

    // Populate State
    if (panSourceAddress?['state'] != null) {
      _stateController.text = panSourceAddress['state'];
    } else if (uccProfile?['state'] != null) {
      _stateController.text = uccProfile['state'];
    } else if (address?['state'] != null) {
      _stateController.text = address['state'];
    }

    // Populate City
    if (panSourceAddress?['city'] != null) {
      _cityController.text = panSourceAddress['city'];
    } else if (uccProfile?['city'] != null) {
      _cityController.text = uccProfile['city'];
    } else if (address?['city'] != null) {
      _cityController.text = address['city'];
    }

    // Populate Pincode - could be string or int
    final pincode =
        panSourceAddress?['pincode'] ??
        uccProfile?['pincode'] ??
        address?['pincode'];
    if (pincode != null) {
      _pincodeController.text = pincode.toString();
    }

    // Populate Gender
    final gender = holder?['gender'] ?? uccProfile?['primary_gender'];
    if (gender != null) {
      _selectedGender = _mapGenderToLabel(gender);
    }

    // Validate form after populating all fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  String _mapGenderToLabel(String genderCode) {
    switch (genderCode.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return genderCode;
    }
  }

  String _mapGenderToCode(String genderLabel) {
    switch (genderLabel) {
      case 'Male':
        return 'M';
      case 'Female':
        return 'F';
      case 'Other':
        return 'O';
      default:
        return 'M';
    }
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  /// Maps country name or code to ISO3 code
  String? _mapCountryToCode(String countryNameOrCode) {
    final normalized = countryNameOrCode.toUpperCase().trim();

    // Common country mappings (ISO3 codes)
    final Map<String, String> countryMap = {
      'INDIA': 'IND',
      'IND': 'IND',
      'UNITED STATES': 'USA',
      'USA': 'USA',
      'US': 'USA',
      'UNITED KINGDOM': 'GBR',
      'UK': 'GBR',
      'GBR': 'GBR',
      'CANADA': 'CAN',
      'CAN': 'CAN',
      'AUSTRALIA': 'AUS',
      'AUS': 'AUS',
      'CHINA': 'CHN',
      'CHN': 'CHN',
      'JAPAN': 'JPN',
      'JPN': 'JPN',
      'GERMANY': 'DEU',
      'DEU': 'DEU',
      'FRANCE': 'FRA',
      'FRA': 'FRA',
      'SINGAPORE': 'SGP',
      'SGP': 'SGP',
      'UAE': 'ARE',
      'ARE': 'ARE',
      'UNITED ARAB EMIRATES': 'ARE',
    };

    return countryMap[normalized];
  }

  // ── Mode-aware display strings ──────────────────────────────────────────────

  String get _addressTitle {
    switch (widget.validateMode) {
      case 'ri_address':
        return 'Add Indian Address';
      case 'nri_address':
        return 'Add Overseas Address';
      default:
        return 'Verify your details';
    }
  }

  String get _addressSubtitle {
    switch (widget.validateMode) {
      case 'ri_address':
        return 'Please provide your Indian correspondence address';
      case 'nri_address':
        return 'Please provide your overseas correspondence address';
      default:
        return 'Details fetched from PAN records';
    }
  }

  String get _addressSectionLabel {
    switch (widget.validateMode) {
      case 'ri_address':
        return 'Enter your Indian address';
      case 'nri_address':
        return 'Enter your overseas address';
      default:
        return 'Enter your address';
    }
  }

  List<Widget> _buildIndianAddressHint() {
    final indian = widget.validateContext['existing_indian_address'] as Map<String, dynamic>?;
    if (indian == null) return [];

    final line1 = indian['address_line_1'] as String? ?? '';
    final city = indian['city'] as String? ?? '';
    final pincode = indian['pincode'] as String? ?? '';

    return [
      Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16.sp),
                SizedBox(width: 6.w),
                AppText(
                  'Your Indian address on file',
                  variant: AppTextVariant.caption,
                  customColor: Colors.blue,
                  weight: AppTextWeight.semiBold,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            AppText(
              [line1, city, pincode].where((s) => s.isNotEmpty).join(', '),
              variant: AppTextVariant.bodySmall,
              colorType: AppTextColorType.secondary,
            ),
            SizedBox(height: 4.h),
            AppText(
              'As an NRI, please also provide your overseas correspondence address below.',
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildForeignAddressHint() {
    final foreign = widget.validateContext['existing_foreign_address'] as Map<String, dynamic>?;
    if (foreign == null) return [];

    final line1 = foreign['address_line_1'] as String? ?? '';
    final city = foreign['city'] as String? ?? '';
    final country = foreign['country_name'] as String? ?? '';

    return [
      Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16.sp),
                SizedBox(width: 6.w),
                AppText(
                  'Previously entered address',
                  variant: AppTextVariant.caption,
                  customColor: Colors.orange,
                  weight: AppTextWeight.semiBold,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            AppText(
              [line1, city, country].where((s) => s.isNotEmpty).join(', '),
              variant: AppTextVariant.bodySmall,
              colorType: AppTextColorType.secondary,
            ),
            SizedBox(height: 4.h),
            AppText(
              'This address is outside India. Please provide your Indian correspondence address below.',
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ],
        ),
      ),
    ];
  }

  void _validateForm() {
    final addressLine1 = _addressLine1Controller.text.trim();
    final state = _stateController.text.trim();
    final city = _cityController.text.trim();
    final pincode = _pincodeController.text.trim();

    // Pincode validation: 6 digits
    final pincodeValid =
        pincode.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(pincode);

    setState(() {
      _isValid =
          _selectedGender != null &&
          addressLine1.isNotEmpty &&
          _selectedCountryName.isNotEmpty &&
          state.isNotEmpty &&
          city.isNotEmpty &&
          pincodeValid;
    });
  }

  void _handleNext() {
    if (_isValid) {
      final address = {
        'address_line_1': _addressLine1Controller.text.trim(),
        'country': _selectedCountryCode ?? 'IND', // Send ISO code, not name
        'state': _stateController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'gender': _mapGenderToCode(_selectedGender!), // Add gender
      };

      AppLogger.info('Address collected: $address', tag: 'HolderDetailsScreen');

      widget.onNext(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Progress indicator
            _buildProgressBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    // Title
                    Semantics(
                      header: true,
                      child: AppText(
                        _addressTitle,
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    AppText(
                      _addressSubtitle,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),

                    SizedBox(height: 32.h),

                    // Holder Details (Read-only)
                    _buildHolderInfo(),

                    SizedBox(height: 32.h),

                    // Mode-specific hint cards
                    if (widget.validateMode == 'ri_address') ..._buildForeignAddressHint(),
                    if (widget.validateMode == 'nri_address') ..._buildIndianAddressHint(),

                    // Address Section (Editable)
                    Semantics(
                      header: true,
                      child: AppText(
                        _addressSectionLabel,
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.semiBold,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    _buildAddressForm(),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            // Next Button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Get.back(),
              child: Tooltip(
                message: 'Back',
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Semantics(
                header: true,
                child: AppText(
                  'HOLDER DETAILS',
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
              ),
            ),
          ),
          SizedBox(width: 36.w),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Progress step 2 of 5',
              child: LinearProgressIndicator(
                value: 2 / 5, // Step 2 of 5
                backgroundColor: AppColors.darkCardBG,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.darkPrimary,
                ),
                minHeight: 4.h,
              ),
            ),
            SizedBox(height: 8.h),
            AppText(
              'Question 2 of 5',
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolderInfo() {
    final holder = widget.holderData['holder'] ?? {};

    return Semantics(
      container: true,
      label: 'Fetched PAN record details',
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            _buildInfoRow('Name', holder['name'] ?? 'N/A'),
            SizedBox(height: 12.h),
            _buildInfoRow('PAN', holder['pan_number'] ?? 'N/A'),
            SizedBox(height: 12.h),
            _buildInfoRow('Date of Birth', holder['dob'] ?? 'N/A'),
            if (holder['father_name'] != null) ...[
              SizedBox(height: 12.h),
              _buildInfoRow('Father\'s Name', holder['father_name']),
            ],
            if (holder['gender'] != null) ...[
              SizedBox(height: 12.h),
              _buildInfoRow('Gender', _getGenderText(holder['gender'])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
          AppText(
            value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
          ),
        ],
      ),
    );
  }

  String _getGenderText(String gender) {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return gender;
    }
  }

  Widget _buildAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Select Gender',
          hint: 'Opens gender selection sheet',
          value: _selectedGender ?? 'Not selected',
          child: AppDropdown(
            labelText: 'Gender',
            hintText: 'Select your gender',
            value: _selectedGender,
            required: true,
            items: const ['Male', 'Female', 'Other'],
            onChanged: (String? value) {
              setState(() {
                _selectedGender = value;
                _validateForm();
              });
            },
          ),
        ),
        SizedBox(height: 16.h),

        _buildTextField(
          label: 'Address Line 1',
          controller: _addressLine1Controller,
          hint: 'Enter your address',
          required: true,
        ),
        SizedBox(height: 16.h),

        Semantics(
          label: 'Select Country',
          hint: 'Opens country selection sheet',
          value: _selectedCountryName,
          child: CountryDropdown(
            label: 'Country',
            selectedCountryCode: _selectedCountryCode,
            onCountrySelected: (Country country) {
              setState(() {
                _selectedCountryCode = country.code;
                _selectedCountryName = country.name;
              });
              _validateForm();
            },
          ),
        ),
        SizedBox(height: 16.h),

        _buildTextField(
          label: 'State',
          controller: _stateController,
          hint: 'Maharashtra',
          required: true,
        ),
        SizedBox(height: 16.h),

        _buildTextField(
          label: 'City',
          controller: _cityController,
          hint: 'Mumbai',
          required: true,
        ),
        SizedBox(height: 16.h),

        _buildTextField(
          label: 'Pincode',
          controller: _pincodeController,
          hint: '400088',
          keyboardType: TextInputType.visiblePassword,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              );
            }),
          ],
          required: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
            ),
            if (required) ...[
              SizedBox(width: 4.w),
              ExcludeSemantics(
                child: AppText(
                  '*',
                  variant: AppTextVariant.bodyMedium,
                  customColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Semantics(
          label: '$label${required ? ", required" : ""}',
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey.shade600,
              fontSize: 16.sp,
            ),
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor: AppColors.darkCardBG,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
              ),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        text: 'NEXT',
        isFullWidth: true,
        onPressed: _isValid ? _handleNext : null,
        isDisabled: !_isValid,
      ),
    );
  }
}
