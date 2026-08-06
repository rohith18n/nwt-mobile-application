import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class AdhocRefreshService {
  /// Triggers an adhoc refresh for account aggregators
  ///
  /// Returns a Future<double?> with the remaining adhoc refreshes count
  /// Returns null if the request fails
  Future<double?> triggerAdhocRefresh({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(
        ApiURLs.ADHOC_REFRESH,
        {}, // Empty body as JSON
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        AppLogger.info(
          'Adhoc Refresh Response: ${responseData.toString()}',
          tag: 'AdhocRefreshService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Extract the remaining adhoc refreshes count from the response
          if (responseData['data'] != null &&
              responseData['data']['adhocremaining'] != null) {
            return responseData['data']['adhocremaining'].toDouble();
          }
          return null;
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Adhoc Refresh Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AdhocRefreshService',
      );
      return null;
    } finally {
      onLoading(false);
    }
  }
}
