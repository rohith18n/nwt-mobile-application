# Dashboard Analytics Events List

A comprehensive list of user actions to track during the Dashboard flow, organized by screen with descriptive event names.

## Events by Screen

### 1. Dashboard Screen (Main)

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_screen_viewed`
- **Action**: User views the dashboard screen
- **Location**: Line 1729 (build method)

- **Event**: `dashboard_pull_to_refresh`
- **Action**: User performs pull-to-refresh gesture to refresh dashboard data
- **Location**: Line 1752 (`_performRefresh` method)

- **Event**: `dashboard_amount_visibility_toggled`
- **Action**: User toggles visibility of amount values (show/hide)
- **Location**: Method `_toggleAmountVisibility` (around line 294-360)

- **Event**: `dashboard_family_mode_toggled`
- **Action**: User toggles between Family Mode and Personal Mode
- **Location**: Line 212 (`toggleFamilyMode` method)

- **Event**: `dashboard_back_press_exit`
- **Action**: User presses back button twice to exit the app
- **Location**: Line 1722 (`_onWillPop` method)

---

### 2. Dashboard Header

- **Screen**: Dashboard Header (`lib/screens/dashboard/components/dashboard_header.dart`)
- **Event**: `dashboard_avatar_clicked`
- **Action**: User clicks on avatar/profile picture to view logout dialog
- **Location**: Line 36-37 (`_showLogoutDialog`)

- **Event**: `dashboard_search_icon_clicked`
- **Action**: User clicks search icon to navigate to global search
- **Location**: Line 71-76 (`Get.to(() => GlobalSearchScreen())`)

- **Event**: `dashboard_notifications_icon_clicked`
- **Action**: User clicks notifications icon to view notifications
- **Location**: Line 82-87 (`Get.to(() => NotificationListScreen())`)

- **Event**: `dashboard_logout_dialog_shown`
- **Action**: Logout confirmation dialog is displayed
- **Location**: Line 97 (`_showLogoutDialog` method)

- **Event**: `dashboard_logout_confirmed`
- **Action**: User confirms logout from the dialog
- **Location**: Line 121-128 (logout button in dialog)

- **Event**: `dashboard_logout_cancelled`
- **Action**: User cancels logout from the dialog
- **Location**: Line 114 (`Navigator.pop(context)`)

---

### 3. Bottom Tab Navigation (Stacked Navbar)

- **Screen**: Stacked Navbar (`lib/widgets/main/stacked_navbar.dart`)
- **Event**: `dashboard_bottom_tab_home_clicked`
- **Action**: User clicks Home tab in bottom navigation
- **Location**: Line 82-85 (`onTap` when index == 0)

- **Event**: `dashboard_bottom_tab_investments_clicked`
- **Action**: User clicks Investments tab in bottom navigation
- **Location**: Line 82-85 (`onTap` when index == 1)

- **Event**: `dashboard_bottom_tab_mf_holdings_clicked`
- **Action**: User clicks MF Holdings tab in bottom navigation
- **Location**: Line 82-85 (`onTap` when index == 2)

---

### 4. Dashboard Bottom Navigation (Alternative)

- **Screen**: Dashboard Bottom Nav (`lib/screens/dashboard/components/dashboard_bottom_nav.dart`)
- **Event**: `dashboard_bottom_nav_home_clicked`
- **Action**: User clicks Home tab (index 0)
- **Location**: Line 33 (`onTap` when index == 0)

- **Event**: `dashboard_bottom_nav_investments_clicked`
- **Action**: User clicks Investments tab and navigates to AssetInvestmentScreen
- **Location**: Line 37-42 (`onTap` when index == 1)

- **Event**: `dashboard_bottom_nav_mutual_funds_clicked`
- **Action**: User clicks Mutual Funds tab and navigates to MutualFunds screen
- **Location**: Line 43-45 (`onTap` when index == 2)

- **Event**: `dashboard_bottom_nav_advisory_clicked`
- **Action**: User clicks Advisory tab and navigates to AdvisoryScreen
- **Location**: Line 46-51 (`onTap` when index == 3)

---

### 5. Asset Cards Section

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_asset_banks_card_clicked`
- **Action**: User clicks on Banks asset card
- **Location**: Line 3422-3436 (`_buildModernAssetItem` with assetType == "banks")

- **Event**: `dashboard_asset_insurance_card_clicked`
- **Action**: User clicks on Insurance asset card
- **Location**: Line 3422-3436 (`_buildModernAssetItem` with assetType == "insurance")

- **Event**: `dashboard_asset_investments_card_clicked`
- **Action**: User clicks on Investments asset card
- **Location**: Line 3422-3436 (`_buildModernAssetItem` with assetType == "investments")

- **Event**: `dashboard_asset_nps_card_clicked`
- **Action**: User clicks on NPS asset card
- **Location**: Line 3422-3436 (`_buildModernAssetItem` with assetType == "nps")

- **Event**: `dashboard_asset_mutual_funds_card_clicked`
- **Action**: User clicks on Mutual Funds asset card
- **Location**: Line 3433-3463 (`_buildModernAssetItem` with assetType == "mutualfunds")

- **Event**: `dashboard_asset_add_card_clicked`
- **Action**: User clicks on "Add" asset card to link new accounts
- **Location**: Line 3428-3432 (`_buildModernAssetItem` with assetType == "add")

- **Event**: `dashboard_asset_link_now_clicked`
- **Action**: User clicks "Link Now" button on unlinked asset card
- **Location**: Line 2612-2617 (GestureDetector for unlinked investments)

- **Event**: `dashboard_asset_info_icon_clicked`
- **Action**: User clicks info icon on asset card to view details
- **Location**: Line 3500-3516 (InkWell with info icon)

