import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/logger.dart';

class ApiURLs {
  static late String _baseUrl;

  /// Hardcoded base URL for all v1 (user.md / profile.md / ucc.md) endpoints.
  /// Change this when promoting to production.
  static const String _v1BaseUrl = 'https://testing.pivotmoney.app/api/v1';

  /// Hardcoded base URL for all v2 (onboarding.md / holder.md) endpoints.
  static const String _v2BaseUrl = 'https://testing.pivotmoney.app/api/v2';
  static const String baseUrlIp = 'http://10.0.2.2:8000/api/v1';
  // static const tempToken =
  //     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc3MDUwNzE2LCJpYXQiOjE3NzcwNDk4MTYsImp0aSI6Ijc1MTllNzY4MjRmODQ2MDJhY2ZjZTg1ZDkzMDhlNDhhIiwidXNlcl9pZCI6IjVjMzFjMTA2LWY0ZmItNDgwNC05NGEyLTAyMmYxNzQ5YTVkYiJ9.X_bikc8LRxoGIEGLuOS7RZeoqim2K47ZH8ckMSxTL2k";

  /// Initialize the API URLs with the remote config base URL
  /// This must be called after RemoteConfigService is initialized
  static void initialize() {
    _baseUrl = RemoteConfigService.to.baseUrl.value;
    AppLogger.info('ApiURLs initialized with base URL: $_baseUrl');
  }

  static String get baseUrl => _baseUrl;

  /// Force refresh the base URL from remote config
  static Future<void> forceRefresh() async {
    try {
      AppLogger.info('Force refreshing API base URL from remote config');

      // Force refresh remote config
      await RemoteConfigService.to.forceRefresh();

      // Update base URL with new value
      final newBaseUrl = RemoteConfigService.to.baseUrl.value;
      if (newBaseUrl != _baseUrl) {
        _baseUrl = newBaseUrl;
        AppLogger.info('API base URL updated to: $_baseUrl');
      } else {
        AppLogger.info('API base URL unchanged: $_baseUrl');
      }
    } catch (e) {
      AppLogger.error('Error refreshing API base URL: $e');
    }
  }

  /// Helper method to append platform-specific query parameters
  static String _addPlatformParams(String url) {
    // final version = RemoteConfigService.to.minimumAppVersion.value;
    // final separator = url.contains('?') ? '&' : '?';
    // if (Platform.isAndroid) {
    //   return '$url${separator}src=android&a_v=$version';
    // } else if (Platform.isIOS) {
    //   return '$url${separator}src=ios&a_v=$version';
    // }
    return url;
  }

  static String get GENERATE_OTP =>
      _addPlatformParams("$baseUrl/auth/send-otp");
  static String get VERIFY_OTP =>
      _addPlatformParams("$baseUrl/auth/verify-otp");
  static String get GOOGLE_AUTH =>
      _addPlatformParams("$baseUrl/auth/google-auth");
  static String get PAN_CARD_VERIFICATION =>
      _addPlatformParams("$baseUrl/pan-verification/verify");
  static String get PAN_CONFIRMATION =>
      _addPlatformParams("$baseUrl/pan-verification/confirm");
  static String get SEND_EMAIL_OTP =>
      _addPlatformParams("$baseUrl/auth/send-email-otp");
  static String get PAN_CARD_MANUAL_VERIFICATION =>
      _addPlatformParams("$baseUrl/pan-verification/manual-panform");

  // ── Auth V1 (user.md) ─────────────────────────────────────────────────────
  static String get AUTH_LOGIN => '$_v1BaseUrl/auth/login/';
  static String get AUTH_VERIFY => '$_v1BaseUrl/auth/verify/';
  static String get AUTH_REFRESH => '$_v1BaseUrl/auth/refresh/';
  static String get AUTH_STATUS => '$_v1BaseUrl/auth/status/';

  // ── Profile V1 (profile.md) ───────────────────────────────────────────────
  static String get PROFILE_PAN => '$_v1BaseUrl/profile/pan/';
  static String get PROFILE_PAN_VERIFY => '$_v1BaseUrl/profile/pan_verify/';
  static String get PROFILE_BANK_DETAILS => '$_v2BaseUrl/profile/bank/details/';
  static String get PROFILE_DETAILS => '$_v2BaseUrl/profile/details/';
  static String get PROFILE_DETAILS_UPDATE => '$_v2BaseUrl/profile/update/';

