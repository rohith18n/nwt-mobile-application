import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class PaymentSuccessWidget extends StatelessWidget {
  final VoidCallback onDone;

  const PaymentSuccessWidget({
    super.key,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          AppText(
            'Payment Successful',
            variant: AppTextVariant.headline4,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 60),
          AppText(
            'Your Payment was successful',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.white,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Done',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onDone,
            ),
          ),
        ],
      ),
    );
  }
}
