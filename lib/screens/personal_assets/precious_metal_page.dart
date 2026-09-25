import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_type/precious_metal.dart';
import 'package:nwt_app/services/personal_assets/get_asset_details.dart';
import 'package:nwt_app/services/personal_assets/precious_metal_service.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/calendar_picker.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PreciousMetalPage extends StatefulWidget {
  const PreciousMetalPage({super.key, this.assetId, this.isEdit});

  final int? assetId;
  final bool? isEdit;

  @override
  State<PreciousMetalPage> createState() => _PreciousMetalPageState();
}

class _PreciousMetalPageState extends State<PreciousMetalPage> {
  final TextEditingController metalDetailsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController purityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedMetalType = 'Gold';
  String selectedOwnershipType = 'Individual';
  String selectedNomineeOption = 'No';
  String? selectedDate;
  int userSharePercentage = 100;

  // List to store multiple nominees
  List<Map<String, dynamic>> nominees = [];

  // Form validation and loading states
  bool _isLoading = false;
  String _errorMessage = '';

  // Services
  final GetAssetDetailsService _getAssetDetailsService =
      GetAssetDetailsService();

  // Edit mode state
  bool _isEditMode = false;
  bool _isLoadingAssetData = false;
  PreciousMetalAssetData? _currentAssetData;

  // Sync wrapper for async submit function
  void _handleSubmit() {
    // Prevent submission if already loading
    if (_isLoading || _isLoadingAssetData) return;
    _submitPreciousMetalData();
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEdit ?? false;

    if (_isEditMode && widget.assetId != null) {
      _fetchAssetData();
    }
  }

  @override
  void dispose() {
    metalDetailsController.dispose();
    weightController.dispose();
    valueController.dispose();
    dateController.dispose();
    purityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssetData() async {
    if (widget.assetId == null) return;

    setState(() {
      _isLoadingAssetData = true;
      _errorMessage = '';
    });

    try {
      final assetResponse = await _getAssetDetailsService
          .getPreciousMetalAssetDetails(widget.assetId!);

      if (assetResponse != null && assetResponse.data != null) {
        _currentAssetData = assetResponse.data;
        _populateFormWithAssetData(assetResponse.data!);
      } else {
        _showErrorMessage('Failed to load asset details');
      }
    } catch (e) {
      _showErrorMessage('Error loading asset: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingAssetData = false;
      });
    }
  }

