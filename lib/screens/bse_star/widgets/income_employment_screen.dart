import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/services/bse_star/occupation_options.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';

class IncomeEmploymentScreen extends StatefulWidget {
  final String selectedAnnualIncome;
  final String selectedOccupation;
  final ValueChanged<String> onAnnualIncomeChanged;
  final ValueChanged<String> onOccupationChanged;

  const IncomeEmploymentScreen({
    super.key,
    required this.selectedAnnualIncome,
    required this.selectedOccupation,
    required this.onAnnualIncomeChanged,
    required this.onOccupationChanged,
  });

  @override
  State<IncomeEmploymentScreen> createState() => _IncomeEmploymentScreenState();
}

class _IncomeEmploymentScreenState extends State<IncomeEmploymentScreen> {
  List<Datum> _options = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() => _loading = true);
    final data = await BseOccupationOptionsService.getOccupationOptionsList();
    if (!mounted) return;
    setState(() {
      _options = data ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Employment',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'We will use this information to tailor your experience and services throughout the app.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
        const SizedBox(height: 32),
        AppText(
          'What is your occupation?',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          for (final o in _options) ...[
            DarkRadioTile(
              title: o.name,
              isSelected: widget.selectedOccupation == o.id,
              onTap: () => widget.onOccupationChanged(o.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}
