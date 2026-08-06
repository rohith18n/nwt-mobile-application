import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/assets/nps/types/nps.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class NPSService {
  Future<NpsRespone> getNPSData({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_NPS,
        //  additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get NPS Data Response: ${responseData.toString()}',
          tag: 'NPSService',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return NpsRespone.fromJson(responseData);
        } else {
          return NpsRespone(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: NPSData(
              totalholdings: 0,
              tier1: Tier(value: 0, schemetype: '', funds: []),
              tier2: Tier(value: 0, schemetype: '', funds: []),
              profiles: [],
            ),
          );
        }
      }
      return NpsRespone(
        statusCode: 0,
        message: 'Unknown error',
        data: NPSData(
          totalholdings: 0,
          tier1: Tier(value: 0, schemetype: '', funds: []),
          tier2: Tier(value: 0, schemetype: '', funds: []),
          profiles: [],
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get NPS Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'NPSService',
      );
      return NpsRespone(
        statusCode: 0,
        message: 'An unexpected error occurred',
        data: NPSData(
          totalholdings: 0,
          tier1: Tier(value: 0, schemetype: '', funds: []),
          tier2: Tier(value: 0, schemetype: '', funds: []),
          profiles: [],
        ),
      );
    } finally {
      onLoading(false);
    }
  }
}
