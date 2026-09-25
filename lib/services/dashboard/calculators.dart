import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/dashboard/types/calculators.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class CalculatorService {
  Future<CalculatorResponse?> getCalculators({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_CALCULATORS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get Calculators Response: ${responseData.toString()}',
          tag: 'calculators',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return CalculatorResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get Calculators Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'calculators',
      );
      return null;
    } finally {
      onLoading(false);
    }
  }
}