  // V2 Bank Management
  static String get BANK_UPI_LOOKUP => '$_v2BaseUrl/profile/bank/upi/lookup/';
  static String get BANK_UPI_CONFIRM => '$_v2BaseUrl/profile/bank/upi/confirm/';
  static String get BANK_MANUAL => '$_v2BaseUrl/profile/bank/manual/';

  // ── MF Central V1 ─────────────────────────────────────────────────────────
  static String get MF_CENTRAL_TRIGGER => '$_v1BaseUrl/mfcentral/trigger/';
  static String get MF_CENTRAL_SYNC => '$_v1BaseUrl/mfcentral/sync/';

  // ── MF Portfolio V2 (after QR sync) ───────────────────────────────────────
  /// Primary holdings endpoint — returns summary + structured holdings list
  static String get MF_PORTFOLIO_HOLDINGS => '$_v2BaseUrl/portfolio/holdings/';

  /// Linked accounts for Linked Accounts screen (from MF Central)
  static String get MF_CENTRAL_LINKED_ACCOUNTS =>
      '$_v2BaseUrl/portfolio/linked-accounts/';

  /// Legacy flat holdings list (kept for fallback)
  static String get MF_USER_HOLDINGS => '$_v2BaseUrl/portfolio/user-holdings/';
  static String get MF_USER_TRANSACTIONS =>
      '$_v2BaseUrl/portfolio/user-transactions/';

  // ── Account V1 (ucc.md) ───────────────────────────────────────────────────
  static String get ACCOUNT_CREATE => '$_v1BaseUrl/account/create/';
  static String get ACCOUNT_CREATE_WITHOUT_NOMINEE =>
      '$_v1BaseUrl/account/create_without_nominee/';
  static String get ACCOUNT_OTP_VERIFY => '$_v1BaseUrl/account/otp_verify/';

  // ── Onboarding V2 (onboarding.md) ─────────────────────────────────────────
  static String get CONTACT_OTP_SEND => '$_v2BaseUrl/profile/contact/otp/';
  static String get CONTACT_OTP_VERIFY =>
      '$_v2BaseUrl/profile/contact/otp/verify/';
  static String get CONTACT_PHONE_SAVE =>
      '$_v2BaseUrl/profile/contact/phone/save/';
  static String get PAN_VERIFY_V2 => '$_v2BaseUrl/profile/pan/verify/';

  // ── Holder Management V2 (holder.md) ──────────────────────────────────────
  static String get HOLDERS_LIST => '$_v2BaseUrl/profile/holders/';
  static String get HOLDERS_ADD => '$_v2BaseUrl/profile/holders/';
  static String holderDetail(int id) => '$_v2BaseUrl/profile/holders/$id/';
  static String holderUpdate(int id) => '$_v2BaseUrl/profile/holders/$id/';
  static String holderDelete(int id) => '$_v2BaseUrl/profile/holders/$id/';
  static String get SET_SECURITY_PIN =>
      _addPlatformParams("$baseUrl/auth/set-security-pin");
  static String get LOGIN_WITH_PIN =>
      _addPlatformParams("$baseUrl/auth/security-pin");
  static String get GET_USER_PROFILE =>
      _addPlatformParams("$baseUrl/userdetail/profile");
  static String get UPDATE_USER_PROFILE =>
      _addPlatformParams("$baseUrl/userdetail/profile");
  static String get UPDATE_USER_PHONE =>
      _addPlatformParams("$baseUrl/userdetail/phone");
  static String get ONBOARDING_FLOW =>
      _addPlatformParams("$baseUrl/onboarding/flow");
  static String get ONBOARDING_PROGRESS =>
      _addPlatformParams("$baseUrl/onboarding/progress");
  static String get USER_DASHBOARD_ASSETS =>
      _addPlatformParams("$_v1BaseUrl/aa/dashboard/assets/");
  static String get GET_BANK_SUMMARY =>
      _addPlatformParams("$_v1BaseUrl/aa/accounts/?view=bank");
  static String get GET_USER_INVESTMENTS =>
      _addPlatformParams("$_v1BaseUrl/aa/dashboard/portfolio/");
  static String get GET_ALL_INVESTMENTS_TRANSACTIONS =>
      _addPlatformParams("$_v1BaseUrl/aa/transaction/all");
  static String get ADHOC_REFRESH =>
      _addPlatformParams("$baseUrl/fiu/v2/adhoc");
  static String get USER_DASHBOARD_ASSET_BANK =>
      _addPlatformParams("$_v1BaseUrl/aa/accounts");
  static String get GET_NPS => _addPlatformParams("$_v1BaseUrl/aa/nps");
  static String get GET_USER_HOLDINGS =>
      _addPlatformParams("$_v1BaseUrl/aa/dashboard/portfolio/all");
  static String get GET_BANK_TRANSACTION =>
      _addPlatformParams("$_v1BaseUrl/aa/bank/transactions");
  static String get GET_ZERODHA_CONNECTION =>
      _addPlatformParams("$baseUrl/zerodha/login-url");

