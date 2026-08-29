import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class _PanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase();
    
    // Ensure PAN format: 5 letters + 4 digits + 1 letter
    if (newText.length <= 10) {
      // Build valid text by filtering invalid characters
      String validText = '';
      for (int i = 0; i < newText.length; i++) {
        if (i < 5) {
          // First 5 positions should be letters
          if (RegExp(r'[A-Z]').hasMatch(newText[i])) {
            validText += newText[i];
          }
        } else if (i < 9) {
          // Next 4 positions should be digits
          if (RegExp(r'[0-9]').hasMatch(newText[i])) {
            validText += newText[i];
          }
        } else {
          // Last position should be a letter
          if (RegExp(r'[A-Z]').hasMatch(newText[i])) {
            validText += newText[i];
          }
        }
      }
      
      return TextEditingValue(
        text: validText,
        selection: TextSelection.collapsed(offset: validText.length),
      );
    }
    
    return oldValue;
  }
}

class FatcaData {
  final String name;
  final String placeOfBirth;
  final String country;
  final String investorType;
  final String dob;
  final String pan;
  final String occupation;
  final String corporateServiceSector;
  final String wealthSource;
  final String networth;
  final String incomeSlab;
  final String dateOfNetworth;

  FatcaData({
    required this.name,
    required this.placeOfBirth,
    required this.country,
    required this.investorType,
    required this.dob,
    required this.pan,
    required this.occupation,
    required this.corporateServiceSector,
    required this.wealthSource,
    required this.networth,
    required this.incomeSlab,
    required this.dateOfNetworth,
  });
}

class FatcaScreen extends StatefulWidget {
  // Primary Holder Controllers
  final TextEditingController primaryNameController;
  final TextEditingController primaryPlaceOfBirthController;
  final TextEditingController primaryCountryController;
  final TextEditingController primaryDobController;
  final TextEditingController primaryPanController;
  final TextEditingController primaryNetworthController;
  final TextEditingController primaryDateOfNetworthController;
  final TextEditingController primaryLogNameController;
  
  // Secondary Holder Controllers
  final TextEditingController secondaryNameController;
  final TextEditingController secondaryPlaceOfBirthController;
  final TextEditingController secondaryCountryController;
  final TextEditingController secondaryDobController;
  final TextEditingController secondaryPanController;
  final TextEditingController secondaryNetworthController;
  final TextEditingController secondaryDateOfNetworthController;
  final TextEditingController secondaryLogNameController;

  // Primary Holder Selections
  final String? primaryInvestorType;
  final String? primaryOccupationId;
  final String? primaryCorporateServiceSector;
  final String? primaryWealthSource;
  final String? primaryIncomeSlab;
  final String? primaryCountryOfBirth;
  final String? primaryPoliticallyExposed;

  // Secondary Holder Selections
  final String? secondaryInvestorType;
  final String? secondaryOccupationId;
  final String? secondaryCorporateServiceSector;
  final String? secondaryWealthSource;
  final String? secondaryIncomeSlab;
  final String? secondaryCountryOfBirth;
  final String? secondaryPoliticallyExposed;

  // Callbacks for Primary Holder
  final ValueChanged<String> onPrimaryInvestorTypeChanged;
  final Function(Datum) onPrimaryOccupationSelected;
  final ValueChanged<String> onPrimaryCorporateServiceSectorChanged;
  final ValueChanged<String> onPrimaryWealthSourceChanged;
  final ValueChanged<String> onPrimaryIncomeSlabChanged;
  final Function(Country) onPrimaryCountryOfBirthSelected;
  final ValueChanged<String> onPrimaryPoliticallyExposedChanged;

  // Callbacks for Secondary Holder
  final ValueChanged<String> onSecondaryInvestorTypeChanged;
  final Function(Datum) onSecondaryOccupationSelected;
  final ValueChanged<String> onSecondaryCorporateServiceSectorChanged;
  final ValueChanged<String> onSecondaryWealthSourceChanged;
  final ValueChanged<String> onSecondaryIncomeSlabChanged;
  final Function(Country) onSecondaryCountryOfBirthSelected;
  final ValueChanged<String> onSecondaryPoliticallyExposedChanged;

  // Flag to show/hide secondary holder section
  final bool hasSecondaryHolder;

