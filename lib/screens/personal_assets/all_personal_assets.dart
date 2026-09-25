import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/data/categories/categories.types.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/screens/personal_assets/crypto_page.dart';
import 'package:nwt_app/screens/personal_assets/land_page.dart';
import 'package:nwt_app/screens/personal_assets/money_lent_page.dart';
import 'package:nwt_app/screens/personal_assets/others_asset_page.dart';
import 'package:nwt_app/screens/personal_assets/personal_assets.dart';
import 'package:nwt_app/screens/personal_assets/precious_metal_page.dart';
import 'package:nwt_app/screens/personal_assets/real_estate.dart';
import 'package:nwt_app/screens/personal_assets/types/personal_assets_models.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/personal_assets/delete_asset.dart';
import 'package:nwt_app/services/personal_assets/personal_assets_fetch_service.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class AllPersonalAssetsScreen extends StatefulWidget {
  final bool isFamilyMode;

  const AllPersonalAssetsScreen({super.key, this.isFamilyMode = false});

  @override
  State<AllPersonalAssetsScreen> createState() =>
      _AllPersonalAssetsScreenState();
}

final List<Category> assetCategories = [
  Category(id: 'ALL', name: 'All'),
  Category(id: 'REAL_ESTATE', name: 'Real Estate'),
  Category(id: 'LAND', name: 'Land'),
  Category(id: 'METAL', name: 'Precious Metal'),
  Category(id: 'CRYPTO', name: 'Crypto'),
  Category(id: 'MONEY_LENT', name: 'Money Lent'),
  Category(id: 'OTHER', name: 'Others'),
];

class PersonalAsset {
  final String id;
  final String name;
  final String location;
  final double value;
  final String category;
  final IconData icon;

  PersonalAsset({
    required this.id,
    required this.name,
    required this.location,
    required this.value,
    required this.category,
    required this.icon,
  });
}

