import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/tin_details.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseTinDetailsService {
  static const String _tag = 'BseTinDetailsService';
 
  static Future<TinResponseData?> getTinDetails({required String country}) async {
    try {
      AppLogger.info('Fetching TIN details for country: $country', tag: _tag);
 
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {  
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Build URL with country parameter
      final url = '${ApiURLs.GET_TIN_DETAILS}?country=${Uri.encodeComponent(country)}';
 
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
 
      AppLogger.info(
        'TIN details API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'TIN details API body: ${response.body}',
        tag: _tag,
      );
 
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        AppLogger.info('TIN details decoded JSON: $jsonData', tag: _tag);
        final tinResponse = TinResponseData.fromJson(jsonData);
        AppLogger.info('TIN details parsed: ${tinResponse.toJson()}', tag: _tag);

        AppLogger.info(
          'Retrieved TIN details for ${tinResponse.data.country}',
          tag: _tag,
        );
        return tinResponse;
      } else {
        AppLogger.error(
          'Failed to fetch TIN details: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
 
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getTinDetails: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}