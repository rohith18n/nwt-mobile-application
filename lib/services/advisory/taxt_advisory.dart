import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/advisory/types/tax_advisory.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class TaxAdvisoryResponseModel {
  final int statusCode;
  final String message;
  final TaxAdvisoryResponse? data;

  TaxAdvisoryResponseModel({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory TaxAdvisoryResponseModel.fromJson(Map<String, dynamic> json) {
    return TaxAdvisoryResponseModel(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? 'Unknown error',
      data: TaxAdvisoryResponse.fromJson(json),
    );
  }
}

class TaxAdvisoryService {
  Future<TaxAdvisoryResponseModel> getTaxAdvisoryData() async {
    try {
      AppLogger.info('Fetching tax advisory data', tag: 'TaxAdvisoryService');

      final response = await NetworkAPIHelper().get(ApiURLs.GET_TAX_ADVISORY);

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          AppLogger.info(
            'Tax Advisory Data Fetched Successfully $responseData',
            tag: 'TaxAdvisoryService',
          );

          return TaxAdvisoryResponseModel(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: TaxAdvisoryResponse.fromJson(responseData),
          );
        } else {
          AppLogger.error(
            'Tax Advisory API Error: Status ${response.statusCode}, Response: ${response.body}',
            tag: 'TaxAdvisoryService',
          );
          return TaxAdvisoryResponseModel(
            statusCode: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to fetch tax advisory data',
            data: null,
          );
        }
      } else {
        AppLogger.error(
          'Tax Advisory API Error: Null response from server',
          tag: 'TaxAdvisoryService',
        );
        return TaxAdvisoryResponseModel(
          statusCode: 500,
          message: 'Failed to connect to server. Please try again later.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Tax Advisory Service Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'TaxAdvisoryService',
      );
      return TaxAdvisoryResponseModel(
        statusCode: 0,
        message: 'An error occurred while fetching tax advisory data',
      );
    }
  }
}
