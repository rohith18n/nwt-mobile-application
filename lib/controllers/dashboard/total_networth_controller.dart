import 'package:get/get.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
import 'package:nwt_app/services/dashboard/total_networth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/mf_central/mf_central_status_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';

class TotalNetworthController extends GetxController {
  static TotalNetworthController get to => Get.find<TotalNetworthController>();

  final _totalNetworthService = TotalNetworthService();

  final isLoading = false.obs;
  final networthData = Rx<DashboardNetworthResponse?>(null);

  /// Calculates networth by replacing backend MF and Equity values with calculated/holding values if available.
  /// This logic is synced with Dashboard.dart.
  double get calculatedNetworth {
    final rawData = networthData.value?.data;
    if (rawData == null) return 0.0;

    double networth = rawData.totalNetWorth;

    // 1. Get Calculated MF from MF Central holdings (checks 3 sources in priority order)
    double mfCalc = 0.0;
    bool hasMfCalc = false;

    // Priority 1: V2 MFC holdings list (summed from active holdings)
    if (Get.isRegistered<InvestmentController>()) {
      final invCtrl = Get.find<InvestmentController>();
      final mfcHoldings = invCtrl.mfCentralHoldings;
      if (mfcHoldings.isNotEmpty) {
        double total = 0.0;
        for (final h in mfcHoldings) {
          total += h.currentmktvalue;
        }
        if (total > 0) {
          mfCalc = total;
          hasMfCalc = true;
        }
      }
    }

    // Priority 2: V1 AA holdings (fallback — may not include MFC data)
    if (!hasMfCalc && Get.isRegistered<InvestmentController>()) {
      final invCtrl = Get.find<InvestmentController>();
      final mfHoldings = invCtrl.holdings?.data?.investments.mf;
      if (mfHoldings != null && mfHoldings.isNotEmpty) {
        double total = 0.0;
        for (final mf in mfHoldings) {
          total += mf.currentmktvalue;
        }
        if (total > 0) {
          mfCalc = total;
          hasMfCalc = true;
        }
      }
    }

    // Priority 3: Pre-computed total from MFC status controller
    if (!hasMfCalc && Get.isRegistered<MFCentralStatusController>()) {
      final mfcTotal = MFCentralStatusController.to.totalValue.value;
      if (mfcTotal > 0) {
        mfCalc = mfcTotal;
        hasMfCalc = true;
      }
    }

    // 2. Get Calculated Equity from stock holdings
    double equityCalc = 0.0;
    if (Get.isRegistered<InvestmentController>()) {
      final invCtrl = Get.find<InvestmentController>();
      List<dynamic> stocks = [];
      final standardStocks = invCtrl.holdings?.data?.investments.stocks;
      if (standardStocks != null && standardStocks.isNotEmpty) {
        stocks = standardStocks;
      } else {
        final isFinarkein = Get.isRegistered<UserController>() &&
            Get.find<UserController>().userData?.isFinarkeinAa == true;
        if (isFinarkein && Get.isRegistered<RawAssetController>()) {
          final rawController = Get.find<RawAssetController>();
          if (rawController.equities.isNotEmpty) {
            stocks = rawController.equities;
          }
        }
        if (stocks.isEmpty) {
          final list = getAccountAggregatorDataProvider().getStocks();
          if (list != null && list.isNotEmpty) stocks = list;
        }
      }

      if (stocks.isNotEmpty) {
        double total = 0.0;
        final liveHoldings = Get.isRegistered<PortfolioRealtimeController>()
            ? Get.find<PortfolioRealtimeController>().holdingsMap
            : null;

        final Map<String, double> isinValues = {};
        for (final s in stocks) {
          String? isin;
          double currentVal = 0.0;
          if (s is Map<String, dynamic>) {
            isin = s['isin']?.toString();
            currentVal = (s['currentvalue'] ?? s['currentmktvalue'] ?? 0.0).toDouble();
          } else {
            isin = s.isin;
            currentVal = s.currentMarketValue;
          }

          if (isin != null && isin.isNotEmpty) {
            isinValues[isin] = (isinValues[isin] ?? 0.0) + currentVal;
          } else {
            total += currentVal;
          }
        }

        for (final entry in isinValues.entries) {
          final isin = entry.key;
          double val = entry.value;
          if (liveHoldings != null && liveHoldings.containsKey(isin)) {
            val = liveHoldings[isin]!.marketValue;
          }
          total += val;
        }
        equityCalc = total;
      }
    }

    // 3. Get Calculated ETF from ETF holdings
    double etfCalc = 0.0;
    if (Get.isRegistered<InvestmentController>()) {
      final invCtrl = Get.find<InvestmentController>();
      List<dynamic> etfs = [];
      final standardEtfs = invCtrl.holdings?.data?.investments.etf;
      if (standardEtfs != null && standardEtfs.isNotEmpty) {
        etfs = standardEtfs;
      } else {
        final isFinarkein = Get.isRegistered<UserController>() &&
            Get.find<UserController>().userData?.isFinarkeinAa == true;
        if (isFinarkein && Get.isRegistered<RawAssetController>()) {
          final rawController = Get.find<RawAssetController>();
          if (rawController.etfs.isNotEmpty) {
            etfs = rawController.etfs;
          }
        }
        if (etfs.isEmpty) {
          final list = getAccountAggregatorDataProvider().getEtf();
          if (list != null && list.isNotEmpty) etfs = list;
        }
      }

      if (etfs.isNotEmpty) {
        double total = 0.0;
        final liveHoldings = Get.isRegistered<PortfolioRealtimeController>()
            ? Get.find<PortfolioRealtimeController>().holdingsMap
            : null;

        final Map<String, double> isinValues = {};
        for (final e in etfs) {
          String? isin;
          double currentVal = 0.0;
          if (e is Map<String, dynamic>) {
            isin = e['isin']?.toString();
            currentVal = (e['currentvalue'] ?? e['currentmktvalue'] ?? 0.0).toDouble();
          } else {
            isin = e.isin;
            currentVal = e.currentMarketValue;
          }

          if (isin != null && isin.isNotEmpty) {
            isinValues[isin] = (isinValues[isin] ?? 0.0) + currentVal;
          } else {
            total += currentVal;
          }
        }

        for (final entry in isinValues.entries) {
          final isin = entry.key;
          double val = entry.value;
          if (liveHoldings != null && liveHoldings.containsKey(isin)) {
            val = liveHoldings[isin]!.marketValue;
          }
          total += val;
        }
        etfCalc = total;
      }
    }

    // 4. Get Backend MF, Equity and ETF from DashboardAssetController to avoid double counting
    double backendMfValue = 0.0;
    double backendEquityValue = 0.0;
    double backendEtfValue = 0.0;
    if (Get.isRegistered<DashboardAssetController>()) {
      final assetCtrl = Get.find<DashboardAssetController>();
      final assets = assetCtrl.dashboardAssets.value?.data;
      if (assets != null) {
        final mfAsset = assets.firstWhereOrNull(
          (a) => a.id.toLowerCase() == 'mf' || a.id.toLowerCase() == 'mutualfunds',
        );
        backendMfValue = mfAsset?.value ?? 0.0;

        final equityAsset = assets.firstWhereOrNull(
          (a) => a.id.toLowerCase() == 'equity',
        );
        backendEquityValue = equityAsset?.value ?? 0.0;

        final etfAsset = assets.firstWhereOrNull(
          (a) => a.id.toLowerCase() == 'etf',
        );
        backendEtfValue = etfAsset?.value ?? 0.0;
      }
    }

    final hasLinkedData = mfCalc > 0 || equityCalc > 0 || etfCalc > 0;
    final double mfVal;
    final double eqVal;
    final double etfVal;

    if (hasLinkedData) {
      mfVal = mfCalc;
      eqVal = equityCalc;
      etfVal = etfCalc;
    } else {
      mfVal = backendMfValue;
      eqVal = backendEquityValue;
      etfVal = backendEtfValue;
    }

    final finalNetworth = (networth - backendMfValue - backendEquityValue - backendEtfValue) +
        mfVal +
        eqVal +
        etfVal;
    
    // Log only if there's a difference to keep console clean
    if ((mfCalc > 0 || equityCalc > 0 || etfCalc > 0) && finalNetworth != networth) {
      AppLogger.info(
        'Calculated Networth: ₹$finalNetworth (Raw: ₹$networth, MF Calc: ₹$mfCalc, Backend MF: ₹$backendMfValue, Equity Calc: ₹$equityCalc, Backend Equity: ₹$backendEquityValue, ETF Calc: ₹$etfCalc, Backend ETF: ₹$backendEtfValue)',
        tag: 'TotalNetworthController',
      );
    }

    return finalNetworth;
  }

  void _setLoading(bool loading) {
    isLoading.value = loading;
    update();
  }

  @override
  void onInit() {
    super.onInit();
  }

  /// Fetches total networth data from the service
  Future<void> fetchTotalNetworth() async {
    final response = await _totalNetworthService.getTotalNetworth(
      onLoading: _setLoading,
    );

    if (response.status == 200 || response.status == 201) {
      networthData.value = response;
      update();
    } else {
      AppLogger.error(
        'Failed to fetch total networth',
        tag: 'TotalNetworthController',
      );
    }
  }

  /// Refreshes total networth data
  Future<void> refreshNetworth() async {
    await fetchTotalNetworth();
  }
}
