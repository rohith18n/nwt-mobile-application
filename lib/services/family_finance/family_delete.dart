import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Response model for the family delete operation
class DeleteFamilyResponse {
  final int statusCode;
  final String message;

  DeleteFamilyResponse({required this.statusCode, required this.message});

  factory DeleteFamilyResponse.fromJson(Map<String, dynamic> json) {
    return DeleteFamilyResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  factory DeleteFamilyResponse.error(String errorMessage) {
    return DeleteFamilyResponse(statusCode: 500, message: errorMessage);
  }
}

/// Service to handle family deletion
class FamilyDeleteService {
  /// Deletes a family using the head member's user GUID and family ID
  ///
  /// [headMemberUserGuid] - The user GUID of the head member/creator
  /// [familyId] - The ID of the family to delete
  /// [onLoading] - Callback to handle loading state
  Future<DeleteFamilyResponse> deleteFamily({
    required String headMemberUserGuid,
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Construct the URL with path parameters
      final url = "${ApiURLs.DELETE_FAMILY}/$headMemberUserGuid/$familyId";

      AppLogger.info(
        'Delete Family Request: URL=$url',
        tag: 'FamilyDeleteService',
      );

      final response = await NetworkAPIHelper().delete(url);

      if (response != null) {
        AppLogger.info(
          'Delete Family Response: ${response.body}',
          tag: 'FamilyDeleteService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          return DeleteFamilyResponse.fromJson(jsonResponse);
        } else {
          AppLogger.error(
            'Delete Family Error: Status=${response.statusCode}, Body=${response.body}',
            tag: 'FamilyDeleteService',
          );
          return DeleteFamilyResponse(
            statusCode: response.statusCode,
            message: 'Failed to delete family. Please try again.',
          );
        }
      } else {
        AppLogger.error(
          'Delete Family Error: Null response from server',
          tag: 'FamilyDeleteService',
        );
        return DeleteFamilyResponse(
          statusCode: 400,
          message:
              'Failed to connect to server. Please check your internet connection.',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Delete Family Exception: $e',
        tag: 'FamilyDeleteService',
      );
      return DeleteFamilyResponse.error('An error occurred: $e');
    } finally {
      onLoading(false);
    }
  }
}
