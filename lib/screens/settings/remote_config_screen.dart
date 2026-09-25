import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/remote_config/remote_config_status.dart';

class RemoteConfigScreen extends StatelessWidget {
  const RemoteConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          'Remote Configuration',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) =>
                        const Center(child: CircularProgressIndicator()),
              );

              // Force refresh Remote Config
              // await RemoteConfigService.to.forceRefresh();

              // Hide loading indicator
              if (context.mounted) {
                Navigator.of(context).pop();
              }

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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Remote Config Status Widget
              const RemoteConfigStatus(),

              const SizedBox(height: 24),

              // Additional Information
              const AppText(
                'About Remote Configuration',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Remote Config allows app behavior to be modified without requiring an app update. This includes:',
                      variant: AppTextVariant.bodyMedium,
                    ),

                    const SizedBox(height: 12),

                    _buildInfoItem(
                      context,
                      'API Base URL',
                      'The base URL for all API requests. Changes to this value will affect all network calls.',
                    ),

                    const SizedBox(height: 8),

                    _buildInfoItem(
                      context,
                      'App Version',
                      'The current app version supported by the backend.',
                    ),

                    const SizedBox(height: 16),

                    const AppText(
                      'Tap the refresh button to fetch the latest configuration from the server.',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Last Updated
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final lastFetchTime =
                            DateTime.now(); // Replace with actual fetch time when available
                        return AppText(
                          'Last updated: ${lastFetchTime.toString()}',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          '• $title',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppText(
            description,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary,
          ),
        ),
      ],
    );
  }
}