  static String get MF_HOLDINGS_TOKEN =>
      _addPlatformParams("$baseUrl/mfcentral/token");
  static String get MF_HOLDINGS_VERIFY =>
      _addPlatformParams("$baseUrl/mfcentral/submit-otp");
  static String get GET_TOTAL_NETWORTH =>
      _addPlatformParams("$_v1BaseUrl/aa/dashboard/networth/");

  static String get GET_MF_SWITCH_ADVICE =>
      _addPlatformParams("$baseUrl/mfcentral/switch/details");

  // ── Mutual Funds V1 (mutual_funds.md) ─────────────────────────────────────
  static String get MUTUAL_FUNDS_LIST => '$_v1BaseUrl/mutual_funds/list/';
  static String get MUTUAL_FUNDS_SEARCH => '$_v1BaseUrl/mutual_funds/search/';
  static String get MUTUAL_FUNDS_DETAIL => '$_v1BaseUrl/mutual_funds/detail/';

  // ── Mutual Funds V2 (Section 9 & 10 - frontend_investment_apis.md) ────────
  static String get MUTUAL_FUNDS_BROWSE_PUBLIC =>
      '$_v2BaseUrl/mutual-funds/browse-public/';
  static String get MUTUAL_FUNDS_BROWSE =>
      '$_v2BaseUrl/mutual-funds/browse-public/';
  static String get MUTUAL_FUNDS_BROWSE_FILTER_OPTIONS =>
      '$_v2BaseUrl/mutual-funds/browse/filter-options/';
  static String get MUTUAL_FUNDS_DETAIL_V2 =>
      '$_v2BaseUrl/mutual-funds/detail/';

  // ── Profile & Onboarding V2 (Section 2, 7, 8 - frontend_investment_apis.md) ─
  static String get PROFILE_VALIDATE => '$_v2BaseUrl/profile/validate/';
  static String get PROFILE_HOLDERS => '$_v2BaseUrl/profile/holders/';

  // ── Orders V1 (order.md) ────────────────────────────────────────────────
  static String get ORDER_ACCOUNTS => '$_v1BaseUrl/order/accounts/';
  static String ORDER_CHECK_FOLIO(String uccId) =>
      '$_v1BaseUrl/order/check_folio/$uccId/';
  static String get ORDER_CREATE => '$_v1BaseUrl/order/create/';
  static String get ORDER_PAYMENT => '$_v1BaseUrl/order/payment/';
  static String ORDER_PAYMENT_STATUS(dynamic id) =>
      '$_v1BaseUrl/order/payment/status/$id/';
  static String get ORDER_REDEEM => '$_v1BaseUrl/order/redeem/';

  // SIP V1
  static String get SIP_CREATE => '$_v1BaseUrl/sip/create/';
  static String get SIP_PAYMENT => '$_v1BaseUrl/sip/payment/';
  static String SIP_PAYMENT_STATUS(dynamic id) =>
      '$_v1BaseUrl/sip/payment/status/$id/';

  // Portfolio V1 (portfolio.md)
  static String get PORTFOLIO_MF_LIST =>
      '$_v1BaseUrl/portfolio/mutual_funds/list/';
  static String PORTFOLIO_MF_DETAIL(dynamic id) =>
      '$_v1BaseUrl/portfolio/mutual_funds/$id/';
  static String get PORTFOLIO_SIP_LIST => '$_v1BaseUrl/portfolio/sip/list/';
  static String PORTFOLIO_SIP_DETAIL(dynamic id) =>
      '$_v1BaseUrl/portfolio/sip/$id/';
  static String get PORTFOLIO_SELLABLE =>
      '$_v1BaseUrl/portfolio/mutual_funds/sellable/';

