import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.darkPrimary : AppColors.darkButtonBorder,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkButtonBorder, width: 1.0),
          ),
          child: ExcludeSemantics(
            child: Center(
              child: AppText(
                label,
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.semiBold,
                colorType:
                    isSelected
                        ? AppTextColorType.tertiary
                        : AppTextColorType.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
