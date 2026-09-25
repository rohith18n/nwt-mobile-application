import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/constants/colors.dart';

class AppDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String? hintText;
  final String? labelText;
  final ValueChanged<String?> onChanged;
  final bool showLabel;
  final Color? fillColor;
  final bool enabled;
  final List<String>? subtitles;
  final String? errorText;
  final bool required;

  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    this.hintText,
    this.labelText,
    required this.onChanged,
    this.showLabel = true,
    this.fillColor,
    this.enabled = true,
    this.subtitles,
    this.errorText,
    this.required = false,
  });

  void _showSelectionSheet(BuildContext context) {
    if (!enabled) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkTextGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (labelText != null) ...[
                Semantics(
                  header: true,
                  child: AppText(
                    labelText!,
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.white,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == value;

                    return Semantics(
                      selected: isSelected,
                      label: subtitles != null &&
                              index < subtitles!.length &&
                              subtitles![index].isNotEmpty
                          ? '$item, ${subtitles![index]}'
                          : item,
                      onTap: () {
                        onChanged(item);
                        Navigator.pop(context);
                      },
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () {
                          onChanged(item);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.darkInputBackground
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(color: AppColors.darkInputBorder)
                                    : Border.all(color: Colors.transparent),
                          ),
                          child: MergeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        item,
                                        variant: AppTextVariant.bodyMedium,
                                        colorType:
                                            isSelected
                                                ? AppTextColorType.white
                                                : AppTextColorType.secondary,
                                        weight:
                                            isSelected
                                                ? AppTextWeight.semiBold
                                                : AppTextWeight.medium,
                                      ),
                                      if (subtitles != null &&
                                          index < subtitles!.length &&
                                          subtitles![index].isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        AppText(
                                          subtitles![index],
                                          variant: AppTextVariant.bodySmall,
                                          colorType: AppTextColorType.gray,
                                          weight: AppTextWeight.medium,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && labelText != null) ...[
          Row(
            children: [
              AppText(
                labelText!,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.white,
              ),
              if (required) ...[
                const SizedBox(width: 4),
                AppText(
                  '*',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _showSelectionSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ), // Increased vertical padding for better touch target and parity
            decoration: BoxDecoration(
              color: fillColor ?? AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: errorText != null ? AppColors.error : AppColors.darkInputBorder,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText(
                    value ?? hintText ?? 'Select Option',
                    variant: AppTextVariant.bodyMedium,
                    colorType:
                        value != null
                            ? AppTextColorType.white
                            : AppTextColorType.gray,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      enabled
                          ? AppColors.darkTextGray
                          : AppColors.darkTextGray.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          AppText(
            errorText!,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.error,
          ),
        ],
      ],
    );
  }
}
