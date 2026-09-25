import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/invitation_response.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyInvitationService {
  /// Accept a family invitation
  ///
  /// [memberUserId] is the ID of the user accepting the invitation
  /// [familyId] is the ID of the family the user is being invited to
  /// [onLoading] is a callback to update the loading state
  Future<FamilyInvitationResponse> acceptFamilyInvitation({
    required String memberUserId,
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Use the API constant for the accept invitation endpoint
      String url = ApiURLs.ACCEPT_FAMILY_INVITATION(memberUserId, familyId);

      final response = await NetworkAPIHelper().post(url, {});
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Accept Family Invitation Response: ${responseData.toString()}',
          tag: 'FamilyInvitationService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return FamilyInvitationResponse.fromJson(responseData);
        } else {
          return FamilyInvitationResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
          );
        }
      } else {
        return FamilyInvitationResponse(
          statusCode: 0,
          message: 'No response received',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Accept Family Invitation Error',
        error: e,
        tag: 'FamilyInvitationService',
        stackTrace: stackTrace,
      );
      return FamilyInvitationResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }

  /// Reject a family invitation
  ///
  /// [memberUserId] is the ID of the user rejecting the invitation
  /// [familyId] is the ID of the family the user is rejecting
  /// [onLoading] is a callback to update the loading state
  Future<FamilyInvitationResponse> rejectFamilyInvitation({
    required String memberUserId,
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Use the API constant for the reject invitation endpoint
      String url = ApiURLs.REJECT_FAMILY_INVITATION(memberUserId, familyId);

      final response = await NetworkAPIHelper().post(url, {});
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Reject Family Invitation Response: ${responseData.toString()}',
          tag: 'FamilyInvitationService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return FamilyInvitationResponse.fromJson(responseData);
        } else {
          return FamilyInvitationResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
          );
        }
      } else {
        return FamilyInvitationResponse(
          statusCode: 0,
          message: 'No response received',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Reject Family Invitation Error',
        error: e,
        tag: 'FamilyInvitationService',
        stackTrace: stackTrace,
      );
      return FamilyInvitationResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
      );
    } finally {
      onLoading(false);
    }
  }
}
