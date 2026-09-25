import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon ?? Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
        ],
        AppText(
          title,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width - 80,
          child: AppText(
            subtitle,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
