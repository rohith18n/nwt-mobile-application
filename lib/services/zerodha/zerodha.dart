import 'dart:convert';

import '../../constants/api.dart';
import '../../types/zerodha/zerodha.dart';
import '../../utils/logger.dart';
import '../../utils/network_api_helper.dart';

class ZerodhaService {
  Future<ZerodhaResponse?> getZerodhaLoginUrl({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_ZERODHA_CONNECTION,
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Zerodha Login URL Response: ${responseData.toString()}',
          tag: 'ZerodhaService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ZerodhaResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Get Zerodha Login URL Error',
        error: e,
        tag: 'ZerodhaService',
      );
      return null;
    } finally {
      onLoading(false);
    }
  }
}
