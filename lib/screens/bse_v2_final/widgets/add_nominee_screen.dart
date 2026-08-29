import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/controllers/user_controller.dart';

/// Add Nominee Screen
class AddNomineeScreen extends StatefulWidget {
  final int currentNomineeCount;
  final int remainingPercentage;

  const AddNomineeScreen({
    super.key,
    this.currentNomineeCount = 0,
    this.remainingPercentage = 100,
  });

  @override
  State<AddNomineeScreen> createState() => _AddNomineeScreenState();
}

class _AddNomineeScreenState extends State<AddNomineeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _percentController = TextEditingController();
  final _dobController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String? _selectedRelation;
  
  final List<String> _relations = [
    'Father', 'Mother', 'Husband', 'Wife', 'Son', 'Daughter', 'Brother', 'Sister', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2NomineeScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2NomineeScreenViewed, tag: 'event');
    });
    _percentController.text = widget.remainingPercentage.toString();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _percentController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.darkButtonPrimaryBackground,
              surface: AppColors.darkCardBG,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _saveNominee() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRelation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select relation')),
      );
      return;
    }
    
    final nomineeData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'relation': _selectedRelation,
      'percent': int.parse(_percentController.text),
      'dob': _dobController.text,
      'pan': _panController.text.trim().toUpperCase(),
      'address_line_1': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    };

    Get.back(result: nomineeData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Add Nominee',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Nominee ${widget.currentNomineeCount + 1} Details',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              SizedBox(height: 8.h),
              AppText(
                'Add nominee details. Remaining allocation: ${widget.remainingPercentage}%',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.gray,
              ),
              SizedBox(height: 32.h),
              
              // Personal Details
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter first name',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppInputField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter last name',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              AppDropdown(
                labelText: 'Relation',
                hintText: 'Select relation',
                value: _selectedRelation,
                items: _relations,
                onChanged: (value) => setState(() => _selectedRelation = value),
              ),
              
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      controller: _percentController,
                      labelText: 'Percentage',
                      hintText: '0-${widget.remainingPercentage}',
                      type: AppInputFieldType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        final val = int.tryParse(v!);
                        if (val == null || val < 1 || val > widget.remainingPercentage) {
                          return 'Invalid (1-${widget.remainingPercentage})';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppInputField(
                      controller: _dobController,
                      labelText: 'Date of Birth',
                      hintText: 'YYYY-MM-DD',
                      readOnly: true,
                      onTap: _selectDate,
                      suffix: const Icon(Icons.calendar_today, color: AppColors.darkTextGray),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              AppInputField(
                controller: _panController,
                labelText: 'PAN Number',
                hintText: 'Enter PAN',
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final userController = Get.find<UserController>();
                  final userPan = userController.userData?.pannumber;
                  if (userPan != null && v.toUpperCase() == userPan.toUpperCase()) {
                    return 'You cannot nominate yourself';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16.h),
              AppInputField(
                controller: _addressController,
                labelText: 'Address',
                hintText: 'Enter address',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'City',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppInputField(
                      controller: _stateController,
                      labelText: 'State',
                      hintText: 'State',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              AppInputField(
                controller: _pincodeController,
                labelText: 'Pincode',
                hintText: 'Enter pincode',
                type: AppInputFieldType.number,
                maxLength: 6,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Save Nominee',
                  onPressed: _saveNominee,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
