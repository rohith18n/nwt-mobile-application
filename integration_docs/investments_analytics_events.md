# Investments Tab Analytics Events List

A comprehensive list of user actions to track during the Investments tab flow, organized by screen with descriptive event names.

## Events by Screen

### 1. Investments Main Screen

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_screen_viewed`
- **Action**: User views the investments screen
- **Location**: Line 747 (`build` method)

- **Event**: `investments_pull_to_refresh`
- **Action**: User performs pull-to-refresh gesture to refresh investments data
- **Location**: Line 754-757 (`RefreshIndicator.onRefresh`)

- **Event**: `investments_amount_visibility_toggled`
- **Action**: User toggles visibility of amount values (show/hide) in portfolio header
- **Location**: Line 259-268 (`GestureDetector.onTap` for visibility icon)

- **Event**: `investments_back_button_clicked`
- **Action**: User clicks back button to navigate to dashboard/home
- **Location**: Line 118-123 (`GestureDetector.onTap` for chevron_left icon)

---

### 2. Investments Header Section

- **Screen**: AssetInvestmentScreen Header (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_status_button_clicked`
- **Action**: User clicks "Status" button to view data fetch status
- **Location**: Line 201-207 (`GestureDetector.onTap` for Status button)

- **Event**: `investments_speak_to_advisor_clicked`
- **Action**: User clicks "Speak to advisor for Investment advise" link
- **Location**: Line 534-537 (`InkWell.onTap` for advisor link)

---

### 3. Category Filter Section

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_category_all_selected`
- **Action**: User selects "All" category filter
- **Location**: Line 2255-2269 (`_buildCategoryChip` with category == "All")

- **Event**: `investments_category_equity_selected`
- **Action**: User selects "Equity" category filter
- **Location**: Line 2255-2269 (`_buildCategoryChip` with category == "Equity")

- **Event**: `investments_category_mutual_funds_selected`
- **Action**: User selects "Mutual Funds" category filter
- **Location**: Line 2255-2269 (`_buildCategoryChip` with category == "Mutual Funds")

- **Event**: `investments_category_etf_selected`
- **Action**: User selects "ETF" category filter
- **Location**: Line 2255-2269 (`_buildCategoryChip` with category == "ETF")

---

### 4. Search Functionality

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_search_initiated`
- **Action**: User starts typing in the search field
- **Location**: Line 826-830 (`AppInputField.onChanged`)

- **Event**: `investments_search_query_entered`
- **Action**: User enters a search query to filter investments
- **Location**: Line 826-830 (`AppInputField.onChanged`)

---

### 5. Nominee Registered Details Section

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_nominee_accordion_expanded`
- **Action**: User expands the "Nominee Registered Details" accordion
- **Location**: Line 840-1042 (`CustomAccordion` section)

- **Event**: `investments_nominee_accordion_collapsed`
- **Action**: User collapses the "Nominee Registered Details" accordion
- **Location**: Line 840-1042 (`CustomAccordion` section)

- **Event**: `investments_nominee_speak_to_advisor_clicked`
- **Action**: User clicks "Speak to our advisor if you need help" link in nominee section
- **Location**: Line 1022-1025 (`GestureDetector.onTap` for advisor link)

---

### 6. Mutual Funds Category Actions

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_mf_update_holdings_card_clicked`
- **Action**: User clicks "Update Your MF Holdings" card when MFC service is available
- **Location**: Line 1259-1267 (`InkWell.onTap` for MF holdings update card)

- **Event**: `investments_mf_service_outage_shown`
- **Action**: Service outage card is displayed when MFC service is unavailable
- **Location**: Line 1244-1252 (`ServiceOutageCard` when `!isMfcWorking`)

- **Event**: `investments_mf_nav_date_info_shown`
- **Action**: NAV date information card is displayed for Mutual Funds category
- **Location**: Line 1198-1238 (NAV date notification widget)

