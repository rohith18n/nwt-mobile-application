import 'package:get/get.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart';
import 'package:nwt_app/services/assets/investments/transactions/investment_transactions.dart';

class InvestmentTransactionController extends GetxController {
  Data? transactions; // Holds categorized transactions (etfs, equities, mfs)
  final InvestmentTransactionService _service = InvestmentTransactionService();

  // Pagination
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1; // Start with page 1 (1-based pagination)
  int pageLimit = 20; // Show 20 initially, then paginate

  // ISIN and Folio filtering
  String? currentIsinCode;
  String? currentFolioNo;

  Future<void> getInvestmentTransactions({
    required Function(bool isLoading) onLoading,
    bool refresh = false,
    String? isinCode,
    String? folioNo,
    bool forceStandardApis = false,
  }) async {
    if (refresh) {
      currentPage = 1; // Start with page 1 (1-based pagination)
      hasMoreData = true;
      currentIsinCode = isinCode; // Store ISIN for pagination
      currentFolioNo = folioNo; // Store Folio for pagination
    }

    final response = await _service.getInvestmentTransactions(
      onLoading: onLoading,
      page: currentPage,
      limit: pageLimit,
      isinCode: currentIsinCode,
      folioNo: currentFolioNo,
      forceStandardApis: forceStandardApis,
    );

    final batch = response?.data;

    if (refresh) {
      if (batch != null) {
        batch.etfs = _dedupeTransactions(batch.etfs);
        batch.equities = _dedupeTransactions(batch.equities);
        batch.mfs = _dedupeTransactions(batch.mfs);
      }
      transactions = batch;
    } else if (batch != null) {
      if (transactions == null) {
        transactions = batch;
      } else {
        // Append by category with deduplication
        transactions!.etfs = _dedupeTransactions([
          ...transactions!.etfs,
          ...batch.etfs,
        ]);
        transactions!.equities = _dedupeTransactions([
          ...transactions!.equities,
          ...batch.equities,
        ]);
        transactions!.mfs = _dedupeTransactions([
          ...transactions!.mfs,
          ...batch.mfs,
        ]);
      }
    }

    // Determine if there is potentially more data by page size
    final receivedCount =
        (batch?.etfs.length ?? 0) +
        (batch?.equities.length ?? 0) +
        (batch?.mfs.length ?? 0);
    hasMoreData = receivedCount >= pageLimit;

    update();
  }

  /// Load more with an explicit page number (useful when ListView reaches end)
  void loadMoreTransactionsWithPage({
    required int page,
    required Function(bool isLoading) onLoading,
    bool forceStandardApis = false,
  }) {
    if (isLoadingMore || !hasMoreData) return;

    isLoadingMore = true;
    update();

    _service
        .getInvestmentTransactions(
          onLoading: onLoading,
          page: page,
          limit: pageLimit,
          isinCode: currentIsinCode,
          folioNo: currentFolioNo,
          forceStandardApis: forceStandardApis,
        )
        .then((value) {
          final batch = value?.data;
          if (batch != null) {
            if (transactions == null) {
              transactions = batch;
            } else {
              transactions!.etfs = _dedupeTransactions([
                ...transactions!.etfs,
                ...batch.etfs,
              ]);
              transactions!.equities = _dedupeTransactions([
                ...transactions!.equities,
                ...batch.equities,
              ]);
              transactions!.mfs = _dedupeTransactions([
                ...transactions!.mfs,
                ...batch.mfs,
              ]);
            }
          }

          final receivedCount =
              (batch?.etfs.length ?? 0) +
              (batch?.equities.length ?? 0) +
              (batch?.mfs.length ?? 0);
          hasMoreData = receivedCount >= pageLimit;

          isLoadingMore = false;
          update();
        });
  }

  /// Convenience helper to request the next page and advance the controller page
  void loadMore({
    required Function(bool isLoading) onLoading,
    bool forceStandardApis = false,
  }) {
    if (!hasMoreData || isLoadingMore) return;
    final nextPage = currentPage + 1;
    currentPage = nextPage;
    loadMoreTransactionsWithPage(
      page: nextPage,
      onLoading: onLoading,
      forceStandardApis: forceStandardApis,
    );
  }

  /// Helper to deduplicate transaction lists based on a unique key
  List<Investment> _dedupeTransactions(List<Investment> items) {
    if (items.isEmpty) return [];
    final seen = <String>{};
    final out = <Investment>[];
    for (final item in items) {
      if (seen.add(item.uniqueKey)) {
        out.add(item);
      }
    }
    return out;
  }
}
