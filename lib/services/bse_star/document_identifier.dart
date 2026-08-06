import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/document_identifier.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseDocumentIdentifierService {
  static const String _tag = 'BseDocumentIdentifierService';

  /// Fetches document identifiers and returns just the data list
  static Future<List<Datum>?> getDocumentIdentifiersList() async {
    try {
      AppLogger.info('Fetching BSE document identifiers', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiURLs.GET_BSE_DOCUMENT_IDENTIFIER),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE document identifiers API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE document identifiers API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final documentResponse = DocumentIdentifierTypeResponse.fromJson(jsonData);
        
        AppLogger.info(
          'Retrieved ${documentResponse.data.length} document identifiers',
          tag: _tag,
        );
        return documentResponse.data;
      } else {
        AppLogger.error(
          'Failed to fetch document identifiers: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getDocumentIdentifiersList: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Fetches the full document identifier response
  static Future<DocumentIdentifierTypeResponse?> getDocumentIdentifiersResponse() async {
    try {
      AppLogger.info('Fetching BSE document identifiers response', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiURLs.GET_BSE_DOCUMENT_IDENTIFIER),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE document identifiers API response: ${response.statusCode}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final documentResponse = DocumentIdentifierTypeResponse.fromJson(jsonData);
        
        AppLogger.info(
          'Retrieved document identifiers response with ${documentResponse.data.length} items',
          tag: _tag,
        );
        return documentResponse;
      } else {
        AppLogger.error(
          'Failed to fetch document identifiers: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getDocumentIdentifiersResponse: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
