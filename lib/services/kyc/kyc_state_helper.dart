import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/logger.dart';

const String _logTag = 'KycStateHelper';

/// Window within which we consider "journey started" as recent (show resume/check status).
const Duration kycJourneyRecentWindow = Duration(hours: 48);

class KycStateHelper {
  KycStateHelper._();
  static final KycStateHelper _instance = KycStateHelper._();
  factory KycStateHelper() => _instance;

  /// Set when we get onboarding URL / open webview.
  void setJourneyStartedAt() {
    final now = DateTime.now().toIso8601String();
    StorageService.write(StorageKeys.KYC_JOURNEY_STARTED_AT, now);
    AppLogger.info('KYC journey started at $now', tag: _logTag);
  }

  /// Set when user lands on success screen.
  void setSuccessScreenSeenAt() {
    final now = DateTime.now().toIso8601String();
    StorageService.write(StorageKeys.KYC_SUCCESS_SCREEN_SEEN_AT, now);
    AppLogger.info('KYC success screen seen at $now', tag: _logTag);
  }

  /// Clear journey started (e.g. when KYC validated or user finished and we no longer show "recent").
  void clearJourneyStartedAt() {
    StorageService.remove(StorageKeys.KYC_JOURNEY_STARTED_AT);
  }

  /// Set when pan/verify succeeds (any status: Validated, Pending, InProgress, Rejected, Unknown).
  void setLastVerifiedStatus(String status) {
    StorageService.write(StorageKeys.KYC_LAST_VERIFIED_STATUS, status);
    StorageService.write(
      StorageKeys.KYC_LAST_VERIFIED_AT,
      DateTime.now().toIso8601String(),
    );
  }

  /// Set raw KRAKYCCOMPLETEDSTATUS value from API (e.g., "Completed", "Pending", etc.)
  void setRawKycStatus(String? rawStatus) {
    if (rawStatus != null && rawStatus.trim().isNotEmpty) {
      StorageService.write(StorageKeys.KYC_RAW_STATUS, rawStatus.trim());
    }
  }

  /// Get raw KRAKYCCOMPLETEDSTATUS value as received from API
  String? get rawKycStatus {
    try {
      final value = StorageService.read(StorageKeys.KYC_RAW_STATUS) as String?;
      return value != null && value.trim().isNotEmpty ? value.trim() : null;
    } catch (e) {
      return null;
    }
  }

  /// Last persisted KRA KYC completed status (e.g. Validated, Pending, InProgress, Rejected, Unknown). Null if never set.
  String? get lastKycStatus {
    try {
      final value = StorageService.read(StorageKeys.KYC_LAST_VERIFIED_STATUS) as String?;
      return value != null && value.trim().isNotEmpty ? value.trim() : null;
    } catch (e) {
      return null;
    }
  }

  /// When the last pan/verify status was persisted (ISO8601 string). Null if never set.
  String? get lastKycVerifiedAt {
    try {
      final value = StorageService.read(StorageKeys.KYC_LAST_VERIFIED_AT) as String?;
      return value != null && value.trim().isNotEmpty ? value.trim() : null;
    } catch (e) {
      return null;
    }
  }

  /// Whether journey was started within the recent window (so we show "Complete your KYC" or "Check KYC status").
  bool get isJourneyRecent {
    try {
      final value =
          StorageService.read(StorageKeys.KYC_JOURNEY_STARTED_AT) as String?;
      if (value == null || value.isEmpty) return false;
      final at = DateTime.tryParse(value);
      if (at == null) return false;
      return DateTime.now().difference(at) < kycJourneyRecentWindow;
    } catch (e) {
      AppLogger.warning('KYC state read failed: $e', tag: _logTag);
      return false;
    }
  }

  /// Whether success screen was already seen (user closed after success).
  bool get hasSeenSuccessScreen {
    try {
      final value =
          StorageService.read(StorageKeys.KYC_SUCCESS_SCREEN_SEEN_AT);
      return value != null && value.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Set when user is in "already initiated" waiting state (show "In progress" on dashboard).
  void setAlreadyInitiatedInProgress(String message) {
    StorageService.write(StorageKeys.KYC_ALREADY_INITIATED_MESSAGE, message);
    AppLogger.info('KYC already initiated in progress: $message', tag: _logTag);
  }

  /// Clear when KYC is validated or polling exhausted.
  void clearAlreadyInitiatedInProgress() {
    StorageService.remove(StorageKeys.KYC_ALREADY_INITIATED_MESSAGE);
  }

  bool get isAlreadyInitiatedInProgress {
    try {
      final value = StorageService.read(StorageKeys.KYC_ALREADY_INITIATED_MESSAGE) as String?;
      return value != null && value.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String? get kycInProgressSnackbarMessage {
    try {
      final value = StorageService.read(StorageKeys.KYC_ALREADY_INITIATED_MESSAGE) as String?;
      return value != null && value.trim().isNotEmpty ? value.trim() : null;
    } catch (e) {
      return null;
    }
  }

  /// Card copy hint: default, complete your KYC, check status, or in progress.
  KycCardCopy get cardCopy {
    if (isAlreadyInitiatedInProgress) return KycCardCopy.inProgress;
    if (!isJourneyRecent) return KycCardCopy.completeKyc;
    if (hasSeenSuccessScreen) return KycCardCopy.checkStatus;
    return KycCardCopy.completeYourKyc;
  }
}

enum KycCardCopy {
  completeKyc,
  completeYourKyc,
  checkStatus,
  inProgress,
}
