/// Firebase Analytics event names and parameter constants
/// All event names follow snake_case convention
class AnalyticsEvents {
  // App Launch & Onboarding Funnel
  static const String appLaunched = 'app_launched';
  static const String splashScreenViewed = 'splash_screen_viewed';
  static const String welcomeScreenViewed = 'welcome_screen_viewed';
  static const String getStartedClicked = 'get_started_clicked';
  static const String welcomeScreenCompleted = 'welcome_screen_completed';
  static const String welcomeScreenAbandoned = 'welcome_screen_abandoned';
  static const String welcomeScreenTimeExceeded = 'welcome_screen_time_exceeded';
  
  // Phone Verification Funnel
  static const String phoneScreenViewed = 'phone_screen_viewed';
  static const String phoneNumberEntered = 'phone_number_entered';
  static const String phoneSubmitClicked = 'phone_submit_clicked';
  static const String otpSentSuccess = 'otp_sent_success';
  static const String otpScreenViewed = 'otp_screen_viewed';
  static const String otpEntered = 'otp_entered';
  static const String otpVerifiedSuccess = 'otp_verified_success';
  static const String phoneVerificationCompleted = 'phone_verification_completed';
  static const String phoneScreenAbandoned = 'phone_screen_abandoned';
  static const String phoneNumberInvalid = 'phone_number_invalid';
  static const String otpSendFailed = 'otp_send_failed';
  static const String otpScreenAbandoned = 'otp_screen_abandoned';
  static const String otpVerificationFailed = 'otp_verification_failed';
  static const String otpMaxAttemptsReached = 'otp_max_attempts_reached';
  
  // Email Verification Funnel
  static const String emailScreenViewed = 'email_screen_viewed';
  static const String emailEntered = 'email_entered';
  static const String emailSubmitClicked = 'email_submit_clicked';
  static const String emailOtpSent = 'email_otp_sent';
  static const String emailOtpScreenViewed = 'email_otp_screen_viewed';
  static const String emailOtpEntered = 'email_otp_entered';
  static const String emailVerifiedSuccess = 'email_verified_success';
  static const String emailVerificationCompleted = 'email_verification_completed';
  static const String emailScreenAbandoned = 'email_screen_abandoned';
  static const String emailOtpNotReceived = 'email_otp_not_received';
  static const String emailVerificationFailed = 'email_verification_failed';
  static const String emailSkipClicked = 'email_skip_clicked';
  
  // PAN Verification Funnel
  static const String panScreenViewed = 'pan_screen_viewed';
  static const String panMethodSelected = 'pan_method_selected';
  static const String panScanned = 'pan_scanned';
  static const String panManualEntered = 'pan_manual_entered';
  static const String panSubmitClicked = 'pan_submit_clicked';
  static const String panVerificationProcessing = 'pan_verification_processing';
  static const String panVerifiedSuccess = 'pan_verified_success';
  static const String panConsentShown = 'pan_consent_shown';
  static const String panConsentAccepted = 'pan_consent_accepted';
  static const String panVerificationCompleted = 'pan_verification_completed';
  static const String panScreenAbandoned = 'pan_screen_abandoned';
  static const String panScanFailed = 'pan_scan_failed';
  static const String panManualEntryFailed = 'pan_manual_entry_failed';
  static const String panVerificationFailed = 'pan_verification_failed';
  static const String panConsentDeclined = 'pan_consent_declined';
  static const String panVerificationTimeout = 'pan_verification_timeout';
  
  // Personalization Funnel
  static const String personalizeScreenViewed = 'personalize_screen_viewed';
  static const String personalizeOptionsDisplayed = 'personalize_options_displayed';
  static const String personalizeOptionSelected = 'personalize_option_selected';
  static const String personalizeContinueClicked = 'personalize_continue_clicked';
  static const String personalizationCompleted = 'personalization_completed';
  static const String personalizeScreenAbandoned = 'personalize_screen_abandoned';
  static const String personalizeNoOptionsSelected = 'personalize_no_options_selected';
  static const String personalizeScreenSkipped = 'personalize_screen_skipped';
  
