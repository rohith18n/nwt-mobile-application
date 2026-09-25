import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class MutualFundAnalysisCard extends StatelessWidget {
  final String logoUrl;
  final String schemeName;
  final String fundType;
  final String investedAmount;

  static const double cardHeight = 95.0;
  static const double logoSize = 40.0;
  static const double cardPadding = 14.0;

  const MutualFundAnalysisCard({
    super.key,
    required this.logoUrl,
    required this.schemeName,
    required this.fundType,
    required this.investedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        padding: const EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: logoSize,
              height: logoSize,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 31, 27, 27),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: SvgPicture.network(
                  logoUrl,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Fund Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: AppText(
                        schemeName,
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      fundType.toUpperCase(),
                      variant: AppTextVariant.caption,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.link,
                    ),
                  ],
                ),
              ),
            ),

            // Invested Amount
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  "Invested",
                  variant: AppTextVariant.caption,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.secondary,
                ),
                const SizedBox(height: 2),
                AppText(
                  investedAmount,
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerInvestmentCard extends StatefulWidget {
  const ShimmerInvestmentCard({super.key});

  @override
  State<ShimmerInvestmentCard> createState() => _ShimmerInvestmentCardState();
}

class _ShimmerInvestmentCardState extends State<ShimmerInvestmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_animation.value * 0.5),
          child: Container(
            height: MutualFundAnalysisCard.cardHeight,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(MutualFundAnalysisCard.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo placeholder
                Container(
                  width: MutualFundAnalysisCard.logoSize,
                  height: MutualFundAnalysisCard.logoSize,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                // Text placeholders
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 180,
                        height: 16,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount placeholder
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
