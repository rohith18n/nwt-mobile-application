# User Journey & Drop-off Analytics Events

## Overview
This document focuses on analytics events specifically designed to track user journeys and identify drop-off points in the NWT mobile application. The events are organized by user funnels to help understand where users abandon the app and optimize conversion rates.

## Key User Funnels & Drop-off Points

---

## 1. ONBOARDING FUNNEL (Critical Drop-off Zone)

### 1.1 App Launch & Welcome
**Funnel Steps:**
1. `app_launched` - App opened
2. `splash_screen_viewed` - Splash screen shown
3. `welcome_screen_viewed` - Welcome screen displayed
4. `get_started_clicked` - User clicks Get Started
5. `welcome_screen_completed` - User proceeds to phone verification

**Drop-off Events:**
- `welcome_screen_abandoned` - User closes app on welcome screen
- `welcome_screen_time_exceeded` - User spends >2 minutes without action

### 1.2 Phone Verification Funnel
**Funnel Steps:**
1. `phone_screen_viewed` - Phone number screen shown
2. `phone_number_entered` - User enters phone number
3. `phone_submit_clicked` - User clicks Send OTP
4. `otp_sent_success` - OTP sent successfully
5. `otp_screen_viewed` - OTP screen displayed
6. `otp_entered` - User enters OTP
7. `otp_verified_success` - OTP verified successfully
8. `phone_verification_completed` - Phone verification complete

**Drop-off Events:**
- `phone_screen_abandoned` - User exits on phone entry
- `phone_number_invalid` - Invalid phone number entered
- `otp_send_failed` - OTP not sent (network/server error)
- `otp_screen_abandoned` - User exits on OTP screen
- `otp_verification_failed` - OTP verification fails
- `otp_resend_clicked` - User requests new OTP (potential drop-off)
- `otp_max_attempts_reached` - User fails OTP verification multiple times

### 1.3 Email Verification Funnel
**Funnel Steps:**
1. `email_screen_viewed` - Email screen shown
2. `email_entered` - User enters email
3. `email_submit_clicked` - User submits email
4. `email_otp_sent` - Email OTP sent
5. `email_otp_screen_viewed` - Email OTP screen shown
6. `email_otp_entered` - User enters email OTP
7. `email_verified_success` - Email verified
8. `email_verification_completed` - Email verification complete

**Drop-off Events:**
- `email_screen_abandoned` - User exits on email screen
- `email_otp_not_received` - User doesn't receive email OTP
- `email_verification_failed` - Email OTP verification fails
- `email_skip_clicked` - User chooses to skip email verification

### 1.4 PAN Verification Funnel
**Funnel Steps:**
1. `pan_screen_viewed` - PAN verification screen shown
2. `pan_method_selected` - User chooses scan/manual entry
3. `pan_scanned` - PAN card scanned successfully
4. `pan_manual_entered` - PAN entered manually
5. `pan_submit_clicked` - User submits PAN
6. `pan_verification_processing` - PAN verification in progress
7. `pan_verified_success` - PAN verified successfully
8. `pan_consent_shown` - PAN consent displayed
9. `pan_consent_accepted` - User accepts consent
10. `pan_verification_completed` - PAN verification complete

**Drop-off Events:**
- `pan_screen_abandoned` - User exits on PAN screen
- `pan_scan_failed` - PAN scanning fails
- `pan_manual_entry_failed` - Manual PAN entry fails
- `pan_verification_failed` - PAN verification fails
- `pan_consent_declined` - User declines PAN consent
- `pan_verification_timeout` - PAN verification times out

### 1.5 Personalization Funnel
**Funnel Steps:**
1. `personalize_screen_viewed` - Personalization screen shown
2. `personalize_options_displayed` - Options displayed to user
3. `personalize_option_selected` - User selects options
4. `personalize_continue_clicked` - User clicks continue
5. `personalization_completed` - Personalization complete

**Drop-off Events:**
- `personalize_screen_abandoned` - User exits on personalization
- `personalize_no_options_selected` - User doesn't select any options
- `personalize_screen_skipped` - User skips personalization

---

## 2. BSE V2 FINAL ONBOARDING FUNNEL

### 2.1 BSE V2 Journey Funnel
**Funnel Steps:**
1. `bse_v2_journey_started` - User starts BSE V2 onboarding
2. `bse_v2_pan_verification_completed` - PAN verification completed
3. `bse_v2_holder_details_screen_viewed` - Holder details screen shown
4. `bse_v2_holder_details_filled` - User fills holder details
5. `bse_v2_holder_details_submitted` - User submits holder details
6. `bse_v2_bank_verification_screen_viewed` - Bank verification screen shown
7. `bse_v2_bank_details_entered` - User enters bank details
8. `bse_v2_bank_verification_completed` - Bank verification completed
9. `bse_v2_occupation_details_screen_viewed` - Occupation screen shown
10. `bse_v2_occupation_details_filled` - User fills occupation details
11. `bse_v2_occupation_details_submitted` - User submits occupation details
12. `bse_v2_signature_screen_viewed` - Signature screen shown
13. `bse_v2_signature_completed` - User completes signature
14. `bse_v2_nominee_screen_viewed` - Nominee screen shown
15. `bse_v2_nominee_added` - User adds nominee
16. `bse_v2_success_screen_viewed` - Success screen shown
17. `bse_v2_journey_completed` - BSE V2 journey completed

