import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/constants/theme.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  DateTime? selectedDate;
  final TextEditingController dobController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current date if needed
    // selectedDate = DateTime.now();
    // updateDobController();
  }

  @override
  void dispose() {
    dobController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  void updateDobController() {
    if (selectedDate != null) {
      dobController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900), // Reasonable minimum date
      lastDate: DateTime.now(), // Not allowing future dates for DOB
      builder: (context, child) {
        return Theme(data: AppTheme.datePickerTheme(isDarkMode), child: child!);
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        updateDobController();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                label: 'Back',
                button: true,
                hint: 'Returns to previous screen',
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    semanticLabel: 'Back',
                  ),
                ),
              ),
            ),
            Center(
              child: Semantics(
                header: true,
                child: AppText(
                  "Profile",
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Semantics(
                        label: 'Profile Picture',
                        image: true,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(112 / 2),
                            child: CachedNetworkImage(
                              width: 112,
                              height: 112,
                              imageUrl:
                                  'https://images.unsplash.com/photo-1633332755192-727a05c4013d?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        label: 'First Name',
                        textField: true,
                        hint: 'Enter your first name',
                        child: AppInputField(
                          controller: firstNameController,
                          hintText: "First Name",
                          labelText: "First Name",
                          validator: AppValidators.validateFirstName,
                          inputFormatters:
                              AppInputFormatters.firstNameFormatters(),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Semantics(
                        label: 'Last Name',
                        textField: true,
                        hint: 'Enter your last name',
                        child: AppInputField(
                          controller: lastNameController,
                          hintText: "Last Name",
                          labelText: "Last Name",
                          validator: AppValidators.validateLastName,
                          inputFormatters:
                              AppInputFormatters.lastNameFormatters(),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Semantics(
                        label: 'Date of Birth',
                        button: true,
                        hint: 'Double tap to select your date of birth',
                        child: AppInputField(
                          controller: dobController,
                          hintText: "DD/MM/YYYY",
                          labelText: "Date of Birth",
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: AppValidators.validateDOB,
                          inputFormatters: AppInputFormatters.dobFormatters(),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Continue',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isLoading: _isLoading,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
