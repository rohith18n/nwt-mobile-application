import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_banks.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyFinanceAssetsBanksService {
  Future<FamilyFinanceBanksResponse> getFamilyFinanceBanks({
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_DASHBOARD_ASSET_BANK(familyId);

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Finance Banks Response: ${responseData.toString()}',
          tag: 'FamilyFinanceAssetsBanksService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyFinanceBanksResponse =
              FamilyFinanceBanksResponse.fromJson(responseData);

          return familyFinanceBanksResponse;
        } else {
          return FamilyFinanceBanksResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      } else {
        return FamilyFinanceBanksResponse(
          statusCode: 0,
          message: 'Unknown error',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Family Finance Banks Error',
        error: e,
        tag: 'FamilyFinanceAssetsBanksService',
        stackTrace: stackTrace,
      );
      return FamilyFinanceBanksResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
