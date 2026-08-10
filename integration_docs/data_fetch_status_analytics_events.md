# Data Fetch Status Analytics Events List

A comprehensive list of user actions to track during the Data Fetch Status screen flow, organized by screen with descriptive event names.

## Events by Screen

### 1. Data Fetch Status Screen (Main)

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_screen_viewed`
- **Action**: User views the Data Fetch Status screen
- **Location**: Line 329 (`build` method) - should be logged in `initState` or when screen first appears

- **Event**: `data_fetch_status_back_button_clicked`
- **Action**: User clicks back button to navigate to dashboard
- **Location**: Line 339 (`onTap` in GestureDetector with chevron_left icon)

- **Event**: `data_fetch_status_info_icon_clicked`
- **Action**: User clicks info icon to view data update information (currently commented out)
- **Location**: Line 349-352 (commented out `_showInfoBottomSheet` call)

---

### 2. Tab Toggle Section

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_tab_accounts_clicked`
- **Action**: User clicks on "Accounts" tab to view account data
- **Location**: Line 393 (`onTap` in GestureDetector for Accounts tab)

- **Event**: `data_fetch_status_tab_mutual_funds_clicked`
- **Action**: User clicks on "Mutual Funds" tab to view mutual fund data
- **Location**: Line 419 (`onTap` in GestureDetector for Mutual Funds tab)

---

### 3. Manual Refresh Section

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_manual_refresh_initiated`
- **Action**: User clicks manual refresh button to trigger adhoc data refresh
- **Location**: Line 641 (`onTap` in InkWell for refresh button)

- **Event**: `data_fetch_status_manual_refresh_success`
- **Action**: Manual refresh completes successfully
- **Location**: Line 251 (`_fetchFipStatus` after successful refresh in `hadHocRefresh` method)

- **Event**: `data_fetch_status_manual_refresh_failed`
- **Action**: Manual refresh fails due to error
- **Location**: Line 252-257 (`catch` block in `hadHocRefresh` method)

- **Event**: `data_fetch_status_manual_refresh_disabled_clicked`
- **Action**: User clicks refresh button when no refreshes are available (button is disabled)
- **Location**: Line 639-640 (when `_adhocRemaining.value <= 0`)

---

### 4. Last Fetch Container

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_last_fetch_viewed`
- **Action**: User views the last fetch information container
- **Location**: Line 672 (`_buildLastFetchContainer` method) - should be logged when container is displayed

---

### 5. Link Now Button (Empty States)

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_link_now_accounts_clicked`
- **Action**: User clicks "Link Now" button on Accounts tab when no accounts are linked
- **Location**: Line 812 (`onTap` in InkWell for Link Now button when `isAccountsTab == true`)

- **Event**: `data_fetch_status_link_now_mutual_funds_clicked`
- **Action**: User clicks "Link Now" button on Mutual Funds tab when no mutual funds are linked
- **Location**: Line 813-822 (`onTap` in InkWell for Link Now button when `isAccountsTab == false`)

---

### 6. Account Status Cards

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_account_card_viewed`
- **Action**: User views an account status card (for each account displayed)
- **Location**: Line 979 (`_buildFetchStatusCard` method) - should be logged when card is displayed

- **Event**: `data_fetch_status_account_card_clicked`
- **Action**: User clicks on an account status card (if card is clickable)
- **Location**: Currently no click handler, but should be added if cards become interactive

---

### 7. Mutual Funds Tab - Update Available Card

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_mf_update_available_card_viewed`
- **Action**: User views the "UPDATE AVAILABLE" card on Mutual Funds tab
- **Location**: Line 2017 (`_buildMFUpdateAvailableCard` method) - should be logged when card is displayed

---

### 8. Mutual Funds Tab - Outdated Warning Card

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_mf_outdated_warning_card_viewed`
- **Action**: User views the outdated warning card on Mutual Funds tab
- **Location**: Line 2082 (`_buildMFOutdatedWarningCard` method) - should be logged when card is displayed

- **Event**: `data_fetch_status_mf_update_now_clicked`
- **Action**: User clicks "Update Now" button in the outdated warning card
- **Location**: Line 2103 (`onPressed` in ElevatedButton)

---

### 9. Service Outage Card

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_service_outage_card_viewed`
- **Action**: User views the service outage card when MFC service is down
- **Location**: Line 502-504 (ServiceOutageCard widget) - should be logged when card is displayed

---

### 10. Info Bottom Sheet

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_info_bottom_sheet_opened`
- **Action**: User opens the info bottom sheet to view data update information
- **Location**: Line 1071 (`_showInfoBottomSheet` method) - currently commented out but should be tracked when implemented

- **Event**: `data_fetch_status_info_bottom_sheet_closed`
- **Action**: User closes the info bottom sheet
- **Location**: Line 1072 (`showModalBottomSheet` dismiss) - should be tracked when bottom sheet is dismissed

---

