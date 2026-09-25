import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class DarkRadioTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;
  final Color? selectedColor;
  final Color? textColor;

  const DarkRadioTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.selectedColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? Colors.grey[700]!),
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              title,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.white,
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedColor ?? Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
