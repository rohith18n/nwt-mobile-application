import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_nps.dart';
import 'package:nwt_app/services/family_finance/assets/family_finance_assets_nps.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FamilyFinanceNPSScreen extends StatefulWidget {
  const FamilyFinanceNPSScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<FamilyFinanceNPSScreen> createState() => _FamilyFinanceNPSScreenState();
}

class _FamilyFinanceNPSScreenState extends State<FamilyFinanceNPSScreen> {
  bool _isAmountVisible = true;
  int _selectedTierIndex = 0; // 0 means Tier 1 is selected by default
  bool _isLoading = false;
  FamilyFinanceNpsResponse? _npsData;

  @override
  void initState() {
    super.initState();
    _fetchNPSData();
  }

  Future<void> _fetchNPSData() async {
    final npsService = FamilyFinanceAssetsNPSService();
    final response = await npsService.getFamilyFinanceAssetsNPS(
      familyId: widget.familyId,
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _npsData = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Family NPS",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            GestureDetector(
              onTap: () => _showInfoBottomSheet(context),
              child: const Icon(Icons.info_outline_rounded, size: 20),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Holdings summary card - fixed at top
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Family Holdings",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.secondary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedAmount(
                                isAmountVisible: _isAmountVisible,
                                amount: CurrencyFormatter.formatRupee(
                                  _npsData?.data?.summary.totalsum ?? 0,
                                ),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkPrimary,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              // Delta value indicator
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAmountVisible = !_isAmountVisible;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  color:
                                      _isAmountVisible
                                          ? AppColors.darkPrimary
                                          : AppColors.darkTextMuted,
                                  size: 22.sp,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tier selection row - fixed below holdings
                if (_npsData != null && _npsData!.data != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tier 1
                      _buildTierContainer(
                        index: 0,
                        title: 'Tier 1',
                        subtitle: 'Moderate',
                        amount: _npsData!.data!.summary.tier1value,
                      ),

                      const SizedBox(width: 12),

                      // Tier 2
                      _buildTierContainer(
                        index: 1,
                        title: 'Tier 2',
                        subtitle: 'Aggressive',
                        amount: _npsData!.data!.summary.tier2value,
                      ),
                    ],
                  ),

                SizedBox(height: 16),
                _isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : _npsData == null ||
                        _npsData!.data == null ||
                        (_npsData!.data!.members.isEmpty)
                    ? _buildNoNPSFoundMessage()
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_npsData!.data!.members.any((member) {
                          for (var npsData in member.assets.nps.data) {
                            if (_selectedTierIndex == 0 &&
                                npsData.tier1.funds.isNotEmpty) {
                              return true;
                            } else if (_selectedTierIndex == 1 &&
                                npsData.tier2.funds.isNotEmpty) {
                              return true;
                            }
                          }
                          return false;
                        }))
                          _buildNoFundsInTierMessage(),

