const BASE_KEY = "pivot.money_";

class StorageKeys {
  static const String AUTH_TOKEN_KEY = '${BASE_KEY}auth_token';
  static const String REFRESH_TOKEN_KEY = '${BASE_KEY}refresh_token';
  static const String MF_SAVINGS_KEY = '${BASE_KEY}mf_savings';
  static const String MF_BOTTOMSHEET_SHOWN_KEY =
      '${BASE_KEY}mf_bottomsheet_shown';
  static const String PREVIOUS_MF_VERIFIED_KEY =
      '${BASE_KEY}previous_mf_verified';
  static const String PIN_KEY = '${BASE_KEY}pin';
  static const String IS_PIN_SET_KEY = '${BASE_KEY}is_pin_set';
  static const String APP_OPENED_COUNT_KEY = '${BASE_KEY}app_opened_count';
  static const String FAMILY_MODE_KEY = '${BASE_KEY}family_mode';
  static const String AMOUNT_VISIBILITY_KEY = '${BASE_KEY}amount_visibility';

  /// When true, user has opted to skip unlock prompts and should land on Dashboard on app open.
  static const String SKIP_TO_DASHBOARD_KEY = '${BASE_KEY}skip_to_dashboard';

  // KYC journey state (app close/reopen)
  static const String KYC_JOURNEY_STARTED_AT = '${BASE_KEY}kyc_journey_started_at';
  static const String KYC_SUCCESS_SCREEN_SEEN_AT =
      '${BASE_KEY}kyc_success_screen_seen_at';
  static const String KYC_LAST_VERIFIED_STATUS =
      '${BASE_KEY}kyc_last_verified_status';
  static const String KYC_LAST_VERIFIED_AT = '${BASE_KEY}kyc_last_verified_at';
  /// When set, KYC is "already initiated" and in progress; value is message for dashboard snackbar.
  static const String KYC_ALREADY_INITIATED_MESSAGE =
      '${BASE_KEY}kyc_already_initiated_message';
  /// Raw KRAKYCCOMPLETEDSTATUS value from API (e.g., "Completed", "Pending", etc.)
  static const String KYC_RAW_STATUS = '${BASE_KEY}kyc_raw_status';

  /// Finarkein AA bootstrap: last known consent existence per user.
  /// Used to speed up cold start decisions while still relying on network truth when available.
  static String AA_HAS_ANY_CONSENT(String userguid) =>
      '${BASE_KEY}aa_has_any_consent_$userguid';
  static String AA_HAS_ANY_CONSENT_UPDATED_AT(String userguid) =>
      '${BASE_KEY}aa_has_any_consent_updated_at_$userguid';
}
