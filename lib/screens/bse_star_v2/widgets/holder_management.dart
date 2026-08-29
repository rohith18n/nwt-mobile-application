import 'package:nwt_app/utils/bse_error_translator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/holder_management.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';

import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/bse_star_v2/types/tax_status.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/screens/bse_star_v2/types/holder_management.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/types/auth/profile_details.dart';

class HolderManagement extends StatefulWidget {
  final VoidCallback? onNext; // Callback to navigate to next screen
  final VoidCallback? onBack; // Callback to navigate back
  final VoidCallback? onError; // Callback to notify of errors
  final bool shouldSubmit; // Flag to trigger submission
  final HolderElement? initialData; // Data for pre-filling

  const HolderManagement({
    super.key,
    this.onNext,
    this.onBack,
    this.onError,
    this.shouldSubmit = false,
    this.initialData,
  });

  @override
  State<HolderManagement> createState() => _HolderManagementState();
}

class _HolderManagementState extends State<HolderManagement> {
  // Controllers for the form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // FocusNodes
  final FocusNode _firstNameNode = FocusNode();
  final FocusNode _lastNameNode = FocusNode();
  final FocusNode _middleNameNode = FocusNode();
  final FocusNode _panNode = FocusNode();
  final FocusNode _dobNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _emailNode = FocusNode();

  // State variables
  String _selectedGender = 'M';
  bool _isLoading = false;
  ProfileDetailsData? _serverProfileData;
  
  // Occupation and Income
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _incomeSlabController = TextEditingController();
  String? _selectedIncomeSlab;

  // NRI-specific fields (Foreign Address)
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _foreignAddressLine1Controller = TextEditingController();
  final TextEditingController _foreignCityController = TextEditingController();
  final TextEditingController _foreignStateController = TextEditingController();
  final TextEditingController _foreignPincodeController = TextEditingController();
  String? _selectedForeignCountry;
  
  // Indian Correspondence Address (for all users, required for NRI)
  final TextEditingController _indAddressLine1Controller = TextEditingController();
  final TextEditingController _indAddressLine2Controller = TextEditingController();
  final TextEditingController _indCityController = TextEditingController();
  final TextEditingController _indStateController = TextEditingController();
  final TextEditingController _indPincodeController = TextEditingController();
  String _selectedAddressType = '1'; // Default to Residential

  // Per-field error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _panError;
  String? _dobError;
  String? _phoneError;
  String? _emailError;
  String? _occupationError;
  String? _incomeSlabError;
  String? _tinError;
  String? _foreignAddressError;
  String? _foreignCountryError;
  String? _indAddressError;
  String? _indCityError;
  String? _indStateError;
  String? _indPincodeError;

  // GlobalKeys for scrolling to fields
  final GlobalKey _firstNameKey = GlobalKey();
  final GlobalKey _lastNameKey = GlobalKey();
  final GlobalKey _panKey = GlobalKey();
  final GlobalKey _dobKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();

  String _selectedCountryCode = '91';
  TaxStatus _selectedTaxStatus = TaxStatus.bseOptions.first;
  String _selectedPep = 'N';

  // Income Slab Options
  final List<String> _incomeSlabs = [
    'Below ₹1 Lakh',
    '₹1 Lakh - ₹5 Lakhs',
    '₹5 Lakhs - ₹10 Lakhs',
    '₹10 Lakhs - ₹25 Lakhs',
    '₹25 Lakhs - ₹1 Crore',
    'Above ₹1 Crore',
  ];

