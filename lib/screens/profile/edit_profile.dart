import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/error_message.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _userController = Get.find<UserController>();
  final _authService = AuthService();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  File? _selectedImage;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing user data
    final user = _userController.userData;
    if (user != null) {
      firstNameController.text = user.firstname ?? '';
      lastNameController.text = user.lastname ?? '';
      if (user.dob != null) {
        dobController.text =
            "${user.dob!.day}/${user.dob!.month}/${user.dob!.year}";
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = File(result.files.first.path!);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Edit Profile",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: InkWell(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Avatar(
                          path:
                              _selectedImage?.path ??
                              (_userController.userData?.gender
                                          ?.toLowerCase() ==
                                      'female'
                                  ? 'assets/svgs/dashboard/female.png'
                                  : 'assets/svgs/dashboard/male.png'),
                          width: 100,
                          height: 100,
                          isNetworkImage: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: AppText(
                "Upload image",
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.secondary,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedErrorMessage(message: _errorMessage),
            const SizedBox(height: 14),

            const AppText(
              'First Name',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
            const SizedBox(height: 6),
            AppInputField(
              controller: firstNameController,
              hintText: "First Name",
              validator: AppValidators.validateFirstName,
              inputFormatters: AppInputFormatters.firstNameFormatters(),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            const AppText(
              'Last Name',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
            const SizedBox(height: 6),
            AppInputField(
              controller: lastNameController,
              hintText: "Last Name",
              validator: AppValidators.validateLastName,
              inputFormatters: AppInputFormatters.lastNameFormatters(),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            const AppText(
              'Date of Birth',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
            const SizedBox(height: 6),
            AppInputField(
              controller: dobController,
              hintText: "DD/MM/YYYY",
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: AppValidators.validateDOB,
              inputFormatters: AppInputFormatters.dobFormatters(),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar:
          true
              ? SizedBox()
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                    ),

                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      width: double.infinity,
                      child: AppButton(
                        text: "Save Changes",
                        onPressed: () async {
                          final currentUser = _userController.userData;
                          if (currentUser != null) {
                            try {
                              // Parse the date string
                              final dateParts = dobController.text.split('/');
                              final dob =
                                  dateParts.length == 3
                                      ? "${dateParts[2]}-${dateParts[1]}-${dateParts[0]}"
                                      : null;

                              // First upload the image if selected
                              String? imageUrl;
                              if (_selectedImage != null) {
                                // TODO: Implement image upload API call
                                // For now, we'll skip image upload
                              }

                              // Update user profile
                              final response = await _authService
                                  .updateUserProfile(
                                    firstname: firstNameController.text,
                                    lastname: lastNameController.text,
                                    dob: dob ?? '',
                                    profileImage: imageUrl,
                                    onLoading: (loading) {
                                      // Handle loading state if needed
                                    },
                                  );

                              if (response.success) {
                                // Refresh user data
                                await _userController.fetchUserProfile(
                                  onLoading: (loading) {
                                    // Handle loading state if needed
                                  },
                                );
                                Get.back(); // Return to profile screen after update
                              } else {
                                setState(() {
                                  _errorMessage = response.message;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Failed to update profile: $e';
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
