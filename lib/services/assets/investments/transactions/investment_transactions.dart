import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class InvestmentTransactionService {
  bool _shouldUseFinarkeinStore() {
    if (!Get.isRegistered<FinarkeinDataStore>()) return false;
    final store = Get.find<FinarkeinDataStore>();
    final hasAny =
        store.lastEquityTransactions.isNotEmpty ||
        store.lastMfTransactions.isNotEmpty ||
        store.lastEtfTransactions.isNotEmpty;
    if (!hasAny) return false;
    if (!Get.isRegistered<UserController>())
      return true; // allow non-UI contexts/tests
    final user = Get.find<UserController>().userData;
    return user?.isFinarkeinAa == true;
  }

  Future<InvestmentTransactions?> getInvestmentTransactions({
    required Function(bool isLoading) onLoading,
    required int page,
    required int limit,
    String? isinCode,
    String? folioNo,
    bool forceStandardApis = false,
  }) async {
    onLoading(true);
    try {
      // Finarkein override: derive transactions from AA data/result store (no UI model changes).
      if (_shouldUseFinarkeinStore()) {
        final store = Get.find<FinarkeinDataStore>();
        var all = <Investment>[
          ...store.lastEquityTransactions,
          ...store.lastMfTransactions,
          ...store.lastEtfTransactions,
        ];

        // Deduplicate aggregated list before processing
        final seen = <String>{};
        all = all.where((t) => seen.add(t.uniqueKey)).toList();

        if (isinCode != null && isinCode.trim().isNotEmpty) {
          final isin = isinCode.trim();
          AppLogger.info(
            'InvestmentTransactionService: Filtering Finarkein transactions for ISIN: $isin',
            tag: 'InvestmentTransactionService',
          );
          // ISIN was stashed into Investment.brokercode by FinarkeinDataResultParser.
          all = all.where((t) {
            final tIsin = (t.isin ?? '').trim();
            final tBroker = (t.brokercode ?? '').trim();
            return tIsin == isin || tBroker == isin;
          }).toList();
          AppLogger.info(
            'InvestmentTransactionService: Found ${all.length} transactions for ISIN: $isin',
            tag: 'InvestmentTransactionService',
          );
        } else {
          AppLogger.info(
            'InvestmentTransactionService: No ISIN provided, returning all ${all.length} Finarkein transactions',
            tag: 'InvestmentTransactionService',
          );
        }

        // Sort newest first
        all.sort(
          (a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );

        final safeLimit = limit <= 0 ? 10 : limit;
        final pageIndex =
            page <= 0 ? 0 : (page - 1); // controller uses 1-based pages
        final startIdx = pageIndex * safeLimit;
        final endIdx =
            (startIdx + safeLimit) > all.length
                ? all.length
                : (startIdx + safeLimit);
        final pageItems =
            startIdx >= all.length
                ? <Investment>[]
                : all.sublist(startIdx, endIdx);

        final etfs = <Investment>[];
        final equities = <Investment>[];
        final mfs = <Investment>[];
        for (final t in pageItems) {
          final c = (t.category ?? '').toUpperCase().trim();
          if (c == 'ETF') {
            etfs.add(t);
          } else if (c == 'EQUITY' || c == 'EQUITIES') {
            equities.add(t);
          } else {
            mfs.add(t);
          }
        }

        return InvestmentTransactions(
          statusCode: 200,
          message: 'OK',
          data: Data(etfs: etfs, equities: equities, mfs: mfs),
        );
      }

      String url;
      bool useMfCentralV2 = false;

      // Determine which API to use.
      // - forceStandardApis: Explicitly requested standard AA API
      // - isinCode present AND folioNo is null: Likely Equity or ETF, must use Standard API
      bool shouldShowStandard = forceStandardApis || (isinCode != null && folioNo == null);

      if (shouldShowStandard) {
        url = "${ApiURLs.GET_ALL_INVESTMENTS_TRANSACTIONS}?page=$page&limit=$limit";
      } else {
        // Use MF Central V2 endpoint for MF transactions
        url = ApiURLs.MF_CENTRAL_USER_TRANSACTIONS;
        useMfCentralV2 = true;
        AppLogger.info(
          'InvestmentTransactionService: Using MF Central V2 endpoint',
          tag: 'InvestmentTransactionService',
        );
      }

      if (isinCode != null && isinCode.isNotEmpty && !useMfCentralV2) {
        url += "&isin=$isinCode";
        AppLogger.info(
          'InvestmentTransactionService: Fetching transactions for specific ISIN: $isinCode',
          tag: 'InvestmentTransactionService',
        );
      } else if (!useMfCentralV2) {
        AppLogger.info(
          'InvestmentTransactionService: No ISIN provided, fetching all transactions',
          tag: 'InvestmentTransactionService',
        );
      }
      AppLogger.info(
        'InvestmentTransactionService: GET $url',
        tag: 'InvestmentTransactionService',
      );

      final response = await NetworkAPIHelper().get(
        url,
        //   additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Investment Transactions Response: ${responseData.toString()}',
          tag: 'InvestmentTransactionService',
        );

        InvestmentTransactions parsed;

        if (useMfCentralV2) {
          // MF Central V2 returns: {success: true, data: [...]}
          // Transform to expected format
          if (responseData['success'] == true && responseData['data'] is List) {
            final mfTransactions = (responseData['data'] as List)
                .map((item) => Investment.fromJson(item as Map<String, dynamic>))
                .toList();

            // Filter by ISIN and/or Folio if provided
            var filteredMfs = mfTransactions;
            
            if (isinCode != null && isinCode.trim().isNotEmpty) {
              filteredMfs = filteredMfs.where((t) => t.isin == isinCode.trim()).toList();
            }
            
            if (folioNo != null && folioNo.trim().isNotEmpty) {
              filteredMfs = filteredMfs.where((t) => t.folio_no == folioNo.trim()).toList();
            }

            parsed = InvestmentTransactions(
              statusCode: 200,
              message: 'Success',
              data: Data(
                etfs: [],
                equities: [],
                mfs: filteredMfs,
              ),
            );
          } else {
            parsed = InvestmentTransactions(
              statusCode: response.statusCode,
              message: responseData['message'] ?? 'Unknown error',
              data: null,
            );
          }
        } else {
          // Standard API format
          parsed = InvestmentTransactions.fromJson(responseData);

          // Client-side filtering by ISIN as the backend sometimes returns unrelated assets
          if (isinCode != null &&
              isinCode.trim().isNotEmpty &&
              parsed.data != null) {
            final isin = isinCode.trim();
            parsed.data!.etfs =
                parsed.data!.etfs.where((e) => (e.isin ?? e.brokercode) == isin).toList();
            parsed.data!.equities =
                parsed.data!.equities.where((e) => (e.isin ?? e.brokercode) == isin).toList();
            parsed.data!.mfs =
                parsed.data!.mfs.where((e) => (e.isin ?? e.brokercode) == isin).toList();
          }
        }

        // If backend returns statusCode in body, respect HTTP code for safety
        if (response.statusCode == 200 || response.statusCode == 201) {
          return parsed;
        } else {
          return InvestmentTransactions(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return InvestmentTransactions(
        statusCode: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Investment Transactions Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InvestmentTransactionService',
      );
      return InvestmentTransactions(
        statusCode: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
