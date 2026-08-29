import 'package:nwt_app/utils/bse_error_translator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/address_management.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/utils/logger.dart';

class AddressManagement extends StatefulWidget {
  final VoidCallback? onNext; // Callback to navigate to next screen
  final VoidCallback? onError; // Callback to notify of errors
  final bool shouldSubmit; // Flag to trigger submission
  final List<Address>? initialData; // Data for pre-filling
  final String? taxStatus; // Tax status from parent

  const AddressManagement({
    super.key,
    this.onNext,
    this.onError,
    this.shouldSubmit = false,
    this.initialData,
    this.taxStatus,
  });

  @override
  State<AddressManagement> createState() => _AddressManagementState();
}

class _AddressManagementState extends State<AddressManagement> {
  // Controllers for the Primary Address (Foreign if NRI, Indian if Resident)
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  String _selectedCountryCode = 'IND';
  String _commCountryCode = 'IND';
  String _selectedAddressType = '1';

  // Controllers for the Communication Address (Indian address for NRIs)
  final TextEditingController _commLine1Controller = TextEditingController();
  final TextEditingController _commLine2Controller = TextEditingController();
  final TextEditingController _commCityController = TextEditingController();
  final TextEditingController _commStateController = TextEditingController();
  final TextEditingController _commPostalCodeController =
      TextEditingController();

  // FocusNodes
  final FocusNode _line1Node = FocusNode();
  final FocusNode _cityNode = FocusNode();
  final FocusNode _stateNode = FocusNode();
  final FocusNode _postalCodeNode = FocusNode();
  final FocusNode _commLine1Node = FocusNode();
  final FocusNode _commCityNode = FocusNode();
  final FocusNode _commStateNode = FocusNode();
  final FocusNode _commPostalCodeNode = FocusNode();
  String _commAddressType = '1';

  // State variables
  bool _isLoading = false;
  bool _isResident = true;
  bool _showCommunicationAddress = false;

  // IDs for updates
  String? _primaryAddressId;
  String? _commAddressId;

  // Error messages
  String? _line1Error;
  String? _line2Error;
  String? _cityError;
  String? _stateError;
  String? _postalCodeError;

  String? _commLine1Error;
  String? _commLine2Error;
  String? _commCityError;
  String? _commStateError;
  String? _commPostalCodeError;

