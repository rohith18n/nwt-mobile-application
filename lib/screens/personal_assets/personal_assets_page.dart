import 'package:flutter/material.dart';
import 'package:nwt_app/screens/personal_assets/crypto_page.dart';
import 'package:nwt_app/screens/personal_assets/land_page.dart';
import 'package:nwt_app/screens/personal_assets/money_lent_page.dart';
import 'package:nwt_app/screens/personal_assets/others_asset_page.dart';
import 'package:nwt_app/screens/personal_assets/precious_metal_page.dart';
import 'package:nwt_app/screens/personal_assets/real_estate.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PersonalAssetsPage extends StatefulWidget {
  const PersonalAssetsPage({super.key});

  @override
  State<PersonalAssetsPage> createState() => _PersonalAssetsPageState();
}

class _PersonalAssetsPageState extends State<PersonalAssetsPage> {
  final List<String> assetOptions = [
    'Real Estate',
    'Land',
    'Precious Metal',
    'Crypto',
    'Money Lent',
    'Others',
  ];

  void _navigateToDetailPage(String assetName) {
    Widget? targetPage;

    switch (assetName) {
      case 'Real Estate':
        targetPage = const RealEstateScreen();
        break;
      case 'Land':
        targetPage = const LandPage();
        break;
      case 'Precious Metal':
        targetPage = const PreciousMetalPage();
        break;
      case 'Crypto':
        targetPage = const CryptoPage();
        break;
      case 'Money Lent':
        targetPage = const MoneyLentPage();
        break;
      case 'Others':
        targetPage = const OthersAssetPage();
        break;
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          "Personal Assets",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.primary,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children:
              assetOptions.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _navigateToDetailPage(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            option,
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.primary,
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
