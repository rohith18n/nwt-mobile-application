import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/add_holder_screen.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';

/// Main screen showing list of holders and nominees
/// Matches web flow: app.pivotmoney.app/profile/holders
class HolderNomineeListScreen extends StatefulWidget {
  final String? fundName;
  final String? isin;
  final String? schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;

  const HolderNomineeListScreen({
    super.key,
    this.fundName,
    this.isin,
    this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
  });

  @override
  State<HolderNomineeListScreen> createState() => _HolderNomineeListScreenState();
}

class _HolderNomineeListScreenState extends State<HolderNomineeListScreen> {
  final OnboardingV2Service _service = OnboardingV2Service();
  
  List<Map<String, dynamic>> _holders = [];
  List<Map<String, dynamic>> _selectedNominees = [];
  bool _isLoading = false;
  
  Map<String, dynamic>? _selectedHolder;
  String _nominationPreference = 'register'; // 'register' or 'opt_out'
  

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      AppLogger.info('Fetching holders and nominees', tag: 'HolderNomineeList');
      
      // Fetch holders from API
      final response = await _service.listHolders();
      
      if (response != null && response['success'] == true) {
        final holdersData = response['data']['holders'] as List<dynamic>?;
        
        AppLogger.info('Holders fetched: $holdersData', tag: 'HolderNomineeList');
        
        setState(() {
          _holders = holdersData?.map((h) => h as Map<String, dynamic>).toList() ?? [];
          // Set first holder as selected if available
          _selectedHolder = _holders.isNotEmpty ? _holders.first : null;
          // Nominees are selected from holders
          _selectedNominees = [];
        });
      } else {
        AppLogger.error('Failed to fetch holders: ${response?['message']}', tag: 'HolderNomineeList');
        setState(() {
          _holders = [];
          _selectedNominees = [];
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching data: $e', tag: 'HolderNomineeList');
      setState(() {
        _holders = [];
        _selectedNominees = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddHolder() async {
    final result = await Get.to(
      () => const AddHolderScreen(),
      transition: Transition.rightToLeft,
    );

    // Refresh the list after adding holder (holder is already saved via API in AddHolderScreen)
    if (result != null && result is Map<String, dynamic>) {
      await _fetchData(); // Refresh from API
    }
  }

  Future<void> _changeHolder() async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.darkCardBG,
        title: AppText(
          'Change Holder',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        content: AppText(
          'Changing the holder will replace the existing holder. Do you want to continue?',
          variant: AppTextVariant.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: AppText('Cancel', customColor: Colors.grey),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: AppText('Continue', customColor: AppColors.darkButtonPrimaryBackground),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _navigateToAddHolder();
    }
  }

  Future<void> _addHolderAsNominee() async {
    // Navigate to add holder screen to create a new holder who will be used as nominee
    final result = await Get.to(
      () => const AddHolderScreen(),
      transition: Transition.rightToLeft,
    );

    if (result != null && result is Map<String, dynamic>) {
      await _fetchData(); // Refresh holders list
      
      // Auto-select the newly added holder as nominee
      final newHolder = _holders.firstWhere(
        (h) => h['pan_number'] == result['pan_number'],
        orElse: () => result,
      );
      
      setState(() {
        if (!_selectedNominees.any((n) => n['id'] == newHolder['id'])) {
          _selectedNominees.add({
            ...newHolder,
            'percent': 100, // Default 100% for single nominee
          });
        }
      });
    }
  }
  
  void _addExistingHolderAsNominee(Map<String, dynamic> holder) {
    setState(() {
      if (!_selectedNominees.any((n) => n['id'] == holder['id'])) {
        _selectedNominees.add({
          ...holder,
          'percent': 100,
        });
      }
    });
  }
  
  void _removeNominee(int index) {
    setState(() {
      _selectedNominees.removeAt(index);
    });
  }

  Future<void> _submitAndContinue() async {
    // Validate nominees total 100%
    if (_selectedNominees.isNotEmpty) {
      final totalPercent = _selectedNominees.fold<int>(0, (sum, n) => sum + (n['percent'] as int? ?? 0));
      if (totalPercent != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Total allocation must be 100%. Current: $totalPercent%')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      // TODO: Submit to backend
      await Future.delayed(const Duration(seconds: 2));
      
      Get.back(result: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account setup complete!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Account Setup',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 32.h),
                  _buildHoldersSection(),
                  SizedBox(height: 24.h),
                  _buildNomineesSection(),
                  SizedBox(height: 40.h),
                  _buildContinueButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Complete Your Account Setup',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.primary,
        ),
        SizedBox(height: 8.h),
        AppText(
          'Add joint holders and nominees to activate your investment account.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
        ),
      ],
    );
  }

  Widget _buildHoldersSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Joint Account Holders',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: AppText(
                  'Optional',
                  variant: AppTextVariant.caption,
                  customColor: AppColors.darkButtonPrimaryBackground,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppText(
            _holders.isEmpty 
                ? 'Add a joint holder by entering their PAN. We fetch their details from income tax records. Maximum 1 holder allowed.'
                : 'Select your joint holder from the dropdown below or change to a different holder.',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 20.h),
          
          // Show dropdown if holders exist, otherwise show add button
          if (_holders.isEmpty) ...[
            // Add Holder Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _navigateToAddHolder,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: AppColors.darkInputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20.sp),
                    SizedBox(width: 8.w),
                    AppText(
                      'Add a New Holder',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Holder Dropdown
            AppDropdown(
              labelText: 'Selected Joint Holder',
              hintText: 'Select holder',
              value: _selectedHolder?['name'],
              items: _holders.map((h) => h['name'] as String).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHolder = _holders.firstWhere((h) => h['name'] == value);
                });
              },
            ),
            SizedBox(height: 16.h),
            
            // Show selected holder details
            if (_selectedHolder != null) _buildHolderCard(_selectedHolder!),
            
            SizedBox(height: 16.h),
            
            // Change Holder Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _changeHolder,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: AppColors.darkButtonPrimaryBackground),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz, color: AppColors.darkButtonPrimaryBackground, size: 20.sp),
                    SizedBox(width: 8.w),
                    AppText(
                      'Change Holder',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      customColor: AppColors.darkButtonPrimaryBackground,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNomineesSection() {
    final totalPercent = _selectedNominees.fold<int>(0, (sum, n) => sum + (n['percent'] as int? ?? 0));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Nomination',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
          SizedBox(height: 8.h),
          AppText(
            'Select holders to use as nominees. You can add a new holder to use as nominee.',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 20.h),
          
          // Nomination Preference Dropdown
          AppText(
            'NOMINATION PREFERENCE',
            variant: AppTextVariant.caption,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.gray,
          ),
          SizedBox(height: 8.h),
          AppDropdown(
            hintText: 'Choose...',
            value: _nominationPreference == 'register' ? 'Register nominee (100% to one holder)' : 'Opt out',
            items: const ['Register nominee (100% to one holder)', 'Opt out'],
            onChanged: (value) {
              setState(() {
                _nominationPreference = value == 'Opt out' ? 'opt_out' : 'register';
                if (_nominationPreference == 'opt_out') {
                  _selectedNominees.clear();
                }
              });
            },
          ),
          
          if (_nominationPreference == 'register') ...[
            SizedBox(height: 20.h),
            
            // Nominee Selection Dropdown
            AppText(
              'NOMINEE (HOLDERS EXCLUDING SECOND HOLDER)',
              variant: AppTextVariant.caption,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.gray,
            ),
            SizedBox(height: 8.h),
            
            if (_holders.isEmpty) ...[
              AppText(
                'No other holders on file. Add a holder above to proceed.',
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.gray,
              ),
            ] else ...[
              // Dropdown with existing holders + add option
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.darkInputBorder),
                ),
                child: Column(
                  children: [
                    // Show selected nominee if any
                    if (_selectedNominees.isNotEmpty)
                      ..._selectedNominees.map((nominee) => ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                        title: AppText(
                          nominee['name'] ?? 'Unknown',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                        ),
                        subtitle: AppText(
                          'PAN: ${nominee['pan_number']} • 100%',
                          variant: AppTextVariant.caption,
                          colorType: AppTextColorType.gray,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20.sp),
                          onPressed: () => _removeNominee(0),
                        ),
                      )).toList()
                    else
                      // Dropdown to select nominee
                      PopupMenuButton<String>(
                        color: AppColors.darkCardBG,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                'Select...',
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.gray,
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          ..._holders.map((holder) => PopupMenuItem<String>(
                            value: holder['id'].toString(),
                            child: AppText(
                              '${holder['name']} (${holder['pan_number']})',
                              variant: AppTextVariant.bodyMedium,
                            ),
                          )).toList(),
                          PopupMenuItem<String>(
                            value: 'add_new',
                            child: Row(
                              children: [
                                Icon(Icons.add, color: AppColors.darkButtonPrimaryBackground, size: 18.sp),
                                SizedBox(width: 8.w),
                                AppText(
                                  'Add a holder to use as nominee...',
                                  variant: AppTextVariant.bodyMedium,
                                  customColor: AppColors.darkButtonPrimaryBackground,
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'add_new') {
                            _addHolderAsNominee();
                          } else {
                            final holder = _holders.firstWhere((h) => h['id'].toString() == value);
                            _addExistingHolderAsNominee(holder);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHolderCard(Map<String, dynamic> holder) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: AppText(
              'VERIFIED',
              variant: AppTextVariant.caption,
              customColor: Colors.green,
              weight: AppTextWeight.semiBold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  holder['name'] ?? 'Holder',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
                SizedBox(height: 4.h),
                AppText(
                  'PAN: ${holder['pan_number'] ?? 'N/A'}',
                  variant: AppTextVariant.caption,
                  colorType: AppTextColorType.gray,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _holders.remove(holder));
            },
            icon: Icon(Icons.close, color: AppColors.error, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: 'Continue & Create Account',
        onPressed: _isLoading ? null : _submitAndContinue,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildNomineeCard(Map<String, dynamic> nominee) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppText(
                '${nominee['percent']}%',
                variant: AppTextVariant.caption,
                weight: AppTextWeight.bold,
                customColor: AppColors.darkButtonPrimaryBackground,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${nominee['first_name']} ${nominee['last_name']}',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
                SizedBox(height: 4.h),
                AppText(
                  'Relation: ${nominee['relation'] ?? 'N/A'}',
                  variant: AppTextVariant.caption,
                  colorType: AppTextColorType.gray,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
