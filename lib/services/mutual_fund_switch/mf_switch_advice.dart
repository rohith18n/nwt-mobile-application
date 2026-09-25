import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/mf_switch/types/mutual_fund_switch_advise.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MutualFundSwitchAdviceService {
  /// Get mutual fund switch advice for the user
  Future<MutualFundSwitchAdvisory?> getMutualFundSwitchAdvice({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_MF_SWITCH_ADVICE,
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get MF Switch Advice Response: ${responseData.toString()}',
          tag: 'MutualFundSwitchAdviceService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return MutualFundSwitchAdvisory.fromJson(responseData);
        }
      }
      return MutualFundSwitchAdvisory(
        status: response?.statusCode ?? 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get MF Switch Advice Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'MutualFundSwitchAdviceService',
      );
      return MutualFundSwitchAdvisory(
        status: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
