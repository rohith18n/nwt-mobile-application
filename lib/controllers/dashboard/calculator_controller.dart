import 'package:get/get.dart';
import 'package:nwt_app/screens/dashboard/types/calculators.dart';
import 'package:nwt_app/services/dashboard/calculators.dart';
import 'package:nwt_app/utils/logger.dart';

class CalculatorController extends GetxController {
  final _calculatorService = CalculatorService();

  final isLoading = false.obs;
  final calculators = <CalculatorItem>[].obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchCalculators() async {
    final response = await _calculatorService.getCalculators(
      onLoading: (loading) => isLoading.value = loading,
    );

    if (response != null && response.success) {
      calculators.assignAll(response.data.calculators);
    } else {
      AppLogger.error('Failed to fetch calculators', tag: 'calculators');
    }
  }
}