**Drop-off Events:**
- `bse_v2_journey_abandoned` - User abandons BSE V2 journey
- `bse_v2_holder_details_incomplete` - Incomplete holder details
- `bse_v2_bank_verification_failed` - Bank verification fails
- `bse_v2_occupation_details_incomplete` - Incomplete occupation details
- `bse_v2_signature_failed` - Signature fails
- `bse_v2_nominee_skipped` - User skips nominee addition
- `bse_v2_journey_timeout` - Journey times out

---

## 3. DASHBOARD ENGAGEMENT FUNNEL

### 3.1 First Dashboard Visit Funnel
**Funnel Steps:**
1. `dashboard_first_visit` - User's first dashboard visit
2. `dashboard_assets_loaded` - Assets loaded successfully
3. `dashboard_portfolio_viewed` - User views portfolio
4. `dashboard_asset_clicked` - User clicks on an asset
5. `dashboard_explored` - User explores dashboard features
6. `dashboard_first_session_completed` - First dashboard session complete

**Drop-off Events:**
- `dashboard_first_visit_abandoned` - User abandons first dashboard visit
- `dashboard_assets_load_failed` - Assets fail to load
- `dashboard_no_interaction` - User doesn't interact with dashboard
- `dashboard_first_session_short` - Session lasts <30 seconds

### 3.2 Dashboard Navigation Funnel
**Funnel Steps:**
1. `dashboard_screen_viewed` - Dashboard screen viewed
2. `dashboard_bottom_tab_clicked` - User clicks bottom tab
3. `dashboard_asset_card_clicked` - User clicks asset card
4. `dashboard_quick_action_clicked` - User clicks quick action
5. `dashboard_search_used` - User uses search
6. `dashboard_navigation_completed` - User navigates successfully

**Drop-off Events:**
- `dashboard_navigation_abandoned` - User abandons navigation
- `dashboard_search_failed` - Search fails or returns no results
- `dashboard_asset_load_failed` - Asset details fail to load
- `dashboard_navigation_confused` - User seems lost (multiple rapid clicks)

---

## 4. ACCOUNT LINKING FUNNEL

### 4.1 Data Fetch Initiation Funnel
**Funnel Steps:**
1. `data_fetch_initiated` - User starts data fetch process
2. `data_fetch_screen_viewed` - Data fetch screen viewed
3. `data_fetch_provider_selected` - User selects data provider
4. `data_fetch_consent_shown` - Consent screen shown
5. `data_fetch_consent_accepted` - User accepts consent
6. `data_fetch_redirect_initiated` - Redirect to provider initiated
7. `data_fetch_provider_completed` - Provider process completed
8. `data_fetch_sync_started` - Data sync started
9. `data_fetch_completed` - Data fetch completed successfully

**Drop-off Events:**
- `data_fetch_abandoned` - User abandons data fetch
- `data_fetch_consent_declined` - User declines consent
- `data_fetch_redirect_failed` - Redirect to provider fails
- `data_fetch_provider_error` - Provider returns error
- `data_fetch_sync_failed` - Data sync fails
- `data_fetch_timeout` - Data fetch times out

### 4.2 Account Status Funnel
**Funnel Steps:**
1. `account_status_screen_viewed` - Account status screen viewed
2. `account_status_checked` - User checks account status
3. `account_refresh_clicked` - User clicks refresh
4. `account_refresh_completed` - Account refresh completed
5. `account_details_viewed` - User views account details

**Drop-off Events:**
- `account_status_abandoned` - User abandons account status check
- `account_refresh_failed` - Account refresh fails
- `account_details_load_failed` - Account details fail to load

---

## 5. INVESTMENT JOURNEY FUNNEL

### 5.1 Investment Discovery Funnel
**Funnel Steps:**
1. `investments_screen_viewed` - Investments screen viewed
2. `investment_category_selected` - User selects investment category
3. `investment_holdings_viewed` - User views holdings
4. `investment_details_viewed` - User views investment details
5. `investment_analytics_viewed` - User views investment analytics

**Drop-off Events:**
- `investments_screen_abandoned` - User abandons investments screen
- `investment_category_not_selected` - User doesn't select category
- `investment_holdings_load_failed` - Holdings fail to load
- `investment_details_load_failed` - Investment details fail to load

