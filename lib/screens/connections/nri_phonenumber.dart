import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';

class NriPhonenumber extends StatefulWidget {
  const NriPhonenumber({super.key});

  @override
  State<NriPhonenumber> createState() => _NriPhonenumberState();
}

class _NriPhonenumberState extends State<NriPhonenumber> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final AccountAggregatorRouter _accountAggregatorRouter = AccountAggregatorRouter();
  bool _isLoading = false;
  String? _errorMessage;
  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
  ];

  late String _selectedCountryCode;
  late String _selectedCountryFlag;
  bool _isAutoDetected = false;
  bool _agreed = true;
  
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _onPhoneNumberChanged() {
    // Store current cursor position and previous text length
    final currentPosition = _phoneController.selection.baseOffset;
    final text = _phoneController.text;

    // Only allow digits and limit to 10 characters
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    final limitedText =
        digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    if (limitedText != text) {
      // Calculate new cursor position
      int newPosition = currentPosition;

      // If text was filtered (non-digits removed), adjust cursor position
      if (digitsOnly != text) {
        // Adjust cursor position based on how many characters were removed before cursor
        final beforeCursor = text.substring(0, currentPosition);
        final digitsBeforeCursor = beforeCursor.replaceAll(RegExp(r'\D'), '');
        newPosition = digitsBeforeCursor.length;
      }

      // If text was truncated, ensure cursor doesn't go beyond text length
      if (limitedText.length < digitsOnly.length) {
        newPosition = newPosition.clamp(0, limitedText.length);
      }

      // Update text and cursor position
      _phoneController.value = TextEditingValue(
        text: limitedText,
        selection: TextSelection.collapsed(
          offset: newPosition.clamp(0, limitedText.length),
        ),
      );
    }

    // Auto-detection logic for Indian numbers
    if (limitedText.length == 1 && !_isAutoDetected) {
      final firstDigit = int.tryParse(limitedText);
      if (firstDigit != null && firstDigit >= 6 && firstDigit <= 9) {
        setState(() {
          _selectedCountryCode = '+91';
          _selectedCountryFlag = '🇮🇳';
          _isAutoDetected = true;
        });
      }
    } else if (limitedText.isEmpty) {
      _isAutoDetected = false;
    }

    // Close keyboard only when reaching 10 digits (not when reducing from 10)
    if (limitedText.length == 10 && _phoneFocusNode.hasFocus) {
      _phoneFocusNode.unfocus();
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Select Country",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: AppText(
                        country['name']!,
                        variant: AppTextVariant.bodyMedium,
                      ),
                      trailing: AppText(
                        country['code']!,
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
                          _selectedCountryFlag = country['flag']!;
                          _isAutoDetected = true;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitPhoneNumber() {
    _performSubmission();
  }

  Future<void> _performSubmission() async {
    // Unfocus any text field first to ensure keyboard is dismissed
    _phoneFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate phone number
    if (_phoneController.text.length != 10) {
      setState(() {
        _errorMessage = "Please enter a valid 10-digit phone number";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement NRI phone number submission logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    setState(() {
      _isLoading = false;
    });

    // Open Saafe SDK directly with the entered phone number
    AppLogger.info(
      "NRI phone number submitted: ${_phoneController.text}",
      tag: 'NriPhonenumber',
    );
    
    // Open AA connection flow (Finarkein or Saafe) with the entered phone number
    await _accountAggregatorRouter.openConnection(
      context,
      phoneNumber: _phoneController.text,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = '+91';
    _selectedCountryFlag = '🇮🇳';

    // Auto-focus the phone input field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });

    // Listen to text changes with proper cursor management
    _phoneController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneNumberChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/onboarding/stars.svg',
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.15,
                      ),
                      AppText(
                        "Add Indian \nPhone Number",
                        variant: AppTextVariant.headline1,
                        lineHeight: 1.3,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                      const SizedBox(height: 6),
                      AppText(
                        "Required for account aggregator services.",
                        variant: AppTextVariant.bodyMedium,
                        lineHeight: 1.3,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.secondary,
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          AppText(
                            "Enter your Indian phone number",
                            variant: AppTextVariant.headline4,
                            lineHeight: 1.3,
                            weight: AppTextWeight.semiBold,
                            colorType: AppTextColorType.primary,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                      Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Country Code Dropdown
                                GestureDetector(
                                  onTap: _showCountryPicker,
                                  child: Container(
                                    height: 56, // Match typical input field height
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkCardBG,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.darkButtonBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _selectedCountryFlag,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        AppText(
                                          _selectedCountryCode,
                                          variant: AppTextVariant.bodyMedium,
                                          weight: AppTextWeight.medium,
                                          colorType: AppTextColorType.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Phone Number Input
                                Expanded(
                                  child: AppInputField(
                                    readOnly: false,
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    hintText: "Eg. 1234567890",
                                    validator: AppValidators.validatePhone,
                                    keyboardType: TextInputType.phone,
                                    type: AppInputFieldType.phone,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedErrorMessage(errorMessage: _errorMessage),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Terms and Privacy Policy checkbox
               
                  // const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Submit',
                isLoading: _isLoading,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () {_submitPhoneNumber();},
              ),
            ),
          ],
        ),
      ),
    );
  }
}