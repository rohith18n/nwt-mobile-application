import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class EditMemberResponse {
  final int statusCode;
  final String message;

  EditMemberResponse({required this.statusCode, required this.message});

  factory EditMemberResponse.fromJson(Map<String, dynamic> json) {
    return EditMemberResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? 'Unknown error',
    );
  }
}

class FamilyMemberEditService {
  Future<EditMemberResponse> editFamilyMember({
    required String userGuid,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String relation,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Create the request body exactly as specified by the API
      final requestBody = {
        "userguid": userGuid,
        "firstname": firstName,
        "lastname": lastName,
        "phonenumber": phoneNumber,
        "relation": relation,
      };

      AppLogger.info(
        'Edit Family Member Request: ${jsonEncode(requestBody)}',
        tag: 'FamilyMemberEditService',
      );

      final response = await NetworkAPIHelper().patch(
        ApiURLs.EDIT_FAMILY_MEMBER,
        requestBody,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          AppLogger.info(
            'Edit Family Member Response: ${responseData.toString()}',
            tag: 'FamilyMemberEditService',
          );
          return EditMemberResponse.fromJson(responseData);
        } else {
          AppLogger.error(
            'Edit Family Member Error: Status ${response.statusCode}, Response: ${response.body}',
            tag: 'FamilyMemberEditService',
          );
          return EditMemberResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Server error occurred. Please try again.',
          );
        }
      } else {
        AppLogger.error(
          'Edit Family Member Error: Null response from server',
          tag: 'FamilyMemberEditService',
        );
        return EditMemberResponse(
          statusCode: 400,
          message:
              'Failed to connect to server. Please check your internet connection.',
        );
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Edit Family Member Error',
        error: e,
        tag: 'FamilyMemberEditService',
        stackTrace: subTrace,
      );
      return EditMemberResponse(statusCode: 0, message: e.toString());
    } finally {
      onLoading(false);
    }
  }
}