  // BSE V2 Final Onboarding Funnel
  static const String bseV2JourneyStarted = 'bse_v2_journey_started';
  static const String bseV2PanVerificationCompleted = 'bse_v2_pan_verification_completed';
  static const String bseV2HolderDetailsScreenViewed = 'bse_v2_holder_details_screen_viewed';
  static const String bseV2HolderDetailsFilled = 'bse_v2_holder_details_filled';
  static const String bseV2HolderDetailsSubmitted = 'bse_v2_holder_details_submitted';
  static const String bseV2BankVerificationScreenViewed = 'bse_v2_bank_verification_screen_viewed';
  static const String bseV2BankDetailsEntered = 'bse_v2_bank_details_entered';
  static const String bseV2BankVerificationCompleted = 'bse_v2_bank_verification_completed';
  static const String bseV2OccupationDetailsScreenViewed = 'bse_v2_occupation_details_screen_viewed';
  static const String bseV2OccupationDetailsFilled = 'bse_v2_occupation_details_filled';
  static const String bseV2OccupationDetailsSubmitted = 'bse_v2_occupation_details_submitted';
  static const String bseV2SignatureScreenViewed = 'bse_v2_signature_screen_viewed';
  static const String bseV2SignatureCompleted = 'bse_v2_signature_completed';
  static const String bseV2NomineeScreenViewed = 'bse_v2_nominee_screen_viewed';
  static const String bseV2NomineeAdded = 'bse_v2_nominee_added';
  static const String bseV2SuccessScreenViewed = 'bse_v2_success_screen_viewed';
  static const String bseV2JourneyCompleted = 'bse_v2_journey_completed';
  static const String bseV2JourneyAbandoned = 'bse_v2_journey_abandoned';
  static const String bseV2HolderDetailsIncomplete = 'bse_v2_holder_details_incomplete';
  static const String bseV2BankVerificationFailed = 'bse_v2_bank_verification_failed';
  static const String bseV2OccupationDetailsIncomplete = 'bse_v2_occupation_details_incomplete';
  static const String bseV2SignatureFailed = 'bse_v2_signature_failed';
  static const String bseV2NomineeSkipped = 'bse_v2_nominee_skipped';
  static const String bseV2JourneyTimeout = 'bse_v2_journey_timeout';

  // Dashboard Engagement Funnel
  static const String dashboardFirstVisit = 'dashboard_first_visit';
  static const String dashboardAssetsLoaded = 'dashboard_assets_loaded';
  static const String dashboardPortfolioViewed = 'dashboard_portfolio_viewed';
  static const String dashboardAssetClicked = 'dashboard_asset_clicked';
  static const String dashboardExplored = 'dashboard_explored';
  static const String dashboardFirstSessionCompleted = 'dashboard_first_session_completed';
  static const String dashboardFirstVisitAbandoned = 'dashboard_first_visit_abandoned';
  static const String dashboardAssetsLoadFailed = 'dashboard_assets_load_failed';
  static const String dashboardNoInteraction = 'dashboard_no_interaction';
  static const String dashboardFirstSessionShort = 'dashboard_first_session_short';
  static const String dashboardScreenViewed = 'dashboard_screen_viewed';
  static const String dashboardBottomTabClicked = 'dashboard_bottom_tab_clicked';
  static const String dashboardAssetCardClicked = 'dashboard_asset_card_clicked';
  static const String dashboardQuickActionClicked = 'dashboard_quick_action_clicked';
  static const String dashboardSearchUsed = 'dashboard_search_used';
  static const String dashboardNavigationCompleted = 'dashboard_navigation_completed';
  static const String dashboardNavigationAbandoned = 'dashboard_navigation_abandoned';
  static const String dashboardSearchFailed = 'dashboard_search_failed';
  static const String dashboardAssetLoadFailed = 'dashboard_asset_load_failed';
  static const String dashboardNavigationConfused = 'dashboard_navigation_confused';

