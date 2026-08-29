import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/calendar_picker.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PANDetailsScreen extends StatefulWidget {
  final String panNumber;

  const PANDetailsScreen({super.key, required this.panNumber});

  @override
  State<PANDetailsScreen> createState() => _PANDetailsScreenState();
}

class _PANDetailsScreenState extends State<PANDetailsScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  // Back press handling variables
  DateTime? _lastBackPressTime;
  static const Duration _backPressTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _panController.text = widget.panNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.panManualEntered);
      AppLogger.info(AnalyticsEvents.panManualEntered, tag: 'event');
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _dobFocusNode.dispose();
    super.dispose();
  }

  // Method to show exit confirmation dialog
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Exit Verification",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Are you sure you want to Logout? Your PAN details progress will be lost.",
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                      Container(
                        height: 52,
                        width: 1,
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _authService.logout();
                            Get.offAll(() => const OnboardingScreen());
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Logout",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.error,
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
  }

  // Method to handle date picker
  void _selectDate() async {
    // Parse the current date from the controller if it exists
    DateTime? currentDate;
    if (_dobController.text.isNotEmpty) {
      try {
        final parts = _dobController.text.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[0]);
          currentDate = DateTime(year, month, day);
        }
      } catch (e) {
        // If parsing fails, use default date
        currentDate = DateTime.now();
      }
    }

    await showAppCalendarPicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
      title: "Select Date of Birth",
      dateFormat: DateFormatType.yyyyMMdd,
      onFormattedDateSelected: (formattedDate) {
        setState(() {
          currentDate = DateTime.parse(formattedDate);
          _dobController.text = formattedDate;
        });
      },
    );
  }

  // Method to submit PAN details
  void _submitPANDetails() async {
    AnalyticsService.to.logEvent(name: AnalyticsEvents.panManualSubmitClicked);
    // Validate all fields
    if (_firstNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your first name";
      });
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter your last name";
      });
      return;
    }

    if (_phoneController.text.trim().isEmpty ||
        _phoneController.text.length != 10) {
      setState(() {
        _errorMessage = "Please enter a valid 10-digit phone number";
      });
      return;
    }

    if (_dobController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please select your date of birth";
      });
      return;
    }

    // Call the manual PAN verification service
    try {
      final response = await _authService.manualPANVerification(
        panNumber: _panController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dob: _dobController.text.trim(),
        panPhoneNumber: _phoneController.text.trim(),
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );

      // Check response
      AppLogger.info(
        'Manual PAN Verification completed: ${response.message}',
        tag: 'PANDetailsScreen',
      );

      if (response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.panManualVerificationSuccess);
        // Clear any error messages on success
        setState(() {
          _errorMessage = null;
        });

        // Navigate to next screen immediately
        Get.offAll(
          () => const MutualFundHoldingsJourneyScreen(isInitialJourney: true),
          transition: Transition.rightToLeft,
        );
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.panManualVerificationFailed,
          parameters: {
            AnalyticsParams.errorMessage: response.message,
          },
        );
        // Show error message
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Manual PAN Verification Error',
        error: e,
        tag: 'PANDetailsScreen',
      );
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    }
  }

  // Method to handle back press with double-tap to exit
  Future<bool> _onWillPop() async {
    final DateTime now = DateTime.now();

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > _backPressTimeout) {
      // First back press or timeout exceeded
      _lastBackPressTime = now;

      // Show snackbar message
      Get.showSnackbar(
        GetSnackBar(
          message: 'Press back again to exit',
          duration: _backPressTimeout,
          backgroundColor: Colors.black87,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          snackPosition: SnackPosition.BOTTOM,
        ),
      );

      return false; // Don't exit
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: SizedBox(),
          centerTitle: true,
          title: AppText(
            "PAN Details",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
          actions: [
            TextButton(
              onPressed: () => _showExitConfirmationDialog(context),
              child: AppText(
                "Logout",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.error,
                weight: AppTextWeight.semiBold,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Lottie animation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: Lottie.asset('assets/lottie/pan.json'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // PAN Number Field (Disabled)
                        AppText(
                          "PAN Number",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _panController,
                          hintText: "PAN Number",
                          // readOnly: true,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 15),

                        // First Name Field
                        AppText(
                          "First Name",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _firstNameController,
                          focusNode: _firstNameFocusNode,
                          hintText: "Enter your first name",
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: AppValidators.validateFirstName,
                        ),
                        const SizedBox(height: 15),

                        // Last Name Field
                        AppText(
                          "Last Name",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _lastNameController,
                          focusNode: _lastNameFocusNode,
                          hintText: "Enter your last name",
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: AppValidators.validateLastName,
                        ),
                        const SizedBox(height: 15),

                        // Phone Number Field
                        AppText(
                          "Phone Number",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          hintText: "Enter phone number",
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: AppValidators.validatePhone,
                        ),

                        const SizedBox(height: 15),

                        // Date of Birth Field
                        AppText(
                          "Date of Birth",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _dobController,
                          focusNode: _dobFocusNode,
                          hintText: "YYYY-MM-DD",
                          readOnly: true,
                          onTap: _selectDate,
                          suffix: const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: AppColors.darkTextMuted,
                          ),
                          validator: AppValidators.validateISODate,
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.darkPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.darkPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppText(
                                  "Ensure details match your PAN Card exactly for verification",
                                  variant: AppTextVariant.bodyMedium,
                                  colorType: AppTextColorType.primary,
                                  lineHeight: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Error message
                AnimatedErrorMessage(errorMessage: _errorMessage),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: "Continue",
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isLoading: _isLoading,
              isDisabled: _isLoading,
              onPressed: _submitPANDetails,
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }
}
