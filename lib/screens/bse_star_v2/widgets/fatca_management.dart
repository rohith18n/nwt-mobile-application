import 'package:nwt_app/utils/bse_error_translator.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/bse_fatca_management.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/holder_management.dart';
import 'package:nwt_app/services/auth/profile_service.dart';

class FatcaManagement extends StatefulWidget {
  final VoidCallback? onNext; // Callback to navigate to next screen
  final VoidCallback? onError; // Callback to notify of errors
  final bool shouldSubmit; // Flag to trigger submission
  final PersonalDetails? initialData; // Data for pre-filling
  final String? taxStatus; // Tax status for conditional fields

  const FatcaManagement({
    super.key,
    this.onNext,
    this.onError,
    this.shouldSubmit = false,
    this.initialData,
    this.taxStatus,
  });

  @override
  State<FatcaManagement> createState() => _FatcaManagementState();
}

class _FatcaManagementState extends State<FatcaManagement> {
  // Controllers for form fields
  final TextEditingController occupationCodeController =
      TextEditingController();
  final TextEditingController annualIncomeController = TextEditingController();
  final TextEditingController sourceOfWealthController =
      TextEditingController();
  final TextEditingController taxResidenceController = TextEditingController();
  final TextEditingController maritalStatusController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController countryOfBirthController =
      TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController tinController = TextEditingController();

  // State variables
  bool isGiinAvailable = false;
  bool _isLoading = false;

  // Error Messages State
  String? _fatherNameError;
  String? _motherNameError;
  String? _occupationError;
  String? _annualIncomeError;
  String? _sourceOfWealthError;
  String? _taxResidenceError;
  String? _maritalStatusError;
  String? _nationalityError;
  String? _countryOfBirthError;
  String? _placeOfBirthError;
  String? _tinError;
  bool _hasPersonalDetails = false;

  // Dropdown selection states
  String? _selectedAnnualIncome;
  String? _selectedWealthSource;
  String? _selectedMaritalStatus;

  // Country selections
  Country? _selectedTaxResidence;
  Country? _selectedNationality;
  Country? _selectedCountryOfBirth;

  final FocusNode _placeOfBirthNode = FocusNode();

  // Dropdown data lists
  final List<String> _incomeSlabs = [
    'Below ₹1 Lakh',
    '₹1 Lakh - ₹5 Lakhs',
    '₹5 Lakhs - ₹10 Lakhs',
    '₹10 Lakhs - ₹25 Lakhs',
    '₹25 Lakhs - ₹1 Crore',
    'Above ₹1 Crore',
  ];

  final List<String> _wealthSources = [
    'Salary',
    'Business Income',
    'Gift',
    'Ancestral Property',
    'Rental Income',
    'Prize Money',
    'Royalty',
    'Others',
  ];

  final Map<String, String> _maritalStatusOptions = {
    'Single': 'S',
    'Married': 'M',
    'Widowed': 'W',
    'Divorced': 'D',
  };

  // Helper methods for mapping display values to API codes

  // Helper methods for mapping display values to API codes
  String _getIncomeSlabCode(String incomeSlab) {
    if (incomeSlab == 'Below ₹1 Lakh') return '31';
    if (incomeSlab == '₹1 Lakh - ₹5 Lakhs') return '32';
    if (incomeSlab == '₹5 Lakhs - ₹10 Lakhs') return '33';
    if (incomeSlab == '₹10 Lakhs - ₹25 Lakhs') return '34';
    if (incomeSlab == '₹25 Lakhs - ₹1 Crore') return '35';
    if (incomeSlab == 'Above ₹1 Crore') return '36';
    return '31';
  }

  String _getWealthSourceCode(String wealthSource) {
    if (wealthSource == 'Salary') return '1';
    if (wealthSource == 'Business Income') return '2';
    if (wealthSource == 'Gift') return '3';
    if (wealthSource == 'Ancestral Property') return '4';
    if (wealthSource == 'Rental Income') return '5';
    if (wealthSource == 'Prize Money') return '6';
    if (wealthSource == 'Royalty') return '7';
    if (wealthSource == 'Others') return '8';
    return '1';
  }