  // Account Linking Funnel
  static const String dataFetchInitiated = 'data_fetch_initiated';
  static const String dataFetchScreenViewed = 'data_fetch_screen_viewed';
  static const String dataFetchProviderSelected = 'data_fetch_provider_selected';
  static const String dataFetchConsentShown = 'data_fetch_consent_shown';
  static const String dataFetchConsentAccepted = 'data_fetch_consent_accepted';
  static const String dataFetchRedirectInitiated = 'data_fetch_redirect_initiated';
  static const String dataFetchProviderCompleted = 'data_fetch_provider_completed';
  static const String dataFetchSyncStarted = 'data_fetch_sync_started';
  static const String dataFetchCompleted = 'data_fetch_completed';
  static const String dataFetchAbandoned = 'data_fetch_abandoned';
  static const String dataFetchConsentDeclined = 'data_fetch_consent_declined';
  static const String dataFetchRedirectFailed = 'data_fetch_redirect_failed';
  static const String dataFetchProviderError = 'data_fetch_provider_error';
  static const String dataFetchSyncFailed = 'data_fetch_sync_failed';
  static const String dataFetchTimeout = 'data_fetch_timeout';
  static const String accountRefreshClicked = 'account_refresh_clicked';

  // Legacy Events (for backward compatibility)
  static const String onboardingGetStartedClicked = 'onboarding_get_started_clicked';

  // Residential Status Screen
  static const String residentialStatusSelected = 'residential_status_selected';
  static const String residentialStatusNextClicked = 'residential_status_next_clicked';

  // Phone Number Input Screen
  static const String phoneNumberOtpSent = 'phone_number_otp_sent';
  static const String phoneNumberOtpSendFailed = 'phone_number_otp_send_failed';

  // OTP Verification Screen
  static const String otpVerifiedFailed = 'otp_verified_failed';
  static const String otpResendClicked = 'otp_resend_clicked';
  static const String otpResendSuccess = 'otp_resend_success';
  static const String otpResendFailure = 'otp_resend_failure';
  static const String phoneNumberEditClicked = 'phone_number_edit_clicked';

  // Email Onboarding (Google Sign-In) Screen
  static const String googleSignInClicked = 'google_sign_in_clicked';
  static const String googleSignInSuccess = 'google_sign_in_success';
  static const String googleSignInFailed = 'google_sign_in_failed';
  static const String googleSignInCancelled = 'google_sign_in_cancelled';

  // PAN Card Verification Screen
  static const String panVerifyButtonClicked = 'pan_verify_button_clicked';
  static const String panVerificationSuccess = 'pan_verification_success';
  static const String panManualEntryClicked = 'pan_manual_entry_clicked';
  static const String panHelpDontKnowClicked = 'pan_help_dont_know_clicked';
  static const String panWhyClicked = 'pan_why_clicked';
  static const String panScreenLogoutClicked = 'pan_screen_logout_clicked';

  // PAN Consent Screen
  static const String panConsentConfirmClicked = 'pan_consent_confirm_clicked';
  static const String panConsentSuccess = 'pan_consent_success';
  static const String panConsentFailed = 'pan_consent_failed';
  static const String panConsentCorrectClicked = 'pan_consent_correct_clicked';

  // PAN Details Screen (Manual Entry)
  static const String panManualSubmitClicked = 'pan_manual_submit_clicked';
  static const String panManualVerificationSuccess = 'pan_manual_verification_success';
  static const String panManualVerificationFailed = 'pan_manual_verification_failed';

  // Dashboard Screen (Main) - Legacy (moved to new section)
  // static const String dashboardScreenViewed = 'dashboard_screen_viewed';
  static const String dashboardPullToRefresh = 'dashboard_pull_to_refresh';
  static const String dashboardAmountVisibilityToggled = 'dashboard_amount_visibility_toggled';
  static const String dashboardFamilyModeToggled = 'dashboard_family_mode_toggled';
  static const String dashboardBackPressExit = 'dashboard_back_press_exit';

  // Dashboard Header
  static const String dashboardAvatarClicked = 'dashboard_avatar_clicked';
  static const String dashboardSearchIconClicked = 'dashboard_search_icon_clicked';
  static const String dashboardNotificationsIconClicked = 'dashboard_notifications_icon_clicked';
  static const String dashboardLogoutDialogShown = 'dashboard_logout_dialog_shown';
  static const String dashboardLogoutConfirmed = 'dashboard_logout_confirmed';
  static const String dashboardLogoutCancelled = 'dashboard_logout_cancelled';

  // Bottom Tab Navigation (Stacked Navbar)
  static const String dashboardBottomTabHomeClicked = 'dashboard_bottom_tab_home_clicked';
  static const String dashboardBottomTabInvestmentsClicked = 'dashboard_bottom_tab_investments_clicked';
  static const String dashboardBottomTabMfHoldingsClicked = 'dashboard_bottom_tab_mf_holdings_clicked';