  const FatcaScreen({
    super.key,
    // Primary Holder
    required this.primaryNameController,
    required this.primaryPlaceOfBirthController,
    required this.primaryCountryController,
    required this.primaryDobController,
    required this.primaryPanController,
    required this.primaryNetworthController,
    required this.primaryDateOfNetworthController,
    required this.primaryLogNameController,
    this.primaryInvestorType,
    this.primaryOccupationId,
    this.primaryCorporateServiceSector,
    this.primaryWealthSource,
    this.primaryIncomeSlab,
    this.primaryCountryOfBirth,
    this.primaryPoliticallyExposed,
    required this.onPrimaryInvestorTypeChanged,
    required this.onPrimaryOccupationSelected,
    required this.onPrimaryCorporateServiceSectorChanged,
    required this.onPrimaryWealthSourceChanged,
    required this.onPrimaryIncomeSlabChanged,
    required this.onPrimaryCountryOfBirthSelected,
    required this.onPrimaryPoliticallyExposedChanged,
    // Secondary Holder
    required this.secondaryNameController,
    required this.secondaryPlaceOfBirthController,
    required this.secondaryCountryController,
    required this.secondaryDobController,
    required this.secondaryPanController,
    required this.secondaryNetworthController,
    required this.secondaryDateOfNetworthController,
    required this.secondaryLogNameController,
    this.secondaryInvestorType,
    this.secondaryOccupationId,
    this.secondaryCorporateServiceSector,
    this.secondaryWealthSource,
    this.secondaryIncomeSlab,
    this.secondaryCountryOfBirth,
    this.secondaryPoliticallyExposed,
    required this.onSecondaryInvestorTypeChanged,
    required this.onSecondaryOccupationSelected,
    required this.onSecondaryCorporateServiceSectorChanged,
    required this.onSecondaryWealthSourceChanged,
    required this.onSecondaryIncomeSlabChanged,
    required this.onSecondaryCountryOfBirthSelected,
    required this.onSecondaryPoliticallyExposedChanged,
    this.hasSecondaryHolder = false,
  });

  @override
  State<FatcaScreen> createState() => _FatcaScreenState();
}

class _FatcaScreenState extends State<FatcaScreen> {
  @override
  void initState() {
    super.initState();
    _fetchIPAddressAndSetLogName();
  }

