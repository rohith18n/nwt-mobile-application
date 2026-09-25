import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_submission.dart'; // Import created type
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';

class SubmissionService {
  static const String _tag = 'SubmissionService';

  static Future<BseSubmissionResponse?> submitOnboarding() async {
    try {
      AppLogger.info('Submitting onboarding to BSE', tag: _tag);

      // Get onboarding ID
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found', tag: _tag);
        return null; // Or throw custom error
      }

      // Get Token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final url = ApiURLs.BSE_Star_SUBMIT(onboardingId);
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'Submission API status: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info('Submission API body: ${response.body}', tag: _tag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return BseSubmissionResponse.fromJson(jsonResponse);
      } else {
        AppLogger.error('Submission failed: ${response.statusCode}', tag: _tag);
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          return BseSubmissionResponse.fromJson(jsonResponse);
        } catch (e) {
          AppLogger.error('Failed to parse error response: $e', tag: _tag);
          return null;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in submission: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
