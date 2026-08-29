import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class ConnectionsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String addText;
  final bool isDisabled;
  final VoidCallback? onAddPressed;

  const ConnectionsCard({
    Key? key,
    required this.icon,
    required this.title,
    this.addText = 'Add',
    this.isDisabled = false,
    this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: isDisabled ? null : () {},
                    icon: Icon(icon),
                  ),
                  const SizedBox(width: 12),
                  AppText(
                    title,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                  ),
                ],
              ),
              GestureDetector(
                onTap: isDisabled ? null : onAddPressed,
                child: AppText(
                  isDisabled ? "Coming Soon" : addText,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: isDisabled ? AppTextColorType.secondary : AppTextColorType.link,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
