import 'package:get/get.dart';
import 'package:nwt_app/widgets/common/data_fetch_status_bar.dart';

class DataFetchStatusController extends GetxController {
  // Observable list of bank statuses
  final bankStatuses = <BankFetchStatus>[].obs;

  // Add a new bank status or update existing one
  void updateBankStatus({
    required String bankName,
    String? logoUrl,
    required DataFetchStatus status,
  }) {
    final now = DateTime.now();

    // Check if bank already exists in the list
    final existingIndex = bankStatuses.indexWhere(
      (bank) => bank.bankName == bankName,
    );

    if (existingIndex >= 0) {
      // Update existing bank status
      bankStatuses[existingIndex] = BankFetchStatus(
        bankName: bankName,
        logoUrl: logoUrl ?? bankStatuses[existingIndex].logoUrl,
        status: status,
        timestamp: now,
      );
    } else {
      // Add new bank status
      bankStatuses.add(
        BankFetchStatus(
          bankName: bankName,
          logoUrl: logoUrl,
          status: status,
          timestamp: now,
        ),
      );
    }
  }

  // Clear all bank statuses
  void clearStatuses() {
    bankStatuses.clear();
  }

  // Get counts by status type
  int getSuccessfulCount() {
    return bankStatuses
        .where((bank) => bank.status == DataFetchStatus.successful)
        .length;
  }

  int getProcessingCount() {
    return bankStatuses
        .where((bank) => bank.status == DataFetchStatus.processing)
        .length;
  }

  int getFailedCount() {
    return bankStatuses
        .where((bank) => bank.status == DataFetchStatus.failed)
        .length;
  }

  // Check if we have any statuses to show
  bool get hasStatuses => bankStatuses.isNotEmpty;

  // Get overall status
  DataFetchStatus get overallStatus {
    if (bankStatuses.isEmpty) {
      return DataFetchStatus.successful;
    }

    if (bankStatuses.any((bank) => bank.status == DataFetchStatus.processing)) {
      return DataFetchStatus.processing;
    }

    if (bankStatuses.any((bank) => bank.status == DataFetchStatus.failed)) {
      return DataFetchStatus.failed;
    }

    return DataFetchStatus.successful;
  }
}
