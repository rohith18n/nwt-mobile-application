import 'package:get/get.dart';
import 'package:nwt_app/services/account_aggregators/raw_asset_service.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart';

/// Controller to manage raw asset data directly from API
/// Bypasses FinarkeinDataStore and parser for direct API-to-UI flow
/// Supports all asset types: banks, equity, ETF, mutual funds
class RawAssetController extends GetxController {
  static RawAssetController get to => Get.find<RawAssetController>();

  final RawAssetService _service = RawAssetService();

  final RxList<Map<String, dynamic>> equities = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> banks = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> mutualFunds = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> etfs = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> insurance = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> bankTransactions =
      <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>> gainsByAsset = Rx<Map<String, dynamic>>({});
  final Rx<Map<String, dynamic>> summary = Rx<Map<String, dynamic>>({});
  final RxInt _loadingCount = 0.obs;
  final RxString error = ''.obs;

  /// Distribute data from a single API result to all observables
  void _populateFromData(Map<String, dynamic> data) {
    try {
      // 1. Summary
      if (data['summary'] is Map<String, dynamic>) {
        summary.value = Map<String, dynamic>.from(data['summary']);
      }

      // 2. Gains By Asset
      if (data['gainsbyasset'] is Map<String, dynamic>) {
        gainsByAsset.value = Map<String, dynamic>.from(data['gainsbyasset']);
      }

      // 3. Details (Equities, MF, ETF, Bank, Insurance, NPS)
      final details = data['details'];
      if (details is Map<String, dynamic>) {
        // Equities
        if (details['equities'] is List) {
          equities.value = _dedupeList(
            List<Map<String, dynamic>>.from(details['equities']),
            'equity',
          );
        }
        // Banks
        if (details['bank'] is List) {
          banks.value = _dedupeList(
            List<Map<String, dynamic>>.from(details['bank']),
            'bank',
          );
        }
        // Mutual Funds
        if (details['mf'] is List) {
          mutualFunds.value = _dedupeList(
            List<Map<String, dynamic>>.from(details['mf']),
            'mf',
          );
        }
        // ETF
        if (details['etf'] is List) {
          etfs.value = _dedupeList(
            List<Map<String, dynamic>>.from(details['etf']),
            'etf',
          );
        }
        // Insurance
        if (details['insurance'] is List) {
          insurance.value = _dedupeList(
            List<Map<String, dynamic>>.from(details['insurance']),
            'insurance',
          );
        }
      }

      // 4. Normalization for Gains By Asset category keys
      final normGains = Map<String, dynamic>.from(gainsByAsset.value);
      normGains.forEach((category, data) {
        if (data is Map<String, dynamic>) {
          final catData = Map<String, dynamic>.from(data);
          // Normalize common keys inside each category (mf, equities, etf)
          _ensureKey(catData, 'totalgain', [
            'total_gain',
            'total_gains',
            'gain',
            'unrealised_gain',
            'unrealisedgain',
          ]);
          _ensureKey(catData, 'investedamount', [
            'total_invested',
            'invested_value',
            'invested_amount',
            'total_invested_amount',
          ]);
          normGains[category] = catData;
        }
      });
      gainsByAsset.value = normGains;

      // 5. Normalization for UI keys in Summary
      final normSummary = Map<String, dynamic>.from(summary.value);

      // Ensure specific keys expected by the Investment screen are present
      // Mapping common snake_case or legacy keys to expected ones if missing
      _ensureKey(normSummary, 'totalequitiesamount', [
        'total_equity_value',
        'equity_current_value',
        'total_equities_amount',
      ]);
      _ensureKey(normSummary, 'totalmfamount', [
        'total_mf_value',
        'mf_current_value',
        'total_mfa_amount',
        'total_mf_amount',
      ]);
      _ensureKey(normSummary, 'totaletfamount', [
        'total_etf_value',
        'etf_current_value',
        'total_etf_amount',
      ]);

      _ensureKey(normSummary, 'totalequitiesinvestedamount', [
        'total_equity_invested',
        'equity_invested_value',
        'investedequitiesamount',
      ]);
      _ensureKey(normSummary, 'totalmfinvestedamount', [
        'total_mf_invested',
        'mf_invested_value',
        'investedmfamount',
      ]);
      _ensureKey(normSummary, 'totaletfinvestedamount', [
        'total_etf_invested',
        'etf_invested_value',
        'investedetfamount',
      ]);

      summary.value = normSummary;

      print('RawAssetController: Consolidated data population complete');
    } catch (e) {
      print('RawAssetController._populateFromData error: $e');
    }
  }

  void _ensureKey(
    Map<String, dynamic> map,
    String targetKey,
    List<String> alternates,
  ) {
    if (map[targetKey] != null && (map[targetKey] as num) > 0) return;
    for (final alt in alternates) {
      if (map[alt] != null && (map[alt] as num) > 0) {
        map[targetKey] = map[alt];
        return;
      }
    }
  }

