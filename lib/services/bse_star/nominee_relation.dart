import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/nominee_relation.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseNomineeRelationService {
  static const String _tag = 'BseNomineeRelationService';

  /// Fetches nominee relations and returns just the data list
  static Future<List<Datum>?> getNomineeRelationsList() async {
    try {
      AppLogger.info('Fetching BSE nominee relations', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiURLs.GET_BSE_NOMINEE_RELATION),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE nominee relations API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE nominee relations API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final nomineeResponse = BseNomineeRelationResponse.fromJson(jsonData);
        
        if (nomineeResponse.data != null) {
          AppLogger.info(
            'Retrieved ${nomineeResponse.data!.length} nominee relations',
            tag: _tag,
          );
          return nomineeResponse.data;
        }
      } else {
        AppLogger.error(
          'Failed to fetch nominee relations: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getNomineeRelationsList: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}