  final Map<String, String> _countryPhoneCodes = {
    'AFG': '93',
    'ALB': '355',
    'DZA': '213',
    'ASM': '1-684',
    'AND': '376',
    'AGO': '244',
    'AIA': '1-264',
    'ATA': '672',
    'ATG': '1-268',
    'ARG': '54',
    'ARM': '374',
    'ABW': '297',
    'AUS': '61',
    'AUT': '43',
    'AZE': '994',
    'BHS': '1-242',
    'BHR': '973',
    'BGD': '880',
    'BRB': '1-246',
    'BLR': '375',
    'BEL': '32',
    'BLZ': '501',
    'BEN': '229',
    'BMU': '1-441',
    'BTN': '975',
    'BOL': '591',
    'BIH': '387',
    'BWA': '267',
    'BRA': '55',
    'IOT': '246',
    'BRN': '673',
    'BGR': '359',
    'BFA': '226',
    'BDI': '257',
    'KHM': '855',
    'CMR': '237',
    'CAN': '1',
    'CPV': '238',
    'CYM': '1-345',
    'CAF': '236',
    'TCD': '235',
    'CHL': '56',
    'CHN': '86',
    'CXR': '61',
    'CCK': '61',
    'COL': '57',
    'COM': '269',
    'COG': '242',
    'COD': '243',
    'CRI': '506',
    'CIV': '225',
    'HRV': '385',
    'CUB': '53',
    'CYP': '357',
    'CZE': '420',
    'DNK': '45',
    'DJI': '253',
    'DMA': '1-767',
    'DOM': '1-809',
    'ECU': '593',
    'EGY': '20',
    'SLV': '503',
    'GNQ': '240',
    'ERI': '291',
    'EST': '372',
    'SWZ': '268',
    'ETH': '251',
    'FJI': '679',
    'FIN': '358',
    'FRA': '33',
    'GAB': '241',
    'GMB': '220',
    'GEO': '995',
    'DEU': '49',
    'GHA': '233',
    'GIB': '350',
    'GRC': '30',
    'GRL': '299',
    'GRD': '1-473',
    'GLP': '590',
    'GUM': '1-671',
    'GTM': '502',
    'GGY': '44',
    'GIN': '224',
    'GNB': '245',
    'GUY': '592',
    'HTI': '509',
    'HND': '504',
    'HKG': '852',
    'HUN': '36',
    'ISL': '354',
    'IND': '91',
    'IDN': '62',
    'IRN': '98',
    'IRQ': '964',
    'IRL': '353',
    'IMN': '44',
    'ISR': '972',
    'ITA': '39',
    'JAM': '1-876',
    'JPN': '81',
    'JEY': '44',
    'JOR': '962',
    'KAZ': '7',
    'KEN': '254',
    'KIR': '686',
    'KWT': '965',
    'KGZ': '996',
    'LAO': '856',
    'LVA': '371',
    'LBN': '961',
    'LSO': '266',
    'LBR': '231',
    'LBY': '218',
    'LIE': '423',
    'LTU': '370',
    'LUX': '352',
    'MAC': '853',
    'MDG': '261',
    'MWI': '265',
    'MYS': '60',
    'MDV': '960',
    'MLI': '223',
    'MLT': '356',
    'MHL': '692',
    'MTQ': '596',
    'MRT': '222',
    'MUS': '230',
    'MEX': '52',
    'FSM': '691',
    'MDA': '373',
    'MCO': '377',
    'MNG': '976',
    'MNE': '382',
    'MSR': '1-664',
    'MAR': '212',
    'MOZ': '258',
    'MMR': '95',
    'NAM': '264',
    'NRU': '674',
    'NPL': '977',
    'NLD': '31',
    'NZL': '64',
    'NIC': '505',
    'NER': '227',
    'NGA': '234',
    'PRK': '850',
    'MKD': '389',
    'NOR': '47',
    'OMN': '968',
    'PAK': '92',
    'PAN': '507',
    'PNG': '675',
    'PRY': '595',
    'PER': '51',
    'PHL': '63',
    'POL': '48',
    'PRT': '351',
    'QAT': '974',
    'ROU': '40',
    'RUS': '7',
    'RWA': '250',
    'SAU': '966',
    'SEN': '221',
    'SRB': '381',
    'SYC': '248',
    'SLE': '232',
    'SGP': '65',
    'SVK': '421',
    'SVN': '386',
    'ZAF': '27',
    'KOR': '82',
    'ESP': '34',
    'LKA': '94',
    'SDN': '249',
    'SUR': '597',
    'SWE': '46',
    'CHE': '41',
    'SYR': '963',
    'TWN': '886',
    'TJK': '992',
    'TZA': '255',
    'THA': '66',
    'TGO': '228',
    'TTO': '1-868',
    'TUN': '216',
    'TUR': '90',
    'TKM': '993',
    'UGA': '256',
    'UKR': '380',
    'ARE': '971',
    'GBR': '44',
    'USA': '1',
    'URY': '598',
    'UZB': '998',
    'VEN': '58',
    'VNM': '84',
    'YEM': '967',
    'ZMB': '260',
    'ZWE': '263',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _prepopulateFromInitialData();
    } else {
      _prepopulateUserData();
      _fetchProfileDetailsFromServer();
    }
    // Listen for shouldSubmit changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _submitHolderData();
      }
    });
  }

  void _prepopulateFromInitialData() {
    setState(() {
      final holder = widget.initialData!.holder;
      debugPrint(
        'HolderManagement: Prepopulating from initialData. DOB: ${holder.dob}',
      );
      _firstNameController.text = holder.firstName ?? '';
      _middleNameController.text = holder.middleName ?? '';
      _lastNameController.text = holder.lastName ?? '';
      _panController.text = holder.pan ?? '';
      if (holder.dob != null) {
        _dobController.text =
            "${holder.dob!.year}-${holder.dob!.month.toString().padLeft(2, '0')}-${holder.dob!.day.toString().padLeft(2, '0')}";
      }
      String rawPhone = holder.phone ?? '';
      if (rawPhone.startsWith('+')) {
        if (rawPhone.startsWith('+91')) {
          _selectedCountryCode = '91';
          _phoneController.text = rawPhone.substring(3);
        } else {
          // Generic handler for other international codes if needed
          _phoneController.text = rawPhone;
          _selectedCountryCode = holder.countryCode ?? '91';
        }
      } else {
        _phoneController.text = rawPhone;
        _selectedCountryCode = holder.countryCode ?? '91';
      }
      _emailController.text = holder.email ?? '';
      _selectedGender = holder.gender ?? 'M';
      _selectedPep = holder.politicallyExposedPerson ?? 'N';

      // Map tax status if possible
      try {
        if (holder.taxStatus != null) {
          _selectedTaxStatus = TaxStatus.all.firstWhere(
            (e) => e.code == holder.taxStatus,
            orElse: () => TaxStatus.bseOptions.first,
          );
        } else {
          _selectedTaxStatus = TaxStatus.bseOptions.first;
        }
      } catch (_) {
        _selectedTaxStatus = TaxStatus.bseOptions.first;
      }
    });
  }

  void _prepopulateUserData() {
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      final user = userController.userData;
      if (user != null) {
        setState(() {
          debugPrint(
            'HolderManagement: Prepopulating from user data. DOB: ${user.dob}',
          );
          // Name Splitting Logic
          if (_firstNameController.text.isEmpty && user.firstname != null) {
            final parts = user.firstname!.trim().split(' ');
            if (parts.isNotEmpty) {
              _firstNameController.text = parts[0];

              if (parts.length > 1) {
                // Remaining parts go to middle name initially
                _middleNameController.text = parts.sublist(1).join(' ');
              }
            }
          }

          if (_lastNameController.text.isEmpty && user.lastname != null) {
            final parts = user.lastname!.trim().split(' ');
            if (parts.isNotEmpty) {
              // If User.LastName has multiple parts, first part(s) append to Middle Name, last part is Last Name
              if (parts.length > 1) {
                final lastNameInitialParts = parts
                    .sublist(0, parts.length - 1)
                    .join(' ');
                if (_middleNameController.text.isNotEmpty) {
                  _middleNameController.text += " $lastNameInitialParts";
                } else {
                  _middleNameController.text = lastNameInitialParts;
                }
                _lastNameController.text = parts.last;
              } else {
                _lastNameController.text = parts[0];
              }
            }
          }
          if (_emailController.text.isEmpty && user.email != null) {
            _emailController.text = user.email!;
          }
          if (_phoneController.text.isEmpty && user.phonenumber != null) {
            String userPhone = user.phonenumber!;
            if (userPhone.startsWith('+91')) {
              _selectedCountryCode = '91';
              _phoneController.text = userPhone.substring(3);
            } else if (userPhone.startsWith('91') && userPhone.length == 12) {
              _selectedCountryCode = '91';
              _phoneController.text = userPhone.substring(2);
            } else {
              _phoneController.text = userPhone;
            }
          }
          if (user.pannumber != null && user.pannumber!.isNotEmpty) {
            _panController.text = user.pannumber!;
          }

          if (_dobController.text.isEmpty && user.dob != null) {
            final dob = user.dob!;
            _dobController.text =
                "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
          }
          // Gender might need mapping
          if (user.gender != null) {
            if (user.gender == 'Male')
              _selectedGender = 'M';
            else if (user.gender == 'Female')
              _selectedGender = 'F';
            else
              _selectedGender = 'O'; // Or whatever logic for 'Others'
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(HolderManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle initialData changes (e.g., when parent finishes async fetch)
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null) {
      _prepopulateFromInitialData();
    }
    // Trigger submission when shouldSubmit changes from false to true
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitHolderData();
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _panController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameNode.dispose();
    _lastNameNode.dispose();
    _middleNameNode.dispose();
    _panNode.dispose();
    _dobNode.dispose();
    _phoneNode.dispose();
    _emailNode.dispose();
    super.dispose();
  }

  bool get _isPrefilled => widget.initialData != null;

  User? get _systemUser =>
      Get.isRegistered<UserController>()
          ? Get.find<UserController>().userData
          : null;

  bool get _isPanPrefilled =>
      _isPrefilled || (_systemUser?.pannumber?.isNotEmpty ?? false);
  bool get _isPhonePrefilled =>
      _isPrefilled || (_systemUser?.phonenumber?.isNotEmpty ?? false);
  bool get _isEmailPrefilled =>
      _isPrefilled || (_systemUser?.email?.isNotEmpty ?? false);
  bool get _isDobPrefilled => _isPrefilled || (_systemUser?.dob != null);

  // Validate form fields
  bool _validateForm({bool autoScroll = true}) {
    String? firstNameError;
    String? lastNameError;
    String? panError;
    String? dobError;
    String? phoneError;
    String? emailError;

    bool isValid = true;
    GlobalKey? firstErrorKey;

    if (_firstNameController.text.trim().isEmpty) {
      firstNameError = 'First Name is required';
      firstErrorKey ??= _firstNameKey;
      isValid = false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      lastNameError = 'Last Name is required';
      firstErrorKey ??= _lastNameKey;
      isValid = false;
    }
    final pan = _panController.text.trim();
    if (pan.isEmpty) {
      panError = 'PAN is required';
      firstErrorKey ??= _panKey;
      isValid = false;
    } else {
      final panErr = AppValidators.validateNomineePan(pan);
      if (panErr != null) {
        panError = panErr;
        firstErrorKey ??= _panKey;
        isValid = false;
      }
    }

    if (_dobController.text.trim().isEmpty) {
      dobError = 'Date of Birth is required';
      firstErrorKey ??= _dobKey;
      isValid = false;
    } else {
      final dob = _dobController.text.trim();
      final date = DateTime.tryParse(dob);
      if (date != null) {
        final today = DateTime.now();
        int age = today.year - date.year;
        if (today.month < date.month ||
            (today.month == date.month && today.day < date.day)) {
          age--;
        }
        if (age < 18) {
          dobError = 'Holder must be 18 years or older';
          firstErrorKey ??= _dobKey;
          isValid = false;
        }
      }
    }
    final phone = _phoneController.text.trim();
    final cleanPhone = AppValidators.cleanPhoneNumber(phone);
    if (phone.isEmpty) {
      phoneError = 'Phone Number is required';
      firstErrorKey ??= _phoneKey;
      isValid = false;
    } else if (cleanPhone.length != 10) {
      phoneError = 'Phone Number must be 10 digits';
      firstErrorKey ??= _phoneKey;
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      emailError = 'Email is required';
      firstErrorKey ??= _emailKey;
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError = 'Invalid Email format';
      firstErrorKey ??= _emailKey;
      isValid = false;
    }

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _panError = panError;
      _dobError = dobError;
      _phoneError = phoneError;
      _emailError = emailError;
    });

    // Scroll to first error field
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

  // Convert TaxStatus to investor_residency format
  String _getInvestorResidency(TaxStatus taxStatus) {
    // Map BSE tax status codes to Profile API investor_residency values
    switch (taxStatus.code) {
      case '01': // Individual
        return 'Resident';
      case '21': // NRE
        return 'NRI-NRE';
      case '24': // NRO
        return 'NRI-NRO';
      default:
        // Default to Resident for other codes
        return 'Resident';
    }
  }

  // Submit holder data to service
  Future<void> _submitHolderData() async {
    AppLogger.info(
      'Starting personal information save',
      tag: 'BSE_Personal_Information',
    );
    
    if (!_validateForm()) {
      widget.onError?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get existing profile to pull address data
      final existingProfile = await ProfileService().getProfileDetails();
      final uccAddress = existingProfile?.data?.uccProfile?['address'];
      
      AppLogger.info(
        'Existing address from ucc_profile: ${uccAddress.toString()}',
        tag: 'BSE_Personal_Information',
      );
      
      // Build extended_profile with CORRECT field names from profile.md
      final extendedProfile = ProfileService().buildExtendedProfile(
        // Personal Information from form
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender, // 'M', 'F', 'O'
        pep: _selectedPep, // 'N', 'Y', 'R'
        
        // Professional Information
        occupation: _occupationController.text.trim().isNotEmpty 
            ? _occupationController.text.trim() 
            : null,
        incomeSlab: _incomeSlabController.text.trim().isNotEmpty 
            ? _incomeSlabController.text.trim() 
            : null,
        
        // NRI-specific fields (only if NRI)
        primaryTaxId: _isNRI && _tinController.text.trim().isNotEmpty
            ? _tinController.text.trim()
            : null,
        country: _isNRI && _selectedForeignCountry != null
            ? _selectedForeignCountry
            : (uccAddress?['country'] ?? 'IND'),
        
        // For NRI: Foreign address goes to primary address fields
        // For Resident: Indian address goes to primary address fields
        addressLine1: _isNRI && _foreignAddressLine1Controller.text.trim().isNotEmpty
            ? _foreignAddressLine1Controller.text.trim()
            : (_indAddressLine1Controller.text.trim().isNotEmpty
                ? _indAddressLine1Controller.text.trim()
                : (uccAddress?['address1'] ?? '')),
        addressLine2: _isNRI
            ? (_foreignAddressLine1Controller.text.trim().isNotEmpty
                ? ''  // No line 2 for foreign address in current implementation
                : (uccAddress?['address2'] ?? ''))
            : (_indAddressLine2Controller.text.trim().isNotEmpty
                ? _indAddressLine2Controller.text.trim()
                : (uccAddress?['address2'] ?? '')),
        city: _isNRI && _foreignCityController.text.trim().isNotEmpty
            ? _foreignCityController.text.trim()
            : (_indCityController.text.trim().isNotEmpty
                ? _indCityController.text.trim()
                : (uccAddress?['city'] ?? '')),
        state: _isNRI && _foreignStateController.text.trim().isNotEmpty
            ? _foreignStateController.text.trim()
            : (_indStateController.text.trim().isNotEmpty
                ? _indStateController.text.trim()
                : (uccAddress?['state'] ?? '')),
        pincode: _isNRI && _foreignPincodeController.text.trim().isNotEmpty
            ? _foreignPincodeController.text.trim()
            : (_indPincodeController.text.trim().isNotEmpty
                ? _indPincodeController.text.trim()
                : (uccAddress?['pincode'] ?? '')),
        
        // NRI Indian Correspondence Address (only for NRI users)
        indAddressLine1: _isNRI && _indAddressLine1Controller.text.trim().isNotEmpty
            ? _indAddressLine1Controller.text.trim()
            : null,
        indCity: _isNRI && _indCityController.text.trim().isNotEmpty
            ? _indCityController.text.trim()
            : null,
        indState: _isNRI && _indStateController.text.trim().isNotEmpty
            ? _indStateController.text.trim()
            : null,
        indPincode: _isNRI && _indPincodeController.text.trim().isNotEmpty
            ? _indPincodeController.text.trim()
            : null,
        
        // Signature will be added in Signature Management screen
        // Don't include primarySignature here
      );
      
      AppLogger.info(
        'Extended profile keys: ${extendedProfile.keys.toList()}',
        tag: 'BSE_Personal_Information',
      );
      
      final investorResidency = _getInvestorResidency(_selectedTaxStatus);
      
      AppLogger.info(
        'Tax Status: ${_selectedTaxStatus.status} (code: ${_selectedTaxStatus.code}) → Investor Residency: $investorResidency',
        tag: 'BSE_Personal_Information',
      );
      
      AppLogger.info(
        'PAN: ${_panController.text.trim()}, DOB: ${_dobController.text.trim()}',
        tag: 'BSE_Personal_Information',
      );

      // Call Profile API with correct top-level fields
      final response = await ProfileService().updateProfileDetails(
        extendedProfile: extendedProfile,
        investorResidency: investorResidency, // 'Resident', 'NRI-NRE', 'NRI-NRO'
        phoneNumber: _phoneController.text.trim(), // Just digits, no + prefix
        dob: _dobController.text.trim(), // YYYY-MM-DD
        panNumber: _panController.text.trim().toUpperCase(),
        name: '${_firstNameController.text} ${_lastNameController.text}',
        submitProfile: false, // Don't submit until signature is added
      );

      if (response != null && response.success) {
        AppLogger.info(
          'Profile updated successfully. Status: ${response.onboardingStatus}',
          tag: 'BSE_Personal_Information',
        );
        
        AppLogger.info(
          'Profile complete: ${response.data?.profileComplete}, Issues: ${response.data?.profileIssues}',
          tag: 'BSE_Personal_Information',
        );
        
        // Show success message
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !Get.isSnackbarOpen) {
              Get.snackbar(
                'Success',
                'Personal information saved successfully!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          });
        }

        // Navigate to next screen after successful submission
        if (widget.onNext != null) {
          widget.onNext!();
        }
      } else {
        AppLogger.error(
          'Profile update failed: ${response?.message}',
          tag: 'BSE_Personal_Information',
        );
        
        final issues = response?.data?.profileIssues ?? [];
        if (issues.isNotEmpty) {
          AppLogger.info(
            'Profile validation issues: ${issues.join(", ")}',
            tag: 'BSE_Personal_Information',
          );
        }
        
        widget.onError?.call();
        
        // Show error message
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !Get.isSnackbarOpen) {
              Get.snackbar(
                'Error',
                BseErrorTranslator.getFriendlyErrorMessage(
                  response?.message ?? 'Failed to save personal information',
                ),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error saving personal information',
        error: e,
        tag: 'BSE_Personal_Information',
      );
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
                    : 'An unexpected error occurred: $e',
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

  // Check if selected tax status is NRI
  bool get _isNRI => _selectedTaxStatus.code == '21' || _selectedTaxStatus.code == '24';

  // Income Slab Helper Methods
  String _getIncomeSlabCode(String incomeSlab) {
    if (incomeSlab == 'Below ₹1 Lakh') return '31';
    if (incomeSlab == '₹1 Lakh - ₹5 Lakhs') return '32';
    if (incomeSlab == '₹5 Lakhs - ₹10 Lakhs') return '33';
    if (incomeSlab == '₹10 Lakhs - ₹25 Lakhs') return '34';
    if (incomeSlab == '₹25 Lakhs - ₹1 Crore') return '35';
    if (incomeSlab == 'Above ₹1 Crore') return '36';
    return '31';
  }

  Future<void> _fetchProfileDetailsFromServer() async {
    setState(() => _isLoading = true);
    try {
      AppLogger.info(
        'Fetching profile details from server',
        tag: 'Personal_Information',
      );
      
      final response = await ProfileService().getProfileDetails();
      
      AppLogger.info(
        'Profile API Response - Success: ${response?.success}, Has Data: ${response?.data != null}',
        tag: 'Personal_Information',
      );
      
      if (response != null && response.success && response.data != null) {
        _serverProfileData = response.data;
        final ucc = _serverProfileData!.uccProfile;
        
        AppLogger.info(
          'UCC Profile Data: ${ucc.toString()}',
          tag: 'Personal_Information',
        );
        
        // FIRST: Set tax status from investor_residency (top-level field)
        final investorResidency = response.data!.investorResidency;
        AppLogger.info(
          'Investor Residency from API: $investorResidency',
          tag: 'Personal_Information',
        );
        
        if (investorResidency != null) {
          if (investorResidency == 'NRI-NRE') {
            _selectedTaxStatus = TaxStatus.all.firstWhere(
              (e) => e.code == '21',
              orElse: () => _selectedTaxStatus,
            );
          } else if (investorResidency == 'NRI-NRO') {
            _selectedTaxStatus = TaxStatus.all.firstWhere(
              (e) => e.code == '24',
              orElse: () => _selectedTaxStatus,
            );
          } else if (investorResidency == 'Resident') {
            _selectedTaxStatus = TaxStatus.all.firstWhere(
              (e) => e.code == '01',
              orElse: () => _selectedTaxStatus,
            );
          }
          
          AppLogger.info(
            'Tax Status set to: ${_selectedTaxStatus.status} (${_selectedTaxStatus.code})',
            tag: 'Personal_Information',
          );
        }
        
        if (ucc != null && ucc.isNotEmpty) {
          AppLogger.info(
            'UCC Profile Keys: ${ucc.keys.toList()}',
            tag: 'Personal_Information',
          );
          
          setState(() {
            if (ucc['first_name'] != null) {
              _firstNameController.text = ucc['first_name'];
            }
            if (ucc['middle_name'] != null) {
              _middleNameController.text = ucc['middle_name'];
            }
            if (ucc['last_name'] != null) {
              _lastNameController.text = ucc['last_name'];
            }
            if (ucc['pan'] != null) _panController.text = ucc['pan'];
            if (ucc['dob'] != null) _dobController.text = ucc['dob'];
            if (ucc['gender'] != null) _selectedGender = ucc['gender'];
            if (ucc['email'] != null) _emailController.text = ucc['email'];
            if (ucc['politically_exposed_person'] != null) {
              _selectedPep = ucc['politically_exposed_person'];
            }
            
            // Map address fields from ucc_profile
            final address = ucc['address'];
            final isNRI = _selectedTaxStatus.code == '21' || _selectedTaxStatus.code == '24';
            
            AppLogger.info(
              'Tax Status: ${_selectedTaxStatus.status} (${_selectedTaxStatus.code}), Is NRI: $isNRI',
              tag: 'Personal_Information',
            );
            
            AppLogger.info(
              'Address Data: ${address.toString()}',
              tag: 'Personal_Information',
            );
            
            if (address != null && address is Map) {
              // For Resident: address goes to Indian address fields
              // For NRI: address is foreign, so don't populate Indian fields here
              if (!isNRI) {
                if (address['address1'] != null) {
                  _indAddressLine1Controller.text = address['address1'];
                }
                if (address['address2'] != null) {
                  _indAddressLine2Controller.text = address['address2'];
                }
                if (address['city'] != null) {
                  _indCityController.text = address['city'];
                }
                if (address['state'] != null) {
                  _indStateController.text = address['state'];
                }
                if (address['pincode'] != null) {
                  _indPincodeController.text = address['pincode'];
                }
                if (address['address_type'] != null) {
                  _selectedAddressType = address['address_type'].toString();
                }
              }
            }
            
            // Map occupation and income from extended_profile
            if (ucc['primary_occupation'] != null) {
              _occupationController.text = ucc['primary_occupation'];
            }
            if (ucc['primary_income_slab'] != null) {
              _incomeSlabController.text = ucc['primary_income_slab'];
              _selectedIncomeSlab = _getIncomeSlabDisplay(ucc['primary_income_slab']);
            }
            
            // Map NRI fields if applicable
            if (ucc['primary_tax_id'] != null) {
              _tinController.text = ucc['primary_tax_id'];
            }
            
            // Map foreign address fields for NRI
            if (ucc['country'] != null && ucc['country'] != 'IND') {
              _selectedForeignCountry = ucc['country'];
              
              AppLogger.info(
                'Foreign Country: ${ucc['country']}, TIN: ${ucc['primary_tax_id']}',
                tag: 'Personal_Information',
              );
              
              // Foreign address is stored in the main address fields when tax status is NRI
              if (_selectedTaxStatus.code == '21' || _selectedTaxStatus.code == '24') {
                AppLogger.info(
                  'Mapping foreign address for NRI user',
                  tag: 'Personal_Information',
                );
                // Copy address to foreign address fields
                if (address != null && address is Map) {
                  if (address['address1'] != null) {
                    _foreignAddressLine1Controller.text = address['address1'];
                  }
                  if (address['city'] != null) {
                    _foreignCityController.text = address['city'];
                  }
                  if (address['state'] != null) {
                    _foreignStateController.text = address['state'];
                  }
                  if (address['pincode'] != null) {
                    _foreignPincodeController.text = address['pincode'];
                  }
                }
                
                // Map Indian correspondence address from ind_* fields
                AppLogger.info(
                  'Indian correspondence address - Line1: ${ucc['ind_address_line_1']}, City: ${ucc['ind_city']}, State: ${ucc['ind_state']}, Pincode: ${ucc['ind_pincode']}',
                  tag: 'Personal_Information',
                );
                
                if (ucc['ind_address_line_1'] != null) {
                  _indAddressLine1Controller.text = ucc['ind_address_line_1'];
                }
                if (ucc['ind_city'] != null) {
                  _indCityController.text = ucc['ind_city'];
                }
                if (ucc['ind_state'] != null) {
                  _indStateController.text = ucc['ind_state'];
                }
                if (ucc['ind_pincode'] != null) {
                  _indPincodeController.text = ucc['ind_pincode'];
                }
              }
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching V1 profile details: $e', tag: 'Personal_Information');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Helper to convert income slab code to display text
  String _getIncomeSlabDisplay(String code) {
    if (code == '31') return 'Below ₹1 Lakh';
    if (code == '32') return '₹1 Lakh - ₹5 Lakhs';
    if (code == '33') return '₹5 Lakhs - ₹10 Lakhs';
    if (code == '34') return '₹10 Lakhs - ₹25 Lakhs';
    if (code == '35') return '₹25 Lakhs - ₹1 Crore';
    if (code == '36') return 'Above ₹1 Crore';
    return 'Below ₹1 Lakh';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Get.back();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Holder Information',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 8),
          AppText(
            'Please provide your personal information for BSE account creation.',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.medium,
          ),

          const SizedBox(height: 32),
          AppText(
            'Personal Information',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            customColor: Colors.white,
          ),
          const SizedBox(height: 12),

          // First Name Field
          Container(
            key: _firstNameKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DarkInputField(
                  key: const ValueKey('holder_first_name'),
                  focusNode: _firstNameNode,
                  label: 'First Name',
                  controller: _firstNameController,
                  hintText: 'Enter your first name',
                  readOnly: false,
                  onChanged: (value) => _validateForm(autoScroll: false),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedErrorMessage(errorMessage: _firstNameError),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Middle Name Field
          DarkInputField(
            key: const ValueKey('holder_middle_name'),
            focusNode: _middleNameNode,
            label: 'Middle Name (Optional)',
            controller: _middleNameController,
            readOnly: false,
            hintText: 'Enter your middle name',
          ),
          const SizedBox(height: 16),

          // Last Name Field
          Container(
            key: _lastNameKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DarkInputField(
                  key: const ValueKey('holder_last_name'),
                  focusNode: _lastNameNode,
                  label: 'Last Name',
                  controller: _lastNameController,
                  hintText: 'Enter your last name',
                  readOnly: false,
                  onChanged: (value) => _validateForm(autoScroll: false),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedErrorMessage(errorMessage: _lastNameError),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Note: PAN and DOB are now collected in PAN Verification screen
          // Controllers remain for API submission but UI fields are removed

          // Phone Number Field
          Container(
            key: _phoneKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CountryDropdown(
                        label: 'Code',
                        selectedCountryCode: 'IND',
                        phoneCodeMap: _countryPhoneCodes,
                        enabled: !_isPhonePrefilled,
                        onCountrySelected: (country) {
                          setState(() {
                            _selectedCountryCode =
                                _countryPhoneCodes[country.code] ?? '91';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: DarkInputField(
                        key: const ValueKey('holder_phone'),
                        focusNode: _phoneNode,
                        label: 'Phone Number',
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                        readOnly: _isPhonePrefilled,
                        onChanged: (value) => _validateForm(autoScroll: false),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedErrorMessage(errorMessage: _phoneError),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Email Field
          Container(
            key: _emailKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DarkInputField(
                  key: const ValueKey('holder_email'),
                  focusNode: _emailNode,
                  label: 'Email Address',
                  controller: _emailController,
                  hintText: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEmailPrefilled,
                  onChanged: (value) => _validateForm(autoScroll: false),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedErrorMessage(errorMessage: _emailError),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Gender Selection
          AppDropdown(
            labelText: 'Gender',
            value:
                _selectedGender == 'M'
                    ? 'Male'
                    : _selectedGender == 'F'
                    ? 'Female'
                    : _selectedGender == 'O'
                    ? 'Others'
                    : 'Select Gender',
            items: const ['Male', 'Female', 'Others'],
            enabled: true,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  if (value == 'Male') {
                    _selectedGender = 'M';
                  } else if (value == 'Female') {
                    _selectedGender = 'F';
                  } else if (value == 'Others') {
                    _selectedGender = 'O';
                  }
                });
              }
            },
          ),

          const SizedBox(height: 24),

          // PEP Selection
          const AppText(
            'Politically Exposed Person',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
          ),
          const SizedBox(height: 12),
          AppDropdown(
            items: const ['No', 'Yes', 'Related'],
            enabled: true,
            value:
                _selectedPep == 'N'
                    ? 'No'
                    : _selectedPep == 'Y'
                    ? 'Yes'
                    : _selectedPep == 'R'
                    ? 'Related'
                    : 'No',
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  if (value == 'No') {
                    _selectedPep = 'N';
                  } else if (value == 'Yes') {
                    _selectedPep = 'Y';
                  } else if (value == 'Related') {
                    _selectedPep = 'R';
                  }
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Occupation Dropdown
          OccupationDropdown(
            selectedOccupationId:
                _occupationController.text.isNotEmpty
                    ? _occupationController.text
                    : null,
            enabled: true,
            onOccupationSelected: (occupation) {
              setState(() {
                _occupationController.text = occupation.id;
              });
            },
          ),
          if (_occupationError != null) ...[
            const SizedBox(height: 6),
            AnimatedErrorMessage(errorMessage: _occupationError!),
          ],
          const SizedBox(height: 24),

          // Annual Income Slab
          AppDropdown(
            labelText: 'Annual Income',
            enabled: true,
            value: _selectedIncomeSlab,
            items: _incomeSlabs,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedIncomeSlab = value;
                  _incomeSlabController.text = _getIncomeSlabCode(value);
                });
              }
            },
          ),
          if (_incomeSlabError != null) ...[
            const SizedBox(height: 6),
            AnimatedErrorMessage(errorMessage: _incomeSlabError!),
          ],
          const SizedBox(height: 24),

          // Note: Indian Address is now collected in PAN Verification screen
          // Controllers remain for API submission but UI fields are removed

          // Tax Status Dropdown
          AppDropdown(
            labelText: 'Tax Status',
            enabled: true,
            value: _selectedTaxStatus.status,
            items: TaxStatus.bseOptions.map((e) => e.status).toList(),
            subtitles:
                TaxStatus.bseOptions.map((e) => e.bseDescription).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTaxStatus = TaxStatus.bseOptions.firstWhere(
                    (e) => e.status == value,
                  );
                });
              }
            },
          ),

          const SizedBox(height: 24),

          // NRI-specific fields (show only for NRE/NRO)
          if (_isNRI) ...[
            // Foreign TIN
            DarkInputField(
              controller: _tinController,
              label: 'Foreign Tax ID (TIN)',
              hintText: 'Enter your foreign tax identification number',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {},
            ),
            if (_tinError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedErrorMessage(errorMessage: _tinError!),
              ),
            const SizedBox(height: 24),

            // Foreign Country
            CountryDropdown(
              label: 'Foreign Country',
              selectedCountryCode: _selectedForeignCountry,
              onCountrySelected: (country) {
                setState(() {
                  _selectedForeignCountry = country.code;
                });
              },
            ),
            if (_foreignCountryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedErrorMessage(errorMessage: _foreignCountryError!),
              ),
            const SizedBox(height: 24),

            // Foreign Address Line 1
            DarkInputField(
              controller: _foreignAddressLine1Controller,
              label: 'Foreign Address',
              hintText: 'Enter your foreign address',
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {},
            ),
            if (_foreignAddressError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedErrorMessage(errorMessage: _foreignAddressError!),
              ),
            const SizedBox(height: 24),

            // Foreign City
            DarkInputField(
              controller: _foreignCityController,
              label: 'Foreign City',
              hintText: 'Enter city',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),

            // Foreign State
            DarkInputField(
              controller: _foreignStateController,
              label: 'Foreign State/Province',
              hintText: 'Enter state or province',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),

            // Foreign Pincode
            DarkInputField(
              controller: _foreignPincodeController,
              label: 'Foreign Postal Code',
              hintText: 'Enter postal code',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
