import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'widgets/pan_confirmation_screen.dart';
import 'widgets/bank_account_screen.dart';
import 'widgets/about_you_screen.dart';
import 'widgets/foreign_address_screen.dart';
import 'widgets/second_holder_screen.dart';
import 'widgets/fatca_screen.dart';
import 'widgets/add_nominee_screen.dart';
import 'widgets/income_employment_screen.dart';
import 'widgets/signature_screen.dart';
import 'widgets/signature_confirmation_screen.dart';
import 'widgets/success_screen.dart';
import 'widgets/progress_indicator_widget.dart';
import 'dart:typed_data';
import 'package:nwt_app/services/bse_star/ucc_creation.dart';
import 'package:nwt_app/screens/bse_star/types/ucc_creation_response.dart';
import 'package:nwt_app/utils/image_compression_helper.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';
import 'package:nwt_app/screens/bse_star/types/tax_status.dart';

class StartBSEJourney extends StatefulWidget {
  const StartBSEJourney({super.key});

  @override
  State<StartBSEJourney> createState() => _StartBSEJourneyState();
}

class _StartBSEJourneyState extends State<StartBSEJourney> {
  int currentStep = 1;
  final int totalSteps = 14;

  // Service instance
  final BseUccCreationService _uccService = BseUccCreationService();
  bool _isLoading = false;

  // GlobalKey for BankAccountScreen to access validation
  final GlobalKey<BankAccountScreenState> _bankAccountKey =
      GlobalKey<BankAccountScreenState>();

  // Controllers for form fields
  final TextEditingController panController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController spouseNameController = TextEditingController();
  final TextEditingController nomineeNameController = TextEditingController();
  final TextEditingController nomineeDobController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController shareAllocationController =
      TextEditingController();
  final TextEditingController secondHolderNameController =
      TextEditingController();
  final TextEditingController secondHolderDobController =
      TextEditingController();
  final TextEditingController secondHolderAadhaarController =
      TextEditingController();
  final TextEditingController secondHolderEmailController =
      TextEditingController();
  final TextEditingController secondHolderMobileController =
      TextEditingController();
  final TextEditingController secondHolderPanController =
      TextEditingController();
  final TextEditingController secondHolderFatherNameController =
      TextEditingController();
  final TextEditingController nomineeEmailController = TextEditingController();
  final TextEditingController nomineeMobileController = TextEditingController();
  final TextEditingController nomineeAddressController =
      TextEditingController();
  final TextEditingController nomineeCityController = TextEditingController();
  final TextEditingController nomineeStateController = TextEditingController();
  final TextEditingController nomineeCountryController =
      TextEditingController();
  final TextEditingController nomineePincodeController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController tinController = TextEditingController();

  // FATCA Primary Holder Controllers
  final TextEditingController primaryFatcaNameController =
      TextEditingController();
  final TextEditingController primaryFatcaPlaceOfBirthController =
      TextEditingController();
  final TextEditingController primaryFatcaCountryController =
      TextEditingController();
  final TextEditingController primaryFatcaDobController =
      TextEditingController();
  final TextEditingController primaryFatcaPanController =
      TextEditingController();
  final TextEditingController primaryFatcaNetworthController =
      TextEditingController();
  final TextEditingController primaryFatcaDateOfNetworthController =
      TextEditingController();
  final TextEditingController primaryFatcaLogNameController =
      TextEditingController();

  // FATCA Secondary Holder Controllers
  final TextEditingController secondaryFatcaNameController =
      TextEditingController();
  final TextEditingController secondaryFatcaPlaceOfBirthController =
      TextEditingController();
  final TextEditingController secondaryFatcaCountryController =
      TextEditingController();
  final TextEditingController secondaryFatcaDobController =
      TextEditingController();
  final TextEditingController secondaryFatcaPanController =
      TextEditingController();
  final TextEditingController secondaryFatcaNetworthController =
      TextEditingController();
  final TextEditingController secondaryFatcaDateOfNetworthController =
      TextEditingController();
  final TextEditingController secondaryFatcaLogNameController =
      TextEditingController();

  // State variables
  TaxStatus selectedTaxStatus = TaxStatus.nre;
  bool isNotNRI =
      true; // Default to true - all users are non-NRI since question is removed
  bool isNotPoliticallyExposed =
      true; // Default to true since question is not in UI
  String selectedAccountType = 'SB';
  String selectedGender = 'F';
  String selectedMaritalStatus = 'S';
  String selectedRelation = 'Father';
  String selectedRelationId = '';
  String selectedIdType = 'Aadhaar Card';
  bool sameAsApplicantAddress = true;
  String selectedSecondHolderRelation = '';
  String selectedSecondHolderRelationId = '';
  String selectedSecondHolderIdType = 'Aadhaar Card';
  String selectedSecondHolderOccupation = '';
  String selectedSecondHolderGender = '';
  bool isSecondHolderNRI = false;
  bool sameAsApplicantAddressSecondHolder = true;
  String selectedAnnualIncome = 'Less than 5 Lakhs';
  String selectedOccupation = '';
  String selectedCountryCode = 'IND'; // Default to India
  List<NomineeData> addedNominees = [];
  bool isEditingNominee = false;
  bool isAddingNominee = false;

  // FATCA Primary Holder State Variables
  String? primaryFatcaInvestorType;
  String? primaryFatcaOccupation;
  String? primaryFatcaCorporateServiceSector;
  String? primaryFatcaWealthSource;
  String? primaryFatcaIncomeSlab;
  String? primaryFatcaCountryOfBirth;
  String? primaryFatcaPoliticallyExposed;

  // FATCA Secondary Holder State Variables
  String? secondaryFatcaInvestorType;
  String? secondaryFatcaOccupation;
  String? secondaryFatcaCorporateServiceSector;
  String? secondaryFatcaWealthSource;
  String? secondaryFatcaIncomeSlab;
  String? secondaryFatcaCountryOfBirth;
  String? secondaryFatcaPoliticallyExposed;

  NomineeData?
  _nomineeBeingEdited; // Store nominee data before editing for cancel functionality
  int?
  _nomineeBeingEditedIndex; // Store the original index of the nominee being edited
  Uint8List? capturedSignature;
  String? capturedSignatureBase64;
  int currentScreenIndex =
      0; // 0: PAN, 1: Bank, 2: About You, 3: Foreign Address, 4: Second Holder, 5: Add Nominee, 6: Income Employment, 7: Signature, 8: Signature Confirmation

  // Track if data was loaded from API
  bool _isPanDataFromAPI = false;
  bool _isNameDataFromAPI = false;

  /// Maps ID type display names to API codes
  /// PAN -> C, Driving Licence -> E, Aadhaar Card -> G
  String _getIdTypeCode(String idType) {
    String code;
    switch (idType) {
      case 'PAN':
        code = 'pan';
        break;
      case 'Driving Licence':
        code = 'Driving Licence';
        break;
      case 'Aadhaar Card':
        code = 'aadhaar';
        break;
      default:
        code = 'aadhaar'; // Default to Aadhaar
        AppLogger.warning(
          'Unknown ID type: $idType, defaulting to G (Aadhaar)',
          tag: 'StartJourney',
        );
    }
    AppLogger.info(
      'ID Type Mapping: "$idType" -> "$code"',
      tag: 'StartJourney',
    );
    return code;
  }

  // Map wealth source display name to API code
  String _getWealthSourceCode(String wealthSource) {
    switch (wealthSource) {
      case 'Salary':
        return '1';
      case 'Business Income':
        return '2';
      case 'Gift':
        return '3';
      case 'Ancestral Property':
        return '4';
      case 'Rental Income':
        return '5';
      case 'Prize Money':
        return '6';
      case 'Royalty':
        return '7';
      case 'Others':
        return '8';
      default:
        return '1'; // Default to Salary
    }
  }

  // Map API code to wealth source display name
  String _getWealthSourceFromCode(String code) {
    switch (code) {
      case '1':
        return 'Salary';
      case '2':
        return 'Business Income';
      case '3':
        return 'Gift';
      case '4':
        return 'Ancestral Property';
      case '5':
        return 'Rental Income';
      case '6':
        return 'Prize Money';
      case '7':
        return 'Royalty';
      case '8':
        return 'Others';
      default:
        return 'Salary'; // Default to Salary
    }
  }

  // Map income slab display name to API code
  String _getIncomeSlabCode(String incomeSlab) {
    switch (incomeSlab) {
      case 'Below 1 Lakh':
        return '31';
      case '> 1 <=5 Lacs':
        return '32';
      case '>5 <=10 Lacs':
        return '33';
      case '>10 <= 25 Lacs':
        return '34';
      case '> 25 Lacs < = 1 Crore':
        return '35';
      case 'Above 1 Crore':
        return '36';
      default:
        return '31'; // Default to Below 1 Lakh
    }
  }

  // Map API code to income slab display name
  String _getIncomeSlabFromCode(String code) {
    switch (code) {
      case '31':
        return 'Below 1 Lakh';
      case '32':
        return '> 1 <=5 Lacs';
      case '33':
        return '>5 <=10 Lacs';
      case '34':
        return '>10 <= 25 Lacs';
      case '35':
        return '> 25 Lacs < = 1 Crore';
      case '36':
        return 'Above 1 Crore';
      default:
        return 'Below 1 Lakh'; // Default to Below 1 Lakh
    }
  }

  // Map politically exposed display name to API code
  String _getPoliticallyExposedCode(String politicallyExposed) {
    if (politicallyExposed.startsWith('Y')) {
      return 'Y';
    } else if (politicallyExposed.startsWith('N')) {
      return 'N';
    } else if (politicallyExposed.startsWith('R')) {
      return 'R';
    }
    return 'N'; // Default to N
  }

