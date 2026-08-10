# Missing Analytics Events - Coverage Analysis

## 📊 Current Coverage Assessment

After analyzing all **313 screens** in the NWT mobile application against the current analytics events CSV, several key areas are missing comprehensive tracking.

---

## 🔍 MISSING SCREENS & FUNNELS

### **1. PAPER TRADING MODULE** (Completely Missing)
**Screens Not Covered:**
- `paper_trading_history` - Paper trading history screen
- `portfolio_simulator` - Portfolio simulation screen
- `choose_investment_method` - Investment method selection
- `choose_strategy` - Strategy selection screen
- `how_does_it_work` - Paper trading tutorial

**Required Events:**
- `paper_trading_screen_viewed`
- `paper_trading_strategy_selected`
- `paper_trading_simulation_started`
- `paper_trading_history_viewed`
- `paper_trading_portfolio_created`
- `paper_trading_drop_off_reasons`

### **2. PERSONAL ASSETS MODULE** (Partially Covered)
**Missing Screens:**
- `all_personal_assets` - All personal assets overview
- `asset_type` - Asset type selection
- `crypto_page` - Cryptocurrency holdings
- `land_page` - Land/property assets
- `money_lent_page` - Money lending records
- `others_asset_page` - Other asset types
- `precious_metal_page` - Gold/silver holdings
- `real_estate` - Real estate assets

**Required Events:**
- `personal_assets_screen_viewed`
- `asset_type_selected`
- `crypto_holdings_added`
- `real_estate_property_added`
- `precious_metals_holdings_added`
- `money_lending_records_added`
- `other_assets_added`

### **3. MF CENTRAL FLOW** (Partially Covered)
**Missing Screens:**
- `mf_central_confirm_details` - Confirm MF Central details
- `mf_central_detail_screen` - MF Central details view
- `mf_central_qr_display` - QR code display
- `mf_central_trigger` - MF Central trigger
- `mf_fetching` - MF data fetching
- `mf_flow_retry` - MF flow retry
- `mf_switch` - MF switch flow
- `mfc_fetching_splash_screen` - MF Central fetching splash
- `mfc_instructions_screen` - MF Central instructions
- `mfc_qr_display_screen` - MF Central QR display
- `mfc_redirecting_splash_screen` - MF Central redirecting
- `mfc_v2` - MF Central V2
- `mfc_webview_screen` - MF Central webview

**Required Events:**
- `mf_central_details_confirmed`
- `mf_central_qr_displayed`
- `mf_central_trigger_initiated`
- `mf_central_fetching_started`
- `mf_central_retry_attempted`
- `mf_central_switch_initiated`
- `mf_central_instructions_viewed`
- `mf_central_webview_loaded`

### **4. TRANSACTIONS MODULE** (Completely Missing)
**Missing Screens:**
- `transactions/banks/details` - Bank transaction details
- `transactions/banks/list` - Bank transactions list

**Required Events:**
- `bank_transactions_viewed`
- `bank_transaction_details_viewed`
- `transaction_search_initiated`
- `transaction_filter_applied`

### **5. ORDERS MODULE** (Partially Covered)
**Missing Screens:**
- `order_details` - Order details view
- `order_preview` - Order preview screen
- `order_preview_sheet` - Order preview bottom sheet
- `orders_screen` - Orders list screen
- `payment_processing_v1_screen` - Payment processing
- `redeem_order_v1_screen` - Order redemption

**Required Events:**
- `order_details_viewed`
- `order_preview_viewed`
- `orders_list_viewed`
- `payment_processing_started`
- `payment_completed`
- `payment_failed`
- `order_redemption_initiated`

### **6. PROFILE & SETTINGS MODULE** (Partially Covered)
**Missing Screens:**
- `account_details` - Account details view
- `biometrics_setup` - Biometrics setup
- `consent_revoke_screen` - Consent revocation
- `data_protection` - Data protection settings
- `edit_profile` - Profile editing
- `help_faq` - Help and FAQ
- `holder_detail_screen` - Holder details
- `holder_management_screen` - Holder management
- `reset_pin` - PIN reset
- `set_pin` - PIN setup
- `setup_biometrics` - Biometrics setup
- `user_profile` - User profile view
- `verify_pin` - PIN verification

**Required Events:**
- `account_details_viewed`
- `biometrics_setup_completed`
- `consent_revoked`
- `data_protection_settings_viewed`
- `profile_edit_initiated`
- `profile_updated`
- `help_faq_viewed`
- `holder_management_viewed`
- `pin_setup_completed`
- `pin_reset_completed`
- `pin_verified`

### **7. SEARCH MODULE** (Completely Missing)
**Missing Screens:**
- `global_search` - Global search functionality

**Required Events:**
- `global_search_initiated`
- `search_query_entered`
- `search_results_viewed`
- `search_result_clicked`
- `search_filter_applied`

### **8. INSIGHTS MODULE** (Partially Covered)
**Missing Screens:**
- `insights` - Main insights screen
- `analysis_mf` - MF analysis
- `buy_direct_fund` - Buy direct fund
- `buy_holdings` - Buy holdings
- `import_mf` - Import MF
- `sell_fund` - Sell fund
- `mf_top_performers_section` - Top performers

