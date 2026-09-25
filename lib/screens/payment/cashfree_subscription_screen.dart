import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfsubscriptioncheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsubssession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/cashfree_subscription_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class CashfreeSubscriptionScreen extends StatefulWidget {
  final String planId;
  final double amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const CashfreeSubscriptionScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<CashfreeSubscriptionScreen> createState() => _CashfreeSubscriptionScreenState();
}

class _CashfreeSubscriptionScreenState extends State<CashfreeSubscriptionScreen> {
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService.setCallback(
      _onSubscriptionVerify,
      _onSubscriptionFailure,
    );
  }

  void _onSubscriptionVerify(String subscriptionId) async {
    AppLogger.info('Subscription verified: $subscriptionId', tag: 'CashfreeSubscription');
    
    setState(() {
      _isProcessing = true;
    });

    // Verify subscription on backend
    final isVerified = await CashfreeSubscriptionService.verifySubscription(
      subscriptionId: subscriptionId,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (isVerified) {
        AppLogger.info('Subscription payment successful', tag: 'CashfreeSubscription');
        widget.onSuccess?.call();
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = 'Payment verification failed. Please contact support.';
        });
        widget.onFailure?.call();
      }
    }
  }

  void _onSubscriptionFailure(CFErrorResponse errorResponse, String orderId) {
    AppLogger.error('Subscription payment failed: ${errorResponse.getMessage()}', tag: 'CashfreeSubscription');
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _errorMessage = errorResponse.getMessage() ?? 'Payment failed. Please try again.';
      });
      
      widget.onFailure?.call();
    }
  }

  Future<void> _initiateSubscriptionCheckout() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create subscription on backend
      final subscriptionData = await CashfreeSubscriptionService.createSubscription(
        planId: widget.planId,
        amount: widget.amount,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );

      final subscriptionId = subscriptionData['subscription_id'] as String;
      final subscriptionSessionId = subscriptionData['subscription_session_id'] as String;

      AppLogger.info('Subscription created: $subscriptionId', tag: 'CashfreeSubscription');

      // Step 2: Create subscription session
      final subscriptionSession = CFSubscriptionSessionBuilder()
          .setEnvironment(CFEnvironment.PRODUCTION) // Change to SANDBOX for testing
          .setSubscriptionId(subscriptionId)
          .setSubscriptionSessionId(subscriptionSessionId)
          .build();

      // Step 3: Create theme (optional)
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor(
            isDarkMode ? AppColors.darkBackground.value.toRadixString(16).substring(2) : AppColors.lightBackground.value.toRadixString(16).substring(2),
          )
          .setNavigationBarTextColor(
            isDarkMode ? AppColors.darkTextPrimary.value.toRadixString(16).substring(2) : AppColors.lightTextPrimary.value.toRadixString(16).substring(2),
          )
          .build();

      // Step 4: Create subscription payment object
      final cfSubscriptionCheckout = CFSubscriptionPaymentBuilder()
          .setSession(subscriptionSession)
          .setTheme(theme)
          .build();

      // Step 5: Initiate payment
      _cfPaymentGatewayService.doPayment(cfSubscriptionCheckout);

      setState(() {
        _isProcessing = false;
      });
    } on CFException catch (e) {
      AppLogger.error('CFException: ${e.message}', tag: 'CashfreeSubscription');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      AppLogger.error('Error initiating subscription: $e', tag: 'CashfreeSubscription');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to initiate payment. Please try again.';
      });
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
        title: AppText(
          'Subscribe to Plan',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Plan Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Details',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      isDarkMode: isDarkMode,
                      label: 'Plan ID',
                      value: widget.planId,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      isDarkMode: isDarkMode,
                      label: 'Amount',
                      value: '₹${widget.amount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      isDarkMode: isDarkMode,
                      label: 'Customer',
                      value: widget.customerName,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // Subscribe Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _initiateSubscriptionCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode 
                        ? AppColors.darkButtonPrimaryBackground 
                        : AppColors.lightButtonPrimaryBackground,
                    foregroundColor: isDarkMode 
                        ? AppColors.darkButtonPrimaryText 
                        : AppColors.lightButtonPrimaryText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: isDarkMode 
                        ? AppColors.darkButtonBorder 
                        : AppColors.lightButtonBorder,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
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
}
