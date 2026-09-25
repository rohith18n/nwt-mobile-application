import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class InsightsService {
  // Cache the last fetched insights data
  InsightsSummary? _cachedInsightData;

  // Fetch mutual fund insights data using the provided fund ID
  Future<MutualFundInsightRespose> getMFInsights({
    required Function(bool isLoading) onLoading,
    String? isincode,
  }) async {
    onLoading(true);
    try {
      // Construct the URL with ISIN parameter if provided
      String url = ApiURLs.MUTUAL_FUNDS_DETAIL;
      if (isincode != null && isincode.isNotEmpty) {
        url = "$url?isin=$isincode";
      }

      final response = await NetworkAPIHelper().get(url);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        // AppLogger.info(
        //   'Get MF Insights Response: ${responseData.toString()}',
        //   tag: 'InsightsService',
        // );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final insightResponse = MutualFundInsightRespose.fromJson(
            responseData,
          );
          // Cache the data if available
          if (insightResponse.data != null) {
            _cachedInsightData = insightResponse.data;
          }
          return insightResponse;
        } else {
          return MutualFundInsightRespose(
            status: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Get MF Insights Error',
        error: e,
        tag: 'InsightsService',
        stackTrace: subTrace,
      );
      return MutualFundInsightRespose(
        status: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
    return MutualFundInsightRespose(
      status: 0,
      message: 'Unknown error',
      data: null,
    );
  }

  // Get the specific fund insights for the provided ID
  Future<InsightsSummary?> getSpecificFundInsights({
    required Function(bool isLoading) onLoading,
    required String isincode,
  }) async {
    final response = await getMFInsights(
      onLoading: onLoading,
      isincode: isincode,
    );

    return response.data;
  }

  // Helper methods to access specific data for charts
  List<MFPerformanceDataPoint> getOneMonthPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .oneMonth;
  }

  List<MFPerformanceDataPoint> getThreeMonthPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .threeMonths;
  }

  List<MFPerformanceDataPoint> getSixMonthPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .sixMonths;
  }

  List<MFPerformanceDataPoint> getOneYearPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .oneYear;
  }

  List<MFPerformanceDataPoint> getFiveYearPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .fiveYears;
  }

  List<MFPerformanceDataPoint> getTenYearPerformanceData() {
    if (_cachedInsightData == null) return [];
    return _cachedInsightData!
        .mfreturnandsipreturn
        .mfreturnandsipreturnReturn
        .tenYears;
  }

  // // Helper methods to get SIP return data for all time periods
  // List<MFPerformanceDataPoint> getSipOneMonthPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.oneMonth;
  // }

  // List<MFPerformanceDataPoint> getSipThreeMonthPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.threeMonths;
  // }

  // List<MFPerformanceDataPoint> getSipSixMonthPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.sixMonths;
  // }

  // List<MFPerformanceDataPoint> getSipOneYearPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.oneYear;
  // }

  // List<MFPerformanceDataPoint> getSipFiveYearPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.fiveYears;
  // }

  // List<MFPerformanceDataPoint> getSipTenYearPerformanceData() {
  //   if (_cachedInsightData == null) return [];
  //   return _cachedInsightData!.mfreturnandsipreturn.sipreturn.tenYears;
  // }

  // // Get fund details
  Map<String, dynamic> getFundDetails() {
    if (_cachedInsightData == null) return {};

    return {
      'name': _cachedInsightData!.fundname,
      'type': _cachedInsightData!.fundtype,
      'nav': _cachedInsightData!.nav,
      'navDelta': _cachedInsightData!.navdelta,
      'expenseRatio': _cachedInsightData!.funddetail.expenseratio,
      'aum': _cachedInsightData!.funddetail.aum,
      'fundManager': _cachedInsightData!.funddetail.fundmanager,
      'investmentStyle': _cachedInsightData!.funddetail.investmentstyle,
      'exitLoad': _cachedInsightData!.funddetail.exitload,
    };
  }

  // Get asset allocation data
  Map<String, double> getAssetAllocation() {
    if (_cachedInsightData == null) return {};

    return {
      'equity': _cachedInsightData!.assetallocation.equity,
      'debt': _cachedInsightData!.assetallocation.debt,
      'hybrid': _cachedInsightData!.assetallocation.hybrid,
    };
  }

  // Get sector allocation data
  List<Map<String, dynamic>> getSectorAllocation() {
    if (_cachedInsightData == null) return [];

    return _cachedInsightData!.sectorallocation.sectors
        .map(
          (sector) => {
            'name': sector.sectorName,
            'percentage': sector.percentage,
            'value': sector.value,
            'sectorCode': sector.sectorCode,
          },
        )
        .toList();
  }

  // Get top holdings
  List<Map<String, dynamic>> getTopHoldings() {
    if (_cachedInsightData == null) return [];

    return _cachedInsightData!.topHoldings
        .map((holding) => {'name': holding.name, 'value': holding.value})
        .toList();
  }

  // Get performance score for a specific fund
  Future<PerformanceScoreResponse> getPerformanceScore({
    required Function(bool isLoading) onLoading,
    required String isincode,
  }) async {
    // Legacy atom.pivotmoney.app endpoints are strictly disabled.
    // Performance scores should be integrated into V1 detail/ in the future.
    return PerformanceScoreResponse(
      statusCode: 200,
      message: 'Feature migrating to V1',
      scores: [],
      green: 0,
      yellow: 0,
      red: 0,
      white: 0,
    );
  }
}
