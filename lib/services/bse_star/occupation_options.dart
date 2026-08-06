import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseOccupationOptionsService {
  static const String _tag = 'BseOccupationOptionsService';
 
  static Future<List<Datum>?> getOccupationOptionsList() async {
    try {
      AppLogger.info('Fetching BSE occupation options', tag: _tag);
 
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {  
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }
 
      final response = await http.get(
        Uri.parse(ApiURLs.GET_BSE_OCCUPATION_OPTIONS),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
 
      AppLogger.info(
        'BSE occupation options API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE occupation options API body: ${response.body}',
        tag: _tag,
      );
 
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        AppLogger.info('BSE occupation options decoded JSON: $jsonData', tag: _tag);
        final optionsResponse = OccupationOptionsResponse.fromJson(jsonData);
        AppLogger.info('BSE occupation options parsed: ${optionsResponse.toJson()}', tag: _tag);

        if (optionsResponse.data.isNotEmpty) {
          AppLogger.info(
            'Retrieved ${optionsResponse.data.length} occupation options',
            tag: _tag,
          );
          return optionsResponse.data;
        }
      } else {
        AppLogger.error(
          'Failed to fetch occupation options: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
 
      return _getHardcodedOccupations();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getOccupationOptionsList: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return _getHardcodedOccupations();
    }
  }

  /// Hardcoded occupation list as fallback when API fails
  static List<Datum> _getHardcodedOccupations() {
    return [
      Datum(id: '01', name: 'Business'),
      Datum(id: '02', name: 'Service — Private'),
      Datum(id: '03', name: 'Service — Government'),
      Datum(id: '04', name: 'Professional'),
      Datum(id: '05', name: 'Agriculturist'),
      Datum(id: '06', name: 'Retired'),
      Datum(id: '07', name: 'Housewife'),
      Datum(id: '08', name: 'Student'),
      Datum(id: '09', name: 'Others'),
    ];
  }
}

