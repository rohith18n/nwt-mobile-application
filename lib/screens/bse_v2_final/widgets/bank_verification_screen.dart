import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';

class BankVerificationScreen extends StatefulWidget {
  final Function(Map<String, dynamic> bankData) onNext;
  final VoidCallback? onBack;

  const BankVerificationScreen({super.key, required this.onNext, this.onBack});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final OnboardingV2Service _onboardingService = OnboardingV2Service();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  // NRI fields (overseas address)
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _foreignAddressController =
      TextEditingController();
  final TextEditingController _foreignCityController = TextEditingController();
  final TextEditingController _foreignStateController = TextEditingController();
  final TextEditingController _foreignPincodeController =
      TextEditingController();

  // Indian address fields (for RI with foreign address)
  final TextEditingController _indAddressController = TextEditingController();
  final TextEditingController _indCityController = TextEditingController();
  final TextEditingController _indStateController = TextEditingController();
  final TextEditingController _indPincodeController = TextEditingController();

  bool _isUpiMode = true;
  bool _isValid = false;
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _wasPreVerified = false; // Track if bank was already verified from API
  String _selectedAccountType = 'Savings (Resident Indian)';
  String? _selectedForeignCountryCode;
  String? _selectedForeignCountryName;
  String?
  _savedCountryFromHolderDetails; // Country selected in holder details screen
  Map<String, dynamic>? _verifiedBankData;

