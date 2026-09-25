import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/profile/holder_controller.dart';
import 'package:nwt_app/types/profile/holder.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/app_bar.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:nwt_app/utils/image_compression_helper.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class HolderDetailScreen extends StatefulWidget {
  final int holderId;

  const HolderDetailScreen({super.key, required this.holderId});

  @override
  State<HolderDetailScreen> createState() => _HolderDetailScreenState();
}

class _HolderDetailScreenState extends State<HolderDetailScreen> {
  final HolderController controller = Get.find<HolderController>();
  late Holder holder;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController fatherNameController;
  late TextEditingController dobController;

  // Address controllers
  late TextEditingController addressLine1Controller;
  late TextEditingController cityController;
  late TextEditingController pincodeController;

  late TextEditingController tinController;
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  bool _hasSignature = false;
  bool _isSameAsPrimary = false;
  String _selectedGender = 'M';
  String _selectedResidency = 'Resident';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _addAddressListeners();
    _refreshData();
  }

  void _addAddressListeners() {
    void listener() {
      if (_isSameAsPrimary) {
        setState(() => _isSameAsPrimary = false);
      }
    }

    addressLine1Controller.addListener(listener);
    cityController.addListener(listener);
    pincodeController.addListener(listener);
  }

  void _initializeData() {
    holder = controller.holders.firstWhere((h) => h.id == widget.holderId);
    nameController = TextEditingController(text: holder.name);
    emailController = TextEditingController(text: holder.email);
    phoneController = TextEditingController(text: holder.phoneNumber);
    fatherNameController = TextEditingController(text: holder.fatherName);
    dobController = TextEditingController(text: holder.dob);

    final addr = holder.address ?? {};
    addressLine1Controller = TextEditingController(
      text: (addr['address_line_1'] ?? addr['address1'] ?? "").toString(),
    );
    cityController = TextEditingController(
      text: (addr['city'] ?? "").toString(),
    );
    final pincode = (addr['pincode'] ?? "").toString();
    pincodeController = TextEditingController(
      text: pincode == "0" ? "" : pincode,
    );

    tinController = TextEditingController(text: holder.tin ?? "");

    _selectedGender = holder.gender ?? 'M';
    _selectedResidency = holder.investorResidency;
  }

  void _refreshData() async {
    await controller.refreshHolderDetail(widget.holderId);
    if (mounted) {
      setState(() {
        holder = controller.holders.firstWhere((h) => h.id == widget.holderId);
        _updateControllers();
      });
    }
  }

  void _updateControllers() {
    nameController.text = holder.name;
    emailController.text = holder.email ?? "";
    phoneController.text = holder.phoneNumber ?? "";
    fatherNameController.text = holder.fatherName ?? "";
    dobController.text = holder.dob ?? "";

    final addr = holder.address ?? {};
    addressLine1Controller.text =
        (addr['address_line_1'] ?? addr['address1'] ?? "").toString();
    cityController.text = (addr['city'] ?? "").toString();
    final pincode = (addr['pincode'] ?? "").toString();
    pincodeController.text = pincode == "0" ? "" : pincode;

    tinController.text = holder.tin ?? "";

    _selectedGender = holder.gender ?? 'M';
    _selectedResidency = holder.investorResidency;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    fatherNameController.dispose();
    dobController.dispose();
    addressLine1Controller.dispose();
    cityController.dispose();
    pincodeController.dispose();
    tinController.dispose();
    super.dispose();
  }

  void _applyPrimaryAddress() {
    final userController = Get.find<UserController>();
    final profileAddr = userController.userData?.uccProfile?['address'];

    if (profileAddr != null && profileAddr is Map) {
      setState(() {
        addressLine1Controller.text =
            (profileAddr['address1'] ?? profileAddr['address_line_1'] ?? "")
                .toString();
        cityController.text = (profileAddr['city'] ?? "").toString();
        final pincode = (profileAddr['pincode'] ?? "").toString();
        pincodeController.text = pincode == "0" ? "" : pincode;
        _isSameAsPrimary = true;
      });
      AppLogger.info(
        'Applied address from main user profile (UCC)',
        tag: 'HolderDetail',
      );
      return;
    }

    // Fallback to first holder if profile address is not yet fetched
    if (controller.holders.isNotEmpty) {
      final primary = controller.holders[0];
      final addr = primary.address ?? {};
      setState(() {
        addressLine1Controller.text =
            (addr['address_line_1'] ?? addr['address1'] ?? "").toString();
        cityController.text = (addr['city'] ?? "").toString();
        final pincode = (addr['pincode'] ?? "").toString();
        pincodeController.text = pincode == "0" ? "" : pincode;
        _isSameAsPrimary = true;
      });
      AppLogger.info(
        'Applied address from first holder (fallback)',
        tag: 'HolderDetail',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: CustomAppBar(
        title: "Holder Details",
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () =>
                    controller.isDetailLoading.value
                        ? Column(
                          children: [
                            const LinearProgressIndicator(
                              color: AppColors.darkPrimary,
                              backgroundColor: Colors.transparent,
                            ),
                            SizedBox(height: 16.h),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              // _buildHeader(),
              // SizedBox(height: 32.h),
              const _SectionHeader(title: "Personal Information"),
              SizedBox(height: 16.h),
              DarkInputField(
                controller: nameController,
                label: "Full Name",
                hintText: "Enter full name",
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 24.h),
              DarkInputField(
                controller: dobController,
                label: "Date of Birth",
                hintText: "YYYY-MM-DD",
                isDateField: true,
                dateFormat: 'yyyy-MM-dd',
              ),
              SizedBox(height: 24.h),
              AppDropdown(
                labelText: 'Gender',
                value: _getGenderDisplay(_selectedGender),
                items: const ['Male', 'Female', 'Other'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      if (value == 'Male') {
                        _selectedGender = 'M';
                      } else if (value == 'Female') {
                        _selectedGender = 'F';
                      } else {
                        _selectedGender = 'O';
                      }
                    });
                  }
                },
              ),
              SizedBox(height: 24.h),
              AppDropdown(
                labelText: 'Investor Residency',
                value: _selectedResidency,
                items: const ['Resident', 'NRI-NRE', 'NRI-NRO'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedResidency = value;
                    });
                  }
                },
              ),
              if (_selectedResidency != 'Resident') ...[
                SizedBox(height: 24.h),
                DarkInputField(
                  controller: tinController,
                  label: "TIN",
                  hintText: "Enter Tax Identification Number",
                ),
              ],
              SizedBox(height: 24.h),
              DarkInputField(
                controller: fatherNameController,
                label: "Father's Name",
                hintText: "Enter father's name",
                textCapitalization: TextCapitalization.words,
              ),

              SizedBox(height: 32.h),
              const _SectionHeader(title: "Contact Information"),
              SizedBox(height: 16.h),
              DarkInputField(
                controller: emailController,
                label: "Email Address",
                hintText: "Enter email",
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 24.h),
              DarkInputField(
                controller: phoneController,
                label: "Phone Number",
                hintText: "Enter 10-digit phone number",
                keyboardType: TextInputType.phone,
              ),

              const _SectionHeader(title: "Address Details"),

              DarkInputField(
                controller: addressLine1Controller,
                label: "Address Line 1",
                hintText: "Enter address line 1",
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 24.h),
              DarkInputField(
                controller: cityController,
                label: "City",
                hintText: "Enter city",
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 24.h),
              DarkInputField(
                controller: pincodeController,
                label: "Pincode",
                hintText: "Enter 6-digit pincode",
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24.h),
              GetBuilder<UserController>(
                builder: (userController) {
                  final hasProfileAddress =
                      userController.userData?.uccProfile?['address'] != null;

                  if (hasProfileAddress) {
                    return Column(
                      children: [
                        SizedBox(height: 12.h),
                        GestureDetector(
                          onTap: _applyPrimaryAddress,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Icon(
                                _isSameAsPrimary
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20.w,
                                color:
                                    _isSameAsPrimary
                                        ? AppColors.darkAccentGreen
                                        : AppColors.darkTextSecondary,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                "Same Address from Primary holder",
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.secondary,
                                weight: AppTextWeight.medium,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 32.h),
              const _SectionHeader(title: "Signature"),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                height: 200.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SfSignaturePad(
                    key: _signaturePadKey,
                    backgroundColor: Colors.white,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 2.0,
                    maximumStrokeWidth: 4.0,
                    onDrawStart: () {
                      if (!_hasSignature) {
                        setState(() {
                          _hasSignature = true;
                        });
                      }
                      return false;
                    },
                  ),
                ),
              ),

              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _signaturePadKey.currentState!.clear();
                    setState(() {
                      _hasSignature = false;
                    });
                  },
                  child: AppText(
                    "CLEAR",
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.link,
                  ),
                ),
              ),

              Obx(
                () => AppButton(
                  isFullWidth: true,
                  text: "Save Changes",
                  isLoading: controller.isOperationLoading.value,
                  onPressed: _updateHolder,
                ),
              ),
              // SizedBox(height: 32.h),
              // _buildStatusInfo(),
              // SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  String _getGenderDisplay(String code) {
    if (code == 'M') return 'Male';
    if (code == 'F') return 'Female';
    return 'Other';
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(Icons.person, size: 40.w, color: AppColors.darkPrimary),
          ),
          SizedBox(height: 16.h),
          AppText(
            holder.name,
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
          ),
          SizedBox(height: 4.h),
          AppText(
            "PAN: ${holder.panNumber}",
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _StatusRow(
            label: "Verification Status",
            value: holder.isVerified ? "Verified" : "Pending",
            valueColor:
                holder.isVerified ? AppColors.success : AppColors.warning,
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 32.h),
          _StatusRow(
            label: "Investor Residency",
            value: holder.investorResidency,
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 32.h),
          _StatusRow(
            label: "Masked Aadhaar",
            value: holder.maskedAadhaar ?? "Not available",
          ),
        ],
      ),
    );
  }

  void _updateHolder() async {
    String? signatureBase64;

    if (_hasSignature) {
      try {
        // Step 1: Capture signature as image
        final ui.Image signatureImage =
            await _signaturePadKey.currentState!.toImage();

        // Step 2: Convert to PNG bytes (SfSignaturePad limitation: only PNG available)
        final ByteData? byteData = await signatureImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData != null) {
          final Uint8List pngBytes = byteData.buffer.asUint8List();

          // Step 3: Convert to JPEG (API requirement)
          final jpegBytes = await ImageCompressionHelper.compressFromMemory(
            imageBytes: pngBytes,
          );

          // Step 4: Convert to Base64
          signatureBase64 = ImageCompressionHelper.convertToBase64(jpegBytes);
        }
      } catch (e) {
        AppLogger.error(
          'Error capturing signature',
          error: e,
          tag: 'HolderDetailScreen',
        );
        Get.snackbar(
          "Error",
          "Failed to process signature. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }
    }

    final Map<String, dynamic> data = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone_number': phoneController.text.trim(),
      'dob': dobController.text.trim(),
      'gender': _selectedGender,
      'investor_residency': _selectedResidency,
      'father_name': fatherNameController.text.trim(),
      'address': {
        'address_line_1': addressLine1Controller.text.trim(),
        'city': cityController.text.trim(),
        'pincode': pincodeController.text.trim(),
      },
    };

    if (_selectedResidency != 'Resident') {
      data['tin'] = tinController.text.trim();
    }

    if (signatureBase64 != null) {
      data['signature'] = signatureBase64;
    }

    final success = await controller.updateHolder(holder.id, data);
    if (success) {
      Get.snackbar(
        "Updated",
        "Holder details updated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Error",
        "Failed to update details.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _confirmDelete() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Remove Holder?",
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 16),
              AppText(
                "Are you sure you want to remove ${holder.name} from your joint holders?",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: "Cancel",
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: "Remove",
                      variant: AppButtonVariant.destructive,
                      onPressed: () async {
                        Get.back();
                        final success = await controller.removeHolder(
                          holder.id,
                        );
                        if (success) {
                          Get.back();
                          Get.snackbar(
                            "Removed",
                            "Holder removed successfully.",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.success,
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            "Error",
                            "Failed to remove holder.",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.error,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppText(
      title,
      variant: AppTextVariant.bodyLarge,
      weight: AppTextWeight.bold,
      colorType: AppTextColorType.primary,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.muted,
        ),
        AppText(
          value,
          variant: AppTextVariant.bodySmall,
          customColor: valueColor,
          weight: AppTextWeight.semiBold,
        ),
      ],
    );
  }
}
