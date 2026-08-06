import 'package:get/get.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_models.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/aa_consent.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/services/account_aggregators/adhoc_remaing.dart';
import 'package:nwt_app/services/adhoc_refresh_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_mapper.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/account_aggregators/fip_status.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/types/finarkein/firnarkein_data_response.dart'
    as finarkein_types;

/// Abstraction for account list, dashboard assets, networth override, and asset data.
/// Callers use the provider only; no isFinarkeinAa or store checks in UI.
abstract class AccountAggregatorDataProvider {
  Future<FipStatusResponse?> fetchAccountList({bool fetchResults = true});
  List<AssetData> getDashboardAssets();
  double? getNetworthOverride();
  String? getLastFetchedTimeOverride();

  /// When non-null, dashboard uses this for the Investments card instead of networth API.
  InvestmentsData? getInvestmentsDataOverride() => null;

  /// When non-null, dashboard uses this for the Spends card instead of networth API.
  SpendsData? getSpendsDataOverride() => null;
  bool shouldPollAccountStatus();
  Future<FipStatusResponse?> refreshDashboardData({bool fetchResults = true});

  Future<double> fetchAdhocRemaining();
  Future<double?> triggerDataFetch();

  List<Bank>? getBanks();
  List<Stock>? getStocks();
  List<Mf>? getMf();
  List<Etf>? getEtf();
  List<Insurance>? getInsurance();
  List<Map<String, dynamic>>? getNpsRows();
  List<PersonalAssetItem>? getPersonalAssets();
}

class SaafeAccountAggregatorDataProvider
    implements AccountAggregatorDataProvider {
  final FipStatusService _fipStatusService = FipStatusService();

  @override
  Future<FipStatusResponse?> fetchAccountList({bool fetchResults = true}) async {
    return null;
  }

  @override
  List<AssetData> getDashboardAssets() {
    if (!Get.isRegistered<DashboardAssetController>()) return const [];
    final c = Get.find<DashboardAssetController>();
    return c.dashboardAssets.value?.data ?? const [];
  }

  @override
  double? getNetworthOverride() => null;

  @override
  String? getLastFetchedTimeOverride() => null;

  @override
  InvestmentsData? getInvestmentsDataOverride() => null;

  @override
  SpendsData? getSpendsDataOverride() => null;

  @override
  bool shouldPollAccountStatus() => false;

  @override
  Future<FipStatusResponse?> refreshDashboardData({
    bool fetchResults = true,
  }) async => null;

  final AdhocRemainingService _adhocRemainingService = AdhocRemainingService();
  final AdhocRefreshService _adhocRefreshService = AdhocRefreshService();

  @override
  Future<double> fetchAdhocRemaining() async {
    final response = await _adhocRemainingService.getAdhocRemaining(
      onLoading: (_) {},
    );
    return response?.data?.adhocRemaining ?? 0.0;
  }

  @override
  Future<double?> triggerDataFetch() async {
    return _adhocRefreshService.triggerAdhocRefresh(onLoading: (_) {});
  }

  @override
  List<Bank>? getBanks() {
    if (!Get.isRegistered<RawAssetController>()) return null;
    final c = Get.find<RawAssetController>();
    if (c.banks.isEmpty) return null;

    return c.banks.map((b) => Bank.fromJson(b)).toList();
  }

  @override
  List<Stock>? getStocks() => null;

  @override
  List<Mf>? getMf() => null;

  @override
  List<Etf>? getEtf() => null;

  @override
  List<Insurance>? getInsurance() => null;

  @override
  List<Map<String, dynamic>>? getNpsRows() => null;

  @override
  List<PersonalAssetItem>? getPersonalAssets() => null;
}

