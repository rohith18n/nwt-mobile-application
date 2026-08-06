import 'package:get/get.dart';
import 'package:nwt_app/screens/assets/investments/types/portfolio.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
import 'package:nwt_app/services/assets/investments/investments.dart';
import 'package:nwt_app/services/dashboard/dashboard_assets.dart';
import 'package:nwt_app/utils/logger.dart';

class DashboardAssetController extends GetxController {
  final _dashboardAssetsService = DashboardAssetsService();
  final _investmentService = InvestmentService();

  final isLoading = false.obs;
  final dashboardAssets = Rx<DashboardAssetsResponse?>(null);
  final portfolio = Rx<InvestmentPortfolio?>(null);

  void _setLoading(bool loading) {
    isLoading.value = loading;
    // Ensure GetBuilder<DashboardAssetController> rebuilds deterministically.
    update();
  }

  @override
  void onInit() {
    super.onInit();
  }

  /// Fetches dashboard assets data from the service
  Future<void> fetchDashboardAssets() async {
    final assetResponse = await _dashboardAssetsService.getDashboardAssets(
      onLoading: _setLoading,
    );

    if (assetResponse != null && assetResponse.success) {
      dashboardAssets.value = assetResponse;
      update();
    } else {
      AppLogger.error(
        'Failed to fetch dashboard assets',
        tag: 'DashboardAssetController',
      );
    }
  }

  /// Refreshes all dashboard assets data
  Future<void> refreshDashboardAssets() async {
    _setLoading(true);
    try {
      // Clear cache to ensure fresh data
      _dashboardAssetsService.clearCache();

      // Fetch fresh data
      await fetchDashboardAssets();

      AppLogger.info(
        'Dashboard assets refreshed',
        tag: 'DashboardAssetController',
      );
    } finally {
      _setLoading(false);
    }
  }

  void getDashboardAssets({required Function(bool isLoading) onLoading}) {
    onLoading(true);
    fetchDashboardAssets().then((_) {
      onLoading(false);
    });
  }
}
