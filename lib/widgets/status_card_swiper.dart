import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class StatusCardSwiper extends StatefulWidget {
  const StatusCardSwiper({
    super.key,
    required this.lastFetchedTime,
    required this.category,
    required this.accounts,
    this.horizontalPadding = AppSizing.scaffoldHorizontalPadding,
    this.isDisabled = false,
    this.onCardTap,
  });

  final String lastFetchedTime;
  final String category;
  final List<Map<String, dynamic>> accounts;
  final double horizontalPadding;
  final bool isDisabled;

  /// Optional custom tap handler. Receives the card's account data map.
  /// When null, falls back to navigating to DataFetchDetailsScreen.
  final void Function(Map<String, dynamic> cardData)? onCardTap;

  @override
  State<StatusCardSwiper> createState() => _StatusCardSwiperState();
}

class _StatusCardSwiperState extends State<StatusCardSwiper> {
  // Card swiper controller
  final CardSwiperController _cardSwiperController = CardSwiperController();

  // Bank account status counts
  int successCount = 0;
  int processingCount = 0;
  int failedCount = 0;

  // FIP names per status (comma-separated)
  String successFips = '';
  String processingFips = '';
  String failedFips = '';

  @override
  void didUpdateWidget(covariant StatusCardSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accounts != widget.accounts ||
        oldWidget.category != widget.category) {
      _updateAccountsByCategory();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateAccountsByCategory();
  }

  List<String> _typesForCategory(String category) {
    // Support multiple aliases for categories
    final normalized = category.trim().toLowerCase();
    if ([
      'banks',
      'bank',
      'bank accounts',
      'bank account',
    ].contains(normalized)) {
      return [
        'DEPOSIT',
        'TERM_DEPOSIT',
        'RECURRING_DEPOSIT',
        'SAVINGS',
        'CURRENT',
        'deposit',
        'term_deposit',
        'recurring_deposit',
        'savings',
        'current',
      ];
    }
    if (['investments', 'investment'].contains(normalized)) {
      return [
        'MUTUAL_FUNDS',
        'MUTUAL_FUND',
        'SIP',
        'ETF',
        'EQUITIES',
        'EQUITY',
        'STOCKS',
        'STOCK',
        'INVESTMENT',
        'INVESTMENTS',
        'mf',
        'sip',
        'etf',
        'equities',
        'stocks',
        'equity',
        'stock',
        'investment',
        'investments',
        'EQUITY_ETF',
        'DEMAT',
        'demat',
      ];
    }
    if (normalized == 'equity' || normalized == 'equities') {
      return [
        'EQUITIES',
        'STOCKS',
        'EQUITY',
        'STOCK',
        'DEMAT',
        'demat',
        'equities',
        'stocks',
      ];
    }
    if (normalized == 'etf' || normalized == 'etfs') {
      return ['ETF', 'ETFS', 'EQUITY_ETF', 'etf', 'etfs', 'equity_etf'];
    }
    if (['mutual funds', 'mutual_funds', 'mf'].contains(normalized)) {
      return [
        'MUTUAL_FUNDS',
        'MUTUAL_FUND',
        'SIP',
        'mf',
        'sip',
        'MF',
        'INVESTMENTS',
        'INVESTMENT',
      ];
    }
    if (['insurance', 'insurances'].contains(normalized)) {
      return [
        'INSURANCE_POLICIES',
        'LIFE_INSURANCE',
        'GENERAL_INSURANCE',
        'ULIP',
        'insurance_policies',
        'life_insurance',
        'general_insurance',
        'ulip',
      ];
    }
    if (['nps'].contains(normalized)) {
      return ['NPS', 'nps'];
    }
    return const <String>[]; // default: no filtering types
  }