### 5.2 Mutual Fund Investment Funnel
**Funnel Steps:**
1. `mf_central_initiated` - User starts MF Central process
2. `mf_central_qr_displayed` - QR code displayed
3. `mf_central_scanned` - QR code scanned
4. `mf_central_authenticated` - User authenticates with MF Central
5. `mf_central_accounts_linked` - Accounts linked successfully
6. `mf_holdings_synced` - MF holdings synced
7. `mf_portfolio_viewed` - User views MF portfolio

**Drop-off Events:**
- `mf_central_abandoned` - User abandons MF Central process
- `mf_central_qr_not_scanned` - QR code not scanned
- `mf_central_authentication_failed` - Authentication fails
- `mf_central_linking_failed` - Account linking fails
- `mf_holdings_sync_failed` - Holdings sync fails

### 5.3 Investment Action Funnel
**Funnel Steps:**
1. `investment_action_initiated` - User starts investment action
2. `investment_type_selected` - User selects investment type
3. `investment_amount_entered` - User enters investment amount
4. `investment_confirmed` - User confirms investment
5. `investment_payment_initiated` - Payment initiated
6. `investment_completed` - Investment completed successfully

**Drop-off Events:**
- `investment_action_abandoned` - User abandons investment action
- `investment_amount_invalid` - Invalid investment amount
- `investment_confirmation_cancelled` - User cancels confirmation
- `investment_payment_failed` - Payment fails
- `investment_timeout` - Investment process times out

---

## 6. ADVISORY & RECOMMENDATIONS FUNNEL

### 6.1 Advisory Discovery Funnel
**Funnel Steps:**
1. `advisory_screen_viewed` - Advisory screen viewed
2. `advisory_category_selected` - User selects advisory category
3. `advisory_recommendations_viewed` - User views recommendations
4. `advisory_details_viewed` - User views advisory details
5. `advisory_action_initiated` - User initiates advisory action

**Drop-off Events:**
- `advisory_screen_abandoned` - User abandons advisory screen
- `advisory_no_category_selected` - User doesn't select category
- `advisory_recommendations_load_failed` - Recommendations fail to load
- `advisory_details_load_failed` - Advisory details fail to load

### 6.2 Advisory Implementation Funnel
**Funnel Steps:**
1. `advisory_implementation_started` - User starts implementation
2. `advisory_strategy_selected` - User selects strategy
3. `advisory_portfolio_analyzed` - Portfolio analyzed
4. `advisory_orders_created` - Orders created
5. `advisory_orders_executed` - Orders executed
6. `advisory_implementation_completed` - Implementation completed

**Drop-off Events:**
- `advisory_implementation_abandoned` - User abandons implementation
- `advisory_strategy_not_selected` - User doesn't select strategy
- `advisory_portfolio_analysis_failed` - Portfolio analysis fails
- `advisory_order_creation_failed` - Order creation fails
- `advisory_order_execution_failed` - Order execution fails

---

## 7. ORDER & TRANSACTION FUNNEL

### 7.1 Order Creation Funnel
**Funnel Steps:**
1. `order_creation_initiated` - User starts order creation
2. `order_type_selected` - User selects order type
3. `order_details_entered` - User enters order details
4. `order_review_started` - Order review started
5. `order_confirmed` - Order confirmed
6. `order_payment_initiated` - Payment initiated
7. `order_completed` - Order completed

**Drop-off Events:**
- `order_creation_abandoned` - User abandons order creation
- `order_type_not_selected` - User doesn't select order type
- `order_details_invalid` - Invalid order details
- `order_review_cancelled` - User cancels during review
- `order_payment_failed` - Payment fails
- `order_execution_failed` - Order execution fails

### 7.2 Payment Processing Funnel
**Funnel Steps:**
1. `payment_initiated` - Payment initiated
2. `payment_method_selected` - User selects payment method
3. `payment_details_entered` - User enters payment details
4. `payment_processing_started` - Payment processing started
5. `payment_completed` - Payment completed

**Drop-off Events:**
- `payment_abandoned` - User abandons payment
- `payment_method_not_selected` - User doesn't select payment method
- `payment_details_invalid` - Invalid payment details
- `payment_processing_failed` - Payment processing fails
- `payment_timeout` - Payment times out

---

## 8. USER RETENTION & ENGAGEMENT FUNNEL

### 8.1 Daily Engagement Funnel
**Funnel Steps:**
1. `daily_session_started` - Daily session started
2. `dashboard_viewed` - Dashboard viewed
3. `portfolio_checked` - Portfolio checked
4. `transactions_viewed` - Transactions viewed
5. `actions_taken` - User takes actions
6. `daily_session_completed` - Daily session completed

