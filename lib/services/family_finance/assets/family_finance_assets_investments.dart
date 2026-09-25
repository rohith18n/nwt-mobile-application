import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_investments.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class FamilyFinanceAssetsInvestmentsService {
  Future<FamilyFinanceInvestmentsResponse> getFamilyFinanceAssetsInvestments({
    required String familyId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      String url = ApiURLs.GET_FAMILY_DASHBOARD_ASSET_INVESTMENTS(familyId);

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Family Finance Investments Response: ${responseData.toString()}',
          tag: 'FamilyFinanceAssetsInvestmentsService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final familyFinanceInvestmentsResponse =
              FamilyFinanceInvestmentsResponse.fromJson(responseData);

          return familyFinanceInvestmentsResponse;
        } else {
          return FamilyFinanceInvestmentsResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: FamilyFinanceInvestmentsData(
              members: [],
              summary: FamilyFinanceInvestmentsSummary(
                etf: FamilyFinanceInvestmentsSummaryClass(
                  avgnav: 0.0,
                  totalsum: 0.0,
                  totalunits: 0.0,
                  avgcurrentvalue: 0.0,
                ),
                equity: FamilyFinanceInvestmentsEquitySummary(
                  avggain: 0.0,
                  avgdelta: 0.0,
                  totalsum: 0.0,
                  totalgain: 0.0,
                  avgcostvalue: 0.0,
                  avgdeltavalue: 0.0,
                  totalinvested: 0.0,
                  avggainpercent: 0.0,
                  avgcurrentvalue: 0.0,
                ),
                mutualFunds: FamilyFinanceInvestmentsMutualFundsSummary(
                  avgnav: 0.0,
                  avggain: 0.0,
                  totalsum: 0.0,
                  totalgain: 0.0,
                  avgcostvalue: 0.0,
                  totalinvested: 0.0,
                  avgcurrentvalue: 0.0,
                ),
              ),
            ),
          );
        }
      } else {
        return FamilyFinanceInvestmentsResponse(
          statusCode: 0,
          message: 'Unknown error',
          data: FamilyFinanceInvestmentsData(
            members: [],
            summary: FamilyFinanceInvestmentsSummary(
              etf: FamilyFinanceInvestmentsSummaryClass(
                avgnav: 0.0,
                totalsum: 0.0,
                totalunits: 0.0,
                avgcurrentvalue: 0.0,
              ),
              equity: FamilyFinanceInvestmentsEquitySummary(
                avggain: 0.0,
                avgdelta: 0.0,
                totalsum: 0.0,
                totalgain: 0.0,
                avgcostvalue: 0.0,
                avgdeltavalue: 0.0,
                totalinvested: 0.0,
                avggainpercent: 0.0,
                avgcurrentvalue: 0.0,
              ),

              mutualFunds: FamilyFinanceInvestmentsMutualFundsSummary(
                avgnav: 0.0,
                avggain: 0.0,
                totalsum: 0.0,
                totalgain: 0.0,
                avgcostvalue: 0.0,
                totalinvested: 0.0,
                avgcurrentvalue: 0.0,
              ),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Family Finance Investments Error',
        error: e,
        tag: 'FamilyFinanceAssetsInvestmentsService',
        stackTrace: stackTrace,
      );
      return FamilyFinanceInvestmentsResponse(
        statusCode: 500,
        message: 'Error: ${e.toString()}',
        data: FamilyFinanceInvestmentsData(
          members: [],
          summary: FamilyFinanceInvestmentsSummary(
            etf: FamilyFinanceInvestmentsSummaryClass(
              avgnav: 0.0,
              totalsum: 0.0,
              totalunits: 0.0,
              avgcurrentvalue: 0.0,
            ),
            equity: FamilyFinanceInvestmentsEquitySummary(
              avggain: 0.0,
              avgdelta: 0.0,
              totalsum: 0.0,
              totalgain: 0.0,
              avgcostvalue: 0.0,
              avgdeltavalue: 0.0,
              totalinvested: 0.0,
              avggainpercent: 0.0,
              avgcurrentvalue: 0.0,
            ),

            mutualFunds: FamilyFinanceInvestmentsMutualFundsSummary(
              avgnav: 0.0,
              avggain: 0.0,
              totalsum: 0.0,
              totalgain: 0.0,
              avgcostvalue: 0.0,
              totalinvested: 0.0,
              avgcurrentvalue: 0.0,
            ),
          ),
        ),
      );
    } finally {
      onLoading(false);
    }
  }
}