  // Dashboard Bottom Navigation (Alternative)
  static const String dashboardBottomNavHomeClicked = 'dashboard_bottom_nav_home_clicked';
  static const String dashboardBottomNavInvestmentsClicked = 'dashboard_bottom_nav_investments_clicked';
  static const String dashboardBottomNavMutualFundsClicked = 'dashboard_bottom_nav_mutual_funds_clicked';
  static const String dashboardBottomNavAdvisoryClicked = 'dashboard_bottom_nav_advisory_clicked';

  // Asset Cards Section
  static const String dashboardAssetBanksCardClicked = 'dashboard_asset_banks_card_clicked';
  static const String dashboardAssetInsuranceCardClicked = 'dashboard_asset_insurance_card_clicked';
  static const String dashboardAssetInvestmentsCardClicked = 'dashboard_asset_investments_card_clicked';
  static const String dashboardAssetNpsCardClicked = 'dashboard_asset_nps_card_clicked';
  static const String dashboardAssetMutualFundsCardClicked = 'dashboard_asset_mutual_funds_card_clicked';
  static const String dashboardAssetAddCardClicked = 'dashboard_asset_add_card_clicked';
  static const String dashboardAssetLinkNowClicked = 'dashboard_asset_link_now_clicked';
  static const String dashboardAssetInfoIconClicked = 'dashboard_asset_info_icon_clicked';

  // Spends and Investments Quick Cards
  static const String dashboardSpendsCardClicked = 'dashboard_spends_card_clicked';
  static const String dashboardInvestmentsCardClicked = 'dashboard_investments_card_clicked';

  // Recommendations Section
  static const String dashboardRecommendationFamilyFinanceClicked = 'dashboard_recommendation_family_finance_clicked';
  static const String dashboardRecommendationPaperTradingClicked = 'dashboard_recommendation_paper_trading_clicked';

  // KYC (MFU) Section
  static const String dashboardKycCardClicked = 'dashboard_kyc_card_clicked';

  // Dashboard bootstrap (Finarkein aa/consents)
  static const String dashboardConsentBootstrapCompleted =
      'dashboard_consent_bootstrap_completed';
  static const String dashboardEntryModeDecided =
      'dashboard_entry_mode_decided';

  // Family Finance Section
  static const String dashboardFamilyChartManageClicked = 'dashboard_family_chart_manage_clicked';
  static const String dashboardFamilyModeSwitchClicked = 'dashboard_family_mode_switch_clicked';

  // Link Data Benefits Bottom Sheet
  static const String dashboardLinkDataBottomSheetShown = 'dashboard_link_data_bottom_sheet_shown';
  static const String dashboardLinkDataNowClicked = 'dashboard_link_data_now_clicked';

  // Asset Type Navigation
  static const String dashboardNavigateToBanks = 'dashboard_navigate_to_banks';
  static const String dashboardNavigateToInsurance = 'dashboard_navigate_to_insurance';
  static const String dashboardNavigateToInvestments = 'dashboard_navigate_to_investments';
  static const String dashboardNavigateToNps = 'dashboard_navigate_to_nps';
  static const String dashboardNavigateToMutualFunds = 'dashboard_navigate_to_mutual_funds';
  static const String dashboardNavigateToConnections = 'dashboard_navigate_to_connections';
  static const String dashboardNavigateToSaafeConnection = 'dashboard_navigate_to_saafe_connection';

  // Mutual Funds Service Unavailable
  static const String dashboardMfServiceUnavailableShown = 'dashboard_mf_service_unavailable_shown';

  // Investments Main Screen
  static const String investmentsScreenViewed = 'investments_screen_viewed';
  static const String investmentsPullToRefresh = 'investments_pull_to_refresh';
  static const String investmentsAmountVisibilityToggled = 'investments_amount_visibility_toggled';
  static const String investmentsBackButtonClicked = 'investments_back_button_clicked';

  // Investments Header Section
  static const String investmentsStatusButtonClicked = 'investments_status_button_clicked';
  static const String investmentsSpeakToAdvisorClicked = 'investments_speak_to_advisor_clicked';

