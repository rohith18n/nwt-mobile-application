import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class DashboardAssetsService {
  // Cache for dashboard assets data
  DashboardAssetsResponse? _cachedDashboardAssets;
  DashboardAssetsResponse getFallbackResponse(String message, int statusCode) {
    return DashboardAssetsResponse(
      statusCode: statusCode,
      message: message,
      data: [
        AssetData(
          id: 'bank',
          title: 'Banks',
          value: 0,
          deltapercentage: 0,
          deltavalue: 0,
          islinked: false,
        ),
        AssetData(
          id: 'mutualfunds',
          title: 'Mutual Funds',
          value: 0,
          deltapercentage: 0,
          deltavalue: 0,
          islinked: false,
        ),
        AssetData(
          id: 'insurance',
          title: 'Insurance',
          value: 0,
          deltapercentage: 0,
          deltavalue: 0,
          islinked: false,
        ),
        AssetData(
          id: 'nps',
          title: 'NPS',
          value: 0,
          deltapercentage: 0,
          deltavalue: 0,
          islinked: false,
        ),
        AssetData(
          id: 'personalassets',
          title: 'Personal Assets',
          value: 0,
          deltapercentage: 0,
          deltavalue: 0,
          islinked: false,
        ),
      ],
    );
  }

  /// Fetches dashboard assets data from the API
  ///
  /// [onLoading] is a callback function to handle loading state
  /// Returns a [DashboardAssetsResponse] object or null if there's an error
  Future<DashboardAssetsResponse?> getDashboardAssets({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.USER_DASHBOARD_ASSETS,
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Dashboard Assets Response: ${responseData.toString()}',
          tag: 'DashboardAssetsService',
        );

        // Check if the response has the expected structure
        if (response.statusCode == 200 || response.statusCode == 201) {
          _cachedDashboardAssets = DashboardAssetsResponse.fromJson(
            responseData,
          );

          // Log the parsed data
          AppLogger.info(
            'Parsed dashboard assets: ${_cachedDashboardAssets?.data.length} assets found',
            tag: 'DashboardAssetsService',
          );

          return _cachedDashboardAssets;
        }
      }
      return getFallbackResponse('Something went wrong', 500);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Dashboard Assets Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'DashboardAssetsService',
      );
      return getFallbackResponse('Something went wrong', 500);
    } finally {
      onLoading(false);
    }
  }

  /// Returns the cached dashboard assets data
  ///
  /// If no data is cached, returns null
  DashboardAssetsResponse? getCachedDashboardAssets() {
    return _cachedDashboardAssets;
  }

  /// Clears the cached dashboard assets data
  void clearCache() {
    _cachedDashboardAssets = null;
  }
}
