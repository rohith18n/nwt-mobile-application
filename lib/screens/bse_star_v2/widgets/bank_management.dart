import 'package:nwt_app/utils/bse_error_translator.dart';
import 'package:nwt_app/services/bse_star/bank_ifsc_validator.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/bank_management.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart' as aa_bank;
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/constants/bank_list.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/types/auth/bank_details.dart';

class BankManagement extends StatefulWidget {
  final VoidCallback? onNext; // Callback to navigate to next screen
  final VoidCallback? onError; // Callback to notify of errors
  final bool shouldSubmit; // Flag to trigger submission
  final List<Bank>? initialData; // Data for pre-filling
  final String? taxStatus; // Tax status for auto-selection

  const BankManagement({
    super.key,
    this.onNext,
    this.onError,
    this.shouldSubmit = false,
    this.initialData,
    this.taxStatus,
  });

  @override
  State<BankManagement> createState() => _BankManagementState();
}

class _BankManagementState extends State<BankManagement> {
  // Controllers for the form fields
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderNameController =
      TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  // State variables
  String _selectedAccountType = 'SB'; // Default to Savings Bank
  bool _setAsPrimary = true;
  bool _isLoading = false;
  bool _hasDeleted = false;
  bool _isFetchingBankName = false;
  String _bankCountry = 'IND'; // Default to India

  // FocusNodes
  final FocusNode _bankNameNode = FocusNode();
  final FocusNode _ifscCodeNode = FocusNode();
  final FocusNode _accountNumberNode = FocusNode();
  final FocusNode _accountHolderNameNode = FocusNode();
  final FocusNode _upiIdNode = FocusNode();

  // Error Messages State
  String? _bankNameError;
  String? _ifscCodeError;
  String? _accountNumberError;
  String? _accountHolderNameError;
  String? _upiIdError;

