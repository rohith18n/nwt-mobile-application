import 'package:get/get.dart';
import 'package:nwt_app/services/profile/holder_service.dart';
import 'package:nwt_app/types/profile/holder.dart';
import 'package:nwt_app/services/network/network_interceptor.dart';
import 'package:nwt_app/utils/logger.dart';

class HolderController extends GetxController {
  final HolderService _holderService = HolderService();

  var holders = <Holder>[].obs;
  var isLoading = false.obs;
  var isDetailLoading = false.obs;
  var isOperationLoading = false.obs;
  var error = RxnString();
  var operationMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchHolders();
  }

  Future<void> fetchHolders({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    error.value = null;
    try {
      final response = await _holderService.listHolders();
      if (response != null && response.success) {
        holders.value = response.data.holders ?? [];
      } else {
        error.value = response?.message ?? "Failed to fetch holders";
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> refreshHolderDetail(int id) async {
    isDetailLoading.value = true;
    try {
      final updated = await _holderService.getHolderDetail(id);
      if (updated != null) {
        final index = holders.indexWhere((h) => h.id == id);
        if (index != -1) {
          holders[index] = updated;
          holders.refresh();
        } else {
          holders.add(updated);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error refreshing holder detail',
        error: e,
        tag: 'HolderController',
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<bool> addHolder(String panNumber) async {
    isOperationLoading.value = true;
    operationMessage.value = null;
    try {
      final response = await _holderService.addHolder(panNumber);
      if (response != null) {
        operationMessage.value = response.message;
        if (response.success) {
          await fetchHolders(silent: true);
          return true;
        } else {
          return false;
        }
      }

      // If response is null (e.g. 500 error), still try to refresh as requested
      // operationMessage.value =
      //   "Something went wrong on the server, but the holder might have been added. Refreshing...";
      await fetchHolders(silent: true);
      return true;
    } on NetworkException catch (e) {
      if (e.errorType == NetworkErrorType.timeout) {
        operationMessage.value =
            "Verification is taking longer than expected. We've refreshed the list to check if the holder was added.";
        await fetchHolders(silent: true);
        return true;
      }
      operationMessage.value = e.message;
      return false;
    } catch (e) {
      operationMessage.value =
          "An unexpected error occurred. Refreshing to verify...";
      await fetchHolders(silent: true);
      return true;
    } finally {
      isOperationLoading.value = false;
    }
  }

  Future<bool> updateHolder(int id, Map<String, dynamic> data) async {
    isOperationLoading.value = true;
    try {
      final updated = await _holderService.updateHolder(id, data);
      if (updated != null) {
        // Update local list
        final index = holders.indexWhere((h) => h.id == id);
        if (index != -1) {
          holders[index] = updated;
          holders.refresh();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isOperationLoading.value = false;
    }
  }

  Future<bool> removeHolder(int id) async {
    isOperationLoading.value = true;
    try {
      final success = await _holderService.removeHolder(id);
      if (success) {
        holders.removeWhere((h) => h.id == id);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isOperationLoading.value = false;
    }
  }
}