  // Keys for scrolling
  final GlobalKey _primaryAddressKey = GlobalKey();
  final GlobalKey _commAddressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeFlow();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    } else {
      // Fetch from Profile API if no initialData provided
      _fetchAddressFromProfileAPI();
    }
    // Listen for shouldSubmit changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _submitAddressData();
      }
    });
  }
  
  /// Fetch address from Profile API and auto-fill
  Future<void> _fetchAddressFromProfileAPI() async {
    try {
      AppLogger.info('Fetching address from Profile API', tag: 'AddressManagement');
      
      final profileData = await ProfileService().getProfileDetails();
      final uccProfile = profileData?.data?.uccProfile;
      
      if (uccProfile != null && mounted) {
        AppLogger.info(
          'UCC Profile found, extracting address fields',
          tag: 'AddressManagement',
        );
        
        setState(() {
          // Auto-fill primary address from extended_profile fields
          _line1Controller.text = uccProfile['address_line_1'] ?? '';
          _line2Controller.text = uccProfile['address_line_2'] ?? '';
          _cityController.text = uccProfile['city'] ?? '';
          _stateController.text = uccProfile['state'] ?? '';
          _postalCodeController.text = uccProfile['pincode'] ?? '';
          _selectedCountryCode = uccProfile['country'] ?? 'IND';
          
          // For NRI, check for Indian address
          if (uccProfile['ind_address_line_1'] != null) {
            _commLine1Controller.text = uccProfile['ind_address_line_1'] ?? '';
            _commCityController.text = uccProfile['ind_city'] ?? '';
            _commStateController.text = uccProfile['ind_state'] ?? '';
            _commPostalCodeController.text = uccProfile['ind_pincode'] ?? '';
          }
        });
        
        AppLogger.info(
          'Address auto-filled: Line1=${_line1Controller.text}, Line2=${_line2Controller.text}, City=${_cityController.text}',
          tag: 'AddressManagement',
        );
      } else {
        AppLogger.info(
          'No address found in ucc_profile',
          tag: 'AddressManagement',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching address from Profile API',
        error: e,
        tag: 'AddressManagement',
      );
    }
  }

  void _initializeFlow() {
    // 01 is individual resident per tax_status.dart v2
    _isResident = widget.taxStatus == '01' || widget.taxStatus == null;

    if (_isResident) {
      _selectedAddressType = '1';
      _selectedCountryCode = 'IND';
      _showCommunicationAddress = false;
    } else {
      // For NRI, primary is Foreign, communication is Indian
      _selectedAddressType = '6'; // Foreign Residential
      _selectedCountryCode = 'USA'; // Default foreign country
      _commAddressType = '1'; // Indian Residential
      _commCountryCode = 'IND';
      _showCommunicationAddress = true; // Show both by default for NRIs
    }
  }

  void _prepopulateFromInitialData() {
    final addresses = widget.initialData!;
    Address? primary;
    Address? comm;

    if (_isResident) {
      // Find any resident address, preferably primary
      primary = addresses.firstWhere(
        (a) => a.addressType == '1' || a.addressType == '5',
        orElse: () => addresses.first,
      );
    } else {
      // NRI: Look for foreign address as primary
      try {
        primary = addresses.firstWhere(
          (a) => a.addressType == '6' || a.addressType == '10',
        );
      } catch (_) {
        primary = addresses.first;
      }

      // Look for indian address as communication
      try {
        comm = addresses.firstWhere(
          (a) => a.addressType == '1' || a.addressType == '5',
        );
      } catch (_) {
        comm = null;
      }

      _showCommunicationAddress = true; // For NRIs, always show dual inputs
    }

    // Set Primary Address values
    _line1Controller.text = primary.line1 ?? '';
    _line2Controller.text = primary.line2 ?? '';
    _cityController.text = primary.city ?? '';
    _stateController.text = primary.state ?? '';
    _selectedCountryCode = primary.country ?? (_isResident ? 'IND' : 'USA');
    _postalCodeController.text = primary.postalCode ?? '';
    _primaryAddressId = primary.id;

    // Set selected address type if it's within our restricted set
    if (primary.addressType != null) {
      if (_isResident &&
          (primary.addressType == '1' || primary.addressType == '5')) {
        _selectedAddressType = primary.addressType!;
      } else if (!_isResident &&
          (primary.addressType == '6' || primary.addressType == '10')) {
        _selectedAddressType = primary.addressType!;
      }
    }

    // Set Communication Address values if present
    if (comm != null) {
      _commLine1Controller.text = comm.line1 ?? '';
      _commLine2Controller.text = comm.line2 ?? '';
      _commCityController.text = comm.city ?? '';
      _commStateController.text = comm.state ?? '';
      _commPostalCodeController.text = comm.postalCode ?? '';
      _commCountryCode = comm.country ?? 'IND';
      _commAddressType = comm.addressType ?? '1';
      _commAddressId = comm.id;
    }
  }

  @override
  void didUpdateWidget(AddressManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitAddressData();
      });
    }

    // Re-populate if initialData changed and we are not recently submitted
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null &&
        widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _commLine1Controller.dispose();
    _commLine2Controller.dispose();
    _commCityController.dispose();
    _commStateController.dispose();
    _commPostalCodeController.dispose();

    _line1Node.dispose();
    _cityNode.dispose();
    _stateNode.dispose();
    _postalCodeNode.dispose();
    _commLine1Node.dispose();
    _commCityNode.dispose();
    _commStateNode.dispose();
    _commPostalCodeNode.dispose();
    super.dispose();
  }

  bool _validateForm({bool autoScroll = true}) {
    String? line1Error;
    String? line2Error;
    String? cityError;
    String? stateError;
    String? postalCodeError;
    String? commLine1Error;
    String? commLine2Error;
    String? commCityError;
    String? commStateError;
    String? commPostalCodeError;

    bool isValid = true;
    GlobalKey? firstErrorKey;

    // Primary Address Validation
    final line1 = _line1Controller.text.trim();
    if (line1.isEmpty) {
      line1Error = 'Address is required';
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    } else if (line1.length < 10 || line1.length > 40) {
      line1Error = 'Address line 1 must be between 10 and 40 characters';
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    }

    final line2 = _line2Controller.text.trim();
    if (line2.isNotEmpty && (line2.length < 10 || line2.length > 40)) {
      line2Error =
          'Address line 2 must be between 10 and 40 characters if provided';
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    }
    if (_cityController.text.trim().isEmpty) {
      cityError = 'City is required';
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    }
    if (_stateController.text.trim().isEmpty) {
      stateError = 'State is required';
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    }
    final pCodeErr = AppValidators.validatePostalCode(
      _postalCodeController.text.trim(),
      countryCode: _isResident ? _selectedCountryCode : 'FOREIGN',
    );
    if (pCodeErr != null) {
      postalCodeError = pCodeErr;
      firstErrorKey ??= _primaryAddressKey;
      isValid = false;
    }

    // Communication Address Validation
    if (_showCommunicationAddress) {
      final commLine1 = _commLine1Controller.text.trim();
      if (commLine1.isEmpty) {
        commLine1Error = 'Communication Address is required';
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      } else if (commLine1.length < 10 || commLine1.length > 40) {
        commLine1Error = 'Address line 1 must be between 10 and 40 characters';
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      }

      final commLine2 = _commLine2Controller.text.trim();
      if (commLine2.isNotEmpty &&
          (commLine2.length < 10 || commLine2.length > 40)) {
        commLine2Error =
            'Address line 2 must be between 10 and 40 characters if provided';
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      }
      if (_commCityController.text.trim().isEmpty) {
        commCityError = 'City is required';
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      }
      if (_commStateController.text.trim().isEmpty) {
        commStateError = 'State is required';
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      }
      final commPCodeErr = AppValidators.validatePostalCode(
        _commPostalCodeController.text.trim(),
        countryCode: _commCountryCode,
      );
      if (commPCodeErr != null) {
        commPostalCodeError = commPCodeErr;
        firstErrorKey ??= _commAddressKey;
        isValid = false;
      }
    }

    setState(() {
      _line1Error = line1Error;
      _line2Error = line2Error;
      _cityError = cityError;
      _stateError = stateError;
      _postalCodeError = postalCodeError;
      _commLine1Error = commLine1Error;
      _commLine2Error = commLine2Error;
      _commCityError = commCityError;
      _commStateError = commStateError;
      _commPostalCodeError = commPostalCodeError;
    });

    if (autoScroll &&
        firstErrorKey != null &&
        firstErrorKey.currentContext != null) {
      Scrollable.ensureVisible(
        firstErrorKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }

    return isValid;
  }

  Future<void> _submitAddressData() async {
    AppLogger.info('Starting address save', tag: 'AddressManagement');
    
    if (!_validateForm()) {
      widget.onError?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build extended_profile with address data
      final extendedProfile = ProfileService().buildExtendedProfile(
        // Primary Address (Correspondence)
        addressLine1: _line1Controller.text.trim(),
        addressLine2: _line2Controller.text.trim().isNotEmpty 
            ? _line2Controller.text.trim() 
            : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _postalCodeController.text.trim(),
        country: _selectedCountryCode,
        
        // Communication Address (Indian address for NRI)
        indAddressLine1: _showCommunicationAddress 
            ? _commLine1Controller.text.trim() 
            : null,
        indCity: _showCommunicationAddress 
            ? _commCityController.text.trim() 
            : null,
        indState: _showCommunicationAddress 
            ? _commStateController.text.trim() 
            : null,
        indPincode: _showCommunicationAddress 
            ? _commPostalCodeController.text.trim() 
            : null,
      );
      
      AppLogger.info(
        'Saving address to Profile API: ${extendedProfile.keys.toList()}',
        tag: 'AddressManagement',
      );

      // Call Profile API to save address
      final response = await ProfileService().updateProfileDetails(
        extendedProfile: extendedProfile,
        submitProfile: false, // Don't submit until signature is added
      );

      if (response == null || !response.success) {
        throw Exception(
          response?.message ?? 'Failed to save address information',
        );
      }
      
      AppLogger.info(
        'Address saved successfully. Profile complete: ${response.data?.profileComplete}',
        tag: 'AddressManagement',
      );

      // Show success message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Success',
              'Address information saved successfully!',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
          }
        });
      }

      if (widget.onNext != null) {
        widget.onNext!();
      }
    } catch (e) {
      widget.onError?.call();
      
      // Show error message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Error',
              BseErrorTranslator.getFriendlyErrorMessage(
                e.toString().contains('Exception: ')
                    ? e.toString().replaceAll('Exception: ', '')
                    : 'An unexpected error occurred',
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Address Details',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 8),
          AppText(
            'Please provide your address for communication and verification.',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.medium,
          ),
          if (_primaryAddressId != null) ...[
            const SizedBox(height: 16),
            AppButton(
              text: 'Delete & Reset Address',
              leadingIcon: Icons.delete_outline,
              onPressed: () async {
                final confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Reset Address Details?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will remove your current address information and allow you to enter it again.',
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
                  setState(() => _isLoading = true);
                  final success = await AddressManagementService.deleteAddress(
                    _primaryAddressId!,
                  );

                  // If there's a communication address, delete it too
                  if (success && _commAddressId != null) {
                    await AddressManagementService.deleteAddress(
                      _commAddressId!,
                    );
                  }

                  setState(() => _isLoading = false);

                  if (success) {
                    // Clear controllers
                    _line1Controller.clear();
                    _line2Controller.clear();
                    _cityController.clear();
                    _stateController.clear();
                    _postalCodeController.clear();
                    _commLine1Controller.clear();
                    _commLine2Controller.clear();
                    _commCityController.clear();
                    _commStateController.clear();
                    _commPostalCodeController.clear();

                    setState(() {
                      _primaryAddressId = null;
                      _commAddressId = null;
                      _showCommunicationAddress = false;
                      _initializeFlow(); // Reset defaults
                    });

                    Get.snackbar(
                      'Success',
                      'Address information reset. You can now enter fresh details.',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to reset address details. Please try again.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              variant: AppButtonVariant.destructive,
              isFullWidth: true,
            ),
          ],
          const SizedBox(height: 32),

          // Primary Address Section
          _buildAddressSection(
            title:
                _isResident ? 'Address Details' : 'Foreign Address (Permanent)',
            line1Controller: _line1Controller,
            line2Controller: _line2Controller,
            cityController: _cityController,
            stateController: _stateController,
            postalCodeController: _postalCodeController,
            countryCode: _selectedCountryCode,
            addressType: _selectedAddressType,
            onCountryChanged:
                (code) => setState(() => _selectedCountryCode = code),
            onTypeChanged:
                (type) => setState(() {
                  _selectedAddressType = type;
                  if (type == '6' || type == '10') {
                    // Foreign address type selected
                  } else if (_postalCodeController.text == '999999') {
                    _postalCodeController.clear();
                  }
                }),
            line1Error: _line1Error,
            line2Error: _line2Error,
            cityError: _cityError,
            stateError: _stateError,
            postalCodeError: _postalCodeError,
            key: _primaryAddressKey,
          ),

          // Indian Address Section for NRIs
          if (!_isResident) ...[
            const SizedBox(height: 24),
            _buildAddressSection(
              title: 'Indian Address (Communication)',
              line1Controller: _commLine1Controller,
              line2Controller: _commLine2Controller,
              cityController: _commCityController,
              stateController: _commStateController,
              postalCodeController: _commPostalCodeController,
              countryCode: _commCountryCode,
              addressType: _commAddressType,
              onCountryChanged:
                  (code) => setState(() => _commCountryCode = code),
              onTypeChanged: (type) => setState(() => _commAddressType = type),
              line1Error: _commLine1Error,
              line2Error: _commLine2Error,
              cityError: _commCityError,
              stateError: _commStateError,
              postalCodeError: _commPostalCodeError,
              key: _commAddressKey,
              isComm: true,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAddressSection({
    required String title,
    required TextEditingController line1Controller,
    required TextEditingController line2Controller,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController postalCodeController,
    required String countryCode,
    required String addressType,
    required Function(String) onCountryChanged,
    required Function(String) onTypeChanged,
    String? line1Error,
    String? line2Error,
    String? cityError,
    String? stateError,
    String? postalCodeError,
    required GlobalKey key,
    bool isComm = false,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          variant: AppTextVariant.bodyLarge,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),
        const SizedBox(height: 16),

        // Address Type Dropdown
        _buildAddressTypeDropdown(addressType, onTypeChanged, isComm),
        const SizedBox(height: 16),

        CountryDropdown(
          label: 'Country',
          selectedCountryCode: countryCode,
          enabled: true,
          onCountrySelected: (c) => onCountryChanged(c.code),
        ),
        const SizedBox(height: 16),

        DarkInputField(
          key: ValueKey('${isComm ? 'comm_' : 'primary_'}line1'),
          focusNode: isComm ? _commLine1Node : _line1Node,
          label: 'Address Line 1',
          controller: line1Controller,
          hintText: 'Enter street address',
          readOnly: false,
          onChanged: (val) => _validateForm(autoScroll: false),
        ),
        AnimatedErrorMessage(errorMessage: line1Error),
        const SizedBox(height: 16),

        DarkInputField(
          label: 'Address Line 2 (Optional)',
          controller: line2Controller,
          hintText: 'Enter apartment, suite, etc.',
          readOnly: false,
          onChanged: (val) => _validateForm(autoScroll: false),
        ),
        AnimatedErrorMessage(errorMessage: line2Error),
        const SizedBox(height: 16),

        DarkInputField(
          key: ValueKey('${isComm ? 'comm_' : 'primary_'}city'),
          focusNode: isComm ? _commCityNode : _cityNode,
          label: 'City',
          controller: cityController,
          hintText: 'City',
          readOnly: false,
          onChanged: (val) => _validateForm(autoScroll: false),
        ),
        AnimatedErrorMessage(errorMessage: cityError),

        const SizedBox(height: 16),

        DarkInputField(
          key: ValueKey('${isComm ? 'comm_' : 'primary_'}postalcode'),
          focusNode: isComm ? _commPostalCodeNode : _postalCodeNode,
          label: 'Postal Code',
          controller: postalCodeController,
          hintText: 'Postal code',
          keyboardType:
              (!_isResident && !isComm)
                  ? TextInputType.text
                  : TextInputType.number,
          readOnly: false,
          inputFormatters: AppInputFormatters.postalCodeFormatters(
            length: (!_isResident && !isComm) ? 12 : 6,
            numericOnly: !(!_isResident && !isComm),
          ),
          onChanged: (val) => _validateForm(autoScroll: false),
        ),
        AnimatedErrorMessage(errorMessage: postalCodeError),
        const SizedBox(height: 16),

        DarkInputField(
          key: ValueKey('${isComm ? 'comm_' : 'primary_'}state'),
          focusNode: isComm ? _commStateNode : _stateNode,
          label: 'State',
          controller: stateController,
          hintText: 'State',
          readOnly: false,
          onChanged: (val) => _validateForm(autoScroll: false),
        ),
        AnimatedErrorMessage(errorMessage: stateError),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddressTypeDropdown(
    String currentType,
    Function(String) onChanged,
    bool isComm,
  ) {
    List<MapEntry<String, String>> options = [];
    if (isComm || _isResident) {
      options = [
        const MapEntry('1', 'Residential or Business'),
        const MapEntry('5', 'Other'),
      ];
    } else {
      options = [
        const MapEntry('6', 'Residential or Business (Foreign)'),
        const MapEntry('10', 'Other (Foreign)'),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Address Type',
          variant: AppTextVariant.bodySmall,
          customColor: Colors.white70,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  options.any((e) => e.key == currentType)
                      ? currentType
                      : options.first.key,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items:
                  options.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: AppText(
                        e.value,
                        variant: AppTextVariant.bodyMedium,
                        customColor: Colors.white,
                      ),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
