import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/financial_profiling/types/financial_profiling.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FinancialProfilingService {
  /// Fetches financial profiling questions from the API
  /// 
  /// Returns a [FinanceProfilingResponse] object containing the questions and options
  /// The [onLoading] callback is used to update the loading state in the UI
  Future<FinanceProfilingResponse> getFinancialProfilingQuestions({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FINANCIAL_PROFILING_QUESTIONS;

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Financial Profiling Questions Response: ${responseData.toString()}',
          tag: 'FinancialProfilingService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final financialProfilingResponse =
              FinanceProfilingResponse.fromJson(responseData);

          onLoading(false);
          return financialProfilingResponse;
        } else {
          onLoading(false);
          return FinanceProfilingResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: [],
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Financial Profiling Questions Error',
        error: e,
        tag: 'FinancialProfilingService',
        stackTrace: stackTrace,
      );
    }
    
    onLoading(false);
    return FinanceProfilingResponse(
      statusCode: 500,
      message: 'Something went wrong',
      data: [],
    );
  }

  /// Submits user's financial profiling answers to the API
  /// 
  /// This method can be implemented later when needed
  Future<bool> submitFinancialProfilingAnswers({
    required Map<String, dynamic> answers,
    required Function(bool isLoading) onLoading,
  }) async {
    // TODO: Implement submission of financial profiling answers
    return true;
  }
}