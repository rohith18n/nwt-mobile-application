import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class InsuranceTransactionsScreen extends StatelessWidget {
  final Insurance insurance;

  const InsuranceTransactionsScreen({
    super.key,
    required this.insurance,
  });

  String _formatTransactionDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  // Group transactions by date and create list items with date headers
  List<Widget> _buildGroupedTransactionList() {
    print('=== BUILDING TRANSACTION LIST ===');
    print('Policy Name: ${insurance.policyname}');
    print('Policy LinkedAccRef: ${insurance.linkedaccref}');
    print('Total Transactions Available: ${insurance.transactions.length}');
    print('================================');
    
    // First check if there are any transactions for this specific policy
    int filteredTransactionCount = 0;
    
    print('Checking filtered transaction count...');
    print('Transactions not empty: ${insurance.transactions.isNotEmpty}');
    print('Transactions length > 1: ${insurance.transactions.length > 1}');
    
    if (insurance.transactions.isNotEmpty && insurance.transactions.length > 1) {
      final policyLinkedAccRef = insurance.linkedaccref?.toString() ?? '';
      
      print('Policy LinkedAccRef: $policyLinkedAccRef');
      
      // Count transactions that belong to this policy
      for (int i = 1; i < insurance.transactions.length; i++) {
        final transaction = insurance.transactions[i];
        
        if (transaction != null && transaction.length >= 12) {
          final transactionLinkedAccRef = transaction[0]?.toString() ?? '';
          
          print('Count check - Transaction LinkedAccRef: $transactionLinkedAccRef vs Policy LinkedAccRef: $policyLinkedAccRef');
          
          if (transactionLinkedAccRef == policyLinkedAccRef) {
            filteredTransactionCount++;
            print('✅ Match found! Count: $filteredTransactionCount');
          }
        }
      }
    }
    
    print('Final filtered transaction count: $filteredTransactionCount');
    
    // If no transactions found for this policy, show no transactions message
    if (filteredTransactionCount == 0) {
      print('❌ Returning "No transactions found" - filtered count is 0');
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ];
    }

    final List<Widget> widgets = [];
    String? currentDateHeader;

    // Skip header row (index 0) and process transactions
    print('Starting transaction loop - Total iterations: ${insurance.transactions.length - 1}');
    for (int i = 1; i < insurance.transactions.length; i++) {
      print('Processing transaction index: $i');
      final transaction = insurance.transactions[i];
      
      // Check if transaction is valid (should have 12 fields including header)
      if (transaction == null || transaction.length < 12) {
        print('Transaction $i is null or has insufficient length: ${transaction?.length}');
        continue;
      }

      // Filter transactions by policy's linkedaccref
      final transactionLinkedAccRef = transaction[0]?.toString() ?? '';
      final policyLinkedAccRef = insurance.linkedaccref?.toString() ?? '';
      
      print('=== INSURANCE_DATA DEBUG ===');
print('Transaction LinkedAccRef: $transactionLinkedAccRef');
print('Policy LinkedAccRef: $policyLinkedAccRef');
print('Policy Name: ${insurance.policyname}');
print('Total Transactions: ${insurance.transactions.length}');
print('==========================');
      
      if (transactionLinkedAccRef != policyLinkedAccRef) {
        print('❌ SKIPPING transaction - GUIDs do not match');
        continue; // Skip transactions that don't belong to this policy
      } else {
        print('✅ INCLUDING transaction - GUIDs match');
      }
      
      try {
        final dateHeader = DateFormat(
          'd MMMM yyyy',
        ).format(DateTime.fromMillisecondsSinceEpoch(transaction[7]?.toInt() ?? 0));

        // Add date header if it's different from the previous one
        if (currentDateHeader != dateHeader) {
          if (widgets.isNotEmpty) {
            widgets.add(const SizedBox(height: 24)); // Space between date groups
          }
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  dateHeader,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
              ),
            ),
          );
          currentDateHeader = dateHeader;
        }

        // Add transaction card
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _InsuranceTxnCard(
              name: insurance.policyname,
              amount: (transaction[6] as num).toDouble(), // amount field (index 6)
              category: transaction[3].toString(), // account_type (index 3)
              type: transaction[5].toString(), // type field (index 5)
              date: _formatTransactionDate(transaction[7]), // txnDate field (index 7)
              imageUrl: 'assets/app/pivot.money.png', // Default insurance logo
              description: transaction[8].toString(), // narration field (index 8)
              maskedPolicyNumber: transaction[1].toString(), // maskedPolicyNumber (index 1)
              maskedAccNumber: transaction[2].toString(), // maskedAccNumber (index 2)
              txnId: transaction[4].toString(), // txnId (index 4)
              fipId: transaction[9].toString(), // fipId (index 9)
              fnrkAccountId: transaction[10].toString(), // fnrkAccountId (index 10)
            ),
          ),
        );
      } catch (e) {
        print('Error processing transaction $i: $e');
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Insurance Transactions",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(
              size: 20,
              color: AppColors.darkPrimary,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Transaction List (matching investment pattern)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: _buildGroupedTransactionList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsuranceTxnCard extends StatefulWidget {
  final String name;
  final double amount;
  final String category;
  final String type;
  final String date;
  final String? imageUrl;
  final String? description;
  final String maskedPolicyNumber;
  final String maskedAccNumber;
  final String txnId;
  final String fipId;
  final String fnrkAccountId;

  const _InsuranceTxnCard({
    required this.name,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.imageUrl,
    this.description,
    required this.maskedPolicyNumber,
    required this.maskedAccNumber,
    required this.txnId,
    required this.fipId,
    required this.fnrkAccountId,
  });

  @override
  State<_InsuranceTxnCard> createState() => _InsuranceTxnCardState();
}

class _InsuranceTxnCardState extends State<_InsuranceTxnCard> {
  bool _expanded = false;
  final GlobalKey _localAccordionKey = GlobalKey();

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool hasInfoIcon = false,
    VoidCallback? onInfoIconTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onInfoIconTap,
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ],
        ),
        AppText(
          value,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          customColor: valueColor ?? AppColors.darkTextPrimary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
              vertical: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Avatar(
                  path: widget.imageUrl ?? "",
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(12),
                  errorWidget: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkButtonBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AppText(
                              widget.name,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  AppText(
                                    "Txn Amount",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.medium,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  const SizedBox(height: 2),
                                  AppText(
                                    CurrencyFormatter.formatRupeeWithCommas(
                                      widget.amount,
                                    ),
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  final st = _localAccordionKey.currentState;
                                  if (st != null) {
                                    (st as dynamic).toggle();
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.darkPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                        // const SizedBox(height: 6),
                        // if (widget.category.isNotEmpty) ...[
                        //   AppText(
                        //     widget.category,
                        //     variant: AppTextVariant.bodySmall,
                        //     weight: AppTextWeight.medium,
                        //     colorType: AppTextColorType.secondary,
                        //   ),
                        // ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          CustomAccordion(
            key: _localAccordionKey,
            title: "Details",
            backgroundColor: Colors.transparent,
            borderRadius: 0,
            padding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            showHeader: false,
            onChanged: (expanded) {
              setState(() {
                _expanded = expanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  "Account Type",
                  widget.category,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Masked Policy Number",
                  widget.maskedPolicyNumber,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Masked Account Number",
                  widget.maskedAccNumber,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Account Type",
                  widget.category,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Transaction ID",
                  widget.txnId,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Transaction Amount",
                  CurrencyFormatter.formatRupeeWithCommas(widget.amount),
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Transaction Date",
                  widget.date,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  "Narration",
                  widget.description ?? 'No description',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

