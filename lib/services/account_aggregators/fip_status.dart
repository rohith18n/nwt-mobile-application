import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FipStatusService {
  Future<FipStatusResponse?> getFipStatus({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_FINARKEIN_STATUS,
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get FIP Status Response: ${responseData.toString()}',
          tag: 'FipStatusService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return FipStatusResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Get FIP Status Error', error: e, tag: 'FipStatusService');
      return null;
    } finally {
      onLoading(false);
    }
  }
}