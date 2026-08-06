import 'package:get/get.dart';
import 'package:nwt_app/screens/search/global_search/types/search.dart';
import 'package:nwt_app/screens/search/global_search/types/trending.dart';
import 'package:nwt_app/services/search/global_search.dart';
import 'package:nwt_app/services/search/search_history.dart';
import 'package:nwt_app/utils/logger.dart';

class GlobalSearchController extends GetxController {
  List<TrendingResult> trendingData = [];
  List<String> suggestions = [];
  List<GlobalSearchResult> searchResults = [];

  final GlobalSearchService globalSearchService = GlobalSearchService();
  final SearchHistoryService searchHistoryService =
      Get.find<SearchHistoryService>();

  /// Clears the current search results
  void clearSearchResults() {
    searchResults = [];
    update();
  }

  /// Sets search results from cache
  void setSearchResultsFromCache(List<GlobalSearchResult> cachedResults) {
    searchResults = cachedResults;
    update();
  }

  /// Sets trending data from cache
  void setTrendingFromCache(List<TrendingResult> cachedTrending) {
    trendingData = cachedTrending;
    update();
  }

  void getTrending({
    required Function(bool isLoading) onLoading,
    String type = '',
    Function(List<TrendingResult>)? onSuccess,
  }) {
    globalSearchService.getTrending(type: type, onLoading: onLoading).then((
      value,
    ) {
      trendingData = value.data?.search ?? [];
      suggestions = value.data?.suggestion ?? [];
      update();

      if (onSuccess != null) {
        onSuccess(trendingData);
      }
    });
  }

  void search({
    required String query,
    required String type,
    required int limit,
    required Function(bool isLoading) onLoading,
    Function(List<GlobalSearchResult>)? onSuccess,
  }) {
    AppLogger.info('Search Query: $query', tag: 'GlobalSearchController');
    globalSearchService.search(query, type, limit, onLoading: onLoading).then((
      value,
    ) {
      searchResults = value.data ?? [];
      update();

      if (onSuccess != null) {
        onSuccess(searchResults);
      }
    });
  }
}
