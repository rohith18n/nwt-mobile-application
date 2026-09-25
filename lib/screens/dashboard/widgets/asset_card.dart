import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/delta_indicator.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class AssetCard extends StatefulWidget {
  final String title;
  final String amount;
  final String delta;
  final DeltaType deltaType;
  final IconData? icon;
  final double? width;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? destination;
  final bool isAmountVisible;
  final bool isLinked;
  final bool hideDelta;

  const AssetCard({
    super.key,
    required this.title,
    required this.amount,
    required this.delta,
    this.deltaType = DeltaType.positive,
    this.icon,
    this.width = 250,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    this.backgroundColor,
    this.borderColor,
    this.destination,
    this.isAmountVisible = true,
    this.isLinked = true,
    this.hideDelta = false,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  @override
  void initState() {
    AppLogger.info(
      "ASSET_CARD_ISTEST_ACCOUNT: ${widget.title} - ${widget.isLinked}",
      tag: 'AssetCard',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          widget.destination != null
              ? () =>
                  Get.to(widget.destination, transition: Transition.rightToLeft)
              : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.borderColor ?? AppColors.darkButtonBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.icon != null)
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          // color: AppColors.darkButtonBorder,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.darkButtonBorder),
                        ),
                        child: Icon(widget.icon, size: 18),
                      ),
                    if (widget.icon != null) const SizedBox(width: 10),
                    AppText(
                      widget.title,
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
                if (widget.isLinked && !widget.hideDelta)
                  DeltaIndicator(
                    deltaValue:
                        double.tryParse(widget.delta.replaceAll('%', '')) ??
                        0.0,
                    deltaType: widget.deltaType,
                  ),
              ],
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  widget.isLinked
                      ? const SizedBox()
                      : const SizedBox(height: 33),
                  widget.isLinked
                      ? AnimatedAmount(
                        amount: widget.amount,
                        isAmountVisible: widget.isAmountVisible,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : AppText(
                        "Link Now",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.link,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DeltaType enum is now defined in constants/enums.dart