  // Category Filter Section
  static const String investmentsCategoryAllSelected = 'investments_category_all_selected';
  static const String investmentsCategoryEquitySelected = 'investments_category_equity_selected';
  static const String investmentsCategoryMutualFundsSelected = 'investments_category_mutual_funds_selected';
  static const String investmentsCategoryEtfSelected = 'investments_category_etf_selected';


  // Nominee Registered Details Section
  static const String investmentsNomineeSpeakToAdvisorClicked = 'investments_nominee_speak_to_advisor_clicked';

  // Mutual Funds Category Actions
  static const String investmentsMfUpdateHoldingsCardClicked = 'investments_mf_update_holdings_card_clicked';
  static const String investmentsMfServiceOutageShown = 'investments_mf_service_outage_shown';
  static const String investmentsMfNavDateInfoShown = 'investments_mf_nav_date_info_shown';

  // Equity Category Actions
  static const String investmentsEquityPriceUpdateInfoShown = 'investments_equity_price_update_info_shown';

  // ETF Category Actions
  static const String investmentsEtfPriceUpdateInfoShown = 'investments_etf_price_update_info_shown';

  // Mutual Fund Holding Card
  static const String investmentsMfHoldingCardClicked = 'investments_mf_holding_card_clicked';
  static const String investmentsMfHoldingFundNameClicked = 'investments_mf_holding_fund_name_clicked';
  static const String investmentsMfHoldingTransactionsClicked = 'investments_mf_holding_transactions_clicked';
  static const String investmentsMfHoldingAvgBuyPriceInfoClicked = 'investments_mf_holding_avg_buy_price_info_clicked';
  static const String investmentsMfHoldingXirrInfoClicked = 'investments_mf_holding_xirr_info_clicked';

  // Stock Holding Card
  static const String investmentsStockHoldingCardClicked = 'investments_stock_holding_card_clicked';
  static const String investmentsStockHoldingTransactionsClicked = 'investments_stock_holding_transactions_clicked';
  static const String investmentsStockHoldingAvgBuyPriceEditClicked = 'investments_stock_holding_avg_buy_price_edit_clicked';
  static const String investmentsStockHoldingAvgBuyPriceEditSaved = 'investments_stock_holding_avg_buy_price_edit_saved';
  static const String investmentsStockHoldingAvgBuyPriceEditCancelled = 'investments_stock_holding_avg_buy_price_edit_cancelled';
  static const String investmentsStockHoldingAvgBuyPriceInfoClicked = 'investments_stock_holding_avg_buy_price_info_clicked';
  static const String investmentsStockHoldingXirrInfoClicked = 'investments_stock_holding_xirr_info_clicked';

  // ETF Holding Card
  static const String investmentsEtfHoldingCardClicked = 'investments_etf_holding_card_clicked';
  static const String investmentsEtfHoldingTransactionsClicked = 'investments_etf_holding_transactions_clicked';
  static const String investmentsEtfHoldingAvgBuyPriceEditClicked = 'investments_etf_holding_avg_buy_price_edit_clicked';
  static const String investmentsEtfHoldingAvgBuyPriceEditSaved = 'investments_etf_holding_avg_buy_price_edit_saved';
  static const String investmentsEtfHoldingAvgBuyPriceEditCancelled = 'investments_etf_holding_avg_buy_price_edit_cancelled';
  static const String investmentsEtfHoldingAvgBuyPriceInfoClicked = 'investments_etf_holding_avg_buy_price_info_clicked';
  static const String investmentsEtfHoldingXirrInfoClicked = 'investments_etf_holding_xirr_info_clicked';

  // Investments Tab - Filtering and Search
  static const String investmentsSearchInitiated = 'investments_search_initiated';
  static const String investmentsSearchQueryEntered = 'investments_search_query_entered';

  // Investments Tab - Navigation
  static const String investmentsNavigateToSaafeDataFetch = 'investments_navigate_to_saafe_data_fetch';

  // Account Linking Bottom Sheet
  static const String investmentsAccountLinkBottomSheetShown = 'investments_account_link_bottom_sheet_shown';
  static const String investmentsAccountLinkNowClicked = 'investments_account_link_now_clicked';

  // Empty State
  static const String investmentsNoHoldingsShown = 'investments_no_holdings_shown';

  // Error States
  static const String investmentsPortfolioFetchFailed = 'investments_portfolio_fetch_failed';
  static const String investmentsHoldingsFetchFailed = 'investments_holdings_fetch_failed';

