import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/adhoc_remaing.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class AdhocRemainingService {
  Future<AdhocRemaingResponse?> getAdhocRemaining({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.ADHOC_REMAINING,
      );
      if (response != null) {
        AppLogger.info(
          'Get Adhoc Remaining Responsesss: ${response}',
          tag: 'AdhocRemainingService',
        );
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Adhoc Remaining Responsesss: ${responseData.toString()}',
          tag: 'AdhocRemainingService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return AdhocRemaingResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Get Adhoc Remaining Error', error: e, tag: 'AdhocRemainingService');
      return null;
    } finally {
      onLoading(false);
    }
  }
}
