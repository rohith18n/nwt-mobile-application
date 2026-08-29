import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/services/bse_star/bank_ifsc_validator.dart';
import 'package:nwt_app/utils/logger.dart';

class BankAccountScreen extends StatefulWidget {
  final TextEditingController ifscController;
  final TextEditingController accountController;
  final String selectedAccountType;
  final ValueChanged<String> onAccountTypeChanged;

  const BankAccountScreen({
    super.key,
    required this.ifscController,
    required this.accountController,
    required this.selectedAccountType,
    required this.onAccountTypeChanged,
  });

  @override
  State<BankAccountScreen> createState() => BankAccountScreenState();
}

class BankAccountScreenState extends State<BankAccountScreen> {
  static const String _tag = 'BankAccountScreen';
  Timer? _debounce;
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isValid;
  String? _accountNumberError;

  @override
  void initState() {
    super.initState();
    widget.ifscController.addListener(_onIfscChanged);
    widget.accountController.addListener(_onAccountNumberChanged);
    
    // Check if IFSC is pre-filled from database (already validated)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrefilledIfsc();
    });
  }
  
  /// Check if IFSC code is pre-filled from database and mark as validated
  void _checkPrefilledIfsc() {
    final ifscCode = widget.ifscController.text.trim();
    if (ifscCode.isNotEmpty && ifscCode.length == 11) {
      AppLogger.info('IFSC code pre-filled from database, marking as validated: $ifscCode', tag: _tag);
      setState(() {
        _isValid = true;
        _validationMessage = 'Valid IFSC code';
      });
    }
  }

  // Public getter for IFSC validation state
  bool? get isIfscValid => _isValid;
  
  /// Public method to mark IFSC as pre-validated (e.g., when loaded from database)
  void markIfscAsValidated() {
    final ifscCode = widget.ifscController.text.trim();
    if (ifscCode.isNotEmpty && ifscCode.length == 11) {
      AppLogger.info('Manually marking IFSC as validated: $ifscCode', tag: _tag);
      setState(() {
        _isValid = true;
        _validationMessage = 'Valid IFSC code';
      });
    }
  }
  
  // Public method to validate the entire form
  bool isFormValid() {
    final ifscCode = widget.ifscController.text.trim();
    final accountNumber = widget.accountController.text.trim();
    
    // Check IFSC validation
    if (ifscCode.isEmpty || ifscCode.length != 11) {
      AppLogger.warning('IFSC code is invalid or empty', tag: _tag);
      return false;
    }
    
    if (_isValid != true) {
      AppLogger.warning('IFSC code has not been validated or is invalid', tag: _tag);
      return false;
    }
    
    // Check account number validation
    if (accountNumber.isEmpty) {
      AppLogger.warning('Account number is empty', tag: _tag);
      return false;
    }
    
    if (accountNumber.length < 9 || accountNumber.length > 20) {
      AppLogger.warning('Account number length is invalid: ${accountNumber.length}', tag: _tag);
      return false;
    }
    
    // Check account type selection
    if (widget.selectedAccountType.isEmpty) {
      AppLogger.warning('Account type not selected', tag: _tag);
      return false;
    }
    
    return true;
  }

  @override
  void dispose() {
    widget.ifscController.removeListener(_onIfscChanged);
    widget.accountController.removeListener(_onAccountNumberChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onAccountNumberChanged() {
    final accountNumber = widget.accountController.text.trim();
    
    if (accountNumber.isEmpty) {
      setState(() {
        _accountNumberError = null;
      });
      return;
    }
    
    if (accountNumber.length < 9) {
      setState(() {
        _accountNumberError = 'Account number must be at least 9 digits';
      });
    } else if (accountNumber.length > 20) {
      setState(() {
        _accountNumberError = 'Account number must not exceed 20 digits';
      });
    } else {
      setState(() {
        _accountNumberError = null;
      });
    }
  }

  void _onIfscChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final ifscCode = widget.ifscController.text.trim();
    
    if (ifscCode.isEmpty) {
      setState(() {
        _validationMessage = null;
        _isValid = null;
        _isValidating = false;
      });
      return;
    }

    // Only validate if IFSC code is 11 characters (standard IFSC length)
    if (ifscCode.length < 11) {
      setState(() {
        _validationMessage = null;
        _isValid = null;
        _isValidating = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
      _isValid = null;
    });

    _debounce = Timer(const Duration(milliseconds: 800), () {
      _validateIfsc(ifscCode);
    });
  }

  Future<void> _validateIfsc(String ifscCode) async {
    try {
      AppLogger.info('Validating IFSC code: $ifscCode', tag: _tag);
      
      final response = await BankIfscValidatorService.validateIfsc(ifscCode);
      
      if (!mounted) return;

      if (response != null) {
        setState(() {
          _isValidating = false;
          _isValid = response.statusCode == 200;
          _validationMessage = response.message ?? 
            (_isValid! ? 'Valid IFSC code' : 'Invalid IFSC code');
        });
        
        AppLogger.info(
          'IFSC validation result: ${_isValid! ? "Valid" : "Invalid"}',
          tag: _tag,
        );
      } else {
        setState(() {
          _isValidating = false;
          _isValid = false;
          _validationMessage = 'Unable to validate IFSC code';
        });
      }
    } catch (e) {
      AppLogger.error('Error validating IFSC: $e', tag: _tag);
      if (!mounted) return;
      
      setState(() {
        _isValidating = false;
        _isValid = false;
        _validationMessage = 'Error validating IFSC code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Bank Validation',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'We need your Indian bank details for investment purposes. As an NRI, we recommend using NRO for your Mutual Fund investments. ',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
       
        const SizedBox(height: 32),
        DarkInputField(
          label: 'IFSC CODE',
          controller: widget.ifscController,
          hintText: 'Enter your IFSC code',
        ),
        if (_isValidating || _validationMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (_isValidating)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              else if (_isValid != null)
                Icon(
                  _isValid! ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: _isValid! ? Colors.green : Colors.red,
                ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText(
                  _isValidating ? 'Validating...' : _validationMessage!,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.medium,
                  customColor: _isValidating
                      ? Colors.blue
                      : (_isValid! ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Account Number',
          controller: widget.accountController,
          hintText: 'Enter your account number',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(20),
          ],
        ),
        if (_accountNumberError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText(
                  _accountNumberError!,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.medium,
                  customColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        AppText(
          'Account Type',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Savings',
          isSelected: widget.selectedAccountType == 'SB',
          onTap: () => widget.onAccountTypeChanged('SB'),
        ),
        const SizedBox(height: 10),
        DarkRadioTile(
          title: 'Current',
          isSelected: widget.selectedAccountType == 'CB',
          onTap: () => widget.onAccountTypeChanged('CB'),
        ),
        const SizedBox(height: 10),
        DarkRadioTile(
          title: 'NRE',
          isSelected: widget.selectedAccountType == 'NE',
          onTap: () => widget.onAccountTypeChanged('NE'),
        ),
        const SizedBox(height: 10),
        DarkRadioTile(
          title: 'NRO',
          isSelected: widget.selectedAccountType == 'NO',
          onTap: () => widget.onAccountTypeChanged('NO'),
        ),
      ],
    );
  }

}
