import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class UpdateFinancialProfilingResponse {
  final int statusCode;
  final String message;

  UpdateFinancialProfilingResponse({
    required this.statusCode,
    required this.message,
  });

  factory UpdateFinancialProfilingResponse.fromJson(Map<String, dynamic> json) {
    return UpdateFinancialProfilingResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'statusCode': statusCode, 'message': message};
  }

  @override
  String toString() {
    return 'UpdateFinancialProfilingResponse(statusCode: $statusCode, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateFinancialProfilingResponse &&
        other.statusCode == statusCode &&
        other.message == message;
  }

  @override
  int get hashCode => statusCode.hashCode ^ message.hashCode;
}

class FinancialProfilingAnswer {
  final int questionid;
  final String answertext;
  final List<int>? selectedoptionids;

  FinancialProfilingAnswer({
    required this.questionid,
    required this.answertext,
    this.selectedoptionids,
  });

  factory FinancialProfilingAnswer.fromJson(Map<String, dynamic> json) {
    return FinancialProfilingAnswer(
      questionid: json['questionid'] ?? 0,
      answertext: json['answertext'] ?? '',
      selectedoptionids:
          json['selectedoptionids'] != null
              ? List<int>.from(json['selectedoptionids'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'questionid': questionid,
      'answertext': answertext,
    };

    if (selectedoptionids != null && selectedoptionids!.isNotEmpty) {
      data['selectedoptionids'] = selectedoptionids;
    }

    return data;
  }

  @override
  String toString() {
    return 'FinancialProfilingAnswer(questionid: $questionid, answertext: $answertext, selectedoptionids: $selectedoptionids)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialProfilingAnswer &&
        other.questionid == questionid &&
        other.answertext == answertext &&
        other.selectedoptionids == selectedoptionids;
  }

  @override
  int get hashCode =>
      questionid.hashCode ^ answertext.hashCode ^ selectedoptionids.hashCode;
}

class UpdateFinancialProfilingService {
  static const String _tag = 'UpdateFinancialProfilingService';

  /// Updates financial profiling answers using PATCH method
  ///
  /// [answers] - List of financial profiling answers to update
  /// [onLoading] - Callback function to handle loading state
  ///
  /// Returns [UpdateFinancialProfilingResponse] with status and message
  Future<UpdateFinancialProfilingResponse> updateFinancialProfilingAnswers({
    required List<FinancialProfilingAnswer> answers,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);

    try {
      String url = ApiURLs.UPDATE_FINANCIAL_PROFILING_ANSWER;

      // Prepare request body
      final requestBody = {
        'answers': answers.map((answer) => answer.toJson()).toList(),
      };

      // Print request body for debugging
      print('=== UPDATE FINANCIAL PROFILING API REQUEST ===');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('===============================================');

      AppLogger.info(
        'Updating financial profiling answers - URL: $url',
        tag: _tag,
      );

      final response = await NetworkAPIHelper().patch(url, requestBody);

      if (response != null) {
        final responseData = jsonDecode(response.body);

        AppLogger.info(
          'Update financial profiling response received - Status: ${response.statusCode}',
          tag: _tag,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final updateResponse = UpdateFinancialProfilingResponse.fromJson(
            responseData,
          );
          onLoading(false);
          return updateResponse;
        } else {
          AppLogger.error(
            'Update financial profiling failed - Status: ${response.statusCode}',
            tag: _tag,
          );
          onLoading(false);
          return UpdateFinancialProfilingResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Failed to update financial profiling answers',
          );
        }
      } else {
        AppLogger.error(
          'Update financial profiling failed - No response received from server',
          tag: _tag,
        );
        onLoading(false);
        return UpdateFinancialProfilingResponse(
          statusCode: 500,
          message: 'No response received from server',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update financial profiling error',
        error: e,
        tag: _tag,
        stackTrace: stackTrace,
      );
      onLoading(false);
      return UpdateFinancialProfilingResponse(
        statusCode: 500,
        message: 'Something went wrong: ${e.toString()}',
      );
    }
  }
}
