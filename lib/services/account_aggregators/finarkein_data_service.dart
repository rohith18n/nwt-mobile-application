import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/types/finarkein/firnarkein_data_response.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FinarkeinDataService {
  Future<FinarkeinDataResponse> getFinarkeinData({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_DATA);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Finarkein Data Response: ${responseData.toString()}',
          tag: 'Finarkein_Data',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return FinarkeinDataResponse.fromJson(responseData);
        } else {
          return FinarkeinDataResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return FinarkeinDataResponse(
        statusCode: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Finarkein Data Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'Finarkein_Data',
      );
      return FinarkeinDataResponse(
        statusCode: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
