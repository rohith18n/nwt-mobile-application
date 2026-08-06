import 'package:get/get.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart'
    as invtx;
import 'package:nwt_app/screens/personal_assets/types/personal_assets_models.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_parser.dart';

/// Store for last parsed Finarkein data/result. Asset screens read their slice
/// when user is Finarkein. Updated after each successful GET aa/data/result
/// (integration service or Data Fetch Status).
class FinarkeinDataStore extends GetxController {
  static FinarkeinDataStore get to => Get.find<FinarkeinDataStore>();

  /// Keeps the best occurrence for each key, preserving order.
  static List<T> _dedupeByKey<T>(List<T> items, String Function(T) keyOf) {
    if (items.isEmpty) return [];
    
    final bestItems = <String, T>{};
    final keyOrder = <String>[];

    for (final item in items) {
      final k = keyOf(item).trim();
      if (k.isEmpty) {
        continue;
      }

      if (!bestItems.containsKey(k)) {
        bestItems[k] = item;
        keyOrder.add(k);
      } else {
        // If we have a collision, check if the NEW item is "better" (has more data)
        final current = bestItems[k];
        if (_isBetter(item, current)) {
          bestItems[k] = item;
        }
      }
    }
    
    return keyOrder.map((k) => bestItems[k]!).toList();
  }

  /// Helper to determine if an object has richer data (e.g. name is present)
  static bool _isBetter<T>(T newItem, T? current) {
    if (current == null) return true;
    
    // For Investment objects (transactions/holdings)
    if (newItem is invtx.Investment && current is invtx.Investment) {
      final newHasName = (newItem.name != null && newItem.name!.isNotEmpty && newItem.name != newItem.category);
      final curHasName = (current.name != null && current.name!.isNotEmpty && current.name != current.category);
      
      if (newHasName && !curHasName) return true;
    }
    
    // For other types, first one usually wins.
    return false;
  }

  static String _keyBank(Bank b) {
    final guid = b.guid.trim();
    if (guid.isNotEmpty) return 'bank:$guid';
    final fipid = b.fipid.trim();
    final masked = b.maskedaccountid.trim();
    final link = b.linkrefnumber.trim();
    return 'bank:$fipid|$masked|$link';
  }

  static String _keyMf(Mf m) {
    return invtx.Investment.generateHoldingKey(
      isin: m.isin,
      folio: m.folio,
      name: m.name,
      category: 'MUTUAL FUNDS',
    );
  }

  static String _keyEtf(Etf e) {
    return invtx.Investment.generateHoldingKey(
      isin: e.isin,
      folio: e.foliono,
      name: e.name,
      category: 'ETF',
    );
  }

  static String _keyInsurance(Insurance i) {
    final ag = i.accountguid.trim();
    final pn = i.policynumber.trim();
    final name = i.policyname.trim().toLowerCase();
    return 'ins:$ag|$pn|$name';
  }

  static String _keyPersonalAsset(PersonalAssetItem p) => 'pa:${p.id}';

  static String _keyBankTxn(Banktransation t) {
    final txnid = (t.txnid ?? '').trim();
    if (txnid.isNotEmpty) return 'btxn:$txnid';
    final guid = (t.guid ?? '').trim();
    if (guid.isNotEmpty) return 'btxn:$guid';
    return 'btxn:${t.accountguid}|${t.transactiontimestamp.toIso8601String()}|${t.amount}|${t.narration.trim()}';
  }

  static String _keyInvTxn(invtx.Investment t) {
    return t.uniqueKey;
  }

