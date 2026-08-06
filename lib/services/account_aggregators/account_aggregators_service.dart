import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/connections/types/aa_create_consent.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class AccountAggregatorsService {
  Future<AaCreateConsentResponse?> createConsent({
    required String identifier,
    required String type,
    required String frontendUrl,
    required List<String> assetNames,
    required List<String> fipids,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final body = {
        "identifier": identifier,
        "type": type,
        "frontend_url": frontendUrl,
        "assetNames": assetNames,
        "fipids": fipids,
      };

      final response = await NetworkAPIHelper().post(
        ApiURLs.ACCOUNT_AGGREGATORS_CREATE_CONSENT,
        jsonEncode(body),
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Create Consent Response: ${responseData.toString()}',
          tag: 'AccountAggregatorsService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return AaCreateConsentResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Create Consent Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountAggregatorsService',
      );
      return null;
    } finally {
      onLoading(false);
    }
  }
}