---

### 7. Equity Category Actions

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_equity_price_update_info_shown`
- **Action**: Price update information card is displayed for Equity category
- **Location**: Line 1378-1421 (Stock price update notification widget)

---

### 8. ETF Category Actions

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_etf_price_update_info_shown`
- **Action**: Price update information card is displayed for ETF category
- **Location**: Line 1424-1469 (ETF price update notification widget)

---

### 9. Mutual Fund Holding Card

- **Screen**: HoldingCard (`lib/screens/assets/investments/widgets/holding_card.dart`)
- **Event**: `investments_mf_holding_card_clicked`
- **Action**: User clicks on a mutual fund holding card
- **Location**: Line 644 (`build` method)

- **Event**: `investments_mf_holding_details_expanded`
- **Action**: User expands the details accordion on a mutual fund holding card
- **Location**: Line 659-669 (`CustomAccordion.onChanged` when expanded)

- **Event**: `investments_mf_holding_details_collapsed`
- **Action**: User collapses the details accordion on a mutual fund holding card
- **Location**: Line 659-669 (`CustomAccordion.onChanged` when collapsed)

- **Event**: `investments_mf_holding_fund_name_clicked`
- **Action**: User clicks on the fund name to navigate to Insights screen
- **Location**: Line 510-515 (`InkWell.onTap` for fund name)

- **Event**: `investments_mf_holding_transactions_clicked`
- **Action**: User clicks "Transactions" button on a mutual fund holding card
- **Location**: Line 370-372 (`GestureDetector.onTap` for Transactions button)

- **Event**: `investments_mf_holding_avg_buy_price_info_clicked`
- **Action**: User clicks info icon next to "Avg. buy price" to view explanation
- **Location**: Line 175-181 (`onInfoIconTap` callback)

- **Event**: `investments_mf_holding_xirr_info_clicked`
- **Action**: User clicks info icon next to "XIRR" to view explanation
- **Location**: Line 203-209 (`onInfoIconTap` callback)

---

### 10. Stock Holding Card

- **Screen**: StockHoldingCard (`lib/screens/assets/investments/widgets/stock_holding_card.dart`)
- **Event**: `investments_stock_holding_card_clicked`
- **Action**: User clicks on a stock holding card
- **Location**: Line 754 (`build` method)

- **Event**: `investments_stock_holding_details_expanded`
- **Action**: User expands the details accordion on a stock holding card
- **Location**: Line 769-782 (`CustomAccordion.onChanged` when expanded)

- **Event**: `investments_stock_holding_details_collapsed`
- **Action**: User collapses the details accordion on a stock holding card
- **Location**: Line 769-782 (`CustomAccordion.onChanged` when collapsed)

- **Event**: `investments_stock_holding_transactions_clicked`
- **Action**: User clicks "Transactions" button on a stock holding card
- **Location**: Line 287-290 (`GestureDetector.onTap` for Transactions button)

- **Event**: `investments_stock_holding_avg_buy_price_edit_clicked`
- **Action**: User clicks edit icon to edit average buy price
- **Location**: Line 139-141 (`onEditIconTap` callback)

- **Event**: `investments_stock_holding_avg_buy_price_edit_saved`
- **Action**: User saves the edited average buy price
- **Location**: Line 509-566 (`AppButton.onPressed` in edit dialog)

- **Event**: `investments_stock_holding_avg_buy_price_edit_cancelled`
- **Action**: User cancels editing average buy price
- **Location**: Line 496-498 (`TextButton.onPressed` in edit dialog)

- **Event**: `investments_stock_holding_avg_buy_price_info_clicked`
- **Action**: User clicks info icon next to "Avg. buy price" to view explanation
- **Location**: Line 132-138 (`onInfoIconTap` callback)

- **Event**: `investments_stock_holding_xirr_info_clicked`
- **Action**: User clicks info icon next to "XIRR" to view explanation
- **Location**: Line 185-192 (`onInfoIconTap` callback)

