import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/family_member_summary.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyMemberSummaryService {
  Future<FamilyMemberSummaryResponse> getFamilyMembers({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_MEMBER;

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Members Response: ${responseData.toString()}',
          tag: 'FamilyMemberSummaryService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyMemberSummaryResponse =
              FamilyMemberSummaryResponse.fromJson(responseData);

          return familyMemberSummaryResponse;
        } else {
          // AppLogger.info(
          //   'Get Family Members $response',
          //   tag: 'FamilyMemberSummaryService',
          // );
          return FamilyMemberSummaryResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Get Family Members Error',
        error: e,
        tag: 'FamilyMemberSummaryService',
        stackTrace: subTrace,
      );
      return FamilyMemberSummaryResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
    return FamilyMemberSummaryResponse(
      statusCode: 0,
      message: 'Unknown error',
      data: null,
    );
  }
}
