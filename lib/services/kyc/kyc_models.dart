// Typed models for KYC API responses.
// Field names match backend DTOs (camelCase).

import 'dart:convert';

import 'package:nwt_app/services/kyc/kyc_kra_state.dart';

/// Picks the best display message from a response map. Checks detailedMessage, message, errorMessage, Message (case variants).
/// Also checks payload['error'] when it's a Map (e.g. gateway/Nest shapes). Returns trimmed, single-line, safe length; null if none found.
String? _extractDisplayMessage(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  const maxLength = 500;
  final candidates = <String?>[
    payload['detailedMessage'] as String?,
    payload['message'] as String?,
    payload['errorMessage'] as String?,
    payload['Message'] as String?,
    payload['error_description'] as String?,
    payload['error'] is String ? payload['error'] as String? : null,
  ];
  for (final c in candidates) {
    if (c == null || c.isEmpty) continue;
    final s = c.toString().trim();
    if (s.isEmpty) continue;
    final firstLine = s.split(RegExp(r'[\r\n]+')).first.trim();
    if (firstLine.isEmpty) continue;
    return firstLine.length > maxLength ? '${firstLine.substring(0, maxLength)}…' : firstLine;
  }
  final errorObj = payload['error'];
  if (errorObj is Map<String, dynamic>) {
    final fromError = _extractDisplayMessage(errorObj);
    if (fromError != null) return fromError;
  }
  return null;
}

/// Parses raw response body as JSON and returns a display message (e.g. for 401/unexpected error shapes).
/// Use when the normal result parsing did not produce an errorMessage.
/// Also uses short non-JSON body as message (e.g. plain "Unauthorized").
String? extractDisplayMessageFromResponseBody(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final msg = _extractDisplayMessage(decoded);
      if (msg != null && msg.isNotEmpty) return msg;
    }
  } catch (_) {}
  // Some APIs return plain text (e.g. "Unauthorized") for 401
  if (trimmed.length <= 200 && !trimmed.startsWith('<')) {
    final firstLine = trimmed.split(RegExp(r'[\r\n]+')).first.trim();
    if (firstLine.isNotEmpty) return firstLine;
  }
  return null;
}

class KycInitiateResult {
  final bool success;
  final String? kycOnboardingUrl;
  final String? errorCode;
  final String? errorMessage;
  final String? panNo;
  /// Set when the service returns due to non-200 status (e.g. 401). Used to avoid treating HTTP errors as "already initiated".
  final int? httpStatusCode;

  const KycInitiateResult({
    required this.success,
    this.kycOnboardingUrl,
    this.errorCode,
    this.errorMessage,
    this.panNo,
    this.httpStatusCode,
  });

  factory KycInitiateResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const KycInitiateResult(success: false);
    }
    // Unwrap common API envelope: { "data": { ... } } or { "result": { ... } }
    Map<String, dynamic> payload = json;
    final inner = payload['data'] ?? payload['result'];
    if (inner is Map<String, dynamic>) {
      payload = inner;
    }
    // Support camelCase, PascalCase, and provider-style (e.g. KYCOnboardingURL).
    final success = payload['success'] as bool? ?? payload['Success'] as bool? ?? false;
    final url = payload['kycOnboardingUrl'] as String? ??
        payload['KycOnboardingUrl'] as String? ??
        payload['KYCOnboardingURL'] as String?;
    final code = payload['errorCode'] as String? ?? payload['ErrorCode'] as String?;
    final message = _extractDisplayMessage(payload) ??
        (payload['errorMessage'] as String? ?? payload['Message'] as String?)?.trim();
    final pan = payload['panNo'] as String? ?? payload['PanNo'] as String?;
    return KycInitiateResult(
      success: success,
      kycOnboardingUrl: url,
      errorCode: code,
      errorMessage: message != null && message.isNotEmpty ? message : null,
      panNo: pan,
    );
  }

  bool get hasValidUrl =>
      kycOnboardingUrl != null &&
      kycOnboardingUrl!.trim().isNotEmpty &&
      Uri.tryParse(kycOnboardingUrl!) != null;

  /// True when initiate returned 200 with success false, no URL, and a message
  /// (e.g. "KYC Already Initiated for the given PAN"). Do not true for HTTP errors (401, 403, etc.).
  bool get isAlreadyInitiatedResponse =>
      !success &&
      !hasValidUrl &&
      (errorMessage != null && errorMessage!.trim().isNotEmpty) &&
      (httpStatusCode == null || httpStatusCode == 200);

  /// Message to show in toast or error UI; never null when [isAlreadyInitiatedResponse] is true.
  String get displayMessage {
    final msg = errorMessage?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return "KYC is in progress. We'll notify you when it's verified.";
  }
}

class KycEvaluateResult {
  final bool isKycRequired;
  final String reason;

  const KycEvaluateResult({
    required this.isKycRequired,
    required this.reason,
  });

