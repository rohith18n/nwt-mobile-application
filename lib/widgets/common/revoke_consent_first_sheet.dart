import 'package:flutter/material.dart';
import 'package:nwt_app/screens/profile/consent_revoke_screen.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// Shows a bottom sheet asking the user to revoke linked account consent first before deleting account.
/// Used by Data Protection and User Profile when Finarkein user has consents and taps "Email us to delete".
/// [Revoke consent] closes the sheet and pushes [ConsentRevokeScreen]; [Cancel] closes the sheet.
/// Styling matches [AccountLinkBottomSheet] and dashboard bottom sheets (dark container, custom drag handle, white primary button).
void showRevokeConsentFirstSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (BuildContext sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Revoke consent first',
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                    const SizedBox(height: 16),
                    const AppText(
                      'Revoke your linked account consent first. After revoking, you can contact us to delete your account.',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.regular,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: FinarkeinConsentsService.isRevokeInProgress
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ConsentRevokeScreen(),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Revoke consent',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const AppText(
                          'Cancel',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
