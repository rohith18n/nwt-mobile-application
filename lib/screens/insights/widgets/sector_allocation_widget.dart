import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SectorItem {
  final String name;
  final double percentage;
  final Color progressColor;

  const SectorItem({
    required this.name,
    required this.percentage,
    required this.progressColor,
  });

  // Factory constructor to create a SectorItem from SectorData
  factory SectorItem.fromSectorData(SectorData data, Color color) {
    return SectorItem(
      name: data.sectorName,
      percentage: data.percentage,
      progressColor: color,
    );
  }
}

class SectorAllocationWidget extends StatefulWidget {
  final List<SectorItem> sectorItems;

  const SectorAllocationWidget({super.key, required this.sectorItems});

  // Factory constructor to create widget from Sectorallocation data
  factory SectorAllocationWidget.fromSectorallocation(
    Sectorallocation sectorallocation,
  ) {
    // Define a list of colors to use for the sectors
    final List<Color> sectorColors = [
      const Color(0xFF36D399), // Green
      const Color(0xFFF87272), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF3ABFF8), // Blue
      const Color(0xFFFFB86C), // Orange
      const Color(0xFFFBBD23), // Yellow
      const Color(0xFFFF79C6), // Pink
      const Color(0xFF9BE9A8), // Light Green
      const Color(0xFFA78BFA), // Light Purple
      const Color(0xFF93C5FD), // Light Blue
    ];

    // Sort sectors by percentage in descending order
    final sortedSectors = List<SectorData>.from(sectorallocation.sectors)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    // Create SectorItems from the sorted sectors
    final sectorItems = <SectorItem>[];
    for (int i = 0; i < sortedSectors.length; i++) {
      final color = sectorColors[i % sectorColors.length];
      sectorItems.add(SectorItem.fromSectorData(sortedSectors[i], color));
    }

    return SectorAllocationWidget(sectorItems: sectorItems);
  }

  @override
  State<SectorAllocationWidget> createState() => _SectorAllocationWidgetState();
}

class _SectorAllocationWidgetState extends State<SectorAllocationWidget> {
  static const int _initialItemCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayItems =
        _showAll
            ? widget.sectorItems
            : widget.sectorItems.take(_initialItemCount).toList();

    final hasMoreItems = widget.sectorItems.length > _initialItemCount;

    return CustomAccordion(
      title: 'Sector Allocation',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayItems.map((item) => _buildSectorRow(item)),

          // Show "See All" or "Show Less" button if there are more than 5 items
          if (hasMoreItems)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      _showAll ? 'Show Less' : 'See All',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.link,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAll
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.linkColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectorRow(SectorItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            item.name,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),

          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF37333D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    FractionallySizedBox(
                      widthFactor: item.percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.progressColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Percentage text
              const SizedBox(width: 16),
              AppText(
                '${item.percentage}%',
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