---

### 6. Spends and Investments Quick Cards

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_spends_card_clicked`
- **Action**: User clicks on Spends quick action card
- **Location**: Line 2063-2065 (GestureDetector for spends card)

- **Event**: `dashboard_investments_card_clicked`
- **Action**: User clicks on Investments quick action card
- **Location**: Line 2521-2532 (InkWell for investments card)

---

### 7. Recommendations Section

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_recommendation_family_finance_clicked`
- **Action**: User clicks on "One Dashboard. Full Control" recommendation card
- **Location**: Line 165-169 (`onTap` in recommendation map)

- **Event**: `dashboard_recommendation_paper_trading_clicked`
- **Action**: User clicks on "Paper Trading Portfolio" recommendation card
- **Location**: Line 181-185 (`onTap` in recommendation map)

---

### 8. Family Finance Section

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_family_chart_manage_clicked`
- **Action**: User clicks "Manage" button on family finance chart
- **Location**: Line 2271-2280 (InkWell with "Manage" text)

- **Event**: `dashboard_family_mode_switch_clicked`
- **Action**: User toggles family mode switch (if visible)
- **Location**: Line 2218 (`onChanged` in CustomSwitch)

---

### 9. Link Data Benefits Bottom Sheet

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_link_data_bottom_sheet_shown`
- **Action**: Bottom sheet explaining benefits of linking data is displayed
- **Location**: Line 800-900 (bottom sheet builder)

- **Event**: `dashboard_link_data_now_clicked`
- **Action**: User clicks "Link Data Now" button in benefits bottom sheet
- **Location**: Line 883-889 (`onPressed` in ElevatedButton)

---

### 10. Asset Type Navigation

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_navigate_to_banks`
- **Action**: User navigates to Banks screen from asset card
- **Location**: Line 3427 (`Get.to(destination)` for banks)

- **Event**: `dashboard_navigate_to_insurance`
- **Action**: User navigates to Insurance screen from asset card
- **Location**: Line 3427 (`Get.to(destination)` for insurance)

- **Event**: `dashboard_navigate_to_investments`
- **Action**: User navigates to Investments screen from asset card
- **Location**: Line 3427 (`Get.to(destination)` for investments)

- **Event**: `dashboard_navigate_to_nps`
- **Action**: User navigates to NPS screen from asset card
- **Location**: Line 3427 (`Get.to(destination)` for nps)

- **Event**: `dashboard_navigate_to_mutual_funds`
- **Action**: User navigates to Mutual Funds screen from asset card
- **Location**: Line 3459 (`Get.to(() => ImportMf())` for unlinked mutual funds)

- **Event**: `dashboard_navigate_to_connections`
- **Action**: User navigates to Connections screen to link accounts
- **Location**: Line 3430 (`Get.to(() => ConnectionsScreen())`)

- **Event**: `dashboard_navigate_to_saafe_connection`
- **Action**: User navigates to Saafe Connection screen
- **Location**: Line 3478 (`Get.to(() => SaafeConnectionScreen())`)

---

### 11. Mutual Funds Service Unavailable

- **Screen**: Dashboard (`lib/screens/dashboard/dashboard.dart`)
- **Event**: `dashboard_mf_service_unavailable_shown`
- **Action**: Snackbar is shown when mutual funds service is unavailable
- **Location**: Line 3442-3456 (`Get.snackbar` for service unavailable)

---

## Summary Count

**Total Events: 38 events across 11 screen sections**

1. Dashboard Screen (Main): 5 events
2. Dashboard Header: 6 events
3. Bottom Tab Navigation (Stacked Navbar): 3 events
4. Dashboard Bottom Navigation (Alternative): 4 events
5. Asset Cards Section: 8 events
6. Spends and Investments Quick Cards: 2 events
7. Recommendations Section: 2 events
8. Family Finance Section: 2 events
9. Link Data Benefits Bottom Sheet: 2 events
10. Asset Type Navigation: 7 events
11. Mutual Funds Service Unavailable: 1 event

## Implementation Notes

- All events use snake_case naming convention
- Event names are descriptive and indicate the action (not just generic "clicked")
- Success/failed events are separate for better analytics segmentation
- Events should be defined in `lib/constants/analytics.dart` before implementation
- All events use the unified AnalyticsService (one call triggers Firebase, CleverTap, and AppsFlyer)
- Bottom tab navigation events should include the tab index as a parameter
- Asset card clicks should include asset type and linked status as parameters
- Navigation events should include destination screen name as a parameter

## Recommended Parameters

### Common Parameters
- `screen_name`: Name of the current screen
- `user_type`: Type of user (individual/family)
- `is_family_mode`: Boolean indicating if family mode is active

### Bottom Tab Navigation Parameters
- `tab_index`: Index of the clicked tab (0, 1, 2, 3)
- `tab_name`: Name of the tab (home, investments, mutual_funds, advisory)
- `previous_tab_index`: Index of the previously selected tab

### Asset Card Parameters
- `asset_type`: Type of asset (banks, insurance, investments, nps, mutual_funds, add)
- `is_linked`: Boolean indicating if the asset is linked
- `asset_amount`: Current value of the asset (if linked and visible)

### Navigation Parameters
- `destination_screen`: Name of the destination screen
- `navigation_method`: Method used (bottom_tab, card_click, button_click)

### Family Mode Parameters
- `previous_mode`: Previous mode (family/individual)
- `new_mode`: New mode (family/individual)

### Amount Visibility Parameters
- `is_visible`: Boolean indicating if amounts are now visible
- `previous_visibility`: Previous visibility state