  /// Consolidate stocks by ISIN, merging quantities and values across demat accounts
  static List<Stock> _consolidateStocks(List<Stock> stocks) {
    final stocksByIsin = <String, List<Stock>>{};
    final stocksWithoutIsin = <Stock>[];
    
    // Group stocks by ISIN
    for (final stock in stocks) {
      final isin = (stock.isin ?? '').trim();
      if (isin.isEmpty) {
        stocksWithoutIsin.add(stock);
        continue;
      }
      stocksByIsin.putIfAbsent(isin, () => []).add(stock);
    }
    
    final consolidated = <Stock>[];
    
    // Merge stocks with same ISIN
    for (final entry in stocksByIsin.entries) {
      final stockList = entry.value;
      if (stockList.length == 1) {
        consolidated.add(stockList.first);
        continue;
      }
      
      // Merge multiple holdings of same stock
      final first = stockList.first;
      double totalQuantity = 0;
      double totalCurrentValue = 0;
      
      for (final stock in stockList) {
        totalQuantity += stock.quantity;
        totalCurrentValue += stock.currentMarketValue;
      }
      
      final avgRate = totalQuantity > 0 ? totalCurrentValue / totalQuantity : first.rate;
      
      consolidated.add(Stock(
        id: first.id,
        guid: first.guid,
        icon: first.icon,
        isin: first.isin,
        name: first.name,
        currentMarketValue: totalCurrentValue,
        costValue: first.costValue,
        gainLoss: first.gainLoss,
        gainLossPercentage: first.gainLossPercentage,
        lastUpdatedDate: first.lastUpdatedDate,
        quantity: totalQuantity,
        rate: avgRate,
        type: first.type,
        buydate: first.buydate,
        delta: first.delta,
        deltaValue: first.deltaValue,
        averageholdingprice: first.averageholdingprice,
        navdate: first.navdate,
        xirr: first.xirr,
        deltapercentage: first.deltapercentage,
        issuername: first.issuername,
        lasttransactiondate: first.lasttransactiondate,
        count: first.count,
      ));
    }
    
    // Add stocks without ISIN
    consolidated.addAll(stocksWithoutIsin);
    
    return consolidated;
  }

  void _dedupeAll() {
    _banks.value = _dedupeByKey(_banks.value, _keyBank);
    _stocks.value = _consolidateStocks(_stocks.value);
    _mf.value = _dedupeByKey(_mf.value, _keyMf);
    _etf.value = _dedupeByKey(_etf.value, _keyEtf);
    _insurance.value = _dedupeByKey(_insurance.value, _keyInsurance);
    _personalAssets.value = _dedupeByKey(_personalAssets.value, _keyPersonalAsset);
    _bankTransactions.value = _dedupeByKey(_bankTransactions.value, _keyBankTxn);
    _equityTransactions.value = _dedupeByKey(_equityTransactions.value, _keyInvTxn);
    _mfTransactions.value = _dedupeByKey(_mfTransactions.value, _keyInvTxn);
    _etfTransactions.value = _dedupeByKey(_etfTransactions.value, _keyInvTxn);
    // npsRows and mfHolders are raw maps; leave as-is for now.
  }

  final Rx<List<Bank>> _banks = Rx<List<Bank>>([]);
  final Rx<List<Stock>> _stocks = Rx<List<Stock>>([]);
  final Rx<List<Mf>> _mf = Rx<List<Mf>>([]);
  final Rx<List<Etf>> _etf = Rx<List<Etf>>([]);
  final Rx<List<Insurance>> _insurance = Rx<List<Insurance>>([]);
  final Rx<List<Map<String, dynamic>>> _npsRows = Rx<List<Map<String, dynamic>>>([]);
  final Rx<List<PersonalAssetItem>> _personalAssets = Rx<List<PersonalAssetItem>>([]);
  final Rx<List<Banktransation>> _bankTransactions =
      Rx<List<Banktransation>>([]);
  final Rx<List<invtx.Investment>> _equityTransactions =
      Rx<List<invtx.Investment>>([]);
  final Rx<List<invtx.Investment>> _mfTransactions =
      Rx<List<invtx.Investment>>([]);
  final Rx<List<invtx.Investment>> _etfTransactions =
      Rx<List<invtx.Investment>>([]);
  final Rx<List<Map<String, dynamic>>> _mfHolders =
      Rx<List<Map<String, dynamic>>>([]);

