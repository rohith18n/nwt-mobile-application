import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class PreciousMetalService {
  Future<PersonalAssetsResponse> createPreciousMetalPersonalAsset({
    required double purchasedValue,
    required String purchasedDate,
    required String metalType,
    required double weightGm,
    required String details,
    String? purity,
    String? ownershipType,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'METAL',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'metaltype': metalType,
        'weightgm': weightGm,
        'details': details,
        if (purity != null && purity.isNotEmpty) 'purity': purity,
        if (ownershipType != null && ownershipType.isNotEmpty)
          'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Precious Metal Data: ${jsonEncode(data)}',
        tag: 'PreciousMetalService',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_METAL,
        jsonEncode(data),
      );

      AppLogger.info(
        'Precious Metal Response: ${response?.body}',
        tag: 'PreciousMetalService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Precious Metal Data Response: ${responseData.toString()}',
          tag: 'PreciousMetalService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to submit precious metal data',
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
        'Submit Precious Metal Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PreciousMetalService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updatePreciousMetalPersonalAsset({
    required int assetId,
    required double purchasedValue,
    required String purchasedDate,
    required String metalType,
    required double weightGm,
    required String details,
    String? purity,
    String? ownershipType,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'METAL',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'metaltype': metalType,
        'weightgm': weightGm,
        'details': details,
        if (purity != null && purity.isNotEmpty) 'purity': purity,
        if (ownershipType != null && ownershipType.isNotEmpty)
          'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };

      AppLogger.info(
        'Update Precious Metal Data Request: ${jsonEncode(data)}',
        tag: 'PreciousMetalService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Precious Metal Data Response: ${response?.body}',
        tag: 'PreciousMetalService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to update precious metal data',
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
        'Update Precious Metal Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PreciousMetalService',
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
