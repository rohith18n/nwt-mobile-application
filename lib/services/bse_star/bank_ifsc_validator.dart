import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BankIfscValidatorService {
  static const String _tag = 'BankIfscValidatorService';

  static Future<IfscValidationResponse?> validateIfsc(String ifsc) async {
    try {
      AppLogger.info('Validating IFSC: $ifsc', tag: _tag);

      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final url = '${ApiURLs.GET_IFSC_DETAILS}/$ifsc';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'IFSC validation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'IFSC validation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return IfscValidationResponse.fromJson(jsonData);
      } else {
        AppLogger.error(
          'Failed to validate IFSC: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return IfscValidationResponse.fromJson(jsonData);
        } catch (_) {
          return IfscValidationResponse(
            statusCode: response.statusCode,
            message: 'Failed to validate IFSC',
            data: null,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in validateIfsc: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

class IfscValidationResponse {
  final int? statusCode;
  final String? message;
  final dynamic data;

  IfscValidationResponse({this.statusCode, this.message, this.data});

  factory IfscValidationResponse.fromJson(Map<String, dynamic> json) {
    return IfscValidationResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data,
    };
  }
}