  List<Bank> get lastBanks => _banks.value;
  List<Stock> get lastStocks => _stocks.value;
  List<Mf> get lastMf => _mf.value;
  List<Etf> get lastEtf => _etf.value;
  List<Insurance> get lastInsurance => _insurance.value;
  List<Map<String, dynamic>> get lastNpsRows => _npsRows.value;
  List<PersonalAssetItem> get lastPersonalAssets => _personalAssets.value;
  List<Banktransation> get lastBankTransactions => _bankTransactions.value;
  List<invtx.Investment> get lastEquityTransactions => _equityTransactions.value;
  List<invtx.Investment> get lastMfTransactions => _mfTransactions.value;
  List<invtx.Investment> get lastEtfTransactions => _etfTransactions.value;
  List<Map<String, dynamic>> get lastMfHolders => _mfHolders.value;

  /// Observed lists for reactive UI (e.g. Obx).
  List<Bank> get banks => _banks.value;
  List<Stock> get stocks => _stocks.value;
  List<Mf> get mf => _mf.value;
  List<Etf> get etf => _etf.value;
  List<Insurance> get insurance => _insurance.value;
  List<Map<String, dynamic>> get npsRows => _npsRows.value;
  List<PersonalAssetItem> get personalAssets => _personalAssets.value;
  List<Banktransation> get bankTransactions => _bankTransactions.value;
  List<invtx.Investment> get equityTransactions => _equityTransactions.value;
  List<invtx.Investment> get mfTransactions => _mfTransactions.value;
  List<invtx.Investment> get etfTransactions => _etfTransactions.value;
  List<Map<String, dynamic>> get mfHolders => _mfHolders.value;

  /// Set store from parsed result. Replaces current data (no merge).
  void setFromParsedResult(FinarkeinParsedResult parsed) {
    print('FinarkeinDataStore: Setting data - ${parsed.stocks.length} stocks before dedupe');
    _banks.value = List<Bank>.from(parsed.banks);
    // Skip setting stocks, mf, etf - RawAssetController handles these for Finarkein users
    // _stocks.value = List<Stock>.from(parsed.stocks);
    // _mf.value = List<Mf>.from(parsed.mf);
    // _etf.value = List<Etf>.from(parsed.etf);
    _insurance.value = List<Insurance>.from(parsed.insurance);
    _npsRows.value = List<Map<String, dynamic>>.from(parsed.npsRows);
    _personalAssets.value = List<PersonalAssetItem>.from(parsed.personalAssets);
    _bankTransactions.value = List<Banktransation>.from(parsed.bankTransactions);
    _equityTransactions.value =
        List<invtx.Investment>.from(parsed.equityTransactions);
    _mfTransactions.value =
        List<invtx.Investment>.from(parsed.mfTransactions);
    _etfTransactions.value =
        List<invtx.Investment>.from(parsed.etfTransactions);
    _mfHolders.value = List<Map<String, dynamic>>.from(parsed.mfHolders);
    _dedupeAll();
    print('FinarkeinDataStore: After dedupe - ${_stocks.value.length} stocks stored');
    _banks.refresh();
    _stocks.refresh();
    _mf.refresh();
    _etf.refresh();
    _insurance.refresh();
    _npsRows.refresh();
    _personalAssets.refresh();
    _bankTransactions.refresh();
    _equityTransactions.refresh();
    _mfTransactions.refresh();
    _etfTransactions.refresh();
    _mfHolders.refresh();
  }

