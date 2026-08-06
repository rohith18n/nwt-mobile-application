import 'package:get/get.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/types/finarkein/firnarkein_data_response.dart';
import 'package:nwt_app/utils/logger.dart';

class FinarkeinDataController extends GetxController {
  static FinarkeinDataController get to => Get.find<FinarkeinDataController>();

  final FinarkeinDataService _dataService = FinarkeinDataService();
  final RxBool isLoading = false.obs;
  final Rx<FinarkeinDataResponse?> dataResponse = Rx<FinarkeinDataResponse?>(
    null,
  );

  /// Fetch Finarkein data from the global result endpoint.
  /// Updates [FinarkeinDataStore] on success to ensure UI reflects new data.
  Future<void> fetchFinarkeinData() async {
    try {
      isLoading.value = true;
      AppLogger.info('Fetching Finarkein data...', tag: 'Finarkein Data');

      // Update the central FinarkeinDataStore if it's registered

      final response = await _dataService.getFinarkeinData(
        onLoading: (loading) {
          isLoading.value = loading;
        },
      );

      if (response.success && response.data != null) {
        dataResponse.value = response;
        AppLogger.info(
          'Finarkein data fetched successfully. Updating store...',
          tag: 'Finarkein Data',
        );

        // Update the central FinarkeinDataStore if it's registered
        if (Get.isRegistered<FinarkeinDataStore>()) {
          final store = Get.find<FinarkeinDataStore>();
          final aaData = response.data?.aaData;
          if (aaData != null) {
            // Use merge: true to accumulate data from multiple demat accounts
            // (API returns separate equities.summary arrays per account)
            store.setFromDataResult(aaData.toJson(), merge: true);
            AppLogger.info(
              'FinarkeinDataStore updated with new results.',
              tag: 'Finarkein Data',
            );
          }
        }
      } else {
        AppLogger.error(
          'Failed to fetch Finarkein data: ${response.message}',
          tag: 'Finarkein Data',
        );
      }
    } catch (e) {
      AppLogger.error('Error in fetchFinarkeinData: $e', tag: 'Finarkein Data');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update controller state from a raw data/result JSON response.
  /// Useful for immediate updates after a linking journey.
  void setFromDataResult(Map<String, dynamic> body, {bool merge = false}) {
    try {
      final newData = FinarkeinDataResponse.fromJson({
        'statusCode': 200,
        'message': 'Success',
        'data': body['data'] ?? body,
      }).data;

      if (newData == null) return;

      if (!merge || dataResponse.value?.data == null) {
        dataResponse.value = FinarkeinDataResponse(
          statusCode: 200,
          message: 'Success',
          data: newData,
        );
      } else {
        final current = dataResponse.value!.data!;
        
        // Merge summary: for certain keys, we suspect they are handle-specific and should be summed.
        // However, most backends return the global summary. We'll try to be smart:
        // if the new value is significantly different, we might need a better strategy.
        // For now, we overwrite summary but we could sum up networth if we knew they were separate.
        // DECISION: Overwrite summary with the latest one, as it's usually the most "complete" view from the backend.
        final mergedSummary = Map<String, double?>.from(current.summary);
        newData.summary.forEach((key, value) {
          if (value != null && value > 0) {
            mergedSummary[key] = value;
          }
        });

        // Merge details lists
        final mergedDetails = Details(
          mf: _dedupeHoldings([...current.details.mf, ...newData.details.mf], 'mf'),
          equities: _dedupeHoldings(
            [...current.details.equities, ...newData.details.equities],
            'equity',
          ),
          etf: _dedupeHoldings(
            [...current.details.etf, ...newData.details.etf],
            'etf',
          ),
          transactioncount: {
            ...?current.details.transactioncount,
            ...?newData.details.transactioncount,
          },
        );

        // Update dataResponse with merged data
        dataResponse.value = FinarkeinDataResponse(
          statusCode: 200,
          message: 'Success',
          data: FinarkeinData(
            summary: mergedSummary,
            gainsbyasset: newData.gainsbyasset, // Use latest gains
            details: mergedDetails,
            aaData: newData.aaData, // aaData is mostly for banks, parser handles it
            meta: newData.meta,
          ),
        );
      }
      AppLogger.info(
        'FinarkeinDataController: Updated state from local journey poll (merge=$merge)',
        tag: 'Finarkein Data',
      );
    } catch (e) {
      AppLogger.error(
        'FinarkeinDataController.setFromDataResult error: $e',
        tag: 'Finarkein Data',
      );
    }
  }

  /// Helper to deduplicate holdings lists inside FinarkeinData objects
  List<T> _dedupeHoldings<T>(List<T> items, String type) {
    if (items.isEmpty) return [];

    final seen = <String>{};
    final out = <T>[];

    for (final item in items) {
      String key = "";
      if (item is Map<String, dynamic>) {
        switch (type) {
          case 'mf':
            final isin = (item['isin'] ?? '').toString().trim();
            final folio = (item['folio'] ?? item['folio_no'] ?? '').toString().trim();
            key = 'mf:$isin|$folio';
            break;
          case 'equity':
            final isin = (item['isin'] ?? '').toString().trim();
            key = 'equity:$isin';
            break;
          case 'etf':
            final isin = (item['isin'] ?? '').toString().trim();
            final folio = (item['foliono'] ?? '').toString().trim();
            key = 'etf:$isin|$folio';
            break;
          default:
            key = item.toString();
        }
      } else {
        // Handle cases where they might already be model objects (less likely here but safe)
        key = item.toString();
      }

      if (seen.add(key)) {
        out.add(item);
      }
    }
    return out;
  }
}
