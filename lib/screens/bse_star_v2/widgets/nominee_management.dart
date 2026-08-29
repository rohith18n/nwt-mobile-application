import 'package:nwt_app/utils/bse_error_translator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/nominee_management.dart';
import 'package:nwt_app/screens/bse_star/widgets/dynamic_relation_selector.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/services/bse_star/nominee_relation.dart';
import 'package:nwt_app/services/secure_storage.dart';

class NomineeData {
  final String firstName;
  final String lastName;
  final String relation;
  final String dob;
  final String nomineePan;
  final String nomineeContactNumber;
  final String nomineeEmail;
  final String addressLine1;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  int nomineePercent;
  // Guardian fields for minors
  String? guardianName;
  String? guardianRelation;
  String? guardianPan;
  String? guardianDob;

  final String? id; // Server ID for deletion

  NomineeData({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.relation,
    required this.dob,
    required this.nomineePan,
    required this.nomineeContactNumber,
    required this.nomineeEmail,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.nomineePercent,
    this.guardianName,
    this.guardianRelation,
    this.guardianPan,
    this.guardianDob,
  });
  
  // Helper getter for display purposes
  String get fullName => '$firstName $lastName'.trim();

  bool get isMinor {
    if (dob.isEmpty) return false;
    try {
      final birthDate = DateTime.tryParse(dob);
      if (birthDate == null) return false;
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age < 18;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      'first_name': firstName,
      'last_name': lastName,
      'relation': relation,
      'dob': dob,
      'percent': nomineePercent, // UCC API uses 'percent', not 'nominee_percent'
      'pan': nomineePan, // UCC API uses 'pan', not 'nominee_pan'
      'mobile': nomineeContactNumber, // UCC API uses 'mobile'
      'email': nomineeEmail,
      'address_line1': addressLine1,
      'city': city,
      'state': state,
      'country': country,
      'pincode': postalCode, // UCC API uses 'pincode'
    };
    if (isMinor && guardianName != null && guardianName!.isNotEmpty) {
      map['guardian_name'] = guardianName!;
    }
    if (isMinor && guardianRelation != null && guardianRelation!.isNotEmpty) {
      map['guardian_relation'] = guardianRelation!;
    }
    if (isMinor && guardianPan != null && guardianPan!.isNotEmpty) {
      map['guardian_pan'] = guardianPan!;
    }
    if (isMinor && guardianDob != null && guardianDob!.isNotEmpty) {
      map['guardian_dob'] = guardianDob!;
    }
    return map;
  }
}

class NomineeManagement extends StatefulWidget {
  final VoidCallback? onNext; // Callback to navigate to next screen
  final bool shouldSubmit; // Flag to trigger submission
  final List<Nominee>? initialData; // Data for pre-filling
  final Address? primaryHolderAddress; // Address of the primary holder
  final VoidCallback? onError; // Callback to notify of errors

  const NomineeManagement({
    super.key,
    this.onNext,
    this.shouldSubmit = false,
    this.initialData,
    this.primaryHolderAddress,
    this.onError,
  });

  @override
  State<NomineeManagement> createState() => _NomineeManagementState();
}

class _NomineeManagementState extends State<NomineeManagement> {
  final List<NomineeData> _nominees = [];
  final Set<int> _manuallyModifiedIndices = {};
  final List<TextEditingController> _firstNameControllers = [];
  final List<TextEditingController> _lastNameControllers = [];
  final List<TextEditingController> _relationControllers = [];
  final List<TextEditingController> _dobControllers = [];
  final List<TextEditingController> _panControllers = [];
  final List<TextEditingController> _contactControllers = [];
  final List<TextEditingController> _emailControllers = [];
  final List<TextEditingController> _address1Controllers = [];
  final List<TextEditingController> _cityControllers = [];
  final List<TextEditingController> _stateControllers = [];
  final List<TextEditingController> _countryControllers = [];
  final List<TextEditingController> _postalCodeControllers = [];
  final List<FocusNode> _firstNameNodes = [];
  final List<FocusNode> _lastNameNodes = [];
  final List<FocusNode> _panNodes = [];
  final List<FocusNode> _contactNodes = [];
  final List<FocusNode> _emailNodes = [];
  final List<FocusNode> _address1Nodes = [];
  final List<FocusNode> _cityNodes = [];
  final List<FocusNode> _stateNodes = [];
  final List<FocusNode> _postalCodeNodes = [];
  final List<FocusNode> _dobNodes = [];
  final List<FocusNode> _guardianNameNodes = [];
  final List<FocusNode> _guardianPanNodes = [];
  final List<FocusNode> _guardianDobNodes = [];
  final List<TextEditingController> _percentControllers = [];
  // Guardian controllers (for minors)
  final List<TextEditingController> _guardianNameControllers = [];
  final List<TextEditingController> _guardianRelationControllers = [];
  final List<TextEditingController> _guardianPanControllers = [];
  final List<TextEditingController> _guardianDobControllers = [];

  // State variables for relation names and IDs
  final List<String> _selectedRelationNames = [];
  final List<String> _selectedRelationIds = [];
  final List<String> _selectedGuardianRelationNames = [];
  final List<String> _selectedGuardianRelationIds = [];

  // State for country selection
  final List<Country?> _selectedCountries = [];

  // State for "Same as primary holder" checkbox
  final List<bool> _isSameAsPrimary = [];

  // Error states for in-line validation
  final List<String?> _firstNameErrors = [];
  final List<String?> _lastNameErrors = [];
  final List<String?> _relationErrors = [];
  final List<String?> _dobErrors = [];
  final List<String?> _panErrors = [];
  final List<String?> _contactErrors = [];
  final List<String?> _emailErrors = [];
  final List<String?> _address1Errors = [];
  final List<String?> _cityErrors = [];
  final List<String?> _stateErrors = [];
  final List<String?> _postalCodeErrors = [];
  final List<String?> _percentErrors = [];

  // Guardian error states
  final List<String?> _guardianNameErrors = [];
  final List<String?> _guardianRelationErrors = [];
  final List<String?> _guardianPanErrors = [];
  final List<String?> _guardianDobErrors = [];

  // Track which nominee is currently being edited (null means all collapsed or focus on summary)
  int? _editingIndex;

  // State variables
  bool _isLoading = false;
  bool _isNomineeOpted = true;

