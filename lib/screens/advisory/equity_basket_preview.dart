import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/advisory/complete_compliance.dart';
import 'package:nwt_app/screens/advisory/types/equity_strategy_response.dart';

class BasketPreviewScreen extends StatefulWidget {
  final CapMomentum strategy;

  const BasketPreviewScreen({
    super.key,
    required this.strategy,
  });

  @override
  State<BasketPreviewScreen> createState() => _BasketPreviewScreenState();
}

class _BasketPreviewScreenState extends State<BasketPreviewScreen> {
  double _investmentAmount = 100000;
  bool _showAllStocks = false;
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  List<Stock> get _stocks => widget.strategy.stocks;

  List<int> _quickAmounts = [25000, 50000, 100000, 500000];

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService.setCallback(_onPaymentVerify, _onPaymentError);
  }

  void _onPaymentVerify(String orderId) {
    AppLogger.info('Payment verified for order: $orderId', tag: 'EquityBasket');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Full basket unlocked.'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to success screen or unlock basket
      Navigator.pop(context);
    }
  }

  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    AppLogger.error('Payment failed: ${errorResponse.getMessage()}', tag: 'EquityBasket');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${errorResponse.getMessage()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final displayedStocks = _showAllStocks ? _stocks : _stocks.take(2).toList();
    final totalStocks = _stocks.length;
    
    // Debug: Print stock count
    print('[BasketPreview] Total stocks: $totalStocks');
    print('[BasketPreview] Displayed stocks: ${displayedStocks.length}');
    if (_stocks.isNotEmpty) {
      print('[BasketPreview] First stock: ${_stocks.first.name}');
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              widget.strategy.name,
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // Personalized Allocation Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF2196F3),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personalized Allocation',
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This basket can be customized based on your investment amount. Enter your amount below to see how we optimize your portfolio.',
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Enter Investment Amount
                      Text(
                        'Enter Investment Amount',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Amount Display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _investmentAmount.toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              ),
                              style: TextStyle(
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Quick Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickAmounts.map((amount) {
                          final isSelected = _investmentAmount == amount.toDouble();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _investmentAmount = amount.toDouble();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground)
                                    : (isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDarkMode ? AppColors.darkButtonPrimaryBorder : AppColors.lightButtonPrimaryBorder)
                                      : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '₹${amount ~/ 1000}K',
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText)
                                      : (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      
                      // Portfolio Composition
                      Text(
                        'Portfolio Composition ($totalStocks Stocks)',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stock List
                      ...displayedStocks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stock = entry.value;
                        return _buildStockCard(
                          isDarkMode: isDarkMode,
                          stock: stock,
                          index: index,
                          isBlurred: index >= 2, // Blur stocks after first 2
                        );
                      }),
                      
                      // Show More/Less Button
                      if (_stocks.length > 2) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllStocks = !_showAllStocks;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showAllStocks ? 'Show Less' : 'View All ${_stocks.length} Stocks',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _showAllStocks ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              isDarkMode: isDarkMode,
                              label: 'Total Stocks',
                              value: '$totalStocks',
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              isDarkMode: isDarkMode,
                              label: 'Investment Amount',
                              value: CurrencyFormatter.formatRupee(_investmentAmount),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              isDarkMode: isDarkMode,
                              label: 'Allocation Method',
                              value: 'Optimized',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // Unlock Full Basket Button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CompleteComplianceScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground,
                        foregroundColor: isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Unlock Full Basket',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe to view stock names & quantities',
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard({
    required bool isDarkMode,
    required Stock stock,
    required int index,
    bool isBlurred = false,
  }) {
    // Calculate allocation (equal allocation across all stocks)
    final allocation = (100 / _stocks.length).round();
    final amount = (_investmentAmount * allocation) / 100;
    final qty = (amount / stock.currentMarketValue).round();
    final symbol = stock.name.replaceAll(' Ltd.', '').replaceAll(' Ltd', '').toUpperCase();
    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Color Indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStockColor(symbol),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          
          // Stock Symbol and NAV
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'NAV: ${CurrencyFormatter.formatRupee(stock.nav)}',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity
          Expanded(
            child: Text(
              '$qty QTY',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Allocation
          Expanded(
            child: Text(
              '$allocation%',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Amount
          Text(
            CurrencyFormatter.formatRupee(amount),
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (isBlurred) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            cardContent,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return cardContent;
  }

  Widget _buildSummaryRow({
    required bool isDarkMode,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStockColor(String symbol) {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF2196F3),
      const Color(0xFF00BCD4),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
    ];
    return colors[symbol.hashCode % colors.length];
  }
}
