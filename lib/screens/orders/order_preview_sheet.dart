import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/services/orders/order_service_v1.dart';
import 'package:nwt_app/services/orders/trade_api_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/screens/orders/netbanking_webview_screen.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class OrderPreviewPage extends StatefulWidget {
  final String fundName;
  final String schemeCode;
  final String isin;
  final double initialAmount;
  final double? minAmount;
  final bool isSipMode;
  final int sipDate;
  final String sipDateSuffix;
  final int installments;
  final String? selectedFolio;

  // Holder info
  final String primaryHolderName;
  final String? primaryPan;
  final String? secondaryHolderName;
  final String? holdingNature;

  // UCC info (from wizard result)
  final String uccId;
  final String? clientCode;
  final String? mandateId;
  final String? paymentUpiId;

  const OrderPreviewPage({
    super.key,
    required this.fundName,
    required this.schemeCode,
    required this.isin,
    required this.initialAmount,
    this.minAmount,
    required this.isSipMode,
    required this.sipDate,
    required this.sipDateSuffix,
    required this.installments,
    this.selectedFolio,
    required this.primaryHolderName,
    this.primaryPan,
    this.secondaryHolderName,
    this.holdingNature,
    required this.uccId,
    this.clientCode,
    this.mandateId,
    this.paymentUpiId,
  });

  @override
  State<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────
class _OrderPreviewPageState extends State<OrderPreviewPage> {
  final MutualFundOrderServiceV1 _orderService = MutualFundOrderServiceV1();
  final TradeApiService _tradeService = TradeApiService();

  late final TextEditingController _amountController;
  late final TextEditingController _upiController;
  final FocusNode _amountFocus = FocusNode();

  // UI state
  String? _amountError;
  bool _isCreatingOrder = false;
  String? _statusMessage;
  String? _orderError;

  // After order created
  OrderData? _orderData;
  bool _isSipCreated = false;
  String? _selectedPaymentMode; // 'UPI' | 'BANK'

  // Payment state
  bool _isInitiatingPayment = false;
  bool _isPolling = false;
  bool _paymentSuccess = false;
  bool _paymentFailed = false;
  Timer? _paymentPollTimer;
  Timer? _successRedirectTimer;
  int _paymentPollAttempts = 0;
  static const int _maxPaymentPollAttempts = 20; // 20 * 15s = 5 min