  final List<String> _accountTypes = [
    'Savings (Resident Indian)',
    'NRE (Non-Resident External)',
    'NRO (Non-Resident Ordinary)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2BankVerificationScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2BankVerificationScreenViewed, tag: 'event');
    });
    _upiController.addListener(_validateForm);
    _accountNumberController.addListener(_validateForm);
    _ifscController.addListener(_validateForm);
    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      final response = await _onboardingService.getProfileDetails();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Get country from ucc_profile (saved in holder details)
        final uccProfile = data['ucc_profile'];
        if (uccProfile != null && uccProfile['country'] != null) {
          setState(() {
            _savedCountryFromHolderDetails = uccProfile['country'];
          });
          AppLogger.info(
            'Country from holder details: $_savedCountryFromHolderDetails',
            tag: 'BankVerificationScreen',
          );
        }

        // Check if bank is already verified
        final defaultBank = data['default_bank'];
        if (defaultBank != null) {
          setState(() {
            _isVerified = true;
            _wasPreVerified = true;
            _verifiedBankData = {
              'account_holder_name': data['name'] ?? 'Account Holder',
              'bank_name': defaultBank['bank_name'] ?? 'Unknown Bank',
              'account_number': defaultBank['account_number'] ?? '',
              'ifsc_code': defaultBank['ifsc_code'] ?? '',
            };

            // Pre-fill UPI if available
            if (defaultBank['upi_id'] != null) {
              _upiController.text = defaultBank['upi_id'];
              _isUpiMode = true;
            } else {
              // Pre-fill manual bank details
              _accountNumberController.text =
                  defaultBank['account_number'] ?? '';
              _ifscController.text = defaultBank['ifsc_code'] ?? '';
              _bankNameController.text = defaultBank['bank_name'] ?? '';
              _isUpiMode = false;
            }

            // Set account type based on investor_residency
            final residency = data['investor_residency'];
            if (residency == 'NRI-NRE') {
              _selectedAccountType = 'NRE (Non-Resident External)';
            } else if (residency == 'NRI-NRO') {
              _selectedAccountType = 'NRO (Non-Resident Ordinary)';
            } else {
              _selectedAccountType = 'Savings (Resident Indian)';
            }
          });
        }

        // Pre-fill NRI fields if they exist
        if (uccProfile?['primary_tax_id'] != null) {
          _tinController.text = uccProfile!['primary_tax_id'];
        }

        // Pre-fill foreign address from ucc_profile
        if (uccProfile != null &&
            uccProfile['country'] != null &&
            uccProfile['country'] != 'IND') {
          _foreignAddressController.text = uccProfile['address_line_1'] ?? '';
          _foreignCityController.text = uccProfile['city'] ?? '';
          _foreignStateController.text = uccProfile['state'] ?? '';
          _selectedForeignCountryCode = uccProfile['country'];
          _foreignPincodeController.text =
              uccProfile['pincode']?.toString() ?? '';
        }

        // Pre-fill Indian address fields if they exist (ind_* fields)
        if (uccProfile?['ind_address_line_1'] != null) {
          _indAddressController.text = uccProfile!['ind_address_line_1'] ?? '';
          _indCityController.text = uccProfile['ind_city'] ?? '';
          _indStateController.text = uccProfile['ind_state'] ?? '';
          _indPincodeController.text =
              uccProfile['ind_pincode']?.toString() ?? '';
        }

        AppLogger.info(
          'Profile details fetched and pre-filled. Bank verified: $_isVerified',
          tag: 'BankVerificationScreen',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching profile details',
        error: e,
        tag: 'BankVerificationScreen',
      );
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      if (_isUpiMode) {
        _isValid = _upiController.text.trim().isNotEmpty;
      } else {
        final accountNumber = _accountNumberController.text.trim();
        final ifsc = _ifscController.text.trim();
        _isValid =
            accountNumber.isNotEmpty &&
            ifsc.length == 11 &&
            RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
      }
    });
  }

  Future<void> _handleVerify() async {
    if (!_isValid) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      Map<String, dynamic>? response;

      if (_isUpiMode) {
        // Call UPI lookup API
        response = await _onboardingService.upiLookup(
          upiId: _upiController.text.trim(),
        );
      } else {
        response = await _onboardingService.manualBank(
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
          bankName: _bankNameController.text.trim().isNotEmpty
              ? _bankNameController.text.trim()
              : null,
        );

        // Normalize manual bank response to match UPI lookup shape
        if (response != null && response['success'] == true) {
          final bank = response['data']?['bank'];
          final nameAtBank = response['data']?['name_at_bank'];
          response = {
            'success': true,
            'data': {
              'fetched': {
                'name_at_bank': nameAtBank,
                'bank_name': bank?['bank_name'],
                'account_number': bank?['account_number_masked'] ?? bank?['account_number'],
                'ifsc_code': bank?['ifsc_code'],
              },
            },
          };
        }
      }

      if (response != null && response['success'] == true) {
        final fetchedData = response['data']?['fetched'];

        _verifiedBankData = {
          'account_holder_name':
              fetchedData?['name_at_bank'] ??
              fetchedData?['account_holder_name'] ??
              'Account Holder',
          'bank_name': fetchedData?['bank_name'] ?? 'Unknown Bank',
          'account_number': fetchedData?['account_number'] ?? '',
          'ifsc_code': fetchedData?['ifsc_code'] ?? '',
        };

        setState(() {
          _isVerifying = false;
          _isVerified = true;
          // Auto-fill bank name for manual mode
          if (!_isUpiMode) {
            _bankNameController.text = _verifiedBankData!['bank_name'];
          }
        });

        AppLogger.info(
          'Bank verified successfully: $_verifiedBankData',
          tag: 'BankVerificationScreen',
        );
      } else {
        setState(() {
          _isVerifying = false;
        });

        _showError(response?['message'] ?? 'Failed to verify bank details');
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      AppLogger.error(
        'Error verifying bank',
        error: e,
        tag: 'BankVerificationScreen',
      );

      _showError('Failed to verify bank details. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleNext() async {
    if (!_isVerified) return;

    final isIndianAddress =
        (_savedCountryFromHolderDetails?.toUpperCase() ?? 'IND') == 'IND';
    final isNRIAccount = _selectedAccountType.contains('Non-Resident');
    final isRIAccount = _selectedAccountType == 'Savings (Resident Indian)';

    // Validate TIN is provided for NRI accounts
    if (isNRIAccount && _tinController.text.trim().isEmpty) {
      _showError('TIN (Tax Identification Number) is required for NRE/NRO accounts');
      return;
    }

    // Validate all NRI foreign address fields
    if (isIndianAddress && isNRIAccount) {
      if (_foreignAddressController.text.trim().isEmpty) {
        _showError('Foreign address is required for NRE/NRO accounts');
        return;
      }
      if (_foreignCityController.text.trim().isEmpty) {
        _showError('City is required for NRE/NRO accounts');
        return;
      }
      if (_foreignStateController.text.trim().isEmpty) {
        _showError('State is required for NRE/NRO accounts');
        return;
      }
      if (_selectedForeignCountryCode == null || _selectedForeignCountryCode!.isEmpty) {
        _showError('Country is required for NRE/NRO accounts');
        return;
      }
      if (_foreignPincodeController.text.trim().isEmpty) {
        _showError('Pincode is required for NRE/NRO accounts');
        return;
      }
    }

    // Validate Indian address fields for RI with foreign address
    if (!isIndianAddress && isRIAccount) {
      if (_indAddressController.text.trim().isEmpty) {
        _showError('Indian address is required');
        return;
      }
      if (_indCityController.text.trim().isEmpty) {
        _showError('City is required');
        return;
      }
      if (_indStateController.text.trim().isEmpty) {
        _showError('State is required');
        return;
      }
      if (_indPincodeController.text.trim().isEmpty) {
        _showError('Pincode is required');
        return;
      }
    }

    // Case 1: Indian address + NRI account → Save overseas address
    if (isIndianAddress && isNRIAccount) {
      try {
        setState(() {
          _isVerifying = true;
        });

        // NRI address fields go directly in extended_profile (new API format)
        final nriAddress = {
          'address_line_1': _foreignAddressController.text.trim(),
          'city': _foreignCityController.text.trim(),
          'state': _foreignStateController.text.trim(),
          'country': _selectedForeignCountryCode ?? '',
          'pincode': _foreignPincodeController.text.trim(),
        };

        final tin = _tinController.text.trim();

        AppLogger.info(
          'Updating NRI profile details:\nTIN: $tin\nForeign Address: $nriAddress',
          tag: 'BankVerificationScreen',
        );

        final response = await _onboardingService.updateProfileDetails(
          tin: tin,
          address:
              nriAddress, // Send as address, service will map to extended_profile
          investorResidency: _getInvestorResidency(), // Set residency type
        );

        setState(() {
          _isVerifying = false;
        });

        if (response == null || response['success'] != true) {
          _showError('Failed to update NRI details');
          return;
        }

        AppLogger.info(
          'NRI details updated successfully',
          tag: 'BankVerificationScreen',
        );
      } catch (e) {
        setState(() {
          _isVerifying = false;
        });
        AppLogger.error(
          'Error updating NRI details',
          error: e,
          tag: 'BankVerificationScreen',
        );
        _showError('Failed to update NRI details');
        return;
      }
    }

    // Case 2: Foreign address + RI account → Save Indian address (ind_* fields)
    if (!isIndianAddress && isRIAccount) {
      try {
        setState(() {
          _isVerifying = true;
        });

        final indianAddress = {
          'ind_address_line_1': _indAddressController.text.trim(),
          'ind_city': _indCityController.text.trim(),
          'ind_state': _indStateController.text.trim(),
          'ind_pincode': _indPincodeController.text.trim(),
        };

        AppLogger.info(
          'Updating Indian address for RI account:\n$indianAddress',
          tag: 'BankVerificationScreen',
        );

        final response = await _onboardingService.updateProfileDetails(
          address: indianAddress, // Send ind_* fields
        );

        setState(() {
          _isVerifying = false;
        });

        if (response == null || response['success'] != true) {
          _showError('Failed to update Indian address');
          return;
        }

        AppLogger.info(
          'Indian address updated successfully',
          tag: 'BankVerificationScreen',
        );
      } catch (e) {
        setState(() {
          _isVerifying = false;
        });
        AppLogger.error(
          'Error updating Indian address',
          error: e,
          tag: 'BankVerificationScreen',
        );
        _showError('Failed to update Indian address');
        return;
      }
    }

    final bankData = {
      'mode': _isUpiMode ? 'upi' : 'manual',
      'upi_id': _isUpiMode ? _upiController.text.trim() : null,
      'account_number':
          !_isUpiMode ? _accountNumberController.text.trim() : null,
      'ifsc_code':
          !_isUpiMode ? _ifscController.text.trim().toUpperCase() : null,
      'account_type': _getAccountTypeForAPI(), // Convert to API format
      'verified_data': _verifiedBankData,
      'was_pre_verified': _wasPreVerified, // Use actual flag value
    };

    AppLogger.info(
      'Bank data collected: $bankData',
      tag: 'BankVerificationScreen',
    );

    widget.onNext(bankData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
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
                    if (!_isVerified) ...[
                      if (_isUpiMode) _buildUpiForm() else _buildManualForm(),
                      SizedBox(height: 16.h),
                      _buildSwitchModeLink(),
                    ],
                    if (_isVerified) ...[
                      _buildVerifiedBankDetails(),
                      SizedBox(height: 24.h),
                      _buildAccountTypeSection(),
                      _buildConditionalAddressFields(),
                    ],
                  ],
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
              'ADD BANK ACCOUNT',
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
            label: 'Progress step 3 of 5',
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.darkInputBackground,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 3 / 5, // 3 of 5 steps
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
            'Question 3 of 5',
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
        'Bank Validation',
        variant: AppTextVariant.headline4,
        weight: AppTextWeight.bold,
        colorType: AppTextColorType.primary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AppText(
      'A refundable ₹1 will be deducted to verify your bank account via UPI ID.',
      variant: AppTextVariant.bodyMedium,
      colorType: AppTextColorType.gray,
    );
  }

  Widget _buildSwitchModeLink() {
    final linkText =
        _isUpiMode
            ? 'Or enter bank details manually'
            : 'Or verify using UPI ID';
    return Center(
      child: Semantics(
        button: true,
        label: linkText,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isUpiMode = !_isUpiMode;
              _validateForm();
            });
          },
          child: AppText(
            linkText,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            customColor: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildUpiForm() {
    return _buildTextField(
      label: 'UPI ID',
      controller: _upiController,
      hint: 'Enter your UPI ID',
      required: true,
    );
  }

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Account Number',
          controller: _accountNumberController,
          hint: 'Details will auto fetched',
          keyboardType: TextInputType.number,
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'IFSC CODE',
          controller: _ifscController,
          hint: 'Details will auto fetched',
          keyboardType: TextInputType.visiblePassword,
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
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Bank Name',
          controller: _bankNameController,
          hint: 'Details will auto fetched',
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildVerifiedBankDetails() {
    if (_verifiedBankData == null) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Verified Bank Details',
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.darkInputBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                AppText(
                  'Verified Bank Details',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildVerifiedField(
              'Account Holder Name',
              _verifiedBankData!['account_holder_name'],
            ),
            SizedBox(height: 12.h),
            _buildVerifiedField('Bank Name', _verifiedBankData!['bank_name']),
            SizedBox(height: 12.h),
            _buildVerifiedField(
              'Account Number',
              _verifiedBankData!['account_number'],
            ),
            SizedBox(height: 12.h),
            _buildVerifiedField('IFSC CODE', _verifiedBankData!['ifsc_code']),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedField(String label, String value) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 4.h),
          AppText(
            value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSection() {
    return Semantics(
      container: true,
      label: 'Account Type Selection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: AppText(
              'Account Type',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
            ),
          ),
          SizedBox(height: 12.h),
          ..._accountTypes.map((type) => _buildAccountTypeOption(type)),
        ],
      ),
    );
  }

  String _getInvestorResidency() {
    if (_selectedAccountType.contains('NRE')) return 'NRI-NRE';
    if (_selectedAccountType.contains('NRO')) return 'NRI-NRO';
    return 'Resident';
  }

  /// Convert display account type to API format
  String _getAccountTypeForAPI() {
    if (_selectedAccountType.contains('Resident Indian')) return 'Savings (RI)';
    if (_selectedAccountType.contains('Non-Resident External'))
      return 'NRE (NRI)';
    if (_selectedAccountType.contains('Non-Resident Ordinary'))
      return 'NRO (NRI)';
    return 'Savings (RI)'; // Default
  }

  Widget _buildConditionalAddressFields() {
    final isIndianAddress =
        (_savedCountryFromHolderDetails?.toUpperCase() ?? 'IND') == 'IND';
    final isNRIAccount = _selectedAccountType.contains('Non-Resident');
    final isRIAccount = _selectedAccountType == 'Savings (Resident Indian)';

    // Case 1: Indian address + NRI account → Show overseas address fields
    if (isIndianAddress && isNRIAccount) {
      return Column(children: [SizedBox(height: 24.h), _buildNRIFields()]);
    }

    // Case 2: Foreign address + RI account → Show Indian address fields
    if (!isIndianAddress && isRIAccount) {
      return Column(
        children: [SizedBox(height: 24.h), _buildIndianAddressFields()],
      );
    }

    // Case 3: Foreign address + NRI account → No additional fields
    // Case 4: Indian address + RI account → No additional fields
    return const SizedBox.shrink();
  }

  Widget _buildIndianAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: AppText(
            'Indian Address',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
        ),
        SizedBox(height: 8.h),
        AppText(
          'As an RI account holder, please provide your Indian address',
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.gray,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Address',
          controller: _indAddressController,
          hint: 'Indian address',
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'City',
          controller: _indCityController,
          hint: 'City',
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'State',
          controller: _indStateController,
          hint: 'State',
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Pincode',
          controller: _indPincodeController,
          hint: '6-digit PIN',
          keyboardType: TextInputType.number,
          required: true,
        ),
      ],
    );
  }

  Widget _buildNRIFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: AppText(
            'NRI Details',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'TIN',
          controller: _tinController,
          hint: 'Tin',
          required: true,
        ),
        SizedBox(height: 24.h),
        Semantics(
          header: true,
          child: AppText(
            'Enter Your Foreign Address',
            variant: AppTextVariant.bodyLarge,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Address',
          controller: _foreignAddressController,
          hint: 'Address',
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'City',
          controller: _foreignCityController,
          hint: 'City',
          required: true,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'State',
          controller: _foreignStateController,
          hint: 'State',
          required: true,
        ),
        SizedBox(height: 16.h),
        Semantics(
          label: 'Select Country',
          hint: 'Opens country selection sheet',
          value: _selectedForeignCountryName ?? 'Not selected',
          child: CountryDropdown(
            label: 'Country',
            selectedCountryCode: _selectedForeignCountryCode,
            onCountrySelected: (Country country) {
              setState(() {
                _selectedForeignCountryCode = country.code;
                _selectedForeignCountryName = country.name;
              });
            },
          ),
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          label: 'Pincode',
          controller: _foreignPincodeController,
          hint: 'Pincode',
          keyboardType: TextInputType.visiblePassword,
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

  Widget _buildAccountTypeOption(String type) {
    final isSelected = _selectedAccountType == type;
    return Semantics(
      selected: isSelected,
      button: true,
      label: type,
      hint: 'Double tap to select $type',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAccountType = type;
          });
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkInputBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? Colors.white : AppColors.darkInputBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  type,
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.primary,
                ),
              ),
              ExcludeSemantics(
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : AppColors.darkTextGray,
                      width: 2,
                    ),
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child:
                      isSelected
                          ? Icon(Icons.circle, size: 12.sp, color: Colors.black)
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
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
              colorType: AppTextColorType.primary,
            ),
            if (required)
              ExcludeSemantics(
                child: AppText(
                  ' *',
                  variant: AppTextVariant.bodyMedium,
                  customColor: Colors.red,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Semantics(
          label: '$label${required ? ", required" : ""}',
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey.shade600,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.darkTextGray,
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor: AppColors.darkInputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.darkInputBorder,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.darkInputBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white, width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.darkInputBorder.withOpacity(0.5),
                  width: 1,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final buttonText = _isVerified ? 'NEXT' : 'VERIFY';
    final isEnabled = _isVerified ? true : _isValid;
    final onPressed = _isVerified ? _handleNext : _handleVerify;

    return Container(
      padding: EdgeInsets.all(24.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled && !_isVerifying ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isEnabled ? Colors.white : AppColors.darkInputBackground,
            foregroundColor: isEnabled ? Colors.black : AppColors.darkTextGray,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child:
              _isVerifying
                  ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                  : AppText(
                    buttonText,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.bold,
                    customColor:
                        isEnabled ? Colors.black : AppColors.darkTextGray,
                  ),
        ),
      ),
    );
  }
}
