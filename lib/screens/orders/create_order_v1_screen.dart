import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/screens/orders/payment_processing_v1_screen.dart';
import 'package:nwt_app/services/orders/order_service_v1.dart';
import 'package:nwt_app/services/orders/trade_api_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:nwt_app/widgets/common/sip_day_picker.dart';
import 'package:nwt_app/screens/bse_v2_final/ucc_wizard_screen.dart';
import 'package:nwt_app/screens/orders/order_preview_sheet.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class CreateOrderV1Screen extends StatefulWidget {
  final String fundName;
  final String isin;
  final String schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;
  final bool isSipMode;

  const CreateOrderV1Screen({
    super.key,
    required this.fundName,
    required this.isin,
    required this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
    this.isSipMode = false,
  });

  @override
  State<CreateOrderV1Screen> createState() => _CreateOrderV1ScreenState();
}

class _CreateOrderV1ScreenState extends State<CreateOrderV1Screen> {
  late final OrderV1Controller _orderController;
  final MutualFundOrderServiceV1 _orderService = MutualFundOrderServiceV1();
  final TradeApiService _tradeService = TradeApiService();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedFolio;
  bool _isLoading = false;
  bool _isSipMode = false;
  bool _uccValidated = false;
  String? _uccId;
  String? _clientCode;
  String? _paymentUpiId;

  // Polling for UCC sync
  Timer? _uccSyncPollTimer;
  int _uccSyncPollAttempts = 0;
  static const int _maxUccSyncPollAttempts =
      30; // 30 attempts * 10 seconds = 5 minutes max
  String? _pollingMessage;

  // SIP Fields
  int _selectedSipDate = DateTime.now().add(const Duration(days: 7)).day;
  final TextEditingController _installmentsController = TextEditingController(
    text: '24',
  );

  late final Worker _folioWorker;

  @override
  void initState() {
    super.initState();

    // Initialize SIP mode from widget parameter to preserve tab state
    _isSipMode = widget.isSipMode;

    // Initialize or get existing OrderV1Controller
    _orderController =
        Get.isRegistered<OrderV1Controller>()
            ? Get.find<OrderV1Controller>()
            : Get.put(OrderV1Controller());

    // Fetch accounts if not already loaded
    if (_orderController.accounts.isEmpty) {
      _orderController.fetchAccounts();
    }

    // Validate UCC before allowing orders
    _validateUcc();

    // Initial fetch if account already selected
    if (_orderController.selectedAccount.value != null) {
      _orderController.checkFolios(widget.isin);
    }

    // Pre-select first available folio if available
    if (_orderController.availableFolios.isNotEmpty) {
      _selectedFolio = _orderController.availableFolios.first;
    }

    // Listen for folio changes to auto-select if nothing is selected
    _folioWorker = ever(_orderController.availableFolios, (
      List<String> folios,
    ) {
      if (mounted && _selectedFolio == null && folios.isNotEmpty) {
        setState(() {
          _selectedFolio = folios.first;
        });
      }
    });
  }

  Future<void> _validateUcc() async {
    if (_orderController.selectedAccount.value == null) {
      // No account selected yet, will validate when account is selected
      return;
    }

    final account = _orderController.selectedAccount.value!;

    // Check if UCC is investment ready via resolve API
    final response = await _tradeService.tradeUccResolve(
      holdingNature: account.holdingNature,
      nomination: 'skip', // For now, skip nomination check
    );

    if (response != null && response['success'] == true) {
      final data = response['data'];

      if (data['investment_ready'] == true && data['ucc_id'] != null) {
        setState(() {
          _uccValidated = true;
          _uccId = data['ucc_id'];
          _clientCode = data['client_code'];
          _paymentUpiId = data['payment_upi_id'];
        });
      } else if (data['ucc_sync_pending'] == true) {
        _showUccError(
          'UCC is still syncing with BSE. Please try again in a few minutes.',
        );
      } else {
        _showUccError(
          'UCC is not ready for trading. Please complete your UCC setup first.',
        );
      }
    }
  }