  void _updateAccountsByCategory() {
    // Filter accounts by the selected category types
    final filterTypes = _typesForCategory(widget.category);
    int success = 0;
    int processing = 0;
    int failed = 0;
    final List<String> successFipList = <String>[];
    final List<String> processingFipList = <String>[];
    final List<String> failedFipList = <String>[];

    for (var account in widget.accounts) {
      // Double check the account type actually matches the category
      final String accType =
          (account['type'] as String? ??
                  account['accounttype'] as String? ??
                  '')
              .toUpperCase();

      // If we have specific filter types, ensure this account belongs to one of them
      if (filterTypes.isNotEmpty) {
        bool typeMatch = false;
        for (var t in filterTypes) {
          if (accType == t.toUpperCase()) {
            typeMatch = true;
            break;
          }
        }
        if (!typeMatch) continue;
      }

      final status = (account['fetchstatus'] as String?)?.toUpperCase() ?? '';
      final fip = (account['fipname'] as String?)?.trim() ?? 'Unknown';

      if (status == 'SUCCESS' || status == 'COMPLETED' || status == 'ACTIVE') {
        success++;
        if (fip.isNotEmpty && !successFipList.contains(fip)) {
          successFipList.add(fip);
        }
      } else if (status == 'FETCHING' ||
          status == 'PENDING' ||
          status == 'PROCESSING' ||
          status == 'IN_PROGRESS') {
        processing++;
        if (fip.isNotEmpty && !processingFipList.contains(fip)) {
          processingFipList.add(fip);
        }
      } else {
        failed++;
        if (fip.isNotEmpty && !failedFipList.contains(fip)) {
          failedFipList.add(fip);
        }
      }
    }

    // Update the counts
    successCount = success;
    processingCount = processing;
    failedCount = failed;

    // Update FIP names strings
    successFips = successFipList.join(', ');
    processingFips = processingFipList.join(', ');
    failedFips = failedFipList.join(', ');

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cardSwiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Filter accounts by the selected category types
        final normalized = widget.category.trim().toLowerCase();
        final filterTypes = _typesForCategory(normalized);
        final filtered = widget.accounts;

        // Create a list of status cards
        final List<Map<String, dynamic>> statusCards = [];

        int successCount = 0;
        int processingCount = 0;
        int failedCount = 0;
        final List<String> successFipList = [];
        final List<String> processingFipList = [];
        final List<String> failedFipList = [];

        // Track most recent lastUpdated for each status group
        String? successLastUpdated;
        String? failedLastUpdated;
        String? processingLastUpdated;

        for (var account in filtered) {
          // Double check the account type actually matches the category
          // (Backend sometimes puts NPS or Banks in the wrong list)
          final String accType =
              (account['type'] as String? ??
                      account['accounttype'] as String? ??
                      '')
                  .toUpperCase();

          // If we have specific filter types, ensure this account belongs to one of them
          if (filterTypes.isNotEmpty) {
            bool typeMatch = false;
            for (var t in filterTypes) {
              if (accType == t.toUpperCase()) {
                typeMatch = true;
                break;
              }
            }
            if (!typeMatch) continue; // Skip if it doesn't belong to this tab
          }

          final String fipName =
              (account['fipname'] as String?) ??
              (account['fipid'] as String?) ??
              'Unknown';

          final String status =
              (account['fetchstatus'] as String?)?.toUpperCase() ?? 'PENDING';

          // Extra check for Banks category: skip anything that looks like a Mutual Fund or Investment
          if (normalized == 'banks' &&
              (fipName.toLowerCase().contains('asset manager') ||
                  fipName.toLowerCase().contains('mutual fund') ||
                  fipName.toLowerCase().contains('amc') ||
                  fipName.toLowerCase().contains('securities') ||
                  fipName.toLowerCase().contains('investment') ||
                  fipName.toLowerCase().contains('wealth'))) {
            continue;
          }
          // Determine the update time for this account - prioritize lastdatafetchedat to match Linked Accounts screen
          DateTime? mostRecentDate;
          final lastFetched = account['lastdatafetchedat'];

          if (lastFetched != null) {
            if (lastFetched is DateTime) {
              mostRecentDate = lastFetched;
            } else if (lastFetched is String && lastFetched.isNotEmpty) {
              mostRecentDate = DateTime.tryParse(lastFetched);
              // If standard parse fails, try MF Central format
              if (mostRecentDate == null) {
                try {
                  mostRecentDate = DateFormat(
                    "dd MMM yyyy, hh:mm a",
                  ).parse(lastFetched);
                } catch (_) {}
              }
            }
          }

          // Fallback to other dates only if lastdatafetchedat is missing
          if (mostRecentDate == null) {
            final datesToCompare = [
              account['fetchstatusupdatedat'],
              account['balancedatetime'],
            ];

            for (final dateValue in datesToCompare) {
              if (dateValue == null) continue;
              DateTime? dt;
              if (dateValue is DateTime) {
                dt = dateValue;
              } else if (dateValue is String && dateValue.isNotEmpty) {
                dt = DateTime.tryParse(dateValue);
              }

              if (dt != null) {
                if (mostRecentDate == null || dt.isAfter(mostRecentDate!)) {
                  mostRecentDate = dt;
                }
              }
            }
          }

          String lastUpdated =
              mostRecentDate != null ? mostRecentDate.toIso8601String() : '';

          // If we still don't have a date but have a raw string (e.g. MF Central), use that
          if (lastUpdated.isEmpty && account['lastdatafetchedat_raw'] != null) {
            lastUpdated = account['lastdatafetchedat_raw'].toString();
          }

          if (status == 'SUCCESS' ||
              status == 'COMPLETED' ||
              status == 'ACTIVE') {
            successCount++;
            if (fipName.isNotEmpty && !successFipList.contains(fipName)) {
              successFipList.add(fipName);
            }
            // Track most recent lastUpdated for success group
            if (lastUpdated.isNotEmpty &&
                (successLastUpdated == null ||
                    lastUpdated.compareTo(successLastUpdated!) > 0)) {
              successLastUpdated = lastUpdated;
            }
          } else if (status == 'FETCHING' ||
              status == 'PENDING' ||
              status == 'PROCESSING' ||
              status == 'IN_PROGRESS') {
            processingCount++;
            if (fipName.isNotEmpty && !processingFipList.contains(fipName)) {
              processingFipList.add(fipName);
            }
            // Track most recent lastUpdated for processing group
            if (lastUpdated.isNotEmpty &&
                (processingLastUpdated == null ||
                    lastUpdated.compareTo(processingLastUpdated!) > 0)) {
              processingLastUpdated = lastUpdated;
            }
          } else {
            failedCount++;
            if (fipName.isNotEmpty && !failedFipList.contains(fipName)) {
              failedFipList.add(fipName);
            }
            // Track most recent lastUpdated for failed group
            if (lastUpdated.isNotEmpty &&
                (failedLastUpdated == null ||
                    lastUpdated.compareTo(failedLastUpdated!) > 0)) {
              failedLastUpdated = lastUpdated;
            }
          }
        }

        if (failedCount > 0) {
          final String failedSubtitle =
              widget.category == 'banks' && failedFipList.length == 1
                  ? '${failedFipList[0]}'
                  : failedFipList.join(', ');

          statusCards.add({
            'title': 'Failed',
            'subtitle': failedSubtitle,
            'iconData': Icons.error_outline,
            'iconColor': AppColors.error,
            'gradient': [
              const Color.fromRGBO(23, 23, 25, 1),
              const Color.fromRGBO(150, 51, 51, 1),
            ],
            'fips': failedFipList.join(', '),
            'lastdatafetchedat': failedLastUpdated ?? '',
          });
        }

        if (processingCount > 0) {
          final String pendingSubtitle =
              widget.category == 'banks' && processingFipList.length == 1
                  ? '${processingFipList[0]} - PENDING'
                  : processingFipList.join(', ');

          statusCards.add({
            'title': 'Pending',
            'subtitle': pendingSubtitle,
            'iconData': Icons.refresh,
            'iconColor': Colors.orange,
            'gradient': [
              const Color.fromRGBO(23, 24, 26, 1),
              const Color.fromRGBO(198, 115, 19, 1), // Orange-ish
            ],
            'fips': processingFipList.join(', '),
            'lastdatafetchedat': processingLastUpdated ?? '',
          });
        }

        if (successCount > 0) {
          final String successSubtitle =
              widget.category == 'banks' && successFipList.length == 1
                  ? '${successFipList[0]}'
                  : successFipList.join(', ');

          statusCards.add({
            'title': 'Success',
            'subtitle': successSubtitle,
            'iconData': Icons.check_circle_outline,
            'iconColor': AppColors.success,
            'gradient': [
              const Color.fromRGBO(23, 24, 26, 1),
              const Color.fromRGBO(92, 186, 160, 1),
            ],
            'fips': successFipList.join(', '),
            'lastdatafetchedat': successLastUpdated ?? '',
          });
        }

        // If no cards have accounts, show a placeholder
        if (statusCards.isEmpty) {
          return const SizedBox(height: 0);
        }

        // We'll only display one card at a time for better manual swiping

        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
              ),
              height: 82,
              width: double.infinity,
              child: Listener(
                onPointerDown: (_) {
                  // Prevent parent scroll when touching the swiper area
                },
                child: CardSwiper(
                  key: ValueKey(
                    'status_card_swiper_${statusCards.length}_${widget.lastFetchedTime}',
                  ),
                  controller: _cardSwiperController,
                  cardsCount: statusCards.length,
                  // Show up to 3 stacked cards based on available statuses
                  numberOfCardsDisplayed: (statusCards.length >= 3
                          ? 3
                          : statusCards.length)
                      .clamp(1, 3),
                  backCardOffset: const Offset(0, -8),
                  scale: 0.92,
                  isLoop: statusCards.length > 1,
                  allowedSwipeDirection:
                      statusCards.length > 1
                          ? AllowedSwipeDirection.only(right: true, left: true)
                          : AllowedSwipeDirection.none(),
                  threshold:
                      50, // Lower threshold for easier swiping (default is 50)
                  onSwipe: (previousIndex, currentIndex, direction) {
                    // Card was swiped, update the state if needed
                    return true; // Return true to allow the swipe
                  },
                  padding: const EdgeInsets.all(0),
                  duration: const Duration(milliseconds: 300),
                  isDisabled: false,

                  cardBuilder: (
                    context,
                    index,
                    percentThresholdX,
                    percentThresholdY,
                  ) {
                    // Check if index is valid for the current statusCards list
                    if (index < 0 || index >= statusCards.length) {
                      return const SizedBox.shrink();
                    }

                    // Get card properties from the filtered list
                    final cardData = statusCards[index];
                    final cardTitle = cardData['title'] as String;
                    final cardSubtitle = cardData['subtitle'] as String;
                    final cardIcon = cardData['iconData'] as IconData;
                    final cardIconColor = cardData['iconColor'] as Color;
                    final gradientColors = cardData['gradient'] as List<Color>;
                    final dynamic lastFetched = cardData['lastdatafetchedat'];
                    final displayTime =
                        (lastFetched != null &&
                                lastFetched.toString().isNotEmpty)
                            ? _formatCardTime(lastFetched)
                            : widget.lastFetchedTime;

                    return GestureDetector(
                      onTap:
                          widget.isDisabled
                              ? null
                              : () {
                                if (widget.onCardTap != null) {
                                  widget.onCardTap!(cardData);
                                } else {
                                  Get.to(
                                    () => DataFetchDetailsScreen(
                                      initialCategory:
                                          _getInitialCategoryForTarget(
                                            widget.category,
                                          ),
                                    ),
                                    transition: Transition.rightToLeft,
                                  );
                                }
                              },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(cardIcon, color: cardIconColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (cardData['subtitle'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 1.0,
                                          bottom: 1.0,
                                        ),
                                        child: Text(
                                          cardData['subtitle'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (displayTime.isNotEmpty)
                                      AppText(
                                        "Last updated on $displayTime",
                                        variant: AppTextVariant.tiny,
                                        weight: AppTextWeight.medium,
                                        colorType: AppTextColorType.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // SizedBox(height: 12),
          ],
        );
      },
    );
  }

  /// Formats an ISO date string into "d MMM, h:mm a" for per-card display.
  /// If parsing fails (e.g., for "10 May 2026, 06:09 PM" format), returns the raw string.
  String _formatCardTime(dynamic dateValue) {
    if (dateValue == null) return '';

    if (dateValue is DateTime) {
      return DateFormatter.formatToDateTimeWithAmPm(dateValue);
    }

    final String dateString = dateValue.toString();
    if (dateString.isEmpty) return '';

    // If the string already contains a comma (like "02 May 2026, 06:41 PM"), return as-is
    if (dateString.contains(',')) {
      return dateString;
    }

    try {
      final dt = DateTime.parse(dateString);
      return DateFormatter.formatToDateTimeWithAmPm(dt);
    } catch (_) {
      return dateString;
    }
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _getInitialCategoryForTarget(String category) {
    final normalized = category.trim().toLowerCase();
    if ([
      'banks',
      'bank',
      'bank accounts',
      'bank account',
    ].contains(normalized)) {
      return "Savings & Deposits";
    }
    if ([
      'investments',
      'investment',
      'mutual funds',
      'mf',
    ].contains(normalized)) {
      return "Mutual Funds";
    }
    if (['equity', 'equities', 'stocks', 'etf', 'etfs'].contains(normalized)) {
      return "Equities & ETFs";
    }
    if (['insurance', 'insurances'].contains(normalized)) {
      return "Insurance";
    }
    if (normalized == 'nps') {
      return "NPS";
    }
    return "Savings & Deposits";
  }
}