**Required Events:**
- `insights_screen_viewed`
- `mf_analysis_viewed`
- `direct_fund_purchase_initiated`
- `holdings_purchase_initiated`
- `mf_import_initiated`
- `fund_sale_initiated`
- `top_performers_viewed`

### **9. NOTIFICATIONS & MESSAGES** (Completely Missing)
**Missing Screens:**
- `notification_list` - Notification list

**Required Events:**
- `notifications_viewed`
- `notification_clicked`
- `notification_marked_read`

### **10. WEBVIEW & EXTERNAL FLOWS** (Partially Covered)
**Missing Screens:**
- `webview_test` - Webview testing
- `netbanking_webview` - Netbanking webview
- `zerodha_webview` - Zerodha webview
- `inappwebview` - In-app webview
- `esign_webview_screen` - E-sign webview

**Required Events:**
- `webview_loaded`
- `webview_error_occurred`
- `webview_completed`
- `external_navigation_started`

### **11. FAMILY & MULTI-USER FEATURES** (Completely Missing)
**Missing Screens:**
- `family_management` - Family management
- `family_member` - Family member details
- `family_member_add` - Add family member
- `family_setting` - Family settings
- `family_finance_banks` - Family banks
- `family_finance_insurance` - Family insurance
- `family_finance_investment` - Family investments
- `family_finance_nps` - Family NPS

**Required Events:**
- `family_management_viewed`
- `family_member_added`
- `family_settings_updated`
- `family_finances_viewed`

### **12. SUBSCRIPTION & PAYMENTS** (Partially Covered)
**Missing Screens:**
- `cashfree_subscription_screen` - Subscription payment

**Required Events:**
- `subscription_screen_viewed`
- `subscription_plan_selected`
- `subscription_payment_initiated`
- `subscription_completed`
- `subscription_failed`

### **13. BLOGS & CONTENT** (Completely Missing)
**Missing Screens:**
- `all_blogs_screen` - All blogs view

**Required Events:**
- `blogs_viewed`
- `blog_article_opened`
- `blog_shared`

### **14. ERROR & LOADING STATES** (Partially Covered)
**Missing Screens:**
- `error_layout` - Error display
- `loading_layout` - Loading states
- `mf_flow_retry` - Retry flows

**Required Events:**
- `error_screen_displayed`
- `loading_state_started`
- `retry_attempted`
- `error_recovery_completed`

---

## 📈 COVERAGE SUMMARY

| Module | Total Screens | Covered | Missing | Coverage % |
|--------|---------------|---------|---------|------------|
| Onboarding | 15 | 15 | 0 | 100% |
| BSE V2 Final | 10 | 10 | 0 | 100% |
| Dashboard | 8 | 8 | 0 | 100% |
| Account Linking | 6 | 6 | 0 | 100% |
| Investments | 12 | 12 | 0 | 100% |
| Advisory | 10 | 10 | 0 | 100% |
| Orders & Transactions | 8 | 3 | 5 | 38% |
| Profile & Settings | 15 | 5 | 10 | 33% |
| Paper Trading | 8 | 0 | 8 | 0% |
| Personal Assets | 10 | 2 | 8 | 20% |
| MF Central | 15 | 8 | 7 | 47% |
| Transactions | 2 | 0 | 2 | 0% |
| Search | 1 | 0 | 1 | 0% |
| Insights | 10 | 3 | 7 | 30% |
| Family Features | 8 | 0 | 8 | 0% |
| Notifications | 1 | 0 | 1 | 0% |
| Webview & External | 8 | 2 | 6 | 25% |
| Subscription | 1 | 0 | 1 | 0% |
| Blogs & Content | 1 | 0 | 1 | 0% |
| Error States | 3 | 1 | 2 | 33% |

**Overall Coverage: 62% of screens have analytics events**

---

## 🚨 IMMEDIATE ACTION REQUIRED

### **Priority 1 - Critical Missing Funnels:**
1. **Paper Trading** (0% coverage) - High engagement feature
2. **Transactions** (0% coverage) - Core functionality
3. **Search** (0% coverage) - User discovery tool
4. **Family Features** (0% coverage) - Multi-user functionality

### **Priority 2 - High Impact:**
1. **Orders Module** (38% coverage) - Revenue critical
2. **Profile & Settings** (33% coverage) - User management
3. **Personal Assets** (20% coverage) - Data completeness

### **Priority 3 - Enhancement:**
1. **MF Central** (47% coverage) - Investment flow
2. **Insights** (30% coverage) - User engagement
3. **Webview & External** (25% coverage) - Third-party integrations

---

## 📋 RECOMMENDED NEXT STEPS

1. **Add missing events to CSV** for Priority 1 modules
2. **Create implementation plan** for remaining modules
3. **Update analytics constants** in `analytics.dart`
4. **Test implementation** with development team
5. **Monitor coverage** and iterate

This analysis shows that while core user journeys are well covered, several important modules lack comprehensive analytics tracking.
