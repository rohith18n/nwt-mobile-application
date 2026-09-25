import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class CryptoService {
  Future<PersonalAssetsResponse> createCryptoPersonalAsset({
    required double purchasedValue,
    required String purchasedDate,
    required String scriptName,
    required double quantity,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'CRYPTO',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'scriptname': scriptName,
        'quantity': quantity,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };

      AppLogger.info('Crypto Data: ${jsonEncode(data)}', tag: 'CryptoService');

      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_CRYPTO,
        jsonEncode(data),
      );

      AppLogger.info(
        'Crypto Response: ${response?.body}',
        tag: 'CryptoService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Crypto Data Response: ${responseData.toString()}',
          tag: 'CryptoService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Failed to submit crypto data',
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
        'Submit Crypto Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'CryptoService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updateCryptoPersonalAsset({
    required int assetId,
    required double purchasedValue,
    required String purchasedDate,
    required String scriptName,
    required double quantity,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'CRYPTO',
        'purchasedvalue': purchasedValue,
        'purchaseddate': purchasedDate,
        'scriptname': scriptName,
        'quantity': quantity,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Update Crypto Data Request: ${jsonEncode(data)}',
        tag: 'CryptoService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Crypto Data Response: ${response?.body}',
        tag: 'CryptoService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Failed to update crypto data',
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
        'Update Crypto Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'CryptoService',
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
