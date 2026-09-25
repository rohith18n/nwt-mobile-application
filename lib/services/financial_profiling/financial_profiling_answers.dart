import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/financial_profiling/types/financial_profiling_question_response.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FinancialProfilingAnswersService {
  /// Fetches financial profiling answers from the API
  ///
  /// Returns a [FinancialProfilingQuestionResponse] object containing the questions with user answers
  /// The [onLoading] callback is used to update the loading state in the UI
  Future<FinancialProfilingQuestionResponse> getFinancialProfilingAnswers({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FINANCIAL_PROFILING_ANSWER;

      AppLogger.info(
        'Get Financial Profiling Answers Request URL: $url',
        tag: 'FinancialProfilingAnswersService',
      );

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Financial Profiling Answers Response: ${responseData.toString()}',
          tag: 'FinancialProfilingAnswersService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final financialProfilingAnswersResponse =
              FinancialProfilingQuestionResponse.fromJson(responseData);

          onLoading(false);
          return financialProfilingAnswersResponse;
        } else {
          AppLogger.warning(
            'Get Financial Profiling Answers Failed - Status: ${response.statusCode}, Message: ${responseData['message']}',
            tag: 'FinancialProfilingAnswersService',
          );

          onLoading(false);
          return FinancialProfilingQuestionResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to fetch financial profiling answers',
            data: [],
          );
        }
      } else {
        AppLogger.error(
          'Get Financial Profiling Answers - No response from server',
          tag: 'FinancialProfilingAnswersService',
        );

        onLoading(false);
        return FinancialProfilingQuestionResponse(
          statusCode: 500,
          message: 'No response from server',
          data: [],
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Financial Profiling Answers Error',
        error: e,
        tag: 'FinancialProfilingAnswersService',
        stackTrace: stackTrace,
      );

      onLoading(false);
      return FinancialProfilingQuestionResponse(
        statusCode: 500,
        message: 'Something went wrong: ${e.toString()}',
        data: [],
      );
    }
  }

  /// Fetches financial profiling answers by specific category
  ///
  /// [category] - The category to filter questions by (e.g., 'risk', 'investment', etc.)
  /// Returns a [FinancialProfilingQuestionResponse] object with filtered questions
  Future<FinancialProfilingQuestionResponse>
  getFinancialProfilingAnswersByCategory({
    required String category,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url =
          '${ApiURLs.GET_FINANCIAL_PROFILING_ANSWER}?category=$category';

      AppLogger.info(
        'Get Financial Profiling Answers by Category Request URL: $url',
        tag: 'FinancialProfilingAnswersService',
      );

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Financial Profiling Answers by Category Response: ${responseData.toString()}',
          tag: 'FinancialProfilingAnswersService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final financialProfilingAnswersResponse =
              FinancialProfilingQuestionResponse.fromJson(responseData);

          onLoading(false);
          return financialProfilingAnswersResponse;
        } else {
          AppLogger.warning(
            'Get Financial Profiling Answers by Category Failed - Status: ${response.statusCode}, Message: ${responseData['message']}',
            tag: 'FinancialProfilingAnswersService',
          );

          onLoading(false);
          return FinancialProfilingQuestionResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to fetch financial profiling answers for category: $category',
            data: [],
          );
        }
      } else {
        AppLogger.error(
          'Get Financial Profiling Answers by Category - No response from server',
          tag: 'FinancialProfilingAnswersService',
        );

        onLoading(false);
        return FinancialProfilingQuestionResponse(
          statusCode: 500,
          message: 'No response from server',
          data: [],
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Financial Profiling Answers by Category Error',
        error: e,
        tag: 'FinancialProfilingAnswersService',
        stackTrace: stackTrace,
      );

      onLoading(false);
      return FinancialProfilingQuestionResponse(
        statusCode: 500,
        message: 'Something went wrong: ${e.toString()}',
        data: [],
      );
    }
  }

  /// Fetches a specific financial profiling question with answer by ID
  ///
  /// [questionId] - The ID of the question to fetch
  /// Returns a [FinancialProfilingQuestionResponse] object with single question
  Future<FinancialProfilingQuestionResponse> getFinancialProfilingAnswerById({
    required int questionId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = '${ApiURLs.GET_FINANCIAL_PROFILING_ANSWER}/$questionId';

      AppLogger.info(
        'Get Financial Profiling Answer by ID Request URL: $url',
        tag: 'FinancialProfilingAnswersService',
      );

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Financial Profiling Answer by ID Response: ${responseData.toString()}',
          tag: 'FinancialProfilingAnswersService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final financialProfilingAnswersResponse =
              FinancialProfilingQuestionResponse.fromJson(responseData);

          onLoading(false);
          return financialProfilingAnswersResponse;
        } else {
          AppLogger.warning(
            'Get Financial Profiling Answer by ID Failed - Status: ${response.statusCode}, Message: ${responseData['message']}',
            tag: 'FinancialProfilingAnswersService',
          );

          onLoading(false);
          return FinancialProfilingQuestionResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to fetch financial profiling answer for question ID: $questionId',
            data: [],
          );
        }
      } else {
        AppLogger.error(
          'Get Financial Profiling Answer by ID - No response from server',
          tag: 'FinancialProfilingAnswersService',
        );

        onLoading(false);
        return FinancialProfilingQuestionResponse(
          statusCode: 500,
          message: 'No response from server',
          data: [],
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Financial Profiling Answer by ID Error',
        error: e,
        tag: 'FinancialProfilingAnswersService',
        stackTrace: stackTrace,
      );

      onLoading(false);
      return FinancialProfilingQuestionResponse(
        statusCode: 500,
        message: 'Something went wrong: ${e.toString()}',
        data: [],
      );
    }
  }
}
