import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/types/portfolio.dart';
import 'package:nwt_app/services/assets/investments/investments.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class InvestmentController extends GetxController {
  static const String _tag = 'InvestmentController';

  InvestmentPortfolio? portfolio;
  InvestmentHoldingsResponse? holdings;

  /// Active holdings from GET /v2/portfolio/holdings/ (units > 0).
  List<Mf> mfCentralHoldings = [];

  /// Raw transactions from GET /v2/portfolio/user-transactions/
  List<Map<String, dynamic>> mfCentralTransactions = [];

  /// Pre-computed summary from /v2/portfolio/holdings/ response.
  Map<String, dynamic>? mfPortfolioSummary;

  InvestmentService investmentService = InvestmentService();

  /// Incremented every time the My Investments tab is selected so the
  /// screen can react and re-fetch without needing a pull-to-refresh.
  final RxInt refreshTrigger = 0.obs;

  void triggerRefresh() => refreshTrigger.value++;

  // ── Standard V1 API ────────────────────────────────────────────────────────

  Future<InvestmentPortfolio?> getPortfolio({
    required Function(bool isLoading) onLoading,
  }) async {
    try {
      final value = await investmentService.getPortfolio(onLoading: onLoading);
      portfolio = value?.data;
      update();
      return portfolio;
    } catch (e) {
      rethrow;
    }
  }

  Future<InvestmentHoldingsResponse> getHoldings({
    required Function(bool isLoading) onLoading,
    bool useMfCentralV2 = false,
  }) async {
    try {
      final value = await investmentService.getHoldings(
        onLoading: onLoading,
        useMfCentralV2: useMfCentralV2,
      );
      
      // If using MF Central V2, merge MF data with existing holdings
      if (useMfCentralV2 && holdings != null && value.data != null) {
        // Keep existing Equity and ETF data, only update MF data
        if (holdings!.data?.investments != null) {
          holdings!.data!.investments.mf = value.data!.investments.mf;
        }
      } else {
        // For standard API, replace all holdings
        holdings = value;
      }
      
      update();
      return value;
    } catch (e) {
      rethrow;
    }
  }

  // ── MF Central V2 Holdings ─────────────────────────────────────────────────

  /// Fetches from GET /v2/portfolio/user-holdings/ (single source for MF data)
  /// - `mfCentralHoldings` — active Mf objects (units > 0)
  /// - `mfPortfolioSummary` — pre-computed totals from API
  /// Also patches `portfolio.mf_total` for the investments header.
  Future<void> fetchMFCentralHoldings() async {
    try {
      AppLogger.info('Fetching /v2/portfolio/user-holdings/…', tag: _tag);
      final resp = await NetworkAPIHelper().get(ApiURLs.MF_USER_HOLDINGS);

      if (resp == null || resp.statusCode != 200) {
        AppLogger.warning(
          '/v2/portfolio/user-holdings/ returned ${resp?.statusCode}',
          tag: _tag,
        );
        return;
      }

      AppLogger.info(
        '/v2/portfolio/user-holdings/ body: ${resp.body}',
        tag: _tag,
      );

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // MF_USER_HOLDINGS returns holdings directly as data array (not nested under data.holdings)
      final rawHoldings = decoded['data'] as List? ?? [];

      // No summary in this endpoint - calculate totals from holdings
      mfPortfolioSummary = null;

      // Parse holdings directly - Mf.fromJson handles API field name mapping
      // Filter: only closingbalance/quantity > 0
      mfCentralHoldings = rawHoldings
          .where((h) {
            final m = h as Map<String, dynamic>;
            final units = (m['closingbalance'] ?? m['quantity'] ?? 0).toDouble();
            return units > 0;
          })
          .map((h) => Mf.fromJson(h as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'MFC active holdings: ${mfCentralHoldings.length} '
        'of ${rawHoldings.length}',
        tag: _tag,
      );

      // Debug: log parsed holdings count and data
      AppLogger.info(
        'Parsed ${mfCentralHoldings.length} MF holdings from API',
        tag: _tag,
      );


      // Calculate portfolio totals from individual holdings (no summary in this endpoint)
      double mfTotal = 0.0;
      double mfInvested = 0.0;
      for (final holding in mfCentralHoldings) {
        mfTotal += holding.currentmktvalue;
        mfInvested += holding.costvalue;
      }

      // Patch portfolio totals so the header shows correct numbers
      if (portfolio == null) {
        portfolio = InvestmentPortfolio(
          value: mfTotal,
          invested: mfInvested,
          gain: mfTotal - mfInvested,
          latestbalancedatetime: DateTime.now().toIso8601String(),
          deltavalue: 0,
          deltapercentage: 0,
          coverage: Coverage(
            stocks: 0,
            mutualfunds: mfTotal,
            etf: 0,
            fo: 0,
          ),
          etf_total: 0,
          mf_total: mfTotal,
          stocks_total: 0,
          mf_invested: mfInvested,
        );
      } else {
        portfolio!.mf_total    = mfTotal;
        portfolio!.mf_invested = mfInvested;
      }

      update();
    } catch (e) {
      AppLogger.error(
        'Error fetching /v2/portfolio/user-holdings/',
        error: e,
        tag: _tag,
      );
    }
  }

  // ── MF Central V2 Transactions ─────────────────────────────────────────────

  Future<void> fetchMFCentralTransactions() async {
    try {
      AppLogger.info('Fetching /v2/portfolio/user-transactions/…', tag: _tag);
      final resp =
          await NetworkAPIHelper().get(ApiURLs.MF_USER_TRANSACTIONS);
      if (resp == null || resp.statusCode != 200) return;

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final raw     = decoded['data'] as List? ?? [];
      mfCentralTransactions = raw.cast<Map<String, dynamic>>();

      AppLogger.info(
        'MFC transactions: ${mfCentralTransactions.length}',
        tag: _tag,
      );
      update();
    } catch (e) {
      AppLogger.error(
        'Error fetching MFC transactions',
        error: e,
        tag: _tag,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Finds a holding across all categories (Stock, Mf, Etf) by ISIN.
  dynamic findHoldingByIsin(String? isin) {
    if (isin == null || isin.isEmpty) return null;

    // V2 MF Central first
    try {
      return mfCentralHoldings.firstWhere((m) => m.isin == isin);
    } catch (_) {}

    if (holdings?.data?.investments == null) return null;
    final inv = holdings!.data!.investments;

    try { return inv.mf.firstWhere((m) => m.isin == isin); } catch (_) {}
    try { return inv.stocks.firstWhere((s) => s.isin == isin); } catch (_) {}
    try { return inv.etf.firstWhere((e) => e.isin == isin); } catch (_) {}

    return null;
  }
}
