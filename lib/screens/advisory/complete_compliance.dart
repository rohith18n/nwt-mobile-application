import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/advisory/esign_document_screen.dart';
import 'package:nwt_app/screens/advisory/document_preview_screen.dart';
import 'package:nwt_app/screens/financial_profiling/financial_profiling.dart';
import 'package:nwt_app/screens/payment/cashfree_subscription_screen.dart';
import 'package:nwt_app/controllers/user_controller.dart';

class CompleteComplianceScreen extends StatefulWidget {
  const CompleteComplianceScreen({super.key});

  @override
  State<CompleteComplianceScreen> createState() => _CompleteComplianceScreenState();
}

class _CompleteComplianceScreenState extends State<CompleteComplianceScreen> {
  bool _riskProfilingSigned = false;
  bool _riaAgreementSigned = false;

  double get _progress {
    int completed = 0;
    if (_riskProfilingSigned) completed++;
    if (_riaAgreementSigned) completed++;
    return completed / 2;
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
              "Complete Compliance",
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
                      
                      // Header with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Compliance',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mandatory regulatory requirements',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Bar
                      if (_progress > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Why E-Sign Info Card
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Why E-Sign?',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SEBI requires registered investment advisors to obtain your consent before providing advisory services. This is a one-time process.',
                              style: TextStyle(
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Documents to Sign Header
                      Text(
                        'Documents to Sign',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Risk Profiling Document Card
                      _buildDocumentCard(
                        isDarkMode: isDarkMode,
                        title: 'Risk Profiling',
                        subtitle: 'Complete your risk profiling questionnaire',
                        isSigned: _riskProfilingSigned,
                        onProceed: () async {
                          // Navigate to Financial Profiling questionnaire
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FinancialProfiling(
                                isUserAnswered: false, // New questionnaire
                              ),
                            ),
                          );
                          
                          // If questionnaire completed successfully, mark as signed
                          if (result == true && mounted) {
                            setState(() {
                              _riskProfilingSigned = true;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Risk profiling completed successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // RIA Agreement Document Card
                      _buildDocumentCard(
                        isDarkMode: isDarkMode,
                        title: 'RIA Agreement',
                        subtitle: 'View, upload & E-Sign agreement',
                        isSigned: _riaAgreementSigned,
                        onProceed: () async {
                          // Step 1: Show RIA Agreement preview
                          final acknowledged = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DocumentPreviewScreen(
                                documentTitle: 'RIA Agreement',
                                onAcknowledged: () {
                                  // User acknowledged the agreement
                                },
                              ),
                            ),
                          );
                          
                          // Step 2: If acknowledged, proceed to E-Sign screen
                          if (acknowledged != null && mounted) {
                            // Get user data from UserController
                            final userController = Get.find<UserController>();
                            final user = userController.userData;
                            
                            // Build full name from firstname and lastname
                            final fullName = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
                            
                            // Navigate to E-Sign screen for document upload and signing
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ESignDocumentScreen(
                                  documentTitle: 'RIA Agreement',
                                  pdfFilePath: null, // User must upload document + Aadhaar
                                  signerName: fullName.isNotEmpty ? fullName : 'User',
                                  signerEmail: user?.email ?? '',
                                  signerPhone: user?.phonenumber ?? '',
                                  onSuccess: () {
                                    setState(() {
                                      _riaAgreementSigned = true;
                                    });
                                  },
                                  onFailure: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('E-Sign failed. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                            
                            // Step 3: If E-Sign completed, open payment gateway
                            if (result == 'payment' && mounted) {
                              setState(() {
                                _riaAgreementSigned = true;
                              });
                              
                              // Open payment gateway
                              final paymentResult = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CashfreeSubscriptionScreen(
                                    planId: 'RIA_ADVISORY_PLAN', // Replace with your actual plan ID
                                    amount: 1000.0, // Replace with your actual amount
                                    customerName: fullName.isNotEmpty ? fullName : 'User',
                                    customerEmail: user?.email ?? '',
                                    customerPhone: user?.phonenumber ?? '',
                                    onSuccess: () {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Payment successful!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    onFailure: () {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Payment failed. Please try again.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                              
                              if (paymentResult == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment completed successfully!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Security Info Card
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
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secured by eMudhra',
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '256-bit encrypted digital signature',
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // Continue Button
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _riskProfilingSigned && _riaAgreementSigned
                      ? () async {
                          // Get user data from UserController
                          final userController = Get.find<UserController>();
                          final user = userController.userData;
                          
                          // Build full name from firstname and lastname
                          final fullName = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
                          
                          // Open payment gateway
                          final paymentResult = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CashfreeSubscriptionScreen(
                                planId: 'RIA_ADVISORY_PLAN', // Replace with your actual plan ID
                                amount: 1000.0, // Replace with your actual amount
                                customerName: fullName.isNotEmpty ? fullName : 'User',
                                customerEmail: user?.email ?? '',
                                customerPhone: user?.phonenumber ?? '',
                                onSuccess: () {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment successful!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                onFailure: () {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment failed. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                          
                          if (paymentResult == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment completed successfully! Proceeding to basket...'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            // TODO: Navigate to basket or next screen after successful payment
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _riskProfilingSigned && _riaAgreementSigned
                        ? (isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground)
                        : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
                    foregroundColor: _riskProfilingSigned && _riaAgreementSigned
                        ? (isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText)
                        : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                    disabledForegroundColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  child: Text(
                    _riskProfilingSigned && _riaAgreementSigned
                        ? 'Sign Documents (2/2)'
                        : 'Sign Documents (${(_riskProfilingSigned ? 1 : 0) + (_riaAgreementSigned ? 1 : 0)}/2)',
                    style: const TextStyle(
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

  Widget _buildDocumentCard({
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required bool isSigned,
    required VoidCallback onProceed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSigned
              ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
          width: isSigned ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Document Icon or Check Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSigned
                      ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
                      : (isDarkMode ? const Color(0xFF0C0C0C) : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSigned ? Icons.check : Icons.description_outlined,
                  color: isSigned
                      ? (isDarkMode ? AppColors.darkBackground : AppColors.lightBackground)
                      : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
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
            ],
          ),
          
          if (isSigned) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Signed Successfully',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground,
                  foregroundColor: isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Proceed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