  // Reverse mapping for pre-filling
  String _getIncomeSlabDisplay(String code) {
    if (code == '31') return 'Below ₹1 Lakh';
    if (code == '32') return '₹1 Lakh - ₹5 Lakhs';
    if (code == '33') return '₹5 Lakhs - ₹10 Lakhs';
    if (code == '34') return '₹10 Lakhs - ₹25 Lakhs';
    if (code == '35') return '₹25 Lakhs - ₹1 Crore';
    if (code == '36') return 'Above ₹1 Crore';
    return 'Below ₹1 Lakh';
  }

  String _getWealthSourceDisplay(String code) {
    if (code == '1') return 'Salary';
    if (code == '2') return 'Business Income';
    if (code == '3') return 'Gift';
    if (code == '4') return 'Ancestral Property';
    if (code == '5') return 'Rental Income';
    if (code == '6') return 'Prize Money';
    if (code == '7') return 'Royalty';
    if (code == '8') return 'Others';
    return 'Salary';
  }

  // Bottom Sheet Helpers
  void _showIncomeSlabBottomSheet() {
    _showSelectionBottomSheet(
      title: 'Select Annual Income',
      options: _incomeSlabs,
      selectedValue: _selectedAnnualIncome,
      onSelect: (value) {
        setState(() {
          _selectedAnnualIncome = value;
          annualIncomeController.text = _getIncomeSlabCode(value);
        });
        _validateForm(autoScroll: false);
      },
    );
  }

  void _showWealthSourceBottomSheet() {
    _showSelectionBottomSheet(
      title: 'Select Source of Wealth',
      options: _wealthSources,
      selectedValue: _selectedWealthSource,
      onSelect: (value) {
        setState(() {
          _selectedWealthSource = value;
          sourceOfWealthController.text = _getWealthSourceCode(value);
        });
        _validateForm(autoScroll: false);
      },
    );
  }

  void _showMaritalStatusBottomSheet() {
    _showSelectionBottomSheet(
      title: 'Select Marital Status',
      options: _maritalStatusOptions.keys.toList(),
      selectedValue:
          _selectedMaritalStatus == null
              ? null
              : _maritalStatusOptions.keys.firstWhere(
                (k) => _maritalStatusOptions[k] == _selectedMaritalStatus,
                orElse: () => '',
              ),
      onSelect: (value) {
        setState(() {
          _selectedMaritalStatus = _maritalStatusOptions[value]!;
          maritalStatusController.text = _selectedMaritalStatus!;
        });
        _validateForm(autoScroll: false);
      },
    );
  }

