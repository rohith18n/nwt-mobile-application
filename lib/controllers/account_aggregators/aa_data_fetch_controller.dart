import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/mf_central/mf_central_linked_accounts_service.dart';
import 'package:nwt_app/types/account_aggregators/aa_data_fetch_all_response.dart';
import 'package:nwt_app/types/account_aggregators/aa_data_fetch_options.dart';
import 'package:nwt_app/types/mf_central/mf_central_linked_account.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:intl/intl.dart';

class AaDataFetchController extends GetxController {
  static AaDataFetchController get to => Get.find<AaDataFetchController>();

  final RxBool isLoading = false.obs;
  final RxBool isRefreshingAll = false.obs;
  final RxMap<String, bool> refreshingAccounts = <String, bool>{}.obs;
  final Rx<AaDataFetchOptionsData?> fetchOptionsData =
      Rx<AaDataFetchOptionsData?>(null);
  final RxInt manualAdhocRemaining = 0.obs;

  /// Store raw lastUpdated strings from MF Central (key = option id)
  final Map<String, String> mfCentralLastUpdatedRaw = {};
  final RxInt timerSeconds = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Do not call fetchDataFetchOptions() here.
    // It hits the legacy atom backend and causes 401 errors during V1 onboarding.
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchDataFetchOptions({bool silent = false}) async {
    if (!silent) isLoading.value = true;

    try {
      // Fetch both AA data and MF Central linked accounts in parallel
      final results = await Future.wait([
        _fetchAAData(),
        _fetchMFCentralLinkedAccounts(),
      ]);

      final aaData = results[0] as AaDataFetchOptionsData?;
      final mfCentralData = results[1] as List<MFCentralLinkedAccount>;

      // Merge MF Central data into AA data
      final mergedData = _mergeMFCentralData(aaData, mfCentralData);
      fetchOptionsData.value = mergedData;

      // Calculate total refresh remaining (AA only, MF Central doesn't have refresh)
      final aaRefreshCount = aaData?.adhocRemainingCount ?? 0;
      manualAdhocRemaining.value = aaRefreshCount;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching data fetch options',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Fetch AA (Account Aggregator) data
  Future<AaDataFetchOptionsData?> _fetchAAData() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.AA_FETCH_OPTIONS);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AaDataFetchOptionsResponse.fromDynamic(data);
        return result.data;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching AA data',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// Fetch MF Central linked accounts using the new service
  Future<List<MFCentralLinkedAccount>> _fetchMFCentralLinkedAccounts() async {
    try {
      final service = MFCentralLinkedAccountsService();
      final response = await service.fetchLinkedAccounts();
      if (response.success) {
        AppLogger.info(
          'Fetched ${response.data.length} MF Central linked accounts',
          tag: 'AA_DataFetch',
        );
        return response.data;
      } else {
        AppLogger.warning(
          'MF Central linked accounts fetch failed: ${response.message}',
          tag: 'AA_DataFetch',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching MF Central linked accounts',
        error: e,
        stackTrace: stackTrace,
        tag: 'AA_DataFetch',
      );
    }
    return [];
  }

  /// Merge MF Central linked accounts into AA data format
  /// NOTE: For MF data, we ONLY use MF Central service (ignore AA MF data)
  AaDataFetchOptionsData? _mergeMFCentralData(
    AaDataFetchOptionsData? aaData,
    List<MFCentralLinkedAccount> mfCentralAccounts,
  ) {
    // Clear previous MF Central raw data
    mfCentralLastUpdatedRaw.clear();

    // Convert MF Central accounts to AaFetchOption format
    final mfCentralOptions =
        mfCentralAccounts.map((account) {
          final option = _convertToAaFetchOption(account);
          // Store raw lastUpdated string for UI display
          mfCentralLastUpdatedRaw[option.id] = account.lastUpdated;
          return option;
        }).toList();

    if (aaData == null) {
      // If no AA data, create new data with only MF Central accounts
      if (mfCentralAccounts.isEmpty) return null;

      return AaDataFetchOptionsData(
        adhocRemainingCount: 0,
        overallAdhocCount: 0,
        fetchOptions: mfCentralOptions,
        deposit: const [],
        mutualFunds: mfCentralOptions,
        equities: const [],
        etf: const [],
        equitiesEtf: const [],
        insurance: const [],
        nps: const [],
        others: const [],
      );
    }

    // Use AA data for all categories EXCEPT mutual funds
    // For mutual funds, ONLY use MF Central data (ignore aaData.mutualFunds)
    final filteredFetchOptions =
        aaData.fetchOptions
            .where((opt) => opt.accountType != 'MUTUAL_FUNDS')
            .toList();

    AppLogger.info(
      'Using MF Central for MF data: ${mfCentralOptions.length} accounts. AA MF data ignored.',
      tag: 'AA_DataFetch',
    );

    return aaData.copyWith(
      // Use MF Central data exclusively for mutual funds
      mutualFunds: mfCentralOptions,
      // Merge fetchOptions: AA non-MF + MF Central MF
      fetchOptions: [...filteredFetchOptions, ...mfCentralOptions],
    );
  }

  /// Convert MFCentralLinkedAccount to AaFetchOption format
  AaFetchOption _convertToAaFetchOption(MFCentralLinkedAccount account) {
    // Store raw string as fallback or for special display
    final String optionId =
        'mfcentral_${account.folioNumber}_${account.fundSchemeName.hashCode}';
    mfCentralLastUpdatedRaw[optionId] = account.lastUpdated;
    DateTime? lastUpdated;

    try {
      if (account.lastUpdated.isNotEmpty) {
        // MFC format is "dd MMM yyyy, hh:mm a" (e.g. "02 May 2026, 06:41 PM")
        lastUpdated = DateFormat(
          "dd MMM yyyy, hh:mm a",
        ).parse(account.lastUpdated);
      }
    } catch (e) {
      // Fallback to tryParse if custom format fails
      lastUpdated = DateTime.tryParse(account.lastUpdated);
    }

    return AaFetchOption(
      id: 'mfcentral_${account.folioNumber}_${account.fundSchemeName.hashCode}',
      fipName:
          account.fundSchemeName.isNotEmpty
              ? account.fundSchemeName
              : account.amcname,
      status: account.status,
      lastFetchedTime: lastUpdated,
      fipId: 'MF_CENTRAL',
      adhocRemainingCount: 0,
      accountType: 'MUTUAL_FUNDS',
      maskedAccNumber: account.folioNumber,
      fetchStatusUpdatedAt: lastUpdated,
    );
  }

  Future<void> refreshAccount(String id) async {
    refreshingAccounts[id] = true;
    try {
      final body = jsonEncode({"accountGuid": id});
      final response = await NetworkAPIHelper().post(
        ApiURLs.AA_FETCH_ACCOUNT,
        body,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = jsonDecode(response.body);
        final data = responseData["data"];
        final String? requestId = data?["requestid"]?.toString();

        if (requestId != null && requestId.isNotEmpty) {
          AppLogger.info(
            'Refresh account returned requestId: $requestId. Starting polling.',
          );
          await _pollAccountStatusFallback(id);
          // Final refreshes
          await fetchDataFetchOptions(silent: true);
        } else {
          AppLogger.warning('No requestId returned for account refresh: $id');
          await fetchDataFetchOptions(silent: true);
        }
      } else {
        AppLogger.error(
          'Refresh account failed for id: $id with status: ${response?.statusCode}',
        );
        await fetchDataFetchOptions(silent: true);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error refreshing account $id',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      refreshingAccounts.remove(id);
    }
  }

  /// Fallback poller that uses fetchDataFetchOptions to check for terminal state
  Future<void> _pollAccountStatusFallback(String id) async {
    int retryCount = 0;
    const int maxRetries = 12; // 12 * 5s = 60s
    bool isRunning = true;

    while (isRunning && retryCount < maxRetries) {
      await Future.delayed(const Duration(seconds: 5));
      await fetchDataFetchOptions(silent: true);

      final currentOptions = fetchOptionsData.value?.fetchOptions ?? [];
      final account = currentOptions.firstWhereOrNull((opt) => opt.id == id);

      if (account != null) {
        final status = account.status.toUpperCase();
        if (status != "IN_PROGRESS" &&
            status != "PENDING" &&
            status != "FETCHING" &&
            status != "PROCESSING") {
          AppLogger.info(
            'Fallback polling reached terminal state for $id: $status',
          );
          isRunning = false;
        } else {
          AppLogger.info(
            'Fallback polling for $id still $status (attempt ${retryCount + 1})',
          );
          retryCount++;
        }
      } else {
        isRunning = false;
      }
    }

    if (retryCount >= maxRetries) {
      AppLogger.warning('Fallback polling timed out for id: $id');
    }
  }

  Future<String?> _pollConsentStatus(String id, String requestId) async {
    int retryCount = 0;
    const int maxRetries = 24; // 24 * 5s = 120s (2 minutes)
    bool isRunning = true;

    try {
      while (isRunning && retryCount < maxRetries) {
        final response = await NetworkAPIHelper().get(
          ApiURLs.AA_CONSENT_STATUS(requestId),
        );

        if (response != null && response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final rawStatus =
              responseData['journeyStatus'] ??
              responseData['journey_status'] ??
              responseData['status'] ??
              responseData['data']?['status'];
          final status = rawStatus?.toString().toUpperCase();

          AppLogger.info(
            'Consent status for requestId $requestId: $status (attempt ${retryCount + 1})',
          );

          if (status == 'COMPLETED' ||
              status == 'SUCCESS' ||
              status == 'ACTIVE' ||
              status == 'FAILED' ||
              status == 'ABANDONED') {
            isRunning = false;
            _updateLocalAccountStatus(id, status!);
            return status;
          } else {
            // Still in progress
            _updateLocalAccountStatus(id, status ?? 'PENDING');
            retryCount++;
            await Future.delayed(const Duration(seconds: 5));
          }
        } else {
          AppLogger.error(
            'Error fetching consent status for requestId $requestId: ${response?.statusCode}',
          );
          isRunning = false;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error polling consent status for $requestId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  void _updateLocalAccountStatus(String id, String newStatus, {Quota? quota}) {
    final currentData = fetchOptionsData.value;
    if (currentData == null) return;

    AaFetchOption updateOpt(AaFetchOption opt) {
      if (opt.id == id) {
        return opt.copyWith(status: newStatus, quota: quota ?? opt.quota);
      }
      return opt;
    }

    fetchOptionsData.value = currentData.copyWith(
      fetchOptions: currentData.fetchOptions.map(updateOpt).toList(),
      deposit: currentData.deposit.map(updateOpt).toList(),
      mutualFunds: currentData.mutualFunds.map(updateOpt).toList(),
      equitiesEtf: currentData.equitiesEtf.map(updateOpt).toList(),
      insurance: currentData.insurance.map(updateOpt).toList(),
      nps: currentData.nps.map(updateOpt).toList(),
      others: currentData.others.map(updateOpt).toList(),
    );
  }

  Future<void> refreshAll() async {
    isRefreshingAll.value = true;
    if (manualAdhocRemaining.value > 0) {
      manualAdhocRemaining.value--;
    }
    _timer?.cancel();

    try {
      final response = await NetworkAPIHelper().post(
        ApiURLs.AA_FETCH_ALL,
        jsonEncode({}),
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = jsonDecode(response.body);
        final fetchAllResponse = AaDataFetchAllResponse.fromJson(responseData);
        final summary = fetchAllResponse.summary;

        // Set timer from estimated duration
        timerSeconds.value = summary.estimatedDurationSec;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (timerSeconds.value > 0) {
            timerSeconds.value--;
          } else {
            timer.cancel();
          }
        });

        if (summary.triggered == 0) {
          AppLogger.info(
            'Refresh all: No accounts triggered. Message: ${fetchAllResponse.message}',
          );
          await fetchDataFetchOptions(silent: true);
        } else {
          AppLogger.info(
            'Refresh all: ${summary.triggered} accounts triggered. Starting polling every ${summary.pollEverySec}s.',
          );

          // Smart polling
          int elapsed = 0;
          while (elapsed < summary.timeoutSec) {
            await Future.delayed(Duration(seconds: summary.pollEverySec));
            elapsed += summary.pollEverySec;

            await fetchDataFetchOptions(silent: true);

            // Check if all are finished
            final currentOptions = fetchOptionsData.value?.fetchOptions ?? [];
            final inProgress = currentOptions.any((opt) {
              final status = opt.status.toUpperCase();
              return status == "IN_PROGRESS" ||
                  status == "PENDING" ||
                  status == "FETCHING" ||
                  status == "PROCESSING";
            });

            if (!inProgress) {
              AppLogger.info(
                'Refresh all: All accounts reached terminal state.',
              );
              break;
            }
          }

          // Final refreshes
          await fetchDataFetchOptions(silent: true);
        }
      } else {
        AppLogger.error(
          'Refresh all failed with status: ${response?.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error refreshing all', error: e, stackTrace: stackTrace);
    } finally {
      // If there's still time on the timer, we wait, otherwise we stop
      if (timerSeconds.value > 0) {
        Timer(Duration(seconds: timerSeconds.value), () {
          isRefreshingAll.value = false;
          _timer?.cancel();
        });
      } else {
        isRefreshingAll.value = false;
        _timer?.cancel();
      }
    }
  }
}
