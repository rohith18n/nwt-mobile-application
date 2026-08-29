import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/screens/bse_star_v2/types/tax_status.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';

class SecondaryHolderManagement extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool shouldSubmit;
  final VoidCallback? onError;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const SecondaryHolderManagement({
    super.key,
    this.initialData,
    this.shouldSubmit = false,
    this.onError,
    this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<SecondaryHolderManagement> createState() => _SecondaryHolderManagementState();
}

class _SecondaryHolderManagementState extends State<SecondaryHolderManagement> {
  bool _isLoading = false;

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Address Fields (for all secondary holders)
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  
  // NRI-specific Fields
  final TextEditingController _tinController = TextEditingController();
  String? _selectedForeignCountry;

  // Error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _panError;
  String? _dobError;
  String? _mobileError;
  String? _emailError;
  String? _addressLine1Error;
  String? _cityError;
  String? _stateError;
  String? _pincodeError;
  String? _tinError;
  String? _foreignCountryError;

  // Dropdowns
  TaxStatus _selectedTaxStatus = TaxStatus.all.first;
  String _selectedGender = 'M';

  // Helper
  bool get _isNRI => _selectedTaxStatus.code == '21' || _selectedTaxStatus.code == '24';

  @override
  void initState() {
    super.initState();
    _fetchSecondaryHolderData();
  }

  @override
  void didUpdateWidget(SecondaryHolderManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldSubmit && !oldWidget.shouldSubmit) {
      _submitSecondaryHolderData();
    }
  }

  Future<void> _fetchSecondaryHolderData() async {
    setState(() => _isLoading = true);
    try {
      AppLogger.info('Fetching secondary holder data', tag: 'Secondary_Holder');

      final response = await ProfileService().getProfileDetails();

      AppLogger.info(
        'Profile API Response - Success: ${response?.success}',
        tag: 'Secondary_Holder',
      );

      if (response != null && response.success && response.data != null) {
        final ucc = response.data!.uccProfile;

        if (ucc != null && ucc.isNotEmpty) {
          AppLogger.info('UCC Profile Data: ${ucc.toString()}', tag: 'Secondary_Holder');

          setState(() {
            // Map secondary holder fields
            if (ucc['secondary_first_name'] != null) {
              _firstNameController.text = ucc['secondary_first_name'];
            }
            if (ucc['secondary_middle_name'] != null) {
              _middleNameController.text = ucc['secondary_middle_name'];
            }
            if (ucc['secondary_last_name'] != null) {
              _lastNameController.text = ucc['secondary_last_name'];
            }
            if (ucc['secondary_pan'] != null) {
              _panController.text = ucc['secondary_pan'];
            }
            if (ucc['secondary_dob'] != null) {
              _dobController.text = ucc['secondary_dob'];
            }
            if (ucc['secondary_mobile'] != null) {
              _mobileController.text = ucc['secondary_mobile'];
            }
            if (ucc['secondary_email'] != null) {
              _emailController.text = ucc['secondary_email'];
            }
            if (ucc['secondary_gender'] != null) {
              _selectedGender = ucc['secondary_gender'];
            }

            // Map tax status
            if (ucc['secondary_tax_status'] != null) {
              try {
                _selectedTaxStatus = TaxStatus.all.firstWhere(
                  (e) => e.code == ucc['secondary_tax_status'].toString(),
                  orElse: () => _selectedTaxStatus,
                );
              } catch (_) {}
            }

            // Map NRI fields
            if (ucc['secondary_tax_id'] != null) {
              _tinController.text = ucc['secondary_tax_id'];
            }
            if (ucc['secondary_country'] != null && ucc['secondary_country'] != 'IND') {
              _selectedForeignCountry = ucc['secondary_country'];
            }
            // Load address fields
            if (ucc['secondary_address_line_1'] != null) {
              _addressLine1Controller.text = ucc['secondary_address_line_1'];
            }
            if (ucc['secondary_city'] != null) {
              _cityController.text = ucc['secondary_city'];
            }
            if (ucc['secondary_state'] != null) {
              _stateController.text = ucc['secondary_state'];
            }
            if (ucc['secondary_pincode'] != null) {
              _pincodeController.text = ucc['secondary_pincode'];
            }
          });

          AppLogger.info(
            'Secondary holder data loaded - Tax Status: ${_selectedTaxStatus.status}',
            tag: 'Secondary_Holder',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching secondary holder data: $e', tag: 'Secondary_Holder');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSecondaryHolderData() async {
    if (!_validateForm()) {
      widget.onError?.call();
      return;
    }

    setState(() => _isLoading = true);

    try {
      AppLogger.info('Submitting secondary holder data', tag: 'Secondary_Holder');

      final extendedProfile = ProfileService().buildExtendedProfile(
        secondaryFirstName: _firstNameController.text.trim(),
        secondaryMiddleName: _middleNameController.text.trim().isNotEmpty
            ? _middleNameController.text.trim()
            : null,
        secondaryLastName: _lastNameController.text.trim(),
        secondaryPan: _panController.text.trim().toUpperCase(),
        secondaryDob: _dobController.text.trim(),
        secondaryMobile: _mobileController.text.trim(),
        secondaryEmail: _emailController.text.trim(),
        secondaryGender: _selectedGender,
        secondaryTaxStatus: _selectedTaxStatus.code,
        
        // NRI fields
        secondaryTaxId: _isNRI && _tinController.text.trim().isNotEmpty
            ? _tinController.text.trim()
            : null,
        // Address fields (for all secondary holders)
        secondaryAddressLine1: _addressLine1Controller.text.trim().isNotEmpty
            ? _addressLine1Controller.text.trim()
            : null,
        secondaryCity: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        secondaryState: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        secondaryPincode: _pincodeController.text.trim().isNotEmpty
            ? _pincodeController.text.trim()
            : null,
        secondaryCountry: _isNRI && _selectedForeignCountry != null
            ? _selectedForeignCountry
            : 'IND',
      );

      AppLogger.info(
        'Secondary holder extended profile: ${extendedProfile.keys.toList()}',
        tag: 'Secondary_Holder',
      );

      final response = await ProfileService().updateProfileDetails(
        extendedProfile: extendedProfile,
        submitProfile: false,
      );

      if (response != null && response.success) {
        AppLogger.info('Secondary holder data saved successfully', tag: 'Secondary_Holder');

        if (mounted) {
          widget.onNext?.call();
        }
      } else {
        throw Exception(response?.message ?? 'Failed to save secondary holder data');
      }
    } catch (e) {
      AppLogger.error('Error submitting secondary holder: $e', tag: 'Secondary_Holder');
      if (mounted) {
        widget.onError?.call();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _panError = null;
      _dobError = null;
      _mobileError = null;
      _emailError = null;
      _addressLine1Error = null;
      _cityError = null;
      _stateError = null;
      _pincodeError = null;
      _tinError = null;
      _foreignCountryError = null;
    });

    // Validate required fields
    if (_firstNameController.text.trim().isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      isValid = false;
    }

    if (_panController.text.trim().isEmpty) {
      setState(() => _panError = 'PAN is required');
      isValid = false;
    } else if (_panController.text.trim().length != 10) {
      setState(() => _panError = 'PAN must be 10 characters');
      isValid = false;
    }

    if (_dobController.text.trim().isEmpty) {
      setState(() => _dobError = 'Date of birth is required');
      isValid = false;
    }

    if (_mobileController.text.trim().isEmpty) {
      setState(() => _mobileError = 'Mobile number is required');
      isValid = false;
    } else if (AppValidators.cleanPhoneNumber(_mobileController.text.trim()).length != 10) {
      setState(() => _mobileError = 'Mobile must be 10 digits');
      isValid = false;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    }

    // Validate address fields (required for all secondary holders)
    if (_addressLine1Controller.text.trim().isEmpty) {
      setState(() => _addressLine1Error = 'Address is required');
      isValid = false;
    }

    if (_cityController.text.trim().isEmpty) {
      setState(() => _cityError = 'City is required');
      isValid = false;
    }

    if (_stateController.text.trim().isEmpty) {
      setState(() => _stateError = 'State is required');
      isValid = false;
    }

    if (_pincodeController.text.trim().isEmpty) {
      setState(() => _pincodeError = 'Pincode is required');
      isValid = false;
    }

    // Validate NRI-specific fields
    if (_isNRI) {
      if (_tinController.text.trim().isEmpty) {
        setState(() => _tinError = 'Foreign Tax ID (TIN) is required for NRI');
        isValid = false;
      }

      if (_selectedForeignCountry == null || _selectedForeignCountry == 'IND') {
        setState(() => _foreignCountryError = 'Foreign country is required for NRI');
        isValid = false;
      }
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        widget.onBack?.call();
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header Section
                  const AppText(
                    'Secondary Holder',
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 8.h),
                  const AppText(
                    'Add a joint holder for Anyone or Survivor account (Optional)',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.muted,
                  ),
                  SizedBox(height: 24.h),
                  
                  const AppText(
                    'Personal Information',
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 16.h),

                  // First Name
                  DarkInputField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hintText: 'Enter first name',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  if (_firstNameError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _firstNameError!),
                  ],
                  const SizedBox(height: 24),

                  // Middle Name
                  DarkInputField(
                    controller: _middleNameController,
                    label: 'Middle Name (Optional)',
                    hintText: 'Enter middle name',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 24),

                  // Last Name
                  DarkInputField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hintText: 'Enter last name',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  if (_lastNameError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _lastNameError!),
                  ],
                  const SizedBox(height: 24),

                  // PAN
                  DarkInputField(
                    controller: _panController,
                    label: 'PAN',
                    hintText: 'Enter PAN number',
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {},
                  ),
                  if (_panError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _panError!),
                  ],
                  const SizedBox(height: 24),

                  // Date of Birth
                  DarkInputField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    isDateField: true,
                    dateFormat: 'yyyy-MM-dd',
                    lastDate: DateTime(
                      DateTime.now().year - 18,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                    onChanged: (value) {},
                  ),
                  if (_dobError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _dobError!),
                  ],
                  const SizedBox(height: 24),

                  // Gender
                  AppDropdown(
                    labelText: 'Gender',
                    value: _selectedGender == 'M' ? 'Male' : _selectedGender == 'F' ? 'Female' : 'Other',
                    items: const ['Male', 'Female', 'Other'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          if (value == 'Male') {
                            _selectedGender = 'M';
                          } else if (value == 'Female') {
                            _selectedGender = 'F';
                          } else {
                            _selectedGender = 'O';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Mobile
                  DarkInputField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    hintText: 'Enter 10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {},
                  ),
                  if (_mobileError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _mobileError!),
                  ],
                  const SizedBox(height: 24),

                  // Email
                  DarkInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {},
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _emailError!),
                  ],
                  const SizedBox(height: 24),

                  // Tax Status
                  AppDropdown(
                    labelText: 'Tax Status',
                    value: _selectedTaxStatus.status,
                    items: TaxStatus.bseOptions.map((e) => e.status).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTaxStatus = TaxStatus.bseOptions.firstWhere(
                            (e) => e.status == value,
                            orElse: () => _selectedTaxStatus,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Address Section (for all secondary holders)
                  const AppText(
                    'Address Details',
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  const SizedBox(height: 16),

                  // NRI-specific fields (TIN and Country)
                  if (_isNRI) ...[
                    // Foreign TIN
                    DarkInputField(
                      controller: _tinController,
                      label: 'Foreign Tax ID (TIN)',
                      hintText: 'Enter foreign tax identification number',
                      onChanged: (value) {},
                    ),
                    if (_tinError != null) ...[
                      const SizedBox(height: 6),
                      AnimatedErrorMessage(errorMessage: _tinError!),
                    ],
                    const SizedBox(height: 24),

                    // Foreign Country
                    CountryDropdown(
                      label: 'Country',
                      selectedCountryCode: _selectedForeignCountry,
                      onCountrySelected: (country) {
                        setState(() {
                          _selectedForeignCountry = country.code;
                        });
                      },
                    ),
                    if (_foreignCountryError != null) ...[
                      const SizedBox(height: 6),
                      AnimatedErrorMessage(errorMessage: _foreignCountryError!),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Address Line 1 (for all)
                  DarkInputField(
                    controller: _addressLine1Controller,
                    label: _isNRI ? 'Foreign Address Line 1' : 'Address Line 1',
                    hintText: 'Enter address line 1',
                    keyboardType: TextInputType.streetAddress,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  if (_addressLine1Error != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _addressLine1Error!),
                  ],
                  const SizedBox(height: 24),

                  // City (for all)
                  DarkInputField(
                    controller: _cityController,
                    label: 'City',
                    hintText: 'Enter city',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  if (_cityError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _cityError!),
                  ],
                  const SizedBox(height: 24),

                  // State (for all)
                  DarkInputField(
                    controller: _stateController,
                    label: _isNRI ? 'State/Province' : 'State',
                    hintText: 'Enter state',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {},
                  ),
                  if (_stateError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _stateError!),
                  ],
                  const SizedBox(height: 24),

                  // Pincode (for all)
                  DarkInputField(
                    controller: _pincodeController,
                    label: _isNRI ? 'Postal Code' : 'Pincode',
                    hintText: _isNRI ? 'Enter postal code' : 'Enter 6-digit pincode',
                    keyboardType: TextInputType.text,
                    onChanged: (value) {},
                  ),
                  if (_pincodeError != null) ...[
                    const SizedBox(height: 6),
                    AnimatedErrorMessage(errorMessage: _pincodeError!),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(height: 32.h),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _panController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _tinController.dispose();
    super.dispose();
  }
}