  void _showUccError(String message) {
    if (mounted) {
      _showErrorBottomSheet(message);
      // Navigate to UCC wizard
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Get.off(() => const UccWizardScreen());
        }
      });
    }
  }

  void _showErrorBottomSheet(String message) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: AppText(
                'Error',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              textAlign: TextAlign.center,
              colorType: AppTextColorType.secondary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AppText(
                  'OK',
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    _folioWorker.dispose();
    _uccSyncPollTimer?.cancel();
    super.dispose();
  }

  void _startUccSyncPolling({
    required String uccId,
    required String schemeCode,
    required double amount,
    required bool isFresh,
    String? folioNumber,
    required String message,
    bool isSip = false,
    int? installments,
    int? txnDate,
    String? startDate,
    String? mandateId,
  }) {
    print(
      'DEBUG: _startUccSyncPolling called with message: $message, isSip: $isSip',
    );
    _uccSyncPollAttempts = 0;
    setState(() => _pollingMessage = message);
    print('DEBUG: Polling message set, timer starting...');

    _uccSyncPollTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      _uccSyncPollAttempts++;
      print('DEBUG: Polling attempt $_uccSyncPollAttempts');

      if (_uccSyncPollAttempts > _maxUccSyncPollAttempts) {
        timer.cancel();
        setState(() {
          _isLoading = false;
          _pollingMessage = null;
        });
        if (mounted) {
          _showErrorBottomSheet(
            'Order creation is taking longer than expected. Please try again later.',
          );
        }
        return;
      }

      try {
        // Retry order creation based on type
        if (isSip && mandateId != null) {
          print('DEBUG: Retrying SIP creation with mandate...');
          final sipResponse = await _tradeService.tradeSipCreate(
            mandateId: mandateId,
            schemeCode: schemeCode,
            amount: amount,
            txnDate: txnDate ?? _selectedSipDate,
            startDate: startDate ?? _calculateStartDate(),
            installments: installments ?? 24,
            isFresh: isFresh,
            folioNumber: folioNumber,
          );

          if (sipResponse != null && sipResponse['success'] == true) {
            final firstOrderId = sipResponse['data']?['first_order_id'];

            if (firstOrderId != null) {
              timer.cancel();
              setState(() {
                _isLoading = false;
                _pollingMessage = null;
              });
              Get.to(
                () => PaymentProcessingV1Screen(
                  orderData: sipResponse['data']!,
                  isSip: true,
                ),
              );
            } else {
              timer.cancel();
              setState(() {
                _isLoading = false;
                _pollingMessage = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "SIP registered successfully! Installments will be auto-debited.",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Get.back();
            }
          } else {
            // Check if UCC sync is pending - stop polling and show message
            final details = sipResponse?['details'] as Map<String, dynamic>?;
            if (details != null && details['ucc_sync_pending'] == true) {
              timer.cancel();
              setState(
                () =>
                    _pollingMessage =
                        sipResponse?['message']?.toString() ??
                        'UCC is syncing with BSE...',
              );
            } else if (sipResponse != null &&
                sipResponse['message'] != null &&
                sipResponse['message'].toString().isNotEmpty) {
              // Update polling message with backend response for other errors
              setState(
                () => _pollingMessage = sipResponse['message'].toString(),
              );
            }
          }
        } else if (isSip) {
          print('DEBUG: Retrying SIP creation without mandate...');
          final response = await _orderService.createSip(
            uccId: uccId,
            schemeCode: schemeCode,
            amount: amount,
            txnDate: txnDate ?? _selectedSipDate,
            startDate: startDate ?? _calculateStartDate(),
            installments: installments ?? 24,
            isFresh: isFresh,
            folioNumber: folioNumber,
          );

          if (response.success && response.data != null) {
            timer.cancel();
            setState(() {
              _isLoading = false;
              _pollingMessage = null;
            });
            Get.to(
              () => PaymentProcessingV1Screen(
                orderData: response.data!,
                isSip: true,
              ),
            );
          } else {
            // Check if UCC sync is pending - stop polling and show message
            final details = response.details;
            if (details != null && details['ucc_sync_pending'] == true) {
              timer.cancel();
              setState(() => _pollingMessage = response.message);
            } else if (response.message.isNotEmpty) {
              // Update polling message with backend response for other errors
              setState(() => _pollingMessage = response.message);
            }
          }
        } else {
          print('DEBUG: Retrying lumpsum order creation...');
          final response = await _orderService.createOrder(
            uccId: uccId,
            schemeCode: schemeCode,
            amount: amount,
            isFresh: isFresh,
            folioNumber: folioNumber,
          );

          if (response.success && response.data != null) {
            timer.cancel();
            setState(() {
              _isLoading = false;
              _pollingMessage = null;
            });
            Get.to(() => PaymentProcessingV1Screen(orderData: response.data!));
          } else {
            // Check if UCC sync is pending - stop polling and show message
            final details = response.details;
            if (details != null && details['ucc_sync_pending'] == true) {
              timer.cancel();
              setState(() => _pollingMessage = response.message);
            } else if (response.message.isNotEmpty) {
              // Update polling message with backend response for other errors
              setState(() => _pollingMessage = response.message);
            }
          }
        }
      } catch (e) {
        // Continue polling on timeout or network errors - don't stop
        print(
          'DEBUG: Polling attempt $_uccSyncPollAttempts failed with error: $e',
        );
        // Error is silently ignored to prevent overlay crash from snackbar during polling
      }
    });
  }

  String _calculateStartDate() {
    final now = DateTime.now();
    // SIP registration can start from tomorrow.
    DateTime startDate = DateTime(now.year, now.month, _selectedSipDate);
    if (startDate.isBefore(now)) {
      startDate = DateTime(now.year, now.month + 1, _selectedSipDate);
    }
    return "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectSipDate(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SipDayPicker(
            initialDay: _selectedSipDate,
            onDaySelected: (day) {
              setState(() {
                _selectedSipDate = day;
              });
            },
          ),
    );
  }

  Future<void> _handleInvest() async {
    if (!_validateForm(checkAccount: true)) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    // Check if a payment is already being processed
    if (_orderController.isPolling.value &&
        _orderController.activeOrderData.value != null) {
      Get.to(
        () => PaymentProcessingV1Screen(
          orderData: _orderController.activeOrderData.value!,
          isSip: _orderController.activeIsSip.value,
          isRedirected: true,
        ),
        transition: Transition.rightToLeft,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // is_fresh should be true when creating a new folio (no existing folio selected)
      final isFresh = _selectedFolio == null || _selectedFolio == 'New Folio';
      final folioNumber = isFresh ? null : _selectedFolio;

      if (_isSipMode) {
        final installmentsString = _installmentsController.text;
        final installments = int.tryParse(installmentsString) ?? 24;

        // Check mandate status for SIP
        if (_clientCode != null) {
          final mandateResponse = await _tradeService.tradeMandateStatus(
            clientCode: _clientCode!,
          );

          if (mandateResponse != null && mandateResponse['success'] == true) {
            final mandateData = mandateResponse['data'];

            // If no active mandate, show error and suggest mandate setup
            if (mandateData == null || mandateData['mandate_id'] == null) {
              setState(() => _isLoading = false);
              AppSnackBar.showError(
                context,
                "SIP requires e-mandate setup. Please set up e-mandate first.",
              );
              // TODO: Navigate to mandate setup screen
              return;
            }

            // If mandate is pending approval, show message
            if (mandateData['status'] != 'APPROVED') {
              setState(() => _isLoading = false);
              AppSnackBar.showError(
                context,
                "Your e-mandate is pending approval. Please complete the authorization.",
              );
              // TODO: Navigate to mandate authorization screen
              return;
            }

            // Mandate is approved, create SIP with mandate
            print(
              'DEBUG: Starting polling immediately for SIP with mandate...',
            );
            setState(() => _isLoading = false);
            _startUccSyncPolling(
              uccId: _orderController.selectedAccount.value!.id,
              schemeCode: widget.schemeCode,
              amount: amount,
              isFresh: isFresh,
              folioNumber: folioNumber,
              message: 'Creating SIP...',
              isSip: true,
              installments: installments,
              txnDate: _selectedSipDate,
              startDate: _calculateStartDate(),
              mandateId: mandateData['mandate_id'],
            );
          } else {
            // Fallback to legacy SIP creation (without mandate)
            print(
              'DEBUG: Starting polling immediately for legacy SIP (with client code)...',
            );
            setState(() => _isLoading = false);
            _startUccSyncPolling(
              uccId: _orderController.selectedAccount.value!.id,
              schemeCode: widget.schemeCode,
              amount: amount,
              isFresh: isFresh,
              folioNumber: folioNumber,
              message: 'Creating SIP...',
              isSip: true,
              installments: installments,
              txnDate: _selectedSipDate,
              startDate: _calculateStartDate(),
            );
          }
        } else {
          // No client code, fallback to legacy SIP
          print(
            'DEBUG: Starting polling immediately for legacy SIP (no client code)...',
          );
          setState(() => _isLoading = false);
          _startUccSyncPolling(
            uccId: _orderController.selectedAccount.value!.id,
            schemeCode: widget.schemeCode,
            amount: amount,
            isFresh: isFresh,
            folioNumber: folioNumber,
            message: 'Creating SIP...',
            isSip: true,
            installments: installments,
            txnDate: _selectedSipDate,
            startDate: _calculateStartDate(),
          );
        }
      } else {
        print('DEBUG: Starting polling immediately on button click...');
        setState(() => _isLoading = false);
        _startUccSyncPolling(
          uccId: _orderController.selectedAccount.value!.id,
          schemeCode: widget.schemeCode,
          amount: amount,
          isFresh: isFresh,
          folioNumber: folioNumber,
          message: 'Creating order...',
        );
      }
    } catch (e) {
      _showErrorBottomSheet("An error occurred: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm({bool checkAccount = false}) {
    if (checkAccount && _orderController.selectedAccount.value == null) {
      AppSnackBar.showError(context, "Please select an account first");
      return false;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      AppSnackBar.showError(context, "Please enter an amount");
      return false;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      AppSnackBar.showError(context, "Please enter a valid amount");
      return false;
    }

    if (widget.minAmount != null && amount < widget.minAmount!) {
      AppSnackBar.showError(
        context,
        "Minimum investment is ₹${widget.minAmount!.toStringAsFixed(0)}",
      );
      return false;
    }

    if (_isSipMode) {
      final installmentsString = _installmentsController.text;
      final installments = int.tryParse(installmentsString) ?? 24;

      if (installments < 6) {
        AppSnackBar.showError(context, "Please select at least 6 installments");
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: AppText(
            "Invest",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
        ),
        leading: Semantics(
          label: 'Close',
          button: true,
          child: IconButton(
            color: Colors.transparent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              // Navigate to Invest & Services tab (MF browse) with bottom navigation
              Get.off(() => const StackedNavbar(selectedIdx: 3));
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFundInfo(),
            const SizedBox(height: 24),
            _buildModeToggle(),
            const SizedBox(height: 32),
            _buildAmountInput(),
            if (_isSipMode) ...[const SizedBox(height: 24), _buildSipDetails()],
            const SizedBox(height: 24),
            _buildFolioSelector(),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            "Lumpsum",
            !_isSipMode,
            () => setState(() => _isSipMode = false),
          ),
          _buildToggleItem(
            "SIP",
            _isSipMode,
            () => setState(() => _isSipMode = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        selected: isSelected,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.darkPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: AppText(
                label,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.bold,
                customColor: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSipDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "SIP Date",
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Select SIP date',
          value:
              "Every $_selectedSipDate${_getDaySuffix(_selectedSipDate)} of the month",
          hint: 'Opens day picker',
          child: InkWell(
            onTap: () => _selectSipDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkButtonBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.darkPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      AppText(
                        "Every $_selectedSipDate${_getDaySuffix(_selectedSipDate)} of the month",
                        variant: AppTextVariant.bodyMedium,
                      ),
                    ],
                  ),
                  const Icon(Icons.edit_calendar, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Frequency",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      "Monthly",
                      variant: AppTextVariant.bodyMedium,
                    ),
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
                    "Installments",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Number of installments',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _installmentsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkInputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if ((int.tryParse(_installmentsController.text) ?? 0) < 6)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: AppText(
              "Please select at least 6 installments",
              variant: AppTextVariant.caption,
              customColor: AppColors.error,
            ),
          ),
        const SizedBox(height: 12),
        AppText(
          "First SIP will start from ${_calculateStartDate()}",
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.secondary,
        ),
      ],
    );
  }

  Widget _buildFundInfo() {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // _buildFundLogo(),
            // const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: AppText(
                      widget.fundName,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                    ),
                  ),
                  if (widget.nav != null)
                    AppText(
                      "NAV: ₹${widget.nav!.toStringAsFixed(2)}",
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.secondary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child:
            widget.fundLogo != null && widget.fundLogo!.isNotEmpty
                ? Image.network(widget.fundLogo!, fit: BoxFit.contain)
                : const Icon(
                  Icons.account_balance,
                  color: AppColors.darkPrimary,
                ),
      ),
    );
  }

  void _showAccountPicker() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                header: true,
                child: AppText(
                  "Select Account",
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _orderController.accounts.length,
                itemBuilder: (context, index) {
                  final acc = _orderController.accounts[index];
                  final isSelected =
                      acc.id == _orderController.selectedAccount.value?.id;
                  return Semantics(
                    selected: isSelected,
                    label: acc.clientCode,
                    onTap: () {
                      _orderController.selectedAccount.value = acc;
                      _orderController.checkFolios(widget.isin);
                      Get.back();
                    },
                    excludeSemantics: true,
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.darkPrimary,
                      ),
                      title: AppText(
                        acc.clientCode,
                        variant: AppTextVariant.bodyMedium,
                      ),
                      subtitle: AppText(
                        acc.holdingNature,
                        variant: AppTextVariant.caption,
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: AppColors.darkPrimary,
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Investment Amount",
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 12),
        Semantics(
          label: "Investment Amount",
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: "₹ ",
              prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
              hintText: "e.g. 5000",
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 18,
              ),
              filled: true,
              fillColor: AppColors.darkInputBackground,
            ),
          ),
        ),
        if (widget.minAmount != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: AppText(
              "Min. amount: ₹${widget.minAmount!.toStringAsFixed(0)}",
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ),
      ],
    );
  }

  Widget _buildFolioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (!_orderController.isLoadingFolios.value &&
        //     _orderController.availableFolios.toString() != '[New Folio]')
        //   AppText(
        //     "Investment Option",
        //     variant: AppTextVariant.bodySmall,
        //     colorType: AppTextColorType.secondary,
        //   ),
        if (!_orderController.isLoadingFolios.value &&
            _orderController.availableFolios.toString() != '[New Folio]')
          const SizedBox(height: 12),
        if (!_orderController.isLoadingFolios.value &&
            _orderController.availableFolios.toString() != '[New Folio]')
          Obx(() {
            // if (_orderController.isLoadingFolios.value) {
            //   return const Center(child: CircularProgressIndicator());
            // }

            final folios = _orderController.availableFolios;

            return Semantics(
              label: 'Select folio option',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    folios.map((f) {
                      final isSelected = _selectedFolio == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFolio = f),
                        selectedColor: AppColors.darkPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                        backgroundColor: AppColors.darkCardBG,
                      );
                    }).toList(),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_pollingMessage != null)
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      _pollingMessage!,
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: _pollingMessage != null ? 'Retry' : 'Proceed to Payment',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            onPressed:
                _pollingMessage != null
                    ? () {
                      // Clear message and retry
                      setState(() => _pollingMessage = null);
                      _handleInvest();
                    }
                    : () {
                      // Always navigate to UCC wizard to create new UCC
                      _navigateToHolderManagement();
                    },
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToHolderManagement() async {
    if (!_validateForm()) return;

    // Navigate to UCC Wizard to create UCC first
    // Pass current SIP mode to preserve it when returning
    final result = await Get.to<Map<String, dynamic>?>(
      () => UccWizardScreen(
        fundName: widget.fundName,
        isin: widget.isin,
        schemeCode: widget.schemeCode,
        nav: widget.nav,
        fundLogo: widget.fundLogo,
        minAmount: widget.minAmount,
        isSipMode: _isSipMode,
      ),
      transition: Transition.rightToLeft,
    );

    // If UCC wizard returned successfully, store clientCode and uccId from response
    if (result != null && result['success'] == true) {
      final uccId = result['uccId'] as String?;
      final clientCode = result['clientCode'] as String?;

      AppLogger.info(
        'UCC wizard completed - UCC ID: $uccId, Client Code: $clientCode',
        tag: 'CreateOrder',
      );

      // Store clientCode and uccId from UCC creation/resolve response
      setState(() {
        _uccId = uccId;
        _clientCode = clientCode;
        _uccValidated = true;
      });

      // Refresh UCC accounts to get the newly created one
      await _orderController.fetchAccounts();

      // Select the first (newly created) account if available
      if (_orderController.accounts.isNotEmpty) {
        _orderController.selectedAccount.value =
            _orderController.accounts.first;
        _orderController.checkFolios(widget.isin);
        AppLogger.info(
          'Selected UCC account: ${_orderController.selectedAccount.value?.clientCode}',
          tag: 'CreateOrder',
        );
      }

      // Show order preview before proceeding to payment
      _showOrderPreview();
    }
  }

  void _showOrderPreview() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    final installments = int.tryParse(_installmentsController.text) ?? 24;

    final userController = Get.find<UserController>();
    final user = userController.userData;
    final firstName = user?.firstname ?? '';
    final lastName = user?.lastname ?? '';
    final primaryNameStr = '$firstName $lastName'.trim();
    final account = _orderController.selectedAccount.value;

    Get.to(
      () => OrderPreviewPage(
        fundName: widget.fundName,
        schemeCode: widget.schemeCode,
        isin: widget.isin,
        initialAmount: amount,
        minAmount: widget.minAmount,
        isSipMode: _isSipMode,
        sipDate: _selectedSipDate,
        sipDateSuffix: _getDaySuffix(_selectedSipDate),
        installments: installments,
        selectedFolio: _selectedFolio,
        primaryHolderName:
            primaryNameStr.isNotEmpty ? primaryNameStr : 'Primary Holder',
        primaryPan: user?.pannumber,
        secondaryHolderName: account?.secondaryHolderName,
        holdingNature: account?.holdingNature,
        uccId: _uccId ?? account?.id ?? '',
        clientCode: _clientCode,
        paymentUpiId: _paymentUpiId,
      ),
      transition: Transition.rightToLeft,
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