  void _populateFormWithAssetData(PreciousMetalAssetData assetData) {
    setState(() {
      // Populate form fields
      metalDetailsController.text = assetData.details;
      weightController.text = assetData.weightgm.toString();
      valueController.text = assetData.purchasedvalue.toString();
      purityController.text = assetData.purity ?? '';
      noteController.text = assetData.notes ?? '';

      // Parse and format date
      try {
        final date = DateTime.parse(assetData.purchaseddate);
        selectedDate = assetData.purchaseddate;
        dateController.text = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        print('Error parsing date: $e');
      }

      // Set dropdown values
      selectedMetalType = assetData.metaltype;

      // Always use Individual ownership type (no ownership complexity)
      selectedOwnershipType = 'Individual';
      userSharePercentage = 100;

      // Populate nominees
      nominees.clear();
      if (assetData.nominees.isNotEmpty) {
        selectedNomineeOption = 'Yes';
        for (var nominee in assetData.nominees) {
          nominees.add({
            'name': nominee.name,
            'relation': nominee.relation,
            'sharepercentage': nominee.sharepercentage,
          });
        }
      } else {
        selectedNomineeOption = 'No';
      }
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });

    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showAppCalendarPicker(
      context: context,
      initialDate:
          selectedDate != null ? DateTime.parse(selectedDate!) : DateTime.now(),
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

  Future<void> _submitPreciousMetalData() async {
    // Reset previous error
    setState(() {
      _errorMessage = '';
    });

    // Validate required fields
    if (metalDetailsController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter metal details');
      return;
    }

    if (weightController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter weight');
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

    if (selectedMetalType.isEmpty) {
      setState(() => _errorMessage = 'Please select metal type');
      return;
    }

    try {
      final PersonalAssetsResponse response;

      if (_isEditMode && widget.assetId != null) {
        // Update existing asset
        response = await PreciousMetalService()
            .updatePreciousMetalPersonalAsset(
              assetId: widget.assetId!,
              purchasedValue: double.parse(valueController.text),
              purchasedDate: selectedDate ?? DateTime.now().toIso8601String(),
              metalType: selectedMetalType,
              weightGm: double.parse(weightController.text),
              details: metalDetailsController.text,
              purity:
                  selectedMetalType != 'Others' ? purityController.text : null,
              ownershipType: 'Individual',
              userSharePercentage: 100.0,
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
        response = await PreciousMetalService()
            .createPreciousMetalPersonalAsset(
              purchasedValue: double.parse(valueController.text),
              purchasedDate: selectedDate ?? DateTime.now().toIso8601String(),
              metalType: selectedMetalType,
              weightGm: double.parse(weightController.text),
              details: metalDetailsController.text,
              purity:
                  selectedMetalType != 'Others' ? purityController.text : null,
              ownershipType: 'Individual',
              userSharePercentage: 100.0,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                "Precious Metal",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
              const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
            ],
          ),
        ),
        body:
            _isLoadingAssetData
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 12,
                    children: [
                      _buildChipSection(
                        "Metal Type",
                        ['Gold', 'Silver', 'Diamond', 'Others'],
                        selectedMetalType,
                        (value) {
                          setState(() {
                            selectedMetalType = value;
                          });
                        },
                      ),
                      AppInputField(
                        controller: metalDetailsController,
                        labelText: "Metal Details (eg: Pendant Set, Rings)",
                        hintText: "Enter metal details",
                      ),
                      AppInputField(
                        controller: weightController,
                        labelText: "Weight in gm",
                        hintText: "Enter weight",
                        type: AppInputFieldType.decimal,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      AppInputField(
                        controller: valueController,
                        labelText: "Purchased Value",
                        hintText: "Enter purchased value",
                        type: AppInputFieldType.decimal,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      AppInputField(
                        controller: dateController,
                        labelText: "Purchased Date",
                        hintText: "Select date",
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        suffix: const Icon(
                          Icons.calendar_month,
                          color: Colors.white70,
                        ),
                      ),
                      if (selectedMetalType != 'Others')
                        AppInputField(
                          controller: purityController,
                          labelText: "Purity",
                          hintText: "Enter purity (e.g., 24K, 22K)",
                        ),
                      // Nominee selection
                      _buildChipSection(
                        "Nominee",
                        ['Yes', "No"],
                        selectedNomineeOption,
                        (value) {
                          setState(() {
                            selectedNomineeOption = value;
                            if (value == 'No') {
                              nominees.clear();
                            }
                          });
                        },
                      ),
      
                      // Nominee details - only show when Yes is selected
                      if (selectedNomineeOption == 'Yes')
                        ..._buildNomineeSection(),
                      AppInputField(
                        controller: noteController,
                        labelText: "Note",
                        hintText: "Enter additional notes",
                        maxLines: 3,
                      ),
                      InkWell(
                        onTap: () {
                          // Add your file picker or upload logic here
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              AppText(
                                "Supporting Document",
                                variant: AppTextVariant.headline6,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                              AppText(
                                "Upload",
                                variant: AppTextVariant.headline6,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.link,
                              ),
                            ],
                          ),
                        ),
                      ),
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
              // Error message display
              if (_errorMessage.isNotEmpty)
                AnimatedErrorMessage(errorMessage: _errorMessage),
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
                              (nominees[i]['sharepercentage'] as num?)
                                      ?.toStringAsFixed(1) ??
                                  '0.0',
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
      total += (nominees[i]['sharepercentage'] as num?)?.toDouble() ?? 0.0;
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
          (nominees[index]['sharepercentage'] as num?)?.toString() ?? '',
    );
  }

  // Show nominee dialog with validation
  void _showNomineeDialog({
    bool isEdit = false,
    int? editIndex,
    String initialName = '',
    String initialRelation = '',
    String initialShareholding = '',
  }) {
    final nameController = TextEditingController(text: initialName);
    final relationController = TextEditingController(text: initialRelation);
    final shareholdingController = TextEditingController(
      text: initialShareholding,
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            suffix: const Icon(
                              Icons.percent,
                              color: Colors.white70,
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                errorMessage = '';
                                if (value.isNotEmpty) {
                                  final percentage =
                                      double.tryParse(value) ?? 0;
                                  if (percentage > 100) {
                                    errorMessage =
                                        'Percentage cannot exceed 100%';
                                  } else {
                                    final currentTotal =
                                        _getCurrentTotalShareholding(
                                          excludeIndex:
                                              isEdit ? editIndex : null,
                                        );
                                    final newTotal = currentTotal + percentage;
                                    if (newTotal > 100) {
                                      errorMessage =
                                          'Total shareholding cannot exceed 100%. Current total: ${currentTotal.toStringAsFixed(1)}%';
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
                                            'sharepercentage': double.parse(
                                              shareholdingController.text
                                                  .trim(),
                                            ),
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
}
