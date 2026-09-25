import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/family_management_summary.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyHeadMemberSummaryService {
  Future<FamilyManagementSummaryResponse> getFamilyHeadMemberSummary({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_HEAD_MEMBER_SUMMARY;

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Head Member Summary Response: ${responseData.toString()}',
          tag: 'FamilyHeadMemberSummaryService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyManagementSummaryResponse =
              FamilyManagementSummaryResponse.fromJson(responseData);

          return familyManagementSummaryResponse;
        } else {
          return FamilyManagementSummaryResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Get Family Head Member Summary Error',
        error: e,
        tag: 'FamilyHeadMemberSummaryService',
        stackTrace: subTrace,
      );
      return FamilyManagementSummaryResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
    return FamilyManagementSummaryResponse(
      statusCode: 0,
      message: 'Unknown error',
      data: null,
    );
  }
}
