import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MFCentralStatusController extends GetxController {
  static MFCentralStatusController get to =>
      Get.find<MFCentralStatusController>();

  static const String _tag = 'MFCentralStatus';
  static const String _storageKeyStatus     = 'mfc_sync_status';
  static const String _storageKeyUpdatedAt  = 'mfc_sync_updated_at';
  static const String _storageKeyAmcNames   = 'mfc_sync_amc_names';
  static const String _storageKeyTotalValue = 'mfc_sync_total_value';

  final _storage = GetStorage();

  // 'none' | 'processing' | 'success'
  final RxString      status      = 'none'.obs;
  final RxString      amcNames    = ''.obs;
  final RxDouble      totalValue  = 0.0.obs;
  final Rx<DateTime?> lastUpdated = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    _restoreFromStorage();
  }

  void _restoreFromStorage() {
    final saved    = _storage.read<String>(_storageKeyStatus);
    final savedAt  = _storage.read<String>(_storageKeyUpdatedAt);
    final savedAmc = _storage.read<String>(_storageKeyAmcNames);
    final savedVal = _storage.read<String>(_storageKeyTotalValue);
    if (saved != null)    status.value      = saved;
    if (savedAt != null)  lastUpdated.value = DateTime.tryParse(savedAt);
    if (savedAmc != null) amcNames.value    = savedAmc;
    if (savedVal != null) totalValue.value  = double.tryParse(savedVal) ?? 0.0;
  }

  void _persist() {
    _storage.write(_storageKeyStatus,     status.value);
    _storage.write(_storageKeyAmcNames,   amcNames.value);
    _storage.write(_storageKeyTotalValue, totalValue.value.toString());
    if (lastUpdated.value != null) {
      _storage.write(_storageKeyUpdatedAt,
          lastUpdated.value!.toIso8601String());
    }
  }

  /// Called immediately after syncPortfolio — Processing card appears right away.
  void markProcessing() {
    status.value      = 'processing';
    lastUpdated.value = DateTime.now();
    _persist();
    AppLogger.info('MFC status → processing', tag: _tag);
  }

  /// Called when holdings API confirms data is present.
  void markSuccess({String? names, double? value}) {
    status.value      = 'success';
    lastUpdated.value = DateTime.now();
    if (names != null && names.isNotEmpty) amcNames.value   = names;
    if (value != null && value > 0)        totalValue.value = value;
    _persist();
    AppLogger.info(
      'MFC status → success (${amcNames.value}, ₹${totalValue.value})',
      tag: _tag,
    );
  }

  void clear() {
    status.value      = 'none';
    lastUpdated.value = null;
    amcNames.value    = '';
    totalValue.value  = 0.0;
    _storage.remove(_storageKeyStatus);
    _storage.remove(_storageKeyUpdatedAt);
    _storage.remove(_storageKeyAmcNames);
    _storage.remove(_storageKeyTotalValue);
  }

  /// Account map entry that StatusCardSwiper understands.
  Map<String, dynamic>? get swiperEntry {
    if (status.value == 'none') return null;
    final isSuccess = status.value == 'success';

    // Use actual AMC names as fipname so it matches the Finarkein pattern
    // (e.g. "Aditya Birla Sun Life Mutual Fund, HDFC Mutual Fund, …")
    final amc = amcNames.value.isNotEmpty
        ? amcNames.value
        : 'Mutual Funds';

    return {
      'type':              'MUTUAL_FUNDS',
      'fetchstatus':       isSuccess ? 'SUCCESS' : 'PROCESSING',
      'fipname':           amc,
      'lastdatafetchedat': lastUpdated.value?.toIso8601String(),
    };
  }

  /// Hits GET /v2/portfolio/user-holdings/ — if holdings exist the user has
  /// already completed MF Central. Always runs so the card appears even after
  /// app reinstall (no dependency on local storage status).
  Future<void> fetchAndUpdateStatus() async {
    try {
      AppLogger.info('Fetching MFC holdings from v2 API…', tag: _tag);

      final resp = await NetworkAPIHelper().get(ApiURLs.MF_PORTFOLIO_HOLDINGS);

      if (resp == null || resp.statusCode != 200) {
        AppLogger.warning(
          'MFC holdings API returned ${resp?.statusCode}',
          tag: _tag,
        );
        return;
      }

      AppLogger.info('MFC holdings body: ${resp.body}', tag: _tag);

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;

      // { "success": true, "data": { "summary": {...}, "holdings": [...] } }
      final dataObj  = decoded['data'] as Map<String, dynamic>? ?? {};
      final summary  = dataObj['summary'] as Map<String, dynamic>? ?? {};
      final holdings = dataObj['holdings'] as List? ?? [];

      // Pre-computed total from API summary
      final apiTotal = double.tryParse(
              summary['total_current_value']?.toString() ?? '0') ??
          0.0;

      AppLogger.info(
        'MFC holdings total items: ${holdings.length}',
        tag: _tag,
      );

      if (holdings.isEmpty) return;

      // Filter active (units > 0)
      final active = holdings.where((h) {
        final m     = h as Map<String, dynamic>;
        final units = double.tryParse(m['units']?.toString() ?? '0') ?? 0.0;
        return units > 0;
      }).toList();

      AppLogger.info('MFC active holdings: ${active.length}', tag: _tag);

      // AMC names from active holdings — new field is "amc_name"
      final amcSet = active
          .map<String>((h) {
            final m = h as Map<String, dynamic>;
            return (m['amc_name'] ?? '').toString().trim();
          })
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      final names = amcSet.isEmpty ? 'Mutual Funds' : amcSet.join(', ');

      AppLogger.info('MFC AMC names: $names', tag: _tag);

      markSuccess(names: names, value: apiTotal);
    } catch (e) {
      AppLogger.error('Error in fetchAndUpdateStatus', error: e, tag: _tag);
    }
  }
}