  // Order creation polling
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxAttempts = 30;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(0),
    );
    _upiController = TextEditingController(
      text: widget.paymentUpiId ?? '',
    );

    // Listen for UPI ID changes to update Pay Now button state
    _upiController.addListener(() {
      if (mounted && _selectedPaymentMode == 'UPI') {
        setState(() {}); // Rebuild to update button disabled state
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _paymentPollTimer?.cancel();
    _successRedirectTimer?.cancel();
    _amountController.dispose();
    _upiController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────
  bool _validateAmount() {
    final text = _amountController.text.trim();
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      setState(() => _amountError = 'Enter a valid amount');
      return false;
    }
    if (widget.minAmount != null && value < widget.minAmount!) {
      setState(
        () => _amountError = 'Min. amount is ₹${widget.minAmount!.toStringAsFixed(0)}',
      );
      return false;
    }
    setState(() => _amountError = null);
    return true;
  }

  // ── Order creation / polling ────────────────────────────
  Future<void> _createOrder() async {
    if (!_validateAmount()) return;
    final amount = double.parse(_amountController.text.trim());
    final isFresh =
        widget.selectedFolio == null || widget.selectedFolio == 'New Folio';
    final folio = isFresh ? null : widget.selectedFolio;

    setState(() {
      _isCreatingOrder = true;
      _statusMessage = widget.isSipMode ? 'Creating SIP…' : 'Creating order…';
      _orderError = null;
      _orderData = null;
      _selectedPaymentMode = null;
    });

    _pollAttempts = 0;
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      _pollAttempts++;
      if (_pollAttempts > _maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isCreatingOrder = false;
            _statusMessage = null;
            _orderError = 'Order creation timed out. Please try again.';
          });
        }
        return;
      }

      try {
        if (widget.isSipMode) {
          await _trySipCreation(
            timer: timer,
            amount: amount,
            isFresh: isFresh,
            folio: folio,
          );
        } else {
          await _tryLumpsumCreation(
            timer: timer,
            amount: amount,
            isFresh: isFresh,
            folio: folio,
          );
        }
      } catch (e) {
        AppLogger.error('Order poll error: $e', tag: 'OrderPreview');
      }
    });
  }

  Future<void> _tryLumpsumCreation({
    required Timer timer,
    required double amount,
    required bool isFresh,
    String? folio,
  }) async {
    final response = await _orderService.createOrder(
      uccId: widget.uccId,
      schemeCode: widget.schemeCode,
      amount: amount,
      isFresh: isFresh,
      folioNumber: folio,
    );

    if (response.success && response.data != null) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
          _statusMessage = null;
          _orderData = response.data;
          _isSipCreated = false;
          if (response.data!.upiId != null && _upiController.text.trim().isEmpty) {
            _upiController.text = response.data!.upiId!;
          }
        });
      }
    } else {
      final details = response.details;
      if (details != null && details['ucc_sync_pending'] == true) {
        if (mounted) setState(() => _statusMessage = 'Syncing with BSE, retrying…');
      } else {
        timer.cancel();
        if (mounted) setState(() {
          _isCreatingOrder = false;
          _statusMessage = null;
          _orderError = response.message.isNotEmpty
              ? response.message
              : 'Order creation failed. Please try again.';
        });
      }
    }
  }

  Future<void> _trySipCreation({
    required Timer timer,
    required double amount,
    required bool isFresh,
    String? folio,
  }) async {
    // Try with mandate first if available
    if (widget.mandateId != null) {
      final start = _calculateStartDate();
      final sipResponse = await _tradeService.tradeSipCreate(
        mandateId: widget.mandateId!,
        schemeCode: widget.schemeCode,
        amount: amount,
        txnDate: widget.sipDate,
        startDate: start,
        installments: widget.installments,
        isFresh: isFresh,
        folioNumber: folio,
      );

      if (sipResponse != null && sipResponse['success'] == true) {
        final firstOrderId = sipResponse['data']?['first_order_id'];
        timer.cancel();
        if (mounted) {
          if (firstOrderId != null) {
            // Has payment step
            final orderData = OrderData.fromJson(sipResponse['data']!);
            setState(() {
              _isCreatingOrder = false;
              _statusMessage = null;
              _orderData = orderData;
              _isSipCreated = false;
              if (orderData.upiId != null && _upiController.text.trim().isEmpty) {
                _upiController.text = orderData.upiId!;
              }
            });
          } else {
            // SIP registered, no payment needed
            setState(() {
              _isCreatingOrder = false;
              _statusMessage = null;
              _isSipCreated = true;
            });
          }
        }
        return;
      }

      final details = sipResponse?['details'] as Map<String, dynamic>?;
      if (details != null && details['ucc_sync_pending'] == true) {
        if (mounted) setState(() => _statusMessage = 'Syncing with BSE, retrying…');
      } else {
        timer.cancel();
        if (mounted) setState(() {
          _isCreatingOrder = false;
          _statusMessage = null;
          _orderError = sipResponse?['message']?.toString().isNotEmpty == true
              ? sipResponse!['message'].toString()
              : 'SIP creation failed. Please try again.';
        });
      }
      return;
    }

    // No mandate — legacy SIP
    final response = await _orderService.createSip(
      uccId: widget.uccId,
      schemeCode: widget.schemeCode,
      amount: amount,
      txnDate: widget.sipDate,
      startDate: _calculateStartDate(),
      installments: widget.installments,
      isFresh: isFresh,
      folioNumber: folio,
    );

    if (response.success && response.data != null) {
      timer.cancel();
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
          _statusMessage = null;
          _orderData = response.data;
          _isSipCreated = false;
          if (response.data!.upiId != null && _upiController.text.trim().isEmpty) {
            _upiController.text = response.data!.upiId!;
          }
        });
      }
    } else {
      final details = response.details;
      if (details != null && details['ucc_sync_pending'] == true) {
        if (mounted) setState(() => _statusMessage = 'Syncing with BSE, retrying…');
      } else {
        timer.cancel();
        if (mounted) setState(() {
          _isCreatingOrder = false;
          _statusMessage = null;
          _orderError = response.message.isNotEmpty
              ? response.message
              : 'SIP creation failed. Please try again.';
        });
      }
    }
  }

  String _calculateStartDate() {
    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, widget.sipDate);
    if (startDate.isBefore(now)) {
      startDate = DateTime(now.year, now.month + 1, widget.sipDate);
    }
    return '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
  }

  void _showError(String msg) {
    if (!mounted) return;
    Get.snackbar('Error', msg,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _handlePaymentInitiation() async {
    if (_orderData == null || _selectedPaymentMode == null) return;
    final apiMode = _selectedPaymentMode == 'UPI' ? 'upi' : 'netbanking';
    final upiId = _selectedPaymentMode == 'UPI' ? _upiController.text.trim() : null;

    if (_selectedPaymentMode == 'UPI' && (upiId == null || upiId.isEmpty)) {
      _showError('Please enter your UPI ID');
      return;
    }

    setState(() => _isInitiatingPayment = true);

    try {
      final response = widget.isSipMode
          ? await _orderService.initiateSipPayment(
              orderId: _orderData!.orderId,
              paymentMode: apiMode,
              upiId: upiId,
            )
          : await _orderService.initiatePayment(
              orderId: _orderData!.orderId,
              paymentMode: apiMode,
              upiId: upiId,
            );

      if (response.success) {
        setState(() => _isInitiatingPayment = false);
        final data = response.data;
        if (data?.paymentUrl != null) {
          // Netbanking: open in-app WebView
          await Get.to(
            () => NetbankingWebViewScreen(
              paymentUrl: data!.paymentUrl!,
              paymentMethod: data.paymentMethod ?? 'POST',
              paymentParams: data.paymentParams,
              orderId: _orderData!.orderId,
            ),
            transition: Transition.rightToLeft,
          );
          // After WebView closed, start polling for status
          if (mounted) {
            setState(() => _isPolling = true);
            _startPaymentPolling();
          }
        } else {
          // UPI: just start polling
          setState(() => _isPolling = true);
          _startPaymentPolling();
        }
      } else {
        setState(() => _isInitiatingPayment = false);
        _showError(response.message.isNotEmpty ? response.message : 'Payment initiation failed');
      }
    } catch (e) {
      setState(() => _isInitiatingPayment = false);
      _showError('Payment initiation failed: $e');
    }
  }

  void _startPaymentPolling() {
    _paymentPollAttempts = 0;
    _paymentPollTimer?.cancel();
    // immediate first check
    _pollPaymentStatus();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _paymentPollAttempts++;
      if (_paymentPollAttempts >= _maxPaymentPollAttempts) {
        _paymentPollTimer?.cancel();
        if (mounted) {
          setState(() => _isPolling = false);
          _showError('Payment verification timed out. Check your orders for status.');
        }
        return;
      }
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    try {
      final response = widget.isSipMode
          ? await _orderService.getSipPaymentStatus(_orderData!.orderId)
          : await _orderService.getPaymentStatus(_orderData!.orderId);

      if (!response.success || response.data == null) return;
      final status = response.data!.orderStatus.toUpperCase();
      final pStatus = response.data!.paymentStatus.toUpperCase();

      if (status == 'SUCCESS' || pStatus == 'SUCCESS' ||
          status == 'PAID' || status == 'SETTLED' ||
          pStatus.contains('COMPLETE') || pStatus.contains('AGENCY_PAYMENT')) {
        _paymentPollTimer?.cancel();
        if (mounted) {
          setState(() {
            _isPolling = false;
            _paymentSuccess = true;
          });
          _successRedirectTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) Get.offAll(() => const StackedNavbar(selectedIdx: 1), transition: Transition.fadeIn);
          });
        }
      } else if (status == 'FAILED' || pStatus == 'FAILED') {
        _paymentPollTimer?.cancel();
        if (mounted) setState(() {
          _isPolling = false;
          _paymentFailed = true;
        });
      }
    } catch (e) {
      AppLogger.error('Payment poll error: $e', tag: 'OrderPreview');
    }
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: (_isPolling || _paymentSuccess)
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Get.back(),
              ),
        automaticallyImplyLeading: false,
        title: AppText(
          _paymentSuccess
              ? 'Payment Successful'
              : _isPolling
                  ? 'Processing Payment'
                  : _paymentFailed
                      ? 'Payment Failed'
                      : _orderData != null
                          ? 'Choose Payment'
                          : 'Order Summary',
          variant: AppTextVariant.bodyLarge,
          weight: AppTextWeight.semiBold,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _paymentSuccess
            ? _buildPaymentSuccessView()
            : _isPolling
                ? _buildPollingView()
                : _paymentFailed
                    ? _buildPaymentFailedView()
                    : _orderData != null
                        ? _buildPaymentView()
                        : _isSipCreated
                            ? _buildSipSuccessView()
                            : _buildSummaryView(),
      ),
    );
  }

  // ── Summary view ─────────────────────────────────────────
  Widget _buildSummaryView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFundCard(),
                const SizedBox(height: 20),
                _buildTypeChip(),
                const SizedBox(height: 24),
                _buildAmountField(),
                if (widget.isSipMode) ...[
                  const SizedBox(height: 20),
                  _buildSipInfoCard(),
                ],
                const SizedBox(height: 24),
                _buildHolderSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _buildConfirmBar(),
      ],
    );
  }

  Widget _buildFundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance, color: AppColors.darkPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AppText(
              widget.fundName,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isSipMode ? Icons.repeat_rounded : Icons.flash_on_rounded,
            color: AppColors.darkPrimary,
            size: 15,
          ),
          const SizedBox(width: 6),
          AppText(
            widget.isSipMode ? 'SIP – Monthly' : 'Lumpsum',
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.semiBold,
            customColor: AppColors.darkPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('Investment Amount',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary),
        const SizedBox(height: 10),
        TextFormField(
          controller: _amountController,
          focusNode: _amountFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_amountError != null) setState(() => _amountError = null);
          },
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            prefixText: '₹  ',
            prefixStyle: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
            suffixText: widget.isSipMode ? '/ mo' : null,
            suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            hintText: '0',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 26, fontWeight: FontWeight.w700),
            filled: true,
            fillColor: AppColors.darkCardBG,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            errorText: _amountError,
            errorStyle: const TextStyle(color: AppColors.error),
          ),
        ),
        if (widget.minAmount != null) ...[
          const SizedBox(height: 6),
          AppText(
            'Min. amount: ₹${widget.minAmount!.toStringAsFixed(0)}',
            variant: AppTextVariant.caption,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildSipInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'SIP Date',
            'Every ${widget.sipDate}${widget.sipDateSuffix} of the month',
          ),
          _buildDivider(),
          _buildDetailRow(Icons.repeat, 'Installments', '${widget.installments} months'),
        ],
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      color: AppColors.darkBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_orderError != null) ...[  
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      _orderError!,
                      variant: AppTextVariant.bodySmall,
                      customColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      _statusMessage!,
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Confirm & Pay',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isLoading: _isCreatingOrder,
              onPressed: _isCreatingOrder ? null : _createOrder,
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment view (after order created) ──────────────────
  Widget _buildPaymentView() {
    final data = _orderData!;
    final amount = data.amount;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount to pay
                Center(
                  child: Column(
                    children: [
                      AppText('Amount to Pay',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary),
                      const SizedBox(height: 6),
                      Text(
                        '₹$amount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Payment method heading
                AppText('Select Payment Method',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary),
                const SizedBox(height: 14),

                // UPI option
                _buildPaymentOption(
                  mode: 'UPI',
                  icon: Icons.phone_android_rounded,
                  label: 'UPI',
                  subtitle: 'Pay via any UPI app',
                  child: _selectedPaymentMode == 'UPI'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            _buildDivider(),
                            const SizedBox(height: 14),
                            AppText('UPI ID',
                                variant: AppTextVariant.caption,
                                colorType: AppTextColorType.secondary),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _upiController,
                              style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                              decoration: InputDecoration(
                                hintText: 'yourname@upi',
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                filled: true,
                                fillColor: AppColors.darkBackground,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.darkPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use any valid UPI ID from GPay, PhonePe, Paytm, or your bank',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Bank transfer option
                if (data.bankDetails.isNotEmpty)
                  _buildPaymentOption(
                    mode: 'BANK',
                    icon: Icons.account_balance_rounded,
                    label: 'Net Banking',
                    subtitle: 'Transfer from your bank account',
                    child: _selectedPaymentMode == 'BANK'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              _buildDivider(),
                              const SizedBox(height: 14),
                              ...data.bankDetails.map(
                                (b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHolderDetailRow('Bank', b.bankName),
                                      const SizedBox(height: 6),
                                      _buildHolderDetailRow('Account No.', b.accountNumber),
                                      const SizedBox(height: 6),
                                      _buildHolderDetailRow('IFSC', b.ifscCode),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Pay button - disabled until payment mode selected and input filled
        Builder(builder: (context) {
          final canPay = _selectedPaymentMode != null &&
              !_isInitiatingPayment &&
              (_selectedPaymentMode != 'UPI' ||
                  _upiController.text.trim().isNotEmpty);

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: AppColors.darkBackground,
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Pay Now',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                isLoading: _isInitiatingPayment,
                isDisabled: !canPay,
                onPressed: canPay ? _handlePaymentInitiation : () {},
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String mode,
    required IconData icon,
    required String label,
    required String subtitle,
    Widget? child,
  }) {
    final isSelected = _selectedPaymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMode = isSelected ? null : mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.darkPrimary
                : Colors.grey.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.darkPrimary.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: isSelected ? AppColors.darkPrimary : Colors.grey,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(label,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold),
                      AppText(subtitle,
                          variant: AppTextVariant.caption,
                          colorType: AppTextColorType.secondary),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.darkPrimary : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  // ── Inline payment processing views ───────────────────────
  Widget _buildPollingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.darkPrimary),
            const SizedBox(height: 32),
            AppText('Payment request sent!',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold),
            const SizedBox(height: 12),
            AppText(
              _selectedPaymentMode == 'UPI'
                  ? 'Please complete the payment in your UPI app. We will update you once confirmed.'
                  : 'Please complete the bank transfer. We will verify once received.',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 56),
            ),
            const SizedBox(height: 28),
            AppText('Investment Successful!',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            AppText('Your order has been placed with the exchange.',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildSuccessRow('Amount Invested', '₹${_orderData?.amount ?? ''}', valueColor: Colors.green),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  _buildSuccessRow('BSE Order ID', _orderData?.bseOrderId ?? ''),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  _buildSuccessRow('Type', widget.isSipMode ? 'SIP' : 'Lumpsum'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                AppText('Redirecting to portfolio…',
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _successRedirectTimer?.cancel();
                Get.offAll(() => const StackedNavbar(selectedIdx: 1), transition: Transition.fadeIn);
              },
              child: AppText('Go to Portfolio now',
                  variant: AppTextVariant.bodySmall,
                  customColor: AppColors.darkPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, variant: AppTextVariant.bodySmall, colorType: AppTextColorType.secondary),
        AppText(value, variant: AppTextVariant.bodySmall, weight: AppTextWeight.semiBold, customColor: valueColor),
      ],
    );
  }

  Widget _buildPaymentFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 56),
            ),
            const SizedBox(height: 24),
            AppText('Payment Failed',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold),
            const SizedBox(height: 12),
            AppText("We couldn't confirm your payment. Please try again.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            AppButton(
              text: 'Try Again',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isFullWidth: true,
              onPressed: () => setState(() {
                _paymentFailed = false;
                _paymentSuccess = false;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── SIP no-payment success view ──────────────────────────
  Widget _buildSipSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 20),
            AppText('SIP Registered!',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold),
            const SizedBox(height: 12),
            AppText(
              'Your SIP has been successfully registered. Installments will be auto-debited on the selected date.',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Done',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  String _holdingPatternLabel(String? nature) {
    switch ((nature ?? '').toUpperCase()) {
      case 'JO': return 'Joint Holder';
      case 'AS': return 'Anyone or Survivor';
      default:   return 'Single Holder';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0].isNotEmpty ? parts[0][0] : ''}${parts[1].isNotEmpty ? parts[1][0] : ''}'.toUpperCase();
  }

  Widget _buildAvatarCircle(String name, Color bg) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(_initials(name),
          style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
    );
  }

  Widget _buildHolderSection() {
    final isJoint = (widget.secondaryHolderName ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PRIMARY HOLDER DETAILS'),
        const SizedBox(height: 10),
        _buildHolderCard(
          name: widget.primaryHolderName,
          subtitle: 'Primary Account Holder',
          avatarColor: const Color(0xFF8B6914),
          detailLabel: 'PAN',
          detailValue: widget.primaryPan,
        ),
        if (isJoint) ...[
          const SizedBox(height: 16),
          _sectionLabel('SECONDARY HOLDER DETAILS'),
          const SizedBox(height: 10),
          _buildHolderCard(
            name: widget.secondaryHolderName!,
            subtitle: 'Joint Holder',
            avatarColor: const Color(0xFF1A5C8A),
            detailLabel: 'Holding Pattern',
            detailValue: _holdingPatternLabel(widget.holdingNature),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontFamily: 'Poppins'));
  }

  Widget _buildHolderCard({
    required String name,
    required String subtitle,
    required Color avatarColor,
    String? detailLabel,
    String? detailValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.darkCardBG, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _buildAvatarCircle(name, avatarColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12, fontFamily: 'Poppins')),
              ]),
            ),
            _kycBadge(),
          ]),
          if (detailLabel != null && detailValue != null) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
            const SizedBox(height: 12),
            _buildHolderDetailRow(detailLabel, detailValue),
          ],
        ],
      ),
    );
  }

  Widget _kycBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check, color: Colors.green, size: 12),
        SizedBox(width: 3),
        Text('KYC',
            style: TextStyle(
                color: Colors.green, fontSize: 11,
                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
      ]),
    );
  }

  Widget _buildHolderDetailRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'Poppins')),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
    ]);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 12),
        AppText(label, variant: AppTextVariant.bodySmall, colorType: AppTextColorType.secondary),
        const Spacer(),
        AppText(value, variant: AppTextVariant.bodySmall, weight: AppTextWeight.semiBold),
      ]),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.withOpacity(0.12));
}
