import 'package:get/get.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_integration_service.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';

/// Runs revoke status polling (for Dashboard backend-driven flow).
/// On terminal: refreshes consents and dashboard, shows snackbar. Call from Dashboard when pendingRevokeRequestId is set.
/// Note: triggerDataFetch is now called in ConsentRevokeScreen before navigation, so this only handles refresh.
Future<void> runPendingRevokePolling(String requestId) async {
  FinarkeinConsentsService.isRevokeInProgress = true;
  try {
    final statusResult = await FinarkeinConsentsService().pollRevokeStatusUntilTerminal(requestId);
    SnackbarHelper.safeCloseAll();
    if (statusResult.success) {
      await _refreshConsentsAndDashboard(forRevoke: true);
      SnackbarHelper.showSuccess(
        title: 'Account delinked',
        message: 'Account delinked successfully.',
        position: SnackPosition.TOP,
      );
    } else {
      SnackbarHelper.showError(
        title: 'Delink failed',
        message: 'Delink could not be completed. Please try again.',
        position: SnackPosition.TOP,
      );
      await _refreshConsentsAndDashboard(forRevoke: true);
    }
  } catch (_) {
    SnackbarHelper.safeCloseAll();
    SnackbarHelper.showError(
      title: 'Delink',
      message: 'Delink is taking longer than expected. Pull to refresh or open Connections to see the latest status.',
      position: SnackPosition.TOP,
    );
    await _refreshConsentsAndDashboard(forRevoke: true);
  } finally {
    FinarkeinConsentsService.isRevokeInProgress = false;
  }
}

/// Runs consent status + data/result polling (for Dashboard backend-driven flow).
/// On terminal: refreshes consents and dashboard, shows snackbar. Call from Dashboard when pendingConsentRequestId is set.
Future<void> runPendingConsentPolling(String requestId) async {
  final outcome = await FinarkeinIntegrationService().pollConsentStatusAndDataResultInBackground(requestId);
  SnackbarHelper.safeCloseAll();
  switch (outcome) {
    case ConsentPollOutcome.success:
      await _refreshConsentsAndDashboard(forRevoke: false);
      SnackbarHelper.showSuccess(
        title: 'Account linked',
        message: 'Your account has been linked successfully.',
        position: SnackPosition.TOP,
      );
      break;
    case ConsentPollOutcome.failed:
      SnackbarHelper.showError(
        title: 'Linking failed',
        message: 'Consent was not approved.',
        position: SnackPosition.TOP,
      );
      await _refreshConsentsAndDashboard(forRevoke: false);
      break;
    case ConsentPollOutcome.abandoned:
      SnackbarHelper.showInfo(
        title: 'Consent abandoned',
        message: 'Consent was abandoned or timed out.',
        position: SnackPosition.TOP,
      );
      await _refreshConsentsAndDashboard(forRevoke: false);
      break;
    case ConsentPollOutcome.timeout:
    case ConsentPollOutcome.maxErrors:
      SnackbarHelper.showInfo(
        title: 'Please try again later',
        message: 'Consent is still pending. Please try again later.',
        position: SnackPosition.TOP,
      );
      await _refreshConsentsAndDashboard(forRevoke: false);
      break;
  }
}

Future<void> _refreshConsentsAndDashboard({required bool forRevoke}) async {
  try {
    await FinarkeinConsentsService().getConsents(forceRefresh: true);
    FinarkeinConsentsService.resetDataResultCircuit();
    final provider = getAccountAggregatorDataProvider();
    if (forRevoke) {
      await provider.refreshDashboardData(fetchResults: false);
    }
    final controllerRegistered = Get.isRegistered<DashboardRefreshController>();
    DashboardRefreshController? c;
    if (controllerRegistered) {
      c = Get.find<DashboardRefreshController>();
    }
    if (controllerRegistered && c != null) {
      if (forRevoke) {
        c.notifyAfterDelink();
      } else {
        c.notifyAfterLink();
      }
    }
  } catch (_) {}
}