class FinarkeinAccountAggregatorDataProvider
    implements AccountAggregatorDataProvider {
  final FinarkeinConsentsService _consentsService = FinarkeinConsentsService();

  /// Cached account list from last successful GET aa/data/result. When store has data, we return this and skip calling the result API again.
  FipStatusResponse? _cachedFipStatusResponse;
  bool _forceNetworkNextFetch = false;

  bool _storeHasData(FinarkeinDataStore store) {
    return store.lastBanks.isNotEmpty ||
        store.lastStocks.isNotEmpty ||
        store.lastMf.isNotEmpty ||
        store.lastEtf.isNotEmpty ||
        store.lastInsurance.isNotEmpty ||
        store.lastNpsRows.isNotEmpty ||
        store.lastPersonalAssets.isNotEmpty;
  }

  List<String> _normalizeFiTypes(List<String>? consentedFiTypes) {
    if (consentedFiTypes == null) return const [];
    return consentedFiTypes
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .map((e) => e.replaceAll(' ', '').replaceAll('-', '_'))
        .toList();
  }

  bool _hasAnyFiType(List<String> normalized, Set<String> candidates) {
    for (final t in normalized) {
      if (candidates.contains(t)) return true;
      // allow simple prefix matches like mutual_funds.*
      for (final c in candidates) {
        if (t.startsWith('$c.')) return true;
      }
    }
    return false;
  }

  bool _isLinkedForBank(
    List<String>? consentedFiTypes,
    FinarkeinDataStore store,
  ) {
    if (consentedFiTypes == null || consentedFiTypes.isEmpty) return true;
    final normalized = _normalizeFiTypes(consentedFiTypes);
    const bankFiTypes = <String>{
      'deposit',
      'deposits',
      'banks',
      'bank',
      'rd',
      'td',
      'fd',
    };
    return _hasAnyFiType(normalized, bankFiTypes) || store.lastBanks.isNotEmpty;
  }

  bool _isLinkedForEquity(
    List<String>? consentedFiTypes,
    FinarkeinDataStore store,
  ) {
    if (consentedFiTypes == null || consentedFiTypes.isEmpty) return true;
    final normalized = _normalizeFiTypes(consentedFiTypes);
    const invFiTypes = <String>{'equities', 'equity', 'stocks', 'stock'};
    return _hasAnyFiType(normalized, invFiTypes) || store.lastStocks.isNotEmpty;
  }

  bool _isLinkedForMutualFunds(
    List<String>? consentedFiTypes,
    FinarkeinDataStore store,
  ) {
    if (consentedFiTypes == null || consentedFiTypes.isEmpty) return true;
    final normalized = _normalizeFiTypes(consentedFiTypes);
    const invFiTypes = <String>{
      'mf',
      'mutual_fund',
      'mutual_funds',
      'mutualfund',
      'mutualfunds',
      'etf',
      'etfs',
    };
    return _hasAnyFiType(normalized, invFiTypes) ||
        store.lastMf.isNotEmpty ||
        store.lastEtf.isNotEmpty;
  }

  bool _isLinkedForInsurance(
    List<String>? consentedFiTypes,
    FinarkeinDataStore store,
  ) {
    if (consentedFiTypes == null || consentedFiTypes.isEmpty) return true;
    return consentedFiTypes.contains('insurance') ||
        store.lastInsurance.isNotEmpty;
  }

  bool _isLinkedForNps(
    List<String>? consentedFiTypes,
    FinarkeinDataStore store,
  ) {
    if (consentedFiTypes == null || consentedFiTypes.isEmpty) return true;
    return consentedFiTypes.contains('nps') || store.lastNpsRows.isNotEmpty;
  }

  /// Builds asset rows from the pre-computed summary fields returned by /aa/result.
  /// Returns null if the controller or summary is unavailable.
  List<AssetData>? _buildAssetDataFromSummary() {
    if (!Get.isRegistered<FinarkeinDataController>()) return null;
    final ctrl = Get.find<FinarkeinDataController>();
    final data = ctrl.dataResponse.value?.data;
    final summary = data?.summary;
    if (summary == null || data == null) return null;

    final consentedFiTypes = _consentsService.consentedFiTypes;

    double _s(String key) {
      final v = summary[key];
      if (v == null) return 0.0;
      return v;
    }

    final bankValue = _s('totalbankamount');
    final equityValue = _s('totalequitiesamount');
    final mfEtfValue = _s('totalmfandetfamount');
    final insuranceValue = _s('totalinsuranceamount');
    final personalValue = _s('totalpersonalassetamount');
    final npsValue = _s('totalnpsamount');

    // Check if amounts are explicitly null (not linked)
    final isBankNull = summary['totalbankamount'] == null;
    final isEquityNull = summary['totalequitiesamount'] == null;
    final isMfEtfNull = summary['totalmfandetfamount'] == null;
    final isInsuranceNull = summary['totalinsuranceamount'] == null;
    final isPersonalNull = summary['totalpersonalassetamount'] == null;
    final isNpsNull = summary['totalnpsamount'] == null;

    // Only use summary if at least one meaningful value is present.
    final hasAnyValue =
        bankValue > 0 ||
        equityValue > 0 ||
        mfEtfValue > 0 ||
        insuranceValue > 0 ||
        personalValue > 0 ||
        npsValue > 0;
    if (!hasAnyValue) return null;

    final normalized = _normalizeFiTypes(consentedFiTypes);
    final noConsentFilter =
        consentedFiTypes == null || consentedFiTypes.isEmpty;

    // islinked: true when value > 0 (data present), or when no consent filter, or when FI type is consented.
    bool linked(double value, Set<String> fiTypes) {
      if (value > 0) return true;
      if (noConsentFilter) return true;
      return _hasAnyFiType(normalized, fiTypes);
    }

    AppLogger.info(
      'Finarkein provider: building assets from summary '
      'bank=$bankValue (null=$isBankNull) equity=$equityValue mf=$mfEtfValue '
      'ins=$insuranceValue personal=$personalValue nps=$npsValue',
      tag: 'AccountAggregatorDataProvider',
    );

    final gains = data.gainsbyasset;

    return [
      AssetData(
        id: 'bank',
        title: 'Banks',
        value: bankValue,
        deltavalue: gains.bank.dailygain,
        deltapercentage: gains.bank.dailygainpercentage,
        islinked:
            isBankNull
                ? false
                : linked(bankValue, {
                  'deposit',
                  'deposits',
                  'banks',
                  'bank',
                  'rd',
                  'td',
                  'fd',
                }),
      ),
      AssetData(
        id: 'equity',
        title: 'Equity',
        value: equityValue,
        deltavalue: gains.equities.dailygain,
        deltapercentage: gains.equities.dailygainpercentage,
        islinked:
            isEquityNull
                ? false
                : linked(equityValue, {
                  'equities',
                  'equity',
                  'stocks',
                  'stock',
                }),
      ),
      AssetData(
        id: 'mutualfunds',
        title: 'Mutual Funds & ETF',
        value: mfEtfValue,
        deltavalue: gains.mf.dailygain + gains.etf.dailygain,
        deltapercentage:
            (gains.mf.dailygainpercentage + gains.etf.dailygainpercentage) /
            2, // approximation
        islinked:
            isMfEtfNull
                ? false
                : linked(mfEtfValue, {
                  'mf',
                  'mutual_fund',
                  'mutual_funds',
                  'mutualfund',
                  'mutualfunds',
                  'etf',
                  'etfs',
                }),
      ),
      AssetData(
        id: 'insurance',
        title: 'Insurance',
        value: insuranceValue,
        deltavalue: gains.insurance.dailygain,
        deltapercentage: gains.insurance.dailygainpercentage,
        islinked:
            isInsuranceNull ? false : linked(insuranceValue, {'insurance'}),
      ),
      AssetData(
        id: 'nps',
        title: 'NPS',
        value: npsValue,
        deltavalue: gains.nps.dailygain,
        deltapercentage: gains.nps.dailygainpercentage,
        islinked: isNpsNull ? false : linked(npsValue, {'nps'}),
      ),
      AssetData(
        id: 'personalassets',
        title: 'Personal Assets',
        value: personalValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: isPersonalNull ? false : true,
      ),
    ];
  }

  List<AssetData> _buildAssetDataFromStore(FinarkeinDataStore store) {
    final consentedFiTypes = _consentsService.consentedFiTypes;
    final bankValue = store.lastBanks.fold<double>(
      0,
      (s, b) => s + b.currentvalue,
    );
    final stocksValue = store.lastStocks.fold<double>(
      0,
      (s, x) => s + x.currentMarketValue,
    );
    final mfValue = store.lastMf.fold<double>(
      0,
      (s, m) => s + m.currentmktvalue,
    );
    final etfValue = store.lastEtf.fold<double>(
      0,
      (s, e) => s + e.currentMarketValue,
    );
    final mutualfundsValue = mfValue + etfValue;
    final insuranceValue = store.lastInsurance.fold<double>(
      0,
      (s, i) => s + i.sumassured,
    );
    final npsValue = store.lastNpsRows.fold<double>(0, (s, row) {
      final v =
          (row['value'] ?? row['currentValue'] ?? row['currentvalue'] ?? 0);
      return s + (v is num ? v.toDouble() : 0.0);
    });
    final personalValue = store.lastPersonalAssets.fold<double>(
      0,
      (s, p) => s + p.amount,
    );

    return [
      AssetData(
        id: 'bank',
        title: 'Banks',
        value: bankValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: _isLinkedForBank(consentedFiTypes, store),
      ),
      AssetData(
        id: 'equity',
        title: 'Equity',
        value: stocksValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: _isLinkedForEquity(consentedFiTypes, store),
      ),
      AssetData(
        id: 'mutualfunds',
        title: 'Mutual Funds & ETF',
        value: mutualfundsValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: _isLinkedForMutualFunds(consentedFiTypes, store),
      ),
      AssetData(
        id: 'insurance',
        title: 'Insurance',
        value: insuranceValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: _isLinkedForInsurance(consentedFiTypes, store),
      ),
      AssetData(
        id: 'nps',
        title: 'NPS',
        value: npsValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: _isLinkedForNps(consentedFiTypes, store),
      ),
      AssetData(
        id: 'personalassets',
        title: 'Personal Assets',
        value: personalValue,
        deltavalue: 0,
        deltapercentage: 0,
        islinked: true, // No AA template; manual only
      ),
    ];
  }

  FinarkeinDataStore? get _store {
    if (!Get.isRegistered<FinarkeinDataStore>()) return null;
    return Get.find<FinarkeinDataStore>();
  }

  List<AssetData> _fallbackDashboardAssets() {
    if (!Get.isRegistered<DashboardAssetController>()) return const [];
    final c = Get.find<DashboardAssetController>();
    return c.dashboardAssets.value?.data ?? const [];
  }

  /// Merge store-backed assets with API-backed dashboard assets for missing slices.
  ///
  /// Why: Finarkein AA data may not include Mutual Funds for some users, but MFU/MF Central
  /// can still populate the backend dashboard assets API. If we only use the store whenever
  /// it has *any* data, the MF card can incorrectly show 0.
  List<AssetData> _mergeStoreWithFallbackAssets({
    required FinarkeinDataStore store,
    required List<AssetData> storeAssets,
  }) {
    final fallback = _fallbackDashboardAssets();
    if (fallback.isEmpty) return storeAssets;
    final fallbackById = <String, AssetData>{for (final a in fallback) a.id: a};

    AssetData mergedMutualFunds(AssetData current) {
      final fb = fallbackById[current.id];
      // Only fall back when AA store has no MF/ETF holdings at all.
      final storeHasMfSlice =
          store.lastMf.isNotEmpty || store.lastEtf.isNotEmpty;
      if (storeHasMfSlice) return current;
      if (fb == null) return current;
      if (fb.value <= 0) return current;
      AppLogger.info(
        'Finarkein provider: overriding mutualfunds from fallback value=${fb.value} (store slice empty)',
        tag: 'AccountAggregatorDataProvider',
      );
      return AssetData(
        id: current.id,
        title: current.title,
        value: fb.value,
        deltavalue: current.deltavalue,
        deltapercentage: current.deltapercentage,
        islinked: fb.islinked || current.islinked,
      );
    }

    return storeAssets.map((a) {
      if (a.id == 'mutualfunds') return mergedMutualFunds(a);
      return a;
    }).toList();
  }

  double _networthFromAssets(List<AssetData> assets) {
    return assets.fold<double>(0, (s, a) => s + a.value);
  }

  /// Derives data map from a single GET aa/data/result body (result['data'] or list-of-key-value normalized to map).
  Map<String, dynamic>? _dataMapFromResult(Map<String, dynamic> result) {
    final rawData = result['data'];
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is List && rawData.isNotEmpty) {
      final first = rawData.first;
      if (first is Map &&
          first.containsKey('key') &&
          first.containsKey('value')) {
        final dataMap = <String, dynamic>{};
        for (final item in rawData) {
          if (item is Map && item['key'] != null) {
            dataMap[item['key'].toString()] = item['value'];
          }
        }
        return dataMap;
      }
      if (first is List && first.length >= 2) {
        final dataMap = <String, dynamic>{};
        for (final item in rawData) {
          if (item is List && item.length >= 2 && item[0] != null) {
            dataMap[item[0].toString()] = item[1];
          }
        }
        return dataMap;
      }
    }
    return null;
  }

  @override
  Future<FipStatusResponse?> fetchAccountList({bool fetchResults = true}) async {
    try {
      final store = _store;
      // When we already have data from a prior successful result API call, return cached response and do not call /result again.
      if (!_forceNetworkNextFetch &&
          store != null &&
          _storeHasData(store) &&
          _cachedFipStatusResponse != null) {
        return _cachedFipStatusResponse;
      }
      // One-shot bypass for refresh: always attempt network once.
      _forceNetworkNextFetch = false;

      final results =
          fetchResults
              ? await _consentsService.getDataResultsForConsents()
              : <Map<String, dynamic>>[];
      if (results.isNotEmpty) {
        if (store != null) {
          bool first = true;
          for (final result in results) {
            final dataMap = _dataMapFromResult(result);
            if (dataMap != null && dataMap.isNotEmpty) {
              // When refreshing, avoid wiping existing slices if this response is partial.
              // De-duplication is applied in the store.
              store.setFromDataResult(
                dataMap,
                merge: !first,
                preserveExistingOnEmpty: first && _storeHasData(store),
              );
              first = false;
            }
          }
        }
      }

      final userguid = Get.find<UserController>().userData?.guid ?? '';

      // Attempt to map from data results
      if (results.isNotEmpty) {
        final firstResult = results.first;
        final mapped = FinarkeinDataResultMapper.mapDataResultToFipStatus(
          firstResult,
          userguid,
        );
        if (mapped != null) {
          _cachedFipStatusResponse = mapped;
          return mapped;
        }
      }

      // FALLBACK 1: If we have no new data results (or mapping failed), but the Store has data from previous fetches,
      // reconstruct the FIP status response from the Store.
      if (store != null && _storeHasData(store)) {
        AppLogger.info(
          'Finarkein provider: constructing FIP status from Store (network fetch yielded no results)',
          tag: 'AccountAggregatorDataProvider',
        );
        final built = _buildFipStatusFromStore(store, userguid);
        if (built != null) {
          _cachedFipStatusResponse = built;
          return built;
        }
      }

      // FALLBACK 2: If we have no data results AND no Store data, but we have consents,
      // construct a synthetic FIP status response from consents so the UI shows "Linked" accounts
      // instead of "Link Now".
      final consents = await _consentsService.getConsents();
      if (consents.isNotEmpty) {
        AppLogger.info(
          'Finarkein provider: fallback to consents for FIP status (count=${consents.length})',
          tag: 'AccountAggregatorDataProvider',
        );
        final syntheticData = <Datum>[];
        for (final c in consents) {
          if (!c.isActive) continue;

          // If consent has accounts, create a card for each
          if (c.accounts.isNotEmpty) {
            for (final acc in c.accounts) {
              final id = acc.fipId ?? c.provider ?? 'Linked Account';
              syntheticData.add(
                Datum(
                  userguid: userguid,
                  type: acc.fiType ?? 'DEPOSIT',
                  activestatus: true,
                  fetchstatusupdatedat: c.lastFetchAt ?? DateTime.now(),
                  guid: c.id ?? '',
                  fipid: id,
                  fipname:
                      (id.toLowerCase() != 'finarkein')
                          ? id
                          : (c.provider ?? 'Linked Account'),
                  fetchstatus: c.lastFetchAt != null ? 'SUCCESS' : 'PENDING',
                  balancedatetime: c.lastFetchAt ?? DateTime.now(),
                  imageurl: null,
                  maskedaccno: acc.maskedAccNumber,
                ),
              );
            }
          } else {
            // Fallback for consents with no specific accounts yet
            syntheticData.add(
              Datum(
                userguid: userguid,
                type: 'DEPOSIT',
                activestatus: true,
                fetchstatusupdatedat: c.lastFetchAt ?? DateTime.now(),
                guid: c.id ?? '',
                fipid: c.provider ?? 'UNKNOWN',
                fipname: c.provider ?? 'Linked Account',
                fetchstatus: c.lastFetchAt != null ? 'SUCCESS' : 'PENDING',
                balancedatetime: c.lastFetchAt ?? DateTime.now(),
                imageurl: null,
              ),
            );
          }
        }

        if (syntheticData.isNotEmpty) {
          final fallbackResponse = FipStatusResponse(
            statusCode: 200,
            message: 'Generated from consents',
            FIPStatusData: syntheticData,
            can_fetch_mfc: false,
          );
          return fallbackResponse;
        }
      }

      return _cachedFipStatusResponse;
    } catch (e) {
      AppLogger.error(
        'FinarkeinAccountAggregatorDataProvider fetchAccountList error',
        error: e,
        tag: 'AccountAggregatorDataProvider',
      );
      return _cachedFipStatusResponse;
    }
  }

  FipStatusResponse? _buildFipStatusFromStore(
    FinarkeinDataStore store,
    String userguid,
  ) {
    if (!_storeHasData(store)) return null;
    final List<Datum> list = [];
    final now = DateTime.now();

    // Banks
    for (final b in store.lastBanks) {
      list.add(
        Datum(
          userguid: userguid,
          type: 'DEPOSIT',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: b.guid,
          fipid: b.fipid,
          fipname: b.fipname.isNotEmpty ? b.fipname : 'Bank Account',
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }
    // Stocks
    for (final s in store.lastStocks) {
      list.add(
        Datum(
          userguid: userguid,
          type: 'EQUITIES',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: s.guid,
          fipid: 'finarkein',
          fipname: s.name,
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }
    // Mutual Funds
    if (store.lastMf.isNotEmpty) {
      for (final m in store.lastMf) {
        list.add(
          Datum(
            userguid: userguid,
            type: 'MUTUAL_FUNDS',
            activestatus: true,
            fetchstatusupdatedat: now,
            guid: m.guid,
            fipid: 'finarkein',
            fipname: m.name,
            fetchstatus: 'SUCCESS',
            balancedatetime: now,
            imageurl: null,
          ),
        );
      }
    } else {
      // Fallback: If no AA funds, check if we have fallback data (e.g. MFC)
      // and add a placeholder so the user sees "Mutual Funds" status.
      if (Get.isRegistered<DashboardAssetController>()) {
        final c = Get.find<DashboardAssetController>();
        final assets = c.dashboardAssets.value?.data ?? [];
        final mfAsset = assets.firstWhereOrNull((a) => a.id == 'mutualfunds');
        if (mfAsset != null && mfAsset.value > 0) {
          list.add(
            Datum(
              userguid: userguid,
              type: 'MUTUAL_FUNDS',
              activestatus: true,
              fetchstatusupdatedat: now,
              guid: 'mfc-fallback-placeholder',
              fipid: 'mfc',
              fipname: 'Mutual Funds (via MFC)',
              fetchstatus: 'SUCCESS',
              balancedatetime: now,
              imageurl: null,
            ),
          );
        }
      }
    }
    // Insurance
    for (final i in store.lastInsurance) {
      list.add(
        Datum(
          userguid: userguid,
          type: 'INSURANCE',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: i.accountguid,
          fipid: 'finarkein',
          fipname: i.policyname,
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }
    // NPS
    for (final row in store.lastNpsRows) {
      final guid =
          (row['linkedAccRef'] ??
                  row['linked_acc_ref'] ??
                  row['guid'] ??
                  'nps-row')
              .toString();
      final fipname =
          (row['issuerName'] ?? row['issuer_name'] ?? row['fipname'] ?? 'NPS')
              .toString();
      list.add(
        Datum(
          userguid: userguid,
          type: 'NPS',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: guid,
          fipid: 'finarkein',
          fipname: fipname,
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }

    // ETF
    for (final e in store.lastEtf) {
      list.add(
        Datum(
          userguid: userguid,
          type: 'ETF',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: e.guid,
          fipid: 'finarkein',
          fipname: e.name,
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }

    // Personal Assets
    for (final p in store.lastPersonalAssets) {
      list.add(
        Datum(
          userguid: userguid,
          type: 'PERSONAL_ASSETS',
          activestatus: true,
          fetchstatusupdatedat: now,
          guid: 'pa-${p.id}',
          fipid: 'finarkein',
          fipname: p.title,
          fetchstatus: 'SUCCESS',
          balancedatetime: now,
          imageurl: null,
        ),
      );
    }

    if (list.isEmpty) return null;
    return FipStatusResponse(
      statusCode: 200,
      message: 'Restored from Store',
      FIPStatusData: list,
      can_fetch_mfc: false,
    );
  }

  @override
  List<AssetData> getDashboardAssets() {
    // Priority 1: pre-computed per-asset amounts from /aa/result summary.
    final summaryAssets = _buildAssetDataFromSummary();
    if (summaryAssets != null) return summaryAssets;

    // Priority 2: sum individual holdings from the store.
    final store = _store;
    final storeHasData = store != null && _storeHasData(store);
    if (storeHasData) {
      final storeAssets = _buildAssetDataFromStore(store);
      return _mergeStoreWithFallbackAssets(
        store: store,
        storeAssets: storeAssets,
      );
    }

    // Priority 3: fallback to DashboardAssetController (non-Finarkein API).
    if (Get.isRegistered<DashboardAssetController>()) {
      final c = Get.find<DashboardAssetController>();
      return c.dashboardAssets.value?.data ?? const [];
    }
    return const [];
  }

  @override
  double? getNetworthOverride() {
    // Prefer the pre-computed networth from the backend /aa/result summary when available.
    if (Get.isRegistered<FinarkeinDataController>()) {
      final ctrl = Get.find<FinarkeinDataController>();
      final summary = ctrl.dataResponse.value?.data?.summary;
      if (summary != null) {
        final networth = summary['networth'] ?? summary['totalcurrentvalue'];
        if (networth != null && networth > 0) {
          AppLogger.info(
            'Finarkein provider: using summary networth=$networth from /aa/result',
            tag: 'AccountAggregatorDataProvider',
          );
          return networth;
        }
      }
    }
    final store = _store;
    if (store == null || !_storeHasData(store)) return null;
    // Fallback: sum individual assets from store.
    final assets = getDashboardAssets();
    return _networthFromAssets(assets);
  }

  bool _hasSummaryData() {
    if (!Get.isRegistered<FinarkeinDataController>()) return false;
    final summary =
        Get.find<FinarkeinDataController>().dataResponse.value?.data?.summary;
    if (summary == null) return false;
    return (summary['networth'] ?? summary['totalcurrentvalue'] ?? 0.0) > 0;
  }

  @override
  String? getLastFetchedTimeOverride() {
    if (_hasSummaryData()) return 'Data from linked accounts';
    final store = _store;
    if (store == null || !_storeHasData(store)) return null;
    return 'Data from linked accounts';
  }

  @override
  InvestmentsData? getInvestmentsDataOverride() {
    // Priority 1: Use pre-computed totalinvestedamount from summary.
    if (Get.isRegistered<FinarkeinDataController>()) {
      final ctrl = Get.find<FinarkeinDataController>();
      final summary = ctrl.dataResponse.value?.data?.summary;
      if (summary != null) {
        final totalInvested = summary['totalinvestedamount'];
        final dailyGain = summary['dailygain'];
        final dailyGainPercentage = summary['dailygainpercentage'];

        if (totalInvested != null && totalInvested > 0) {
          AppLogger.info(
            'Finarkein provider: using summary totalinvestedamount=$totalInvested',
            tag: 'AccountAggregatorDataProvider',
          );
          return FinancialData.investments(
            amount: totalInvested,
            delta: dailyGainPercentage ?? 0.0,
            deltarange: '',
            islinked: true,
            deltaamount: dailyGain ?? 0.0,
          );
        }
      }
    }

    // Priority 2: Fallback to summing equity + mutualfunds from assets.
    final hasSummary = _hasSummaryData();
    final store = _store;
    if (!hasSummary && (store == null || !_storeHasData(store))) return null;
    final assets = getDashboardAssets();
    final equity = assets
        .where((a) => a.id == 'equity')
        .fold<double>(0, (s, a) => s + a.value);
    final mutualfunds = assets
        .where((a) => a.id == 'mutualfunds')
        .fold<double>(0, (s, a) => s + a.value);
    final amount = equity + mutualfunds;
    return FinancialData.investments(
      amount: amount,
      delta: 0,
      deltarange: '',
      islinked: true,
      deltaamount: 0,
    );
  }

  @override
  SpendsData? getSpendsDataOverride() {
    // Priority 1: Use pre-computed spends from summary if available.
    if (Get.isRegistered<FinarkeinDataController>()) {
      final ctrl = Get.find<FinarkeinDataController>();
      final summary = ctrl.dataResponse.value?.data?.summary;
      if (summary != null && summary.containsKey('spends')) {
        final spends = summary['spends'];
        final data = ctrl.dataResponse.value?.data;
        if (spends != null && data != null) {
          AppLogger.info(
            'Finarkein provider: using summary spends=$spends',
            tag: 'AccountAggregatorDataProvider',
          );
          return FinancialData(
            amount: spends,
            delta: data.gainsbyasset.bank.dailygainpercentage,
            deltaamount: data.gainsbyasset.bank.dailygain,
            spendrange: '',
            deltarange: '',
            islinked: true,
          );
        }
      }
    }

    // Priority 2: Fallback to calculating from dashboard assets.
    if (_hasSummaryData()) {
      final assets = getDashboardAssets();
      final bankAmount = assets
          .where((a) => a.id == 'bank')
          .fold<double>(0, (s, a) => s + a.value);
      return FinancialData.spends(
        amount: bankAmount,
        delta: 0,
        spendrange: '',
        deltarange: '',
        islinked: true,
      );
    }

    // Priority 3: Fallback to summing individual banks from store.
    final store = _store;
    if (store == null || !_storeHasData(store)) return null;
    final amount = store.lastBanks.fold<double>(
      0,
      (s, b) => s + b.currentvalue,
    );
    return FinancialData.spends(
      amount: amount,
      delta: 0,
      spendrange: '',
      deltarange: '',
      islinked: true,
    );
  }

  @override
  bool shouldPollAccountStatus() => false;

  @override
  Future<FipStatusResponse?> refreshDashboardData({
    bool fetchResults = true,
  }) async {
    // Refresh should be non-destructive: keep last known values until we have fresh data.
    // Only delink/revoke flows should clear store, handled elsewhere.
    _cachedFipStatusResponse = null;
    FinarkeinConsentsService.resetDataResultCircuit();
    _forceNetworkNextFetch = true;
    return fetchAccountList(fetchResults: fetchResults);
  }

  @override
  Future<double> fetchAdhocRemaining() async {
    return _consentsService.fetchAdhocRemaining(onLoading: (_) {});
  }

  @override
  Future<double?> triggerDataFetch() async {
    final consents = await _consentsService.getConsents();
    if (consents.isEmpty) return 0.0;

    // Find the first active consent with a valid handle and positive remaining count
    AaConsent? candidate;
    for (final c in consents) {
      final h = (c.consentHandle ?? '').trim();
      final r = (c.requestId ?? '').trim();
      if (c.isActive && h.isNotEmpty && r.isNotEmpty) {
        // Prefer one with remaining > 0
        if (c.remaining > 0) {
          candidate = c;
          break;
        }
        // Fallback to one with 0 remaining if no others found (though API might reject)
        candidate ??= c;
      }
    }

    if (candidate == null) {
      AppLogger.info(
        'Finarkein triggerDataFetch: no valid active consent found (count=${consents.length})',
        tag: 'AccountAggregatorDataProvider',
      );
      // Fallback: try first consent if it has a handle, just in case isActive logic is too strict
      final first = consents.first;
      final fh = (first.consentHandle ?? '').trim();
      final fr = (first.requestId ?? '').trim();
      if (fh.isNotEmpty && fr.isNotEmpty) {
        candidate = first;
      } else {
        return 0.0;
      }
    }

    final consentHandle = candidate.consentHandle!.trim();
    final requestId = candidate.requestId!.trim();

    return _consentsService.triggerDataFetch(
      consentHandle: consentHandle,
      requestId: requestId,
      onLoading: (_) {},
    );
  }

  @override
  List<Bank>? getBanks() {
    // Prefer RawAssetController for Finarkein users
    if (Get.isRegistered<RawAssetController>()) {
      final c = Get.find<RawAssetController>();
      if (c.banks.isNotEmpty) {
        return c.banks.map((b) => Bank.fromJson(b)).toList();
      }
    }
    return _store?.lastBanks;
  }

  @override
  List<Stock>? getStocks() {
    List<Stock>? stocks;

    // Prefer RawAssetController for Finarkein users
    if (Get.isRegistered<RawAssetController>()) {
      final c = Get.find<RawAssetController>();
      if (c.equities.isNotEmpty) {
        stocks = c.equities.map((s) => Stock.fromJson(s)).toList();
      }
    }

    stocks ??= _store?.lastStocks;
    print(
      'AccountAggregatorDataProvider.getStocks(): Retrieved ${stocks?.length ?? 0} stocks from store',
    );
    if (stocks == null || stocks.isEmpty) return stocks;
    final enriched = _enrichStocksWithDetails(stocks);
    print(
      'AccountAggregatorDataProvider.getStocks(): Returning ${enriched.length} enriched stocks',
    );
    return enriched;
  }

  @override
  List<Mf>? getMf() {
    List<Mf>? mfs;

    // Prefer RawAssetController for Finarkein users
    if (Get.isRegistered<RawAssetController>()) {
      final c = Get.find<RawAssetController>();
      if (c.mutualFunds.isNotEmpty) {
        mfs = c.mutualFunds.map((m) => Mf.fromJson(m)).toList();
      }
    }

    mfs ??= _store?.lastMf;
    AppLogger.info(
      'getMf() called - Store has ${mfs?.length ?? 0} MF holdings. Store is null: ${_store == null}',
      tag: 'transaction_count',
    );
    if (mfs == null || mfs.isEmpty) {
      AppLogger.info(
        'getMf() returning early - mfs is ${mfs == null ? "null" : "empty"}',
        tag: 'transaction_count',
      );
      return mfs;
    }
    return _enrichMfWithDetails(mfs);
  }

  @override
  List<Etf>? getEtf() {
    List<Etf>? etfs;

    // Prefer RawAssetController for Finarkein users
    if (Get.isRegistered<RawAssetController>()) {
      final c = Get.find<RawAssetController>();
      if (c.etfs.isNotEmpty) {
        etfs = c.etfs.map((e) => Etf.fromJson(e)).toList();
      }
    }

    etfs ??= _store?.lastEtf;
    if (etfs == null || etfs.isEmpty) return etfs;
    return _enrichEtfWithDetails(etfs);
  }

  /// Enriches Stock objects with gain metrics from details.equities by matching ISIN.
  List<Stock> _enrichStocksWithDetails(List<Stock> stocks) {
    if (!Get.isRegistered<FinarkeinDataController>()) return stocks;
    final ctrl = Get.find<FinarkeinDataController>();
    final details = ctrl.dataResponse.value?.data?.details;
    if (details == null || details.equities.isEmpty) return stocks;

    final detailsMap = <String, finarkein_types.Equity>{};
    for (final eq in details.equities) {
      if (eq.isin.isNotEmpty) {
        detailsMap[eq.isin] = eq;
      }
    }

    return stocks.map((stock) {
      final isin = stock.isin;

      if (isin == null || isin.isEmpty || !detailsMap.containsKey(isin)) {
        return stock;
      }
      final detail = detailsMap[isin]!;
      // Use count ONLY from API (FinarkeinDataController service)
      final finalCount = detail.count;

      AppLogger.info(
        'Equity: ${detail.name} (ISIN: ${detail.isin}) - Transaction Count from API: ${detail.count}, Final: $finalCount',
        tag: 'transaction_count',
      );

      return Stock(
        id: stock.id,
        guid: stock.guid,
        icon: stock.icon,
        isin: stock.isin,
        name: stock.name,
        currentMarketValue: detail.currentvalue ?? stock.currentMarketValue,
        costValue: stock.costValue,
        gainLoss:
            detail.totalgain != null
                ? (detail.totalgain as num).toDouble()
                : stock.gainLoss,
        gainLossPercentage:
            detail.totalgainpercentage != null
                ? (detail.totalgainpercentage as num).toDouble()
                : stock.gainLossPercentage,
        lastUpdatedDate: stock.lastUpdatedDate,
        quantity: stock.quantity,
        rate: stock.rate,
        type: stock.type,
        buydate: stock.buydate,
        delta: stock.delta,
        deltaValue: detail.dailygain,
        averageholdingprice: stock.averageholdingprice,
        navdate: stock.navdate,
        xirr: detail.xirr,
        deltapercentage: detail.dailygainpercentage,
        issuername: detail.issuername,
        lasttransactiondate: stock.lasttransactiondate,
        count: finalCount,
        broker: stock.broker,
        brokername: stock.brokername,
        fipid: stock.fipid,
        fipname: stock.fipname,
      );
    }).toList();
  }

  /// Enriches Mf objects with gain metrics from details.mf by matching ISIN.
  List<Mf> _enrichMfWithDetails(List<Mf> mfs) {
    AppLogger.info(
      '_enrichMfWithDetails called with ${mfs.length} MF holdings',
      tag: 'transaction_count',
    );

    if (!Get.isRegistered<FinarkeinDataController>()) {
      AppLogger.info(
        'FinarkeinDataController NOT registered - skipping enrichment',
        tag: 'transaction_count',
      );
      return mfs;
    }

    final ctrl = Get.find<FinarkeinDataController>();
    final details = ctrl.dataResponse.value?.data?.details;

    AppLogger.info(
      'FinarkeinDataController registered. Has details: ${details != null}, MF count in details: ${details?.mf.length ?? 0}',
      tag: 'transaction_count',
    );

    if (details == null || details.mf.isEmpty) return mfs;

    final detailsMap = <String, finarkein_types.Mf>{};
    for (final mfDetail in details.mf) {
      if (mfDetail.isin.isNotEmpty) {
        detailsMap[mfDetail.isin] = mfDetail;
      }
    }

    return mfs.map((mf) {
      final isin = mf.isin;

      if (isin.isEmpty || !detailsMap.containsKey(isin)) {
        return mf;
      }
      final detail = detailsMap[isin]!;

      // Use count ONLY from API (FinarkeinDataController service)
      final finalCount = detail.count;

      AppLogger.info(
        'MF: ${detail.name} (ISIN: ${detail.isin}) - Transaction Count from API: ${detail.count}, Final: $finalCount',
        tag: 'transaction_count',
      );

      mf.xirrvalue = detail.xirr;
      mf.deltavalue = detail.dailygain;
      mf.deltapercentage = detail.dailygainpercentage;
      mf.gainloss =
          detail.totalgain != null
              ? (detail.totalgain as num).toDouble()
              : null;
      mf.gainlosspercentage =
          detail.totalgainpercentage != null
              ? (detail.totalgainpercentage as num).toDouble()
              : null;
      mf.holdingavgprice = detail.avgbuyprice;
      mf.count = finalCount;
      return mf;
    }).toList();
  }

  /// Enriches Etf objects with gain metrics from details.etf by matching ISIN.
  List<Etf> _enrichEtfWithDetails(List<Etf> etfs) {
    if (!Get.isRegistered<FinarkeinDataController>()) return etfs;
    final ctrl = Get.find<FinarkeinDataController>();
    final details = ctrl.dataResponse.value?.data?.details;
    if (details == null || details.etf.isEmpty) return etfs;

    // details.etf is List<dynamic> - parse if needed
    final detailsMap = <String, dynamic>{};
    for (final etf in details.etf) {
      if (etf is Map<String, dynamic> && etf['isin'] != null) {
        detailsMap[etf['isin']] = etf;
      }
    }

    return etfs.map((etf) {
      final isin = etf.isin;
      if (isin == null || isin.isEmpty || !detailsMap.containsKey(isin)) {
        return etf;
      }
      final detail = detailsMap[isin];
      etf.xirr = detail['xirr']?.toDouble();
      etf.deltavalue = detail['dailygain']?.toDouble();
      etf.deltapercentage = detail['dailygainpercentage']?.toDouble();
      etf.gainloss = detail['totalgain']?.toDouble();
      etf.gainlosspercentage = detail['totalgainpercentage']?.toDouble();
      etf.count = detail['count']?.toInt();
      return etf;
    }).toList();
  }

  @override
  List<Insurance>? getInsurance() {
    // For Finarkein users, use RawAssetController to get insurance data from API
    if (Get.isRegistered<RawAssetController>()) {
      final rawController = Get.find<RawAssetController>();
      if (rawController.insurance.isNotEmpty) {
        // Convert raw Map data to Insurance models
        return rawController.insurance.map((rawInsurance) {
          return Insurance.fromJson(rawInsurance);
        }).toList();
      }
    }

    // Fallback to store if RawAssetController has no data
    return _store?.lastInsurance;
  }

  @override
  List<Map<String, dynamic>>? getNpsRows() => _store?.lastNpsRows;

  @override
  List<PersonalAssetItem>? getPersonalAssets() => _store?.lastPersonalAssets;
}

/// Resolves the correct provider for the current user. Use after user profile is loaded.
AccountAggregatorDataProvider? _cachedProvider;
bool? _cachedIsFinarkein;

AccountAggregatorDataProvider getAccountAggregatorDataProvider({
  bool forceStandard = false,
}) {
  final user =
      Get.isRegistered<UserController>()
          ? Get.find<UserController>().userData
          : null;
  final isFinarkein = !forceStandard && user?.isFinarkeinAa == true;

  if (!forceStandard &&
      _cachedProvider != null &&
      _cachedIsFinarkein == isFinarkein) {
    return _cachedProvider!;
  }

  final provider =
      isFinarkein
          ? FinarkeinAccountAggregatorDataProvider()
          : SaafeAccountAggregatorDataProvider();

  if (!forceStandard) {
    _cachedIsFinarkein = isFinarkein;
    _cachedProvider = provider;
  }

  return provider;
}

/// Clears the cached AA provider (e.g., on logout or profile switch).
void resetAccountAggregatorDataProviderCache() {
  _cachedProvider = null;
  _cachedIsFinarkein = null;
}
