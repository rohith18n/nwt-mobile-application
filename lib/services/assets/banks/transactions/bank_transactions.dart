import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_parser.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class BankTransactionService {
  bool _shouldUseRawAssetController() {
    if (!Get.isRegistered<RawAssetController>()) return false;
    if (!Get.isRegistered<UserController>())
      return true; // allow non-UI contexts/tests
    final user = Get.find<UserController>().userData;
    return user?.isFinarkeinAa == true;
  }

  Future<BankTransactionResponse> getBankTransactions({
    List<String>? bankGUIDs,
    double? amountMin,
    double? amountMax,
    DateTime? startDate,
    DateTime? endDate,
    required Function(bool isLoading) onLoading,
    int page = 0,
    int limit = 5,
    bool forceStandard = false,
  }) async {
    onLoading(true);
    try {
      // Finarkein override: derive transactions from RawAssetController (no UI model changes).
      if (!forceStandard && _shouldUseRawAssetController()) {
        final controller = Get.find<RawAssetController>();

        // Fetch transactions if not already loaded
        if (controller.bankTransactions.isEmpty) {
          await controller.fetchBankTransactions();
        }

        // Convert raw maps to Banktransation objects using the robust parser
        var items =
            controller.bankTransactions
                .map(
                  (txn) => FinarkeinDataResultParser.rowToBankTransaction(txn),
                )
                .whereType<Banktransation>()
                .toList();

        // Filter by bank GUIDs
        if (bankGUIDs != null && bankGUIDs.isNotEmpty) {
          final set =
              bankGUIDs.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
          items = items.where((t) => set.contains(t.accountguid)).toList();
        }

        // Amount filters (absolute like Saafe flow)
        if (amountMin != null) {
          final min = amountMin.abs();
          items = items.where((t) => t.amount.abs() >= min).toList();
        }
        if (amountMax != null) {
          final max = amountMax.abs();
          items = items.where((t) => t.amount.abs() <= max).toList();
        }

        // Date filters (inclusive)
        if (startDate != null) {
          items =
              items
                  .where((t) => !t.transactiontimestamp.isBefore(startDate))
                  .toList();
        }
        if (endDate != null) {
          final endInclusive = endDate.add(const Duration(days: 1));
          items =
              items
                  .where((t) => t.transactiontimestamp.isBefore(endInclusive))
                  .toList();
        }

        // Sort newest first
        items.sort(
          (a, b) => b.transactiontimestamp.compareTo(a.transactiontimestamp),
        );

        final total = items.length;
        final safeLimit = limit <= 0 ? 10 : limit;
        final safePage = page < 0 ? 0 : page;
        final startIdx = safePage * safeLimit;
        final endIdx =
            (startIdx + safeLimit) > total ? total : (startIdx + safeLimit);
        final pageItems =
            startIdx >= total
                ? <Banktransation>[]
                : items.sublist(startIdx, endIdx);
        final totalpages =
            total == 0 ? 0 : ((total + safeLimit - 1) ~/ safeLimit);
        final maxAmount =
            items.isEmpty
                ? 0.0
                : items
                    .map((t) => t.amount.abs())
                    .reduce((a, b) => a > b ? a : b);

        return BankTransactionResponse(
          status: 200,
          message: 'OK',
          data: TransactionData(
            banktransations: pageItems,
            pagination: Pagination(
              total: total,
              page: safePage,
              limit: safeLimit,
              totalpages: totalpages,
            ),
            maxamount: maxAmount,
          ),
        );
      }

      // Start with base URL and required pagination parameters
      String url = "${ApiURLs.GET_BANK_TRANSACTION}?page=$page&limit=$limit";

      // Add bank GUIDs if provided (supports multiple banks)
      if (bankGUIDs != null && bankGUIDs.isNotEmpty) {
        // Add each bank GUID as a separate parameter for multiple selection
        for (String guid in bankGUIDs) {
          url += "&bankguid=$guid";
        }
      }

      // Add amount filters if provided
      if (amountMin != null) {
        // Use absolute value for amount filtering
        url += "&amountmin=${amountMin.abs().round()}";
      }
      if (amountMax != null) {
        // Use absolute value for amount filtering
        url += "&amountmax=${amountMax.abs().round()}";
      }

      // Add date filters if provided
      if (startDate != null) {
        // Format date as YYYY-MM-DD
        String formattedStartDate =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
        url += "&startdate=$formattedStartDate";
      }
      if (endDate != null) {
        // Format date as YYYY-MM-DD
        String formattedEndDate =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
        url += "&enddate=$formattedEndDate";
      }

      final response = await NetworkAPIHelper().get(
        url,
        // additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Bank Transactions Response: ${responseData.toString()}',
          tag: 'BankTransactionService',
        );
        final parsedResponse = BankTransactionResponse.fromJson(responseData);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return parsedResponse;
        } else {
          return BankTransactionResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return BankTransactionResponse(
        status: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Bank Transactions Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'BankTransactionService',
      );
      return BankTransactionResponse(
        status: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