  void _showSelectionBottomSheet({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.white,
                ),
                const SizedBox(height: 20),
                ...options.map(
                  (option) => ListTile(
                    title: AppText(
                      option,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                    trailing:
                        selectedValue == option
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : null,
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Dropdown UI Field Builder
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required VoidCallback onTap,
    String? errorText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    value ?? hintText,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    customColor:
                        value != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: errorText),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize marital status controller with default value
    maritalStatusController.text = _selectedMaritalStatus ?? '';

    if (widget.initialData != null) {
      _hasPersonalDetails = true;
      _prepopulateFromInitialData();
    } else {
      // Fetch from Profile API
      _fetchFatcaFromProfileAPI();
    }

    // Listen for shouldSubmit changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _submitFatcaData();
      }
    });
  }

  /// Fetch FATCA data from Profile API and auto-fill
  Future<void> _fetchFatcaFromProfileAPI() async {
    try {
      AppLogger.info('Fetching FATCA data from Profile API', tag: 'FatcaManagement');
      
      final profileData = await ProfileService().getProfileDetails();
      final extendedProfile = profileData?.data?.uccProfile?['extended_profile'];
      
      if (extendedProfile != null && mounted) {
        AppLogger.info(
          'FATCA data found in extended_profile',
          tag: 'FatcaManagement',
        );
        
        setState(() {
          // Professional Information
          if (extendedProfile['primary_occupation'] != null) {
            occupationCodeController.text = extendedProfile['primary_occupation'];
          }
          if (extendedProfile['primary_income_slab'] != null) {
            annualIncomeController.text = extendedProfile['primary_income_slab'];
            _selectedAnnualIncome = _getIncomeSlabDisplay(extendedProfile['primary_income_slab']);
          }
          if (extendedProfile['primary_source_of_wealth'] != null) {
            sourceOfWealthController.text = extendedProfile['primary_source_of_wealth'];
            _selectedWealthSource = _getWealthSourceDisplay(extendedProfile['primary_source_of_wealth']);
          }
          
          // Personal Information
          if (extendedProfile['primary_father_name'] != null) {
            fatherNameController.text = extendedProfile['primary_father_name'];
          }
          if (extendedProfile['primary_mother_name'] != null) {
            motherNameController.text = extendedProfile['primary_mother_name'];
          }
          if (extendedProfile['primary_marital_status'] != null) {
            maritalStatusController.text = extendedProfile['primary_marital_status'];
            _selectedMaritalStatus = extendedProfile['primary_marital_status'];
          }
          if (extendedProfile['primary_pob'] != null) {
            placeOfBirthController.text = extendedProfile['primary_pob'];
          }
          
          // Set default countries to India
          final india = Country(name: 'India', code: 'IND');
          _selectedCountryOfBirth = india;
          countryOfBirthController.text = 'IND';
          _selectedTaxResidence = india;
          taxResidenceController.text = 'IND';
          _selectedNationality = india;
          nationalityController.text = 'IND';
        });
        
        AppLogger.info(
          'FATCA data auto-filled successfully',
          tag: 'FatcaManagement',
        );
      } else {
        AppLogger.info(
          'No FATCA data found, using defaults',
          tag: 'FatcaManagement',
        );
        
        // Set defaults
        setState(() {
          final india = Country(name: 'India', code: 'IND');
          _selectedCountryOfBirth = india;
          countryOfBirthController.text = 'IND';
          _selectedTaxResidence = india;
          taxResidenceController.text = 'IND';
          _selectedNationality = india;
          nationalityController.text = 'IND';
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching FATCA data from Profile API',
        error: e,
        tag: 'FatcaManagement',
      );
      
      // Set defaults on error
      if (mounted) {
        setState(() {
          final india = Country(name: 'India', code: 'IND');
          _selectedCountryOfBirth = india;
          countryOfBirthController.text = 'IND';
          _selectedTaxResidence = india;
          taxResidenceController.text = 'IND';
          _selectedNationality = india;
          nationalityController.text = 'IND';
        });
      }
    }
  }

  void _prepopulateFromInitialData() {
    final data = widget.initialData!;
    occupationCodeController.text = data.occupationCode ?? '';
    annualIncomeController.text = data.annualIncome ?? '';
    sourceOfWealthController.text = data.sourceOfWealth ?? '';
    taxResidenceController.text = data.taxResidence ?? '';
    maritalStatusController.text = data.maritalStatus ?? '';
    nationalityController.text = data.nationality ?? '';
    countryOfBirthController.text = data.countryOfBirth ?? '';
    placeOfBirthController.text = data.placeOfBirth ?? '';
    fatherNameController.text = data.fatherName ?? '';
    motherNameController.text = data.motherName ?? '';
    tinController.text = data.tin ?? '';

    // Set selection states
    _selectedAnnualIncome = _getIncomeSlabDisplay(data.annualIncome ?? '');
    _selectedWealthSource = _getWealthSourceDisplay(data.sourceOfWealth ?? '');
    _selectedMaritalStatus = data.maritalStatus;

    // Set country states
    _selectedTaxResidence = Country(name: '', code: data.taxResidence ?? '');
    _selectedNationality = Country(name: '', code: data.nationality ?? '');
    _selectedCountryOfBirth = Country(
      name: '',
      code: data.countryOfBirth ?? '',
    );
  }

  String _getDisplayMaritalStatus() {
    if (_selectedMaritalStatus == null) return 'Select marital status';
    return _maritalStatusOptions.keys.firstWhere(
      (k) => _maritalStatusOptions[k] == _selectedMaritalStatus,
      orElse: () => _selectedMaritalStatus!,
    );
  }

  @override
  void didUpdateWidget(FatcaManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger submission when shouldSubmit changes from false to true
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitFatcaData();
      });
    }

    // Re-populate if initialData changed
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null) {
      _prepopulateFromInitialData();
    }
  }

  @override
  void dispose() {
    occupationCodeController.dispose();
    annualIncomeController.dispose();
    sourceOfWealthController.dispose();
    taxResidenceController.dispose();
    maritalStatusController.dispose();
    nationalityController.dispose();
    countryOfBirthController.dispose();
    placeOfBirthController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    tinController.dispose();
    _placeOfBirthNode.dispose();
    super.dispose();
  }

  // Removed _isPrefilled to allow updating all fields as requested

  // Validate form fields
  bool _validateForm({bool autoScroll = true}) {
    String? occupationError;
    String? annualIncomeError;
    String? sourceOfWealthError;
    String? taxResidenceError;
    String? maritalStatusError;
    String? nationalityError;
    String? countryOfBirthError;
    String? placeOfBirthError;
    String? fatherNameError;
    String? motherNameError;
    String? tinError;

    bool isValid = true;

    if (fatherNameController.text.trim().isEmpty) {
      fatherNameError = "Please enter father's name";
      isValid = false;
    }

    if (motherNameController.text.trim().isEmpty) {
      motherNameError = "Please enter mother's name";
      isValid = false;
    }

    if (occupationCodeController.text.isEmpty) {
      occupationError = 'Please select occupation';
      isValid = false;
    }

    if (annualIncomeController.text.isEmpty) {
      annualIncomeError = 'Please select annual income';
      isValid = false;
    }

    if (sourceOfWealthController.text.isEmpty) {
      sourceOfWealthError = 'Please select source of wealth';
      isValid = false;
    }

    if (maritalStatusController.text.isEmpty) {
      maritalStatusError = 'Please select marital status';
      isValid = false;
    }

    if (nationalityController.text.isEmpty) {
      nationalityError = 'Please select nationality';
      isValid = false;
    }

    if (countryOfBirthController.text.isEmpty) {
      countryOfBirthError = 'Please select country of birth';
      isValid = false;
    }

    if (placeOfBirthController.text.trim().isEmpty) {
      placeOfBirthError = 'Please enter place of birth';
      isValid = false;
    }

    // TIN validation for NRI
    if (widget.taxStatus == '21' || widget.taxStatus == '24') {
      if (tinController.text.trim().isEmpty) {
        tinError = 'TIN Number is required for NRI users';
        isValid = false;
      }
    }

    setState(() {
      _occupationError = occupationError;
      _annualIncomeError = annualIncomeError;
      _sourceOfWealthError = sourceOfWealthError;
      _taxResidenceError = taxResidenceError;
      _maritalStatusError = maritalStatusError;
      _nationalityError = nationalityError;
      _countryOfBirthError = countryOfBirthError;
      _placeOfBirthError = placeOfBirthError;
      _fatherNameError = fatherNameError;
      _motherNameError = motherNameError;
      _tinError = tinError;
    });

    return isValid;
  }

  // Submit FATCA data to Profile API
  Future<void> _submitFatcaData() async {
    AppLogger.info('Starting FATCA data save', tag: 'FatcaManagement');
    
    if (!_validateForm()) {
      widget.onError?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build extended_profile with FATCA data
      final extendedProfile = ProfileService().buildExtendedProfile(
        // Professional Information
        occupation: occupationCodeController.text.trim(),
        incomeSlab: annualIncomeController.text.trim(),
        sourceOfWealth: sourceOfWealthController.text.trim(),
        
        // Personal Information
        fatherName: fatherNameController.text.trim(),
        motherName: motherNameController.text.trim(),
        maritalStatus: maritalStatusController.text.trim(),
        placeOfBirth: placeOfBirthController.text.trim(),
        
        // NRI Tax ID (if applicable)
        primaryTaxId: tinController.text.trim().isNotEmpty 
            ? tinController.text.trim() 
            : null,
      );
      
      AppLogger.info(
        'Saving FATCA data to Profile API: ${extendedProfile.keys.toList()}',
        tag: 'FatcaManagement',
      );

      // Call Profile API to save FATCA data
      final response = await ProfileService().updateProfileDetails(
        extendedProfile: extendedProfile,
        submitProfile: false, // Don't submit until signature is added
      );

      if (response == null || !response.success) {
        throw Exception(
          response?.message ?? 'Failed to save personal details',
        );
      }
      
      AppLogger.info(
        'FATCA data saved successfully. Profile complete: ${response.data?.profileComplete}',
        tag: 'FatcaManagement',
      );

      // Show success message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Success',
              'Personal details saved successfully!',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        });
      }

      // Navigate to next screen
      if (widget.onNext != null) {
        widget.onNext!();
      }
    } catch (e) {
      AppLogger.error(
        'Error saving FATCA data',
        error: e,
        tag: 'FatcaManagement',
      );
      
      widget.onError?.call();
      
      // Show error message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Error',
              BseErrorTranslator.getFriendlyErrorMessage(
                e.toString().replaceAll('Exception: ', ''),
              ),
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Personal Details',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'Please provide your personal information.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
        if (_hasPersonalDetails) ...[
          const SizedBox(height: 16),
          AppButton(
            text: 'Delete & Reset Personal Details',
            leadingIcon: Icons.delete_outline,
            onPressed: () async {
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text(
                    'Reset Personal Details?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'This will remove your current personal information and allow you to enter it again.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final holderId = await SecureStorage.read('primary_holder_id');
                if (holderId != null) {
                  setState(() => _isLoading = true);
                  final success =
                      await HolderManagementService.deletePersonalDetails(
                        holderId,
                      );
                  setState(() => _isLoading = false);

                  if (success) {
                    // Clear controllers
                    occupationCodeController.clear();
                    annualIncomeController.clear();
                    sourceOfWealthController.clear();
                    taxResidenceController.text = 'IND';
                    maritalStatusController.clear();
                    nationalityController.text = 'IND';
                    countryOfBirthController.text = 'IND';
                    placeOfBirthController.clear();
                    fatherNameController.clear();
                    motherNameController.clear();
                    tinController.clear();

                    setState(() {
                      _selectedAnnualIncome = null;
                      _selectedWealthSource = null;
                      _selectedMaritalStatus = null;
                      _selectedTaxResidence = Country(
                        name: 'India',
                        code: 'IND',
                      );
                      _selectedNationality = Country(
                        name: 'India',
                        code: 'IND',
                      );
                      _selectedCountryOfBirth = Country(
                        name: 'India',
                        code: 'IND',
                      );
                      _hasPersonalDetails = false;
                    });

                    Get.snackbar(
                      'Success',
                      'Personal details reset. You can now enter fresh information.',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to reset personal details. Please try again.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              }
            },
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
          ),
        ],

        const SizedBox(height: 32),
        AppText(
          'Professional Information',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        OccupationDropdown(
          selectedOccupationId:
              occupationCodeController.text.isNotEmpty
                  ? occupationCodeController.text
                  : null,
          enabled: true,
          onOccupationSelected: (occupation) {
            setState(() {
              occupationCodeController.text = occupation.id;
            });
            _validateForm(autoScroll: false);
          },
        ),
        if (_occupationError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _occupationError!),
        ],
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Annual Income',
          value: _selectedAnnualIncome,
          hintText: 'Select annual income range',
          onTap: _showIncomeSlabBottomSheet,
          errorText: _annualIncomeError,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Source of Wealth',
          value: _selectedWealthSource,
          hintText: 'Select source of wealth',
          onTap: _showWealthSourceBottomSheet,
          errorText: _sourceOfWealthError,
        ),

        const SizedBox(height: 32),
        AppText(
          'Personal Information',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkInputField(
          label: "Father's Name",
          controller: fatherNameController,
          hintText: "Enter father's name",
          readOnly: false,
          onChanged: (value) => _validateForm(autoScroll: false),
        ),
        if (_fatherNameError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _fatherNameError!),
        ],
        const SizedBox(height: 16),
        DarkInputField(
          label: "Mother's Name",
          controller: motherNameController,
          hintText: "Enter mother's name",
          readOnly: false,
          onChanged: (value) => _validateForm(autoScroll: false),
        ),
        if (_motherNameError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _motherNameError!),
        ],
        const SizedBox(height: 16),
        CountryDropdown(
          label: 'Tax Residence',
          hintText: 'Select Tax Residence',
          selectedCountryCode: _selectedTaxResidence?.code,
          enabled: true,
          onCountrySelected: (country) {
            setState(() {
              _selectedTaxResidence = country;
              taxResidenceController.text =
                  country.code; // Sending 3-letter code
            });
            _validateForm(autoScroll: false);
          },
        ),
        if (_taxResidenceError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _taxResidenceError!),
        ],
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Marital Status',
          value: _getDisplayMaritalStatus(),
          hintText: 'Select marital status',
          onTap: _showMaritalStatusBottomSheet,
          errorText: _maritalStatusError,
        ),
        const SizedBox(height: 16),
        CountryDropdown(
          label: 'Nationality',
          hintText: 'Select Nationality',
          selectedCountryCode: _selectedNationality?.code,
          enabled: true,
          onCountrySelected: (country) {
            setState(() {
              _selectedNationality = country;
              nationalityController.text = country.code;
            });
            _validateForm(autoScroll: false);
          },
        ),
        if (_nationalityError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _nationalityError!),
        ],
        const SizedBox(height: 16),
        if (widget.taxStatus == '21' || widget.taxStatus == '24') ...[
          DarkInputField(
            label: 'Tax Identification Number (TIN)',
            controller: tinController,
            hintText: 'Enter your TIN number',
            onChanged: (value) => _validateForm(autoScroll: false),
          ),
          if (_tinError != null) ...[
            const SizedBox(height: 6),
            AnimatedErrorMessage(errorMessage: _tinError!),
          ],
          const SizedBox(height: 16),
        ],
        CountryDropdown(
          label: 'Country of Birth',
          hintText: 'Select Country of Birth',
          selectedCountryCode: _selectedCountryOfBirth?.code,
          enabled: true,
          onCountrySelected: (country) {
            setState(() {
              _selectedCountryOfBirth = country;
              countryOfBirthController.text = country.code;
            });
            _validateForm(autoScroll: false);
          },
        ),
        if (_countryOfBirthError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _countryOfBirthError!),
        ],
        const SizedBox(height: 16),
        DarkInputField(
          key: const ValueKey('fatca_place_of_birth'),
          focusNode: _placeOfBirthNode,
          label: 'Place of Birth',
          controller: placeOfBirthController,
          hintText: 'Enter place of birth',
          readOnly: false,
          onChanged: (value) => _validateForm(autoScroll: false),
        ),
        if (_placeOfBirthError != null) ...[
          const SizedBox(height: 6),
          AnimatedErrorMessage(errorMessage: _placeOfBirthError!),
        ],
      ],
    );
  }
}
