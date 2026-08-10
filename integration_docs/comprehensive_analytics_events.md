# Comprehensive CleverTap Events List for NWT Mobile Application

## Overview
This document outlines all the CleverTap events that should be implemented for the active screens in the Networth Tracker mobile application. The events are organized by feature/module for better tracking and analysis.

## Event Naming Convention
- All events follow `snake_case` convention
- Format: `[feature]_[screen]_[action]`
- Examples: `advisory_screen_viewed`, `bse_onboarding_step_completed`

---

## 1. ONBOARDING & AUTHENTICATION

### 1.1 Splash & Welcome
- `splash_screen_viewed`
- `welcome_get_started_clicked`

### 1.2 Phone & OTP Verification
- `phone_number_screen_viewed`
- `phone_number_submitted`
- `otp_screen_viewed`
- `otp_entered`
- `otp_verified_success`
- `otp_verified_failed`
- `otp_resend_clicked`
- `phone_number_edit_clicked`

### 1.3 Email & Google Sign-In
- `email_screen_viewed`
- `email_submitted`
- `email_otp_sent`
- `email_otp_verified`
- `google_sign_in_clicked`
- `google_sign_in_success`
- `google_sign_in_failed`

### 1.4 PAN Verification
- `pan_screen_viewed`
- `pan_manual_entry_clicked`
- `pan_scanned`
- `pan_verified_success`
- `pan_verified_failed`
- `pan_consent_shown`
- `pan_consent_accepted`

### 1.5 Personalization
- `personalize_experience_screen_viewed`
- `personalize_option_selected`
- `personalize_continue_clicked`

---

## 2. BSE STAR & BSE V2 FINAL ONBOARDING

### 2.1 BSE V2 Final Flow
- `bse_v2_journey_started`
- `bse_v2_pan_verification_completed`
- `bse_v2_holder_details_screen_viewed`
- `bse_v2_holder_details_submitted`
- `bse_v2_bank_verification_screen_viewed`
- `bse_v2_bank_verification_completed`
- `bse_v2_occupation_details_screen_viewed`
- `bse_v2_occupation_details_submitted`
- `bse_v2_signature_screen_viewed`
- `bse_v2_signature_completed`
- `bse_v2_nominee_screen_viewed`
- `bse_v2_nominee_added`
- `bse_v2_success_screen_viewed`
- `bse_v2_journey_completed`
- `bse_v2_ucc_wizard_screen_viewed`
- `bse_v2_ucc_generated`

---

## 3. DASHBOARD & HOME

### 3.1 Main Dashboard
- `dashboard_screen_viewed`
- `dashboard_pull_to_refresh`
- `dashboard_amount_visibility_toggled`
- `dashboard_family_mode_toggled`
- `dashboard_avatar_clicked`
- `dashboard_search_clicked`
- `dashboard_notifications_clicked`

### 3.2 Asset Cards
- `dashboard_asset_banks_card_clicked`
- `dashboard_asset_insurance_card_clicked`
- `dashboard_asset_investments_card_clicked`
- `dashboard_asset_nps_card_clicked`
- `dashboard_asset_mutual_funds_card_clicked`
- `dashboard_asset_add_card_clicked`
- `dashboard_asset_link_now_clicked`

### 3.3 Quick Actions
- `dashboard_spends_card_clicked`
- `dashboard_investments_card_clicked`
- `dashboard_recommendations_clicked`
- `dashboard_kyc_card_clicked`

### 3.4 Bottom Navigation
- `dashboard_bottom_tab_home_clicked`
- `dashboard_bottom_tab_investments_clicked`
- `dashboard_bottom_tab_insights_clicked`
- `dashboard_bottom_tab_advisory_clicked`

---

## 4. INVESTMENTS & PORTFOLIO

### 4.1 Investments Main Screen
- `investments_screen_viewed`
- `investments_pull_to_refresh`
- `investments_amount_visibility_toggled`
- `investments_status_button_clicked`
- `investments_speak_to_advisor_clicked`

### 4.2 Category Filters
- `investments_category_all_selected`
- `investments_category_equity_selected`
- `investments_category_mutual_funds_selected`
- `investments_category_etf_selected`

### 4.3 Holding Cards
- `investments_holding_card_clicked`
- `investments_holding_transactions_clicked`
- `investments_holding_details_viewed`
- `investments_holding_edit_clicked`

### 4.4 Investment Activity
- `investment_activity_screen_viewed`
- `investment_activity_filter_selected`
- `investment_activity_transaction_clicked`

### 4.5 Paper Trading
- `paper_trading_screen_viewed`
- `paper_trading_choose_strategy_clicked`
- `paper_trading_portfolio_viewed`
- `paper_trading_simulator_started`
- `paper_trading_history_viewed`

---

## 5. MUTUAL FUNDS (MF CENTRAL)

### 5.1 MF Central Flow
- `mf_central_trigger_clicked`
- `mf_central_qr_displayed`
- `mf_central_webview_loaded`
- `mf_central_fetching_started`
- `mf_central_sync_completed`
- `mf_central_linked_accounts_viewed`

