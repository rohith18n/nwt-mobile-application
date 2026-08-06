import 'package:get/get.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/services/assets/banks/transactions/bank_transactions.dart';
import 'package:nwt_app/utils/app_logger.dart';

class BankTransactionController extends GetxController {
  TransactionData? transactionData;
  BankTransactionService bankTransactionService = BankTransactionService();

  // Pagination variables
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 0;
  int pageLimit = 10; // Set to match API default limit

  String _getCompositeKey(Banktransation t) {
    // Primary identifier: txnid (if valid). Fallback: narration + amount + timestamp + type.
    final txnPart =
        (t.txnid != null && t.txnid!.isNotEmpty && t.txnid != 'NA')
            ? t.txnid!
            : '';
    // Robust composite key: txnid + narration (trimmed) + amount (fixed precision) + timestamp (ms) + type (uppercase)
    return "${txnPart}_${t.narration.trim()}_${t.amount.toStringAsFixed(2)}_${t.transactiontimestamp.millisecondsSinceEpoch}_${t.type.trim().toUpperCase()}";
  }

  Future<double?> getBankTransactions({
    String? bankGUID,
    List<String>? bankGUIDs,
    double? amountMin,
    double? amountMax,
    DateTime? startDate,
    DateTime? endDate,
    required Function(bool isLoading) onLoading,
    bool refresh = false,
    bool forceStandard = false,
  }) async {
    double? maxamount_data;
    if (refresh) {
      currentPage = 0;
      hasMoreData = true;
    }

    // Convert single bankGUID to list if provided
    List<String>? finalBankGUIDs;
    if (bankGUID != null) {
      finalBankGUIDs = [bankGUID];
    } else if (bankGUIDs != null && bankGUIDs.isNotEmpty) {
      finalBankGUIDs = bankGUIDs;
    }

    final value = await bankTransactionService.getBankTransactions(
      bankGUIDs: finalBankGUIDs,
      amountMin: amountMin,
      amountMax: amountMax,
      startDate: startDate,
      endDate: endDate,
      page: currentPage,
      limit: pageLimit,
      forceStandard: forceStandard,
      onLoading: (isLoading) {
        onLoading(isLoading);
      },
    );
    maxamount_data = value.data?.maxamount;

    List<Banktransation> deDuplicatedNewList = [];
    if (value.data != null) {
      // De-duplicate the incoming data within itself first
      final Map<String, Banktransation> uniqueMap = {};
      for (var t in value.data!.banktransations) {
        final key = _getCompositeKey(t);
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = t;
        }
      }
      deDuplicatedNewList = uniqueMap.values.toList();

      if (refresh || transactionData == null) {
        transactionData = value.data;
        transactionData!.banktransations = deDuplicatedNewList;
      } else {
        // Appending: Filter out transactions that already exist in the list
        final Set<String> existingKeys =
            transactionData!.banktransations
                .map((t) => _getCompositeKey(t))
                .toSet();

        final newTransactions =
            deDuplicatedNewList.where((t) {
              final key = _getCompositeKey(t);
              return !existingKeys.contains(key);
            }).toList();

        transactionData!.banktransations.addAll(newTransactions);
        transactionData!.pagination = value.data!.pagination;
      }
    }

    // Check if we have more data to load
    if (value.data?.pagination != null) {
      final pagination = value.data!.pagination!;
      hasMoreData =
          (pagination.total > 0) && ((currentPage + 1) < pagination.totalpages);
    } else {
      // Fallback: If no pagination metadata, assume no more data if we got fewer UNIQUE items than requested
      // Using de-duplicated count is more accurate for determining if the backend has more data
      hasMoreData = deDuplicatedNewList.length >= pageLimit;
    }

    update();
    return maxamount_data ?? 0.0;
  }

  /// Load more transactions with a specific page number
  void loadMoreTransactionsWithPage({
    String? bankGUID,
    List<String>? bankGUIDs,
    double? amountMin,
    double? amountMax,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required Function(bool isLoading) onLoading,
    bool forceStandard = false,
  }) {
    if (isLoadingMore) return;

    isLoadingMore = true;
    update();

    // Convert single bankGUID to list if provided
    List<String>? finalBankGUIDs;
    if (bankGUID != null) {
      finalBankGUIDs = [bankGUID];
    } else if (bankGUIDs != null && bankGUIDs.isNotEmpty) {
      finalBankGUIDs = bankGUIDs;
    }

    bankTransactionService
        .getBankTransactions(
          bankGUIDs: finalBankGUIDs,
          amountMin: amountMin,
          amountMax: amountMax,
          startDate: startDate,
          endDate: endDate,
          page: page,
          limit: pageLimit,
          forceStandard: forceStandard,
          onLoading: (isLoading) {
            onLoading(isLoading);
          },
        )
        .then((value) {
          List<Banktransation> deDuplicatedNewList = [];
          if (value.data != null) {
            // De-duplicate the incoming data within itself
            final Map<String, Banktransation> uniqueMap = {};
            for (var t in value.data!.banktransations) {
              final key = _getCompositeKey(t);
              if (!uniqueMap.containsKey(key)) {
                uniqueMap[key] = t;
              }
            }
            deDuplicatedNewList = uniqueMap.values.toList();

            if (transactionData == null) {
              transactionData = value.data;
              transactionData!.banktransations = deDuplicatedNewList;
            } else {
              // Append: Filter out existing keys
              final Set<String> existingKeys =
                  transactionData!.banktransations
                      .map((t) => _getCompositeKey(t))
                      .toSet();

              final newTransactions =
                  deDuplicatedNewList.where((t) {
                    final key = _getCompositeKey(t);
                    return !existingKeys.contains(key);
                  }).toList();

              transactionData!.banktransations.addAll(newTransactions);
              transactionData!.pagination = value.data!.pagination;

              // If we fetched a page but NO new items were added (all were duplicates),
              // stop further fetching to prevent infinite loops.
              if (newTransactions.isEmpty &&
                  value.data!.banktransations.isNotEmpty) {
                hasMoreData = false;
                AppLogger.info(
                  'Pagination stopped: all items on this page were duplicates.',
                  tag: 'BankTxnController',
                );
              }
            }
          }

          // Check if we have more data based on pagination info
          if (hasMoreData && value.data?.pagination != null) {
            final pagination = value.data!.pagination!;
            hasMoreData =
                (pagination.total > 0) && ((page + 1) < pagination.totalpages);
          } else if (value.data?.pagination == null) {
            // Fallback: assume no more data if we got fewer UNIQUE items than requested
            hasMoreData = deDuplicatedNewList.length >= pageLimit;
          }

          isLoadingMore = false;
          update();
          onLoading(false);
        });
  }
}
