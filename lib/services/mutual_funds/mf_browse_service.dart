import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Mutual Fund Browse Service - V2 APIs for browsing and filtering funds
class MFBrowseService {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Unified fetch method that chooses between public and authenticated APIs
  Future<Map<String, dynamic>?> fetchSchemes({
    int start = 0,
    int length = 30,
    String? query,
    String? planType,
    String? category,
    String? subCategory,
    String? amc,
    String? schemeOption,
    int? budget,
    bool includeTotal = false,
  }) async {
    // Check for auth token to decide which API to use
    final token = await _api.getAuthToken();
    final useAuth = token != null && token.isNotEmpty;

    if (useAuth) {
      return fetchMutualFundsBrowse(
        start: start,
        length: length,
        query: query,
        planType: planType,
        category: category,
        subCategory: subCategory,
        amc: amc,
        schemeOption: schemeOption,
        budget: budget,
        includeTotal: includeTotal,
      );
    } else {
      return fetchMutualFundsBrowsePublic(
        start: start,
        length: length,
        query: query,
        planType: planType,
        category: category,
        subCategory: subCategory,
        amc: amc,
        schemeOption: schemeOption,
        budget: budget,
        includeTotal: includeTotal,
      );
    }
  }

  /// Fetch mutual funds (public - no auth required)
  /// GET /api/v2/mutual-funds/browse-public/
  Future<Map<String, dynamic>?> fetchMutualFundsBrowsePublic({
    int start = 0,
    int length = 30,
    String? query,
    String? planType,
    String? category,
    String? subCategory,
    String? amc,
    String? schemeOption,
    int? budget,
    bool includeTotal = false,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      queryParams['start'] = start.toString();
      queryParams['length'] = length.toString();
      if (query != null && query.length >= 2) queryParams['q'] = query;
      if (includeTotal) queryParams['include_total'] = '1';
      if (planType != null && planType.isNotEmpty) queryParams['plan_type'] = planType;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (subCategory != null && subCategory.isNotEmpty) queryParams['sub_category'] = subCategory;
      if (amc != null && amc.isNotEmpty) queryParams['amc'] = amc;
      if (schemeOption != null && schemeOption.isNotEmpty) queryParams['scheme_option'] = schemeOption;
      if (budget != null && budget > 0) queryParams['budget'] = budget.toString();

      final uri = Uri.parse(ApiURLs.MUTUAL_FUNDS_BROWSE_PUBLIC).replace(
        queryParameters: queryParams,
      );

      AppLogger.info(
        '📤 GET ${uri.toString()}',
        tag: 'MFBrowseService',
      );

      final response = await _api.get(uri.toString());
      
      if (response != null && response.statusCode == 200) {
        // Use background isolate for large payloads
        final Map<String, dynamic> data = response.body.length > 50000 
            ? await compute(_parseResponse, response.body) 
            : jsonDecode(response.body);

        AppLogger.info(
          '✅ Browse public response received\n'
          'Schemes count: ${data['data']?['schemes']?.length ?? 0}',
          tag: 'MFBrowseService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Browse public failed\nStatus: ${response?.statusCode}',
          tag: 'MFBrowseService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in fetchMutualFundsBrowsePublic',
        error: e,
        tag: 'MFBrowseService',
      );
      return null;
    }
  }

  /// Fetch mutual funds (authenticated - filtered by user eligibility)
  /// GET /api/v2/mutual-funds/browse/
  Future<Map<String, dynamic>?> fetchMutualFundsBrowse({
    int start = 0,
    int length = 30,
    String? query,
    String? planType,
    String? category,
    String? subCategory,
    String? amc,
    String? schemeOption,
    int? budget,
    bool includeTotal = false,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      queryParams['start'] = start.toString();
      queryParams['length'] = length.toString();
      if (query != null && query.length >= 2) queryParams['q'] = query;
      if (includeTotal) queryParams['include_total'] = '1';
      if (planType != null && planType.isNotEmpty) queryParams['plan_type'] = planType;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (subCategory != null && subCategory.isNotEmpty) queryParams['sub_category'] = subCategory;
      if (amc != null && amc.isNotEmpty) queryParams['amc'] = amc;
      if (schemeOption != null && schemeOption.isNotEmpty) queryParams['scheme_option'] = schemeOption;
      if (budget != null && budget > 0) queryParams['budget'] = budget.toString();

      final uri = Uri.parse(ApiURLs.MUTUAL_FUNDS_BROWSE).replace(
        queryParameters: queryParams,
      );

      AppLogger.info(
        '📤 GET ${uri.toString()}',
        tag: 'MFBrowseService',
      );

      final response = await _api.get(uri.toString());

      if (response != null && response.statusCode == 200) {
        // Use background isolate for large payloads
        final Map<String, dynamic> data = response.body.length > 50000 
            ? await compute(_parseResponse, response.body) 
            : jsonDecode(response.body);

        AppLogger.info(
          '✅ Browse response received\n'
          'Schemes count: ${data['data']?['schemes']?.length ?? 0}',
          tag: 'MFBrowseService',
        );
        return data;
      } else if (response != null && response.statusCode == 403) {
        final data = jsonDecode(response.body);
        AppLogger.warning(
          '⚠️ Browse forbidden - PAN verification required\n'
          'Message: ${data['message']}',
          tag: 'MFBrowseService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Browse failed\nStatus: ${response?.statusCode}',
          tag: 'MFBrowseService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in fetchMutualFundsBrowse',
        error: e,
        tag: 'MFBrowseService',
      );
      return null;
    }
  }

  /// Fetch filter options for browse UI
  /// GET /api/v2/mutual-funds/browse/filter-options/
  Future<Map<String, dynamic>?> fetchMutualFundsBrowseFilterOptions() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.MUTUAL_FUNDS_BROWSE_FILTER_OPTIONS}',
        tag: 'MFBrowseService',
      );

      final response = await _api.get(ApiURLs.MUTUAL_FUNDS_BROWSE_FILTER_OPTIONS);

      if (response != null && response.statusCode == 200) {
        // Use background isolate for large payloads
        final Map<String, dynamic> data = response.body.length > 50000 
            ? await compute(_parseResponse, response.body) 
            : jsonDecode(response.body);

        AppLogger.info(
          '✅ Filter options received\n'
          'Categories: ${data['data']?['categories']?.length ?? 0}\n'
          'AMCs: ${data['data']?['amcs']?.length ?? 0}',
          tag: 'MFBrowseService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Filter options failed\nStatus: ${response?.statusCode}',
          tag: 'MFBrowseService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in fetchMutualFundsBrowseFilterOptions',
        error: e,
        tag: 'MFBrowseService',
      );
      return null;
    }
  }

  /// Fetch detailed fund information
  /// GET /api/v2/mutual-funds/detail/?isin=...
  Future<Map<String, dynamic>?> fetchMutualFundDetail({
    required String isin,
  }) async {
    try {
      final uri = Uri.parse(ApiURLs.MUTUAL_FUNDS_DETAIL_V2).replace(
        queryParameters: {'isin': isin},
      );

      AppLogger.info(
        '📤 GET ${uri.toString()}',
        tag: 'MFBrowseService',
      );

      final response = await _api.get(uri.toString());

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Fund detail received\n'
          'Fund: ${data['data']?['name'] ?? 'N/A'}',
          tag: 'MFBrowseService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Fund detail failed\nStatus: ${response?.statusCode}',
          tag: 'MFBrowseService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in fetchMutualFundDetail',
        error: e,
        tag: 'MFBrowseService',
      );
      return null;
    }
  }

  /// Static parsing function for compute isolate
  static Map<String, dynamic> _parseResponse(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
