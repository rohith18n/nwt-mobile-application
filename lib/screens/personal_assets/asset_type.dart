import 'package:flutter/material.dart';
import 'package:nwt_app/screens/personal_assets/crypto_page.dart';
import 'package:nwt_app/screens/personal_assets/land_page.dart';
import 'package:nwt_app/screens/personal_assets/money_lent_page.dart';
import 'package:nwt_app/screens/personal_assets/others_asset_page.dart';
import 'package:nwt_app/screens/personal_assets/precious_metal_page.dart';
import 'package:nwt_app/screens/personal_assets/real_estate.dart';

enum AssetType { realEstate, land, preciousMetal, crypto, moneyLent, others }

class AssetOption {
  final AssetType type;
  final String name;
  final IconData icon;
  final String description;
  final Widget page;

  const AssetOption({
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.page,
  });

  static const List<AssetOption> allOptions = [
    AssetOption(
      type: AssetType.realEstate,
      name: 'Real Estate',
      icon: Icons.home_rounded,
      description:
          'Include residential and commercial properties you own such as houses, apartments, condos, office buildings, warehouses, or rental properties.',
      page: RealEstateScreen(),
    ),
    AssetOption(
      type: AssetType.land,
      name: 'Land',
      icon: Icons.landscape_rounded,
      description:
          'Record plots, agricultural land, or vacant lots that you own. This includes farmland, residential plots awaiting construction, or any land held for investment purposes.',
      page: LandPage(),
    ),
    AssetOption(
      type: AssetType.preciousMetal,
      name: 'Precious Metal',
      icon: Icons.diamond_rounded,
      description:
          'Add your investments in gold, silver, diamond, or other precious metals. Include jewelry, coins, bars, or other metal articles.',
      page: PreciousMetalPage(),
    ),
    AssetOption(
      type: AssetType.crypto,
      name: 'Crypto',
      icon: Icons.currency_bitcoin_rounded,
      description:
          'Track your cryptocurrency holdings including Bitcoin, Ethereum, and other digital currencies. Include coins held in wallets, exchanges, or staking platforms.',
      page: CryptoPage(),
    ),
    AssetOption(
      type: AssetType.moneyLent,
      name: 'Money Lent',
      icon: Icons.account_balance_wallet_rounded,
      description:
          'Record loans you\'ve given to friends, family, or through peer-to-peer lending platforms. Include personal loans, or any money owed to you with expected repayment.',
      page: MoneyLentPage(),
    ),
    AssetOption(
      type: AssetType.others,
      name: 'Others',
      icon: Icons.more_horiz_rounded,
      description:
          'Add any valuable assets not covered above such as artwork, collectibles, or other investments and valuables.',
      page: OthersAssetPage(),
    ),
  ];

  /// Get asset option by type
  static AssetOption? getByType(AssetType type) {
    try {
      return allOptions.firstWhere((option) => option.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get asset option by name
  static AssetOption? getByName(String name) {
    try {
      return allOptions.firstWhere((option) => option.name == name);
    } catch (e) {
      return null;
    }
  }
}