**Drop-off Events:**
- `daily_session_abandoned` - User abandons daily session
- `portfolio_not_checked` - User doesn't check portfolio
- `no_actions_taken` - User doesn't take any actions
- `daily_session_very_short` - Session lasts <10 seconds

### 8.2 Feature Adoption Funnel
**Funnel Steps:**
1. `feature_discovered` - User discovers new feature
2. `feature_explored` - User explores feature
3. `feature_used` - User uses feature
4. `feature_value_realized` - User realizes value
5. `feature_adopted` - Feature adopted into routine

**Drop-off Events:**
- `feature_not_discovered` - User doesn't discover feature
- `feature_not_explored` - User doesn't explore feature
- `feature_not_used` - User doesn't use feature
- `feature_value_not_realized` - User doesn't realize value
- `feature_abandoned` - User abandons feature

---

## 9. CRITICAL DROP-OFF IDENTIFICATION

### 9.1 High-Risk Drop-off Points
1. **Phone Verification** (40-60% drop-off rate)
   - OTP not received
   - OTP entry errors
   - Network issues

2. **PAN Verification** (30-50% drop-off rate)
   - PAN scanning failures
   - Consent refusal
   - Verification timeouts

3. **Bank Account Linking** (35-55% drop-off rate)
   - Bank selection issues
   - OTP failures
   - Connection timeouts

4. **First Investment** (60-80% drop-off rate)
   - Analysis paralysis
   - Amount uncertainty
   - Payment failures

5. **MF Central Onboarding** (45-65% drop-off rate)
   - QR scanning issues
   - Authentication failures
   - Sync failures

### 9.2 Drop-off Event Categories
- **Technical Issues**: Network errors, server failures, timeouts
- **User Confusion**: Complex UI, unclear instructions, too many options
- **Trust Issues**: Security concerns, data privacy worries
- **Friction Points**: Too many steps, lengthy processes, mandatory fields
- **External Dependencies**: Bank APIs, third-party services, verification services

---

## 10. IMPLEMENTATION STRATEGY

### 10.1 Funnel Tracking Implementation
```dart
// Example: Phone verification funnel tracking
class PhoneVerificationTracker {
  static void trackPhoneScreenViewed() {
    AnalyticsService.to.logEvent(
      name: 'phone_screen_viewed',
      parameters: {
        'screen_name': 'phone_verification',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': getSessionId(),
      },
    );
  }
  
  static void trackPhoneScreenAbandoned() {
    AnalyticsService.to.logEvent(
      name: 'phone_screen_abandoned',
      parameters: {
        'time_on_screen': getTimeOnScreen(),
        'reason': 'user_exit',
        'session_id': getSessionId(),
      },
    );
  }
}
```

### 10.2 Drop-off Detection Logic
```dart
class DropOffDetector {
  static Timer? _dropOffTimer;
  
  static void startDropOffTracking(String screenName) {
    _dropOffTimer?.cancel();
    _dropOffTimer = Timer(Duration(minutes: 2), () {
      AnalyticsService.to.logEvent(
        name: '${screenName}_time_exceeded',
        parameters: {
          'screen_name': screenName,
          'time_limit_exceeded': '2_minutes',
        },
      );
    });
  }
  
  static void stopDropOffTracking() {
    _dropOffTimer?.cancel();
  }
}
```

### 10.3 Funnel Analysis Dashboard
- Track conversion rates for each funnel step
- Identify bottlenecks and drop-off points
- Monitor funnel performance over time
- A/B test improvements to reduce drop-offs

---

## 11. MONITORING & OPTIMIZATION

### 11.1 Key Metrics to Monitor
- **Funnel Conversion Rates**: Percentage of users completing each step
- **Drop-off Rates**: Percentage of users abandoning at each step
- **Time to Complete**: Average time to complete each funnel
- **Error Rates**: Percentage of users encountering errors
- **Retry Rates**: Percentage of users retrying after failure

### 11.2 Optimization Strategies
1. **Simplify Processes**: Reduce steps and complexity
2. **Improve Onboarding**: Better guidance and instructions
3. **Enhance Error Handling**: Clear error messages and recovery options
4. **Optimize Performance**: Faster loading times and responses
5. **Build Trust**: Better security indicators and privacy explanations

### 11.3 A/B Testing Framework
- Test different UI variations
- Test different process flows
- Test different messaging strategies
- Measure impact on conversion rates

---

## 12. ALERTS & NOTIFICATIONS

### 12.1 Real-time Drop-off Alerts
- Alert when drop-off rate exceeds threshold
- Alert when technical errors spike
- Alert when funnel performance degrades
- Alert when new drop-off patterns emerge

### 12.2 Daily/Weekly Reports
- Funnel performance summaries
- Drop-off analysis reports
- Conversion trend analysis
- Optimization recommendations

---

This focused analytics approach will help you identify exactly where users are dropping off and enable data-driven improvements to increase conversion rates and user retention.