  // Holders API (Section 8 - frontend_investment_apis.md)
  static String get GET_HOLDERS => '$_v2BaseUrl/profile/holders/';
  static String updateHolder(int holderId) =>
      '$_v2BaseUrl/profile/holders/$holderId/';

  // UCC Trade Wizard V2 (Section 14 - frontend_investment_apis.md)
  static String get TRADE_PAYMENT_POLL_CONFIG =>
      '$_v2BaseUrl/trade/payment-poll-config/';
  static String get TRADE_UCC_RESOLVE => '$_v2BaseUrl/trade/ucc/resolve/';
  static String get TRADE_UCC_DRAFT => '$_v2BaseUrl/trade/ucc/draft/';
  static String get TRADE_UCC_NOMINATION => '$_v2BaseUrl/trade/ucc/nomination/';
  static String get TRADE_UCC_NOMINEE_OPTOUT_VERIFY =>
      '$_v2BaseUrl/trade/ucc/nominee-opt-out/verify/';
  static String get TRADE_UCC_NOMINEE_OPTOUT_RESEND =>
      '$_v2BaseUrl/trade/ucc/nominee-opt-out/resend/';
  static String get TRADE_UCC_BSE_FINISH => '$_v2BaseUrl/trade/ucc/bse/finish/';
  static String tradeUccStatus(String clientCode) =>
      '$_v2BaseUrl/trade/ucc/status/?client_code=$clientCode';

  // Mandate APIs (Section 17 - frontend_investment_apis.md)
  static String get TRADE_MANDATE_STATUS => '$_v2BaseUrl/trade/mandate/status/';
  static String get TRADE_MANDATE_REGISTER =>
      '$_v2BaseUrl/trade/mandate/register/';
  static String get TRADE_MANDATE_POLL => '$_v2BaseUrl/trade/mandate/poll/';
  static String get TRADE_SIP_CREATE => '$_v2BaseUrl/trade/sip/create/';

  static String get GET_NOTIFICATION_PERMISSION =>
      _addPlatformParams("$baseUrl/userdetail/fcm");

  static String get GET_GLOBAL_SEARCH =>
      _addPlatformParams("$_v1BaseUrl/disabled/global-search/search");
  static String get GET_GLOBAL_SEARCH_TRENDING =>
      _addPlatformParams("$_v1BaseUrl/disabled/global-search/trending");

  static String get SET_PIN =>
      _addPlatformParams("$baseUrl/auth/set-security-pin");
  static String get ACCOUNT_AGGREGATORS_CREATE_CONSENT =>
      _addPlatformParams("$baseUrl/fiu/v2/create-consent");

  static String get GET_INSURANCE_LIST =>
      _addPlatformParams("$_v1BaseUrl/aa/insurance/summary");
  static String get GET_INSURANCE_DETAILS =>
      _addPlatformParams("$_v1BaseUrl/aa/insurance/details/");

  static String get GET_RELATION_OPTIONS =>
      _addPlatformParams("$baseUrl/family/select-relation");
  static String get GET_FAMILY_HEAD_MEMBER_SUMMARY =>
      _addPlatformParams("$baseUrl/family/userfamilysummary");
  static String get CREATE_FAMILY =>
      _addPlatformParams("$baseUrl/family/invite");
  static String get GET_FAMILY_MEMBER =>
      _addPlatformParams("$baseUrl/family/members");
  static String get EDIT_FAMILY_MEMBER =>
      _addPlatformParams("$baseUrl/family/members/edit");
  static String get REMOVE_FAMILY_MEMBER =>
      _addPlatformParams("$baseUrl/family/kickout");
  static String get DELETE_FAMILY =>
      _addPlatformParams("$baseUrl/family/delete-family");
  static String get LEAVE_FAMILY => _addPlatformParams("$baseUrl/family/leave");
  static String get FAMILY_ASSET_CONSENT =>
      _addPlatformParams("$baseUrl/family/members/asset-consent");
  static String Function(String invitationId) get GET_INVITATION_DETAILS =>
      (String invitationId) => _addPlatformParams(
        "$baseUrl/family/invitation-details/$invitationId",
      );

