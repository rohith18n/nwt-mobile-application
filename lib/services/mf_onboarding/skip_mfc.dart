import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class SkipMfcResponse {
  int statusCode;
  String message;
  Data? data;

  SkipMfcResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory SkipMfcResponse.fromJson(Map<String, dynamic> json) => SkipMfcResponse(
    statusCode: json["statusCode"],
    message: json["message"],
    data: json["data"] != null ? Data.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  bool skipmfc;

  Data({
    required this.skipmfc,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    skipmfc: json["skipmfc"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "skipmfc": skipmfc,
  };
}

class SkipMfcService {
  Future<SkipMfcResponse?> skipMfc({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().patch(
        ApiURLs.SKIP_MFC,
        {},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Skip MFC Response: ${responseData.toString()}',
          tag: 'SkipMfcService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return SkipMfcResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Skip MFC Error', error: e, tag: 'SkipMfcService');
      return null;
    } finally {
      onLoading(false);
    }
  }
}