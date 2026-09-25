import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/relation_options.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class RelationOptionService {
  Future<RelationOptionResponse> getRelationOptions({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_RELATION_OPTIONS;

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Relation Options Response: ${responseData.toString()}',
          tag: 'RelationOptionService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final relationOptionResponse = RelationOptionResponse.fromJson(
            responseData,
          );

          return relationOptionResponse;
        } else {
          return RelationOptionResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: [],
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Get Relation Options Error',
        error: e,
        tag: 'RelationOptionService',
        stackTrace: subTrace,
      );
      return RelationOptionResponse(
        statusCode: 0,
        message: e.toString(),
        data: [],
      );
    } finally {
      onLoading(false);
    }
    return RelationOptionResponse(
      statusCode: 0,
      message: 'Unknown error',
      data: [],
    );
  }
}
