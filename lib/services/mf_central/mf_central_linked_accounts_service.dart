import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/types/mf_central/mf_central_linked_account.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Service for fetching MF Central linked accounts
/// Used to populate the Linked Accounts screen
class MFCentralLinkedAccountsService {
  static const String _tag = 'MFC_LinkedAccounts';

  /// Fetches linked MF Central accounts
  /// Endpoint: GET /api/v2/portfolio/linked-accounts/
  Future<MFCentralLinkedAccountsResponse> fetchLinkedAccounts() async {
    try {
      AppLogger.info('Fetching MF Central linked accounts...', tag: _tag);

      final response = await NetworkAPIHelper().get(
        ApiURLs.MF_CENTRAL_LINKED_ACCOUNTS,
      );

      if (response == null) {
        AppLogger.error('Null response from linked accounts API', tag: _tag);
        return MFCentralLinkedAccountsResponse(
          success: false,
          data: [],
          message: 'No response from server',
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final result = MFCentralLinkedAccountsResponse.fromJson(decoded);

        AppLogger.info(
          'Fetched ${result.data.length} linked accounts',
          tag: _tag,
        );

        return result;
      } else if (response.statusCode == 401) {
        AppLogger.error('Unauthorized - token expired', tag: _tag);
        return MFCentralLinkedAccountsResponse(
          success: false,
          data: [],
          message: 'Authentication required',
        );
      } else {
        AppLogger.error(
          'Linked accounts API error: ${response.statusCode}',
          tag: _tag,
        );
        return MFCentralLinkedAccountsResponse(
          success: false,
          data: [],
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching linked accounts',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return MFCentralLinkedAccountsResponse(
        success: false,
        data: [],
        message: 'Network error: $e',
      );
    }
  }
}
