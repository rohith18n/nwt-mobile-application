import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class LatestIsinUpdatedDateResponse {
  final int statusCode;
  final bool success;
  final String message;
  final LatestIsinUpdatedDateData? data;

  LatestIsinUpdatedDateResponse({
    required this.statusCode,
    required this.success,
    required this.message,
    this.data,
  });

  factory LatestIsinUpdatedDateResponse.fromJson(Map<String, dynamic> json) {
    return LatestIsinUpdatedDateResponse(
      statusCode: json['statusCode'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? LatestIsinUpdatedDateData.fromJson(json['data']) 
          : null,
    );
  }
}

class LatestIsinUpdatedDateData {
  final String date;

  LatestIsinUpdatedDateData({
    required this.date,
  });

  factory LatestIsinUpdatedDateData.fromJson(Map<String, dynamic> json) {
    return LatestIsinUpdatedDateData(
      date: json['date'] ?? '',
    );
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      AppLogger.error('Error parsing ISIN updated date', error: e, tag: 'IsinService');
      return null;
    }
  }
}

class IsinService {
  Future<LatestIsinUpdatedDateResponse?> getLatestIsinUpdatedDate({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_LATEST_ISIN_UPDATED_DATE,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Latest ISIN updated date response: $responseData',
          tag: 'IsinService',
        );

        final result = LatestIsinUpdatedDateResponse.fromJson(responseData);
        onLoading(false);
        return result;
      } else {
        AppLogger.error(
          'Failed to get latest ISIN updated date - null response',
          tag: 'IsinService',
        );
        onLoading(false);
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Error getting latest ISIN updated date',
        error: e,
        tag: 'IsinService',
      );
      onLoading(false);
      return null;
    }
  }
}