  Future<void> _fetchIPAddressAndSetLogName() async {
    try {
      // Fetch IP address from a public API
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ipAddress = data['ip'] ?? '0.0.0.0';
        
        // Format current date and time: "23-Nov-15;16:4"
        final now = DateTime.now();
        final dateFormat = DateFormat('dd-MMM-yy');
        final formattedDate = dateFormat.format(now);
        final formattedTime = '${now.hour}:${now.minute}';
        
        // Combine in the required format: "IP#Date;Time"
        final logName = '$ipAddress#$formattedDate;$formattedTime';
        
        // Set the value in both primary and secondary controllers
        widget.primaryLogNameController.text = logName;
        widget.secondaryLogNameController.text = logName;
      }
    } catch (e) {
      // Fallback to a default value if IP fetch fails
      final now = DateTime.now();
      final dateFormat = DateFormat('dd-MMM-yy');
      final formattedDate = dateFormat.format(now);
      final formattedTime = '${now.hour}:${now.minute}';
      final fallbackLogName = '0.0.0.0#$formattedDate;$formattedTime';
      widget.primaryLogNameController.text = fallbackLogName;
      widget.secondaryLogNameController.text = fallbackLogName;
    }
  }

  final List<String> _corporateServiceSectors = [
    'Private Sector',
    'Public Sector',
    'Government',
    'Self Employed',
    'Not Applicable',
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

  final List<String> _incomeSlabs = [
    'Below 1 Lakh',
    '> 1 <=5 Lacs',
    '>5 <=10 Lacs',
    '>10 <= 25 Lacs',
    '> 25 Lacs < = 1 Crore',
    'Above 1 Crore',
  ];

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

  final List<String> _politicallyExposedOptions = [
    'The investor is politically exposed person',
    'The investor is not politically exposed person',
    'If the investor is a relative of the politically exposed person',
  ];

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
        return 'The investor is politically exposed person';
      case 'N':
        return 'The investor is not politically exposed person';
      case 'R':
        return 'If the investor is a relative of the politically exposed person';
      default:
        return 'The investor is not politically exposed person'; // Default to N
    }
  }

  void _showCorporateServiceSectorBottomSheet(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              'Select Corporate Service Sector',
              variant: AppTextVariant.headline4,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 20),
            ..._corporateServiceSectors.map((sector) => ListTile(
              title: AppText(
                sector,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
              trailing: (isPrimary ? widget.primaryCorporateServiceSector : widget.secondaryCorporateServiceSector) == sector
                  ? Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              onTap: () {
                if (isPrimary) {
                  widget.onPrimaryCorporateServiceSectorChanged(sector);
                } else {
                  widget.onSecondaryCorporateServiceSectorChanged(sector);
                }
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showWealthSourceBottomSheet(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Select Wealth Source',
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _wealthSources.map((source) => ListTile(
                    title: AppText(
                      source,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                    ),
                    trailing: (isPrimary ? widget.primaryWealthSource : widget.secondaryWealthSource) == source
                        ? Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                    onTap: () {
                      if (isPrimary) {
                        widget.onPrimaryWealthSourceChanged(source);
                      } else {
                        widget.onSecondaryWealthSourceChanged(source);
                      }
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncomeSlabBottomSheet(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Select Income Slab',
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _incomeSlabs.map((slab) => ListTile(
                    title: AppText(
                      slab,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                    ),
                    trailing: (isPrimary ? widget.primaryIncomeSlab : widget.secondaryIncomeSlab) == slab
                        ? Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                    onTap: () {
                      if (isPrimary) {
                        widget.onPrimaryIncomeSlabChanged(slab);
                      } else {
                        widget.onSecondaryIncomeSlabChanged(slab);
                      }
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPoliticallyExposedBottomSheet(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Select Political Exposure',
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _politicallyExposedOptions.map((option) => ListTile(
                    title: AppText(
                      option,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                    ),
                    trailing: (isPrimary ? widget.primaryPoliticallyExposed : widget.secondaryPoliticallyExposed) == option
                        ? Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                    onTap: () {
                      if (isPrimary) {
                        widget.onPrimaryPoliticallyExposedChanged(option);
                      } else {
                        widget.onSecondaryPoliticallyExposedChanged(option);
                      }
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    // Check if this is a DOB controller (not date of networth)
    final isDobController = controller == widget.primaryDobController || 
                            controller == widget.secondaryDobController;
    
    // Calculate the maximum date for 18+ age requirement (18 years ago from today)
    final DateTime eighteenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 18));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDobController ? eighteenYearsAgo : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: isDobController ? eighteenYearsAgo : DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.success,
              onPrimary: Colors.white,
              surface: AppColors.darkCardBG,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // Additional validation for DOB to ensure 18+ years
      if (isDobController) {
        final age = DateTime.now().difference(picked).inDays ~/ 365;
        if (age < 18) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be at least 18 years old'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.primary,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.darkInputBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    value ?? hintText,
                    variant: AppTextVariant.bodyMedium,
                    colorType: value != null
                        ? AppTextColorType.primary
                        : AppTextColorType.gray,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.darkTextGray,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFatcaSection({
    required String title,
    required bool isPrimary,
  }) {
    final nameController = isPrimary ? widget.primaryNameController : widget.secondaryNameController;
    final placeOfBirthController = isPrimary ? widget.primaryPlaceOfBirthController : widget.secondaryPlaceOfBirthController;
    final countryController = isPrimary ? widget.primaryCountryController : widget.secondaryCountryController;
    final dobController = isPrimary ? widget.primaryDobController : widget.secondaryDobController;
    final panController = isPrimary ? widget.primaryPanController : widget.secondaryPanController;
    final networthController = isPrimary ? widget.primaryNetworthController : widget.secondaryNetworthController;
    final dateOfNetworthController = isPrimary ? widget.primaryDateOfNetworthController : widget.secondaryDateOfNetworthController;
    final logNameController = isPrimary ? widget.primaryLogNameController : widget.secondaryLogNameController;
    
    final investorType = isPrimary ? widget.primaryInvestorType : widget.secondaryInvestorType;
    final occupationId = isPrimary ? widget.primaryOccupationId : widget.secondaryOccupationId;
    final corporateServiceSector = isPrimary ? widget.primaryCorporateServiceSector : widget.secondaryCorporateServiceSector;
    final wealthSource = isPrimary ? widget.primaryWealthSource : widget.secondaryWealthSource;
    final incomeSlab = isPrimary ? widget.primaryIncomeSlab : widget.secondaryIncomeSlab;
    final countryOfBirth = isPrimary ? widget.primaryCountryOfBirth : widget.secondaryCountryOfBirth;
    final politicallyExposed = isPrimary ? widget.primaryPoliticallyExposed : widget.secondaryPoliticallyExposed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPrimary ? Icons.person : Icons.people,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              AppText(
                title,
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Name
        DarkInputField(
          label: 'Name',
          controller: nameController,
          hintText: 'Enter full name',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),

        // 2. Place of Birth
        DarkInputField(
          label: 'Place of Birth',
          controller: placeOfBirthController,
          hintText: 'Enter place of birth',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),

        // 3. Country of Birth
        CountryDropdown(
          selectedCountryCode: countryOfBirth,
          onCountrySelected: (Country country) {
            if (isPrimary) {
              widget.onPrimaryCountryOfBirthSelected(country);
            } else {
              widget.onSecondaryCountryOfBirthSelected(country);
            }
          },
          label: 'Country of Birth',
          hintText: 'Select Country',
        ),
        const SizedBox(height: 16),

        // 4. DOB
        DarkInputField(
          label: 'Date of Birth',
          controller: dobController,
          hintText: 'YYYY-MM-DD',
          readOnly: true,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
          onTap: () => _selectDate(context, dobController),
        ),
        const SizedBox(height: 16),

        // 6. PAN
        DarkInputField(
          label: 'PAN Number',
          controller: panController,
          hintText: 'Enter PAN number (e.g., AAAAA1950P)',
          keyboardType: TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            _PanFormatter(),
          ],
          validator: (value) {
            
            if (value == null || value.isEmpty) {
              return 'PAN number is required';
            }
            if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
              return 'Invalid PAN format. Use format: BEPPK1950P';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 7. Occupation
        OccupationDropdown(
          selectedOccupationId: occupationId,
          onOccupationSelected: isPrimary 
              ? widget.onPrimaryOccupationSelected 
              : widget.onSecondaryOccupationSelected,
          label: 'Occupation',
          hintText: 'Select Occupation',
        ),
        // const SizedBox(height: 16),

        // // 8. Corporate Service Sector
        // _buildDropdownField(
        //   label: 'Corporate Service Sector',
        //   value: corporateServiceSector,
        //   hintText: 'Select corporate service sector',
        //   onTap: () => _showCorporateServiceSectorBottomSheet(isPrimary),
        // ),
        const SizedBox(height: 16),

        // 9. Wealth Source
        _buildDropdownField(
          label: 'Wealth Source',
          value: wealthSource,
          hintText: 'Select wealth source',
          onTap: () => _showWealthSourceBottomSheet(isPrimary),
        ),
        const SizedBox(height: 16),

        // 10. Networth
        DarkInputField(
          label: 'Networth',
          controller: networthController,
          hintText: 'Enter networth amount',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 16),

        // 11. Income Slab
        _buildDropdownField(
          label: 'Income Slab',
          value: incomeSlab,
          hintText: 'Select income slab',
          onTap: () => _showIncomeSlabBottomSheet(isPrimary),
        ),
        const SizedBox(height: 16),

        // 12. Date of Networth
        DarkInputField(
          label: 'Date of Networth',
          controller: dateOfNetworthController,
          hintText: 'YYYY-MM-DD',
          readOnly: true,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
          onTap: () => _selectDate(context, dateOfNetworthController),
        ),
        const SizedBox(height: 16),

        // 13. Political Exposed
        _buildDropdownField(
          label: 'Political Exposed',
          value: politicallyExposed,
          hintText: 'Select political exposure status',
          onTap: () => _showPoliticallyExposedBottomSheet(isPrimary),
        ),  
        
        // // 14. Log Name (for both primary and secondary holders)
        // DarkInputField(
        //   label: 'Log Name',
        //   controller: logNameController,
        //   hintText: 'Auto-generated from IP address',
        //   readOnly: true,
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Holder FATCA
        _buildFatcaSection(
          title: 'FATCA for Primary Holder',
          isPrimary: true,
        ),
        
        // Secondary Holder FATCA (if applicable)
        if (widget.hasSecondaryHolder) ...[
          const SizedBox(height: 32),
          _buildFatcaSection(
            title: 'FATCA for Secondary Holder',
            isPrimary: false,
          ),
        ],
      ],
    );
  }
}
