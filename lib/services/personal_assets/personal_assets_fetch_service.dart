import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_models.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class PersonalAssetsFetchService {
  /// Fetch all personal assets
  Future<PersonalAssetsListResponse> getAllPersonalAssets() async {
    try {
      AppLogger.info(
        'Fetching all personal assets from: ${ApiURLs.GET_PERSONAL_ASSETS}',
        tag: 'PersonalAssetsFetchService',
      );

      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_PERSONAL_ASSETS,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Personal Assets Response: ${responseData.toString()}',
          tag: 'PersonalAssetsFetchService',
        );

        return PersonalAssetsListResponse.fromJson(responseData);
      } else {
        AppLogger.error(
          'No response from server for personal assets',
          tag: 'PersonalAssetsFetchService',
        );
        return PersonalAssetsListResponse(
          statusCode: 0,
          message: 'No response from server',
          data: [],
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Personal Assets Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PersonalAssetsFetchService',
      );
      return PersonalAssetsListResponse(
        statusCode: 0,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  /// Fetch total value of personal assets
  Future<PersonalAssetsTotalValueResponse> getTotalValue() async {
    try {
      AppLogger.info(
        'Fetching personal assets total value from: ${ApiURLs.GET_PERSONAL_ASSETS_TOTAL_VALUE}',
        tag: 'PersonalAssetsFetchService',
      );

      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_PERSONAL_ASSETS_TOTAL_VALUE,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Personal Assets Total Value Response: ${responseData.toString()}',
          tag: 'PersonalAssetsFetchService',
        );

        return PersonalAssetsTotalValueResponse.fromJson(responseData);
      } else {
        AppLogger.error(
          'No response from server for personal assets total value',
          tag: 'PersonalAssetsFetchService',
        );
        return PersonalAssetsTotalValueResponse(
          statusCode: 0,
          message: 'No response from server',
          totalValue: 0.0,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Personal Assets Total Value Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PersonalAssetsFetchService',
      );
      return PersonalAssetsTotalValueResponse(
        statusCode: 0,
        message: 'Error: ${e.toString()}',
        totalValue: 0.0,
      );
    }
  }
}