### 5.2 MF Holdings
- `mf_holdings_screen_viewed`
- `mf_holding_card_clicked`
- `mf_fund_details_viewed`
- `mf_transactions_viewed`
- `mf_nav_date_info_viewed`

### 5.3 MF Actions
- `mf_buy_clicked`
- `mf_sell_clicked`
- `mf_sip_started`
- `mf_sip_paused`
- `mf_redemption_initiated`

---

## 6. EQUITY & STOCKS

### 6.1 Equity Holdings
- `equity_holdings_screen_viewed`
- `equity_holding_card_clicked`
- `equity_company_details_viewed`
- `equity_price_update_info_viewed`

### 6.2 Stock Actions
- `stock_buy_clicked`
- `stock_sell_clicked`
- `stock_price_alert_set`
- `stock_news_viewed`

### 6.3 ETF Holdings
- `etf_holdings_screen_viewed`
- `etf_holding_card_clicked`
- `etf_details_viewed`
- `etf_price_update_info_viewed`

---

## 7. BANKS & DEPOSITS

### 7.1 Banks Main
- `banks_screen_viewed`
- `banks_pull_to_refresh`
- `banks_amount_visibility_toggled`

### 7.2 Bank Details
- `bank_details_screen_viewed`
- `bank_account_clicked`
- `bank_transactions_viewed`
- `bank_balance_viewed`

### 7.3 Deposits
- `deposits_screen_viewed`
- `deposit_card_clicked`
- `deposit_details_viewed`
- `deposit_maturity_viewed`

---

## 8. INSURANCE

### 8.1 Insurance Main
- `insurance_screen_viewed`
- `insurance_pull_to_refresh`
- `insurance_amount_visibility_toggled`

### 8.2 Insurance Details
- `insurance_details_screen_viewed`
- `insurance_policy_clicked`
- `insurance_premium_viewed`
- `insurance_claims_viewed`
- `insurance_transactions_viewed`

---

## 9. ADVISORY & RECOMMENDATIONS

### 9.1 Advisory Main
- `advisory_screen_viewed`
- `advisory_intelligence_viewed`
- `advisory_strategic_review_viewed`

### 9.2 Equity Advisory
- `equity_advisory_screen_viewed`
- `equity_strategy_selected`
- `equity_basket_preview_viewed`
- `equity_order_placed`

### 9.3 Tax Advisory
- `tax_advisory_screen_viewed`
- `tax_recommendation_viewed`
- `tax_optimization_clicked`

### 9.4 Document Handling
- `advisory_document_previewed`
- `advisory_esign_initiated`
- `advisory_esign_completed`
- `advisory_document_downloaded`

---

## 10. INSIGHTS & ANALYTICS

### 10.1 Insights Main
- `insights_screen_viewed`
- `insights_portfolio_analyzed`
- `insights_asset_allocation_viewed`
- `insights_sector_allocation_viewed`

### 10.2 Fund Details
- `fund_details_widget_viewed`
- `fund_performance_analyzed`
- `fund_holdings_viewed`
- `fund_dividend_history_viewed`

### 10.3 SIP Details
- `sip_details_widget_viewed`
- `sip_performance_analyzed`
- `sip_installments_viewed`

### 10.4 Risk Analysis
- `riskometer_widget_viewed`
- `risk_analysis_completed`
- `risk_recommendation_viewed`

### 10.5 Actions
- `buy_direct_fund_clicked`
- `sell_fund_clicked`
- `fund_added_to_watchlist`

---

## 11. ORDERS & TRANSACTIONS

### 11.1 Order Management
- `orders_screen_viewed`
- `order_history_viewed`
- `order_status_checked`
- `order_cancelled`

### 11.2 Create Order
- `create_order_screen_viewed`
- `order_details_filled`
- `order_payment_initiated`
- `order_confirmation_viewed`

### 11.3 Payment Processing
- `payment_processing_screen_viewed`
- `payment_method_selected`
- `payment_completed`
- `payment_failed`

### 11.4 Order Types
- `buy_order_placed`
- `sell_order_placed`
- `sip_order_placed`
- `redemption_order_placed`

---

## 12. PERSONAL ASSETS

### 12.1 Personal Assets Main
- `personal_assets_screen_viewed`
- `personal_assets_category_selected`
- `personal_assets_added`
- `personal_assets_edited`

### 12.2 Asset Types
- `real_estate_screen_viewed`
- `real_estate_property_added`
- `land_screen_viewed`
- `land_property_added`
- `precious_metals_screen_viewed`
- `metals_holdings_added`
- `crypto_screen_viewed`
- `crypto_holdings_added`
- `money_lent_screen_viewed`
- `lending_records_added`
- `others_assets_screen_viewed`
- `other_assets_added`

---

## 13. DATA FETCH & ACCOUNT LINKING

### 13.1 SAAFE Data Fetch
- `saafe_data_fetch_screen_viewed`
- `saafe_consent_given`
- `saafe_accounts_linked`
- `saafe_data_synced`

