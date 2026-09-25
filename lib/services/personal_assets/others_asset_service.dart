import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class OthersAssetService {
  Future<PersonalAssetsResponse> createOthersAssetPersonalAsset({
    required String assetName,
    required double purchasedValue,
    required String purchasedDate,
    required String description,
    String? ownershipType,
    double? userSharePercentage,
    List<Map<String, dynamic>>? nominees,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'OTHER',
        'assetname': assetName,
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'description': description,
        if (ownershipType != null) 'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };

      AppLogger.info(
        'Others Asset Data: ${jsonEncode(data)}',
        tag: 'OthersAssetService',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_OTHER,
        jsonEncode(data),
      );

      AppLogger.info(
        'Others Asset Response: ${response?.body}',
        tag: 'OthersAssetService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Others Asset Data Response: ${responseData.toString()}',
          tag: 'OthersAssetService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to submit others asset data',
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
        'Submit Others Asset Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'OthersAssetService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updateOthersAssetPersonalAsset({
    required int assetId,
    required String assetName,
    required double purchasedValue,
    required String purchasedDate,
    required String description,
    String? ownershipType,
    double? userSharePercentage,
    List<Map<String, dynamic>>? nominees,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'OTHER',
        'assetname': assetName,
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'description': description,
        if (ownershipType != null) 'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Update Others Asset Data: ${jsonEncode(data)}',
        tag: 'OthersAssetService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Others Asset Response: ${response?.body}',
        tag: 'OthersAssetService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Update Others Asset Data Response: ${responseData.toString()}',
          tag: 'OthersAssetService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to update others asset data',
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
        'Update Others Asset Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'OthersAssetService',
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
