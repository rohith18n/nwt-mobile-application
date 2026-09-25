import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_insurance.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyFinanceAssetsInsurancesService {
  Future<FamilyFinanceAssetsInsuranceResponse> getFamilyFinanceInsurances({
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_DASHBOARD_ASSET_INSURANCE(familyId);

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Finance Insurances Response: ${responseData.toString()}',
          tag: 'FamilyFinanceAssetsInsurancesService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyFinanceInsurancesResponse =
              FamilyFinanceAssetsInsuranceResponse.fromJson(responseData);

          return familyFinanceInsurancesResponse;
        } else {
          return FamilyFinanceAssetsInsuranceResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      } else {
        return FamilyFinanceAssetsInsuranceResponse(
          statusCode: 0,
          message: 'Unknown error',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Family Finance Insurances Error',
        error: e,
        tag: 'FamilyFinanceAssetsInsurancesService',
        stackTrace: stackTrace,
      );
      return FamilyFinanceAssetsInsuranceResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
