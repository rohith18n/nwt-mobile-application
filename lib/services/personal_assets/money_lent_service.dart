import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/personal_assets/types/main_personal_assets.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MoneyLentService {
  Future<PersonalAssetsResponse> createMoneyLentPersonalAsset({
    required double amount,
    required String lentDate,
    required String lentTo,
    required double roiPercent,
    required int timelineMonths,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'MONEY_LENT',
        'amount': amount,
        'lentdate': lentDate,
        'lentto': lentTo,
        'roipercent': roiPercent,
        'timelinemonths': timelineMonths,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        if (nominees != null && nominees.isNotEmpty) 'nominees': nominees,
      };

      AppLogger.info(
        'Money Lent Data: ${jsonEncode(data)}',
        tag: 'MoneyLentService',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.POST_PERSONAL_FINANCE_MONEY_LENT,
        jsonEncode(data),
      );

      AppLogger.info(
        'Money Lent Response: ${response?.body}',
        tag: 'MoneyLentService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Money Lent Data Response: ${responseData.toString()}',
          tag: 'MoneyLentService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to submit money lent data',
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
        'Submit Money Lent Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'MoneyLentService',
      );
      return PersonalAssetsResponse(
        status: 0,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PersonalAssetsResponse> updateMoneyLentPersonalAsset({
    required int assetId,
    required double amount,
    required String lentDate,
    required String lentTo,
    required double roiPercent,
    required int timelineMonths,
    List<Map<String, dynamic>>? nominees,
    double? userSharePercentage,
    String? notes,
    List<String>? supportingDocs,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        'type': 'MONEY_LENT',
        'amount': amount,
        'lentdate': lentDate,
        'lentto': lentTo,
        'roipercent': roiPercent,
        'timelinemonths': timelineMonths,
        if (userSharePercentage != null)
          'usersharepercentage': userSharePercentage,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (supportingDocs != null && supportingDocs.isNotEmpty)
          'supportingdocs': supportingDocs,
        'nominees': nominees,
      };

      AppLogger.info(
        'Update Money Lent Data Request: ${jsonEncode(data)}',
        tag: 'MoneyLentService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_PERSONAL_ASSET(assetId),
        jsonEncode(data),
      );

      AppLogger.info(
        'Update Money Lent Data Response: ${response?.body}',
        tag: 'MoneyLentService',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return PersonalAssetsResponse.fromJson(responseData);
        } else {
          return PersonalAssetsResponse(
            status: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to update money lent data',
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
        'Update Money Lent Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'MoneyLentService',
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
