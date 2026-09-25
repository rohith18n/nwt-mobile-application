import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/family_dashboard_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyDashboardAssetsService {
  Future<FamilyDashboardAssetsResponse> getFamilyDashboardAssets({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_DASHBOARD_ASSETS;

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Dashboard Assets Response: ${responseData.toString()}',
          tag: 'FamilyDashboardAssetsService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyDashboardAssetsResponse =
              FamilyDashboardAssetsResponse.fromJson(responseData);

          return familyDashboardAssetsResponse;
        } else {
          return FamilyDashboardAssetsResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      } else {
        return FamilyDashboardAssetsResponse(
          statusCode: response?.statusCode ?? 0,
          message: response?.body ?? 'Unknown error',
          data: null,
        );
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Get Family Head Member Summary Error',
        error: e,
        tag: 'FamilyHeadMemberSummaryService',
        stackTrace: subTrace,
      );
      return FamilyDashboardAssetsResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