  factory KycEvaluateResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const KycEvaluateResult(
        isKycRequired: true,
        reason: 'Unable to evaluate',
      );
    }
    return KycEvaluateResult(
      isKycRequired: json['isKycRequired'] as bool? ?? true,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class KycPanVerifyResult {
  final bool success;
  final String? kRASubmissionStatus;
  final String? kRAKYCCompletedStatus;
  final String? kRAStatusCode;
  final String? errorMessage;
  final String? panNo;

  const KycPanVerifyResult({
    required this.success,
    this.kRASubmissionStatus,
    this.kRAKYCCompletedStatus,
    this.kRAStatusCode,
    this.errorMessage,
    this.panNo,
  });

  factory KycPanVerifyResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const KycPanVerifyResult(success: false);
    }
    // Unwrap envelope: { "data": { ... } } or { "result": { ... } }
    Map<String, dynamic> payload = json;
    final inner = payload['data'] ?? payload['result'];
    if (inner is Map<String, dynamic>) {
      payload = inner;
    }

    // Success: top-level Success (PascalCase) or success (camelCase)
    final success = payload['Success'] as bool? ?? payload['success'] as bool? ?? false;

    // KRA status: prefer nested KRAStatus object, then flat keys
    final kraStatus = payload['KRAStatus'] as Map<String, dynamic>?;
    final kRASubmissionStatus = _stringOrNull(kraStatus?['KRASUBMISSIONSTATUS']) ??
        _stringOrNull(kraStatus?['KRASubmissionStatus']) ??
        _stringOrNull(payload['kRASubmissionStatus']);
    final kRAKYCCompletedStatus = _stringOrNull(kraStatus?['KRAKYCCOMPLETEDSTATUS']) ??
        _stringOrNull(kraStatus?['KRAKYCCompletedStatus']) ??
        _stringOrNull(payload['kRAKYCCompletedStatus']) ??
        _stringOrNull(payload['KRAKYCCompletedStatus']);
    final kRAStatusCode = _stringOrNull(kraStatus?['KRASTATUSCODE']) ??
        _stringOrNull(kraStatus?['KRAStatusCode']) ??
        _stringOrNull(payload['kRAStatusCode']);

    // Message: top-level Message, or extract from payload
    final errorMsg = _extractDisplayMessage(payload) ??
        _stringOrNull(payload['Message']) ??
        _stringOrNull(payload['errorMessage']) ??
        _stringOrNull(payload['ErrorCode']);
    final errorMessage = errorMsg != null && errorMsg.trim().isNotEmpty ? errorMsg.trim() : null;

    // PAN: CustomerDetails.APP_PAN_NO or top-level
    final customerDetails = payload['CustomerDetails'] as Map<String, dynamic>?;
    final panNo = _stringOrNull(customerDetails?['APP_PAN_NO']) ??
        _stringOrNull(payload['panNo']) ??
        _stringOrNull(payload['PanNo']);

    return KycPanVerifyResult(
      success: success,
      kRASubmissionStatus: kRASubmissionStatus,
      kRAKYCCompletedStatus: kRAKYCCompletedStatus,
      kRAStatusCode: kRAStatusCode,
      errorMessage: errorMessage,
      panNo: panNo,
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return value.toString().trim();
  }

  /// User-facing message when verification failed; null if success or no message.
  String? get displayErrorMessage => errorMessage?.trim().isNotEmpty == true ? errorMessage!.trim() : null;

  /// Normalized (lowercase) KRA submission status for branching.
  String? get kraSubmissionStatusNormalized =>
      kRASubmissionStatus != null && kRASubmissionStatus!.trim().isNotEmpty
          ? kRASubmissionStatus!.trim().toLowerCase().replaceAll(' ', '')
          : null;

  /// Normalized (lowercase) KRA KYC completed status for branching.
  String? get kraKycCompletedStatusNormalized =>
      kRAKYCCompletedStatus != null && kRAKYCCompletedStatus!.trim().isNotEmpty
          ? kRAKYCCompletedStatus!.trim().toLowerCase().replaceAll(' ', '')
          : null;

  /// Display state from (KRASUBMISSIONSTATUS, KRAKYCCOMPLETEDSTATUS) for UI message lookup.
  KycKraDisplayState get kraDisplayState => kraDisplayStateFromStatus(
        submissionNormalized: kraSubmissionStatusNormalized,
        completedNormalized: kraKycCompletedStatusNormalized,
      );

  /// User-facing message for current state (snackbar). Use messageForKycKraState(kraDisplayState, ...) for custom context.
  String get displayMessageForState =>
      messageForKycKraState(kraDisplayState, forSnackbar: true);

  /// True when status is Validated or Completed (show full-screen success).
  bool get isKycCompleted {
    final n = kraKycCompletedStatusNormalized;
    return n == 'validated' || n == 'completed';
  }

  /// Display string for persistence (Validated, Pending, InProgress, Rejected, Unknown).
  String get statusForPersistence {
    final n = kraKycCompletedStatusNormalized;
    if (n == null) return 'Unknown';
    switch (n) {
      case 'validated':
      case 'completed':
        return 'Validated';
      case 'pending':
        return 'Pending';
      case 'inprogress':
        return 'InProgress';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// Backend enum value for validated KYC (legacy).
  bool get isValidated =>
      kRAKYCCompletedStatus != null &&
      kRAKYCCompletedStatus!.toLowerCase() == 'validated';
}