  // Linked accounts for validation and auto-fill
  aa_bank.Bank? _selectedBank;
  List<aa_bank.Bank> _linkedBanks = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    } else {
      _initializeAccountTypeFromTaxStatus();
      _fetchBankDetailsFromServer();
    }
    _fetchLinkedBanks();
    _accountNumberController.addListener(_onAccountNumberChanged);
    // Listen for shouldSubmit changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _submitBankData();
      }
    });
  }

  void _prepopulateFromInitialData() {
    final bank = widget.initialData!.first;
    _bankNameController.text = bank.bankName ?? '';
    _ifscCodeController.text = bank.ifscCode ?? '';
    _accountNumberController.text = bank.accountNumber ?? '';
    _accountHolderNameController.text = bank.accountHolderName ?? '';
    _selectedAccountType = bank.accountType ?? 'SB';
    _setAsPrimary = bank.isPrimary;
  }

  void _initializeAccountTypeFromTaxStatus() {
    if (widget.taxStatus == '21') {
      _selectedAccountType = 'NE'; // NRI - NRE
    } else if (widget.taxStatus == '24') {
      _selectedAccountType = 'NO'; // NRI - NRO
    } else if (widget.taxStatus == '01') {
      _selectedAccountType = 'SB'; // Resident Savings
    } else {
      _selectedAccountType = 'SB'; // Default
    }
  }

  @override
  void didUpdateWidget(BankManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger submission when shouldSubmit changes from false to true
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitBankData();
      });
    }

    // Re-populate if initialData changed
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null &&
        widget.initialData!.isNotEmpty) {
      _prepopulateFromInitialData();
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    _accountNumberController.removeListener(_onAccountNumberChanged);
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _bankNameNode.dispose();
    _ifscCodeNode.dispose();
    _accountNumberNode.dispose();
    _accountHolderNameNode.dispose();
    _upiIdNode.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  bool get _isPrefilled =>
      widget.initialData != null &&
      widget.initialData!.isNotEmpty &&
      !_hasDeleted;

  // Validate form fields
  bool _validateForm({bool autoScroll = true}) {
    String? bankNameError;
    String? ifscCodeError;
    String? accountNumberError;
    String? accountHolderNameError;
    String? upiIdError;

    bool isValid = true;

    if (_bankNameController.text.trim().isEmpty) {
      bankNameError = 'Please enter your bank name';
      isValid = false;
    }
    if (_ifscCodeController.text.trim().isEmpty) {
      ifscCodeError = 'Please enter 11-character IFSC code';
      isValid = false;
    } else if (_ifscCodeController.text.trim().length != 11) {
      ifscCodeError = 'IFSC code must be 11 characters long';
      isValid = false;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      accountNumberError = 'Please enter your account number';
      isValid = false;
    } else if (_selectedBank != null) {
      final text = _accountNumberController.text.trim();
      final maskedId = _selectedBank!.maskedaccountid;
      if (text.length >= 4) {
        final last4 = text.substring(text.length - 4);
        if (!maskedId.endsWith(last4)) {
          accountNumberError = 'Last 4 digits do not match selected account';
          isValid = false;
        }
      }
    }
    if (_accountHolderNameController.text.trim().isEmpty) {
      accountHolderNameError = 'Please enter account holder name';
      isValid = false;
    }

    final upi = _upiIdController.text.trim();
    if (upi.isNotEmpty && !upi.contains('@')) {
      upiIdError = 'Please enter a valid UPI ID (e.g. user@bank)';
      isValid = false;
    }

    // Account type is auto-determined from tax status, no validation needed

    setState(() {
      _bankNameError = bankNameError;
      _ifscCodeError = ifscCodeError;
      _accountNumberError = accountNumberError;
      _accountHolderNameError = accountHolderNameError;
      _upiIdError = upiIdError;
    });

    return isValid;
  }

  // Submit bank data to service
  Future<void> _submitBankData() async {
    if (_isPrefilled) {
      if (widget.onNext != null) {
        widget.onNext!();
      }
      return;
    }

    if (!_validateForm()) {
      widget.onError?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService().updateBankDetails(
        bankName: _bankNameController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        bankType: _selectedAccountType,
        upiId: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
      );

      if (response != null && response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank information saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to next screen after successful submission
        if (widget.onNext != null) {
          widget.onNext!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                BseErrorTranslator.getFriendlyErrorMessage(
                  response?.message ?? 'Failed to verify bank information',
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        widget.onError?.call();
      }
    } catch (e) {
      widget.onError?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch bank details from IFSC
  Future<void> _fetchBankDetails(String ifsc) async {
    setState(() {
      _isFetchingBankName = true;
      _bankNameError = null;
    });

    try {
      final response = await BankIfscValidatorService.validateIfsc(ifsc);
      if (response != null &&
          response.statusCode == 200 &&
          response.data != null) {
        final data = response.data;
        // Try multiple common field names for bank name
        final String? bankName =
            data['BANK'] ?? data['bank'] ?? data['bank_name'];

        if (bankName != null && bankName.isNotEmpty) {
          setState(() {
            _bankNameController.text = bankName.toUpperCase();
            _bankNameError = null;
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching bank name via IFSC: $e',
        tag: 'BankManagement',
      );
    } finally {
      setState(() {
        _isFetchingBankName = false;
      });
    }
  }

  Future<void> _fetchBankDetailsFromServer() async {
    setState(() => _isLoading = true);
    try {
      final response = await ProfileService().getBankDetails();
      if (response != null && response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          if (data.bankName.isNotEmpty) _bankNameController.text = data.bankName;
          if (data.ifscCode.isNotEmpty) _ifscCodeController.text = data.ifscCode;
          if (data.accountNumber.isNotEmpty) {
            _accountNumberController.text = data.accountNumber;
          }
          if (data.upiId != null) _upiIdController.text = data.upiId!;
          if (data.bankType.isNotEmpty) _selectedAccountType = data.bankType;
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching bank details from V1 API: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBankSelectionBottomSheet() {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredBanks = List.from(INDIAN_BANKS);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Select Bank',
                      variant: AppTextVariant.headline6,
                      weight: AppTextWeight.bold,
                      customColor: Colors.white,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DarkInputField(
                  controller: searchController,
                  hintText: 'Search bank name...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  onChanged: (val) {
                    setModalState(() {
                      filteredBanks =
                          INDIAN_BANKS
                              .where(
                                (bank) => bank.toLowerCase().contains(
                                  val.toLowerCase(),
                                ),
                              )
                              .toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredBanks.length,
                    separatorBuilder:
                        (context, index) =>
                            const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final bank = filteredBanks[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: AppText(
                          bank,
                          variant: AppTextVariant.bodyMedium,
                          customColor: Colors.white,
                        ),
                        onTap: () {
                          setState(() {
                            _bankNameController.text = bank;
                            _bankNameError = null;
                          });
                          Get.back();
                          _validateForm(autoScroll: false);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _fetchLinkedBanks() {
    try {
      final provider = getAccountAggregatorDataProvider();
      final banks = provider.getBanks();
      if (banks != null) {
        setState(() {
          _linkedBanks = banks;
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching linked banks: $e');
    }
  }

  void _onAccountNumberChanged() {
    final text = _accountNumberController.text.trim();

    // Trigger validation (including last 4 digits check)
    _validateForm(autoScroll: false);

    // Auto-fill lookup if name is empty
    if (text.length >= 4 && _accountHolderNameController.text.isEmpty) {
      final last4 = text.substring(text.length - 4);
      final match = _linkedBanks.firstWhereOrNull(
        (b) => b.maskedaccountid.endsWith(last4),
      );

      if (match != null) {
        setState(() {
          _accountHolderNameController.text = match.profile.name ?? '';
          // If no bank is explicitly selected, pre-fill its info too
          if (_selectedBank == null) {
            _bankNameController.text = match.fipname;
            _ifscCodeController.text = match.ifsc ?? '';
            _selectedAccountType = _mapAccountType(match.type);
          }
        });
      }
    }
  }

  // Fetch bank details from AA
  Future<void> _fetchFromLinkedAccounts() async {
    final provider = getAccountAggregatorDataProvider();
    final linkedBanks = provider.getBanks();

    if (linkedBanks == null || linkedBanks.isEmpty) {
      Get.snackbar(
        'No Linked Accounts',
        'No bank accounts found in your linked Account Aggregator data.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Always show selection bottom sheet per user preference
    _showBankSelectionDialog(linkedBanks);
  }

  void _showBankSelectionDialog(List<aa_bank.Bank> banks) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Select Linked Account',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              customColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: banks.length,
                separatorBuilder:
                    (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: AppText(
                      bank.fipname,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      customColor: Colors.white,
                    ),
                    subtitle: AppText(
                      'Account: ${bank.maskedaccountid}',
                      variant: AppTextVariant.caption,
                      customColor: Colors.white70,
                    ),
                    onTap: () {
                      Get.back();
                      _applyBankData(bank);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyBankData(aa_bank.Bank bank) {
    setState(() {
      _selectedBank = bank;
      _bankNameController.text = bank.fipname;
      _ifscCodeController.text = bank.ifsc ?? '';
      _accountHolderNameController.text = bank.profile.name ?? '';
      _accountNumberController.text = ''; // Masked in AA, must be manual
      _selectedAccountType = _mapAccountType(bank.type);
    });

    // Clear errors when pre-filling
    _validateForm(autoScroll: false);

    // Get.snackbar(
    //   'Account Fetched',
    //   'Bank information pre-filled from your linked account.',
    //   backgroundColor: Colors.blue.withOpacity(0.8),
    //   colorText: Colors.white,
    // );
  }

  String _mapAccountType(String? type) {
    if (type == null) return 'SB';
    final t = type.toLowerCase();
    if (t.contains('saving')) return 'SB';
    if (t.contains('nro')) return 'NO';
    if (t.contains('nre')) return 'NE';
    if (t.contains('current')) return 'CA';
    return 'SB';
  }

  void _clearSelectedBank() {
    setState(() {
      _selectedBank = null;
      _bankNameController.clear();
      _ifscCodeController.clear();
      _accountNumberController.clear();
      _accountHolderNameController.clear();
      _selectedAccountType = 'SB';
    });
    _validateForm(autoScroll: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Bank Account Details',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'Please provide your bank account information for verification and transactions.',
          weight: AppTextWeight.medium,
        ),
        const SizedBox(height: 8),
        AppText(
          'For testing transactions and help us verify your bank account, once you enter your bank account details, we drop a penny (Re.1 in our case) to your bank account',
          variant: AppTextVariant.caption,
          customColor: Colors.white70,
        ),
        if (_isPrefilled) ...[
          const SizedBox(height: 16),
          AppButton(
            text: 'Delete & Reset Bank',
            leadingIcon: Icons.delete_outline,
            onPressed: () async {
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text(
                    'Delete Bank Details?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'This will remove your current bank information and allow you to add a fresh account.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final bankId = widget.initialData!.first.id;
                if (bankId != null) {
                  setState(() => _isLoading = true);
                  final success = await BankManagementService.deleteBank(
                    bankId,
                  );
                  setState(() => _isLoading = false);

                  if (success) {
                    setState(() => _hasDeleted = true);
                    _clearSelectedBank();
                    // Force refresh progress
                    Get.snackbar(
                      'Success',
                      'Bank details deleted. You can now add a new account.',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to delete bank details. Please try again.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              }
            },
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
          ),
        ],
        const SizedBox(height: 16),
        if (!_isPrefilled) ...[
          if (_selectedBank != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      'Linked Account Selected',
                      variant: AppTextVariant.bodyMedium,
                      customColor: Colors.blue,
                      weight: AppTextWeight.medium,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSelectedBank,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_linkedBanks.isNotEmpty) ...[
            AppButton(
              text: 'Select from Linked Accounts',
              leadingIcon: Icons.account_balance_wallet_outlined,
              onPressed: _fetchFromLinkedAccounts,
              variant: AppButtonVariant.outlined,
              isFullWidth: true,
            ),
            const SizedBox(height: 32),
          ],
        ],
        AppText(
          'Bank Information',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkInputField(
          key: const ValueKey('bank_name'),
          focusNode: _bankNameNode,
          label: 'Bank Name',
          controller: _bankNameController,
          hintText: 'Select bank',
          readOnly: true,
          onTap:
              _isPrefilled || _selectedBank != null
                  ? null
                  : _showBankSelectionBottomSheet,
          suffixIcon:
              _isFetchingBankName
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          onChanged: (value) => _validateForm(autoScroll: false),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedErrorMessage(errorMessage: _bankNameError),
        ),
        const SizedBox(height: 16),
        DarkInputField(
          key: const ValueKey('bank_ifsc'),
          focusNode: _ifscCodeNode,
          label: 'IFSC Code',
          controller: _ifscCodeController,
          hintText: 'Enter IFSC code',
          readOnly: _isPrefilled || _selectedBank != null,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            final ifsc = value.trim().toUpperCase();
            _validateForm(autoScroll: false);

            if (ifsc.length == 11 && _ifscCodeError == null) {
              _fetchBankDetails(ifsc);
            }
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(11),
            UpperCaseTextFormatter(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedErrorMessage(errorMessage: _ifscCodeError),
        ),
        const SizedBox(height: 16),
        DarkInputField(
          key: const ValueKey('bank_account_number'),
          focusNode: _accountNumberNode,
          label: 'Account Number',
          controller: _accountNumberController,
          hintText: 'Enter bank account number',
          keyboardType: TextInputType.number,
          readOnly: _isPrefilled,
          onChanged: (value) => _validateForm(autoScroll: false),
          helperText:
              'Enter full account number. Pre-filled data may be masked for security.',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedErrorMessage(errorMessage: _accountNumberError),
        ),
        const SizedBox(height: 16),
        DarkInputField(
          key: const ValueKey('bank_holder_name'),
          focusNode: _accountHolderNameNode,
          label: 'Account Holder Name',
          controller: _accountHolderNameController,
          hintText: 'Enter name as per bank records',
          readOnly: _isPrefilled,
          onChanged: (value) => _validateForm(autoScroll: false),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedErrorMessage(errorMessage: _accountHolderNameError),
        ),
        const SizedBox(height: 16),
        DarkInputField(
          key: const ValueKey('bank_upi_id'),
          focusNode: _upiIdNode,
          label: 'UPI ID (Optional)',
          controller: _upiIdController,
          hintText: 'e.g. username@bank',
          readOnly: _isPrefilled,
          onChanged: (value) => _validateForm(autoScroll: false),
          helperText: 'Using a UPI ID can help in faster withdrawals.',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AnimatedErrorMessage(errorMessage: _upiIdError),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