  static String get GET_FAMILY_DASHBOARD_ASSETS =>
      _addPlatformParams("$baseUrl/family/dashboardassets");

  static String Function(String familyId) get GET_FAMILY_DASHBOARD_ASSET_BANK =>
      (String familyId) => _addPlatformParams(
        "$baseUrl/family/members/assets?familyId=$familyId&types=DEPOSIT",
      );

  static String Function(String familyId) get GET_FAMILY_DASHBOARD_ASSET_NPS =>
      (String familyId) => _addPlatformParams(
        "$baseUrl/family/members/assets?familyId=$familyId&types=NPS",
      );

  static String Function(String familyId)
  get GET_FAMILY_DASHBOARD_ASSET_INVESTMENTS =>
      (String familyId) => _addPlatformParams(
        "$baseUrl/family/members/assets?familyId=$familyId&types=EQUITY,MUTUAL_FUNDS,ETF",
      );

  static String Function(String familyId)
  get GET_FAMILY_DASHBOARD_ASSET_INSURANCE =>
      (String familyId) => _addPlatformParams(
        "$baseUrl/family/members/assets?familyId=$familyId&types=life_insurance,general_insurance,insurance_policies",
      );

  static String Function(String memberUserId, String familyId)
  get ACCEPT_FAMILY_INVITATION =>
      (String memberUserId, String familyId) =>
          _addPlatformParams("$baseUrl/family/accept/$memberUserId/$familyId");

  static String Function(String memberUserId, String familyId)
  get REJECT_FAMILY_INVITATION =>
      (String memberUserId, String familyId) =>
          _addPlatformParams("$baseUrl/family/reject/$memberUserId/$familyId");

  static String get GET_FINANCIAL_PROFILING_QUESTIONS =>
      _addPlatformParams("$baseUrl/financial-profile/questions");

  static String get SUBMIT_FINANCIAL_PROFILING =>
      _addPlatformParams("$baseUrl/financial-profile");

  static String get GET_FINANCIAL_PROFILING_ANSWER =>
      _addPlatformParams("$baseUrl/financial-profile");

  static String get UPDATE_FINANCIAL_PROFILING_ANSWER =>
      _addPlatformParams("$baseUrl/financial-profile");

  static String get POST_PERSONAL_FINANCE_REAL_ESTATE =>
      _addPlatformParams("$baseUrl/personal-assets/real-estate");

  static String get POST_PERSONAL_FINANCE_LAND =>
      _addPlatformParams("$baseUrl/personal-assets/land");

  static String POST_PERSONAL_FINANCE_METAL = _addPlatformParams(
    "$baseUrl/personal-assets/metal",
  );
  static String POST_PERSONAL_FINANCE_CRYPTO = _addPlatformParams(
    "$baseUrl/personal-assets/crypto",
  );
  static String POST_PERSONAL_FINANCE_MONEY_LENT = _addPlatformParams(
    "$baseUrl/personal-assets/money-lent",
  );
  static String POST_PERSONAL_FINANCE_OTHER = _addPlatformParams(
    "$baseUrl/personal-assets/other",
  );

  // Personal Assets GET APIs
  static String get GET_PERSONAL_ASSETS =>
      _addPlatformParams("$baseUrl/personal-assets");
  static String get GET_PERSONAL_ASSETS_TOTAL_VALUE =>
      _addPlatformParams("$baseUrl/personal-assets/total-value");

  // Personal Assets DELETE API
  static String Function(int assetId) get DELETE_PERSONAL_ASSET =>
      (int assetId) => _addPlatformParams("$baseUrl/personal-assets/$assetId");

  // Personal Assets GET by ID API
  static String Function(int assetId) get GET_PERSONAL_ASSET_BY_ID =>
      (int assetId) => _addPlatformParams("$baseUrl/personal-assets/$assetId");

  // Personal Assets UPDATE API
  static String Function(int assetId) get UPDATE_PERSONAL_ASSET =>
      (int assetId) => _addPlatformParams("$baseUrl/personal-assets/$assetId");

  static String get GET_TAX_ADVISORY =>
      _addPlatformParams("$baseUrl/mf-lots-tax/user-tax-calculation");

