import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/real_estate.dart';
import 'package:nwt_app/services/personal_assets/get_asset_details.dart';
import 'package:nwt_app/services/personal_assets/real_estate_service.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/calendar_picker.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key, this.assetId, this.isEdit});

  final int? assetId;
  final bool? isEdit;

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController nomineeController = TextEditingController();
  final TextEditingController relationController = TextEditingController();
  final TextEditingController shareholdingController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController userShareholdingController =
      TextEditingController();

  String selectedPropertyType = 'Residential';
  String selectedOwnershipType = 'Individual';
  String selectedNomineeOption = 'No';
  String? selectedDate;
  List<Map<String, dynamic>> nominees = [];
  List<PlatformFile> selectedFiles = [];

  // Services
  final GetAssetDetailsService _getAssetDetailsService =
      GetAssetDetailsService();

  // Edit mode state
  bool _isEditMode = false;
  bool _isLoadingAssetData = false;
  RealEstateAssetData? _currentAssetData;

  @override
  void initState() {
    super.initState();

    // Check if this is edit mode
    _isEditMode = widget.isEdit == true && widget.assetId != null;

    if (_isEditMode) {
      // Fetch asset data for editing
      _fetchAssetData();
    }
  }

  Future<void> _fetchAssetData() async {
    if (widget.assetId == null) return;

    setState(() {
      _isLoadingAssetData = true;
    });

    try {
      final response = await _getAssetDetailsService.getRealEstateAssetDetails(
        widget.assetId!,
      );

      if (response?.data != null) {
        _currentAssetData = response!.data!;
        _populateFormWithAssetData(_currentAssetData!);
      } else {
        // Handle error - show snackbar
        Get.snackbar(
          'Error',
          'Failed to load asset details',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Handle error
      Get.snackbar(
        'Error',
        'Failed to load asset details: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoadingAssetData = false;
      });
    }
  }

  void _populateFormWithAssetData(RealEstateAssetData data) {
    locationController.text = data.location;
    valueController.text = data.purchasedvalue.toString();
    areaController.text = data.areasqft.toString();
    noteController.text = data.notes ?? '';

    // Parse and format the date
    try {
      final DateTime parsedDate = DateTime.parse(data.purchaseddate);
      selectedDate = parsedDate.toIso8601String();
      dateController.text =
          "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
    } catch (e) {
      dateController.text = data.purchaseddate;
    }

    // Set property type and ownership type
    selectedPropertyType = data.propertytype;
    selectedOwnershipType = data.ownershiptype;

    // Set user share percentage if joint ownership
    if (data.usersharepercentage != null) {
      userShareholdingController.text = data.usersharepercentage.toString();
    }

    // Set nominees
    if (data.nominees.isNotEmpty) {
      selectedNomineeOption = 'Yes';
      nominees =
          data.nominees
              .map(
                (nominee) => {
                  'name': nominee.name,
                  'relation': nominee.relation,
                  'sharepercentage': nominee.sharepercentage,
                },
              )
              .toList();
    } else {
      selectedNomineeOption = 'No';
      nominees = [];
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    valueController.dispose();
    dateController.dispose();
    areaController.dispose();
    nomineeController.dispose();
    relationController.dispose();
    userShareholdingController.dispose();
    shareholdingController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showAppCalendarPicker(
      context: context,
      initialDate: DateTime.parse(
        selectedDate ?? DateTime.now().toIso8601String(),
      ),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      title: 'Select Purchase Date',
      dateFormat: DateFormatType.ddMMyyyy,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked.toIso8601String();
        dateController.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  // Sync wrapper for async submit function
  void _handleSubmit() {
    // Prevent submission if already loading
    if (_isLoading || _isLoadingAssetData) return;
    _submitRealEstateData();
  }

  Future<void> _submitRealEstateData() async {
    // Reset previous error
    setState(() {
      _errorMessage = '';
    });

    // Validate required fields
    if (locationController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter location');
      return;
    }

    if (valueController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter purchased value');
      return;
    }

    if (dateController.text.isEmpty) {
      setState(() => _errorMessage = 'Please select purchase date');
      return;
    }

    if (areaController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter area');
      return;
    }

    if (selectedPropertyType.isEmpty) {
      setState(() => _errorMessage = 'Please select property type');
      return;
    }

    if (selectedOwnershipType.isEmpty) {
      setState(() => _errorMessage = 'Please select ownership type');
      return;
    }

    if (selectedOwnershipType == 'Joint Holder' &&
        userShareholdingController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter shareholding percentage');
      return;
    }

    try {
      final PersonalAssetsResponse response;

      if (_isEditMode && widget.assetId != null) {
        // Update existing asset
        response = await RealEstateService().updateRealEstatePersonalAsset(
          assetId: widget.assetId!,
          purchasedValue: double.parse(valueController.text),
          purchasedDate: selectedDate ?? DateTime.now().toIso8601String(),
          location: locationController.text,
          areaSqFt: double.parse(areaController.text),
          propertyType: selectedPropertyType,
          ownershipType: selectedOwnershipType,
          userSharePercentage:
              selectedOwnershipType == 'Joint'
                  ? double.parse(userShareholdingController.text)
                  : 100, // Default to 100% for Individual
          notes: noteController.text,
          supportingDocs: [],
          nominees: selectedNomineeOption == 'Yes' ? nominees : [],
          onLoading: (isLoading) {
            if (mounted) {
              setState(() {
                _isLoading = isLoading;
              });
            }
          },
        );
      } else {
        // Create new asset
        response = await RealEstateService().createRealEstatePersonalAsset(
          purchasedValue: double.parse(valueController.text),
          purchasedDate: selectedDate ?? DateTime.now().toIso8601String(),
          location: locationController.text,
          areaSqFt: double.parse(areaController.text),
          propertyType: selectedPropertyType,
          ownershipType: selectedOwnershipType,
          userSharePercentage:
              selectedOwnershipType == 'Joint'
                  ? double.parse(userShareholdingController.text)
                  : 100, // Default to 100% for Individual
          notes: noteController.text,
          supportingDocs: [],
          nominees: selectedNomineeOption == 'Yes' ? nominees : [],
          onLoading: (isLoading) {
            if (mounted) {
              setState(() {
                _isLoading = isLoading;
              });
            }
          },
        );
      }

      if (response.status == 200 || response.status == 201) {
        Get.back();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
      // AppLogger.error('Error submitting real estate data', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Real Estate",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            AppInputField(
              controller: locationController,
              labelText: "Location",
              hintText: "Enter location",
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            AppInputField(
              controller: valueController,
              labelText: "Purchased Value",
              hintText: "Enter purchased value",
              type: AppInputFieldType.decimal,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter purchased value';
                }
                return null;
              },
            ),
            AppInputField(
              controller: dateController,
              labelText: "Purchased Date",
              hintText: "Select date",
              readOnly: true,
              onTap: () => _selectDate(context),
              suffix: const Icon(Icons.calendar_month, color: Colors.white70),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please select purchased date';
                }
                return null;
              },
            ),
            AppInputField(
              controller: areaController,
              labelText: "Area in sq ft",
              hintText: "Enter area",
              type: AppInputFieldType.decimal,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter area';
                }
                return null;
              },
            ),
            _buildChipSection(
              "Property Type",
              ['Residential', 'Commercial'],
              selectedPropertyType,
              (value) {
                setState(() {
                  selectedPropertyType = value;
                });
              },
            ),
            _buildChipSection(
              "Type of Ownership",
              ['Individual', 'Joint'],
              selectedOwnershipType,
              (value) {
                setState(() {
                  selectedOwnershipType = value;
                });
              },
            ),
            if (selectedOwnershipType == 'Joint')
              AppInputField(
                controller: userShareholdingController,
                labelText: "Shareholding Percentage",
                hintText: "Enter your shareholding percentage",
                type: AppInputFieldType.decimal,
                suffix: const Icon(Icons.percent, color: Colors.white70),
                validator: (value) {
                  if (selectedOwnershipType == 'Joint') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shareholding percentage';
                    }
                    final shareValue = double.tryParse(value) ?? 0;
                    if (shareValue <= 0) {
                      return 'Shareholding must be greater than 0';
                    }
                    if (shareValue > 100) {
                      return 'Shareholding cannot exceed 100%';
                    }
                  }
                  return null;
                },
              ),

            // Nominee selection
            _buildChipSection("Nominee", ['Yes', "No"], selectedNomineeOption, (
              value,
            ) {
              setState(() {
                selectedNomineeOption = value;
                if (value == 'No') {
                  nominees.clear();
                  nomineeController.clear();
                  relationController.clear();
                }
              });
            }),

            // Nominee details - only show when Yes is selected
            if (selectedNomineeOption == 'Yes') ..._buildNomineeSection(),
            AppInputField(
              controller: noteController,
              labelText: "Note",
              hintText: "Enter additional notes",
              maxLines: 3,
            ),
            // Supporting Documents Section
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     InkWell(
            //       onTap: _pickFiles,
            //       child: Container(
            //         padding: const EdgeInsets.symmetric(
            //           vertical: 16,
            //           horizontal: 12,
            //         ),
            //         decoration: BoxDecoration(
            //           color: const Color(0xFF1E1E1E),
            //           borderRadius: BorderRadius.circular(8),
            //           border: Border.all(
            //             color: AppColors.darkButtonBorder,
            //             width: 1,
            //           ),
            //         ),
            //         child: const Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             AppText(
            //               "Supporting Documents",
            //               variant: AppTextVariant.headline6,
            //               weight: AppTextWeight.semiBold,
            //               colorType: AppTextColorType.primary,
            //             ),
            //             Row(
            //               children: [
            //                 Icon(
            //                   Icons.upload_file,
            //                   color: AppColors.darkButtonPrimaryBackground,
            //                   size: 20,
            //                 ),
            //                 SizedBox(width: 8),
            //                 AppText(
            //                   "Upload",
            //                   variant: AppTextVariant.headline6,
            //                   weight: AppTextWeight.semiBold,
            //                   colorType: AppTextColorType.link,
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //     const SizedBox(height: 8),
            //     const AppText(
            //       "Supported formats: PDF, Images (JPG, PNG), Documents (DOC, DOCX), Excel (XLS, XLSX)",
            //       variant: AppTextVariant.bodySmall,
            //       colorType: AppTextColorType.secondary,
            //     ),
            //     if (selectedFiles.isNotEmpty) ..._buildSelectedFilesPreview(),
            //   ],
            // ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedErrorMessage(errorMessage: _errorMessage),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isEditMode ? "Update Asset" : "Save & Continue",
                onPressed: _handleSubmit,
                isLoading: _isLoading || _isLoadingAssetData,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Build nominee section with add/remove functionality
  List<Widget> _buildNomineeSection() {
    List<Widget> nomineeWidgets = [];

    // Display existing nominees
    for (int i = 0; i < nominees.length; i++) {
      nomineeWidgets.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Nominee ${i + 1}",
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                  ),
                  Row(
                    children: [
                      // Edit button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _editNominee(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _removeNominee(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Name",
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          nominees[i]['name'] ?? '',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Relation",
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          nominees[i]['relation'] ?? '',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Share %",
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppText(
                              (nominees[i]['sharepercentage'] as num)
                                  .toStringAsFixed(1),
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                            AppText(
                              "%",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Add nominee button
    if (nominees.length < 3) {
      // Limit to 3 nominees
      nomineeWidgets.add(
        GestureDetector(
          onTap: _addNominee,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF333333), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                AppText(
                  nominees.isEmpty
                      ? "Add Nominee"
                      : "Add Another Nominee (${nominees.length}/3)",
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return nomineeWidgets;
  }

  // Calculate current total shareholding
  double _getCurrentTotalShareholding({int? excludeIndex}) {
    double total = 0;
    for (int i = 0; i < nominees.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;
      total += (nominees[i]['sharepercentage'] as num).toDouble();
    }
    return total;
  }

  // Add nominee dialog with styled UI and validation
  void _addNominee() {
    _showNomineeDialog();
  }

  // Edit nominee dialog
  void _editNominee(int index) {
    _showNomineeDialog(
      isEdit: true,
      editIndex: index,
      initialName: nominees[index]['name'] ?? '',
      initialRelation: nominees[index]['relation'] ?? '',
      initialShareholding:
          (nominees[index]['sharepercentage'] as num).toDouble(),
    );
  }

  // Show nominee dialog with validation
  void _showNomineeDialog({
    bool isEdit = false,
    int? editIndex,
    String initialName = '',
    String initialRelation = '',
    double initialShareholding = 0,
  }) {
    final nameController = TextEditingController(text: initialName);
    final relationController = TextEditingController(text: initialRelation);
    final shareholdingController = TextEditingController(
      text: initialShareholding.toString(),
    );
    String errorMessage = '';

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top icon section
                    Container(
                      padding: const EdgeInsets.only(top: 28, bottom: 16),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (isEdit ? Colors.blue : Colors.green)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.person_add,
                          color: isEdit ? Colors.blue : Colors.green,
                          size: 28,
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppText(
                        isEdit ? "Edit Nominee" : "Add Nominee",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          AppInputField(
                            controller: nameController,
                            labelText: "Nominee Name",
                            hintText: "Enter nominee name",
                          ),
                          const SizedBox(height: 16),
                          AppInputField(
                            controller: relationController,
                            labelText: "Relation",
                            hintText: "Enter relation",
                          ),
                          const SizedBox(height: 16),
                          AppInputField(
                            controller: shareholdingController,
                            labelText: "Shareholding %",
                            hintText: "Enter shareholding percentage",
                            type: AppInputFieldType.decimal,
                            suffix: const Icon(
                              Icons.percent,
                              color: Colors.white70,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                errorMessage = '';
                                if (value.isNotEmpty) {
                                  final percentage =
                                      double.tryParse(value) ?? 0.0;
                                  if (percentage > 100) {
                                    errorMessage =
                                        'Percentage cannot exceed 100%';
                                  } else if (percentage <= 0) {
                                    errorMessage =
                                        'Percentage must be greater than 0';
                                  } else {
                                    final currentTotal =
                                        _getCurrentTotalShareholding(
                                          excludeIndex:
                                              isEdit ? editIndex : null,
                                        );
                                    final newTotal =
                                        isEdit && editIndex != null
                                            ? (currentTotal -
                                                    (nominees[editIndex]['sharepercentage']
                                                            as num)
                                                        .toDouble()) +
                                                percentage
                                            : currentTotal + percentage;

                                    if (newTotal > 100) {
                                      errorMessage =
                                          'Total shareholding cannot exceed 100%. Current total: ${(newTotal - percentage).toStringAsFixed(1)}%';
                                    }
                                  }
                                }
                              });
                            },
                          ),
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppText(
                                      errorMessage,
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.error,
                                      weight: AppTextWeight.medium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action buttons with divider
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.darkInputBorder.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                  ),
                                ),
                              ),
                              child: AppText(
                                "Cancel",
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.secondary,
                                weight: AppTextWeight.semiBold,
                              ),
                            ),
                          ),

                          // Vertical divider
                          Container(
                            height: 52,
                            width: 1,
                            color: AppColors.darkInputBorder.withOpacity(0.5),
                          ),

                          // Add/Update button
                          Expanded(
                            child: TextButton(
                              onPressed:
                                  errorMessage.isEmpty &&
                                          nameController.text.isNotEmpty &&
                                          relationController.text.isNotEmpty &&
                                          shareholdingController.text.isNotEmpty
                                      ? () {
                                        setState(() {
                                          final nomineeData = {
                                            'name': nameController.text.trim(),
                                            'relation':
                                                relationController.text.trim(),
                                            'sharepercentage':
                                                double.tryParse(
                                                  shareholdingController.text,
                                                ) ??
                                                0.0,
                                          };

                                          if (isEdit && editIndex != null) {
                                            nominees[editIndex] = nomineeData;
                                          } else {
                                            nominees.add(nomineeData);
                                          }
                                        });
                                        Navigator.of(context).pop();
                                      }
                                      : null,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                              ),
                              child: AppText(
                                isEdit ? "Update" : "Add",
                                variant: AppTextVariant.bodyMedium,
                                colorType:
                                    errorMessage.isEmpty &&
                                            nameController.text.isNotEmpty &&
                                            relationController
                                                .text
                                                .isNotEmpty &&
                                            shareholdingController
                                                .text
                                                .isNotEmpty
                                        ? AppTextColorType.primary
                                        : AppTextColorType.secondary,
                                weight: AppTextWeight.semiBold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Remove nominee
  void _removeNominee(int index) {
    setState(() {
      nominees.removeAt(index);
    });
  }

  Widget _buildChipSection(
    String label,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return CategoryChip(
                label: options[index],
                isSelected: selectedValue == options[index],
                onTap: () => onChanged(options[index]),
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox(width: 8);
            },
            itemCount: options.length,
          ),
        ),
      ],
    );
  }

  // File picker method
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      // Handle error - could show a snackbar or dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Build selected files preview
  List<Widget> _buildSelectedFilesPreview() {
    if (selectedFiles.isEmpty) return [];

    return [
      const SizedBox(height: 16),
      const AppText(
        "Selected Files:",
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
      ),
      const SizedBox(height: 8),
      ...selectedFiles.asMap().entries.map((entry) {
        int index = entry.key;
        PlatformFile file = entry.value;
        return _buildFilePreviewCard(file, index);
      }),
    ];
  }

  // Build individual file preview card
  Widget _buildFilePreviewCard(PlatformFile file, int index) {
    IconData fileIcon = _getFileIcon(file.extension ?? '');
    String fileSize = _formatFileSize(file.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              fileIcon,
              color: AppColors.darkButtonPrimaryBackground,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  file.name,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AppText(
                  fileSize,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeFile(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.close,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate icon for file type
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Remove file from selection
  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }
}
