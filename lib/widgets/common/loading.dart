import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size ?? MediaQuery.of(context).size.width * 0.45,
          child: Lottie.asset('assets/lottie/mf_loading.json'),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          AppText(
            message!,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ],
    );
  }
}
