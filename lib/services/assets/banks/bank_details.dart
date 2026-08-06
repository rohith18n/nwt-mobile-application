import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/assets/banks/types/bank_details.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class BankDetailsService {
  Future<BankDetailsResponse> getBankDetails({
    required String accountguid,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final url =
          "${ApiURLs.USER_DASHBOARD_ASSET_BANK}/$accountguid/details/?view=bank";

      final response = await NetworkAPIHelper().get(url);

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Bank Details Response: ${responseData.toString()}',
          tag: 'BankDetailsService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return BankDetailsResponse.fromJson(responseData);
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error');
        }
      }

      throw Exception('No response received');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Bank Details Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'BankDetailsService',
      );
      rethrow;
    } finally {
      onLoading(false);
    }
  }
}
