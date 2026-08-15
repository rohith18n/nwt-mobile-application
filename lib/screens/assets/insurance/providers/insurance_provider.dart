import 'package:flutter/foundation.dart';

class InsuranceProvider with ChangeNotifier {
  bool _showBanner = true;

  bool get showInsuranceBanner => _showBanner;

  void hideBanner() {
    _showBanner = false;
    notifyListeners();
  }

  // Call this method to reset the banner visibility if needed
  void resetBanner() {
    _showBanner = true;
    notifyListeners();
  }
}
