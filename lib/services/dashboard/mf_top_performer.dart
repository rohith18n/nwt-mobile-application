import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/dashboard/types/mf_top_performers.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MFTopPerformerService {
  Future<MutualFundTopPerformersRespose?> getTopPerformers({
    required Function(bool isLoading) onLoading,
    required int limit,
    int offset = 0,
    required String type,
  }) async {
    // Don't call onLoading here - let the controller handle loading state
    try {
      final url = "${ApiURLs.MUTUAL_FUNDS_LIST}?start=$offset&length=$limit&include_total=true";
      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get MF Top Performers Response: ${responseData.toString()}',
          tag: 'MFTopPerformerService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return MutualFundTopPerformersRespose.fromJson(responseData);
        } else {
          return MutualFundTopPerformersRespose(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return MutualFundTopPerformersRespose(
        statusCode: response?.statusCode ?? 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e) {
      AppLogger.error(
        'Get MF Top Performers Error',
        error: e,
        tag: 'MFTopPerformerService',
      );
      return MutualFundTopPerformersRespose(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      // Don't call onLoading here - let the controller handle loading state
    }
  }
}
