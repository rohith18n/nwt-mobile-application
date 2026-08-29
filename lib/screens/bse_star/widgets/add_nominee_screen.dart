import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/screens/bse_star/widgets/dynamic_relation_selector.dart';

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

class _DrivingLicenceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase();
    
    // Indian DL format: 2 letters (state) + 2 digits (RTO) + 4 digits (year) + 7 digits (unique)
    // Total: 15 characters (e.g., MH0120190001234)
    if (newText.length <= 15) {
      String validText = '';
      for (int i = 0; i < newText.length; i++) {
        if (i < 2) {
          // First 2 positions should be letters (state code)
          if (RegExp(r'[A-Z]').hasMatch(newText[i])) {
            validText += newText[i];
          }
        } else if (i >= 2 && i < 15) {
          // Remaining 13 positions should be digits
          if (RegExp(r'[0-9]').hasMatch(newText[i])) {
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

class NomineeData {
  final String name;
  final String relation;
  final String dateOfBirth;
  final String idType;
  final String aadhaar;
  final String email;
  final String mobile;
  final String shareAllocation;
  final bool sameAsApplicantAddress;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  NomineeData({
    required this.name,
    required this.relation,
    required this.dateOfBirth,
    required this.idType,
    required this.aadhaar,
    required this.email,
    required this.mobile,
    required this.shareAllocation,
    required this.sameAsApplicantAddress,
    this.address = '',
    this.city = '',
    this.state = '', 
    this.country = '',
    this.pincode = '',
  });
}

class AddNomineeScreen extends StatefulWidget {
  final TextEditingController nomineeNameController;
  final TextEditingController nomineeDobController;
  final TextEditingController aadhaarController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController shareAllocationController;
  final TextEditingController nomineeAddressController;
  final TextEditingController nomineeCityController;
  final TextEditingController nomineeStateController;
  final TextEditingController nomineeCountryController;
  final TextEditingController nomineePincodeController;
  final String selectedRelation;
  final String selectedRelationId;
  final String selectedIdType;
  final bool sameAsApplicantAddress;
  final ValueChanged<String> onRelationChanged;
  final ValueChanged<String> onRelationIdChanged;
  final ValueChanged<String> onIdTypeChanged;
  final ValueChanged<bool> onAddressChanged;
  final Function(int, NomineeData) onEditNominee;
  final Function(int) onRemoveNominee;
  final VoidCallback onAddAnotherNominee;
  final Function() onSaveNominee;
  final VoidCallback? onCancel;
  final List<NomineeData> addedNominees;
  final bool isEditMode;
  final bool showInputForm;
  final int? editingIndex;
  final NomineeData? nomineeData;
  final bool isEditing;

  const AddNomineeScreen({
    super.key,
    required this.nomineeNameController,
    required this.nomineeDobController,
    required this.aadhaarController,
    required this.emailController,
    required this.mobileController,
    required this.shareAllocationController,
    required this.nomineeAddressController,
    required this.nomineeCityController,
    required this.nomineeStateController,
    required this.nomineeCountryController,
    required this.nomineePincodeController,
    required this.selectedRelation,
    required this.selectedRelationId,
    required this.selectedIdType,
    required this.sameAsApplicantAddress,
    required this.onRelationChanged,
    required this.onRelationIdChanged,
    required this.onIdTypeChanged,
    required this.onAddressChanged,
    required this.onEditNominee,
    required this.onRemoveNominee,
    required this.onAddAnotherNominee,
    required this.onSaveNominee,
    this.onCancel,
    required this.addedNominees,
    this.isEditMode = false,
    this.showInputForm = false,
    this.editingIndex,
    this.nomineeData,
    this.isEditing = false,
  });

  @override
  State<AddNomineeScreen> createState() => _AddNomineeScreenState();
}

class _AddNomineeScreenState extends State<AddNomineeScreen> {
  late bool sameAsApplicantAddress;
  final FocusNode _aadhaarFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    sameAsApplicantAddress = widget.sameAsApplicantAddress;
  }

  @override
  void didUpdateWidget(AddNomineeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sameAsApplicantAddress != oldWidget.sameAsApplicantAddress) {
      setState(() {
        sameAsApplicantAddress = widget.sameAsApplicantAddress;
      });
    }
  }

  @override
  void dispose() {
    _aadhaarFocusNode.dispose();
    super.dispose();
  }

  Widget _buildIdInputField() {
    switch (widget.selectedIdType) {
      case 'PAN':
        return DarkInputField(
          label: 'PAN Number',
          controller: widget.aadhaarController,
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
        );
      case 'Driving Licence':
        return DarkInputField(
          label: 'Driving Licence Number',
          controller: widget.aadhaarController,
          hintText: 'Enter DL number (e.g., MH0120190001234)',
          keyboardType: TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
            _DrivingLicenceFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Driving Licence number is required';
            }
            if (!RegExp(r'^[A-Z]{2}[0-9]{13}$').hasMatch(value)) {
              return 'Invalid DL format. Use format: MH0120190001234';
            }
            return null;
          },
        );
      case 'Aadhaar Card':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Aadhaar Number',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.white,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _aadhaarFocusNode.requestFocus();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppText(
                      'XXXX-XXXX-',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.gray,
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.aadhaarController,
                        focusNode: _aadhaarFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0000',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          counterText: '', // Hide character counter
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildNomineeCard(NomineeData nominee, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    'Nominee ${index + 1}',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.white,
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onEditNominee(index, nominee),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.onRemoveNominee(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 16,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Name',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      nominee.name,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Relation',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      nominee.relation,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Share (%)',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      '${nominee.shareAllocation}%',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'DOB',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      nominee.dateOfBirth,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Email',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      nominee.email.isEmpty ? '-' : nominee.email,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Mobile',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      nominee.mobile.isEmpty ? '-' : nominee.mobile,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    bool basicFieldsValid = widget.nomineeNameController.text.trim().isNotEmpty &&
                           widget.nomineeDobController.text.trim().isNotEmpty &&
                           widget.aadhaarController.text.trim().isNotEmpty &&
                           widget.emailController.text.trim().isNotEmpty &&
                           widget.mobileController.text.trim().isNotEmpty &&
                           widget.shareAllocationController.text.trim().isNotEmpty;
    
    // If same as applicant is unchecked, address fields are also required
    if (!sameAsApplicantAddress) {
      return basicFieldsValid &&
             widget.nomineeAddressController.text.trim().isNotEmpty &&
              widget.nomineeCityController.text.trim().isNotEmpty &&
              widget.nomineeCountryController.text.trim().isNotEmpty &&
              widget.nomineePincodeController.text.trim().isNotEmpty;
    }
    
    return basicFieldsValid;
  }

  // Calculate if share field should be editable
  bool get _isShareEditable {
    // If only 1 nominee (including current), not editable
    if (widget.addedNominees.isEmpty || (widget.addedNominees.length == 1 && widget.isEditing)) {
      return false;
    }
    // If 2 or more nominees, editable
    return true;
  }

  void _handleSave() {
    if (_isFormValid()) {
      widget.onSaveNominee();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Add a nominee for all products',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 8),
          AppText(
            'You can add up to 3 nominees',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.medium,
          ),
          
          // Show added nominees
          if (widget.addedNominees.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...widget.addedNominees.asMap().entries.map((entry) {
              return _buildNomineeCard(entry.value, entry.key);
            }).toList(),
          ],
          
          // Show input form conditionally
          if (widget.showInputForm) ...[
            const SizedBox(height: 24),
            DarkInputField(
              label: 'Nominee Name',
              controller: widget.nomineeNameController,
              hintText: 'Enter nominee\'s full name',
            ),
            const SizedBox(height: 24),
        AppText(
          'Relation',
          variant: AppTextVariant.bodyMedium,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
            ),
        const SizedBox(height: 12),
            DynamicRelationSelector(
              selectedRelationName: widget.selectedRelation,
              selectedRelationId: widget.selectedRelationId,
              onRelationNameChanged: widget.onRelationChanged,
              onRelationIdChanged: widget.onRelationIdChanged,
            ),
            const SizedBox(height: 24),
        DarkInputField(
          label: 'Nominee\'s Date of Birth',
          controller: widget.nomineeDobController,
          hintText: 'YYYY-MM-DD',
          isDateField: true,
          lastDate: DateTime(
            DateTime.now().year - 18,
            DateTime.now().month,
            DateTime.now().day,
          ),
          dateFormat: 'yyyy-MM-dd',
            ),
        const SizedBox(height: 24), 
        AppDropdown(
          labelText: 'ID Type',
          fillColor: Colors.transparent,
          value: widget.selectedIdType.isNotEmpty && ['PAN', 'Aadhaar Card', 'Driving Licence'].contains(widget.selectedIdType) 
              ? widget.selectedIdType 
              : 'Aadhaar Card',
          items: const ['PAN', 'Aadhaar Card', 'Driving Licence'],
          hintText: 'Select ID Type',
          onChanged: (value) {
            if (value != null) {
              widget.onIdTypeChanged(value);
            }
          },
            ),
            const SizedBox(height: 24),
            _buildIdInputField(),
            const SizedBox(height: 24),
            DarkInputField(
              label: 'Email',
              controller: widget.emailController,
              hintText: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            DarkInputField(
              label: 'Mobile Number',
              controller: widget.mobileController,
              hintText: 'Enter 10-digit mobile number',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 24),
            DarkInputField(
              label: 'Share Allocation (%)',
              controller: widget.shareAllocationController,
              hintText: 'Enter share percentage',
              keyboardType: TextInputType.number,
              enabled: _isShareEditable,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
            const SizedBox(height: 24),
            AppText(
              'Nominee Address',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.white,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  sameAsApplicantAddress = !sameAsApplicantAddress;
                });
                widget.onAddressChanged(sameAsApplicantAddress);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Same as applicant',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: sameAsApplicantAddress ? Colors.white : Colors.transparent,
                        border: Border.all(color: Colors.grey[600]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: sameAsApplicantAddress
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            // Show address fields when "same as applicant" is unchecked
            if (!sameAsApplicantAddress) ...[
              const SizedBox(height: 24),
              DarkInputField(
                label: 'Nominee Address',
                controller: widget.nomineeAddressController,
                hintText: 'Enter nominee\'s complete address',
              ),
              const SizedBox(height: 24),
              DarkInputField(
                label: 'State',
                controller: widget.nomineeCityController,
                hintText: 'Enter state name',
                onChanged: (value) {
                  // Sync with state controller for backend consistency
                  widget.nomineeStateController.text = value;
                },
              ),
              const SizedBox(height: 24),
              DarkInputField(
                label: 'Country',
                controller: widget.nomineeCountryController,
                hintText: 'Enter country name',
              ),
              const SizedBox(height: 24),
              DarkInputField(
                label: 'Pincode',
                controller: widget.nomineePincodeController,
                hintText: 'Enter postal/zip code',
              ),
            ],
            
            // Show cancel button when:
            // 1. Adding 2nd or 3rd nominee (at least 1 nominee already exists) OR
            // 2. Editing any nominee
            // Don't show when adding the first nominee (addedNominees.isEmpty)
            if (widget.showInputForm && widget.onCancel != null && widget.addedNominees.isNotEmpty) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800]!.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      AppText(
                        'CANCEL',
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.gray,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ], // End of conditional input form
        
        // Show "Add Nominee" button when:
        // 1. Less than 3 nominees total AND
        // 2. Not currently showing the input form (to prevent showing button while adding 3rd nominee)
        if (widget.addedNominees.length < 3 && !widget.showInputForm) ...[
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => widget.onAddAnotherNominee(),
            child: Container(
              width: double.infinity,  
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  AppText(
                    'ADD ANOTHER NOMINEE',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.link,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
      ),
    );
  }
}
