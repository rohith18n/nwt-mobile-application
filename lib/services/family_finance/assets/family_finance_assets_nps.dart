import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_nps.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyFinanceAssetsNPSService {
  Future<FamilyFinanceNpsResponse> getFamilyFinanceAssetsNPS({
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_DASHBOARD_ASSET_NPS(familyId);

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Finance NPS Response: ${responseData.toString()}',
          tag: 'FamilyFinanceAssetsNPSService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyFinanceNpsResponse = FamilyFinanceNpsResponse.fromJson(
            responseData,
          );

          return familyFinanceNpsResponse;
        } else {
          return FamilyFinanceNpsResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      } else {
        return FamilyFinanceNpsResponse(
          statusCode: 0,
          message: 'Unknown error',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Family Finance NPS Error',
        error: e,
        tag: 'FamilyFinanceAssetsNPSService',
        stackTrace: stackTrace,
      );
      return FamilyFinanceNpsResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