class _AllPersonalAssetsScreenState extends State<AllPersonalAssetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final PersonalAssetsFetchService _service = PersonalAssetsFetchService();
  final DeleteAssetService _deleteService = DeleteAssetService();

  bool _isLoading = true;
  Category _selectedCategory = assetCategories.first;

  List<PersonalAssetItem> _personalAssets = [];
  double _totalValue = 0.0;

  bool _isAmountVisible = false;

  @override
  void initState() {
    super.initState();
    _restoreAmountVisibilityState();
    _fetchData();
  }

  /// Restores amount visibility state from persistent storage
  void _restoreAmountVisibilityState() {
    final savedAmountVisibility = StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? true;
    setState(() {
      _isAmountVisible = savedAmountVisibility;
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = getAccountAggregatorDataProvider();
      final providerAssets = provider.getPersonalAssets();
      if (providerAssets != null && providerAssets.isNotEmpty) {
        if (mounted) {
          setState(() {
            _personalAssets = providerAssets;
            _totalValue = providerAssets.fold<double>(
              0,
              (s, p) => s + p.amount,
            );
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch both assets list and total value concurrently
      final results = await Future.wait([
        _service.getAllPersonalAssets(),
        _service.getTotalValue(),
      ]);

      final assetsResponse = results[0] as PersonalAssetsListResponse;
      final totalValueResponse = results[1] as PersonalAssetsTotalValueResponse;

      if (assetsResponse.success) {
        _personalAssets = assetsResponse.data;
      }

      if (totalValueResponse.success) {
        _totalValue = totalValueResponse.totalValue;
      }
    } catch (e) {
      // Handle error - could show a snackbar or error dialog
      print('Error fetching personal assets data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconForAssetType(String type) {
    switch (type) {
      case 'REAL_ESTATE':
        return Icons.home;
      case 'LAND':
        return Icons.location_on;
      case 'METAL':
        return Icons.diamond;
      case 'CRYPTO':
        return Icons.currency_bitcoin;
      case 'MONEY_LENT':
        return Icons.account_balance_wallet;
      case 'OTHER':
        return Icons.palette;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            BackNavigation.backOrHome();
          },
          child: const Icon(Icons.chevron_left, size: 32),
        ),
        centerTitle: true,
        title: AppText(
          "Personal Assets",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.darkButtonPrimaryBackground,
                  ),
                ),
              )
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.darkButtonPrimaryBackground,
                  backgroundColor: AppColors.darkCardBG,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Total Value Card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.scaffoldHorizontalPadding,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.darkButtonBorder,
                              ),
                              color: AppColors.darkCardBG,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          "Personal Assets Value",
                                          variant: AppTextVariant.bodyMedium,
                                          weight: AppTextWeight.bold,
                                          colorType: AppTextColorType.secondary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AnimatedAmount(
                                      isAmountVisible: _isAmountVisible,
                                      amount: CurrencyFormatter.formatRupee(
                                        _totalValue.toInt(),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isAmountVisible = !_isAmountVisible;
                                        });
                                        // Save amount visibility state to storage
                                        StorageService.write(StorageKeys.AMOUNT_VISIBILITY_KEY, _isAmountVisible);
                                      },
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          _isAmountVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color:
                                              AppColors
                                                  .darkButtonPrimaryBackground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Search Field
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.scaffoldHorizontalPadding,
                            vertical: 12,
                          ),
                          child: Obx(
                            () => AppInputField(
                              controller: _searchController,
                              onChanged: (value) {
                                _searchQuery.value = value;
                                setState(() {});
                              },
                              prefix: const Icon(
                                CupertinoIcons.search,
                                color: AppColors.darkTextMuted,
                              ),
                              suffix:
                                  _searchQuery.value.isNotEmpty
                                      ? InkWell(
                                        onTap: () {
                                          _searchController.clear();
                                          _searchQuery.value = '';
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.clear,
                                          color: AppColors.darkTextMuted,
                                        ),
                                      )
                                      : null,
                              hintText: "Search",
                            ),
                          ),
                        ),
                        // Category Chips
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizing.scaffoldHorizontalPadding,
                            ),
                            itemBuilder: (context, index) {
                              return CategoryChip(
                                label: assetCategories[index].name,
                                isSelected:
                                    _selectedCategory == assetCategories[index],
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = assetCategories[index];
                                  });
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(width: 8);
                            },
                            itemCount: assetCategories.length,
                          ),
                        ),
                        // Assets List
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: () {
                            final filteredAssets =
                                _personalAssets.where((asset) {
                                  final matchesSearch =
                                      _searchQuery.value.isEmpty ||
                                      asset.title.toLowerCase().contains(
                                        _searchQuery.value.toLowerCase(),
                                      ) ||
                                      asset.subtitle.toLowerCase().contains(
                                        _searchQuery.value.toLowerCase(),
                                      );

                                  final matchesCategory =
                                      _selectedCategory.id == 'ALL' ||
                                      asset.type == _selectedCategory.id;

                                  return matchesSearch && matchesCategory;
                                }).toList();

                            if (filteredAssets.isEmpty) {
                              return Center(
                                child: EmptyState(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: "No personal assets found",
                                  subtitle:
                                      "We couldn't find any assets matching your criteria",
                                ),
                              );
                            }

                            return Column(
                              spacing: 12,
                              children: [
                                ...filteredAssets.map(
                                  (asset) => _buildSwipeableAssetCard(asset),
                                ),
                              ],
                            );
                          }(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: "Add Asset",
            onPressed: () => Get.to(() => const PersonalAssetsScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableAssetCard(PersonalAssetItem asset) {
    return SizedBox(
      width:
          MediaQuery.of(context).size.width -
          2 * AppSizing.scaffoldHorizontalPadding,
      child: Dismissible(
        key: Key(asset.id.toString()),
        direction:
            widget.isFamilyMode ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        confirmDismiss: (direction) async {
          if (widget.isFamilyMode) {
            Get.snackbar(
              'Family Mode',
              'Deleting assets is disabled in family mode',
              backgroundColor: AppColors.info,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            );
            return false;
          }
          final shouldDelete = await _showDeleteConfirmation(asset);
          if (shouldDelete == true) {
            return await _deleteAssetAndReturnResult(asset);
          }
          return false;
        },
        child: _buildAssetCard(asset),
      ),
    );
  }

  Widget _buildAssetCard(PersonalAssetItem asset) {
    return GestureDetector(
      onTap: () => _navigateToAssetPage(asset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForAssetType(asset.type),
                color: AppColors.darkButtonPrimaryBackground,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    asset.title,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    asset.subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
              ),
            ),
            AnimatedAmount(
              isAmountVisible: _isAmountVisible,
              amount: CurrencyFormatter.formatRupee(asset.amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(PersonalAssetItem asset) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Delete Asset",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    'Are you sure you want to delete "${asset.title}"? This action cannot be undone.',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Cancel",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),
                      Container(
                        height: 52,
                        width: 1,
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Delete",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.error,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAssetPage(PersonalAssetItem asset) {
    // Navigate to specific asset page based on asset type
    switch (asset.type) {
      case 'REAL_ESTATE':
        Get.to(() => RealEstateScreen(assetId: asset.id, isEdit: true));
        break;
      case 'LAND':
        Get.to(() => LandPage(assetId: asset.id, isEdit: true));
        break;
      case 'METAL':
        Get.to(() => PreciousMetalPage(assetId: asset.id, isEdit: true));
        break;
      case 'CRYPTO':
        Get.to(() => CryptoPage(assetId: asset.id, isEdit: true));
        break;
      case 'MONEY_LENT':
        Get.to(() => MoneyLentPage(assetId: asset.id, isEdit: true));
        break;
      case 'OTHER':
        Get.to(() => OthersAssetPage(assetId: asset.id, isEdit: true));
        break;
      default:
        Get.snackbar(
          'Info',
          'Edit functionality for ${asset.type} will be available soon',
          backgroundColor: AppColors.info,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
    }
  }

  Future<bool> _deleteAssetAndReturnResult(PersonalAssetItem asset) async {
    try {
      final response = await _deleteService.deletePersonalAsset(
        assetId: asset.id,
        onLoading: (isLoading) {},
      );

      if (response.status == 200 ||
          response.status == 204 ||
          response.status == 201) {
        setState(() {
          _personalAssets.removeWhere((a) => a.id == asset.id);
          _totalValue = _personalAssets.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
