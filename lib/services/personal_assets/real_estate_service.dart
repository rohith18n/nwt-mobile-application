import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class RealEstateService {
  Future<PersonalAssetsResponse> createRealEstatePersonalAsset({
    required double purchasedValue,
    required String purchasedDate,
    required String location,
    required double areaSqFt,
    required String propertyType,
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
        'type': 'REAL_ESTATE',
        "assetname": "11",
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'location': location,
        'areasqft': areaSqFt,
        'propertytype': propertyType,
        'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };
      print(data);
      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_REAL_ESTATE,
        jsonEncode(data),
      );
      print(response?.body);

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Real Estate Data Response: ${responseData.toString()}',
          tag: 'RealEstateService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to submit real estate data',
          );
        }
      } else {
        print("asdasdasdasasdads--------------------");
        return PersonalAssetsResponse(
          status: response?.statusCode ?? 0,
          message: 'No response from server',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Submit Real Estate Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'RealEstateService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updateRealEstatePersonalAsset({
    required int assetId,
    required double purchasedValue,
    required String purchasedDate,
    required String location,
    required double areaSqFt,
    required String propertyType,
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
        'type': 'REAL_ESTATE',
        "assetname": "11",
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'location': location,
        'areasqft': areaSqFt,
        'propertytype': propertyType,
        'ownershiptype': ownershipType,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Update Real Estate Data Request: ${data.toString()}',
        tag: 'RealEstateService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Real Estate Data Response: ${response?.body}',
        tag: 'RealEstateService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to update real estate data',
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
        'Update Real Estate Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'RealEstateService',
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
