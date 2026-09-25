import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/invitation.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class InvitationService {
  Future<InvitationResponse> getInvitationDetails({
    required String invitationId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_INVITATION_DETAILS(invitationId),
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Invitation Details Response: ${responseData.toString()}',
          tag: 'InvitationService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final invitationResponse = InvitationResponse.fromJson(responseData);
          return invitationResponse;
        } else {
          return InvitationResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Fetch Invitation Details Error',
        error: e,
        tag: 'InvitationService',
        stackTrace: subTrace,
      );
      return InvitationResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
    return InvitationResponse(
      statusCode: 0,
      message: 'Unknown error',
      data: null,
    );
  }
}
