import 'package:nwt_app/utils/bse_error_translator.dart';

class BseSubmissionResponse {
  final String? message;
  final SubmissionData? data;

  BseSubmissionResponse({this.message, this.data});

  factory BseSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return BseSubmissionResponse(
      message: json['message'],
      data: json['data'] != null ? SubmissionData.fromJson(json['data']) : null,
    );
  }
}

class SubmissionData {
  final OnboardingData? onboarding;
  final BseResponse? bseResponse;

  SubmissionData({this.onboarding, this.bseResponse});

  factory SubmissionData.fromJson(Map<String, dynamic> json) {
    return SubmissionData(
      onboarding:
          json['onboarding'] != null
              ? OnboardingData.fromJson(json['onboarding'])
              : null,
      bseResponse:
          json['bse_response'] != null
              ? BseResponse.fromJson(json['bse_response'])
              : null,
    );
  }
}

class OnboardingData {
  final String? id;
  final String? userId;
  final String? status;
  final String? formattedStatus;

  OnboardingData({this.id, this.userId, this.status, this.formattedStatus});

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      formattedStatus: json['status'], // Or format if needed
    );
  }
}

class BseResponse {
  final String? status;
  final BseResponseData? data;
  final List<BseMessage>? messages;

  BseResponse({this.status, this.data, this.messages});

  factory BseResponse.fromJson(Map<String, dynamic> json) {
    return BseResponse(
      status: json['status'],
      data:
          json['data'] != null ? BseResponseData.fromJson(json['data']) : null,
      messages:
          json['messages'] != null
              ? (json['messages'] as List)
                  .map((e) => BseMessage.fromJson(e))
                  .toList()
              : null,
    );
  }
}

class BseMessage {
  final int? msgid;
  final String? errcode;
  final String? field;
  final List<String>? vals;

  BseMessage({this.msgid, this.errcode, this.field, this.vals});

  factory BseMessage.fromJson(Map<String, dynamic> json) {
    return BseMessage(
      msgid: json['msgid'],
      errcode: json['errcode'],
      field: json['field'],
      vals:
          json['vals'] != null
              ? (json['vals'] as List).map((e) => e.toString()).toList()
              : null,
    );
  }

  String get formattedMessage {
    if (field != null && vals != null && vals!.isNotEmpty) {
      return BseErrorTranslator.getFriendlyErrorMessage(
        vals!.last,
        field: field,
      );
    } else if (vals != null && vals!.isNotEmpty) {
      return BseErrorTranslator.getFriendlyErrorMessage(vals!.last);
    } else {
      return BseErrorTranslator.getFriendlyErrorMessage(
        errcode ?? 'An unexpected error occurred',
        field: field,
      );
    }
  }

  String get actionSuggestion {
    if (field != null && vals != null && vals!.isNotEmpty) {
      return BseErrorTranslator.getActionSuggestion(vals!.last, field: field);
    } else if (vals != null && vals!.isNotEmpty) {
      return BseErrorTranslator.getActionSuggestion(vals!.last);
    } else {
      return BseErrorTranslator.getActionSuggestion(
        errcode ?? '',
        field: field,
      );
    }
  }
}

class BseResponseData {
  final String? clientCode;
  final String? memberCode;
  final String? status;

  BseResponseData({this.clientCode, this.memberCode, this.status});

  factory BseResponseData.fromJson(Map<String, dynamic> json) {
    return BseResponseData(
      clientCode: json['client_code'],
      memberCode: json['member_code'],
      status: json['status'],
    );
  }
}