  /// Fetch all equities from API (raw data without consolidation)
  Future<void> fetchEquities() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawEquities = await _service.getAllEquities();
      print('RawAssetController: Fetched ${rawEquities.length} equity rows');

      // Show raw data as-is (backend will handle consolidation)
      equities.value = rawEquities;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch all banks from API (raw data without consolidation)
  Future<void> fetchBanks() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawBanks = await _service.getAllBanks();
      print('RawAssetController: Fetched ${rawBanks.length} bank rows');

      // Show raw data as-is (backend will handle consolidation)
      banks.value = rawBanks;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch all mutual funds from API (raw data without consolidation)
  Future<void> fetchMutualFunds() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawMfs = await _service.getAllMutualFunds();
      print('RawAssetController: Fetched ${rawMfs.length} MF rows');

      // Show raw data as-is (backend will handle consolidation)
      mutualFunds.value = rawMfs;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch all ETFs from API (raw data without consolidation)
  Future<void> fetchETFs() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawEtfs = await _service.getAllETFs();
      print('RawAssetController: Fetched ${rawEtfs.length} ETF rows');

      // Show raw data as-is (backend will handle consolidation)
      etfs.value = rawEtfs;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch all insurance from API (raw data without consolidation)
  Future<void> fetchInsurance() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawInsurance = await _service.getAllInsurance();
      print(
        'RawAssetController: Fetched ${rawInsurance.length} insurance rows',
      );

