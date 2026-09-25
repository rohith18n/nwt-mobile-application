import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class TopPerformersDashboard extends StatelessWidget {
  const TopPerformersDashboard({super.key});

  final List<_FundData> _funds = const [
    _FundData(
      name: "Kotak Flexicap Fund Direct Growth",
      icon: Icons.trending_up,
    ),
    _FundData(
      name: "Bajaj Finserv Liquid Fund Direct Growth",
      icon: Icons.water_drop,
    ),
    _FundData(
      name: "Motilal Oswal Focused Direct growth",
      icon: Icons.bubble_chart,
    ),
    _FundData(
      name: "LIC MF Healthcare Fund Direct Growth",
      icon: Icons.local_hospital,
    ),
    _FundData(
      name: "HSBC Small Cap Fund Direct Growth",
      icon: Icons.stacked_line_chart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80), // Add top padding of 50px
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'MF Top 10 Performers',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
              decoration: TextDecoration.none,
            ),
            const SizedBox(height: 20),
            ..._funds.map((fund) => _buildFundTile(fund)),
          ],
        ),
      ),
    );
  }

  Widget _buildFundTile(_FundData fund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: Icon(fund.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              fund.name,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
              decoration: TextDecoration.none,
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

class _FundData {
  final String name;
  final IconData icon;

  const _FundData({required this.name, required this.icon});
}