  // Data Fetch Status Screen
  static const String dataFetchStatusScreenViewed = 'data_fetch_status_screen_viewed';
  static const String dataFetchStatusBackButtonClicked = 'data_fetch_status_back_button_clicked';
  static const String dataFetchStatusInfoIconClicked = 'data_fetch_status_info_icon_clicked';
  static const String dataFetchStatusTabAccountsClicked = 'data_fetch_status_tab_accounts_clicked';
  static const String dataFetchStatusTabMutualFundsClicked = 'data_fetch_status_tab_mutual_funds_clicked';
  static const String dataFetchStatusManualRefreshInitiated = 'data_fetch_status_manual_refresh_initiated';
  static const String dataFetchStatusManualRefreshSuccess = 'data_fetch_status_manual_refresh_success';
  static const String dataFetchStatusManualRefreshFailed = 'data_fetch_status_manual_refresh_failed';
  static const String dataFetchStatusManualRefreshDisabledClicked = 'data_fetch_status_manual_refresh_disabled_clicked';
  static const String dataFetchStatusLastFetchViewed = 'data_fetch_status_last_fetch_viewed';
  static const String dataFetchStatusLinkNowAccountsClicked = 'data_fetch_status_link_now_accounts_clicked';
  static const String dataFetchStatusLinkNowMutualFundsClicked = 'data_fetch_status_link_now_mutual_funds_clicked';
  static const String dataFetchStatusAccountCardViewed = 'data_fetch_status_account_card_viewed';
  static const String dataFetchStatusAccountCardClicked = 'data_fetch_status_account_card_clicked';
  static const String dataFetchStatusMfUpdateAvailableCardViewed = 'data_fetch_status_mf_update_available_card_viewed';
  static const String dataFetchStatusMfOutdatedWarningCardViewed = 'data_fetch_status_mf_outdated_warning_card_viewed';
  static const String dataFetchStatusMfUpdateNowClicked = 'data_fetch_status_mf_update_now_clicked';
  static const String dataFetchStatusServiceOutageCardViewed = 'data_fetch_status_service_outage_card_viewed';
  static const String dataFetchStatusInfoBottomSheetOpened = 'data_fetch_status_info_bottom_sheet_opened';
  static const String dataFetchStatusInfoBottomSheetClosed = 'data_fetch_status_info_bottom_sheet_closed';
  static const String dataFetchStatusLoadingStarted = 'data_fetch_status_loading_started';
  static const String dataFetchStatusLoadingCompleted = 'data_fetch_status_loading_completed';
  static const String dataFetchStatusLoadingFailed = 'data_fetch_status_loading_failed';
  static const String dataFetchStatusPollingStarted = 'data_fetch_status_polling_started';
  static const String dataFetchStatusPollingStopped = 'data_fetch_status_polling_stopped';
  static const String dataFetchStatusPollingUpdateReceived = 'data_fetch_status_polling_update_received';

  // Profile and Settings
  static const String userProfileDataProtectionClicked = 'user_profile_data_protection_clicked';
  static const String userProfilePrivacyPolicyClicked = 'user_profile_privacy_policy_clicked';
  static const String userProfileTermsConditionsClicked = 'user_profile_terms_conditions_clicked';
  static const String userProfileBiometricLockToggled = 'user_profile_biometric_lock_toggled';
  static const String userProfileLogoutClicked = 'user_profile_logout_clicked';
  static const String userProfileLogoutCancelled = 'user_profile_logout_cancelled';
  static const String userProfileLogoutConfirmed = 'user_profile_logout_confirmed';
  static const String userProfileFinancialProfilingClicked = 'user_profile_financial_profiling_clicked';
  static const String userProfileSetPinClicked = 'user_profile_set_pin_clicked';
  static const String userProfileHelpFaqClicked = 'user_profile_help_faq_clicked';

  // Set PIN
  static const String userProfilePinSetSuccess = 'user_profile_pin_set_success';
  static const String userProfilePinMismatchError = 'user_profile_pin_mismatch_error';
  static const String userProfilePinIncompleteError = 'user_profile_pin_incomplete_error';
  static const String userProfilePinSkipClicked = 'user_profile_pin_skip_clicked';