  static String get FIP_STATUS => _addPlatformParams("$baseUrl/aa/fip-status");
  // Finarkein AA endpoints - Used when aa_provider is FINARKEIN
  static String get AA_CONSENT_INITIATE =>
      _addPlatformParams("$_v1BaseUrl/finarkein/consent/initiate/");
  static String AA_CONSENT_STATUS(String requestId) => _addPlatformParams(
    "https://atom.pivotmoney.app/clearance/api/v1/aa/consent/status/$requestId",
  );
  static String AA_DATA_RESULT(String requestId) => _addPlatformParams(
    "https://atom.pivotmoney.app/clearance/api/v1/aa/data/result/$requestId",
  );
  static String get AA_CONSENTS =>
      _addPlatformParams("$_v1BaseUrl/aa/consents");
  static String get AA_DATA_FETCH =>
      _addPlatformParams("$_v1BaseUrl/aa/data/fetch");
  static String get AA_CONSENT_REVOKE =>
      _addPlatformParams("$_v1BaseUrl/aa/consent/revoke/");
  static String AA_CONSENT_REVOKE_STATUS(String requestId) =>
      _addPlatformParams("$_v1BaseUrl/aa/consent/revoke/status/$requestId");

  static String get AA_DATA_REFRESH_ON_OPEN =>
      _addPlatformParams("$_v1BaseUrl/aa/data/refresh/on-open/");
  static String AA_DATA_REFRESH_ON_OPEN_STATUS(String operationId) =>
      _addPlatformParams("$_v1BaseUrl/aa/data/refresh/on-open/$operationId/");

  // KYC (MFU) endpoints - same base as clearance API
  static const String _kycBaseUrl =
      'https://atom.pivotmoney.app/clearance/api/v1';
  static String get KYC_EVALUATE =>
      _addPlatformParams('$_kycBaseUrl/kyc/evaluate');
  static String get KYC_PAN_VERIFY =>
      _addPlatformParams('$_kycBaseUrl/kyc/pan/verify');
  static String get KYC_INITIATE =>
      _addPlatformParams('$_kycBaseUrl/kyc/initiate');
  static String get KYC_DOCUMENTS =>
      _addPlatformParams('$_kycBaseUrl/kyc/documents');

  static String get MF_FETCHING_POLLING =>
      _addPlatformParams("$baseUrl/mfcentral/status");
  static String get ADHOC_REMAINING => _addPlatformParams("$baseUrl/aa/adhoc");
  static String get SKIP_MFC =>
      _addPlatformParams("$baseUrl/mfcentral/skipmfc");
  static String get GET_INVESTMENT_TRANSACTION =>
      _addPlatformParams("$_v1BaseUrl/aa/transaction/all");

  // MF Central V2 Portfolio & Transactions
  static String get MF_CENTRAL_USER_HOLDINGS =>
      '$_v2BaseUrl/portfolio/user-holdings/';
  static String get MF_CENTRAL_USER_TRANSACTIONS =>
      '$_v2BaseUrl/portfolio/user-transactions/';

  // UCC BSE
  static String get GET_BSE_NOMINEE_RELATION =>
      _addPlatformParams("$baseUrl/bse-star/nominee-relation");
  static String get GET_BSE_OCCUPATION_OPTIONS =>
      _addPlatformParams("$baseUrl/bse-star/get-occupations");
  static String get GET_BSE_UCC_STATUS =>
      _addPlatformParams("$_v1BaseUrl/disabled/bse-star/ucc-status");
  static String get GET_BSE_UCC_REGISTER =>
      _addPlatformParams("$baseUrl/bse-star/register-ucc");
  static String get GET_BSE_DOCUMENT_IDENTIFIER =>
      _addPlatformParams("$baseUrl/identifier/get-identifiers");

  static String get EDIT_AVG_BUY_PRICE =>
      _addPlatformParams("$baseUrl/transaction/edit_avgbuyprice");
  static String get PORTFOLIO_HOLDINGS_COST =>
      '$_v2BaseUrl/portfolio/holdings/cost/';
  static String get GET_LATEST_ISIN_UPDATED_DATE => _addPlatformParams(
    "$baseUrl/personal-assets/get-latest-isin-updated-date",
  );
  static String get GET_TIN_DETAILS =>
      _addPlatformParams("$baseUrl/tin/get-tin-details");
  static String get GET_IFSC_DETAILS =>
      _addPlatformParams("$baseUrl/bank/validate-ifsc");