### 11. Data Loading States

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_loading_started`
- **Action**: Initial data loading begins when screen is opened
- **Location**: Line 97 (`_loadData` method)

- **Event**: `data_fetch_status_loading_completed`
- **Action**: Initial data loading completes successfully
- **Location**: Line 171 (`_fetchFipStatus` after successful response)

- **Event**: `data_fetch_status_loading_failed`
- **Action**: Initial data loading fails
- **Location**: Line 198-200 (`catch` block in `_fetchFipStatus`)

---

### 12. Polling Events

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_polling_started`
- **Action**: Automatic polling for FIP status updates begins
- **Location**: Line 110 (`_startPolling` method)

- **Event**: `data_fetch_status_polling_stopped`
- **Action**: Automatic polling stops (when no accounts are fetching)
- **Location**: Line 135 (`_stopPolling` method)

- **Event**: `data_fetch_status_polling_update_received`
- **Action**: Polling successfully fetches updated FIP status
- **Location**: Line 122 (`_fetchFipStatus` called during polling)

---

### 13. App Lifecycle Events

- **Screen**: Data Fetch Status (`lib/screens/saafe_data_fetch_status/saafe_data_fetch.dart`)
- **Event**: `data_fetch_status_app_resumed`
- **Action**: App resumes and polling restarts
- **Location**: Line 277 (`didChangeAppLifecycleState` when state is `resumed`)

- **Event**: `data_fetch_status_app_paused`
- **Action**: App is paused/inactive and polling stops
- **Location**: Line 282-285 (`didChangeAppLifecycleState` when state is `paused` or `inactive`)

---

## Summary Count

**Total Events: 24 events across 13 screen sections**

1. Data Fetch Status Screen (Main): 3 events
2. Tab Toggle Section: 2 events
3. Manual Refresh Section: 4 events
4. Last Fetch Container: 1 event
5. Link Now Button (Empty States): 2 events
6. Account Status Cards: 2 events
7. Mutual Funds Tab - Update Available Card: 1 event
8. Mutual Funds Tab - Outdated Warning Card: 2 events
9. Service Outage Card: 1 event
10. Info Bottom Sheet: 2 events
11. Data Loading States: 3 events
12. Polling Events: 3 events
13. App Lifecycle Events: 2 events

## Implementation Notes

- All events use snake_case naming convention
- Event names are descriptive and indicate the action (not just generic "clicked")
- Success/failed events are separate for better analytics segmentation
- Events should be defined in `lib/constants/analytics.dart` before implementation
- All events use the unified AnalyticsService (one call triggers Firebase, CleverTap, and AppsFlyer)
- Screen view events should be logged when the screen first appears (in `initState` or `didChangeDependencies`)
- Loading events should include timing information
- Polling events should include account status information

## Recommended Parameters

### Common Parameters
- `screen_name`: Name of the current screen ("data_fetch_status")
- `tab_selected`: Currently selected tab ("accounts" or "mutual_funds")
- `user_id`: User identifier (if available)

### Tab Toggle Parameters
- `previous_tab`: Previously selected tab ("accounts" or "mutual_funds")
- `new_tab`: Newly selected tab ("accounts" or "mutual_funds")

### Manual Refresh Parameters
- `adhoc_remaining`: Number of refreshes remaining before action
- `refresh_count`: Total number of refreshes used (if available)
- `error_message`: Error message if refresh fails
- `error_code`: Error code if refresh fails

### Link Now Button Parameters
- `tab_context`: Tab where button was clicked ("accounts" or "mutual_funds")
- `destination_screen`: Screen navigated to ("saafe_connection" or "mutual_fund_holdings_journey")

### Account Card Parameters
- `account_type`: Type of account (e.g., "DEPOSIT", "EQUITIES", "MUTUAL_FUNDS")
- `account_status`: Fetch status of account ("SUCCESS", "FAILED", "FETCHING")
- `fip_name`: Name of the Financial Information Provider
- `last_fetch_date`: Last successful fetch date/time

### MF Update Parameters
- `last_fetch_date_mfc`: Last fetch date from MFC
- `can_fetch_mfc`: Whether user can fetch MFC data
- `has_mf_accounts`: Whether user has mutual fund accounts

### Loading Parameters
- `loading_duration_seconds`: Time taken to load data
- `accounts_count`: Number of accounts loaded
- `error_type`: Type of error if loading fails

### Polling Parameters
- `polling_interval_seconds`: Interval between polling attempts
- `accounts_fetching_count`: Number of accounts currently in fetching status
- `polling_duration_seconds`: Total time polling was active

### Service Outage Parameters
- `service_name`: Name of the service that is down ("mfc" or "aa")
- `is_mfc_working`: Boolean indicating if MFC service is working

### App Lifecycle Parameters
- `app_state`: Current app state ("resumed", "paused", "inactive")
- `time_in_background_seconds`: Time spent in background (if available)