  @override
  void initState() {
    super.initState();
    _loadNomineeData();

    // Listen for shouldSubmit changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _submitNomineeData();
      }
    });
  }

  /// Load nominee data from SecureStorage or initialData
  Future<void> _loadNomineeData() async {
    // First, try to load from SecureStorage (user may have saved data previously)
    final hasNomineesStr = await SecureStorage.read('has_nominees');
    final nomineeDataStr = await SecureStorage.read('nominee_data');
    
    if (hasNomineesStr == 'false') {
      // User opted out previously
      setState(() {
        _isNomineeOpted = false;
      });
      AppLogger.info('Loaded nominee opt-out from SecureStorage', tag: 'NomineeManagement');
      return;
    }
    
    if (nomineeDataStr != null && nomineeDataStr.isNotEmpty) {
      try {
        final nomineeData = json.decode(nomineeDataStr) as Map<String, dynamic>;
        final nominees = nomineeData['nominees'] as List<dynamic>?;
        
        if (nominees != null && nominees.isNotEmpty) {
          AppLogger.info('Loading ${nominees.length} nominees from SecureStorage', tag: 'NomineeManagement');
          await _prepopulateFromSecureStorage(nominees);
          return;
        }
      } catch (e) {
        AppLogger.error('Error loading nominees from SecureStorage: $e', tag: 'NomineeManagement');
      }
    }
    
    // Fallback to initialData from API
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    } else {
      // Initialize with one empty nominee
      _addNewNominee();
    }
  }

  /// Prepopulate from SecureStorage data
  Future<void> _prepopulateFromSecureStorage(List<dynamic> nominees) async {
    // Fetch relations list for mapping names
    final relations = await BseNomineeRelationService.getNomineeRelationsList();

    if (!mounted) return;

    setState(() {
      _nominees.clear();
      _firstNameControllers.clear();
      _lastNameControllers.clear();
      _relationControllers.clear();
      _dobControllers.clear();
      _panControllers.clear();
      _contactControllers.clear();
      _emailControllers.clear();
      _address1Controllers.clear();
      _cityControllers.clear();
      _stateControllers.clear();
      _countryControllers.clear();
      _postalCodeControllers.clear();
      _percentControllers.clear();
      _selectedRelationNames.clear();
      _selectedRelationIds.clear();
      _selectedCountries.clear();
      
      for (final nomineeData in nominees) {
        final firstName = nomineeData['first_name'] ?? '';
        final lastName = nomineeData['last_name'] ?? '';
        final dob = nomineeData['dob'] ?? '';
        final percent = nomineeData['percent'] ?? 0;
        final relationId = nomineeData['relation']?.toString() ?? '';
        
        // Map relation ID to name
        String relationName = '';
        if (relations != null && relationId.isNotEmpty) {
          try {
            final match = relations.firstWhere(
              (r) => r.id == relationId || int.tryParse(r.id) == int.tryParse(relationId),
            );
            relationName = match.name;
          } catch (_) {}
        }
        
        final nominee = NomineeData(
          firstName: firstName,
          lastName: lastName,
          relation: relationId,
          dob: dob,
          nomineePan: nomineeData['pan'] ?? '',
          nomineeContactNumber: nomineeData['mobile'] ?? '',
          nomineeEmail: nomineeData['email'] ?? '',
          addressLine1: nomineeData['address_line1'] ?? '',
          city: nomineeData['city'] ?? '',
          state: nomineeData['state'] ?? '',
          country: nomineeData['country'] ?? 'IND',
          postalCode: nomineeData['pincode'] ?? '',
          nomineePercent: percent,
        );
        
        _nominees.add(nominee);
        _firstNameControllers.add(TextEditingController(text: firstName));
        _lastNameControllers.add(TextEditingController(text: lastName));
        _relationControllers.add(TextEditingController(text: relationId));
        _dobControllers.add(TextEditingController(text: dob));
        _panControllers.add(TextEditingController(text: nomineeData['pan'] ?? ''));
        _contactControllers.add(TextEditingController(text: nomineeData['mobile'] ?? ''));
        _emailControllers.add(TextEditingController(text: nomineeData['email'] ?? ''));
        _address1Controllers.add(TextEditingController(text: nomineeData['address_line1'] ?? ''));
        _cityControllers.add(TextEditingController(text: nomineeData['city'] ?? ''));
        _stateControllers.add(TextEditingController(text: nomineeData['state'] ?? ''));
        _countryControllers.add(TextEditingController(text: nomineeData['country'] ?? 'IND'));
        _postalCodeControllers.add(TextEditingController(text: nomineeData['pincode'] ?? ''));
        _percentControllers.add(TextEditingController(text: percent.toString()));
        
        _selectedRelationNames.add(relationName);
        _selectedRelationIds.add(relationId);
        _selectedCountries.add(Country(name: '', code: nomineeData['country'] ?? 'IND'));
        
        // Initialize errors and focus nodes
        _firstNameErrors.add(null);
        _lastNameErrors.add(null);
        _relationErrors.add(null);
        _dobErrors.add(null);
        _panErrors.add(null);
        _contactErrors.add(null);
        _emailErrors.add(null);
        _address1Errors.add(null);
        _cityErrors.add(null);
        _stateErrors.add(null);
        _postalCodeErrors.add(null);
        _percentErrors.add(null);
        _isSameAsPrimary.add(false);
        
        _firstNameNodes.add(FocusNode());
        _lastNameNodes.add(FocusNode());
        _dobNodes.add(FocusNode());
        _panNodes.add(FocusNode());
        _contactNodes.add(FocusNode());
        _emailNodes.add(FocusNode());
        _address1Nodes.add(FocusNode());
        _cityNodes.add(FocusNode());
        _stateNodes.add(FocusNode());
        _postalCodeNodes.add(FocusNode());
        _guardianNameNodes.add(FocusNode());
        _guardianPanNodes.add(FocusNode());
        _guardianDobNodes.add(FocusNode());
      }
    });
    
    AppLogger.info('Successfully loaded ${_nominees.length} nominees from SecureStorage', tag: 'NomineeManagement');
  }

  Future<void> _prepopulateFromInitialData() async {
    // Fetch relations list for mapping names in summary cards
    final relations = await BseNomineeRelationService.getNomineeRelationsList();

    if (!mounted) return;

    setState(() {
      for (final nominee in widget.initialData!) {
        final dob = nominee.dob;
        final guardianDob = nominee.guardianDob;
        // Split name into first and last name
        final fullName = nominee.name ?? '';
        final nameParts = fullName.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        final nomineeData = NomineeData(
          id: nominee.id,
          firstName: firstName,
          lastName: lastName,
          relation: nominee.relation ?? '',
          dob:
              dob != null
                  ? "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}"
                  : '',
          nomineePan: nominee.nomineePan ?? '',
          nomineeContactNumber: nominee.nomineeContactNumber ?? '',
          nomineeEmail: nominee.nomineeEmail ?? '',
          addressLine1: nominee.addressLine1 ?? '',
          city: nominee.city ?? '',
          state: nominee.state ?? '',
          country: nominee.country ?? '',
          postalCode: nominee.postalCode ?? '',
          nomineePercent: nominee.nomineePercent ?? 0,
          guardianName: nominee.guardianName ?? '',
          guardianRelation: nominee.guardianRelation ?? '',
          guardianPan: nominee.guardianPan ?? '',
          guardianDob:
              guardianDob != null
                  ? "${guardianDob.year}-${guardianDob.month.toString().padLeft(2, '0')}-${guardianDob.day.toString().padLeft(2, '0')}"
                  : null,
        );

        // Map relation ID to name
        String relationName = '';
        if (relations != null) {
          try {
            final match = relations.firstWhere(
              (r) =>
                  r.id == nominee.relation ||
                  (nominee.relation != null &&
                      int.tryParse(r.id) == int.tryParse(nominee.relation!)),
            );
            relationName = match.name;
          } catch (_) {}
        }

        // Map guardian relation ID to name
        String guardianRelationName = '';
        if (relations != null && nominee.guardianRelation != null) {
          try {
            final match = relations.firstWhere(
              (r) =>
                  r.id == nominee.guardianRelation ||
                  int.tryParse(r.id) == int.tryParse(nominee.guardianRelation!),
            );
            guardianRelationName = match.name;
          } catch (_) {}
        }

        _nominees.add(nomineeData);
        _firstNameControllers.add(TextEditingController(text: firstName));
        _lastNameControllers.add(TextEditingController(text: lastName));
        _relationControllers.add(
          TextEditingController(text: nominee.relation ?? ''),
        );
        final nomineeDob = nominee.dob;
        _dobControllers.add(
          TextEditingController(
            text:
                nomineeDob != null
                    ? "${nomineeDob.year}-${nomineeDob.month.toString().padLeft(2, '0')}-${nomineeDob.day.toString().padLeft(2, '0')}"
                    : '',
          ),
        );
        _panControllers.add(
          TextEditingController(text: nominee.nomineePan ?? ''),
        );
        _contactControllers.add(
          TextEditingController(text: nominee.nomineeContactNumber ?? ''),
        );
        _emailControllers.add(
          TextEditingController(text: nominee.nomineeEmail ?? ''),
        );
        _address1Controllers.add(
          TextEditingController(text: nominee.addressLine1 ?? ''),
        );
        _cityControllers.add(TextEditingController(text: nominee.city ?? ''));
        _stateControllers.add(TextEditingController(text: nominee.state ?? ''));
        _countryControllers.add(
          TextEditingController(text: nominee.country ?? ''),
        );
        _postalCodeControllers.add(
          TextEditingController(text: nominee.postalCode ?? ''),
        );
        _percentControllers.add(
          TextEditingController(text: nominee.nomineePercent.toString()),
        );
        _guardianNameControllers.add(
          TextEditingController(text: nominee.guardianName ?? ''),
        );
        _guardianRelationControllers.add(
          TextEditingController(text: nominee.guardianRelation ?? ''),
        );
        _guardianPanControllers.add(
          TextEditingController(text: nominee.guardianPan ?? ''),
        );
        _guardianDobControllers.add(
          TextEditingController(
            text:
                nominee.guardianDob != null
                    ? "${nominee.guardianDob!.year}-${nominee.guardianDob!.month.toString().padLeft(2, '0')}-${nominee.guardianDob!.day.toString().padLeft(2, '0')}"
                    : '',
          ),
        );

        _selectedRelationNames.add(relationName);
        _selectedRelationIds.add(nominee.relation ?? '');
        _selectedGuardianRelationNames.add(guardianRelationName);
        _selectedGuardianRelationIds.add(nominee.guardianRelation ?? '');
        _selectedCountries.add(Country(name: '', code: nominee.country ?? ''));

        // Initialize errors as null
        _firstNameErrors.add(null);
        _lastNameErrors.add(null);
        _relationErrors.add(null);
        _dobErrors.add(null);
        _panErrors.add(null);
        _contactErrors.add(null);
        _emailErrors.add(null);
        _address1Errors.add(null);
        _cityErrors.add(null);
        _stateErrors.add(null);
        _postalCodeErrors.add(null);
        _percentErrors.add(null);
        _guardianNameErrors.add(null);
        _guardianRelationErrors.add(null);
        _guardianPanErrors.add(null);
        _guardianDobErrors.add(null);
        _isSameAsPrimary.add(false);

        // Initialize FocusNodes
        _firstNameNodes.add(FocusNode());
        _lastNameNodes.add(FocusNode());
        _panNodes.add(FocusNode());
        _contactNodes.add(FocusNode());
        _emailNodes.add(FocusNode());
        _address1Nodes.add(FocusNode());
        _cityNodes.add(FocusNode());
        _stateNodes.add(FocusNode());
        _postalCodeNodes.add(FocusNode());
        _dobNodes.add(FocusNode());
        _guardianNameNodes.add(FocusNode());
        _guardianPanNodes.add(FocusNode());
        _guardianDobNodes.add(FocusNode());
      }
    });
  }

  @override
  void didUpdateWidget(NomineeManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('didUpdateWidget called');
    debugPrint('Old shouldSubmit: ${oldWidget.shouldSubmit}');
    debugPrint('New shouldSubmit: ${widget.shouldSubmit}');
    debugPrint('Is loading: $_isLoading');

    // Trigger submission when shouldSubmit is true and not already loading
    if (widget.shouldSubmit && !_isLoading) {
      debugPrint('Triggering _submitNomineeData from didUpdateWidget');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitNomineeData();
      });
    }

    // Re-populate if initialData changed
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null &&
        widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    }
  }

  @override
  void dispose() {
    for (var controller in _firstNameControllers) {
      controller.dispose();
    }
    for (var controller in _lastNameControllers) {
      controller.dispose();
    }
    for (var controller in _relationControllers) {
      controller.dispose();
    }
    for (var controller in _dobControllers) {
      controller.dispose();
    }
    for (var controller in _panControllers) {
      controller.dispose();
    }
    for (var controller in _contactControllers) {
      controller.dispose();
    }
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var controller in _address1Controllers) {
      controller.dispose();
    }
    for (var controller in _cityControllers) {
      controller.dispose();
    }
    for (var controller in _stateControllers) {
      controller.dispose();
    }
    for (var controller in _countryControllers) {
      controller.dispose();
    }
    for (var controller in _postalCodeControllers) {
      controller.dispose();
    }
    for (var controller in _percentControllers) {
      controller.dispose();
    }
    for (var controller in _guardianNameControllers) {
      controller.dispose();
    }
    for (var controller in _guardianRelationControllers) {
      controller.dispose();
    }
    for (var controller in _guardianPanControllers) {
      controller.dispose();
    }
    for (var controller in _guardianDobControllers) {
      controller.dispose();
    }
    for (var node in _firstNameNodes) node.dispose();
    for (var node in _lastNameNodes) node.dispose();
    for (var node in _panNodes) node.dispose();
    for (var node in _contactNodes) node.dispose();
    for (var node in _emailNodes) node.dispose();
    for (var node in _address1Nodes) node.dispose();
    for (var node in _cityNodes) node.dispose();
    for (var node in _stateNodes) node.dispose();
    for (var node in _postalCodeNodes) node.dispose();
    for (var node in _dobNodes) node.dispose();
    for (var node in _guardianNameNodes) node.dispose();
    for (var node in _guardianPanNodes) node.dispose();
    for (var node in _guardianDobNodes) node.dispose();
    super.dispose();
  }

  bool get _isPrefilled =>
      widget.initialData != null && widget.initialData!.isNotEmpty;

  void _addNewNominee() {
    if (_nominees.length >= 3) return;

    final newNominee = NomineeData(
      firstName: '',
      lastName: '',
      relation: '',
      dob: '',
      nomineePan: '',
      nomineeContactNumber: '',
      nomineeEmail: '',
      addressLine1: '',
      city: '',
      state: '',
      country: 'IND',
      postalCode: '',
      nomineePercent: _calculateDefaultPercentage(),
    );

    setState(() {
      // Add at the end to avoid confusion
      _nominees.add(newNominee);
      _firstNameControllers.add(TextEditingController());
      _lastNameControllers.add(TextEditingController());
      _relationControllers.add(TextEditingController());
      _dobControllers.add(TextEditingController());
      _panControllers.add(TextEditingController());
      _contactControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
      _address1Controllers.add(TextEditingController());
      _cityControllers.add(TextEditingController());
      _stateControllers.add(TextEditingController());
      _countryControllers.add(TextEditingController(text: 'IND'));
      _postalCodeControllers.add(TextEditingController());
      _percentControllers.add(
        TextEditingController(text: newNominee.nomineePercent.toString()),
      );
      _guardianNameControllers.add(TextEditingController());
      _guardianRelationControllers.add(TextEditingController());
      _guardianPanControllers.add(TextEditingController());
      _guardianDobControllers.add(TextEditingController());

      // Initialize relation name and ID for new nominee
      _selectedRelationNames.add('');
      _selectedRelationIds.add('');
      _selectedGuardianRelationNames.add('');
      _selectedGuardianRelationIds.add('');

      // Initialize with India as default
      _selectedCountries.add(Country(name: 'India', code: 'IND'));

      // Initialize error states as null
      _firstNameErrors.add(null);
      _lastNameErrors.add(null);
      _relationErrors.add(null);
      _dobErrors.add(null);
      _panErrors.add(null);
      _contactErrors.add(null);
      _emailErrors.add(null);
      _address1Errors.add(null);
      _cityErrors.add(null);
      _stateErrors.add(null);
      _postalCodeErrors.add(null);
      _percentErrors.add(null);
      _guardianNameErrors.add(null);
      _guardianRelationErrors.add(null);
      _guardianPanErrors.add(null);
      _guardianDobErrors.add(null);
      _isSameAsPrimary.add(false);

      // Initialize FocusNodes
      _firstNameNodes.add(FocusNode());
      _lastNameNodes.add(FocusNode());
      _panNodes.add(FocusNode());
      _contactNodes.add(FocusNode());
      _emailNodes.add(FocusNode());
      _address1Nodes.add(FocusNode());
      _cityNodes.add(FocusNode());
      _stateNodes.add(FocusNode());
      _postalCodeNodes.add(FocusNode());
      _dobNodes.add(FocusNode());
      _guardianNameNodes.add(FocusNode());
      _guardianPanNodes.add(FocusNode());
      _guardianDobNodes.add(FocusNode());

      // Auto-expand the newly added nominee
      _editingIndex = _nominees.length - 1;
    });

    _redistributePercentages();
  }

  int _calculateDefaultPercentage() {
    switch (_nominees.length) {
      case 0:
        return 100;
      case 1:
        return 50;
      case 2:
        return 33;
      default:
        return 0;
    }
  }

  void _redistributePercentages() {
    if (_nominees.isEmpty) return;

    setState(() {
      if (_nominees.length == 1) {
        _nominees[0].nomineePercent = 100;
      } else if (_nominees.length == 2) {
        _nominees[0].nomineePercent = 50;
        _nominees[1].nomineePercent = 50;
      } else if (_nominees.length == 3) {
        _nominees[0].nomineePercent = 34;
        _nominees[1].nomineePercent = 33;
        _nominees[2].nomineePercent = 33;
      }

      // Sync controllers for all nominees
      for (int i = 0; i < _nominees.length; i++) {
        _percentControllers[i].text = _nominees[i].nomineePercent.toString();
      }
    });
  }

  void _updatePercentage(int index, String value) {
    if (_nominees.length == 1) {
      _nominees[0].nomineePercent = 100;
      _percentControllers[0].text = '100';
      return;
    }

    int? newPercent = int.tryParse(value);
    if (newPercent == null) return;

    // Enforce minimum share of 1% for all nominees (max share depends on number of nominees)
    int minOtherShares = (_nominees.length - 1) * 1;
    int maxPercent = 100 - minOtherShares;

    if (newPercent > maxPercent) newPercent = maxPercent;
    if (newPercent < 1) newPercent = 1;

    setState(() {
      _nominees[index].nomineePercent = newPercent!;
      _percentControllers[index].text = newPercent.toString();
      _manuallyModifiedIndices.add(index);

      // Redistribute remaining percentages among other nominees
      _redistributeRemainingPercentages(index);
    });
  }

  void _redistributeRemainingPercentages(int changedIndex) {
    final otherIndices = List.generate(_nominees.length, (i) => i)
      ..remove(changedIndex);
    if (otherIndices.isEmpty) return;

    int remaining = 100 - _nominees[changedIndex].nomineePercent;

    // Distribute 'remaining' percentage among other nominees proportionally,
    // ensuring each gets at least 1% (API requirement)
    int minOtherShares = otherIndices.length * 1;
    int extraToDistribute = remaining - minOtherShares;

    int currentOthersSum = 0;
    for (int idx in otherIndices) {
      currentOthersSum += _nominees[idx].nomineePercent;
    }

    if (currentOthersSum == 0 || extraToDistribute <= 0) {
      // If others were 0 or we only have minimal shares to give, split the remaining share equally
      int share = remaining ~/ otherIndices.length;
      for (int i = 0; i < otherIndices.length; i++) {
        int idx = otherIndices[i];
        _nominees[idx].nomineePercent =
            (i == 0) ? share + (remaining % otherIndices.length) : share;
        if (_nominees[idx].nomineePercent < 1)
          _nominees[idx].nomineePercent = 1;
        _percentControllers[idx].text =
            _nominees[idx].nomineePercent.toString();
      }
    } else {
      // Redistribute proportionally based on current relative shares
      int runningExtraAdded = 0;
      for (int i = 0; i < otherIndices.length; i++) {
        int idx = otherIndices[i];
        if (i == otherIndices.length - 1) {
          _nominees[idx].nomineePercent =
              1 + (extraToDistribute - runningExtraAdded);
        } else {
          int extraShare =
              (extraToDistribute * _nominees[idx].nomineePercent) ~/
              currentOthersSum;
          _nominees[idx].nomineePercent = 1 + extraShare;
          runningExtraAdded += extraShare;
        }
        _percentControllers[idx].text =
            _nominees[idx].nomineePercent.toString();
      }
    }
  }

  Future<void> _removeNominee(int index) async {
    final nomineeId = _nominees[index].id;

    if (nomineeId != null) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Nominee?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will permanently remove this nominee from your application.',
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
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);
      final success = await NomineeManagementService.deleteNominee(nomineeId);
      setState(() => _isLoading = false);

      if (!success) {
        Get.snackbar(
          'Error',
          'Failed to delete nominee. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() {
      _nominees.removeAt(index);
      _firstNameControllers.removeAt(index).dispose();
      _lastNameControllers.removeAt(index).dispose();
      _relationControllers.removeAt(index).dispose();
      _dobControllers.removeAt(index).dispose();
      _panControllers.removeAt(index).dispose();
      _contactControllers.removeAt(index).dispose();
      _emailControllers.removeAt(index).dispose();
      _address1Controllers.removeAt(index).dispose();
      _cityControllers.removeAt(index).dispose();
      _stateControllers.removeAt(index).dispose();
      _countryControllers.removeAt(index).dispose();
      _postalCodeControllers.removeAt(index).dispose();
      _percentControllers.removeAt(index).dispose();
      _guardianNameControllers.removeAt(index).dispose();
      _guardianRelationControllers.removeAt(index).dispose();
      _guardianPanControllers.removeAt(index).dispose();
      _guardianDobControllers.removeAt(index).dispose();

      // Remove focus nodes
      _firstNameNodes.removeAt(index).dispose();
      _lastNameNodes.removeAt(index).dispose();
      _panNodes.removeAt(index).dispose();
      _contactNodes.removeAt(index).dispose();
      _emailNodes.removeAt(index).dispose();
      _address1Nodes.removeAt(index).dispose();
      _cityNodes.removeAt(index).dispose();
      _stateNodes.removeAt(index).dispose();
      _postalCodeNodes.removeAt(index).dispose();
      _dobNodes.removeAt(index).dispose();
      _guardianNameNodes.removeAt(index).dispose();
      _guardianPanNodes.removeAt(index).dispose();
      _guardianDobNodes.removeAt(index).dispose();

      // Remove relation name and ID
      _selectedRelationNames.removeAt(index);
      _selectedRelationIds.removeAt(index);
      _selectedGuardianRelationNames.removeAt(index);
      _selectedGuardianRelationIds.removeAt(index);
      _selectedCountries.removeAt(index);

      // Remove error states
      _firstNameErrors.removeAt(index);
      _lastNameErrors.removeAt(index);
      _relationErrors.removeAt(index);
      _dobErrors.removeAt(index);
      _panErrors.removeAt(index);
      _contactErrors.removeAt(index);
      _emailErrors.removeAt(index);
      _address1Errors.removeAt(index);
      _cityErrors.removeAt(index);
      _stateErrors.removeAt(index);
      _postalCodeErrors.removeAt(index);
      _percentErrors.removeAt(index);
      _guardianNameErrors.removeAt(index);
      _guardianRelationErrors.removeAt(index);
      _guardianPanErrors.removeAt(index);
      _guardianDobErrors.removeAt(index);
      _isSameAsPrimary.removeAt(index);

      // Reset editing index if the deleted one was being edited
      if (_editingIndex == index) {
        _editingIndex = _nominees.isEmpty ? null : 0;
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }

      // If no nominees left, add one empty one
      if (_nominees.isEmpty) {
        _addNewNominee();
      }
    });
    _redistributePercentages();
  }

  void _updateRelationSelection(
    int index,
    String relationName,
    String relationId,
  ) {
    setState(() {
      _selectedRelationNames[index] = relationName;
      _selectedRelationIds[index] = relationId;

      // Format relation ID to remove leading zeros for API submission
      String formattedRelationId = relationId;
      if (relationId.startsWith('0') && relationId.length > 1) {
        formattedRelationId =
            int.tryParse(relationId)?.toString() ?? relationId;
      }

      _relationControllers[index].text =
          formattedRelationId; // Update relation controller for submission
      _updateNomineeData(index);
    });
  }

  void _updateGuardianRelationSelection(
    int index,
    String relationName,
    String relationId,
  ) {
    setState(() {
      _selectedGuardianRelationNames[index] = relationName;
      _selectedGuardianRelationIds[index] = relationId;

      // Format relation ID to remove leading zeros for API submission
      String formattedRelationId = relationId;
      if (relationId.startsWith('0') && relationId.length > 1) {
        formattedRelationId =
            int.tryParse(relationId)?.toString() ?? relationId;
      }

      _guardianRelationControllers[index].text =
          formattedRelationId; // Update relation controller for submission
      _updateNomineeData(index);
    });
  }

  void _updateNomineeData(int index) {
    setState(() {
      _nominees[index] = NomineeData(
        id: _nominees[index].id,
        firstName: _firstNameControllers[index].text,
        lastName: _lastNameControllers[index].text,
        relation: _relationControllers[index].text,
        dob: _dobControllers[index].text,
        nomineePan: _panControllers[index].text,
        nomineeContactNumber: _contactControllers[index].text,
        nomineeEmail: _emailControllers[index].text,
        addressLine1: _address1Controllers[index].text,
        city: _cityControllers[index].text,
        state: _stateControllers[index].text,
        country: _countryControllers[index].text,
        postalCode: _postalCodeControllers[index].text,
        nomineePercent: _nominees[index].nomineePercent,
        guardianName: _guardianNameControllers[index].text,
        guardianRelation: _guardianRelationControllers[index].text,
        guardianPan: _guardianPanControllers[index].text,
        guardianDob: _guardianDobControllers[index].text,
      );
    });
    _validateNomineeAtIndex(index);
  }

  // Validate form fields
  bool _validateForm() {
    AppLogger.info(
      'Entering _validateForm, nominee count: ${_nominees.length}',
      tag: 'NomineeValidation',
    );
    debugPrint('Entering _validateForm, nominee count: ${_nominees.length}');

    // Clear all existing errors
    setState(() {
      for (int i = 0; i < _nominees.length; i++) {
        _firstNameErrors[i] = null;
        _lastNameErrors[i] = null;
        _relationErrors[i] = null;
        _dobErrors[i] = null;
        _panErrors[i] = null;
        _contactErrors[i] = null;
        _emailErrors[i] = null;
        _address1Errors[i] = null;
        _cityErrors[i] = null;
        _stateErrors[i] = null;
        _postalCodeErrors[i] = null;
        _percentErrors[i] = null;
        _guardianNameErrors[i] = null;
        _guardianRelationErrors[i] = null;
        _guardianPanErrors[i] = null;
        _guardianDobErrors[i] = null;
      }
    });

    if (!_isNomineeOpted) return true;

    if (_nominees.isEmpty) {
      debugPrint('Validation failed: _nominees list is empty');
      widget.onError?.call();
      return false;
    }

    bool hasErrors = false;
    int? firstErrorIndex;

    for (int i = 0; i < _nominees.length; i++) {
      if (!_validateNomineeAtIndex(i)) {
        hasErrors = true;
        firstErrorIndex ??= i;
      }
    }

    if (hasErrors) {
      // Expand the first nominee that has an error
      if (firstErrorIndex != null) {
        setState(() {
          _editingIndex = firstErrorIndex;
        });
      }
      return false;
    }

    return true;
  }

  bool _validateNomineeAtIndex(int i) {
    bool hasError = false;
    String? firstNameError;
    String? lastNameError;
    String? relationError;
    String? dobError;
    String? panError;
    String? contactError;
    String? emailError;
    String? address1Error;
    String? cityError;
    String? stateError;
    String? postalCodeError;
    String? guardianNameError;
    String? guardianRelationError;
    String? guardianPanError;
    String? guardianDobError;

    // First Name
    if (_firstNameControllers[i].text.trim().isEmpty) {
      firstNameError = 'First name is required';
      hasError = true;
    }
    
    // Last Name
    if (_lastNameControllers[i].text.trim().isEmpty) {
      lastNameError = 'Last name is required';
      hasError = true;
    }

    // Relation
    if (_relationControllers[i].text.trim().isEmpty) {
      relationError = 'Relation is required';
      hasError = true;
    }

    // Date of Birth
    final dob = _dobControllers[i].text.trim();
    if (dob.isEmpty) {
      dobError = 'Date of Birth is required';
      hasError = true;
    } else {
      final dobErr = AppValidators.validateISODate(dob);
      if (dobErr != null) {
        dobError = dobErr;
        hasError = true;
      }
    }

    // PAN
    final pan = _panControllers[i].text.trim();
    if (!_nominees[i].isMinor) {
      if (pan.isEmpty) {
        panError = 'PAN is required';
        hasError = true;
      } else {
        final panErr = AppValidators.validateNomineePan(pan);
        if (panErr != null) {
          panError = panErr;
          hasError = true;
        }
      }
    }

    // Contact Number
    final contact = _contactControllers[i].text.trim();
    final cleanContact = AppValidators.cleanPhoneNumber(contact);
    if (contact.isEmpty) {
      contactError = 'Contact Number is required';
      hasError = true;
    } else if (cleanContact.length != 10) {
      contactError = 'Must be 10 digits';
      hasError = true;
    }

    // Email
    final email = _emailControllers[i].text.trim();
    if (email.isEmpty) {
      emailError = 'Email is required';
      hasError = true;
    } else if (!GetUtils.isEmail(email)) {
      emailError = 'Invalid email format';
      hasError = true;
    }

    // Address Line 1
    final address1 = _address1Controllers[i].text.trim();
    if (address1.isEmpty) {
      address1Error = 'Address Line 1 is required';
      hasError = true;
    } else if (address1.length < 10 || address1.length > 40) {
      address1Error = 'Must be between 10 and 40 characters';
      hasError = true;
    }

    // State (renamed from City)
    if (_cityControllers[i].text.trim().isEmpty) {
      cityError = 'State is required';
      hasError = true;
    }

    // Postal Code
    final postalCode = _postalCodeControllers[i].text.trim();
    final pCodeErr = AppValidators.validatePostalCode(
      postalCode,
      countryCode: _selectedCountries[i]?.code ?? 'IND',
    );
    if (pCodeErr != null) {
      postalCodeError = pCodeErr;
      hasError = true;
    }

    // Guardian validation if minor - COMMENTED OUT (not needed for now)
    // if (_nominees[i].isMinor) {
    //   if (_guardianNameControllers[i].text.trim().isEmpty) {
    //     guardianNameError = 'Guardian Name is required';
    //     hasError = true;
    //   }
    //   if (_guardianRelationControllers[i].text.trim().isEmpty) {
    //     guardianRelationError = 'Guardian Relation is required';
    //     hasError = true;
    //   }
    //   final gDob = _guardianDobControllers[i].text.trim();
    //   if (gDob.isEmpty) {
    //     guardianDobError = 'Guardian DOB is required';
    //     hasError = true;
    //   } else {
    //     try {
    //       final guardianBirthDate = DateTime.parse(gDob);
    //       final now = DateTime.now();
    //       final age = now.year -
    //           guardianBirthDate.year -
    //           (now.month < guardianBirthDate.month ||
    //                   (now.month == guardianBirthDate.month &&
    //                       now.day < guardianBirthDate.day)
    //               ? 1
    //               : 0);
    //       if (age < 18) {
    //         guardianDobError = 'Guardian must be at least 18 years old';
    //         hasError = true;
    //       }
    //     } catch (_) {
    //       guardianDobError = 'Invalid date format';
    //       hasError = true;
    //     }
    //   }

    //   final gPan = _guardianPanControllers[i].text.trim();
    //   if (gPan.isEmpty) {
    //     guardianPanError = 'Guardian PAN is required';
    //     hasError = true;
    //   } else {
    //     final gPanErr = AppValidators.validateNomineePan(gPan);
    //     if (gPanErr != null) {
    //       guardianPanError = gPanErr;
    //       hasError = true;
    //     }
    //   }
    // }

    // Update all errors at once to ensure smooth typing performance
    setState(() {
      _firstNameErrors[i] = firstNameError;
      _lastNameErrors[i] = lastNameError;
      _relationErrors[i] = relationError;
      _dobErrors[i] = dobError;
      _panErrors[i] = panError;
      _contactErrors[i] = contactError;
      _emailErrors[i] = emailError;
      _address1Errors[i] = address1Error;
      _cityErrors[i] = cityError;
      _stateErrors[i] = stateError;
      _postalCodeErrors[i] = postalCodeError;
      _guardianNameErrors[i] = guardianNameError;
      _guardianRelationErrors[i] = guardianRelationError;
      _guardianPanErrors[i] = guardianPanError;
      _guardianDobErrors[i] = guardianDobError;
    });

    if (hasError) {
      debugPrint('Validation failed for nominee at index $i:');
      if (firstNameError != null) debugPrint(' - FirstName: $firstNameError');
      if (lastNameError != null) debugPrint(' - LastName: $lastNameError');
      if (relationError != null) debugPrint(' - Relation: $relationError');
      if (dobError != null) debugPrint(' - DOB: $dobError');
      if (panError != null) debugPrint(' - PAN: $panError');
      if (contactError != null) debugPrint(' - Contact: $contactError');
      if (emailError != null) debugPrint(' - Email: $emailError');
      if (address1Error != null) debugPrint(' - Address1: $address1Error');
      if (cityError != null) debugPrint(' - State: $cityError');
      if (postalCodeError != null)
        debugPrint(' - PostalCode: $postalCodeError');
      if (guardianNameError != null)
        debugPrint(' - GuardianName: $guardianNameError');
      if (guardianRelationError != null)
        debugPrint(' - GuardianRelation: $guardianRelationError');
      if (guardianPanError != null)
        debugPrint(' - GuardianPAN: $guardianPanError');
      if (guardianDobError != null)
        debugPrint(' - GuardianDOB: $guardianDobError');
    }

    return !hasError;
  }

  // Store nominee data locally for UCC API submission in signature screen
  Future<void> _submitNomineeData() async {
    AppLogger.info('Starting nominee data save to local storage', tag: 'NomineeManagement');
    
    // If opted out, just store the choice and proceed
    if (!_isNomineeOpted) {
      AppLogger.info('User opted out of nominees', tag: 'NomineeManagement');
      
      await SecureStorage.write('has_nominees', 'false');
      await SecureStorage.write('nominee_data', '');
      
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Success',
              'Nominee preference saved. You can proceed to signature.',
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
      return;
    }
    
    // Validate form
    if (!_validateForm()) {
      AppLogger.info('Validation failed - nominee data not valid', tag: 'NomineeManagement');
      widget.onError?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

      // Build nominee list for UCC API format
      final List<Map<String, dynamic>> nomineeList = [];

      for (int i = 0; i < _nominees.length; i++) {
        // Get first and last name from controllers
        final firstName = _firstNameControllers[i].text.trim();
        final lastName = _lastNameControllers[i].text.trim();
        
        String relationId = _relationControllers[i].text.trim();
        if (relationId.startsWith('0') && relationId.length > 1) {
          relationId = int.tryParse(relationId)?.toString() ?? relationId;
        }

        final nomineeMap = {
          'first_name': firstName,
          'last_name': lastName,
          'dob': _dobControllers[i].text.trim(),
          'percent': _nominees[i].nomineePercent,
          'relation': relationId,
          'is_minor': _nominees[i].isMinor,
          'pan': _nominees[i].isMinor ? '' : _panControllers[i].text.trim(),
          'mobile': _contactControllers[i].text.trim(),
          'email': _emailControllers[i].text.trim(),
          // Address fields
          'address_line1': _address1Controllers[i].text.trim(),
          'city': _cityControllers[i].text.trim(),
          'state': _stateControllers[i].text.trim(),
          'country': _countryControllers[i].text.trim(),
          'pincode': _postalCodeControllers[i].text.trim(),
        };

        // Add guardian info for minors
        if (_nominees[i].isMinor) {
          String guardianRelationId = _guardianRelationControllers[i].text.trim();
          if (guardianRelationId.startsWith('0') && guardianRelationId.length > 1) {
            guardianRelationId = int.tryParse(guardianRelationId)?.toString() ?? guardianRelationId;
          }
          
          // Parse guardian name
          final guardianNameParts = _guardianNameControllers[i].text.trim().split(' ');
          final guardianFirstName = guardianNameParts.isNotEmpty ? guardianNameParts.first : '';
          final guardianLastName = guardianNameParts.length > 1 ? guardianNameParts.last : '';
          final guardianMiddleName = guardianNameParts.length > 2 ? guardianNameParts.sublist(1, guardianNameParts.length - 1).join(' ') : '';
          
          nomineeMap['guardian'] = {
            'first_name': guardianFirstName,
            'last_name': guardianLastName,
            'middle_name': guardianMiddleName,
            'dob': _guardianDobControllers[i].text.trim(),
            'pan': _guardianPanControllers[i].text.trim(),
          };
        }

        nomineeList.add(nomineeMap);
      }

      // Store nominee data in SecureStorage for UCC API
      final nomineeData = {
        'has_nominees': true,
        'nominees': nomineeList,
      };
      
      await SecureStorage.write('has_nominees', 'true');
      await SecureStorage.write('nominee_data', json.encode(nomineeData));
      
      AppLogger.info(
        'Stored ${nomineeList.length} nominees locally',
        tag: 'NomineeManagement',
      );
      
      AppLogger.info(
        'Nominee data: ${json.encode(nomineeData)}',
        tag: 'NomineeManagement',
      );

      // Show success message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Success',
              'Nominee information saved! Proceed to signature.',
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
        'Error saving nominee data',
        error: e,
        tag: 'NomineeManagement',
      );
      
      widget.onError?.call();
      
      // Show error message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !Get.isSnackbarOpen) {
            Get.snackbar(
              'Error',
              BseErrorTranslator.getFriendlyErrorMessage(
                'Failed to save nominee information',
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
          'Nominee Details',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'Add up to 3 nominees and allocate percentage shares.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),

        const SizedBox(height: 24),

        // Nomination Opt-out Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'I want to nominate',
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                      customColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'Provide nominee details for your account',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isNomineeOpted,
                onChanged: (value) {
                  setState(() {
                    _isNomineeOpted = value;
                    if (value && _nominees.isEmpty) {
                      _addNewNominee();
                    }
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white24,
                inactiveThumbColor: Colors.white.withOpacity(0.3),
                inactiveTrackColor: Colors.white.withOpacity(0.05),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (!_isNomineeOpted)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppText(
                    'You have chosen not to nominate. In case of unfortunate events, legal heirs will have to go through a longer process to claim the assets.',
                    variant: AppTextVariant.bodySmall,
                    customColor: Colors.orange.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...List.generate(
            _nominees.length,
            (index) =>
                _editingIndex == index
                    ? _buildNomineeCard(
                      index,
                      key: ValueKey('nominee_edit_$index'),
                    )
                    : _buildNomineeSummary(
                      index,
                      key: ValueKey('nominee_summary_$index'),
                    ),
          ),

          if (!_isPrefilled && _nominees.length < 3) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _addNewNominee,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    AppText(
                      'Add Nominee',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      customColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNomineeCard(int index, {Key? key}) {
    // Calculate actual nominee number
    final actualNomineeNumber = index + 1;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Nominee $actualNomineeNumber',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.semiBold,
                customColor: Colors.white,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingIndex = null;
                      });
                    },
                    child: const Icon(
                      Icons.expand_less,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (_nominees.length > 1 || _nominees[index].id != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _removeNominee(index),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // One field per line layout
          DarkInputField(
            label: 'First Name',
            controller: _firstNameControllers[index],
            hintText: 'Enter first name',
            errorText: _firstNameErrors[index],
            readOnly: _nominees[index].id != null,
            onChanged: (value) => _updateNomineeData(index),
          ),
          const SizedBox(height: 16),
          
          DarkInputField(
            label: 'Last Name',
            controller: _lastNameControllers[index],
            hintText: 'Enter last name',
            errorText: _lastNameErrors[index],
            readOnly: _nominees[index].id != null,
            onChanged: (value) => _updateNomineeData(index),
          ),
          const SizedBox(height: 16),

          CountryDropdown(
            label: 'Country',
            hintText: 'Select Country',
            enabled: _nominees[index].id == null,
            selectedCountryCode:
                _selectedCountries.length > index
                    ? _selectedCountries[index]?.code
                    : null,
            onCountrySelected: (country) {
              setState(() {
                _selectedCountries[index] = country;
                _countryControllers[index].text = country.code;
                _updateNomineeData(index);
              });
            },
          ),
          const SizedBox(height: 16),

          // Relation Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Relation',
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.white,
              ),
              const SizedBox(height: 8),
              DynamicRelationSelector(
                selectedRelationName:
                    _selectedRelationNames.isNotEmpty
                        ? _selectedRelationNames[index]
                        : '',
                selectedRelationId:
                    _selectedRelationIds.isNotEmpty
                        ? _selectedRelationIds[index]
                        : null,
                enabled: _nominees[index].id == null,
                errorText: _relationErrors[index],
                onRelationNameChanged:
                    (relationName) => _updateRelationSelection(
                      index,
                      relationName,
                      _selectedRelationIds[index],
                    ),
                onRelationIdChanged:
                    (relationId) => _updateRelationSelection(
                      index,
                      _selectedRelationNames[index],
                      relationId,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DarkInputField(
            key: ValueKey('nominee_${index}_dob'),
            focusNode: _dobNodes[index],
            label: 'Date of Birth',
            controller: _dobControllers[index],
            hintText: 'YYYY-MM-DD',
            isDateField: true,
            dateFormat: 'yyyy-MM-dd',
            readOnly: _nominees[index].id != null,
            errorText: _dobErrors[index],
            onChanged: (value) {
              _updateNomineeData(index);
              setState(() {}); // Refresh to show/hide guardian fields
            },
          ),
          const SizedBox(height: 16),

          // Guardian fields (shown only if nominee is minor) - COMMENTED OUT (not needed for now)
          // if (_nominees[index].isMinor) ...[
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: Colors.orange.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: Colors.orange.withOpacity(0.3)),
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(Icons.info_outline, color: Colors.orange, size: 16),
          //             const SizedBox(width: 6),
          //             AppText(
          //               'Minor - Guardian Required',
          //               variant: AppTextVariant.bodySmall,
          //               weight: AppTextWeight.semiBold,
          //               customColor: Colors.orange,
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         DarkInputField(
          //           key: ValueKey('nominee_${index}_guardian_name'),
          //           focusNode: _guardianNameNodes[index],
          //           label: 'Guardian Name',
          //           controller: _guardianNameControllers[index],
          //           hintText: 'Enter guardian name',
          //           readOnly: _nominees[index].id != null,
          //           errorText: _guardianNameErrors[index],
          //           onChanged: (value) => _updateNomineeData(index),
          //         ),
          //         const SizedBox(height: 16),
          //         DarkInputField(
          //           key: ValueKey('nominee_${index}_guardian_dob'),
          //           focusNode: _guardianDobNodes[index],
          //           label: 'Guardian Date of Birth',
          //           controller: _guardianDobControllers[index],
          //           hintText: 'YYYY-MM-DD',
          //           isDateField: true,
          //           lastDate: DateTime.now(),
          //           dateFormat: 'yyyy-MM-dd',
          //           readOnly: _nominees[index].id != null,
          //           errorText: _guardianDobErrors[index],
          //           onChanged: (value) => _updateNomineeData(index),
          //         ),
          //         const SizedBox(height: 16),
          //         DarkInputField(
          //           key: ValueKey('nominee_${index}_guardian_pan'),
          //           focusNode: _guardianPanNodes[index],
          //           label: 'Guardian PAN',
          //           controller: _guardianPanControllers[index],
          //           hintText: 'ABCDE1234F',
          //           helperText: '4th character must be P for Individuals',
          //           textCapitalization: TextCapitalization.characters,
          //           inputFormatters:
          //               AppInputFormatters.panCardFormattersLenient(),
          //           readOnly: _nominees[index].id != null,
          //           errorText: _guardianPanErrors[index],
          //           onChanged: (value) {
          //             _updateNomineeData(index);
          //             setState(() {
          //               final val = value.trim().toUpperCase();
          //               if (val.isNotEmpty &&
          //                   !RegExp(
          //                     r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
          //                   ).hasMatch(val)) {
          //                 _guardianPanErrors[index] = 'Invalid PAN format';
          //               } else {
          //                 _guardianPanErrors[index] = null;
          //               }
          //             });
          //           },
          //         ),
          //         const SizedBox(height: 16),
          //         Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             AppText(
          //               'Guardian Relation',
          //               variant: AppTextVariant.bodyMedium,
          //               weight: AppTextWeight.medium,
          //               colorType: AppTextColorType.white,
          //             ),
          //             const SizedBox(height: 6),
          //             DynamicRelationSelector(
          //               selectedRelationName:
          //                   _selectedGuardianRelationNames.isNotEmpty
          //                       ? _selectedGuardianRelationNames[index]
          //                       : '',
          //               selectedRelationId:
          //                   _selectedGuardianRelationIds.isNotEmpty
          //                       ? _selectedGuardianRelationIds[index]
          //                       : null,
          //               enabled: _nominees[index].id == null,
          //               errorText: _guardianRelationErrors[index],
          //               onRelationNameChanged: (relationName) {
          //                 _updateGuardianRelationSelection(
          //                   index,
          //                   relationName,
          //                   _selectedGuardianRelationIds[index],
          //                 );
          //               },
          //               onRelationIdChanged: (relationId) {
          //                 setState(() {
          //                   _selectedGuardianRelationIds[index] = relationId;
          //
          //                   // Format relation ID to remove leading zeros
          //                   String formattedId = relationId;
          //                   if (relationId.startsWith('0') &&
          //                       relationId.length > 1) {
          //                     formattedId =
          //                         int.tryParse(relationId)?.toString() ??
          //                         relationId;
          //                   }
          //
          //                   _guardianRelationControllers[index].text =
          //                       formattedId;
          //                 });
          //               },
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 16),
          // ],

          // if (!_nominees[index].isMinor) ...[
          // Show PAN for all nominees (minor check disabled)
          if (true) ...[
            DarkInputField(
              key: ValueKey('nominee_${index}_pan'),
              focusNode: _panNodes[index],
              label: 'PAN Number',
              controller: _panControllers[index],
              hintText: 'ABCDE1234F',
              helperText: '4th character must be P for Individuals',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: AppInputFormatters.panCardFormatters(),
              readOnly: _nominees[index].id != null,
              errorText: _panErrors[index],
              onChanged: (value) => _updateNomineeData(index),
            ),
            const SizedBox(height: 16),
          ],

          DarkInputField(
            key: ValueKey('nominee_${index}_contact'),
            focusNode: _contactNodes[index],
            label: 'Contact Number',
            controller: _contactControllers[index],
            hintText: 'Enter contact number',
            keyboardType: TextInputType.phone,
            readOnly: _nominees[index].id != null,
            errorText: _contactErrors[index],
            onChanged: (value) => _updateNomineeData(index),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 16),

          DarkInputField(
            key: ValueKey('nominee_${index}_email'),
            focusNode: _emailNodes[index],
            label: 'Email Address',
            controller: _emailControllers[index],
            hintText: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
            readOnly: _nominees[index].id != null,
            errorText: _emailErrors[index],
            onChanged: (value) => _updateNomineeData(index),
          ),
          const SizedBox(height: 16),

          // Same as Primary Holder Checkbox
          if (widget.primaryHolderAddress != null) ...[
            Row(
              children: [
                GestureDetector(
                  onTap:
                      _nominees[index].id != null
                          ? null
                          : () {
                            setState(() {
                              _isSameAsPrimary[index] =
                                  !_isSameAsPrimary[index];
                              if (_isSameAsPrimary[index]) {
                                final addr = widget.primaryHolderAddress!;
                                _address1Controllers[index].text =
                                    addr.line1 ?? '';
                                _cityControllers[index].text =
                                    addr.state ?? '';
                                _stateControllers[index].text =
                                    addr.state ?? '';
                                _selectedCountries[index] = Country(
                                  name: '',
                                  code: addr.country ?? 'IND',
                                );
                                _countryControllers[index].text =
                                    addr.country ?? 'IND';
                                _postalCodeControllers[index].text =
                                    addr.postalCode ?? '';
                                _updateNomineeData(index);
                              }
                            });
                          },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:
                          _isSameAsPrimary[index]
                              ? Colors.white
                              : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        _isSameAsPrimary[index]
                            ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                const AppText(
                  'Same as primary holder',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  customColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          DarkInputField(
            key: ValueKey('nominee_${index}_address1'),
            focusNode: _address1Nodes[index],
            label: 'Address Line 1',
            controller: _address1Controllers[index],
            hintText: 'Enter address',
            readOnly: _nominees[index].id != null,
            errorText: _address1Errors[index],
            onChanged: (value) => _updateNomineeData(index),
          ),
          const SizedBox(height: 16),

          DarkInputField(
            key: ValueKey('nominee_${index}_city'),
            focusNode: _cityNodes[index],
            label: 'State',
            controller: _cityControllers[index],
            hintText: 'Enter state',
            readOnly: _nominees[index].id != null,
            errorText: _cityErrors[index],
            onChanged: (value) {
              _updateNomineeData(index);
              // Sync with state controller if needed by the backend
              _stateControllers[index].text = value;
            },
          ),
          const SizedBox(height: 16),
          DarkInputField(
            label: 'Postal Code',
            controller: _postalCodeControllers[index],
            hintText: 'Enter postal code',
            keyboardType:
                (_selectedCountries[index]?.code == 'IND' ||
                        _selectedCountries[index]?.code == '91')
                    ? TextInputType.number
                    : TextInputType.text,
            readOnly: _nominees[index].id != null,
            inputFormatters: AppInputFormatters.postalCodeFormatters(
              length:
                  (_selectedCountries[index]?.code == 'IND' ||
                          _selectedCountries[index]?.code == '91')
                      ? 6
                      : 12,
              numericOnly:
                  (_selectedCountries[index]?.code == 'IND' ||
                      _selectedCountries[index]?.code == '91'),
            ),
            errorText: _postalCodeErrors[index],
            onChanged: (value) => _updateNomineeData(index),
          ),
          const SizedBox(height: 16),

          DarkInputField(
            key: ValueKey('nominee_${index}_percent'),
            label: 'Percentage (%)',
            controller: _percentControllers[index],
            hintText: 'Enter percentage',
            keyboardType: TextInputType.number,
            readOnly: _nominees[index].id != null || _nominees.length == 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _updatePercentage(index, value),
          ),

          const SizedBox(height: 24),
          const SizedBox(height: 12),
          // Done Button removed per user request
        ],
      ),
    );
  }

  Widget _buildNomineeSummary(int index, {Key? key}) {
    final nominee = _nominees[index];
    final actualNomineeNumber = index + 1;

    return GestureDetector(
      key: key,
      onTap: () {
        setState(() {
          _editingIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppText(
                  '$actualNomineeNumber',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  customColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    nominee.fullName.isEmpty
                        ? 'Nominee $actualNomineeNumber'
                        : nominee.fullName,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                    customColor: Colors.white,
                  ),
                  if (nominee.relation.isNotEmpty)
                    AppText(
                      '${_selectedRelationNames[index]} • ${nominee.nomineePercent}% share',
                      variant: AppTextVariant.bodySmall,
                      customColor: Colors.white.withOpacity(0.6),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
            if (_nominees.length > 1 || _nominees[index].id != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _removeNominee(index),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Formatting helper classes formerly here moved to validators.dart
