import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/services/bse_star/tin_details.dart';
import 'package:nwt_app/screens/bse_star/types/tin_details.dart';

// Custom formatter that enforces exact TIN pattern
class _TinPatternFormatter extends TextInputFormatter {
  final String pattern;

  _TinPatternFormatter(this.pattern);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase(); // Convert to uppercase
    
    // Allow deletion
    if (newText.length < oldValue.text.length) {
      return TextEditingValue(
        text: newText,
        selection: newValue.selection,
      );
    }
    
    // Build formatted text based on pattern
    String formattedText = '';
    int inputIndex = 0;
    
    for (int patternIndex = 0; patternIndex < pattern.length && inputIndex < newText.length; patternIndex++) {
      final patternChar = pattern[patternIndex];
      final inputChar = newText[inputIndex];
      
      if (patternChar == '9') {
        // Position expects any digit (explicit 9 in pattern)
        if (RegExp(r'\d').hasMatch(inputChar)) {
          formattedText += inputChar;
          inputIndex++;
        } else {
          // Skip non-digit characters
          inputIndex++;
          patternIndex--; // Retry this pattern position
        }
      } else if (patternChar == ' ') {
        // Auto-insert space
        formattedText += ' ';
        // Don't increment inputIndex, spaces are auto-added
      } else if (RegExp(r'[A-Z]').hasMatch(patternChar)) {
        // Position has a letter in pattern - allow any letter
        if (RegExp(r'[A-Z]').hasMatch(inputChar)) {
          formattedText += inputChar;
          inputIndex++;
        } else {
          // Skip non-letter characters
          inputIndex++;
          patternIndex--; // Retry this pattern position
        }
      } else if (RegExp(r'\d').hasMatch(patternChar)) {
        // Position has a digit in pattern - allow any digit
        if (RegExp(r'\d').hasMatch(inputChar)) {
          formattedText += inputChar;
          inputIndex++;
        } else {
          // Skip non-digit characters
          inputIndex++;
          patternIndex--; // Retry this pattern position
        }
      } else {
        // Position expects specific special character
        if (inputChar == patternChar) {
          formattedText += inputChar;
          inputIndex++;
        } else {
          // Skip invalid characters for special characters
          inputIndex++;
          patternIndex--; // Retry this pattern position
        }
      }
    }
    
    // Don't exceed pattern length
    if (formattedText.length > pattern.length) {
      formattedText = formattedText.substring(0, pattern.length);
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ForeignAddressScreen extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController pincodeController;
  final TextEditingController tinController;
  final bool isNRI;

  const ForeignAddressScreen({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.pincodeController,
    required this.tinController,
    this.isNRI = false,
  });

  @override
  State<ForeignAddressScreen> createState() => _ForeignAddressScreenState();
}

class _ForeignAddressScreenState extends State<ForeignAddressScreen> {
  TinResponseData? _tinDetails;
  bool _isLoadingTinDetails = false;

  // Create input formatter based on TIN format pattern
  List<TextInputFormatter> _getTinInputFormatters() {
    if (_tinDetails?.data.tinFormatLegalEntities == null) {
      return []; // No restrictions if no data
    }

    final format = _tinDetails!.data.tinFormatLegalEntities!;
    
    return [
      _TinPatternFormatter(format),
      LengthLimitingTextInputFormatter(format.length),
    ];
  }

  // Validate TIN format based on pattern
  String? _validateTinFormat(String? value) {
    if (value == null || value.isEmpty) {
      return 'TIN is required';
    }

    if (_tinDetails?.data.tinFormatLegalEntities == null) {
      return null; // No validation if no format data
    }

    final format = _tinDetails!.data.tinFormatLegalEntities!;
    final cleanValue = value.replaceAll(' ', '').toUpperCase();
    final cleanFormat = format.replaceAll(' ', '').toUpperCase();
    
    // Create regex pattern from format
    String regexPattern = '';
    for (int i = 0; i < cleanFormat.length; i++) {
      final char = cleanFormat[i];
      if (char == '9') {
        regexPattern += r'\d'; // Digit
      } else if (RegExp(r'[A-Z]').hasMatch(char)) {
        regexPattern += r'[A-Z]'; // Letter
      } else {
        regexPattern += RegExp.escape(char); // Literal character
      }
    }
    
    final regex = RegExp('^$regexPattern\$');
    
    if (!regex.hasMatch(cleanValue)) {
      return 'TIN must match format: $format';
    }
    
    return null;
  }

  void _showTinInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        width: double.infinity,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Tax Identification Number (TIN)',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.white,
              ),
              const SizedBox(height: 16),
              if (_isLoadingTinDetails)
                const Center(child: CircularProgressIndicator())
              else if (_tinDetails != null && _tinDetails!.data.comment != null && _tinDetails!.data.comment!.isNotEmpty)
                AppText(
                  _tinDetails!.data.comment!,
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.white,
                )
              else
                AppText(
                  'Enter a country name to get TIN format information.',
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.gray,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchTinDetails() async {
    final country = widget.countryController.text.trim();
    if (country.isEmpty) return;

    setState(() {
      _isLoadingTinDetails = true;
    });

    try {
      final tinDetails = await BseTinDetailsService.getTinDetails(country: country);
      setState(() {
        _tinDetails = tinDetails;
        _isLoadingTinDetails = false;
        // Clear TIN field when country changes to apply new validation
        widget.tinController.clear();
      });
    } catch (e) {
      setState(() {
        _isLoadingTinDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          widget.isNRI ? 'Enter Your Foreign Address' : 'Enter Your Address',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          widget.isNRI 
              ? 'Please provide your foreign address details for KYC verification.'
              : 'Please provide your address details for KYC verification.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
        
        const SizedBox(height: 32),
        DarkInputField(
          label: 'Address',
          controller: widget.addressController,
          hintText: 'Enter your complete address',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'City',
          controller: widget.cityController,
          hintText: 'Enter city name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'State',
          controller: widget.stateController,
          hintText: 'Enter state name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Country',
          controller: widget.countryController,
          hintText: 'Enter country name',
          onChanged: (value) {
            // Auto-fetch TIN details when country changes
            if (value.isNotEmpty && value.length > 2) {
              _fetchTinDetails();
            }
          },
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Pincode',
          controller: widget.pincodeController,
          hintText: 'Enter postal/zip code',
        ),
        // Only show TIN field for NRI users
        if (widget.isNRI) ...[
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText(
                    'Tax Identification Number (TIN)',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.white,
                    weight: AppTextWeight.medium,
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () async {
                      await _fetchTinDetails();
                      if (_tinDetails != null && _tinDetails!.data.comment != null && _tinDetails!.data.comment!.isNotEmpty) {
                        _showTinInfoBottomSheet(context);
                      }
                    },
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DarkInputField(
                label: '',
                controller: widget.tinController,
                hintText: _tinDetails?.data.tinFormatLegalEntities ?? 'Enter your TIN',
                inputFormatters: _getTinInputFormatters(),
                validator: _validateTinFormat,
              ),
              if (_tinDetails?.data.tinFormatLegalEntities != null) ...[
                const SizedBox(height: 4),
                AppText(
                  'Expected format: ${_tinDetails!.data.tinFormatLegalEntities}',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.gray,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