### 13.2 Data Fetch Status
- `data_fetch_status_screen_viewed`
- `data_fetch_tab_selected`
- `data_fetch_refresh_initiated`
- `data_fetch_account_clicked`
- `data_fetch_link_now_clicked`

### 13.3 Account Management
- `account_linking_initiated`
- `account_verification_completed`
- `account_refresh_triggered`
- `account_disconnected`

---

## 14. PROFILE & SETTINGS

### 14.1 User Profile
- `user_profile_screen_viewed`
- `profile_edit_clicked`
- `profile_updated`
- `profile_photo_changed`

### 14.2 Security Settings
- `biometrics_setup_viewed`
- `biometrics_enabled`
- `pin_setup_viewed`
- `pin_created`
- `pin_changed`
- `pin_reset`

### 14.3 Account Settings
- `account_details_viewed`
- `data_protection_viewed`
- `privacy_policy_viewed`
- `terms_conditions_viewed`
- `help_faq_viewed`

### 14.4 App Settings
- `settings_screen_viewed`
- `notifications_configured`
- `dark_mode_toggled`
- `language_changed`
- `app_version_checked`

---

## 15. SEARCH & DISCOVERY

### 15.1 Global Search
- `global_search_screen_viewed`
- `search_query_entered`
- `search_results_viewed`
- `search_filter_applied`
- `search_result_clicked`

### 15.2 Search Categories
- `search_funds_clicked`
- `search_stocks_clicked`
- `search_articles_clicked`
- `search_help_clicked`

---

## 16. NOTIFICATIONS & MESSAGES

### 16.1 Push Notifications
- `notification_received`
- `notification_clicked`
- `notification_dismissed`
- `notification_settings_opened`

### 16.2 In-App Messages
- `in_app_message_shown`
- `in_app_message_clicked`
- `in_app_message_dismissed`

---

## 17. ERROR STATES & EXCEPTIONS

### 17.1 Network Errors
- `network_error_occurred`
- `api_request_failed`
- `timeout_error_occurred`
- `retry_attempted`

### 17.2 App Errors
- `app_crash_reported`
- `unexpected_error_occurred`
- `feature_not_available`
- `maintenance_mode_active`

---

## 18. USER ENGAGEMENT & RETENTION

### 18.1 Session Tracking
- `app_session_started`
- `app_session_ended`
- `screen_time_tracked`
- `deep_link_opened`

### 18.2 Feature Adoption
- `feature_first_used`
- `feature_usage_frequency`
- `feature_completion_rate`
- `feature_abandonment`

---

## Implementation Guidelines

### 1. Event Parameters
Each event should include relevant parameters:
- `screen_name`: Current screen
- `user_id`: User identifier
- `timestamp`: Event timestamp
- `session_id`: Session identifier
- Feature-specific parameters (amount, category, etc.)

### 2. User Properties
Set user properties for better segmentation:
- `user_type`: Individual/Family
- `kyc_status`: Verified/Pending
- `account_linked`: Yes/No
- `portfolio_value`: Current portfolio value
- `registration_date`: User registration date

### 3. Screen View Tracking
Implement screen view tracking for all major screens:
```dart
AnalyticsService.to.logScreenView(screenName: 'investments_main');
```

### 4. Event Tracking Pattern
Follow consistent pattern for event tracking:
```dart
AnalyticsService.to.logEvent(
  name: AnalyticsEvents.investmentsScreenViewed,
  parameters: {
    AnalyticsParams.screenName: 'investments_main',
    AnalyticsParams.categoryName: 'equity',
    AnalyticsParams.portfolioValue: '1000000',
  },
);
```

### 5. Error Handling
Always wrap analytics calls in try-catch blocks:
```dart
try {
  AnalyticsService.to.logEvent(name: eventName, parameters: params);
} catch (e) {
  AppLogger.error('Analytics error: $e');
}
```

---

## Priority Implementation Order

### Phase 1 (High Priority)
1. Dashboard & Navigation events
2. Investments & Portfolio events
3. User Authentication events
4. MF Central events

### Phase 2 (Medium Priority)
1. Advisory & Insights events
2. Orders & Transactions events
3. Profile & Settings events
4. Search & Discovery events

### Phase 3 (Low Priority)
1. Personal Assets events
2. Error & Exception events
3. User Engagement events
4. Notification events

---

## Testing & Validation

1. **Event Verification**: Use CleverTap debug mode to verify events are firing
2. **Parameter Validation**: Ensure all required parameters are included
3. **Event Naming**: Follow consistent naming convention
4. **Performance**: Ensure analytics calls don't impact app performance
5. **Privacy**: Ensure no sensitive user data is tracked

---

## Maintenance & Updates

1. **Regular Review**: Review events quarterly for relevance
2. **New Features**: Add events for new features immediately
3. **Deprecated Events**: Remove or update deprecated events
4. **Documentation**: Keep this document updated with changes
5. **Team Training**: Ensure development team follows guidelines
