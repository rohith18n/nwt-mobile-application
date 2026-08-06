import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/types/portfolio.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class EditAverageBuyPriceResponse {
  final int statusCode;
  final String message;
  final dynamic data;

  EditAverageBuyPriceResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory EditAverageBuyPriceResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return EditAverageBuyPriceResponse(
      statusCode: statusCode ?? json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class InvestmentService {
  Future<EditAverageBuyPriceResponse?> editAverageBuyPrice({
    required String category,
    required double value,
    required String isin,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final body = {"isin": isin, "avg_buy_price": value};

      final response = await NetworkAPIHelper().put(
        ApiURLs.PORTFOLIO_HOLDINGS_COST,
        body,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Edit Average Buy Price Response: ${responseData.toString()}',
          tag: 'InvestmentService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EditAverageBuyPriceResponse.fromJson(responseData, statusCode: response.statusCode);
        } else {
          return EditAverageBuyPriceResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to update average buy price',
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Edit Average Buy Price Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InvestmentService',
      );
      return EditAverageBuyPriceResponse(
        statusCode: 0,
        message:
            'An unexpected error occurred while updating average buy price',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<EditAverageBuyPriceResponse?> deleteAverageBuyPrice({
    required String isin,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().delete(
        '${ApiURLs.PORTFOLIO_HOLDINGS_COST}?isin=$isin',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Delete Average Buy Price Response: ${responseData.toString()}',
          tag: 'InvestmentService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EditAverageBuyPriceResponse.fromJson(responseData, statusCode: response.statusCode);
        } else {
          return EditAverageBuyPriceResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ?? 'Failed to reset average buy price',
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Delete Average Buy Price Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InvestmentService',
      );
      return EditAverageBuyPriceResponse(
        statusCode: 0,
        message:
            'An unexpected error occurred while resetting average buy price',
      );
    } finally {
      onLoading(false);
    }
  }

  Future<InvestmentPortfolioResponse?> getPortfolio({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(
        ApiURLs.GET_USER_INVESTMENTS,
        // additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Portfolio Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return InvestmentPortfolioResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Get Portfolio Error', error: e, tag: 'AuthService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  Future<InvestmentHoldingsResponse> getHoldings({
    required Function(bool isLoading) onLoading,
    bool useMfCentralV2 = false,
  }) async {
    onLoading(true);
    try {
      final url = useMfCentralV2
          ? ApiURLs.MF_CENTRAL_USER_HOLDINGS
          : ApiURLs.GET_USER_HOLDINGS;

      AppLogger.info(
        'Get Holdings: Using ${useMfCentralV2 ? "MF Central V2" : "Standard"} endpoint: $url',
        tag: 'InvestmentService',
      );

      final response = await NetworkAPIHelper().get(
        url,
        // additionalHeaders: {'Authorization': 'Bearer ${ApiURLs.tempToken}'},
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Holdings Response: ${responseData.toString()}',
          tag: 'InvestmentService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (useMfCentralV2) {
            // MF Central V2 returns: {success: true, data: [...]}
            // Transform to expected format
            if (responseData['success'] == true && responseData['data'] is List) {
              final mfHoldings = (responseData['data'] as List)
                  .map((item) => Mf.fromJson(item as Map<String, dynamic>))
                  .toList();

              return InvestmentHoldingsResponse(
                status: 200,
                message: 'Success',
                data: HoldingsData(
                  investments: Investments(
                    stocks: [],
                    mf: mfHoldings,
                    etf: [],
                    profiles: [],
                  ),
                ),
              );
            } else {
              return InvestmentHoldingsResponse(
                status: response.statusCode,
                message: responseData['message'] ?? 'Unknown error',
                data: null,
              );
            }
          } else {
            // Standard API format
            return InvestmentHoldingsResponse.fromJson(responseData);
          }
        } else {
          return InvestmentHoldingsResponse(
            status: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return InvestmentHoldingsResponse(
        status: 0,
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Holdings Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'InvestmentService',
      );
      return InvestmentHoldingsResponse(
        status: 0,
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }
}
