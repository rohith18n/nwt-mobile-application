import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// A widget that displays the current status of Remote Config values
/// and provides a button to refresh them
class RemoteConfigStatus extends StatelessWidget {
  const RemoteConfigStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService.to;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Remote Config Status',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.lightPrimary),
                  tooltip: 'Refresh configuration',
                  onPressed: () async {
                    // Show loading indicator
                    final loadingOverlay = _showLoadingOverlay(context);

                    // Force refresh Remote Config
                    await remoteConfig.forceRefresh();

                    // Hide loading indicator
                    loadingOverlay.remove();

                    // Show success snackbar
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Remote Config refreshed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // API Base URL
          Obx(
            () => _buildConfigItem('API Base URL', remoteConfig.baseUrl.value),
          ),

          const SizedBox(height: 16),

          // App Version
          Obx(
            () =>
                _buildConfigItem('Minimum App Version', remoteConfig.minimumAppVersion.value),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  OverlayEntry _showLoadingOverlay(BuildContext context) {
    final overlay = OverlayEntry(
      builder:
          (context) => Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const AppText(
                      'Updating configuration...',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(overlay);
    return overlay;
  }
}
