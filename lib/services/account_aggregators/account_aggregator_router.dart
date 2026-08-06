import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/connections/finarkein_connection_screen.dart';
import 'package:nwt_app/screens/connections/saafe_connection.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/finarkein_data_fetch.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/saafe_data_fetch.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_integration_service.dart';
import 'package:nwt_app/services/account_aggregators/saafe_integration_service.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';

/// Router for AA connection: branches to Finarkein or Saafe based on user's aa_provider from profile.
/// Use at all entry points (Dashboard, Connections, Data Fetch "Link Now", NRI submit).
class AccountAggregatorRouter {
  static final AccountAggregatorRouter _instance =
      AccountAggregatorRouter._internal();
  factory AccountAggregatorRouter() => _instance;
  AccountAggregatorRouter._internal();

  final UserController _userController = Get.find<UserController>();

  /// Opens the appropriate AA connection flow (Finarkein or Saafe) based on user's aa_provider.
  /// If [phoneNumber] is provided (e.g. from NRI submit), starts the flow directly with that phone;
  /// otherwise navigates to the connection screen where user taps "I ACKNOWLEDGE".
  Future<void> openConnection(
    BuildContext context, {
    String? phoneNumber,
    bool showConnectionScreen = false,
    bool hideBackButton = false,
  }) async {
    var user = _userController.userData;
    // Ensure we have latest profile before choosing AA provider.
    if (user == null) {
      await _userController.fetchUserProfile(onLoading: (_) {});
      user = _userController.userData;
    }
    final isFinarkein = user?.isFinarkeinAa ?? false;
    final normalizedPhone = phoneNumber?.trim();

    if (isFinarkein) {
      if (FinarkeinIntegrationService.isConsentStatusInProgress) {
        SnackbarHelper.showInfo(
          title: 'Please wait',
          message:
              'Linking is already in progress. Please wait for it to complete.',
          position: SnackPosition.TOP,
        );
        return;
      }
      if (showConnectionScreen) {
        Get.to(
          () => FinarkeinConnectionScreen(
            phoneNumber: normalizedPhone,
            hideBackButton: hideBackButton,
          ),
          transition: Transition.rightToLeft,
        );
      } else if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        await FinarkeinIntegrationService().initiateAndOpenRedirect(
          context: context,
          phoneNumber: normalizedPhone,
          hideBackButton: hideBackButton,
        );
      } else {
        Get.to(
          () => FinarkeinConnectionScreen(hideBackButton: hideBackButton),
          transition: Transition.rightToLeft,
        );
      }
    } else {
      if (showConnectionScreen) {
        Get.to(
          () => SaafeConnectionScreen(
            phoneNumber: normalizedPhone,
            hideBackButton: hideBackButton,
          ),
          transition: Transition.rightToLeft,
        );
      } else if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        await SaafeIntegrationService().openSaafeSdk(
          context: context,
          phoneNumber: normalizedPhone,
        );
      } else {
        Get.to(
          () => SaafeConnectionScreen(hideBackButton: hideBackButton),
          transition: Transition.rightToLeft,
        );
      }
    }
  }

  /// Opens the Data Fetch Status screen (Finarkein or Saafe).
  void openDataFetchStatus(BuildContext context) {
    if (_userController.userData?.isFinarkeinAa == true) {
      Get.to(
        () => const FinarkeinDataFetch(),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(() => const SaafeDataFetch(), transition: Transition.rightToLeft);
    }
  }
}
