import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';

class PanPhoneCollection extends StatefulWidget {
  final Function(String pan, String phone) onNext;
  final String? initialPan;
  final String? initialPhone;

  const PanPhoneCollection({
    super.key,
    required this.onNext,
    this.initialPan,
    this.initialPhone,
  });

  @override
  State<PanPhoneCollection> createState() => _PanPhoneCollectionState();
}

class _PanPhoneCollectionState extends State<PanPhoneCollection> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  
  String _selectedCountryCode = '+91';
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPan != null) {
      _panController.text = widget.initialPan!;
    }
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
    _panController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _panController.dispose();
    _phoneController.dispose();
    _panFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    final pan = _panController.text.trim();
    final phone = _phoneController.text.trim();
    final cleanPhone = AppValidators.cleanPhoneNumber(phone);
    
    // PAN validation: 10 characters, format: ABCDE1234F
    final panValid = pan.length == 10 && RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan.toUpperCase());
    
    // Phone validation: 10 digits for Indian numbers
    final phoneValid = cleanPhone.length == 10;
    
    setState(() {
      _isValid = panValid && phoneValid;
    });
  }

  void _handleNext() {
    if (_isValid) {
      final pan = _panController.text.trim().toUpperCase();
      final phone = _phoneController.text.trim();
      
      AppLogger.info(
        'PAN and Phone collected - PAN: $pan, Phone: $phone',
        tag: 'PanPhoneCollection',
      );
      
      widget.onNext(pan, phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Progress indicator
            _buildProgressBar(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),
                    
                    // Illustration
                    _buildIllustration(),
                    
                    SizedBox(height: 32.h),
                    
                    // Title
                    AppText(
                      'Enter your PAN',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // PAN Input
                    _buildPanInput(),
                    
                    SizedBox(height: 32.h),
                    
                    // Phone Title
                    AppText(
                      'Enter your phone number',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Phone Input
                    _buildPhoneInput(),
                    
                    SizedBox(height: 32.h),
                    
                    // Info Cards
                    _buildInfoCards(),
                    
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
            
            // Next Button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AppText(
                'PAN VERIFICATION',
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
          ),
          SizedBox(width: 36.w), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: 1 / 6, // Step 1 of 6
            backgroundColor: AppColors.darkCardBG,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkPrimary),
            minHeight: 4.h,
          ),
          SizedBox(height: 8.h),
          AppText(
            'Question 1 of 6',
            variant: AppTextVariant.caption,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: Container(
        width: 120.w,
        height: 120.w,
        decoration: BoxDecoration(
          color: AppColors.darkCardBG.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.search,
          size: 60.sp,
          color: AppColors.darkPrimary,
        ),
      ),
    );
  }

  Widget _buildPanInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'PAN',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _panController,
          focusNode: _panFocusNode,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            letterSpacing: 2,
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: 'HCMSB6578L',
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16.sp,
            ),
            filled: true,
            fillColor: AppColors.darkCardBG,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
            ),
            counterText: '',
            suffixIcon: GestureDetector(
              onTap: () {
                // TODO: Implement "Don't know my PAN" functionality
                AppLogger.info('Don\'t know my PAN clicked', tag: 'PanPhoneCollection');
              },
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Center(
                  widthFactor: 1,
                  child: AppText(
                    'Don\'t know my PAN',
                    variant: AppTextVariant.caption,
                    customColor: AppColors.darkPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country Code Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  AppText(
                    _selectedCountryCode,
                    variant: AppTextVariant.bodyMedium,
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            
            // Phone Number Input
            Expanded(
              child: TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                enabled: true,
                readOnly: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '7045321654',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.darkCardBG,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
                  ),
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.check_circle_outline,
          text: 'We share your PAN and mobile with Cashfree to securely help you invest and give unified view of investment holdings',
        ),
        SizedBox(height: 12.h),
        _buildInfoCard(
          icon: Icons.verified_user_outlined,
          text: 'SEBI Registered Investment Advisor: INA000020396',
        ),
        SizedBox(height: 12.h),
        _buildInfoCard(
          icon: Icons.lock_outline,
          text: 'Your data is encrypted and 100% secure',
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.darkCardBG,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.darkPrimary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppText(
              text,
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        text: 'NEXT',
        isFullWidth: true,
        onPressed: _isValid ? _handleNext : null,
        isDisabled: !_isValid,
      ),
    );
  }
}
