import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching_polling.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MfFetchingPollingService {
  Future<MfFetchingPolling?> getMfFetchingStatus({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.MF_FETCHING_POLLING,
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get MF Fetching Status Response: ${responseData.toString()}',
          tag: 'MfFetchingPollingService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return MfFetchingPolling.fromJson(responseData);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Get MF Fetching Status Error', error: e, tag: 'MfFetchingPollingService', stackTrace: stackTrace);
      return null;
    } finally {
      onLoading(false);
    }
  }
}