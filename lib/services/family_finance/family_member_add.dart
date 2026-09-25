import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/family_member_add.dart';
import 'package:nwt_app/services/deep_linking/branch_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyMemberAddService {
  Future<FamilyMemberAddResponse> inviteFamilyMember({
    required String familyLastName,
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String relation,
    required Function(bool isLoading) onLoading,
    bool shouldCreateShareLink = true, // New parameter to control link creation
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.CREATE_FAMILY, {
        "familyLastName": familyLastName,
        "firstName": firstName,
        "lastName": lastName,
        "mobileNumber": mobileNumber,
        "relation": relation,
      });

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Invite Family Member Response: ${responseData.toString()}',
          tag: 'FamilyMemberAddService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyMemberAddResponse = FamilyMemberAddResponse.fromJson(
            responseData,
          );
          
          // Create and share Branch link if requested and response is successful
          if (shouldCreateShareLink && familyMemberAddResponse.data != null) {
            try {
              // Get the inviter's name from the response data
              final String inviterName = 
                  "${familyMemberAddResponse.data!.creatorfirstname} ${familyMemberAddResponse.data!.creatorlastname}";

              // Use BranchService to create and share the link
              await BranchService.to.createLink(
                route: '/invite',
                title: 'Family Finance Invitation',
                description:
                    'Join $inviterName on Pivot Money to manage family finances together',
                feature: 'family_invitation',
                metadata: {
                  'invitationId': familyMemberAddResponse.data?.invitationid ?? '',
                  'familyId': familyMemberAddResponse.data?.familyid ?? '',
                  'inviterName': inviterName,
                  'inviteeName': firstName,
                },
              );
              
              AppLogger.info(
                'Branch link created and shared successfully for $firstName',
                tag: 'FamilyMemberAddService',
              );
            } catch (e) {
              AppLogger.error(
                'Error creating Branch link',
                error: e,
                tag: 'FamilyMemberAddService',
              );
              // Don't fail the entire operation if link creation fails
            }
          }
          
          return familyMemberAddResponse;
        } else {
          return FamilyMemberAddResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Invite Family Member Error',
        error: e,
        tag: 'FamilyMemberAddService',
        stackTrace: subTrace,
      );
      return FamilyMemberAddResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
    return FamilyMemberAddResponse(
      statusCode: 0,
      message: 'Unknown error',
      data: null,
    );
  }
}