  // Map API code to politically exposed display name
  String _getPoliticallyExposedFromCode(String code) {
    switch (code) {
      case 'Y':
        return 'Y - The investor is politically exposed person';
      case 'N':
        return 'N - The investor is not politically exposed person';
      case 'R':
        return 'R - If the investor is a relative of the politically exposed person';
      default:
        return 'N - The investor is not politically exposed person'; // Default to N
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUccData();

    // Add listeners to nominee form fields to trigger rebuild when values change
    nomineeNameController.addListener(_onNomineeFormChanged);
    nomineeDobController.addListener(_onNomineeFormChanged);
    aadhaarController.addListener(_onNomineeFormChanged);
    nomineeEmailController.addListener(_onNomineeFormChanged);
    nomineeMobileController.addListener(_onNomineeFormChanged);
    shareAllocationController.addListener(_onShareAllocationChanged);
    nomineeAddressController.addListener(_onNomineeFormChanged);
    nomineeCityController.addListener(_onNomineeFormChanged);
    nomineeStateController.addListener(_onNomineeFormChanged);
    nomineeCountryController.addListener(_onNomineeFormChanged);
    nomineePincodeController.addListener(_onNomineeFormChanged);
  }

  void _onNomineeFormChanged() {
    // Only rebuild if we're on the nominee screen and adding/editing
    if (currentScreenIndex == 5 &&
        (isAddingNominee || isEditingNominee || addedNominees.isEmpty)) {
      setState(() {});
    }
  }

  void _onShareAllocationChanged() {
    // Handle real-time share redistribution
    if (currentScreenIndex == 5) {
      final currentShare = int.tryParse(shareAllocationController.text) ?? 0;

      // Case 1: When there's 1 nominee in the list (either adding 2nd or editing one of 2)
      if (addedNominees.length == 1 &&
          currentShare > 0 &&
          currentShare <= 100) {
        // Update the other nominee's share to be the remainder (works for both add and edit)
        final remainingShare = 100 - currentShare;
        setState(() {
          final existing = addedNominees[0];
          addedNominees[0] = NomineeData(
            name: existing.name,
            relation: existing.relation,
            dateOfBirth: existing.dateOfBirth,
            idType: existing.idType,
            aadhaar: existing.aadhaar,
            email: existing.email,
            mobile: existing.mobile,
            shareAllocation: remainingShare.toString(),
            sameAsApplicantAddress: existing.sameAsApplicantAddress,
            address: existing.address,
            city: existing.city,
            state: existing.state,
            country: existing.country,
            pincode: existing.pincode,
          );
        });
      }
      // Case 2: When there are 2 nominees in the list (either adding 3rd or editing one of 3)
      else if (addedNominees.length == 2 &&
          currentShare > 0 &&
          currentShare <= 100) {
        // Calculate remaining share to distribute between the 2 existing nominees (works for both add and edit)
        final remainingShare = 100 - currentShare;
        final sharePerNominee = (remainingShare / 2).floor();
        final remainder = remainingShare % 2;

        // Update existing nominees with new shares
        setState(() {
          for (int i = 0; i < addedNominees.length; i++) {
            final existing = addedNominees[i];
            final newShare = sharePerNominee + (i == 0 ? remainder : 0);
            addedNominees[i] = NomineeData(
              name: existing.name,
              relation: existing.relation,
              dateOfBirth: existing.dateOfBirth,
              idType: existing.idType,
              aadhaar: existing.aadhaar,
              email: existing.email,
              mobile: existing.mobile,
              shareAllocation: newShare.toString(),
              sameAsApplicantAddress: existing.sameAsApplicantAddress,
              address: existing.address,
              city: existing.city,
              state: existing.state,
              country: existing.country,
              pincode: existing.pincode,
            );
          }
        });
      } else {
        // For other cases, just trigger rebuild
        _onNomineeFormChanged();
      }
    }
  }

  Future<void> _loadUccData() async {
    try {
      final response = await _uccService.getUccResponse(
        onLoading: (loading) {
          setState(() {
            _isLoading = loading;
          });
        },
      );

      if (response.data != null) {
        final uccData = response.data!;

        // Populate form fields with API data
        setState(() {
          // PAN and basic info
          panController.text = uccData.panNumber!;
          nameController.text = uccData.panName!;
          dobController.text = uccData.dob!;
          emailController.text = uccData.email!;
          if (uccData.primaryFatherName != null &&
              uccData.primaryFatherName!.isNotEmpty) {
            fatherNameController.text = uccData.primaryFatherName!;
          }

          // Mark PAN and name as loaded from API
          _isPanDataFromAPI = true;
          _isNameDataFromAPI = true;

          // Bank details
          ifscController.text = uccData.ifscCode!;
          accountController.text = uccData.bankAccountNumber!;
          selectedAccountType = uccData.bankAccountType!;

          // Personal details
          selectedGender = uccData.gender!;
          selectedMaritalStatus = uccData.maritalStatus!;
          // Load occupation from primaryOccCode if available, fallback to occupation
          if (uccData.primaryOccCode != null &&
              uccData.primaryOccCode!.isNotEmpty) {
            selectedOccupation = uccData.primaryOccCode!;
          } else if (uccData.occupation != null &&
              uccData.occupation!.isNotEmpty) {
            selectedOccupation = uccData.occupation!;
          }

          // Tax status from taxCode
          if (uccData.taxCode != null && uccData.taxCode!.isNotEmpty) {
            final taxStatus = TaxStatus.fromTaxCode(uccData.taxCode);
            if (taxStatus != null) {
              selectedTaxStatus = taxStatus;
            }
          }

          // Foreign address details (populate if available)
          if (uccData.address != null && uccData.address!.isNotEmpty) {
            addressController.text = uccData.address!;
          }
          if (uccData.city != null && uccData.city!.isNotEmpty) {
            cityController.text = uccData.city!;
          }
          if (uccData.state != null && uccData.state!.isNotEmpty) {
            stateController.text = uccData.state!;
          }
          if (uccData.country != null && uccData.country!.isNotEmpty) {
            countryController.text = uccData.country!;
          }
          if (uccData.pincode != null && uccData.pincode!.isNotEmpty) {
            pincodeController.text = uccData.pincode!;
          }
          if (uccData.tin != null && uccData.tin!.isNotEmpty) {
            tinController.text = uccData.tin!;
          }
          if (uccData.sameAsApplicantAddress != null) {
            sameAsApplicantAddress = uccData.sameAsApplicantAddress!;
          }

          // FATCA Log Names (load from API if available)
          if (uccData.primaryLogName != null &&
              uccData.primaryLogName!.isNotEmpty) {
            primaryFatcaLogNameController.text = uccData.primaryLogName!;
          }
          if (uccData.secondHolderLogName != null &&
              uccData.secondHolderLogName!.isNotEmpty) {
            secondaryFatcaLogNameController.text = uccData.secondHolderLogName!;
          }

          // FATCA Place of Birth and Country of Birth (load from API if available)
          if (uccData.primaryPlaceOfBirth != null &&
              uccData.primaryPlaceOfBirth!.isNotEmpty) {
            primaryFatcaPlaceOfBirthController.text =
                uccData.primaryPlaceOfBirth!;
          }
          if (uccData.primaryCountryOfBirth != null &&
              uccData.primaryCountryOfBirth!.isNotEmpty) {
            primaryFatcaCountryOfBirth = uccData.primaryCountryOfBirth!;
          }
          if (uccData.secondHolderPlaceOfBirth != null &&
              uccData.secondHolderPlaceOfBirth!.isNotEmpty) {
            secondaryFatcaPlaceOfBirthController.text =
                uccData.secondHolderPlaceOfBirth!;
          }
          if (uccData.secondHolderCountryOfBirth != null &&
              uccData.secondHolderCountryOfBirth!.isNotEmpty) {
            secondaryFatcaCountryOfBirth = uccData.secondHolderCountryOfBirth!;
          }

          // FATCA Primary Holder Details (load from API if available)
          if (uccData.primaryFatcaName != null &&
              uccData.primaryFatcaName!.isNotEmpty) {
            primaryFatcaNameController.text = uccData.primaryFatcaName!;
          }
          if (uccData.primaryFatcaDob != null &&
              uccData.primaryFatcaDob!.isNotEmpty) {
            primaryFatcaDobController.text = uccData.primaryFatcaDob!;
          }
          if (uccData.primaryFatcaOccCode != null &&
              uccData.primaryFatcaOccCode!.isNotEmpty) {
            primaryFatcaOccupation = uccData.primaryFatcaOccCode!;
          }
          if (uccData.primaryIdentifierNumber != null &&
              uccData.primaryIdentifierNumber!.isNotEmpty) {
            primaryFatcaPanController.text = uccData.primaryIdentifierNumber!;
          }
          if (uccData.primaryLogName != null &&
              uccData.primaryLogName!.isNotEmpty) {
            primaryFatcaLogNameController.text = uccData.primaryLogName!;
          }
          if (uccData.primaryWealthSource != null &&
              uccData.primaryWealthSource!.isNotEmpty) {
            primaryFatcaWealthSource = _getWealthSourceFromCode(
              uccData.primaryWealthSource!,
            );
          }
          if (uccData.primaryIncomeSlab != null &&
              uccData.primaryIncomeSlab!.isNotEmpty) {
            primaryFatcaIncomeSlab = _getIncomeSlabFromCode(
              uccData.primaryIncomeSlab!,
            );
          }
          if (uccData.primaryNetWorth != null &&
              uccData.primaryNetWorth!.isNotEmpty) {
            primaryFatcaNetworthController.text = uccData.primaryNetWorth!;
          }
          if (uccData.primaryDateOfNetWorth != null &&
              uccData.primaryDateOfNetWorth!.isNotEmpty) {
            primaryFatcaDateOfNetworthController.text =
                uccData.primaryDateOfNetWorth!;
          }
          if (uccData.primaryPoliticallyExposed != null &&
              uccData.primaryPoliticallyExposed!.isNotEmpty) {
            primaryFatcaPoliticallyExposed = _getPoliticallyExposedFromCode(
              uccData.primaryPoliticallyExposed!,
            );
          }

          // FATCA Secondary Holder Details (load from API if available)
          if (uccData.secondaryHolderFatcaName != null &&
              uccData.secondaryHolderFatcaName!.isNotEmpty) {
            secondaryFatcaNameController.text =
                uccData.secondaryHolderFatcaName!;
          }
          if (uccData.secondaryHolderFatcaDob != null &&
              uccData.secondaryHolderFatcaDob!.isNotEmpty) {
            secondaryFatcaDobController.text = uccData.secondaryHolderFatcaDob!;
          }
          if (uccData.secondaryHolderFatcaOccCode != null &&
              uccData.secondaryHolderFatcaOccCode!.isNotEmpty) {
            secondaryFatcaOccupation = uccData.secondaryHolderFatcaOccCode!;
          }
          if (uccData.secondHolderIdentifierNumber != null &&
              uccData.secondHolderIdentifierNumber!.isNotEmpty) {
            secondaryFatcaPanController.text =
                uccData.secondHolderIdentifierNumber!;
          }
          if (uccData.secondHolderLogName != null &&
              uccData.secondHolderLogName!.isNotEmpty) {
            secondaryFatcaLogNameController.text = uccData.secondHolderLogName!;
          }
          if (uccData.secondHolderWealthSource != null &&
              uccData.secondHolderWealthSource!.isNotEmpty) {
            secondaryFatcaWealthSource = _getWealthSourceFromCode(
              uccData.secondHolderWealthSource!,
            );
          }
          if (uccData.secondHolderIncomeSlab != null &&
              uccData.secondHolderIncomeSlab!.isNotEmpty) {
            secondaryFatcaIncomeSlab = _getIncomeSlabFromCode(
              uccData.secondHolderIncomeSlab!,
            );
          }
          if (uccData.secondHolderNetWorth != null &&
              uccData.secondHolderNetWorth!.isNotEmpty) {
            secondaryFatcaNetworthController.text =
                uccData.secondHolderNetWorth!;
          }
          if (uccData.secondHolderDateOfNetWorth != null &&
              uccData.secondHolderDateOfNetWorth!.isNotEmpty) {
            secondaryFatcaDateOfNetworthController.text =
                uccData.secondHolderDateOfNetWorth!;
          }
          if (uccData.secondHolderPoliticallyExposed != null &&
              uccData.secondHolderPoliticallyExposed!.isNotEmpty) {
            secondaryFatcaPoliticallyExposed = _getPoliticallyExposedFromCode(
              uccData.secondHolderPoliticallyExposed!,
            );
          }

          // Secondary holder details (prefill if available)
          if (uccData.secondaryHolder != null) {
            final sh = uccData.secondaryHolder!;
            if ((sh.firstName ?? '').isNotEmpty) {
              secondHolderNameController.text = sh.firstName!;
            }
            if ((sh.dob ?? '').isNotEmpty) {
              secondHolderDobController.text = sh.dob!;
            }
            if ((sh.pan ?? '').isNotEmpty) {
              secondHolderPanController.text = sh.pan!;
            }
            if ((sh.email ?? '').isNotEmpty) {
              secondHolderEmailController.text = sh.email!;
            }
            if ((sh.mobile ?? '').isNotEmpty) {
              secondHolderMobileController.text = sh.mobile!;
            }
            if ((sh.relationship ?? '').isNotEmpty) {
              selectedSecondHolderRelationId = sh.relationship!;
            }
          }

          // Load second holder gender from API
          if (uccData.second_holder_gender != null &&
              uccData.second_holder_gender!.isNotEmpty) {
            selectedSecondHolderGender = uccData.second_holder_gender!;
          }

          // Load second holder father name from API
          if (uccData.secondHolderFatherName != null &&
              uccData.secondHolderFatherName!.isNotEmpty) {
            secondHolderFatherNameController.text =
                uccData.secondHolderFatherName!;
          }

          // Nominees (prefill if available)
          if (uccData.nominees != null && uccData.nominees!.isNotEmpty) {
            addedNominees =
                uccData.nominees!
                    .whereType<Map<String, dynamic>>()
                    .map(
                      (n) => NomineeData(
                        name: (n['name'] ?? '').toString(),
                        relation: (n['relation'] ?? '').toString(),
                        dateOfBirth: (n['dob'] ?? '').toString(),
                        idType: (n['id_type'] ?? 'Aadhaar Card').toString(),
                        aadhaar: (n['id_number'] ?? '').toString(),
                        email: (n['email'] ?? '').toString(),
                        mobile: (n['mobile'] ?? '').toString(),
                        shareAllocation: (n['percentage'] ?? '').toString(),
                        sameAsApplicantAddress:
                            (n['same_as_applicant_address'] ?? true) as bool,
                        address: (n['address'] ?? '').toString(),
                        city: (n['city'] ?? '').toString(),
                        state: (n['state'] ?? '').toString(),
                        country: (n['country'] ?? '').toString(),
                        pincode: (n['pincode'] ?? '').toString(),
                      ),
                    )
                    .toList();
          }
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error loading UCC data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If on nominee screen and editing/adding, cancel the edit/add mode
        if (currentScreenIndex == 5 && (isEditingNominee || isAddingNominee)) {
          _cancelEditNominee();
          return false; // Prevent default back navigation
        }

        // Handle system back button
        if (currentScreenIndex > 0) {
          // Go back to previous screen
          setState(() {
            currentScreenIndex--;
            currentStep = 1; // Reset step for previous screen
          });
          return false; // Prevent default back navigation
        } else {
          // If on first screen, allow exit
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _handleBack,
                child: const Icon(
                  Icons.chevron_left,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              AppText(
                _getScreenTitle(),
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                customColor: Colors.white,
              ),
              const Opacity(
                opacity: 0,
                child: Icon(Icons.chevron_left, size: 32),
              ),
            ],
          ),
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
                : Column(
                  children: [
                    _buildProgressIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildCurrentScreen(),
                      ),
                    ),
                    // _buildNextButton(),
                  ],
                ),
        bottomNavigationBar:
            _shouldShowNextButton() ? _buildNextButton() : null,
      ),
    );
  }

  String _getScreenTitle() {
    switch (currentScreenIndex) {
      case 0:
        return 'Confirm Your PAN';
      case 1:
        return 'Bank Account';
      case 2:
        return 'About You';
      case 3:
        return !isNotNRI ? 'Foreign Address' : 'Address';
      case 4:
        return 'Add Second Holder';
      case 5:
        return 'FATCA Declaration';
      case 6:
        return 'Add Nominee';
      case 7:
        return 'More About You';
      case 8:
        return 'Provide Your Signature';
      case 9:
        return 'Confirmation';
      default:
        return 'Confirm Your PAN';
    }
  }

  Widget _buildProgressIndicator() {
    return ProgressIndicatorWidget(
      currentStep: currentStep,
      currentScreenIndex: currentScreenIndex,
      totalSteps: totalSteps,
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentScreenIndex) {
      case 0:
        return SecondHolderScreen(
          nomineeNameController: secondHolderNameController,
          nomineeDobController: secondHolderDobController,
          fatherNameController: secondHolderFatherNameController,
          aadhaarController: secondHolderAadhaarController,
          emailController: secondHolderEmailController,
          mobileController: secondHolderMobileController,
          panController: secondHolderPanController,
          selectedRelation: selectedSecondHolderRelation,
          selectedRelationId: selectedSecondHolderRelationId,
          selectedIdType: selectedSecondHolderIdType,
          selectedOccupationId: selectedSecondHolderOccupation,
          selectedGender: selectedSecondHolderGender,
          isNRI: isSecondHolderNRI,
          sameAsApplicantAddress: sameAsApplicantAddressSecondHolder,
          onRelationChanged: (value) {
            setState(() {
              selectedSecondHolderRelation = value;
            });
          },
          onRelationIdChanged: (value) {
            setState(() {
              selectedSecondHolderRelationId = value;
            });
          },
          onIdTypeChanged: (value) {
            setState(() {
              selectedSecondHolderIdType = value;
            });
          },
          onOccupationSelected: (Datum occupation) {
            setState(() {
              selectedSecondHolderOccupation = occupation.id;
            });
          },
          onGenderChanged: (value) {
            setState(() {
              selectedSecondHolderGender = value;
            });
          },
          onNRIChanged: (value) {
            setState(() {
              isSecondHolderNRI = value;
            });
          },
          onAddressChanged: (value) {
            setState(() {
              sameAsApplicantAddressSecondHolder = value;
            });
          },
        );
      // return PANConfirmationScreen(
      //   panController: panController,
      //   nameController: nameController,
      //   dobController: dobController,
      //   fatherNameController: fatherNameController,
      //   emailController: emailController,
      //   selectedCountryCode: selectedCountryCode,
      //   selectedOccupationId: selectedOccupation,
      //   onCountrySelected: (Country country) {
      //     setState(() {
      //       selectedCountryCode = country.code;
      //     });
      //   },
      //   onOccupationSelected: (Datum occupation) {
      //     setState(() {
      //       selectedOccupation = occupation.id;
      //     });
      //   },
      //   isPanDataFromAPI: _isPanDataFromAPI,
      //   isNameDataFromAPI: _isNameDataFromAPI,
      // );
      case 1:
        return BankAccountScreen(
          key: _bankAccountKey,
          ifscController: ifscController,
          accountController: accountController,
          selectedAccountType: selectedAccountType,
          onAccountTypeChanged: (value) {
            setState(() {
              selectedAccountType = value;
            });
          },
        );
      case 2:
        return AboutYouScreen(
          fatherNameController: fatherNameController,
          motherNameController: motherNameController,
          spouseNameController: spouseNameController,
          selectedGender: selectedGender,
          selectedMaritalStatus: selectedMaritalStatus,
          selectedTaxStatus: selectedTaxStatus,
          onGenderChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
          onMaritalStatusChanged: (value) {
            setState(() {
              selectedMaritalStatus = value;
            });
          },
          onTaxStatusChanged: (TaxStatus value) {
            setState(() {
              selectedTaxStatus = value;
            });
          },
        );
      case 3:
        return ForeignAddressScreen(
          addressController: addressController,
          cityController: cityController,
          stateController: stateController,
          countryController: countryController,
          pincodeController: pincodeController,
          tinController: tinController,
          isNRI: !isNotNRI, // isNotNRI = false means user IS an NRI
        );
      case 4:
        return SecondHolderScreen(
          nomineeNameController: secondHolderNameController,
          nomineeDobController: secondHolderDobController,
          fatherNameController: secondHolderFatherNameController,
          aadhaarController: secondHolderAadhaarController,
          emailController: secondHolderEmailController,
          mobileController: secondHolderMobileController,
          panController: secondHolderPanController,
          selectedRelation: selectedSecondHolderRelation,
          selectedRelationId: selectedSecondHolderRelationId,
          selectedIdType: selectedSecondHolderIdType,
          selectedOccupationId: selectedSecondHolderOccupation,
          selectedGender: selectedSecondHolderGender,
          isNRI: isSecondHolderNRI,
          sameAsApplicantAddress: sameAsApplicantAddressSecondHolder,
          onRelationChanged: (value) {
            setState(() {
              selectedSecondHolderRelation = value;
            });
          },
          onRelationIdChanged: (value) {
            setState(() {
              selectedSecondHolderRelationId = value;
            });
          },
          onIdTypeChanged: (value) {
            setState(() {
              selectedSecondHolderIdType = value;
            });
          },
          onOccupationSelected: (Datum occupation) {
            setState(() {
              selectedSecondHolderOccupation = occupation.id;
            });
          },
          onGenderChanged: (value) {
            setState(() {
              selectedSecondHolderGender = value;
            });
          },
          onNRIChanged: (value) {
            setState(() {
              isSecondHolderNRI = value;
            });
          },
          onAddressChanged: (value) {
            setState(() {
              sameAsApplicantAddressSecondHolder = value;
            });
          },
        );
      case 5:
        // FATCA Screen - determine if secondary holder exists and is NRI
        bool hasSecondaryHolder =
            (secondHolderNameController.text.isNotEmpty ||
                secondHolderPanController.text.isNotEmpty) &&
            isSecondHolderNRI;
        return FatcaScreen(
          // Primary Holder
          primaryNameController: primaryFatcaNameController,
          primaryPlaceOfBirthController: primaryFatcaPlaceOfBirthController,
          primaryCountryController: primaryFatcaCountryController,
          primaryDobController: primaryFatcaDobController,
          primaryPanController: primaryFatcaPanController,
          primaryNetworthController: primaryFatcaNetworthController,
          primaryDateOfNetworthController: primaryFatcaDateOfNetworthController,
          primaryLogNameController: primaryFatcaLogNameController,
          primaryInvestorType: primaryFatcaInvestorType,
          primaryOccupationId: primaryFatcaOccupation,
          primaryCorporateServiceSector: primaryFatcaCorporateServiceSector,
          primaryWealthSource: primaryFatcaWealthSource,
          primaryIncomeSlab: primaryFatcaIncomeSlab,
          primaryCountryOfBirth: primaryFatcaCountryOfBirth,
          onPrimaryInvestorTypeChanged: (value) {
            setState(() {
              primaryFatcaInvestorType = value;
            });
          },
          onPrimaryOccupationSelected: (Datum occupation) {
            setState(() {
              primaryFatcaOccupation = occupation.id;
            });
          },
          onPrimaryCorporateServiceSectorChanged: (value) {
            setState(() {
              primaryFatcaCorporateServiceSector = value;
            });
          },
          onPrimaryWealthSourceChanged: (value) {
            setState(() {
              primaryFatcaWealthSource = value;
            });
          },
          onPrimaryIncomeSlabChanged: (value) {
            setState(() {
              primaryFatcaIncomeSlab = value;
            });
          },
          onPrimaryCountryOfBirthSelected: (Country country) {
            setState(() {
              primaryFatcaCountryOfBirth = country.code;
            });
          },
          primaryPoliticallyExposed: primaryFatcaPoliticallyExposed,
          onPrimaryPoliticallyExposedChanged: (value) {
            setState(() {
              primaryFatcaPoliticallyExposed = value;
            });
          },
          // Secondary Holder
          secondaryNameController: secondaryFatcaNameController,
          secondaryPlaceOfBirthController: secondaryFatcaPlaceOfBirthController,
          secondaryCountryController: secondaryFatcaCountryController,
          secondaryDobController: secondaryFatcaDobController,
          secondaryPanController: secondaryFatcaPanController,
          secondaryNetworthController: secondaryFatcaNetworthController,
          secondaryDateOfNetworthController:
              secondaryFatcaDateOfNetworthController,
          secondaryLogNameController: secondaryFatcaLogNameController,
          secondaryInvestorType: secondaryFatcaInvestorType,
          secondaryOccupationId: secondaryFatcaOccupation,
          secondaryCorporateServiceSector: secondaryFatcaCorporateServiceSector,
          secondaryWealthSource: secondaryFatcaWealthSource,
          secondaryIncomeSlab: secondaryFatcaIncomeSlab,
          secondaryCountryOfBirth: secondaryFatcaCountryOfBirth,
          onSecondaryInvestorTypeChanged: (value) {
            setState(() {
              secondaryFatcaInvestorType = value;
            });
          },
          onSecondaryOccupationSelected: (Datum occupation) {
            setState(() {
              secondaryFatcaOccupation = occupation.id;
            });
          },
          onSecondaryCorporateServiceSectorChanged: (value) {
            setState(() {
              secondaryFatcaCorporateServiceSector = value;
            });
          },
          onSecondaryWealthSourceChanged: (value) {
            setState(() {
              secondaryFatcaWealthSource = value;
            });
          },
          onSecondaryIncomeSlabChanged: (value) {
            setState(() {
              secondaryFatcaIncomeSlab = value;
            });
          },
          onSecondaryCountryOfBirthSelected: (Country country) {
            setState(() {
              secondaryFatcaCountryOfBirth = country.code;
            });
          },
          secondaryPoliticallyExposed: secondaryFatcaPoliticallyExposed,
          onSecondaryPoliticallyExposedChanged: (value) {
            setState(() {
              secondaryFatcaPoliticallyExposed = value;
            });
          },
          hasSecondaryHolder: hasSecondaryHolder,
        );
      case 6:
        // Prefill share allocation defaults when adding a new nominee or when first landing on screen with no nominees
        if (!isEditingNominee && (isAddingNominee || addedNominees.isEmpty)) {
          if (addedNominees.isEmpty &&
              (shareAllocationController.text.isEmpty)) {
            shareAllocationController.text = '100';
          } else if (addedNominees.length == 1 &&
              (shareAllocationController.text.isEmpty)) {
            shareAllocationController.text = '50';
          }
        }
        return AddNomineeScreen(
          nomineeNameController: nomineeNameController,
          nomineeDobController: nomineeDobController,
          aadhaarController: aadhaarController,
          emailController: nomineeEmailController,
          mobileController: nomineeMobileController,
          shareAllocationController: shareAllocationController,
          nomineeAddressController: nomineeAddressController,
          nomineeCityController: nomineeCityController,
          nomineeStateController: nomineeStateController,
          nomineeCountryController: nomineeCountryController,
          nomineePincodeController: nomineePincodeController,
          selectedRelation: selectedRelation,
          selectedRelationId: selectedRelationId,
          selectedIdType: selectedIdType,
          sameAsApplicantAddress: sameAsApplicantAddress,
          addedNominees: addedNominees,
          onRelationChanged: (value) {
            setState(() {
              selectedRelation = value;
            });
          },
          onRelationIdChanged: (value) {
            setState(() {
              selectedRelationId = value;
            });
          },
          onIdTypeChanged: (value) {
            setState(() {
              selectedIdType = value;
            });
          },
          onAddressChanged: (value) {
            setState(() {
              sameAsApplicantAddress = value;
            });
          },
          onAddAnotherNominee: _startAddingNominee,
          onSaveNominee: _addNominee,
          onRemoveNominee: _removeNominee,
          onEditNominee: _editNominee,
          onCancel: _cancelEditNominee,
          isEditMode: isEditingNominee,
          showInputForm:
              isAddingNominee || isEditingNominee || addedNominees.isEmpty,
        );
      case 7:
        return IncomeEmploymentScreen(
          selectedAnnualIncome: selectedAnnualIncome,
          selectedOccupation: selectedOccupation,
          onAnnualIncomeChanged: (value) {
            setState(() {
              selectedAnnualIncome = value;
            });
          },
          onOccupationChanged: (value) {
            setState(() {
              selectedOccupation = value;
            });
          },
        );
      case 8:
        return SignatureScreen(
          onSignatureCaptured: (
            String base64Signature,
            Uint8List imageBytes,
          ) async {
            // Store signature and move to confirmation screen - NO API submission yet
            AppLogger.info(
              'Signature captured in journey - Base64 length: ${base64Signature.length}, Image size: ${imageBytes.length} bytes',
              tag: 'StartJourney',
            );

            setState(() {
              capturedSignatureBase64 = base64Signature;
              capturedSignature = imageBytes;
              currentScreenIndex = 9; // Move to confirmation screen
            });

            AppLogger.info(
              'Navigating to confirmation screen - Screen index: $currentScreenIndex',
              tag: 'StartJourney',
            );
          },
          onSignatureCleared: () {
            AppLogger.info('Signature cleared', tag: 'StartJourney');
          },
        );
      case 9:
        // Only show confirmation screen if signature exists
        if (capturedSignature != null && capturedSignatureBase64 != null) {
          AppLogger.info(
            'Showing confirmation screen - Base64 length: ${capturedSignatureBase64!.length}, Image size: ${capturedSignature!.length} bytes',
            tag: 'StartJourney',
          );

          return SignatureConfirmationScreen(
            signatureBase64: capturedSignatureBase64!,
            signatureBytes: capturedSignature!,
            onConfirm: (String signatureBase64) async {
              // Receive base64 signature and submit to API (FINAL SUBMIT)
              AppLogger.info(
                'Final signature submission - Base64 length: ${signatureBase64.length} characters',
                tag: 'StartJourney',
              );

              // Submit form data with signature to API (final submit)
              final response = await _submitCurrentFormData(
                isFinalSubmit: true,
              );

              if (mounted) {
                // Check if API response is successful
                if (response != null && response.data != null) {
                  AppLogger.info(
                    'Form submitted successfully - Navigating to success screen',
                    tag: 'StartJourney',
                  );

                  // Navigate to success screen on successful API response
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SuccessScreen(
                            title: 'SUCCESS',
                            message: 'You are ready to invest',
                            buttonText: 'EXPLORE MUTUAL FUNDS',
                            onButtonPressed: () {
                              // Pop twice to go back to the screen before the journey
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                    ),
                  );
                } else {
                  // Show error message if API failed
                  AppLogger.error(
                    'Form submission failed - Response: ${response?.message ?? "No response"}',
                    tag: 'StartJourney',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response?.message ??
                            'Failed to submit form. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            onClear: () {
              // Go back to signature screen and clear
              AppLogger.info(
                'Clearing signature and returning to signature screen',
                tag: 'StartJourney',
              );
              setState(() {
                capturedSignature = null;
                capturedSignatureBase64 = null;
                currentScreenIndex = 7;
              });
            },
          );
        } else {
          // If no signature, redirect to signature screen
          AppLogger.warning(
            'No signature found, redirecting to signature screen',
            tag: 'StartJourney',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              currentScreenIndex = 7;
            });
          });
          return Container(); // Temporary placeholder
        }
      default:
        return PANConfirmationScreen(
          panController: panController,
          nameController: nameController,
          dobController: dobController,
          fatherNameController: fatherNameController,
          emailController: emailController,
          selectedCountryCode: selectedCountryCode,
          selectedOccupationId: selectedOccupation,
          onCountrySelected: (Country country) {
            setState(() {
              selectedCountryCode = country.code;
            });
          },
          onOccupationSelected: (Datum occupation) {
            setState(() {
              selectedOccupation = occupation.id;
            });
          },
          isPanDataFromAPI: _isPanDataFromAPI,
          isNameDataFromAPI: _isNameDataFromAPI,
        );
    }
  }

  bool _shouldShowNextButton() {
    // Hide Next button for signature screens (8 and 9) as they have their own submit buttons
    if (currentScreenIndex == 8 || currentScreenIndex == 9) {
      return false;
    }

    // Always show Next button on nominee screen (it will act as Save/Next based on state)
    return true;
  }

  String _getNextButtonText() {
    // On nominee screen (6), show different text based on state
    if (currentScreenIndex == 6) {
      if (isAddingNominee || isEditingNominee) {
        return isEditingNominee ? 'UPDATE' : 'SAVE';
      } else if (addedNominees.isNotEmpty) {
        return 'NEXT';
      } else {
        // First time on nominee screen with no nominees - show SAVE
        return 'SAVE';
      }
    }
    return 'NEXT';
  }

  bool _isNomineeFormValid() {
    bool basicFieldsValid =
        nomineeNameController.text.trim().isNotEmpty &&
        nomineeDobController.text.trim().isNotEmpty &&
        aadhaarController.text.trim().isNotEmpty &&
        nomineeEmailController.text.trim().isNotEmpty &&
        nomineeMobileController.text.trim().isNotEmpty &&
        shareAllocationController.text.trim().isNotEmpty;

    // If same as applicant is unchecked, address fields are also required
    if (!sameAsApplicantAddress) {
      return basicFieldsValid &&
          nomineeAddressController.text.trim().isNotEmpty &&
          nomineeCityController.text.trim().isNotEmpty &&
          nomineeStateController.text.trim().isNotEmpty &&
          nomineeCountryController.text.trim().isNotEmpty &&
          nomineePincodeController.text.trim().isNotEmpty;
    }

    return basicFieldsValid;
  }

  Widget _buildNextButton() {
    // Determine if button should be disabled on nominee screen
    bool isDisabled = _isLoading;
    if (currentScreenIndex == 6) {
      // If adding/editing nominee OR no nominees added yet, disable if form is invalid
      if (isAddingNominee || isEditingNominee || addedNominees.isEmpty) {
        isDisabled = _isLoading || !_isNomineeFormValid();
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child:
          currentScreenIndex ==
                  4 // Secondary Holder screen
              ? Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'SKIP',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      onPressed:
                          _isLoading
                              ? () {}
                              : _handleNext, // Skip to next screen
                      isLoading: _isLoading,
                      isDisabled: _isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: 'NEXT',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed: _isLoading ? () {} : _handleNext,
                      isLoading: _isLoading,
                      isDisabled: _isLoading,
                    ),
                  ),
                ],
              )
              : AppButton(
                isFullWidth: true,
                text: _getNextButtonText(),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: isDisabled ? () {} : _handleNext,
                isLoading: _isLoading,
                isDisabled: isDisabled,
              ),
    );
  }

  void _handleNext() async {
    // Special handling for nominee screen (6)
    if (currentScreenIndex == 6) {
      // If adding or editing nominee, OR if no nominees exist yet (first time), save it first
      if (isAddingNominee || isEditingNominee || addedNominees.isEmpty) {
        _addNominee();
        return; // Don't proceed to next screen yet
      }
      // If nominees exist and not adding/editing, proceed to next screen
    }

    // Validate current screen before proceeding
    final validationError = _validateCurrentScreen();

    if (validationError != null) {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Skip API submission for signature screen (screen 8) - it will be submitted from confirmation screen
    if (currentScreenIndex != 8) {
      // Submit current form data to UCC service
      await _submitCurrentFormData();
    }

    if (currentScreenIndex < 8) {
      setState(() {
        currentScreenIndex++;
        currentStep = 1; // Reset step for new screen
      });
    } else {
      // Handle final submission or navigation
      Navigator.pop(context);
    }
  }

  String? _validateCurrentScreen() {
    switch (currentScreenIndex) {
      case 0: // PAN Confirmation Screen
        if (panController.text.trim().isEmpty) {
          return 'Please enter your PAN number';
        }
        if (nameController.text.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (dobController.text.trim().isEmpty) {
          return 'Please enter your date of birth';
        }
        if (fatherNameController.text.trim().isEmpty) {
          return 'Please enter your father\'s name';
        }
        if (emailController.text.trim().isEmpty) {
          return 'Please enter your email';
        }
        // No validation needed - user can select either Yes or No for NRI
        break;

      case 1: // Bank Account Screen
        // Use the BankAccountScreen's validation method
        if (_bankAccountKey.currentState != null) {
          if (!_bankAccountKey.currentState!.isFormValid()) {
            // Check specific errors for better messages
            final ifscCode = ifscController.text.trim();
            final accountNumber = accountController.text.trim();

            if (ifscCode.isEmpty) {
              return 'Please enter IFSC code';
            }
            if (ifscCode.length != 11) {
              return 'IFSC code must be 11 characters';
            }
            if (_bankAccountKey.currentState!.isIfscValid != true) {
              return 'Please wait for IFSC validation or enter a valid IFSC code';
            }
            if (accountNumber.isEmpty) {
              return 'Please enter bank account number';
            }
            if (accountNumber.length < 9) {
              return 'Account number must be at least 9 digits';
            }
            if (accountNumber.length > 20) {
              return 'Account number must not exceed 20 digits';
            }
            if (selectedAccountType.isEmpty) {
              return 'Please select account type';
            }
            return 'Please complete all bank details correctly';
          }
        } else {
          // Fallback validation if key is not available
          if (ifscController.text.trim().isEmpty) {
            return 'Please enter IFSC code';
          }
          if (accountController.text.trim().isEmpty) {
            return 'Please enter bank account number';
          }
          if (selectedAccountType.isEmpty) {
            return 'Please select account type';
          }
        }
        break;

      case 2: // About You Screen
        // Only validate visible fields (Gender and Marital Status radio buttons)
        // Spouse, Father, and Mother name fields are commented out in UI
        if (selectedGender.isEmpty) {
          return 'Please select your gender';
        }
        if (selectedMaritalStatus.isEmpty) {
          return 'Please select marital status';
        }
        break;

      case 3: // Address Screen
        if (addressController.text.trim().isEmpty) {
          return 'Please enter your address';
        }
        if (cityController.text.trim().isEmpty) {
          return 'Please enter city';
        }
        if (stateController.text.trim().isEmpty) {
          return 'Please enter state';
        }
        if (countryController.text.trim().isEmpty) {
          return 'Please enter country';
        }
        if (pincodeController.text.trim().isEmpty) {
          return 'Please enter pincode';
        }
        // Only validate TIN for NRI users
        if (!isNotNRI && tinController.text.trim().isEmpty) {
          return 'Please enter TIN (Tax Identification Number)';
        }
        break;

      case 4: // Second Holder Screen - CAN BE SKIPPED
        // Only validate if user has started filling the form
        if (secondHolderNameController.text.trim().isNotEmpty ||
            secondHolderDobController.text.trim().isNotEmpty ||
            secondHolderPanController.text.trim().isNotEmpty) {
          if (secondHolderNameController.text.trim().isEmpty) {
            return 'Please enter second holder name or skip this step';
          }
          if (secondHolderDobController.text.trim().isEmpty) {
            return 'Please enter second holder date of birth or skip this step';
          }
          if (secondHolderPanController.text.trim().isEmpty) {
            return 'Please enter second holder PAN or skip this step';
          }
          if (selectedSecondHolderRelationId.isEmpty) {
            return 'Please select relationship or skip this step';
          }
        }
        // If nothing is filled, allow skip
        break;

      case 5: // FATCA Screen - Optional validation based on filled fields
        // Only validate if user has started filling the form
        if (primaryFatcaNameController.text.trim().isNotEmpty ||
            primaryFatcaPanController.text.trim().isNotEmpty) {
          if (primaryFatcaNameController.text.trim().isEmpty) {
            return 'Please enter name for primary holder FATCA';
          }
          if (primaryFatcaPanController.text.trim().isEmpty) {
            return 'Please enter PAN for primary holder FATCA';
          }
        }
        // If nothing is filled, allow skip
        break;

      case 6: // Add Nominee Screen
        if (addedNominees.isEmpty) {
          return 'Please add at least one nominee';
        }
        // Validate total percentage equals 100
        int totalPercentage = 0;
        for (var nominee in addedNominees) {
          totalPercentage += int.tryParse(nominee.shareAllocation) ?? 0;
        }
        if (totalPercentage != 100) {
          return 'Total nominee share allocation must equal 100%';
        }
        break;

      case 7: // Income Employment Screen
        if (selectedAnnualIncome.isEmpty) {
          return 'Please select annual income';
        }
        if (selectedOccupation.isEmpty) {
          return 'Please select occupation';
        }
        break;

      case 8: // Signature Screen - Handled by its own button
        // Validation handled in signature screen itself
        break;

      case 9: // Confirmation Screen - Handled by its own button
        // Validation handled in confirmation screen itself
        break;
    }

    return null; // No validation errors
  }

  void _handleBack() {
    // If on nominee screen and editing/adding, cancel the edit/add mode
    if (currentScreenIndex == 6 && (isEditingNominee || isAddingNominee)) {
      _cancelEditNominee();
      return;
    }

    if (currentScreenIndex > 0) {
      // Go back to previous screen
      setState(() {
        currentScreenIndex--;
        currentStep = 1; // Reset step for previous screen
      });
    } else {
      // If on first screen, exit the journey
      Get.back();
    }
  }

  Future<UccResponse?> _submitCurrentFormData({
    bool isFinalSubmit = false,
  }) async {
    try {
      AppLogger.info(
        '=== STARTING FORM SUBMISSION ===',
        tag: 'StartJourney-Submit',
      );
      AppLogger.info(
        'Is Final Submit: $isFinalSubmit',
        tag: 'StartJourney-Submit',
      );
      AppLogger.info(
        'Current Screen Index: $currentScreenIndex',
        tag: 'StartJourney-Submit',
      );

      // Collect current form data
      final formData = _collectFormData(isFinalSubmit: isFinalSubmit);

      // Log if signature is included in form data
      if (formData.containsKey('signature')) {
        final sig = formData['signature'] as String?;
        if (sig != null) {
          AppLogger.info(
            'Signature included in formData - Length: ${sig.length} characters',
            tag: 'StartJourney-Submit',
          );
          AppLogger.info(
            'Signature preview: ${sig.substring(0, sig.length > 100 ? 100 : sig.length)}...',
            tag: 'StartJourney-Submit',
          );
        } else {
          AppLogger.warning(
            'Signature key exists but value is null',
            tag: 'StartJourney-Submit',
          );
        }
      } else {
        AppLogger.warning(
          'No signature key in formData',
          tag: 'StartJourney-Submit',
        );
      }

      // Submit to UCC service
      AppLogger.info(
        'Submitting UCC registration with full data: ${jsonEncode(formData)}',
        tag: 'StartJourney-Submit',
      );

      final response = await _uccService.registerUcc(
        uccData: formData,
        onLoading: (loading) {
          setState(() {
            _isLoading = loading;
          });
        },
      );

      // Log response
      AppLogger.info(
        '=== FORM SUBMISSION RESPONSE ===',
        tag: 'StartJourney-Submit',
      );
      AppLogger.info(
        'Response Message: ${response.message}',
        tag: 'StartJourney-Submit',
      );
      AppLogger.info(
        'Response Data: ${response.data != null ? "Available" : "Null"}',
        tag: 'StartJourney-Submit',
      );

      // Handle response
      if (response.data != null) {
        // Update form with any new data from response
        _updateFormFromResponse(response.data!);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error submitting form data: $e',
        tag: 'StartJourney-Submit',
        error: e,
        stackTrace: stackTrace,
      );
      // Return null on error
      return null;
    }
  }

  Map<String, dynamic> _collectFormData({bool isFinalSubmit = false}) {
    // Prepare nominees data
    List<Map<String, dynamic>>? nomineesData;
    if (addedNominees.isNotEmpty) {
      nomineesData =
          addedNominees
              .map<Map<String, dynamic>>(
                (nominee) => <String, dynamic>{
                  'name': nominee.name,
                  'relation': nominee.relation,
                  'dob': nominee.dateOfBirth,
                  'id_type': _getIdTypeCode(
                    nominee.idType,
                  ), // Map to API code: PAN=C, Driving Licence=E, Aadhaar=G
                  'id_number': nominee.aadhaar,
                  'email': nominee.email,
                  'mobile': nominee.mobile,
                  'percentage': nominee.shareAllocation,
                  'same_as_applicant_address': nominee.sameAsApplicantAddress,
                  if (!nominee.sameAsApplicantAddress) ...{
                    'address': nominee.address,
                    'city': nominee.city,
                    'state': nominee.state,
                    'country': nominee.country,
                    'pincode': nominee.pincode,
                  },
                },
              )
              .toList();
    }

    // Only include the nominee currently being edited if ALL required fields are complete
    final hasCompleteInProgressNominee =
        (nomineeNameController.text.trim().isNotEmpty &&
            nomineeDobController.text.trim().isNotEmpty &&
            aadhaarController.text.trim().isNotEmpty &&
            nomineeEmailController.text.trim().isNotEmpty &&
            nomineeMobileController.text.trim().isNotEmpty &&
            shareAllocationController.text.trim().isNotEmpty &&
            // If same as applicant is unchecked, address fields are also required
            (sameAsApplicantAddress ||
                (nomineeAddressController.text.trim().isNotEmpty &&
                    nomineeCityController.text.trim().isNotEmpty &&
                    nomineeStateController.text.trim().isNotEmpty &&
                    nomineeCountryController.text.trim().isNotEmpty &&
                    nomineePincodeController.text.trim().isNotEmpty)));

    if (hasCompleteInProgressNominee) {
      (nomineesData ??= <Map<String, dynamic>>[]).add(<String, dynamic>{
        'name': nomineeNameController.text,
        'relation': selectedRelation,
        'dob': nomineeDobController.text,
        'id_type': _getIdTypeCode(
          selectedIdType,
        ), // Map to API code: PAN=C, Driving Licence=E, Aadhaar=G
        'id_number': aadhaarController.text,
        'email': nomineeEmailController.text,
        'mobile': nomineeMobileController.text,
        'percentage': shareAllocationController.text,
        'same_as_applicant_address': sameAsApplicantAddress,
        if (!sameAsApplicantAddress) ...{
          'address': nomineeAddressController.text,
          'city': nomineeCityController.text,
          'state': nomineeStateController.text,
          'country': nomineeCountryController.text,
          'pincode': nomineePincodeController.text,
        },
      });
    }

    // Use pre-generated base64 signature if available
    String? signatureBase64 = capturedSignatureBase64;
    if (signatureBase64 != null) {
      final fileSize =
          capturedSignature != null
              ? ImageCompressionHelper.calculateFileSizeInKB(capturedSignature!)
              : 0;

      AppLogger.info(
        '=== SIGNATURE DATA FOR API ===',
        tag: 'StartJourney-Signature',
      );
      AppLogger.info(
        'Signature Base64 Length: ${signatureBase64.length} characters',
        tag: 'StartJourney-Signature',
      );
      AppLogger.info(
        'File Size (KB): $fileSize KB (multiple of 1024)',
        tag: 'StartJourney-Signature',
      );
      AppLogger.info('File Name: signature.jpg', tag: 'StartJourney-Signature');
      AppLogger.info(
        'Base64 Preview (first 100 chars): ${signatureBase64.substring(0, signatureBase64.length > 100 ? 100 : signatureBase64.length)}...',
        tag: 'StartJourney-Signature',
      );
      AppLogger.info(
        'Is Final Submit: $isFinalSubmit',
        tag: 'StartJourney-Signature',
      );
    } else {
      AppLogger.warning(
        'No signature available for submission (capturedSignatureBase64 is null)',
        tag: 'StartJourney-Signature',
      );
    }

    return <String, dynamic>{
      // PAN and basic info
      if (panController.text.isNotEmpty) 'pan_number': panController.text,
      if (nameController.text.isNotEmpty) 'pan_name': nameController.text,
      if (dobController.text.isNotEmpty) 'dob': dobController.text,
      if (emailController.text.isNotEmpty) 'email': emailController.text,
      if (fatherNameController.text.isNotEmpty)
        'primaryFatherName': fatherNameController.text,

      // Bank details
      if (ifscController.text.isNotEmpty) 'ifsc_code': ifscController.text,
      if (accountController.text.isNotEmpty)
        'bank_account_number': accountController.text,
      if (selectedAccountType.isNotEmpty)
        'bank_account_type': selectedAccountType,

      // Personal details
      if (selectedGender.isNotEmpty) 'gender': selectedGender,
      if (selectedMaritalStatus.isNotEmpty)
        'marital_status': selectedMaritalStatus,
      if (selectedOccupation.isNotEmpty) 'primaryOccCode': selectedOccupation,

      // Tax status code
      'taxCode': selectedTaxStatus.taxCode,
      'commMode': 'E',

      // Holding nature and KYC type
      'holdingNature': 'AS',
      'primaryKycType': 'K',
      'primaryInvestorType': 'Individual',
      'primaryDataSource': 'E',
      'primaryTaxIdType': 'pan',
      'secondHolderTaxIdType': 'pan',
      'primaryIdentifierType': 'pan',
      'secondHolderIdentifierType': 'pan',
      "primaryAddressType": "1",
      "primaryAuthMode": "E",
      "rdmpIdcwPayMode": "04",
      "secondHolderAddressType": "1",
      "secondHolderAuthMode": "E",
      // Primary Tax Residency - dynamic values from FATCA
      if (primaryFatcaCountryOfBirth != null &&
          primaryFatcaCountryOfBirth!.isNotEmpty &&
          primaryFatcaPanController.text.isNotEmpty)
        "primaryTaxResidency": [
          {
            "country": primaryFatcaCountryOfBirth,
            "taxIdType": "C",
            "taxIdNumber": primaryFatcaPanController.text,
          },
        ],

      // Secondary Holder Tax Residency - dynamic values from FATCA
      if (secondaryFatcaCountryOfBirth != null &&
          secondaryFatcaCountryOfBirth!.isNotEmpty &&
          secondaryFatcaPanController.text.isNotEmpty)
        "secondHolderTaxResidency": [
          {
            "country": secondaryFatcaCountryOfBirth,
            "taxIdType": "C",
            "taxIdNumber": secondaryFatcaPanController.text,
          },
        ],
      // FATCA Primary Holder Details
      if (primaryFatcaNameController.text.isNotEmpty)
        'primaryFatcaName': primaryFatcaNameController.text,
      if (primaryFatcaDobController.text.isNotEmpty)
        'primaryFatcaDob': primaryFatcaDobController.text,
      if (primaryFatcaOccupation != null && primaryFatcaOccupation!.isNotEmpty)
        'primaryFatcaOccCode': primaryFatcaOccupation,
      if (primaryFatcaPanController.text.isNotEmpty)
        'primaryIdentifierNumber': primaryFatcaPanController.text,
      if (primaryFatcaLogNameController.text.isNotEmpty)
        'primaryLogName': primaryFatcaLogNameController.text,
      if (primaryFatcaWealthSource != null &&
          primaryFatcaWealthSource!.isNotEmpty)
        'primaryWealthSource': _getWealthSourceCode(primaryFatcaWealthSource!),
      if (primaryFatcaIncomeSlab != null && primaryFatcaIncomeSlab!.isNotEmpty)
        'primaryIncomeSlab': _getIncomeSlabCode(primaryFatcaIncomeSlab!),
      if (primaryFatcaNetworthController.text.isNotEmpty)
        'primaryNetWorth': primaryFatcaNetworthController.text,
      if (primaryFatcaDateOfNetworthController.text.isNotEmpty)
        'primaryDateOfNetWorth': primaryFatcaDateOfNetworthController.text,
      if (primaryFatcaPoliticallyExposed != null &&
          primaryFatcaPoliticallyExposed!.isNotEmpty)
        'primaryPoliticallyExposed': _getPoliticallyExposedCode(
          primaryFatcaPoliticallyExposed!,
        ),

      // FATCA Secondary Holder Details
      if (secondaryFatcaNameController.text.isNotEmpty)
        'secondaryHolderFatcaName': secondaryFatcaNameController.text,
      if (secondaryFatcaDobController.text.isNotEmpty)
        'secondaryHolderFatcaDob': secondaryFatcaDobController.text,
      if (secondaryFatcaOccupation != null &&
          secondaryFatcaOccupation!.isNotEmpty)
        'secondaryHolderFatcaOccCode': secondaryFatcaOccupation,
      if (secondaryFatcaPanController.text.isNotEmpty)
        'secondHolderIdentifierNumber': secondaryFatcaPanController.text,
      if (secondaryFatcaLogNameController.text.isNotEmpty)
        'secondHolderLogName': secondaryFatcaLogNameController.text,
      if (secondaryFatcaWealthSource != null &&
          secondaryFatcaWealthSource!.isNotEmpty)
        'secondHolderWealthSource': _getWealthSourceCode(
          secondaryFatcaWealthSource!,
        ),
      if (secondaryFatcaIncomeSlab != null &&
          secondaryFatcaIncomeSlab!.isNotEmpty)
        'secondHolderIncomeSlab': _getIncomeSlabCode(secondaryFatcaIncomeSlab!),
      if (secondaryFatcaNetworthController.text.isNotEmpty)
        'secondHolderNetWorth': secondaryFatcaNetworthController.text,
      if (secondaryFatcaDateOfNetworthController.text.isNotEmpty)
        'secondHolderDateOfNetWorth':
            secondaryFatcaDateOfNetworthController.text,
      if (secondaryFatcaPoliticallyExposed != null &&
          secondaryFatcaPoliticallyExposed!.isNotEmpty)
        'secondHolderPoliticallyExposed': _getPoliticallyExposedCode(
          secondaryFatcaPoliticallyExposed!,
        ),

      // FATCA Place of Birth and Country of Birth
      if (primaryFatcaPlaceOfBirthController.text.isNotEmpty)
        'primaryPlaceOfBirth': primaryFatcaPlaceOfBirthController.text,
      if (primaryFatcaCountryOfBirth != null &&
          primaryFatcaCountryOfBirth!.isNotEmpty)
        'primaryCountryOfBirth': primaryFatcaCountryOfBirth,
      if (secondaryFatcaPlaceOfBirthController.text.isNotEmpty)
        'secondHolderPlaceOfBirth': secondaryFatcaPlaceOfBirthController.text,
      if (secondaryFatcaCountryOfBirth != null &&
          secondaryFatcaCountryOfBirth!.isNotEmpty)
        'secondHolderCountryOfBirth': secondaryFatcaCountryOfBirth,

      // Address details
      if (addressController.text.isNotEmpty) 'address': addressController.text,
      if (cityController.text.isNotEmpty) 'city': cityController.text,
      if (stateController.text.isNotEmpty) 'state': stateController.text,
      if (countryController.text.isNotEmpty) 'country': countryController.text,
      if (pincodeController.text.isNotEmpty) 'pincode': pincodeController.text,
      // Only send TIN for NRI users
      if (!isNotNRI && tinController.text.isNotEmpty)
        'tin': tinController.text.replaceAll(' ', ''),

      // Second holder details - only include if user has provided second holder information
      if (secondHolderNameController.text.isNotEmpty)
        'second_holder_first_name': secondHolderNameController.text,
      if (secondHolderDobController.text.isNotEmpty)
        'second_holder_dob': secondHolderDobController.text,
      if (secondHolderPanController.text.isNotEmpty)
        'second_holder_pan': secondHolderPanController.text,
      if (selectedSecondHolderRelationId.isNotEmpty &&
          secondHolderNameController.text.isNotEmpty)
        'second_holder_relationship': selectedSecondHolderRelationId,
      if (selectedSecondHolderGender.isNotEmpty)
        'second_holder_gender': selectedSecondHolderGender,
      if (secondHolderFatherNameController.text.isNotEmpty)
        'secondHolderFatherName': secondHolderFatherNameController.text,
      if (secondHolderEmailController.text.isNotEmpty)
        'second_holder_email': secondHolderEmailController.text,
      if (secondHolderMobileController.text.isNotEmpty)
        'second_holder_mobile': secondHolderMobileController.text,

      // Nominees
      if (nomineesData != null && nomineesData.isNotEmpty)
        'nominees': nomineesData,

      // Signature as pure base64 string with file_size and file_name
      if (signatureBase64 != null) 'signature': signatureBase64,
      if (signatureBase64 != null && capturedSignature != null)
        'file_size': ImageCompressionHelper.calculateFileSizeInKB(
          capturedSignature!,
        ),
      if (signatureBase64 != null) 'file_name': 'signature.jpg',

      // Final submit flag - true when submitting with signature
      if (isFinalSubmit) 'final_submit': true,

      // Country ISO code
      'country_iso_code': selectedCountryCode,

      // Current page tracking
      'current_page': currentScreenIndex,
    };
  }

  void _updateFormFromResponse(Data uccData) {
    setState(() {
      // Update any fields that came back from the API
      if (uccData.panNumber != null && uccData.panNumber!.isNotEmpty) {
        panController.text = uccData.panNumber!;
      }
      if (uccData.panName != null && uccData.panName!.isNotEmpty) {
        nameController.text = uccData.panName!;
      }
      if (uccData.dob != null && uccData.dob!.isNotEmpty) {
        dobController.text = uccData.dob!;
      }
      if (uccData.email != null && uccData.email!.isNotEmpty) {
        emailController.text = uccData.email!;
      }
      if (uccData.ifscCode != null && uccData.ifscCode!.isNotEmpty) {
        ifscController.text = uccData.ifscCode!;
      }
      if (uccData.bankAccountNumber != null &&
          uccData.bankAccountNumber!.isNotEmpty) {
        accountController.text = uccData.bankAccountNumber!;
      }
      if (uccData.bankAccountType != null &&
          uccData.bankAccountType!.isNotEmpty) {
        selectedAccountType = uccData.bankAccountType!;
      }
      if (uccData.gender != null && uccData.gender!.isNotEmpty) {
        selectedGender = uccData.gender!;
      }
      if (uccData.maritalStatus != null && uccData.maritalStatus!.isNotEmpty) {
        selectedMaritalStatus = uccData.maritalStatus!;
      }
      // Load occupation from primaryOccCode if available, fallback to occupation
      if (uccData.primaryOccCode != null &&
          uccData.primaryOccCode!.isNotEmpty) {
        selectedOccupation = uccData.primaryOccCode!;
      } else if (uccData.occupation != null && uccData.occupation!.isNotEmpty) {
        selectedOccupation = uccData.occupation!;
      }
      if (uccData.country_iso_code != null &&
          uccData.country_iso_code!.isNotEmpty) {
        selectedCountryCode = uccData.country_iso_code!;
      }
      // Tax status from taxCode
      if (uccData.taxCode != null && uccData.taxCode!.isNotEmpty) {
        final taxStatus = TaxStatus.fromTaxCode(uccData.taxCode);
        if (taxStatus != null) {
          selectedTaxStatus = taxStatus;
        }
      }
      // FATCA Name, DOB, and Occupation loading logic
      if (uccData.primaryFatcaName != null &&
          uccData.primaryFatcaName!.isNotEmpty) {
        primaryFatcaNameController.text = uccData.primaryFatcaName!;
      }
      if (uccData.primaryFatcaDob != null &&
          uccData.primaryFatcaDob!.isNotEmpty) {
        primaryFatcaDobController.text = uccData.primaryFatcaDob!;
      }
      if (uccData.primaryFatcaOccCode != null &&
          uccData.primaryFatcaOccCode!.isNotEmpty) {
        primaryFatcaOccupation = uccData.primaryFatcaOccCode!;
      }
      if (uccData.primaryIdentifierNumber != null &&
          uccData.primaryIdentifierNumber!.isNotEmpty) {
        primaryFatcaPanController.text = uccData.primaryIdentifierNumber!;
      }
      if (uccData.primaryWealthSource != null &&
          uccData.primaryWealthSource!.isNotEmpty) {
        primaryFatcaWealthSource = _getWealthSourceFromCode(
          uccData.primaryWealthSource!,
        );
      }
      if (uccData.primaryIncomeSlab != null &&
          uccData.primaryIncomeSlab!.isNotEmpty) {
        primaryFatcaIncomeSlab = _getIncomeSlabFromCode(
          uccData.primaryIncomeSlab!,
        );
      }
      if (uccData.primaryNetWorth != null &&
          uccData.primaryNetWorth!.isNotEmpty) {
        primaryFatcaNetworthController.text = uccData.primaryNetWorth!;
      }
      if (uccData.primaryDateOfNetWorth != null &&
          uccData.primaryDateOfNetWorth!.isNotEmpty) {
        primaryFatcaDateOfNetworthController.text =
            uccData.primaryDateOfNetWorth!;
      }
      if (uccData.primaryPoliticallyExposed != null &&
          uccData.primaryPoliticallyExposed!.isNotEmpty) {
        primaryFatcaPoliticallyExposed = _getPoliticallyExposedFromCode(
          uccData.primaryPoliticallyExposed!,
        );
      }

      // FATCA Secondary Holder Details (load from API if available)
      if (uccData.secondaryHolderFatcaName != null &&
          uccData.secondaryHolderFatcaName!.isNotEmpty) {
        secondaryFatcaNameController.text = uccData.secondaryHolderFatcaName!;
      }
      if (uccData.secondaryHolderFatcaDob != null &&
          uccData.secondaryHolderFatcaDob!.isNotEmpty) {
        secondaryFatcaDobController.text = uccData.secondaryHolderFatcaDob!;
      }
      if (uccData.secondaryHolderFatcaOccCode != null &&
          uccData.secondaryHolderFatcaOccCode!.isNotEmpty) {
        secondaryFatcaOccupation = uccData.secondaryHolderFatcaOccCode!;
      }
      if (uccData.secondHolderIdentifierNumber != null &&
          uccData.secondHolderIdentifierNumber!.isNotEmpty) {
        secondaryFatcaPanController.text =
            uccData.secondHolderIdentifierNumber!;
      }
      if (uccData.secondHolderWealthSource != null &&
          uccData.secondHolderWealthSource!.isNotEmpty) {
        secondaryFatcaWealthSource = _getWealthSourceFromCode(
          uccData.secondHolderWealthSource!,
        );
      }
      if (uccData.secondHolderIncomeSlab != null &&
          uccData.secondHolderIncomeSlab!.isNotEmpty) {
        secondaryFatcaIncomeSlab = _getIncomeSlabFromCode(
          uccData.secondHolderIncomeSlab!,
        );
      }
      if (uccData.secondHolderNetWorth != null &&
          uccData.secondHolderNetWorth!.isNotEmpty) {
        secondaryFatcaNetworthController.text = uccData.secondHolderNetWorth!;
      }
      if (uccData.secondHolderDateOfNetWorth != null &&
          uccData.secondHolderDateOfNetWorth!.isNotEmpty) {
        secondaryFatcaDateOfNetworthController.text =
            uccData.secondHolderDateOfNetWorth!;
      }
      if (uccData.secondHolderPoliticallyExposed != null &&
          uccData.secondHolderPoliticallyExposed!.isNotEmpty) {
        secondaryFatcaPoliticallyExposed = _getPoliticallyExposedFromCode(
          uccData.secondHolderPoliticallyExposed!,
        );
      }
      // FATCA Log Names (load from API if available)
      if (uccData.primaryLogName != null &&
          uccData.primaryLogName!.isNotEmpty) {
        primaryFatcaLogNameController.text = uccData.primaryLogName!;
      }
      if (uccData.secondHolderLogName != null &&
          uccData.secondHolderLogName!.isNotEmpty) {
        secondaryFatcaLogNameController.text = uccData.secondHolderLogName!;
      }
      // FATCA Place of Birth and Country of Birth (load from API if available)
      if (uccData.primaryPlaceOfBirth != null &&
          uccData.primaryPlaceOfBirth!.isNotEmpty) {
        primaryFatcaPlaceOfBirthController.text = uccData.primaryPlaceOfBirth!;
      }
      if (uccData.primaryCountryOfBirth != null &&
          uccData.primaryCountryOfBirth!.isNotEmpty) {
        primaryFatcaCountryOfBirth = uccData.primaryCountryOfBirth!;
      }
      if (uccData.secondHolderPlaceOfBirth != null &&
          uccData.secondHolderPlaceOfBirth!.isNotEmpty) {
        secondaryFatcaPlaceOfBirthController.text =
            uccData.secondHolderPlaceOfBirth!;
      }
      if (uccData.secondHolderCountryOfBirth != null &&
          uccData.secondHolderCountryOfBirth!.isNotEmpty) {
        secondaryFatcaCountryOfBirth = uccData.secondHolderCountryOfBirth!;
      }
      // Secondary holder details (prefill if available)
      if (uccData.secondaryHolder != null) {
        final sh = uccData.secondaryHolder!;
        if (sh.firstName != null && sh.firstName!.isNotEmpty) {
          secondHolderNameController.text = sh.firstName!;
        }
        if (sh.dob != null && sh.dob!.isNotEmpty) {
          secondHolderDobController.text = sh.dob!;
        }
        if (sh.pan != null && sh.pan!.isNotEmpty) {
          secondHolderPanController.text = sh.pan!;
        }
        if (sh.email != null && sh.email!.isNotEmpty) {
          secondHolderEmailController.text = sh.email!;
        }
        if (sh.mobile != null && sh.mobile!.isNotEmpty) {
          secondHolderMobileController.text = sh.mobile!;
        }
        if (sh.relationship != null && sh.relationship!.isNotEmpty) {
          selectedSecondHolderRelationId = sh.relationship!;
        }
      }

      // Load second holder gender from API
      if (uccData.second_holder_gender != null &&
          uccData.second_holder_gender!.isNotEmpty) {
        selectedSecondHolderGender = uccData.second_holder_gender!;
      }

      // Load second holder father name from API
      if (uccData.secondHolderFatherName != null &&
          uccData.secondHolderFatherName!.isNotEmpty) {
        secondHolderFatherNameController.text = uccData.secondHolderFatherName!;
      }

      // Nominees (prefill if available)
      if (uccData.nominees != null && uccData.nominees!.isNotEmpty) {
        addedNominees =
            uccData.nominees!
                .whereType<Map<String, dynamic>>()
                .map(
                  (n) => NomineeData(
                    name: (n['name'] ?? '').toString(),
                    relation: (n['relation'] ?? '').toString(),
                    dateOfBirth: (n['dob'] ?? '').toString(),
                    idType: (n['id_type'] ?? 'Aadhaar Card').toString(),
                    aadhaar: (n['id_number'] ?? '').toString(),
                    email: (n['email'] ?? '').toString(),
                    mobile: (n['mobile'] ?? '').toString(),
                    shareAllocation: (n['percentage'] ?? '').toString(),
                    sameAsApplicantAddress:
                        (n['same_as_applicant_address'] ?? true) as bool,
                    address: (n['address'] ?? '').toString(),
                    city: (n['city'] ?? '').toString(),
                    state: (n['state'] ?? '').toString(),
                    country: (n['country'] ?? '').toString(),
                    pincode: (n['pincode'] ?? '').toString(),
                  ),
                )
                .toList();
      }
    });
  }

  void _startAddingNominee() {
    // If form has data and is valid, save the current nominee first
    if (nomineeNameController.text.trim().isNotEmpty && _isNomineeFormValid()) {
      // Save the current nominee
      _addNominee();
      return; // _addNominee will clear the form and set isAddingNominee = false
    }

    // If form is partially filled but invalid, show error
    if (nomineeNameController.text.trim().isNotEmpty &&
        !_isNomineeFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required nominee fields before adding another',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // If form is empty or we're already adding, just show the form
    setState(() {
      isAddingNominee = true;
      // Clear any existing form data
      nomineeNameController.clear();
      nomineeDobController.clear();
      aadhaarController.clear();
      nomineeEmailController.clear();
      nomineeMobileController.clear();
      shareAllocationController.clear();
      nomineeAddressController.clear();
      nomineeCityController.clear();
      nomineeStateController.clear();
      nomineeCountryController.clear();
      nomineePincodeController.clear();
      selectedRelation = 'Father';
      selectedRelationId = '';
      selectedIdType = 'Aadhaar Card';
      sameAsApplicantAddress = true;

      // Redistribute shares immediately when adding nominee
      _redistributeShares();
    });
  }

  // Helper method to redistribute shares automatically
  void _redistributeShares() {
    final int nomineeCount =
        addedNominees.length + 1; // Including the one being added

    if (nomineeCount == 1) {
      // First nominee gets 100%, non-editable
      shareAllocationController.text = '100';
    } else if (nomineeCount == 2) {
      // Two nominees: 50% each, both editable
      shareAllocationController.text = '50';
      if (addedNominees.isNotEmpty) {
        final existing = addedNominees[0];
        addedNominees[0] = NomineeData(
          name: existing.name,
          relation: existing.relation,
          dateOfBirth: existing.dateOfBirth,
          idType: existing.idType,
          aadhaar: existing.aadhaar,
          email: existing.email,
          mobile: existing.mobile,
          shareAllocation: '50',
          sameAsApplicantAddress: existing.sameAsApplicantAddress,
          address: existing.address,
          city: existing.city,
          state: existing.state,
          country: existing.country,
          pincode: existing.pincode,
        );
      }
    } else if (nomineeCount == 3) {
      // Three nominees: distribute remaining percentage
      // Get current share from the form if user has entered it
      int currentShare = int.tryParse(shareAllocationController.text) ?? 0;

      if (currentShare == 0 || shareAllocationController.text.isEmpty) {
        // Auto-calculate: distribute evenly among all 3
        int totalExistingShare = 0;
        for (var nominee in addedNominees) {
          totalExistingShare += int.tryParse(nominee.shareAllocation) ?? 0;
        }

        // Calculate remaining share for the new nominee
        int remainingShare = 100 - totalExistingShare;
        shareAllocationController.text = remainingShare.toString();

        // If remaining is 0 or negative, distribute evenly
        if (remainingShare <= 0) {
          // Redistribute all 3 nominees to ~33% each
          shareAllocationController.text = '34';
          for (int i = 0; i < addedNominees.length; i++) {
            final existing = addedNominees[i];
            addedNominees[i] = NomineeData(
              name: existing.name,
              relation: existing.relation,
              dateOfBirth: existing.dateOfBirth,
              idType: existing.idType,
              aadhaar: existing.aadhaar,
              email: existing.email,
              mobile: existing.mobile,
              shareAllocation:
                  i == 0 ? '33' : '33', // First gets 33, others get 33
              sameAsApplicantAddress: existing.sameAsApplicantAddress,
              address: existing.address,
              city: existing.city,
              state: existing.state,
              country: existing.country,
              pincode: existing.pincode,
            );
          }
        }
      }
    }
  }

  void _addNominee() {
    AppLogger.info(
      '_addNominee called - addedNominees.length: ${addedNominees.length}, isEditingNominee: $isEditingNominee',
      tag: 'AddNominee',
    );

    // Limit to 3 nominees maximum
    if (addedNominees.length >= 3 && !isEditingNominee) {
      AppLogger.warning('Maximum nominees reached', tag: 'AddNominee');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 nominees allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate form before saving
    if (!_isNomineeFormValid()) {
      AppLogger.warning('Nominee form validation failed', tag: 'AddNominee');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required nominee fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate share allocation percentage
    int currentShare = int.tryParse(shareAllocationController.text) ?? 0;
    if (currentShare <= 0 || currentShare > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share allocation must be between 1% and 100%'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate total share allocation
    // Calculate total share including current nominee
    int totalShare = currentShare;
    for (var nominee in addedNominees) {
      totalShare += int.tryParse(nominee.shareAllocation) ?? 0;
    }

    if (!isEditingNominee) {
      // When adding a new nominee, check if total would exceed 100%
      if (totalShare > 100) {
        int availableShare = 100;
        for (var nominee in addedNominees) {
          availableShare -= int.tryParse(nominee.shareAllocation) ?? 0;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total share allocation cannot exceed 100%. Available: $availableShare%',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // For 3 nominees, ensure total equals exactly 100%
      if (addedNominees.length == 2 && totalShare != 100) {
        AppLogger.warning(
          'Share validation failed - Total: $totalShare%, Expected: 100%',
          tag: 'AddNominee',
        );
        AppLogger.info(
          'Current nominee share: $currentShare%, Existing nominees: ${addedNominees.map((n) => n.shareAllocation).join(", ")}',
          tag: 'AddNominee',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total share allocation must equal 100%. Current total: $totalShare%',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      AppLogger.info(
        'Share validation passed - Total: $totalShare%',
        tag: 'AddNominee',
      );
    } else {
      // When editing, validate that total will equal 100% after re-insertion
      // For 2 nominees total (1 in list + 1 being edited)
      if (addedNominees.length == 1 && totalShare != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total share allocation must equal 100%. Current total: $totalShare%',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      // For 3 nominees total (2 in list + 1 being edited)
      if (addedNominees.length == 2 && totalShare != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total share allocation must equal 100%. Current total: $totalShare%',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      AppLogger.info(
        'Edit validation passed - Total: $totalShare%',
        tag: 'AddNominee',
      );
    }

    if (nomineeNameController.text.isNotEmpty) {
      // Capture edit mode before resetting
      final bool wasEditing = isEditingNominee;

      // Apply default share logic: first nominee 100%, second nominee 50/50
      // Skip this logic when editing an existing nominee
      if (!isEditingNominee) {
        if (addedNominees.isEmpty) {
          if (shareAllocationController.text.isEmpty) {
            shareAllocationController.text = '100';
          }
        } else if (addedNominees.length == 1) {
          // Set current default to 50% if empty
          if (shareAllocationController.text.isEmpty) {
            shareAllocationController.text = '50';
          }
        }
      }

      final nominee = NomineeData(
        name: nomineeNameController.text,
        relation: selectedRelation,
        dateOfBirth: nomineeDobController.text,
        idType: selectedIdType,
        aadhaar: aadhaarController.text,
        email: nomineeEmailController.text,
        mobile: nomineeMobileController.text,
        shareAllocation: shareAllocationController.text,
        sameAsApplicantAddress: sameAsApplicantAddress,
        address: nomineeAddressController.text,
        city: nomineeCityController.text,
        state: nomineeStateController.text,
        country: nomineeCountryController.text,
        pincode: nomineePincodeController.text,
      );

      setState(() {
        // Update existing nominee's share when adding second nominee
        if (!wasEditing && addedNominees.length == 1) {
          final existing = addedNominees[0];
          addedNominees[0] = NomineeData(
            name: existing.name,
            relation: existing.relation,
            dateOfBirth: existing.dateOfBirth,
            idType: existing.idType,
            aadhaar: existing.aadhaar,
            email: existing.email,
            mobile: existing.mobile,
            shareAllocation: '50',
            sameAsApplicantAddress: existing.sameAsApplicantAddress,
            address: existing.address,
            city: existing.city,
            state: existing.state,
            country: existing.country,
            pincode: existing.pincode,
          );
        }

        // If editing, insert at original index; if adding, append to end
        if (wasEditing && _nomineeBeingEditedIndex != null) {
          addedNominees.insert(_nomineeBeingEditedIndex!, nominee);
        } else {
          addedNominees.add(nominee);
        }
        // Clear form fields
        nomineeNameController.clear();
        nomineeDobController.clear();
        aadhaarController.clear();
        nomineeEmailController.clear();
        nomineeMobileController.clear();
        shareAllocationController.clear();
        nomineeAddressController.clear();
        nomineeCityController.clear();
        nomineeStateController.clear();
        nomineeCountryController.clear();
        nomineePincodeController.clear();
        selectedRelation = 'Father';
        selectedRelationId = '';
        selectedIdType = 'Aadhaar Card';
        sameAsApplicantAddress = true;
        isEditingNominee = false; // Reset edit mode
        isAddingNominee = false; // Hide form after adding
        _nomineeBeingEdited = null; // Clear the stored nominee
        _nomineeBeingEditedIndex = null; // Clear the stored index
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Nominee updated successfully'
                : 'Nominee saved successfully',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Don't submit to API here - will be submitted when user clicks Next button
    }
  }

  void _removeNominee(int index) async {
    setState(() {
      addedNominees.removeAt(index);

      // Redistribute shares after removal
      if (addedNominees.length == 1) {
        // Only one nominee left, set to 100%
        final existing = addedNominees[0];
        addedNominees[0] = NomineeData(
          name: existing.name,
          relation: existing.relation,
          dateOfBirth: existing.dateOfBirth,
          idType: existing.idType,
          aadhaar: existing.aadhaar,
          email: existing.email,
          mobile: existing.mobile,
          shareAllocation: '100',
          sameAsApplicantAddress: existing.sameAsApplicantAddress,
          address: existing.address,
          city: existing.city,
          state: existing.state,
          country: existing.country,
          pincode: existing.pincode,
        );
      } else if (addedNominees.length == 2) {
        // Two nominees left, set both to 50%
        for (int i = 0; i < addedNominees.length; i++) {
          final existing = addedNominees[i];
          addedNominees[i] = NomineeData(
            name: existing.name,
            relation: existing.relation,
            dateOfBirth: existing.dateOfBirth,
            idType: existing.idType,
            aadhaar: existing.aadhaar,
            email: existing.email,
            mobile: existing.mobile,
            shareAllocation: '50',
            sameAsApplicantAddress: existing.sameAsApplicantAddress,
            address: existing.address,
            city: existing.city,
            state: existing.state,
            country: existing.country,
            pincode: existing.pincode,
          );
        }
      }
    });

    // Don't submit to API here - will be submitted when user clicks Next button

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nominee removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _editNominee(int index, NomineeData nominee) {
    setState(() {
      // Store the original nominee data and index for cancel functionality
      _nomineeBeingEdited = nominee;
      _nomineeBeingEditedIndex = index;

      // Load nominee data into form fields
      nomineeNameController.text = nominee.name;
      nomineeDobController.text = nominee.dateOfBirth;
      aadhaarController.text = nominee.aadhaar;
      nomineeEmailController.text = nominee.email;
      nomineeMobileController.text = nominee.mobile;
      shareAllocationController.text = nominee.shareAllocation;
      nomineeAddressController.text = nominee.address;
      nomineeCityController.text = nominee.city;
      nomineeStateController.text = nominee.state;
      nomineeCountryController.text = nominee.country;
      nomineePincodeController.text = nominee.pincode;
      selectedRelation = nominee.relation;
      selectedRelationId = ''; // Will be set by relation selector
      selectedIdType = nominee.idType; // Load the ID type
      sameAsApplicantAddress = nominee.sameAsApplicantAddress;
      isEditingNominee = true; // Set edit mode
      isAddingNominee = false; // Not adding, just editing

      // Remove the nominee from the list (it will be re-added when user saves)
      addedNominees.removeAt(index);
    });

    // Force a rebuild after the next frame to ensure validation runs with populated fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _cancelEditNominee() {
    setState(() {
      // Restore the original nominee if it was being edited
      if (_nomineeBeingEdited != null && _nomineeBeingEditedIndex != null) {
        addedNominees.insert(_nomineeBeingEditedIndex!, _nomineeBeingEdited!);
        _nomineeBeingEdited = null;
        _nomineeBeingEditedIndex = null;
      }

      // Reset shares based on number of nominees when canceling
      if (isAddingNominee) {
        if (addedNominees.length == 1) {
          // Reset first nominee's share to 100% if canceling while adding second nominee
          final existing = addedNominees[0];
          addedNominees[0] = NomineeData(
            name: existing.name,
            relation: existing.relation,
            dateOfBirth: existing.dateOfBirth,
            idType: existing.idType,
            aadhaar: existing.aadhaar,
            email: existing.email,
            mobile: existing.mobile,
            shareAllocation: '100',
            sameAsApplicantAddress: existing.sameAsApplicantAddress,
            address: existing.address,
            city: existing.city,
            state: existing.state,
            country: existing.country,
            pincode: existing.pincode,
          );
        } else if (addedNominees.length == 2) {
          // Reset both nominees to 50% if canceling while adding third nominee
          for (int i = 0; i < addedNominees.length; i++) {
            final existing = addedNominees[i];
            addedNominees[i] = NomineeData(
              name: existing.name,
              relation: existing.relation,
              dateOfBirth: existing.dateOfBirth,
              idType: existing.idType,
              aadhaar: existing.aadhaar,
              email: existing.email,
              mobile: existing.mobile,
              shareAllocation: '50',
              sameAsApplicantAddress: existing.sameAsApplicantAddress,
              address: existing.address,
              city: existing.city,
              state: existing.state,
              country: existing.country,
              pincode: existing.pincode,
            );
          }
        }
      }

      // Clear form fields
      nomineeNameController.clear();
      nomineeDobController.clear();
      aadhaarController.clear();
      nomineeEmailController.clear();
      nomineeMobileController.clear();
      shareAllocationController.clear();
      nomineeAddressController.clear();
      nomineeCityController.clear();
      nomineeStateController.clear();
      nomineeCountryController.clear();
      nomineePincodeController.clear();
      selectedRelation = 'Father';
      selectedRelationId = '';
      selectedIdType = 'Aadhaar Card';
      sameAsApplicantAddress = true;

      // Exit both edit and add modes
      isEditingNominee = false;
      isAddingNominee = false;
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    nomineeNameController.removeListener(_onNomineeFormChanged);
    nomineeDobController.removeListener(_onNomineeFormChanged);
    aadhaarController.removeListener(_onNomineeFormChanged);
    nomineeEmailController.removeListener(_onNomineeFormChanged);
    nomineeMobileController.removeListener(_onNomineeFormChanged);
    shareAllocationController.removeListener(_onShareAllocationChanged);
    nomineeAddressController.removeListener(_onNomineeFormChanged);
    nomineeCityController.removeListener(_onNomineeFormChanged);
    nomineeStateController.removeListener(_onNomineeFormChanged);
    nomineeCountryController.removeListener(_onNomineeFormChanged);
    nomineePincodeController.removeListener(_onNomineeFormChanged);

    panController.dispose();
    nameController.dispose();
    dobController.dispose();
    ifscController.dispose();
    accountController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    spouseNameController.dispose();
    nomineeNameController.dispose();
    nomineeDobController.dispose();
    aadhaarController.dispose();
    emailController.dispose();
    mobileController.dispose();
    shareAllocationController.dispose();
    secondHolderNameController.dispose();
    secondHolderDobController.dispose();
    secondHolderAadhaarController.dispose();
    secondHolderEmailController.dispose();
    secondHolderMobileController.dispose();
    secondHolderPanController.dispose();
    secondHolderFatherNameController.dispose();
    nomineeEmailController.dispose();
    nomineeMobileController.dispose();
    nomineeAddressController.dispose();
    nomineeCityController.dispose();
    nomineeStateController.dispose();
    nomineeCountryController.dispose();
    nomineePincodeController.dispose();
    super.dispose();
  }
}