  // Personalize Experience Screen
  static const String personalizeExperienceScreenViewed = 'personalize_experience_screen_viewed';
  static const String personalizeExperienceOptionSelected = 'personalize_experience_option_selected';
  static const String personalizeExperienceOptionDeselected = 'personalize_experience_option_deselected';
  static const String personalizeExperienceContinueClicked = 'personalize_experience_continue_clicked';
  static const String personalizeExperienceContinueSuccess = 'personalize_experience_continue_success';
  static const String personalizeExperienceContinueFailed = 'personalize_experience_continue_failed';
  static const String personalizeExperienceLogoutClicked = 'personalize_experience_logout_clicked';
  static const String personalizeExperienceLogoutConfirmed = 'personalize_experience_logout_confirmed';
  static const String personalizeExperienceOptionDisplayed = 'personalize_experience_option_displayed';

  // Unlock Portfolio Screen
  static const String unlockPortfolioScreenViewed = 'unlock_portfolio_screen_viewed';
  static const String unlockPortfolioUnlockButtonClicked = 'unlock_portfolio_unlock_button_clicked';
  static const String unlockPortfolioBackClicked = 'unlock_portfolio_back_clicked';
  static const String unlockPortfolioSkipToDashboard = 'unlock_portfolio_skip_to_dashboard';

  // Email OTP Verification - Legacy (moved to new section)
  // static const String emailOtpScreenViewed = 'email_otp_screen_viewed';
  static const String emailOtpContinueClicked = 'email_otp_continue_clicked';
  static const String emailOtpSendSuccess = 'email_otp_send_success';
  static const String emailOtpSendFailed = 'email_otp_send_failed';
  static const String emailOtpVerifySuccess = 'email_otp_verify_success';
  static const String emailOtpVerifyFailed = 'email_otp_verify_failed';
  static const String emailOtpResendClicked = 'email_otp_resend_clicked';
  static const String emailOtpEditEmailClicked = 'email_otp_edit_email_clicked';

  // Email OTP Verification Screen - Legacy (moved to new section)
  // static const String emailOtpEntered = 'email_otp_entered';
  static const String emailOtpVerifyClicked = 'email_otp_verify_clicked';
  static const String emailOtpVerified = 'email_otp_verified';
  static const String emailOtpResendSuccess = 'email_otp_resend_success';
  static const String emailOtpResendFailure = 'email_otp_resend_failure';
  static const String emailOtpEditClicked = 'email_otp_edit_clicked';

  // Unlinked State Widgets
  static const String dashboardUnlockCardViewed = 'dashboard_unlock_card_viewed';
  static const String dashboardUnlockCardClicked = 'dashboard_unlock_card_clicked';
  static const String dashboardSetupCarouselViewed = 'dashboard_setup_carousel_viewed';
  static const String dashboardSetupTaskCardClicked = 'dashboard_setup_task_card_clicked';
  static const String dashboardPivotInfoLearnMoreClicked = 'dashboard_pivot_info_learn_more_clicked';
  static const String dashboardUnlinkedCtaClicked = 'dashboard_unlinked_cta_clicked';
  static const String dashboardScrollDepthReached = 'dashboard_scroll_depth_reached';

  // Sell Holdings
  static const String sellHoldingsBackClicked = 'sell_holdings_back_clicked';

  // Investments
  static const String holdingCardEditClicked = 'holding_card_edit_clicked';

  // Paper Trading
  static const String paperTradingEditClicked = 'paper_trading_edit_clicked';

  // MF Top Performers
  static const String mfTopPerformersInfoIconClicked = 'mf_top_performers_info_icon_clicked';
}

/// Firebase Analytics parameter names
class AnalyticsParams {
  // Common parameters
  static const String errorMessage = 'error_message';
  static const String errorCode = 'error_code';
  
  // Onboarding parameters
  static const String pageIndex = 'page_index';
  
  // Residential status parameters
  static const String status = 'status';
  static const String selectedStatus = 'selected_status';
  
  // Phone number parameters
  static const String phoneNumberLength = 'phone_number_length';
  static const String countryCode = 'country_code';
  
  // OTP parameters
  static const String phoneNumber = 'phone_number';
  static const String isAutoFilled = 'is_auto_filled';
  static const String verificationMethod = 'verification_method';
  static const String timeSinceLastSend = 'time_since_last_send';
  
  // Google Sign-In parameters
  static const String email = 'email';
  
