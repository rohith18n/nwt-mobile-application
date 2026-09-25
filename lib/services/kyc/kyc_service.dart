import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/kyc/kyc_models.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/utils/logger.dart';

const String _logTag = 'KycFlow';

/// KYC API service. Uses Bearer auth via [NetworkAPIHelper].
/// Does not throw; returns result objects with error fields on failure.
class KycService {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// GET /kyc/evaluate - whether a fresh KYC journey is needed.
  Future<KycEvaluateResult> evaluateKycNeed() async {
    AppLogger.info('KYC evaluate request', tag: _logTag);
    final response = await _api.get(ApiURLs.KYC_EVALUATE);
    if (response == null) {
      AppLogger.warning('KYC evaluate: no response', tag: _logTag);
      return const KycEvaluateResult(
        isKycRequired: true,
        reason: 'Please check your connection and try again.',
      );
    }
    if (response.statusCode != 200) {
      AppLogger.warning(
        'KYC evaluate: status=${response.statusCode}',
        tag: _logTag,
      );
      return const KycEvaluateResult(
        isKycRequired: true,
        reason: 'Unable to evaluate KYC status.',
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      AppLogger.info('KYC evaluate response: ${response.body}', tag: 'KYC_STATUS');
      return KycEvaluateResult.fromJson(json);
    } catch (e) {
      AppLogger.error('KYC evaluate parse error: $e', tag: _logTag);
      return const KycEvaluateResult(
        isKycRequired: true,
        reason: 'Invalid response.',
      );
    }
  }

  /// POST /kyc/initiate - returns onboarding URL for webview.
  Future<KycInitiateResult> initiateKyc() async {
    AppLogger.info('KYC initiate request', tag: _logTag);
    final response = await _api.post(
      ApiURLs.KYC_INITIATE,
      <String, dynamic>{},
    );
    if (response == null) {
      AppLogger.warning('KYC initiate: no response', tag: _logTag);
      return const KycInitiateResult(
        success: false,
        errorMessage: 'Please check your connection and try again.',
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      AppLogger.info('KYC initiate response (status=${response.statusCode}): ${response.body}', tag: 'KYC_STATUS');
      final result = KycInitiateResult.fromJson(json);
      if (response.statusCode != 200) {
        final serverMessage = result.errorMessage?.trim();
        final fromBody = extractDisplayMessageFromResponseBody(response.body)?.trim();
        const fallback = 'Unable to start KYC. Please try again later.';
        final message = (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : (fromBody != null && fromBody.isNotEmpty)
                ? fromBody
                : fallback;
        return KycInitiateResult(
          success: false,
          errorCode: result.errorCode,
          errorMessage: message,
          httpStatusCode: response.statusCode,
        );
      }
      return result;
    } catch (e) {
      AppLogger.error('KYC initiate parse error: $e', tag: _logTag);
      return const KycInitiateResult(
        success: false,
        errorMessage: 'Invalid response.',
      );
    }
  }

  /// POST /kyc/pan/verify - verify PAN status; used pre-flow and for polling.
  Future<KycPanVerifyResult> verifyPanStatus() async {
    AppLogger.info('KYC pan/verify request', tag: _logTag);
    final response = await _api.post(
      ApiURLs.KYC_PAN_VERIFY,
      <String, dynamic>{},
    );
    if (response == null) {
      AppLogger.warning('KYC pan/verify: no response', tag: _logTag);
      return const KycPanVerifyResult(
        success: false,
        errorMessage: 'Please check your connection.',
      );
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      AppLogger.info('KYC pan/verify response (status=${response.statusCode}): ${response.body}', tag: 'KYC_STATUS');
      final result = KycPanVerifyResult.fromJson(json);
      AppLogger.info(
        'KYC pan/verify parsed: success=${result.success}, '
        'KRASUBMISSIONSTATUS=${result.kRASubmissionStatus}, '
        'KRAKYCCOMPLETEDSTATUS=${result.kRAKYCCompletedStatus}, '
        'statusForPersistence=${result.statusForPersistence}',
        tag: 'KYC_STATUS',
      );
      if (response.statusCode != 200) {
        final serverMessage = result.errorMessage?.trim();
        const fallback = 'Could not verify KYC status. Please try again later.';
        AppLogger.warning('KYC pan/verify non-200 status: ${response.statusCode}', tag: 'KYC_STATUS');
        return KycPanVerifyResult(
          success: false,
          errorMessage: serverMessage != null && serverMessage.isNotEmpty
              ? serverMessage
              : fallback,
        );
      }
      return result;
    } catch (e) {
      AppLogger.error('KYC pan/verify parse error: $e', tag: _logTag);
      return const KycPanVerifyResult(
        success: false,
        errorMessage: 'Invalid response.',
      );
    }
  }
}
