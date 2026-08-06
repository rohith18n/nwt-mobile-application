import 'package:get/get.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/services/assets/banks/banks.dart';

class BankController extends GetxController {
  BankSummaryResponse? bankSummary;
  BankService bankService = BankService();

  Future<void> getBankSummary({
    required Function(bool isLoading) onLoading,
    bool forceStandard = false,
  }) async {
    onLoading(true);
    try {
      final value = await bankService.getBankSummary(
        onLoading: (isLoading) {
          // We handle loading state here to ensure bankSummary is updated first
        },
      );
      print('Bank Summary Response: ${value.toJson()}');
      if (value.data != null) {
        print('Bank Summary Data: ${value.data!.toJson()}');
      }
      bankSummary = value;
      update();
    } catch (e) {
      print('Error fetching bank summary: $e');
    } finally {
      onLoading(false);
    }
  }
}