  // PAN parameters
  static const String panValid = 'pan_valid';
  
  // Dashboard parameters
  static const String screenName = 'screen_name';
  static const String userType = 'user_type';
  static const String isFamilyMode = 'is_family_mode';
  static const String tabIndex = 'tab_index';
  static const String tabName = 'tab_name';
  static const String previousTabIndex = 'previous_tab_index';
  static const String assetType = 'asset_type';
  static const String isLinked = 'is_linked';
  static const String assetAmount = 'asset_amount';
  static const String destinationScreen = 'destination_screen';
  static const String navigationMethod = 'navigation_method';
  static const String previousMode = 'previous_mode';
  static const String newMode = 'new_mode';
  static const String isVisible = 'is_visible';
  static const String previousVisibility = 'previous_visibility';
  static const String isAmountVisible = 'is_amount_visible';

  // Dashboard bootstrap parameters
  static const String bootstrapSuccess = 'bootstrap_success';
  static const String bootstrapDurationMs = 'bootstrap_duration_ms';
  static const String bootstrapHasAnyConsent = 'bootstrap_has_any_consent';
  static const String dashboardEntryMode = 'dashboard_entry_mode';

  // Investments parameters
  static const String categoryName = 'category_name';
  static const String previousCategory = 'previous_category';
  static const String holdingsCount = 'holdings_count';
  static const String searchQueryLength = 'search_query_length';
  static const String searchResultsCount = 'search_results_count';
  static const String searchCategory = 'search_category';
  static const String investmentType = 'investment_type';
  static const String isinCode = 'isin_code';
  static const String fundName = 'fund_name';
  static const String marketValue = 'market_value';
  static const String gainLossPercentage = 'gain_loss_percentage';
  static const String transactionCount = 'transaction_count';
  static const String oldPrice = 'old_price';
  static const String newPrice = 'new_price';
  static const String priceChangePercentage = 'price_change_percentage';
  static const String sourceCategory = 'source_category';
  static const String errorType = 'error_type';
  static const String retryAttempted = 'retry_attempted';
  static const String portfolioValue = 'portfolio_value';
  static const String entryPoint = 'entry_point';
  static const String mfNavDate = 'mf_nav_date';
  static const String stockPriceUpdateTime = 'stock_price_update_time';
  static const String etfPriceUpdateTime = 'etf_price_update_time';
  static const String mfcServiceStatus = 'mfc_service_status';

  // Data Fetch Status parameters
  static const String tabSelected = 'tab_selected';
  static const String previousTab = 'previous_tab';
  static const String newTab = 'new_tab';
  static const String adhocRemaining = 'adhoc_remaining';
  static const String refreshCount = 'refresh_count';
  static const String tabContext = 'tab_context';
  static const String accountType = 'account_type';
  static const String accountStatus = 'account_status';
  static const String fipName = 'fip_name';
  static const String lastFetchDate = 'last_fetch_date';
  static const String lastFetchDateMfc = 'last_fetch_date_mfc';
  static const String canFetchMfc = 'can_fetch_mfc';
  static const String hasMfAccounts = 'has_mf_accounts';
  static const String loadingDurationSeconds = 'loading_duration_seconds';
  static const String accountsCount = 'accounts_count';
  static const String pollingIntervalSeconds = 'polling_interval_seconds';
  static const String accountsFetchingCount = 'accounts_fetching_count';
  static const String pollingDurationSeconds = 'polling_duration_seconds';
  static const String serviceName = 'service_name';
  static const String isMfcWorking = 'is_mfc_working';
  static const String appState = 'app_state';
  static const String timeInBackgroundSeconds = 'time_in_background_seconds';

  // New parameters
  static const String optionTitle = 'option_title';
  static const String selectedOption = 'selected_option';
  static const String emailDomain = 'email_domain';
  static const String taskTitle = 'task_title';

  // Personalize Experience parameters
  static const String optionIndex = 'option_index';
  static const String flowType = 'flow_type';
  static const String timeOnScreenSeconds = 'time_on_screen_seconds';
  static const String isDisplayedToUser = 'is_displayed_to_user';
  static const String scrollDepthPercent = 'scroll_depth_percent';
  static const String selectedFlowType = 'selected_flow_type';
  static const String timeToDecisionSeconds = 'time_to_decision_seconds';
}
