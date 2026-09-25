import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class LandService {
  Future<PersonalAssetsResponse> createLandPersonalAsset({
    required double purchasedValue,
    required String purchasedDate,
    required String location,
    required double areaSqFt,
    required String landType,
    required String ownershipType,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'LAND',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'location': location,
        'areasqft': areaSqFt,
        'landtype': landType,
        'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };

      AppLogger.info('Land Data: ${jsonEncode(data)}', tag: 'LandService');

      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_LAND,
        jsonEncode(data),
      );

      AppLogger.info('Land Response: ${response?.body}', tag: 'LandService');

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Land Data Response: ${responseData.toString()}',
          tag: 'LandService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Failed to submit land data',
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
        'Submit Land Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'LandService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updateLandPersonalAsset({
    required int assetId,
    required double purchasedValue,
    required String purchasedDate,
    required String location,
    required double areaSqFt,
    required String landType,
    required String ownershipType,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'LAND',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'location': location,
        'areasqft': areaSqFt,
        'landtype': landType,
        'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Update Land Data Request: ${jsonEncode(data)}',
        tag: 'LandService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Land Data Response: ${response?.body}',
        tag: 'LandService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Failed to update land data',
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
        'Update Land Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'LandService',
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
