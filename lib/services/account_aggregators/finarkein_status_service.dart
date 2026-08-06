import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FinarkeinStatusService {
  Future<FipStatusResponse> getFinarkeinStatus({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_FINARKEIN_STATUS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Finarkein Status Response: ${responseData.toString()}',
          tag: 'Finarkein_Status',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return FipStatusResponse.fromJson(responseData);
        } else {
          return FipStatusResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            FIPStatusData: null,
            can_fetch_mfc: false,
          );
        }
      }
      return FipStatusResponse(
        statusCode: 0,
        message: 'Unknown error',
        FIPStatusData: null,
        can_fetch_mfc: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Finarkein Status Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'Finarkein_Status',
      );
      return FipStatusResponse(
        statusCode: 0,
        message: 'An unexpected error occurred',
        FIPStatusData: null,
        can_fetch_mfc: false,
      );
    } finally {
      onLoading(false);
    }
  }
}
