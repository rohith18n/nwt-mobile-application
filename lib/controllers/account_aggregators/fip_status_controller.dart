import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/services/account_aggregators/fip_status.dart';
import 'package:nwt_app/utils/date_formatter.dart';

/// Controller to manage FIP status data from GET_FINARKEIN_STATUS API
/// Keeps UI in sync with current account statuses without local storage
class FipStatusController extends GetxController {
  static FipStatusController get to => Get.find<FipStatusController>();

  final FipStatusService _fipStatusService = FipStatusService();

  final Rx<FipStatusResponse?> statusResponse = Rx<FipStatusResponse?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// Get formatted last fetched time from the most recent account update
  String get lastFetchedTime {
    final response = statusResponse.value;
    if (response?.FIPStatusData == null || response!.FIPStatusData!.isEmpty) {
      return '';
    }

    // Find the most recent fetchstatusupdatedat
    DateTime? mostRecent;
    for (final datum in response.FIPStatusData!) {
      if (mostRecent == null ||
          datum.fetchstatusupdatedat.isAfter(mostRecent)) {
        mostRecent = datum.fetchstatusupdatedat;
      }
    }

    if (mostRecent == null) return '';

    return DateFormatter.formatToDateTimeWithAmPm(mostRecent);
  }

  /// Get formatted accounts list for UI components
  List<Map<String, dynamic>> get accounts {
    final response = statusResponse.value;
    if (response?.FIPStatusData == null) return [];

    return response!.FIPStatusData!.map((datum) {
      return {
        'type': datum.type,
        'fetchstatus': datum.fetchstatus,
        'fipname': datum.fipname,
        'guid': datum.guid,
        'fipid': datum.fipid,
        'userguid': datum.userguid,
        'activestatus': datum.activestatus,
        'fetchstatusupdatedat': datum.fetchstatusupdatedat,
        'balancedatetime': datum.balancedatetime,
        'imageurl': datum.imageurl,
        'maskedaccno': datum.maskedaccno,
      };
    }).toList();
  }

  /// Fetch FIP status from API
  Future<void> fetchFipStatus() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _fipStatusService.getFipStatus(onLoading: (_) {});

      if (response != null) {
        statusResponse.value = response;
      } else {
        error.value = 'Failed to fetch FIP status';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh FIP status (for pull-to-refresh)
  Future<void> refreshFipStatus() async {
    await fetchFipStatus();
  }

  /// Clear status data
  void clearStatus() {
    statusResponse.value = null;
    error.value = '';
  }
}