---

### 11. ETF Holding Card

- **Screen**: EtfHoldingCard (`lib/screens/assets/investments/widgets/etf_holding_card.dart`)
- **Event**: `investments_etf_holding_card_clicked`
- **Action**: User clicks on an ETF holding card
- **Location**: Line 469 (`build` method)

- **Event**: `investments_etf_holding_details_expanded`
- **Action**: User expands the details accordion on an ETF holding card
- **Location**: Line 479-488 (`CustomAccordion.onChanged` when expanded)

- **Event**: `investments_etf_holding_details_collapsed`
- **Action**: User collapses the details accordion on an ETF holding card
- **Location**: Line 479-488 (`CustomAccordion.onChanged` when collapsed)

- **Event**: `investments_etf_holding_transactions_clicked`
- **Action**: User clicks "Transactions" button on an ETF holding card
- **Location**: Line 260-263 (`GestureDetector.onTap` for Transactions button)

- **Event**: `investments_etf_holding_avg_buy_price_edit_clicked`
- **Action**: User clicks edit icon to edit average buy price
- **Location**: Line 179-181 (`onEditIconTap` callback)

- **Event**: `investments_etf_holding_avg_buy_price_edit_saved`
- **Action**: User saves the edited average buy price
- **Location**: Line 559-616 (`AppButton.onPressed` in edit dialog)

- **Event**: `investments_etf_holding_avg_buy_price_edit_cancelled`
- **Action**: User cancels editing average buy price
- **Location**: Line 546-548 (`TextButton.onPressed` in edit dialog)

- **Event**: `investments_etf_holding_avg_buy_price_info_clicked`
- **Action**: User clicks info icon next to "Avg. buy price" to view explanation
- **Location**: Line 172-178 (`onInfoIconTap` callback)

- **Event**: `investments_etf_holding_xirr_info_clicked`
- **Action**: User clicks info icon next to "XIRR" to view explanation
- **Location**: Line 217-224 (`onInfoIconTap` callback)

---

### 12. Navigation Actions

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_navigate_to_saafe_data_fetch`
- **Action**: User navigates to Saafe Data Fetch Status screen
- **Location**: Line 203-206 (`Get.to(() => SaafeDataFetch())`)

- **Event**: `investments_navigate_to_connections`
- **Action**: User navigates to Connections screen to link accounts
- **Location**: Line 644 (`Get.to(() => ConnectionsScreen())`)

- **Event**: `investments_navigate_to_mf_holdings_journey`
- **Action**: User navigates to Mutual Fund Holdings Journey screen
- **Location**: Line 1262-1267 (`Get.to(() => MutualFundHoldingsJourneyScreen())`)

---

### 13. Holding Card Navigation

- **Screen**: HoldingCard (`lib/screens/assets/investments/widgets/holding_card.dart`)
- **Event**: `investments_navigate_to_insights`
- **Action**: User navigates to Insights screen from holding card
- **Location**: Line 512-515 (`Get.to(() => InsightsScreen())`)

- **Event**: `investments_navigate_to_transactions`
- **Action**: User navigates to Transactions screen from holding card
- **Location**: Line 372 (`Get.to(() => TransactionScreen())`)

---

### 14. Account Linking Bottom Sheet

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_account_link_bottom_sheet_shown`
- **Action**: Account linking bottom sheet is displayed when portfolio value is 0
- **Location**: Line 639-646 (`AccountLinkBottomSheet.show`)

- **Event**: `investments_account_link_now_clicked`
- **Action**: User clicks "Link Now" button in account linking bottom sheet
- **Location**: Line 643-645 (`onLinkPressed` callback)

---

