import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/advisory/equity_basket_preview.dart';
import 'package:nwt_app/screens/advisory/types/equity_strategy_response.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectStrategyScreen extends StatefulWidget {
  const SelectStrategyScreen({super.key});

  @override
  State<SelectStrategyScreen> createState() => _SelectStrategyScreenState();
}

class _SelectStrategyScreenState extends State<SelectStrategyScreen> {
  String? _selectedStrategy;
  bool _velocityExpanded = false;
  bool _surgeExpanded = false;
  
  EquityBasketResponse? _equityBasketResponse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStrategies();
  }

  Future<void> _fetchStrategies() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final url = Uri.parse(ApiURLs.EQUITY_BASKET_STRATEGY);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _equityBasketResponse = EquityBasketResponse.fromJson(responseData);
            _isLoading = false;
            
            // Debug: Print parsed data
            print('[SelectStrategy] API Response parsed successfully');
            print('[SelectStrategy] Midcap stocks: ${_equityBasketResponse?.data?.strategies.midcapMomentum.stocks.length}');
            print('[SelectStrategy] Smallcap stocks: ${_equityBasketResponse?.data?.strategies.smallcapMomentum.stocks.length}');
          });
        }
      } else {
        throw Exception('Failed to load strategies: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              "Strategy Type",
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
                      
                      Text(
                        'Select Your Strategy',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Choose the momentum strategy that fits your investment goals',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Loading State
                      if (_isLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      
                      // Error State
                      if (_errorMessage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load strategies',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchStrategies,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Success State - Dynamic Strategy Cards
                      if (_equityBasketResponse != null && _equityBasketResponse!.data != null)
                        ...[
                          // Midcap Strategy Card
                          _buildDynamicStrategyCard(
                            isDarkMode: isDarkMode,
                            strategy: _equityBasketResponse!.data!.strategies.midcapMomentum,
                            isExpanded: _velocityExpanded,
                            onExpandToggle: () {
                              setState(() {
                                _velocityExpanded = !_velocityExpanded;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Smallcap Strategy Card
                          _buildDynamicStrategyCard(
                            isDarkMode: isDarkMode,
                            strategy: _equityBasketResponse!.data!.strategies.smallcapMomentum,
                            isExpanded: _surgeExpanded,
                            onExpandToggle: () {
                              setState(() {
                                _surgeExpanded = !_surgeExpanded;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Continue Button
            Container(
              padding: EdgeInsets.symmetric(
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedStrategy != null && _equityBasketResponse != null)
                      ? () {
                          // Find selected strategy
                          CapMomentum? selectedStrategy;
                          if (_selectedStrategy == 'midcap_momentum') {
                            selectedStrategy = _equityBasketResponse!.data!.strategies.midcapMomentum;
                          } else if (_selectedStrategy == 'smallcap_momentum') {
                            selectedStrategy = _equityBasketResponse!.data!.strategies.smallcapMomentum;
                          }
                          
                          if (selectedStrategy != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BasketPreviewScreen(
                                  strategy: selectedStrategy!,
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStrategy != null
                        ? (isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground)
                        : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
                    foregroundColor: _selectedStrategy != null
                        ? (isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText)
                        : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                    disabledForegroundColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard({
    required bool isDarkMode,
    required String strategyId,
    required String title,
    required String subtitle,
    required String yearlyReturn,
    required String benchmark,
    required String riskLabel,
    required String returnsLabel,
    required Color riskColor,
    required Color returnsColor,
    required bool isExpanded,
    required VoidCallback onExpandToggle,
    required String description,
  }) {
    final isSelected = _selectedStrategy == strategyId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStrategy = isSelected ? null : strategyId;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and selection indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            
              // Returns Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1Y RETURN*',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            yearlyReturn,
                            style: TextStyle(
                              color: returnsColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BENCHMARK',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            benchmark,
                            style: TextStyle(
                              color: returnsColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Risk and Returns Labels with Expand Icon
              GestureDetector(
                onTap: onExpandToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        returnsLabel,
                        style: TextStyle(
                          color: returnsColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded Description
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicStrategyCard({
    required bool isDarkMode,
    required CapMomentum strategy,
    required bool isExpanded,
    required VoidCallback onExpandToggle,
  }) {
    final isSelected = _selectedStrategy == strategy.id;
    final riskColor = const Color(0xFFFF6B35);
    final returnsColor = const Color(0xFF4CAF50);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStrategy = isSelected ? null : strategy.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and selection indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strategy.name,
                          style: TextStyle(
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strategy.subtitle,
                          style: TextStyle(
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            
              // Returns Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1Y RETURN*',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${strategy.yearlyReturn}%',
                            style: TextStyle(
                              color: returnsColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BENCHMARK',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${strategy.benchmark}%',
                            style: TextStyle(
                              color: returnsColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Risk and Returns Labels with Expand Icon
              GestureDetector(
                onTap: onExpandToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        strategy.riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        strategy.returnsLabel,
                        style: TextStyle(
                          color: returnsColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded Description
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    strategy.description,
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
