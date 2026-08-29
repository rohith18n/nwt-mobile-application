import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';

class OccupationDetailsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Map<String, dynamic> occupationData) onNext;

  const OccupationDetailsScreen({super.key, this.onBack, required this.onNext});

  @override
  State<OccupationDetailsScreen> createState() =>
      _OccupationDetailsScreenState();
}

class _OccupationDetailsScreenState extends State<OccupationDetailsScreen> {
  final OnboardingV2Service _onboardingService = OnboardingV2Service();

  String? _selectedOccupationCode;
  String? _selectedIncomeSlab;
  bool _isPep = false;

  // Field validation states
  bool _showOccupationError = false;
  bool _showIncomeError = false;

  final List<Map<String, String>> _incomeSlabs = [
    {'code': '31', 'label': 'Below ₹ 1L'},
    {'code': '32', 'label': '₹ 1L - ₹ 5L'},
    {'code': '33', 'label': '₹ 5L - ₹ 10L'},
    {'code': '34', 'label': '₹ 10L - ₹ 25L'},
    {'code': '35', 'label': 'Above ₹ 25 L'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.bseV2OccupationDetailsScreenViewed);
      AppLogger.info(AnalyticsEvents.bseV2OccupationDetailsScreenViewed, tag: 'event');
    });
    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      final response = await _onboardingService.getProfileDetails();

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final uccProfile = data?['ucc_profile'];

        if (uccProfile != null) {
          setState(() {
            // Pre-fill occupation
            if (uccProfile['primary_occupation'] != null) {
              _selectedOccupationCode = uccProfile['primary_occupation'];
            }

            // Pre-fill income slab
            if (uccProfile['primary_income_slab'] != null) {
              _selectedIncomeSlab = uccProfile['primary_income_slab'];
            }

            // Pre-fill PEP
            if (uccProfile['primary_pep'] != null) {
              final pepValue =
                  uccProfile['primary_pep'].toString().toUpperCase();
              _isPep = pepValue == 'Y';
            }
          });
        }

        AppLogger.info(
          'Occupation details pre-filled from API',
          tag: 'OccupationDetailsScreen',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching occupation details',
        error: e,
        tag: 'OccupationDetailsScreen',
      );
    }
  }

  bool get _isValid {
    return _selectedOccupationCode != null && _selectedIncomeSlab != null;
  }

  void _handleNext() {
    // Trigger field-level validation
    setState(() {
      _showOccupationError = _selectedOccupationCode == null;
      _showIncomeError = _selectedIncomeSlab == null;
    });

    if (!_isValid) return;

    final occupationData = {
      'occupation_code': _selectedOccupationCode,
      'income_slab': _selectedIncomeSlab,
      'pep': _isPep,
    };

    AppLogger.info(
      'Occupation data collected: $occupationData',
      tag: 'OccupationDetailsScreen',
    );

    widget.onNext(occupationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressIndicator(),
                      SizedBox(height: 24.h),
                      _buildTitle(),
                      SizedBox(height: 8.h),
                      _buildSubtitle(),
                      SizedBox(height: 32.h),
                      _buildOccupationSection(),
                      SizedBox(height: 32.h),
                      _buildIncomeSection(),
                      SizedBox(height: 32.h),
                      _buildPepSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: widget.onBack ?? () => Navigator.of(context).pop(),
              child: Tooltip(
                message: 'Back',
                child: Icon(
                  Icons.chevron_left,
                  size: 32.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Semantics(
            header: true,
            child: AppText(
              'OCCUPATION DETAILS',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Progress step 4 of 5',
            child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.darkInputBackground,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 4 / 5, // Question 4 of 5
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            'Question 4 of 5',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Semantics(
      header: true,
      child: AppText(
        'Occupation Details',
        variant: AppTextVariant.headline5,
        weight: AppTextWeight.bold,
        colorType: AppTextColorType.primary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AppText(
      'We will use this information to tailor your experience and services throughout the app.',
      variant: AppTextVariant.bodyMedium,
      colorType: AppTextColorType.gray,
    );
  }

  Widget _buildOccupationSection() {
    return Semantics(
      label: 'Select occupation',
      hint: 'Opens occupation selection sheet',
      value: _selectedOccupationCode ?? 'Not selected',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: AppText(
              'What is your occupation?',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
          ),
          SizedBox(height: 12.h),
          OccupationDropdown(
            selectedOccupationId: _selectedOccupationCode,
            enabled: true,
            errorText: _showOccupationError ? 'Please select your occupation' : null,
            onOccupationSelected: (occupation) {
              setState(() {
                _selectedOccupationCode = occupation.id;
                _showOccupationError = false; // Clear error on selection
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection() {
    // Get selected income slab label (null if not selected to show hint)
    final selectedLabel = _selectedIncomeSlab != null
        ? _incomeSlabs.firstWhere(
            (slab) => slab['code'] == _selectedIncomeSlab,
            orElse: () => {'code': '', 'label': ''},
          )['label']
        : null;

    final label = 'What is your income details?';

    return Semantics(
      label: 'Select income details',
      hint: 'Opens income selection sheet',
      value: selectedLabel ?? 'Not selected',
      child: AppDropdown(
        labelText: label,
        hintText: 'Select your annual earning range',
        value: selectedLabel,
        errorText: _showIncomeError ? 'Please select your income range' : null,
        items: _incomeSlabs.map((slab) => slab['label']!).toList(),
        onChanged: (String? value) {
          if (value != null) {
            final selectedSlab = _incomeSlabs.firstWhere(
              (slab) => slab['label'] == value,
            );
            setState(() {
              _selectedIncomeSlab = selectedSlab['code'];
              _showIncomeError = false; // Clear error on selection
            });
          }
        },
      ),
    );
  }

  Widget _buildPepSection() {
    final label = 'Are you a politically exposed person?';
    final value = _isPep ? 'Yes' : 'No';

    return Semantics(
      label: 'Select PEP status',
      hint: 'Opens PEP selection sheet',
      value: value,
      child: AppDropdown(
        labelText: label,
        hintText: 'Select an option',
        value: value,
        items: const ['Yes', 'No'],
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _isPep = value == 'Yes';
            });
          }
        },
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isValid ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isValid ? Colors.white : AppColors.darkInputBackground,
            foregroundColor: _isValid ? Colors.black : AppColors.darkTextGray,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: AppText(
            'NEXT',
            variant: AppTextVariant.bodyLarge,
            weight: AppTextWeight.bold,
            customColor: _isValid ? Colors.black : AppColors.darkTextGray,
          ),
        ),
      ),
    );
  }
}