### 15. Empty State

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_no_holdings_shown`
- **Action**: Empty state message is displayed when no holdings are found
- **Location**: Line 2187-2253 (`_buildNoHoldingsMessage`)

---

### 16. Error States

- **Screen**: AssetInvestmentScreen (`lib/screens/assets/investments/investments.dart`)
- **Event**: `investments_portfolio_fetch_failed`
- **Action**: Portfolio data fetch fails
- **Location**: Line 662-670 (`catch` block in `fetchPortfolio`)

- **Event**: `investments_holdings_fetch_failed`
- **Action**: Holdings data fetch fails
- **Location**: Line 662-670 (`catch` block in `fetchPortfolio`)

---

## Summary Count

**Total Events: 58 events across 16 screen sections**

1. Investments Main Screen: 4 events
2. Investments Header Section: 2 events
3. Category Filter Section: 4 events
4. Search Functionality: 2 events
5. Nominee Registered Details Section: 3 events
6. Mutual Funds Category Actions: 3 events
7. Equity Category Actions: 1 event
8. ETF Category Actions: 1 event
9. Mutual Fund Holding Card: 7 events
10. Stock Holding Card: 9 events
11. ETF Holding Card: 9 events
12. Navigation Actions: 3 events
13. Holding Card Navigation: 2 events
14. Account Linking Bottom Sheet: 2 events
15. Empty State: 1 event
16. Error States: 2 events

## Implementation Notes

- All events use snake_case naming convention
- Event names are descriptive and indicate the action (not just generic "clicked")
- Success/failed events are separate for better analytics segmentation
- Events should be defined in `lib/constants/analytics.dart` before implementation
- All events use the unified AnalyticsService (one call triggers Firebase, CleverTap, and AppsFlyer)
- Category filter events should include the selected category as a parameter
- Holding card events should include investment type (MF/Stock/ETF), ISIN, and fund name as parameters
- Navigation events should include destination screen name as a parameter
- Edit price events should include the old price and new price as parameters
- Search events should include the search query length and whether results were found as parameters

## Recommended Parameters

### Common Parameters
- `screen_name`: Name of the current screen (e.g., "investments_main")
- `user_type`: Type of user (individual/family)
- `is_family_mode`: Boolean indicating if family mode is active
- `is_amount_visible`: Boolean indicating if amounts are currently visible

### Category Filter Parameters
- `category_name`: Name of the selected category (all, equity, mutual_funds, etf)
- `previous_category`: Name of the previously selected category
- `holdings_count`: Number of holdings in the selected category

### Search Parameters
- `search_query_length`: Length of the search query
- `search_results_count`: Number of results found
- `search_category`: Category being searched (if applicable)

### Holding Card Parameters
- `investment_type`: Type of investment (mutual_fund, stock, etf)
- `isin_code`: ISIN code of the investment
- `fund_name`: Name of the fund/investment
- `market_value`: Current market value of the holding
- `gain_loss_percentage`: Total gain/loss percentage
- `transaction_count`: Number of transactions for the holding

### Edit Price Parameters
- `investment_type`: Type of investment (equity, etf)
- `isin_code`: ISIN code of the investment
- `old_price`: Previous average buy price
- `new_price`: New average buy price
- `price_change_percentage`: Percentage change in price

### Navigation Parameters
- `destination_screen`: Name of the destination screen
- `navigation_method`: Method used (button_click, card_click, link_click)
- `source_category`: Category filter active when navigation occurred

### Error Parameters
- `error_type`: Type of error (network_error, api_error, validation_error)
- `error_message`: Error message from API or system
- `error_code`: Error code if available
- `retry_attempted`: Whether user attempted to retry

### Account Linking Parameters
- `portfolio_value`: Current portfolio value (0 when bottom sheet is shown)
- `entry_point`: How user entered the investments screen

### Category-Specific Parameters
- `mf_nav_date`: Latest NAV date for mutual funds
- `stock_price_update_time`: Latest stock price update time
- `etf_price_update_time`: Latest ETF price update time
- `mfc_service_status`: Status of MFC service (available/unavailable)
