import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';

/// Centralized controller for managing amount visibility across all screens
class AmountVisibilityController extends GetxController {
  static AmountVisibilityController get instance => Get.find();
  
  // Reactive variable that all screens can observe
  final RxBool _isAmountVisible = false.obs;
  
  // Getter for the current visibility state
  bool get isAmountVisible => _isAmountVisible.value;
  
  // Getter for reactive listening
  RxBool get isAmountVisibleRx => _isAmountVisible;
  
  @override
  void onInit() {
    super.onInit();
    _restoreFromStorage();
  }
  
  /// Restore visibility state from storage on initialization
  void _restoreFromStorage() {
    final savedVisibility = StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? false;
    _isAmountVisible.value = savedVisibility;
    print('AmountVisibilityController: Restored visibility from storage: $savedVisibility');
  }
  
  /// Toggle visibility and save to storage
  void toggleVisibility() {
    _isAmountVisible.value = !_isAmountVisible.value;
    StorageService.write(StorageKeys.AMOUNT_VISIBILITY_KEY, _isAmountVisible.value);
    print('AmountVisibilityController: Toggled visibility to: ${_isAmountVisible.value}');
  }
  
  /// Set visibility state directly
  void setVisibility(bool isVisible) {
    _isAmountVisible.value = isVisible;
    StorageService.write(StorageKeys.AMOUNT_VISIBILITY_KEY, _isAmountVisible.value);
    print('AmountVisibilityController: Set visibility to: ${_isAmountVisible.value}');
  }
}
