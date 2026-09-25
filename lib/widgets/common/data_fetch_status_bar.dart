import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

enum DataFetchStatus { successful, processing, failed }

class BankFetchStatus {
  final String bankName;
  final String? logoUrl;
  final DataFetchStatus status;
  final DateTime timestamp;

  BankFetchStatus({
    required this.bankName,
    this.logoUrl,
    required this.status,
    required this.timestamp,
  });
}

class DataFetchStatusBar extends StatelessWidget {
  final List<BankFetchStatus> bankStatuses;

  const DataFetchStatusBar({super.key, required this.bankStatuses});

  @override
  Widget build(BuildContext context) {
    if (bankStatuses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Count statuses by type
    int successCount = 0;
    int processingCount = 0;
    int failedCount = 0;

    for (var status in bankStatuses) {
      switch (status.status) {
        case DataFetchStatus.successful:
          successCount++;
          break;
        case DataFetchStatus.processing:
          processingCount++;
          break;
        case DataFetchStatus.failed:
          failedCount++;
          break;
      }
    }

    // Determine overall status color and icon
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'All updated';
    
    if (processingCount > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
      statusText = 'Updating data...';
    } else if (failedCount > 0) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Update failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: processingCount > 0
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                : Icon(statusIcon, color: statusColor, size: 14),
            ),
          ),
          const SizedBox(width: 8),
          
          // Status text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                statusText,
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.white,
              ),
              Row(
                children: [
                  if (successCount > 0)
                    _buildStatusDot(count: successCount, color: Colors.green),
                  if (processingCount > 0) ...[  
                    if (successCount > 0) const SizedBox(width: 8),
                    _buildStatusDot(count: processingCount, color: Colors.orange),
                  ],
                  if (failedCount > 0) ...[  
                    if (successCount > 0 || processingCount > 0) const SizedBox(width: 8),
                    _buildStatusDot(count: failedCount, color: Colors.red),
                  ],
                ],
              ),
            ],
          ),
          
          // Last updated time
          if (bankStatuses.isNotEmpty) ...[  
            const SizedBox(width: 8),
            Container(
              height: 20,
              width: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildLastUpdatedIndicator(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusDot({required int count, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        AppText(
          count.toString(),
          variant: AppTextVariant.tiny,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.secondary,
        ),
      ],
    );
  }


  Widget _buildLastUpdatedIndicator() {
    // Find the most recent status update
    DateTime? mostRecent;
    for (var status in bankStatuses) {
      if (mostRecent == null || status.timestamp.isAfter(mostRecent)) {
        mostRecent = status.timestamp;
      }
    }

    if (mostRecent == null) return const SizedBox.shrink();

    final timeText = _getStatusTimeText(
      BankFetchStatus(
        bankName: '',
        status: DataFetchStatus.successful,
        timestamp: mostRecent,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          AppText(
            timeText,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.regular,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ),
    );
  }

  String _getStatusTimeText(BankFetchStatus status) {
    final now = DateTime.now();
    final difference = now.difference(status.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }


}
