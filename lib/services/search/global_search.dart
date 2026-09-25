import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/search/global_search/types/search.dart';
import 'package:nwt_app/screens/search/global_search/types/trending.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class GlobalSearchService {
  Future<GlobalSearchResponse> search(
    String query,
    String type,
    int limit, {
    required Function(bool isLoading) onLoading,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      onLoading(false);
      return GlobalSearchResponse(
        statusCode: 200,
        message: 'Query too short',
        data: [],
      );
    }

    onLoading(true);
    try {
      // Exclusively use the new V1 Mutual Funds Search API (POST) per user request
      final url = ApiURLs.MUTUAL_FUNDS_BROWSE;
      final body = {'q': trimmedQuery, if (limit > 0) 'limit': limit};

      AppLogger.info(
        'POST Global Search (V1 MF) URL: $url',
        tag: 'GlobalSearchService',
      );
      final response = await NetworkAPIHelper().post(url, body);

      if (response != null) {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return GlobalSearchResponse.fromJson(responseData);
        }
        return GlobalSearchResponse(
          statusCode: response.statusCode,
          message: responseData['message'] ?? 'Unknown error',
          data: [],
        );
      }

      return GlobalSearchResponse(
        statusCode: 0,
        message: 'No response from server',
        data: [],
      );
    } catch (e) {
      AppLogger.error(
        'V1 global search failed, defaulting to empty results',
        error: e,
        tag: 'GlobalSearchService',
      );
      return GlobalSearchResponse(
        statusCode: 0,
        message: e.toString(),
        data: [],
      );
    } finally {
      onLoading(false);
    }
  }

  Future<GlobalSearchTrendingResponse> getTrending({
    required Function(bool isLoading) onLoading,
    String type = '',
  }) async {
    // onLoading(true);
    try {
      // Neutralized legacy call per user request
      return GlobalSearchTrendingResponse(
        statusCode: 200,
        message: 'Success',
        data: TrendingData(
          search: [],
          suggestion: [],
        ), // Return empty data object
      );
      /*
      String url = ApiURLs.GET_GLOBAL_SEARCH_TRENDING;
      // Add type parameter to URL if provided
      url = "$url?limit=8${type.isNotEmpty ? '&type=$type' : ''}";
      final response = await NetworkAPIHelper().get(url);
      ...
      */
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Global Search Trending Neutralized Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'GlobalSearchService',
      );
      return GlobalSearchTrendingResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      // onLoading(false);
    }
  }
}