      // Show raw data as-is (backend will handle consolidation)
      insurance.value = rawInsurance;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch bank transactions from API
  Future<void> fetchBankTransactions() async {
    try {
      _loadingCount.value++;
      error.value = '';

      final rawTransactions = await _service.getBankTransactions();
      print(
        'RawAssetController: Fetched ${rawTransactions.length} bank transactions',
      );

      bankTransactions.value = rawTransactions;
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Fetch all asset types at once with batching to avoid request saturation/timeouts
  /// Fetch all asset types at once with a single API call for maximum efficiency
  Future<void> fetchAllAssets() async {
    try {
      _loadingCount.value++;
      error.value = '';

      print('RawAssetController: Starting consolidated fetchAllAssets...');

      // Call the new single-fetch service method
      final data = await _service.getDataResult();

      if (data.isNotEmpty) {
        _populateFromData(data);
      } else {
        error.value = 'Failed to fetch asset data';
      }

      // Bank transactions are still separate as they might be handled differently in aaData
      await fetchBankTransactions();
    } catch (e) {
      error.value = e.toString();
      print('RawAssetController.fetchAllAssets error: $e');
    } finally {
      _loadingCount.value--;
    }
  }

  /// Refresh all asset data
  @override
  Future<void> refresh() async {
    await fetchAllAssets();
  }

  /// Fetch summary data from API
  Future<void> fetchSummary() async {
    try {
      final summaryData = await _service.getSummary();
      summary.value = summaryData;
      print(
        'RawAssetController: Fetched summary - totalmfamount=${summaryData['totalmfamount']}, totalequitiesamount=${summaryData['totalequitiesamount']}, totaletfamount=${summaryData['totaletfamount']}',
      );
    } catch (e) {
      print('RawAssetController.fetchSummary error: $e');
    }
  }

  /// Fetch gains by asset data from API
  Future<void> fetchGainsByAsset() async {
    try {
      final gains = await _service.getGainsByAsset();
      gainsByAsset.value = gains;
      print(
        'RawAssetController: Fetched gainsByAsset with keys: ${gains.keys.join(", ")}',
      );
    } catch (e) {
      print('RawAssetController.fetchGainsByAsset error: $e');
    }
  }

  /// Clear all asset data
  void clear() {
    equities.clear();
    banks.clear();
    mutualFunds.clear();
    etfs.clear();
    insurance.clear();
    bankTransactions.clear();
    gainsByAsset.value = {};
    summary.value = {};
    error.value = '';
  }

  /// Update controller state from a raw data/result JSON response.
  /// Useful for immediate updates after a linking journey without a full network fetch.
  void setFromDataResult(Map<String, dynamic> data, {bool merge = false}) {
    try {
      final details = data['details'];
      if (details is Map<String, dynamic>) {
        if (merge) {
          equities.addAll(_toList(details['equities']));
          banks.addAll(_toList(details['bank']));
          mutualFunds.addAll(_toList(details['mf']));
          etfs.addAll(_toList(details['etf']));
          insurance.addAll(_toList(details['insurance']));
          bankTransactions.addAll(_toList(details['bank_transactions']));

          // Dedupe after merging
          equities.value = _dedupeList(equities, 'equity');
          banks.value = _dedupeList(banks, 'bank');
          mutualFunds.value = _dedupeList(mutualFunds, 'mf');
          etfs.value = _dedupeList(etfs, 'etf');
          insurance.value = _dedupeList(insurance, 'insurance');
          bankTransactions.value = _dedupeList(
            bankTransactions,
            'bank_transaction',
          );
        } else {
          equities.value = _dedupeList(_toList(details['equities']), 'equity');
          banks.value = _dedupeList(_toList(details['bank']), 'bank');
          mutualFunds.value = _dedupeList(_toList(details['mf']), 'mf');
          etfs.value = _dedupeList(_toList(details['etf']), 'etf');
          insurance.value = _dedupeList(
            _toList(details['insurance']),
            'insurance',
          );
          bankTransactions.value = _dedupeList(
            _toList(details['bank_transactions']),
            'bank_transaction',
          );
        }
      } else {
        // Fallback to legacy aaData format or direct maps
        final aaData = data['aaData'] ?? data;
        if (aaData is Map<String, dynamic>) {
          // In legacy format, we'd need to convert array-of-arrays to maps
          // but usually journey polling returns the new format or already-parsed maps.
          // For now, we handle the most common keys if they are direct lists.
          _setIfList(aaData, 'equities.summary', equities, merge, 'equity');
          _setIfList(aaData, 'banks.summary', banks, merge, 'bank');
          _setIfList(aaData, 'mutual_funds.summary', mutualFunds, merge, 'mf');
          _setIfList(aaData, 'etf.summary', etfs, merge, 'etf');
          _setIfList(
            aaData,
            'insurance.summary',
            insurance,
            merge,
            'insurance',
          );
          _setIfList(
            aaData,
            'bank.transactions',
            bankTransactions,
            merge,
            'bank_transaction',
          );
        }
      }

      // Update summary if present
      final summaryData = data['summary'];
      if (summaryData is Map<String, dynamic>) {
        if (merge) {
          summary.value = {...summary.value, ...summaryData};
        } else {
          summary.value = summaryData;
        }
      }

      print(
        'RawAssetController: Updated state from locally provided data result (merge=$merge)',
      );
    } catch (e) {
      print('RawAssetController.setFromDataResult error: $e');
    }
  }

  void _setIfList(
    Map<String, dynamic> source,
    String key,
    RxList<Map<String, dynamic>> target,
    bool merge,
    String typeFilter,
  ) {
    final val = source[key];
    if (val is List) {
      final list = val.whereType<Map<String, dynamic>>().toList();
      if (merge) {
        target.addAll(list);
        target.value = _dedupeList(target, typeFilter);
      } else {
        target.value = _dedupeList(list, typeFilter);
      }
    }
  }

  List<Map<String, dynamic>> _toList(dynamic val) {
    if (val is List) {
      return val.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// Helper to deduplicate lists of maps based on asset-specific keys
  List<Map<String, dynamic>> _dedupeList(
    List<Map<String, dynamic>> items,
    String type,
  ) {
    if (items.isEmpty) return [];

    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    for (final item in items) {
      String key = "";

      switch (type) {
        case 'bank':
          final guid = (item['guid'] ?? '').toString().trim();
          final accId = (item['maskedaccountid'] ?? '').toString().trim();
          final fip =
              (item['fipname'] ?? item['fipid'] ?? '').toString().trim();
          key = guid.isNotEmpty ? 'bank:$guid' : 'bank:$fip|$accId';
          break;

        case 'equity':
          key = Investment.generateHoldingKey(
            isin: (item['isin'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            category: 'EQUITY',
          );
          break;

        case 'mf':
          key = Investment.generateHoldingKey(
            isin: (item['isin'] ?? '').toString(),
            folio: (item['folio'] ?? item['folio_no'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            category: 'MUTUAL FUNDS',
          );
          break;

        case 'etf':
          key = Investment.generateHoldingKey(
            isin: (item['isin'] ?? '').toString(),
            folio: (item['foliono'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            category: 'ETF',
          );
          break;

        case 'insurance':
          final ag = (item['accountguid'] ?? '').toString().trim();
          final pn = (item['policynumber'] ?? '').toString().trim();
          key = 'ins:$ag|$pn';
          break;

        case 'bank_transaction':
          final txnid = (item['txnid'] ?? '').toString().trim();
          final guid = (item['guid'] ?? '').toString().trim();
          if (txnid.isNotEmpty) {
            key = 'btxn:$txnid';
          } else if (guid.isNotEmpty) {
            key = 'btxn:$guid';
          } else {
            final date = (item['transactiontimestamp'] ?? '').toString();
            final amt = (item['amount'] ?? '').toString();
            final desc = (item['narration'] ?? '').toString().trim();
            key = 'btxn:$date|$amt|$desc';
          }
          break;

        default:
          key = (item['guid'] ?? item['id'] ?? item.toString()).toString();
      }

      if (seen.add(key)) {
        out.add(item);
      }
    }

    return out;
  }
}