  /// Parse raw data/result [response] (full body or data object) and set store.
  /// [response] can be the full GET aa/data/result body (will use response['data'])
  /// or the inner data map. When merging multiple handles, pass [merge: true]
  /// to append to existing lists instead of replacing.
  ///
  /// When [preserveExistingOnEmpty] is true and [merge] is false, empty slices from the parsed
  /// result will not overwrite previously stored non-empty slices. This prevents intermittent
  /// "missing" holdings when a refresh only returns partial slices for some handles.
  void setFromDataResult(
    Map<String, dynamic> response, {
    bool merge = false,
    bool preserveExistingOnEmpty = false,
  }) {
    final data = response['data'] ?? response;
    if (data is! Map<String, dynamic>) return;
    final parsed = FinarkeinDataResultParser.parse(data);
    if (merge) {
      _banks.value = [..._banks.value, ...parsed.banks];
      // Skip merging stocks, mf, etf - RawAssetController handles these
      // _stocks.value = [..._stocks.value, ...parsed.stocks];
      // _mf.value = [..._mf.value, ...parsed.mf];
      // _etf.value = [..._etf.value, ...parsed.etf];
      _insurance.value = [..._insurance.value, ...parsed.insurance];
      _npsRows.value = [..._npsRows.value, ...parsed.npsRows];
      _personalAssets.value = [..._personalAssets.value, ...parsed.personalAssets];
      _bankTransactions.value = [
        ..._bankTransactions.value,
        ...parsed.bankTransactions,
      ];
      _equityTransactions.value = [
        ..._equityTransactions.value,
        ...parsed.equityTransactions,
      ];
      _mfTransactions.value = [
        ..._mfTransactions.value,
        ...parsed.mfTransactions,
      ];
      _etfTransactions.value = [
        ..._etfTransactions.value,
        ...parsed.etfTransactions,
      ];
      _mfHolders.value = [
        ..._mfHolders.value,
        ...parsed.mfHolders,
      ];
    } else {
      if (!preserveExistingOnEmpty) {
        setFromParsedResult(parsed);
      } else {
        // Replace only slices that are present/non-empty in this response.
        if (parsed.banks.isNotEmpty) _banks.value = List<Bank>.from(parsed.banks);
        // Skip setting stocks, mf, etf - RawAssetController handles these
        // if (parsed.stocks.isNotEmpty) _stocks.value = List<Stock>.from(parsed.stocks);
        // if (parsed.mf.isNotEmpty) _mf.value = List<Mf>.from(parsed.mf);
        // if (parsed.etf.isNotEmpty) _etf.value = List<Etf>.from(parsed.etf);
        if (parsed.insurance.isNotEmpty) _insurance.value = List<Insurance>.from(parsed.insurance);
        if (parsed.npsRows.isNotEmpty) _npsRows.value = List<Map<String, dynamic>>.from(parsed.npsRows);
        if (parsed.personalAssets.isNotEmpty) {
          _personalAssets.value = List<PersonalAssetItem>.from(parsed.personalAssets);
        }
        if (parsed.bankTransactions.isNotEmpty) {
          _bankTransactions.value = List<Banktransation>.from(parsed.bankTransactions);
        }
        if (parsed.equityTransactions.isNotEmpty) {
          _equityTransactions.value = List<invtx.Investment>.from(parsed.equityTransactions);
        }
        if (parsed.mfTransactions.isNotEmpty) {
          _mfTransactions.value = List<invtx.Investment>.from(parsed.mfTransactions);
        }
        if (parsed.etfTransactions.isNotEmpty) {
          _etfTransactions.value = List<invtx.Investment>.from(parsed.etfTransactions);
        }
        if (parsed.mfHolders.isNotEmpty) {
          _mfHolders.value = List<Map<String, dynamic>>.from(parsed.mfHolders);
        }
        _dedupeAll();
      }
    }
    _dedupeAll();
    _banks.refresh();
    _stocks.refresh();
    _mf.refresh();
    _etf.refresh();
    _insurance.refresh();
    _npsRows.refresh();
    _personalAssets.refresh();
    _bankTransactions.refresh();
    _equityTransactions.refresh();
    _mfTransactions.refresh();
    _etfTransactions.refresh();
    _mfHolders.refresh();
  }

  /// Clear all stored data (e.g. on logout).
  void clear() {
    setFromParsedResult(FinarkeinParsedResult());
  }
}
