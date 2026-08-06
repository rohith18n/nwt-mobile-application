import 'package:get/get.dart';
import 'package:nwt_app/screens/dashboard/types/mf_top_performers.dart';
import 'package:nwt_app/services/dashboard/mf_top_performer.dart';
import 'package:nwt_app/utils/logger.dart';

class MFTopPerformersController extends GetxController {
  final _mfTopPerformerService = MFTopPerformerService();

  final isLoading = true.obs;
  final isPaginating = false.obs;
  final hasMore = true.obs;
  int currentOffset = 0;
  final topPerformers = Rx<List<MFPerformers>?>([]);
  final collections = Rx<List<MFPerformers>?>([]);
  final currentReturnPeriodIndex = 2.obs; // Default to 5Y Returns (index 2)

  // Return period options
  final List<String> returnPeriods = ['1Y Returns', '3Y Returns', '5Y Returns'];

  // Get the current return value based on selected period using formatreturn absolute values
  double? getCurrentReturnValue(MFPerformers performer) {
    if (performer.formatreturn == null) return null;

    switch (currentReturnPeriodIndex.value) {
      case 0: // 1Y Returns
        return performer.formatreturn!.oneYear?.annualized;
      case 1: // 3Y Returns
        return performer.formatreturn!.threeYear?.annualized;
      case 2: // 5Y Returns
        return performer.formatreturn!.fiveYear?.annualized;
      default:
        return performer.formatreturn!.fiveYear?.annualized;
    }
  }

  @override
  void onInit() {
    super.onInit();
  }

  // Update the current return period index
  void updateReturnPeriod(int index) {
    if (index >= 0 && index < returnPeriods.length) {
      currentReturnPeriodIndex.value = index;
      AppLogger.info(
        'Return period updated to: ${returnPeriods[index]}',
        tag: 'MFTopPerformersController',
      );
    }
  }

  // Cycle to the next return period
  void cycleReturnPeriod() {
    currentReturnPeriodIndex.value =
        (currentReturnPeriodIndex.value + 1) % returnPeriods.length;
    AppLogger.info(
      'Return period cycled to: ${returnPeriods[currentReturnPeriodIndex.value]}',
      tag: 'MFTopPerformersController',
    );
  }

  Future<List<MFPerformers>?> fetchTopPerformers({
    required bool dashboard,
    required int limit,
    int offset = 0,
    required String type,
    bool isLoadMore = false,
  }) async {
    try {
      if (isLoadMore) {
        isPaginating.value = true;
      } else {
        isLoading.value = true;
        currentOffset = 0;
        hasMore.value = true;
      }

      final response = await _mfTopPerformerService.getTopPerformers(
        onLoading: (_) {}, // Remove loading callback to avoid build conflicts
        limit: limit,
        offset: offset,
        type: type,
      );

      if (response != null && response.data != null) {
        final newData = response.data ?? [];

        // Update hasMore based on API response if available, otherwise fallback to length check
        if (response.hasMore != null) {
          hasMore.value = response.hasMore!;
        } else if (newData.length < limit) {
          hasMore.value = false;
        }

        if (dashboard) {
          if (isLoadMore) {
            final oldData = topPerformers.value ?? [];
            topPerformers.value = [...oldData, ...newData];
          } else {
            topPerformers.value = newData;
          }
          AppLogger.info(
            'Fetched ${topPerformers.value?.length ?? 0} top performers (offset: $offset)',
            tag: 'MFTopPerformersController',
          );
        } else {
          if (isLoadMore) {
            final oldData = collections.value ?? [];
            collections.value = [...oldData, ...newData];
          } else {
            collections.value = newData;
          }
          AppLogger.info(
            'Fetched ${collections.value?.length ?? 0} collections (offset: $offset)',
            tag: 'MFTopPerformersController',
          );
        }

        currentOffset += newData.length;
        return newData;
      } else {
        if (!isLoadMore) {
          hasMore.value = false;
        }
        AppLogger.error(
          'Failed to fetch top performers',
          tag: 'MFTopPerformersController',
        );
        return [];
      }
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }
}
