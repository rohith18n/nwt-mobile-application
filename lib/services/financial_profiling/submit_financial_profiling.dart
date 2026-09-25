import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Service class for submitting financial profiling answers to the API
class SubmitFinancialProfilingService {
  /// Submits the user's financial profiling answers to the API
  /// 
  /// Takes a list of answers in the format:
  /// ```
  /// {
  ///   "answers": [
  ///     {
  ///       "questionid": 1,
  ///       "answertext": "Wealth Creation",
  ///       "selectedoptionids": [9]
  ///     },
  ///     ...
  ///   ]
  /// }
  /// ```
  /// 
  /// Returns a Future<bool> indicating success or failure
  /// The [onLoading] callback is used to update the loading state in the UI
  Future<Map<String, dynamic>> submitFinancialProfiling({
    required List<Map<String, dynamic>> answers,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.SUBMIT_FINANCIAL_PROFILING;
      
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "answers": answers,
      };
      
      AppLogger.info(
        'Submitting Financial Profiling: ${jsonEncode(requestBody)}',
        tag: 'SubmitFinancialProfilingService',
      );

      final response = await NetworkAPIHelper().post(
        url,
        jsonEncode(requestBody),
      );
      
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Submit Financial Profiling Response: ${responseData.toString()}',
          tag: 'SubmitFinancialProfilingService',
        );

        onLoading(false);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'statusCode': response.statusCode,
            'message': responseData['message'] ?? 'Financial profile submitted successfully',
            'data': responseData['data'] ?? {},
          };
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': responseData['message'] ?? 'Failed to submit financial profile',
            'data': responseData['data'] ?? {},
          };
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Submit Financial Profiling Error',
        error: e,
        tag: 'SubmitFinancialProfilingService',
        stackTrace: stackTrace,
      );
    }
    
    onLoading(false);
    return {
      'success': false,
      'statusCode': 500,
      'message': 'Something went wrong',
      'data': {},
    };
  }
  
  /// Helper method to format answers for API submission
  /// 
  /// Takes a map of question IDs to selected answers and formats them for the API
  /// For multiple choice questions, selectedoptionids should be a list of option IDs
  /// For single choice questions, selectedoptionids should be a list with a single option ID
  /// For range questions, only answertext is used
  static List<Map<String, dynamic>> formatAnswersForSubmission({
    required Map<int, dynamic> selectedAnswers,
    required Map<int, String> answerTexts,
    required Map<int, List<int>> selectedOptionIds,
  }) {
    final List<Map<String, dynamic>> formattedAnswers = [];
    
    selectedAnswers.forEach((questionId, value) {
      final Map<String, dynamic> answer = {
        'questionid': questionId,
        'answertext': answerTexts[questionId] ?? '',
      };
      
      // Add selectedoptionids if available
      if (selectedOptionIds.containsKey(questionId)) {
        answer['selectedoptionids'] = selectedOptionIds[questionId];
      }
      
      formattedAnswers.add(answer);
    });
    
    return formattedAnswers;
  }
}