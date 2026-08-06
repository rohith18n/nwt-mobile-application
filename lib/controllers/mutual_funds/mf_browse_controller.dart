import 'package:get/get.dart';
import 'package:nwt_app/services/mutual_funds/mf_browse_service.dart';
import 'package:nwt_app/utils/logger.dart';

/// Controller to manage Mutual Fund browsing state and shared filter options
class MFBrowseController extends GetxController {
  final MFBrowseService _service = MFBrowseService();
  
  // Shared filter options data
  final RxMap<String, dynamic> filterOptions = <String, dynamic>{}.obs;
  final RxBool isLoadingFilters = false.obs;

  // Initial schemes data for pre-fetching
  final RxList<dynamic> initialSchemes = <dynamic>[].obs;
  final RxInt totalCount = 0.obs;
  final RxBool isLoadingSchemes = false.obs;

  static MFBrowseController get to => Get.find<MFBrowseController>();

  /// Fetch filter options if not already loaded
  Future<void> fetchFilterOptions({bool forceRefresh = false}) async {
    if (filterOptions.isNotEmpty && !forceRefresh) {
      AppLogger.info('MF Filter options already available, skipping fetch', tag: 'MFBrowseController');
      return;
    }
    
    isLoadingFilters.value = true;
    try {
      AppLogger.info('Fetching MF filter options...', tag: 'MFBrowseController');
      final result = await _service.fetchMutualFundsBrowseFilterOptions();
      
      if (result != null && result['success'] == true) {
        filterOptions.value = result['data'] ?? {};
        AppLogger.info(
          '✅ MF Filter options stored successfully\n'
          'Categories: ${filterOptions['categories']?.length ?? 0}\n'
          'AMCs: ${filterOptions['amcs']?.length ?? 0}', 
          tag: 'MFBrowseController'
        );
      } else {
        AppLogger.error('❌ Failed to fetch MF filter options', tag: 'MFBrowseController');
      }
    } catch (e) {
      AppLogger.error('❌ Exception in fetchFilterOptions', error: e, tag: 'MFBrowseController');
    } finally {
      isLoadingFilters.value = false;
    }
  }

  /// Fetch initial mutual fund schemes to speed up screen loading
  Future<void> fetchInitialSchemes({bool forceRefresh = false}) async {
    if (initialSchemes.isNotEmpty && !forceRefresh) {
      AppLogger.info('MF Initial schemes already available, skipping fetch', tag: 'MFBrowseController');
      return;
    }

    isLoadingSchemes.value = true;
    try {
      AppLogger.info('Pre-fetching initial MF schemes...', tag: 'MFBrowseController');
      final result = await _service.fetchMutualFundsBrowsePublic(
        start: 0,
        length: 30,
        includeTotal: true,
      );

      if (result != null && result['success'] == true) {
        final data = result['data'];
        initialSchemes.value = data['schemes'] ?? [];
        totalCount.value = data['total_count'] ?? 0;
        AppLogger.info(
          '✅ MF Initial schemes pre-fetched successfully (${initialSchemes.length} schemes)', 
          tag: 'MFBrowseController'
        );
      } else {
        AppLogger.error('❌ Failed to pre-fetch MF schemes', tag: 'MFBrowseController');
      }
    } catch (e) {
      AppLogger.error('❌ Exception in fetchInitialSchemes', error: e, tag: 'MFBrowseController');
    } finally {
      isLoadingSchemes.value = false;
    }
  }
}
