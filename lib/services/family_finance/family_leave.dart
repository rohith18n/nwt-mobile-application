import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Response model for the family leave operation
class LeaveFamilyResponse {
  final int statusCode;
  final String message;

  LeaveFamilyResponse({required this.statusCode, required this.message});

  factory LeaveFamilyResponse.fromJson(Map<String, dynamic> json) {
    return LeaveFamilyResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  factory LeaveFamilyResponse.error(String errorMessage) {
    return LeaveFamilyResponse(statusCode: 500, message: errorMessage);
  }
}

/// Service to handle family leave functionality
class FamilyLeaveService {
  /// Allows a family member to leave the family
  ///
  /// [userGuid] - The user GUID of the member who wants to leave
  /// [familyId] - The ID of the family to leave
  /// [onLoading] - Callback to handle loading state
  Future<LeaveFamilyResponse> leaveFamily({
    required String userGuid,
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Construct the URL with path parameters
      final url = "${ApiURLs.LEAVE_FAMILY}/$userGuid/$familyId";

      AppLogger.info(
        'Leave Family Request: URL=$url',
        tag: 'FamilyLeaveService',
      );

      final response = await NetworkAPIHelper().post(url, {});

      if (response != null) {
        AppLogger.info(
          'Leave Family Response: ${response.body}',
          tag: 'FamilyLeaveService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          return LeaveFamilyResponse.fromJson(jsonResponse);
        } else {
          AppLogger.error(
            'Leave Family Error: Status=${response.statusCode}, Body=${response.body}',
            tag: 'FamilyLeaveService',
          );
          return LeaveFamilyResponse(
            statusCode: response.statusCode,
            message: 'Failed to leave family. Please try again.',
          );
        }
      } else {
        AppLogger.error(
          'Leave Family Error: Null response from server',
          tag: 'FamilyLeaveService',
        );
        return LeaveFamilyResponse(
          statusCode: 400,
          message:
              'Failed to connect to server. Please check your internet connection.',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Leave Family Exception: $e',
        tag: 'FamilyLeaveService',
      );
      return LeaveFamilyResponse.error('An error occurred: $e');
    } finally {
      onLoading(false);
    }
  }
}
