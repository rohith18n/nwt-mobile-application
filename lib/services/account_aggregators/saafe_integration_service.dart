import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/saafe_approve.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregators_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:saafe_aa_sdk/saafe_sdk.dart';

/// A service to handle Saafe SDK integration across the app
class SaafeIntegrationService {
  // Singleton instance
  static final SaafeIntegrationService _instance =
      SaafeIntegrationService._internal();
  factory SaafeIntegrationService() => _instance;
  SaafeIntegrationService._internal();      

  // Dependencies
  final AccountAggregatorsService _accountAggregatorsService =
      AccountAggregatorsService();
  final UserController _userController = Get.find<UserController>();

  /// Opens the Saafe SDK for account linking
  ///
  /// [context] - The BuildContext for showing dialogs and SDK
  /// [onSuccess] - Callback function to execute when linking is successful
  /// [onError] - Optional callback function for handling errors
  /// [onCancel] - Optional callback function when user cancels the process
  Future<void> openSaafeSdk({
    required BuildContext context,
    String? phoneNumber,
    Function? onError,
    Function? onCancel,
  }) async {
    // Show loading indicator during API call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    // Use provided phone number or get from user controller
    final normalizedPhone =
        (phoneNumber ?? _userController.userData?.phonenumber ?? "").trim();

    // Create consent using the service
    final consentResponse = await _accountAggregatorsService.createConsent(
      identifier: normalizedPhone,
      type: "MOBILE",
      frontendUrl: "https://www.google.com/",
      assetNames: [],
      fipids: [],
      onLoading: (isLoading) {
        // No need to use setState here as we're using dialog for loading state
        if (!isLoading && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
      },
    );

    if (consentResponse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to create consent")));
      return;
    }

    // Persist phone ONLY after consent/initiate succeeds (mirrors Finarkein behavior).
    try {
      final user = _userController.userData;
      final isEmailUserWithoutPhone =
          user != null &&
          (user.email ?? '').trim().isNotEmpty &&
          (user.phonenumber == null || (user.phonenumber ?? '').trim().isEmpty);
      if (isEmailUserWithoutPhone && normalizedPhone.isNotEmpty) {
        final updated = await AuthService().updatePhone(
          phonenumber: normalizedPhone,
        );
        if (updated) {
          await _userController.fetchUserProfile(onLoading: (_) {});
          AppLogger.info(
            'Saafe: updated primary phone for email user after consent create success',
            tag: 'SaafeIntegrationService',
          );
        } else {
          AppLogger.warning(
            'Saafe: updatePhone failed after consent create success (non-blocking)',
            tag: 'SaafeIntegrationService',
          );
        }
      }
    } catch (_) {
      // Non-blocking
    }

    // Open Saafe SDK with consent data
    await SaafeSdk.triggerRedirect(
      context,
      SaafeRedirectOptions(
        fi: consentResponse.data.fi,
        reqdate: consentResponse.data.reqdate,
        ecreq: consentResponse.data.ecreq,
        displayMode: DisplayMode.fullPage,
        showCloseButton: false,
        theme: 'dark',
        onComplete: (data) {
          // Check if context is still valid
          if (!context.mounted) {
            AppLogger.info(
              "Context no longer valid, skipping navigation in onComplete",
              tag: "SaafeIntegrationService",
            );
            return;
          }

          // Parse the completion data
          AppLogger.info(
            "WebView onComplete callback fired with data: $data",
            tag: "SaafeIntegrationService",
          );

          final responseData = jsonDecode(data['url']);
          AppLogger.info(
            "WebView onComplete callback fired with data: ${responseData.toString()}",
            tag: "SaafeIntegrationService",
          );
          if (responseData['status'] == 'approved') {
            // Call success callback
            // First pop the current screen
              Navigator.of(context).pop();
              if (Get.isRegistered<DashboardRefreshController>()) {
                Get.find<DashboardRefreshController>().notifyAfterLink();
              }
              Get.to(
                () => const SaafeApprovedScreen(),
                transition: Transition.rightToLeft,
              );
          } else if (responseData['status'] == 'rejected') {
            AppLogger.info(
              "WebView onComplete callback fired with rejected status: $data",
              tag: "SaafeIntegrationService",
            );
            // Handle rejection
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Call error callback if provided
            if (onError != null) {
              onError(responseData);
            }

            AppLogger.info(
              "WebView onComplete callback fired with rejected status: $data",
              tag: "SaafeIntegrationService",
            );
          }
        },
        onError: (error) {
          // Check if context is still valid
          if (!context.mounted) {
            AppLogger.info(
              "Context no longer valid, skipping navigation in onError",
              tag: "SaafeIntegrationService",
            );
            return;
          }

          // Parse error details
          final errorData = jsonDecode(error);

          // Call error callback if provided
          if (onError != null) {
            onError(errorData);
          }

          // Decide whether to close SDK or show retry option
          if (errorData['errorType'] == 'network') {
            AppLogger.info(
              "WebView onError callback fired with network error: $error",
              tag: "SaafeIntegrationService",
            );
          } else {
            // if (context.mounted) {
            //   Navigator.of(context).pop(); // Close SDK for other errors
            // }
            AppLogger.info(
              "WebView onError callback fired with error: $error",
              tag: "SaafeIntegrationService",
            );
          }
        },
        onCancel: () {
          // Check if context is still valid
          if (!context.mounted) {
            AppLogger.info(
              "Context no longer valid, skipping navigation in onCancel",
              tag: "SaafeIntegrationService",
            );
            return;
          }

          // Call cancel callback if provided
          if (onCancel != null) {
            onCancel();
          }

          // User cancelled - close SDK
          AppLogger.info(
            "WebView onCancel callback fired",
            tag: "SaafeIntegrationService",
          );
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
