import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AssetItem {
  final String name;
  final double percentage;
  final Color color;

  const AssetItem({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

class AssetAllocationWidget extends StatefulWidget {
  final List<AssetItem> assetItems;

  const AssetAllocationWidget({super.key, required this.assetItems});

  @override
  State<AssetAllocationWidget> createState() => _AssetAllocationWidgetState();
}

class _AssetAllocationWidgetState extends State<AssetAllocationWidget> {
  String? selectedAsset;
  int _chartRebuildKey = 0;

  @override
  void initState() {
    super.initState();
    selectedAsset = null;
  }

  @override
  void didUpdateWidget(AssetAllocationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetItems != widget.assetItems) {
      setState(() {
        selectedAsset = null;
        _chartRebuildKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomAccordion(
      title: 'Asset Allocation',
      initiallyExpanded: true,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.width * 0.35,
                child: _buildDonutChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildLegendItems(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AssetItem> _getSortedAssetItems() {
    return List<AssetItem>.from(widget.assetItems)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  Widget _buildDonutChart() {
    final sortedItems = _getSortedAssetItems();

    List<int> selectedIndexes = [];
    if (selectedAsset != null) {
      final index = sortedItems.indexWhere(
        (item) => item.name == selectedAsset,
      );
      if (index != -1) {
        selectedIndexes = [index];
      }
    }

    return SfCircularChart(
      key: ValueKey(_chartRebuildKey),
      margin: EdgeInsets.zero,
      series: <CircularSeries>[
        DoughnutSeries<AssetItem, String>(
          dataSource: sortedItems,
          xValueMapper: (AssetItem data, _) => data.name,
          yValueMapper:
              (AssetItem data, _) => data.percentage < 1 ? 1 : data.percentage,
          pointColorMapper: (AssetItem data, _) => data.color,
          innerRadius: '60%',
          radius: '80%',
          selectionBehavior: SelectionBehavior(
            enable: true,
            toggleSelection: true,
            selectedOpacity: 1,
            unselectedOpacity: 0.3,
          ),
          animationDuration: 500,
          initialSelectedDataIndexes: selectedIndexes,
          onPointTap: (ChartPointDetails details) {
            if (details.pointIndex != null && details.dataPoints != null) {
              final tappedName =
                  details.dataPoints![details.pointIndex!].x as String;
              setState(() {
                selectedAsset = selectedAsset == tappedName ? null : tappedName;
                _chartRebuildKey++;
              });
            }
          },
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
      legend: const Legend(isVisible: false),
    );
  }

  List<Widget> _buildLegendItems() {
    final sortedItems = _getSortedAssetItems();
    return sortedItems.map((item) => _buildLegendItem(item)).toList();
  }

  Widget _buildLegendItem(AssetItem item) {
    final bool isSelected = selectedAsset == item.name;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAsset = selectedAsset == item.name ? null : item.name;
          _chartRebuildKey++;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? item.color.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.rectangle,
              ),
            ),
            const SizedBox(width: 5),
            AppText(
              "${item.name}:",
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(width: 8),
            AppText(
              '${item.percentage.toStringAsFixed(2)}%',
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
          ],
        ),
      ),
    );
  }
}
