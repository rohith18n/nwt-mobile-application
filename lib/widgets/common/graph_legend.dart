import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class CategoryLegend extends StatelessWidget {
  final String category;
  final Color color;

  const CategoryLegend({
    required this.category,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified to a single Row with no unnecessary nesting
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Important for proper wrapping
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          AppText(
            category,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ),
    );
  }
}