                        // Family members with NPS accounts
                        ..._npsData!.data!.members
                            .where((member) {
                              // Check if this member has any funds in the selected tier
                              bool hasFundsInSelectedTier = false;

                              for (var npsData in member.assets.nps.data) {
                                if (_selectedTierIndex == 0 &&
                                    npsData.tier1.funds.isNotEmpty) {
                                  hasFundsInSelectedTier = true;
                                  break;
                                } else if (_selectedTierIndex == 1 &&
                                    npsData.tier2.funds.isNotEmpty) {
                                  hasFundsInSelectedTier = true;
                                  break;
                                }
                              }

                              return hasFundsInSelectedTier;
                            })
                            .map(
                              (member) => CustomAccordion(
                                title: "${member.firstname} ${member.lastname}",
                                initiallyExpanded: false,
                                child: Column(
                                  spacing: 12,
                                  children: [
                                    // Member's NPS funds
                                    ...member.assets.nps.data.expand(
                                      (npsData) => [
                                        // Show Tier 1 funds only when Tier 1 is selected
                                        if (_selectedTierIndex == 0 &&
                                            npsData.tier1.funds.isNotEmpty)
                                          ...npsData.tier1.funds.map(
                                            (fund) => _NPSCard(
                                              fund: fund,
                                              onTap: () {
                                                // Handle tap on pension fund card
                                                debugPrint(
                                                  'Tapped on ${fund.schemename}',
                                                );
                                              },
                                            ),
                                          ),
                                        // Show Tier 2 funds only when Tier 2 is selected
                                        if (_selectedTierIndex == 1 &&
                                            npsData.tier2.funds.isNotEmpty)
                                          ...npsData.tier2.funds.map(
                                            (fund) => _NPSCard(
                                              fund: fund,
                                              onTap: () {
                                                // Handle tap on pension fund card
                                                debugPrint(
                                                  'Tapped on ${fund.schemename}',
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                        // Add bottom padding for better scrolling experience
                        const SizedBox(height: 24),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Track NPS',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                isLoading: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build consistent text displays
  Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Montserrat'),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.darkPrimary,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.darkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build delta indicator
  Widget _buildDeltaIndicator(double deltaValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            deltaValue >= 0
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        deltaValue >= 0
            ? "+ ${deltaValue.abs().toStringAsFixed(1)}%"
            : "- ${deltaValue.abs().toStringAsFixed(1)}%",
        variant: AppTextVariant.bodySmall,
        weight: AppTextWeight.medium,
        colorType:
            deltaValue >= 0 ? AppTextColorType.success : AppTextColorType.error,
      ),
    );
  }

  /// A private widget to display pension fund information within the NPS screen
  Widget _NPSCard({required Fund fund, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkInputBorder),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              fund.schemename,
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildInfoText('Units', fund.units.toString()),
                      _buildInfoText('NAV', fund.nav.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildInfoText(
                        'Value',
                        CurrencyFormatter.formatRupee(fund.value),
                      ),
                      const SizedBox(width: 12),
                      _buildDeltaIndicator(fund.deltapercentage.toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierContainer({
    required int index,
    required String title,
    required String subtitle,
    required num amount,
  }) {
    final bool isSelected = _selectedTierIndex == index;

    // Define colors based on selection state
    final backgroundColor =
        isSelected ? AppColors.darkPrimary : AppColors.darkCardBG;
    final borderColor =
        isSelected ? AppColors.darkPrimary : AppColors.darkButtonBorder;
    final shadowColor =
        isSelected
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.2);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!isSelected) {
              _selectedTierIndex = index;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType:
                        isSelected
                            ? AppTextColorType.black
                            : AppTextColorType.primary,
                  ),
                  // Only show the subtitle container if it's not 'NA'
                  if (subtitle.toUpperCase() != 'NA')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.black.withOpacity(0.1)
                                : AppColors.darkButtonBorder.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AppText(
                        subtitle,
                        variant: AppTextVariant.tiny,
                        weight: AppTextWeight.semiBold,
                        colorType:
                            isSelected
                                ? AppTextColorType.black
                                : AppTextColorType.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                CurrencyFormatter.formatRupee(amount),
                variant: AppTextVariant.headline2,
                weight: AppTextWeight.bold,
                colorType:
                    isSelected
                        ? AppTextColorType.black
                        : AppTextColorType.primary,
              ),
              // No selected tag
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a message to display when no NPS data is found
  Widget _buildNoNPSFoundMessage() {
    // Use LayoutBuilder to get the available height
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // Take the full available height
          height: constraints.maxHeight,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppColors.darkTextMuted,
                ),
                const SizedBox(height: 16),
                AppText(
                  'No NPS found',
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: AppText(
                    'You don\'t have any NPS accounts linked yet.',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a message to display when no funds are found for the selected tier
  Widget _buildNoFundsInTierMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
        vertical: 24.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkInputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkButtonBorder.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedTierIndex == 0 ? Icons.filter_1 : Icons.filter_2,
              size: 48,
              color: AppColors.darkPrimary,
            ),
          ),
          const SizedBox(height: 20),
          AppText(
            'No funds in ${_selectedTierIndex == 0 ? "Tier 1" : "Tier 2"}',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AppText(
              'There are no investments in the selected tier category.',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTierIndex = _selectedTierIndex == 0 ? 1 : 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: AppColors.darkPrimary,
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    'Switch to ${_selectedTierIndex == 0 ? "Tier 2" : "Tier 1"}',
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "NPS Terms",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                spacing: 12,
                children: [
                  _buildNPSTermCard(
                    title: "Moderate",
                    description:
                        'The Moderate option in NPS is a Life Cycle Fund with a 50% equity cap until age 35, which decreases with age.',
                  ),
                  _buildNPSTermCard(
                    title: "Conservative",
                    description:
                        'The Conservative caps equity at 25% until age 35, then reduces it to 5% by age 55, prioritizing safer investments like bonds.',
                  ),
                  _buildNPSTermCard(
                    title: "Aggressive",
                    description:
                        'The Aggressive NPS option invests 75% in equity until age 35, then reduces equity by 4% each year, moving to safer assets like bonds.',
                  ),
                  _buildNPSTermCard(
                    title: "Corporate",
                    description:
                        'Corporate NPS is tailored for employer-employee collaboration, offering joint contributions and tax benefits.',
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Helper method to build NPS term cards with consistent styling
  Widget _buildNPSTermCard({
    required String title,
    required String description,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Column(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.bold,
          ),
          AppText(
            description,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.regular,
          ),
        ],
      ),
    );
  }
}
