import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/assets/banks/bank_details.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class BankCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final bool redirect;
  final String bankName;
  final String accountNumber;
  final String balance;
  final String deltaValue;
  final bool isPositiveDelta;
  final bool? isAmountVisible;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconBackgroundColor;
  final String bankGUID;
  final DateTime? balanceDateTime;
  final bool forceStandardApis;

  const BankCard({
    super.key,
    this.redirect = true,
    required this.type,
    required this.icon,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    required this.deltaValue,
    this.isPositiveDelta = true,
    this.isAmountVisible = true,
    this.backgroundColor,
    this.borderColor,
    this.iconBackgroundColor,
    required this.bankGUID,
    this.balanceDateTime,
    this.forceStandardApis = true,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDeltaValue = deltaValue;
    if (isPositiveDelta && !deltaValue.startsWith('+')) {
      formattedDeltaValue = '+ $deltaValue';
    }

    return Semantics(
      button: true,
      label: '$bankName, Account Number $accountNumber, Balance $balance' +
          (balanceDateTime != null
              ? ', Last fetched at ${DateFormatter.formatToDateTimeWithAmPm(balanceDateTime!)}'
              : ''),
      child: InkWell(
        onTap:
            redirect
                ? () => Get.to(
                  () => BankDetailsScreen(
                    bankGUID: bankGUID,
                    balance:
                        double.tryParse(
                          balance.replaceAll(RegExp(r'[^0-9.]'), ''),
                        ) ??
                        0,
                    bankLogo: 'assets/app/pivot.money.png',
                    forceStandardApis: forceStandardApis,
                  ),
                  transition: Transition.rightToLeft,
                )
                : null,
        child: ExcludeSemantics(
          child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor ?? AppColors.darkButtonBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 17, color: AppColors.darkTextMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    bankName,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    accountNumber,
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.regular,
                    colorType: AppTextColorType.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (balanceDateTime != null) ...[
                    const SizedBox(height: 4),
                    AppText(
                      "Last fetched at ${DateFormatter.formatToDateTimeWithAmPm(balanceDateTime!)}",
                      variant: AppTextVariant.tiny,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedAmount(
                  isAmountVisible: isAmountVisible ?? true,
                  amount: balance,
                  alignment: Alignment.centerRight,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
