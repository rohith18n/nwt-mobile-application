import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class InsuranceService {
  Future<InsuranceResponse> getInsuranceSummary({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_INSURANCE_LIST,
        // additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Insurance Summary Response: ${responseData.toString()}',
          tag: 'InsuranceService',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return InsuranceResponse.fromJson(responseData);
        } else {
          return InsuranceResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return InsuranceResponse(
        statusCode: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Insurance Summary Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InsuranceService',
      );
      return InsuranceResponse(
        statusCode: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  Future<InsuranceDetailsResponse> getInsuranceDetails({
    required String accountguid,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Use the test URL for now
      final response = await NetworkAPIHelper().get(
        '${ApiURLs.GET_INSURANCE_DETAILS}?accountguid=$accountguid',
        // additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Insurance Details Response: ${responseData.toString()}',
          tag: 'InsuranceService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return InsuranceDetailsResponse.fromJson(responseData);
        } else {
          return InsuranceDetailsResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }

      return InsuranceDetailsResponse(
        statusCode: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Insurance Details Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InsuranceService',
      );

      return InsuranceDetailsResponse(
        statusCode: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
