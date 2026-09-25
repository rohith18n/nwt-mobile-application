import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class DeleteAssetService {
  Future<PersonalAssetsResponse> deletePersonalAsset({
    required int assetId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      AppLogger.info('Deleting Asset ID: $assetId', tag: 'DeleteAssetService');

      final response = await NetworkAPIHelper().delete(
        ApiURLs.DELETE_PERSONAL_ASSET(assetId),
      );

      AppLogger.info(
        'Delete Asset Response: ${response?.body}',
        tag: 'DeleteAssetService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Delete Asset Response Data: ${responseData.toString()}',
          tag: 'DeleteAssetService',
        );

        if (response.statusCode == 200 ||
            response.statusCode == 204 ||
            response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Failed to delete asset',
          );
        }
      } else {
        return PersonalAssetsResponse(
          status: response?.statusCode ?? 0,
          message: 'No response from server',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Delete Asset Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'DeleteAssetService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }
}
