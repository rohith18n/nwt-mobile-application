import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class TotalNetworthService {
  Future<DashboardNetworthResponse> getTotalNetworth({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_TOTAL_NETWORTH);

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Total Networth Response: ${responseData.toString()}',
          tag: 'TotalNetworthService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final result = DashboardNetworthResponse.fromJson(responseData);
          return result;
        } else {
          return DashboardNetworthResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return DashboardNetworthResponse(
        status: response?.statusCode ?? 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Total Networth Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'TotalNetworthService',
      );
      return DashboardNetworthResponse(
        status: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