  static String get GET_BSE_ORDER_DETAILS =>
      _addPlatformParams("$baseUrl/orders");

  static String get GET_BLOGS => _addPlatformParams("$baseUrl/content/blogs");
  static String get GET_CALCULATORS =>
      _addPlatformParams("$baseUrl/content/calculators");

  // BSE Star API Endpoints
  static String get BSE_Star_ONBOARDING =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding";
  static String BSE_Star_DELETE_ONBOARDING(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId";
  static String BSE_Star_CREATE_HOLDER(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders";
  static String BSE_Star_UPDATE_HOLDER(String onboardingId, String holderId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId";
  static String BSE_Star_DELETE_HOLDER(String onboardingId, String holderId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId";
  static String BSE_Star_BANK_ACCOUNT(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/banks";
  static String BSE_Star_DELETE_BANK(String onboardingId, String bankId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/banks/$bankId";
  static String BSE_Star_CREATE_ADDRESS(String onboardingId, String holderId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId/addresses";
  static String BSE_Star_UPDATE_ADDRESS(String onboardingId, String holderId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId";
  static String BSE_Star_DELETE_ADDRESS(
    String onboardingId,
    String holderId,
    String addressId,
  ) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId/addresses/$addressId";
  static String BSE_Star_NOMINEES(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/nominees";
  static String BSE_Star_DELETE_NOMINEE(
    String onboardingId,
    String nomineeId,
  ) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/nominees/$nomineeId";
  static String BSE_Star_FATCA(String onboardingId, String holderId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/holders/$holderId/personal";
  static String BSE_Star_SUBMIT(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/submit";

  static String get STORAGE_PRESIGNED_URL =>
      "https://atom.pivotmoney.app/onboarding/api/v1/storage/presigned-url";
  static String get STORAGE_OBJECT =>
      "https://atom.pivotmoney.app/onboarding/api/v1/storage/object";

  static String BSE_Star_GET_BSE_ONBOARDING(String onboardingId) =>
      "https://atom.pivotmoney.app/onboarding/api/v1/onboarding/$onboardingId/full";

  // Create Order API
  static String get CREATE_ORDER =>
      "https://atom.pivotmoney.app/orders/api/v1/orders/";
  static String get SELL_ORDER =>
      "https://atom.pivotmoney.app/orders/api/v1/orders/sell";

  static String get GET_FINARKEIN_DATA =>
      "https://atom.pivotmoney.app/clearance/api/v1/aa/result";

  static String get GET_FINARKEIN_STATUS =>
      "https://testing.pivotmoney.app/api/v1/aa/consents";

  static String get LOGOUT => _addPlatformParams("$baseUrl/userdetail/logout");

  static String BSE_UCC_STATUS_CHECK() => '';
  // "$_v1BaseUrl/disabled/bse/ucc-details";

  static String BSE_payment_redirect_link(int orderId) =>
      "https://atom.pivotmoney.app/orders/api/v1/orders/$orderId/payment-link";
  // AA Data Fetch APIs
  static String get AA_FETCH_OPTIONS => "$_v1BaseUrl/aa/data/fetch/options";
  static String get AA_FETCH_ACCOUNT => "$_v1BaseUrl/aa/data/fetch/account/";
  static String get AA_FETCH_ALL => "$_v1BaseUrl/aa/data/fetch/all";
  static String CANCEL_ORDER(dynamic orderId) =>
      "https://atom.pivotmoney.app/orders/api/v1/orders/$orderId/cancel";

  // Equity Basket APIs
  static String get EQUITY_BASKET_STRATEGY =>
      "http://192.168.1.14:3000/api/equities";

  static String get CASHFREE_CREATE_ORDER =>
      "http://192.168.1.14:3000/api/cashfree/orders";

  // Document Generation APIs
  static String get GENERATE_RIA_AGREEMENT =>
      "http://192.168.1.14:3000/api/cashfree/documents/ria-agreement";

  // E-Sign APIs
  static String get ESIGN_UPLOAD_DOCUMENT =>
      "http://192.168.1.14:3000/api/cashfree/esign/upload";

  static String get ESIGN_CREATE_REQUEST =>
      "http://192.168.1.14:3000/api/cashfree/esign/create";

  static String esignStatus(String requestId) =>
      "http://192.168.1.14:3000/api/cashfree/esign/status/$requestId";
}
