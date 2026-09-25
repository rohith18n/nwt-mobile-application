import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MFCentralTriggerResponse {
  final bool success;
  final String? message;
  final String? redirectUrl;
  final String? reqId;
  final String? clientRefNo;

  MFCentralTriggerResponse({
    required this.success,
    this.message,
    this.redirectUrl,
    this.reqId,
    this.clientRefNo,
  });

  factory MFCentralTriggerResponse.fromJson(Map<String, dynamic> json) {
    return MFCentralTriggerResponse(
      success: true,
      redirectUrl: json['redirect_url'] as String?,
      reqId: json['req_id']?.toString(),
      clientRefNo: json['client_ref_no']?.toString(),
    );
  }
}

class MFCentralService {
  /// Trigger MF Central connection
  /// Calls POST /api/v1/mfcentral/trigger/
  Future<MFCentralTriggerResponse> triggerConnect({
    String? pan,
    String? mobile,
    String? email,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final requestBody = <String, dynamic>{};
      
      if (pan != null) requestBody['pan'] = pan;
      if (mobile != null) requestBody['mobile'] = mobile;
      if (email != null) requestBody['email'] = email;
      if (fromDate != null) requestBody['fromDate'] = fromDate;
      if (toDate != null) requestBody['toDate'] = toDate;

      AppLogger.info(
        '🚀 MF Central Trigger - Request Body: $requestBody',
        tag: 'MF_Central',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.MF_CENTRAL_TRIGGER,
        requestBody,
      );

      if (response == null) {
        AppLogger.error(
          '❌ MF Central Trigger - Response is null',
          tag: 'MF_Central',
        );
        return MFCentralTriggerResponse(
          success: false,
          message: 'Failed to connect to MF Central',
        );
      }

      AppLogger.info(
        '📥 MF Central Trigger - Status Code: ${response.statusCode}',
        tag: 'MF_Central',
      );
      AppLogger.info(
        '📥 MF Central Trigger - Response Headers: ${response.headers}',
        tag: 'MF_Central',
      );
      AppLogger.info(
        '📥 MF Central Trigger - Response Body: ${response.body}',
        tag: 'MF_Central',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info(
          '✅ MF Central Trigger - Success! Redirect URL: ${responseData['redirect_url']}',
          tag: 'MF_Central',
        );
        AppLogger.info(
          '✅ MF Central Trigger - Req ID: ${responseData['req_id']}',
          tag: 'MF_Central',
        );
        return MFCentralTriggerResponse.fromJson(responseData);
      } else {
        // Extract error message from response
        String errorMessage = 'Failed to trigger MF Central';
        
        try {
          // Check for nested detail.errors structure (MF Central specific format)
          if (responseData['detail'] != null && responseData['detail'] is Map) {
            final detail = responseData['detail'] as Map<String, dynamic>;
            if (detail['errors'] != null && detail['errors'] is List) {
              final errors = detail['errors'] as List;
              if (errors.isNotEmpty) {
                final firstError = errors[0];
                if (firstError is Map && firstError['message'] != null) {
                  errorMessage = firstError['message'].toString();
                }
              }
            }
          } 
          // Check for direct errors array
          else if (responseData['errors'] != null && responseData['errors'] is List) {
            final errors = responseData['errors'] as List;
            if (errors.isNotEmpty) {
              final firstError = errors[0];
              if (firstError is Map && firstError['message'] != null) {
                errorMessage = firstError['message'].toString();
              }
            }
          } 
          // Check for error field
          else if (responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          }
          // Check for message field
          else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } 
          // Check for detail field (string)
          else if (responseData['detail'] != null && responseData['detail'] is String) {
            errorMessage = responseData['detail'].toString();
          }
        } catch (e) {
          AppLogger.error(
            '❌ Error parsing MF Central error response',
            error: e,
            tag: 'MF_Central',
          );
        }
        
        AppLogger.error(
          '❌ MF Central Trigger - Failed with status ${response.statusCode}: $errorMessage',
          tag: 'MF_Central',
        );
        
        return MFCentralTriggerResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      AppLogger.error(
        '❌ MF Central Trigger - Exception occurred',
        error: e,
        tag: 'MF_Central',
      );
      return MFCentralTriggerResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Sync MF Central portfolio with QR code
  /// Calls POST /api/v1/mfcentral/sync/
  Future<MFCentralSyncResponse> syncPortfolio({
    required String reqId,
    required String qrBase64,
    String? clientRefNo,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'req_id': reqId,
        'qr_base64': qrBase64,
      };
      
      if (clientRefNo != null) {
        requestBody['client_ref_no'] = clientRefNo;
      }

      AppLogger.info(
        '🚀 MF Central Sync - Request: req_id=$reqId, qr_base64_length=${qrBase64.length}, client_ref_no=$clientRefNo',
        tag: 'MF_Central',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.MF_CENTRAL_SYNC,
        requestBody,
      );

      if (response == null) {
        AppLogger.error(
          '❌ MF Central Sync - Response is null',
          tag: 'MF_Central',
        );
        return MFCentralSyncResponse(
          success: false,
          message: 'Failed to sync portfolio',
        );
      }

      AppLogger.info(
        '📥 MF Central Sync - Status Code: ${response.statusCode}',
        tag: 'MF_Central',
      );
      AppLogger.info(
        '📥 MF Central Sync - Response Body: ${response.body}',
        tag: 'MF_Central',
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info(
          '✅ MF Central Sync - Success!',
          tag: 'MF_Central',
        );
        return MFCentralSyncResponse.fromJson(responseData);
      } else {
        // Extract error message
        String errorMessage = 'Failed to sync portfolio';
        
        try {
          if (responseData['detail'] != null && responseData['detail'] is Map) {
            final detail = responseData['detail'] as Map<String, dynamic>;
            if (detail['errors'] != null && detail['errors'] is List) {
              final errors = detail['errors'] as List;
              if (errors.isNotEmpty) {
                final firstError = errors[0];
                if (firstError is Map && firstError['message'] != null) {
                  errorMessage = firstError['message'].toString();
                }
              }
            }
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } catch (e) {
          AppLogger.error(
            '❌ Error parsing sync error response',
            error: e,
            tag: 'MF_Central',
          );
        }
        
        AppLogger.error(
          '❌ MF Central Sync - Failed with status ${response.statusCode}: $errorMessage',
          tag: 'MF_Central',
        );
        
        return MFCentralSyncResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      AppLogger.error(
        '❌ MF Central Sync - Exception occurred',
        error: e,
        tag: 'MF_Central',
      );
      return MFCentralSyncResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }
}

class MFCentralSyncResponse {
  final bool success;
  final String? message;
  final String? status;
  final String? portfolioId;

  MFCentralSyncResponse({
    required this.success,
    this.message,
    this.status,
    this.portfolioId,
  });

  factory MFCentralSyncResponse.fromJson(Map<String, dynamic> json) {
    return MFCentralSyncResponse(
      success: true,
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      portfolioId: json['portfolio_id']?.toString(),
    );
  }
}
