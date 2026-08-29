import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_submission.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/bse_onboarding.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SubmissionStatusScreen extends StatelessWidget {
  final bool isSubmitting;
  final BseSubmissionResponse? submissionResponse;
  final String? submissionError;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback? onRestart;

  const SubmissionStatusScreen({
    super.key,
    required this.isSubmitting,
    this.submissionResponse,
    this.submissionError,
    required this.onRetry,
    required this.onDone,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final bseStatus = submissionResponse?.data?.bseResponse?.status;
    final isBseSuccess = bseStatus == 'success';

    if (isSubmitting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Submitting data to BSE...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your application',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (submissionResponse != null && isBseSuccess) {
      final clientCode =
          submissionResponse?.data?.bseResponse?.data?.clientCode ?? 'N/A';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Submission Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Client Code: $clientCode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    } else if (submissionError != null ||
        (submissionResponse != null && !isBseSuccess)) {
      // Find the first message with an action if available
      String? actionSuggestion;
      if (submissionResponse?.data?.bseResponse?.messages != null &&
          submissionResponse!.data!.bseResponse!.messages!.isNotEmpty) {
        actionSuggestion =
            submissionResponse!
                .data!
                .bseResponse!
                .messages!
                .first
                .actionSuggestion;
      }

      final bseData = submissionResponse?.data?.bseResponse?.data;
      final showTechnicalDetails =
          bseData?.clientCode != null || bseData?.memberCode != null;

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Technical info section (like Client/Member codes)
              if (showTechnicalDetails) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'TECHNICAL RESPONSE DATA',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (bseData?.clientCode != null)
                        _buildTechnicalDetailItem(
                          'Client Code',
                          bseData!.clientCode!,
                        ),
                      if (bseData?.memberCode != null)
                        _buildTechnicalDetailItem(
                          'Member Code',
                          bseData!.memberCode!,
                        ),
                    ],
                  ),
                ),
              ],

              // Multi-error handling
              if (submissionResponse?.data?.bseResponse?.messages != null &&
                  submissionResponse!
                      .data!
                      .bseResponse!
                      .messages!
                      .isNotEmpty) ...[
                // Unique error messages
                ...submissionResponse!.data!.bseResponse!.messages!
                    .map((m) => m.formattedMessage)
                    .toSet()
                    .map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildErrorDetailCard(
                          title: 'Error detail',
                          content: msg,
                          icon: Icons.info_outline,
                          iconColor: Colors.blueAccent,
                        ),
                      ),
                    ),

                const SizedBox(height: 16),

                // Unique action suggestions
                ...submissionResponse!.data!.bseResponse!.messages!
                    .map((m) => m.actionSuggestion)
                    .toSet()
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildErrorDetailCard(
                          title: 'What to do?',
                          content: suggestion,
                          icon: Icons.lightbulb_outline,
                          iconColor: Colors.amberAccent,
                        ),
                      ),
                    ),
              ] else ...[
                // Fallback to single error if no messages present
                _buildErrorDetailCard(
                  title: 'What happened?',
                  content:
                      submissionError ??
                      'An unknown error occurred during submission',
                  icon: Icons.info_outline,
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _buildErrorDetailCard(
                  title: 'What should I do?',
                  content:
                      actionSuggestion ??
                      'Please review your information and try again. If the issue persists, contact support.',
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amberAccent,
                ),
              ],

              const SizedBox(height: 16),


              AppButton(
                text: 'Contact Support',
                onPressed: () {
                  SupportContactService.contactSupport(
                    context: SupportContext.generalSupport,
                  );
                },
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                leadingIcon: Icons.chat_bubble_outline_rounded,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback loading state if neither success nor error is present initially
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildTechnicalDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodySmall,
            customColor: Colors.white70,
          ),
          AppText(
            value,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.bold,
            customColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDetailCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
