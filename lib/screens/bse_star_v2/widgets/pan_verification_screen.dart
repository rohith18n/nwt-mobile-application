import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';

class PanVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  const PanVerificationScreen({
    super.key,
    this.onVerified,
    this.onSkip,
    this.onBack,
  });

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  bool _isVerifying = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _liveError;
  bool _addressFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingPanDetails();
  }

  Future<void> _fetchExistingPanDetails() async {
    setState(() => _isVerifying = true);
    try {
      final authService = AuthService();
      final data = await authService.getProfilePan(onLoading: (_) {});
      if (data != null && mounted) {
        setState(() {
          _panController.text = data['pan_number'] ?? '';
        });
      }
    } catch (e) {
      AppLogger.error('Error loading PAN data: $e', tag: 'PanVerification');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _validateLive(String val) {
    if (val.isEmpty) {
      setState(() => _liveError = null);
      return;
    }

    String? error;
    for (int i = 0; i < val.length; i++) {
      String char = val[i].toUpperCase();
      if (i < 5) {
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          error = "First 5 characters must be letters";
          break;
        }
      } else if (i >= 5 && i < 9) {
        if (!RegExp(r'[0-9]').hasMatch(char)) {
          error = "Characters 6-9 must be digits";
          break;
        }
      } else if (i == 9) {
        if (!RegExp(r'[A-Z]').hasMatch(char)) {
          error = "Last character must be a letter";
          break;
        }
      }
    }
    setState(() => _liveError = error);
  }

  Future<void> _updateAddressIfNeeded() async {
    try {
      final profileService = ProfileService();
      
      final extendedProfile = <String, dynamic>{};
      
      // Use ind_* fi12eld names to match holder_management
      if (_addressLine1Controller.text.isNotEmpty) {
        extendedProfile['ind_address_line_1'] = _addressLine1Controller.text.trim();
      }
      if (_cityController.text.isNotEmpty) {
        extendedProfile['ind_city'] = _cityController.text.trim();
      }
      if (_stateController.text.isNotEmpty) {
        extendedProfile['ind_state'] = _stateController.text.trim();
      }
      if (_pincodeController.text.isNotEmpty) {
        extendedProfile['ind_pincode'] = _pincodeController.text.trim();
      }
      
      // Also save name components if available
      if (_nameController.text.isNotEmpty) {
        final nameParts = _nameController.text.trim().split(' ');
        if (nameParts.isNotEmpty) {
          extendedProfile['primary_first_name'] = nameParts.first;
          if (nameParts.length > 1) {
            extendedProfile['primary_last_name'] = nameParts.last;
          }
        }
      }
      
      if (extendedProfile.isNotEmpty) {
        final response = await profileService.updateProfileDetails(
          extendedProfile: extendedProfile,
          panNumber: _panController.text.trim().toUpperCase(),
          dob: _dobController.text.trim(),
        );
        
        if (response != null && response.success) {
          AppLogger.info('Profile updated with PAN, DOB, and address', tag: 'PanVerification');
        }
      }
    } catch (e) {
      AppLogger.error('Error updating profile: $e', tag: 'PanVerification');
    }
  }

  void _handleVerify() async {
    final panErr = AppValidators.validatePanCard(_panController.text);

    if (panErr != null) {
      setState(() {
        _hasError = true;
        _errorMessage = panErr;
      });
      return;
    }

    try {
      setState(() {
        _isVerifying = true;
        _hasError = false;
        _errorMessage = null;
      });

      final profileService = ProfileService();
      
      // Step 1: Update PAN
      final verifyResponse = await profileService.updateProfileDetails(
        panNumber: _panController.text.trim().toUpperCase(),
      );

      if (!mounted) return;

      if (verifyResponse != null && verifyResponse.success) {
        AppLogger.info('PAN saved successfully', tag: 'PanVerification');
        
        // Step 2: Fetch complete profile data including address
        final profileDetailsResponse = await profileService.getProfileDetails();
        
        if (!mounted) return;
        
        if (profileDetailsResponse != null && profileDetailsResponse.success) {
          AppLogger.info('Profile details fetched successfully', tag: 'PanVerification');
          
          // Pre-fill name, DOB, and address fields if available
          final profileData = profileDetailsResponse.data;
          final extendedProfile = profileData?.uccProfile;
          
          setState(() {
            // Set name and DOB from profile
            _nameController.text = profileData?.name ?? '';
            _dobController.text = profileData?.dob ?? '';
            
            // Set address fields from extended profile (using ind_* fields for Indian address)
            if (extendedProfile != null) {
              _addressLine1Controller.text = extendedProfile['ind_address_line_1'] ?? extendedProfile['address_line_1'] ?? '';
              _cityController.text = extendedProfile['ind_city'] ?? extendedProfile['city'] ?? '';
              _stateController.text = extendedProfile['ind_state'] ?? extendedProfile['state'] ?? '';
              _pincodeController.text = extendedProfile['ind_pincode'] ?? extendedProfile['pincode'] ?? '';
            }
            
            _addressFetched = true;
          });
        } else {
          throw Exception('Failed to fetch profile data');
        }
      } else {
        final errorMessage = verifyResponse?.message ?? 'PAN verification failed';
        setState(() {
          _hasError = true;
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      AppLogger.error('PAN Verification Error', error: e, tag: 'PanVerification');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Something went wrong";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _handleContinue() async {
    try {
      setState(() => _isVerifying = true);
      
      // Update address if any field is filled
      await _updateAddressIfNeeded();
      
      if (!mounted) return;
      
      // Proceed to next screen
      if (widget.onVerified != null) {
        widget.onVerified!();
      }
    } catch (e) {
      AppLogger.error('Error updating address: $e', tag: 'PanVerification');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to update address";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    AppText(
                      "Verify your PAN",
                      variant: AppTextVariant.headline1,
                      weight: AppTextWeight.bold,
                    ),
                    SizedBox(height: 12.h),
                    AppText(
                      "We'll use this to fetch your investment\ndetails securely",
                      variant: AppTextVariant.bodyLarge,
                      colorType: AppTextColorType.secondary,
                    ),
                    SizedBox(height: 40.h),

                    _buildPanField(),

                    if (_liveError != null) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: AppText(
                          _liveError!,
                          variant: AppTextVariant.bodySmall,
                          customColor: AppColors.error,
                          weight: AppTextWeight.medium,
                        ),
                      ),
                    ],

                    if (_addressFetched) ...[
                      SizedBox(height: 32.h),
                      AppText(
                        "Personal Details",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                      ),
                      SizedBox(height: 8.h),
                      AppText(
                        "Verify your details from PAN records",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      SizedBox(height: 24.h),
                      _buildReadOnlyField("Full Name", _nameController),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField("Date of Birth", _dobController),
                      SizedBox(height: 32.h),
                      AppText(
                        "Address",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                      ),
                      SizedBox(height: 8.h),
                      AppText(
                        "Verify or update your address details",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      SizedBox(height: 24.h),
                      _buildAddressField("Address Line 1", _addressLine1Controller),
                      SizedBox(height: 16.h),
                      _buildAddressField("City", _cityController),
                      SizedBox(height: 16.h),
                      _buildAddressField("State", _stateController),
                      SizedBox(height: 16.h),
                      _buildAddressField("Pincode", _pincodeController, keyboardType: TextInputType.number),
                    ],

                    if (_isVerifying) ...[
                      SizedBox(height: 24.h),
                      _buildStatusCard(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF00C7AC),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                "Verifying details...",
                                variant: AppTextVariant.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_hasError) ...[
                      SizedBox(height: 24.h),
                      _buildStatusCard(
                        borderColor: AppColors.error,
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 24.w,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                _errorMessage ?? "Verification Failed",
                                variant: AppTextVariant.bodyMedium,
                                customColor: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    _buildInfoSection(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding.w,
        vertical: 16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24.w,
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildPanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "PAN Number",
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _panController,
          onChanged: (val) {
            _validateLive(val);
            setState(() => _hasError = false);
          },
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          inputFormatters: AppInputFormatters.panCardFormattersLenient(),
          decoration: InputDecoration(
            hintText: "ABCDE1234F",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              letterSpacing: 2.0,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 20.h,
            ),
            fillColor: AppColors.darkCardBG,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _liveError != null ? AppColors.error : Colors.transparent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _liveError != null ? AppColors.error : Colors.transparent,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _liveError != null
                    ? AppColors.error
                    : Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.darkButtonBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: AppText(
            controller.text.isNotEmpty ? controller.text : '-',
            variant: AppTextVariant.bodyMedium,
            colorType: controller.text.isNotEmpty 
                ? AppTextColorType.white 
                : AppTextColorType.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: controller,
          onChanged: (val) => setState(() {}),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 16.h,
            ),
            fillColor: AppColors.darkCardBG,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.darkButtonBorder,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkButtonBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: const Color(0xFF00C7AC),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              AppText(
                "Why we need this",
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoItem("Fetch your investment portfolio"),
          SizedBox(height: 12.h),
          _buildInfoItem("Verify your identity securely"),
          SizedBox(height: 12.h),
          _buildInfoItem("Compliant with RBI and SEBI regulations"),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_rounded, color: AppColors.darkTextGray, size: 18.w),
        SizedBox(width: 12.w),
        Expanded(
          child: AppText(
            text,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary,
            weight: AppTextWeight.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final bool showVerifyButton = !_addressFetched;
    final bool canVerify = _panController.text.length == 10 && _liveError == null && !_isVerifying;
    final bool canContinue = _addressFetched && !_isVerifying;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding.w,
        vertical: 16.h,
      ),
      child: AppButton(
        text: showVerifyButton ? "Verify" : "Continue",
        isFullWidth: true,
        onPressed: showVerifyButton
            ? (canVerify ? _handleVerify : () {})
            : (canContinue ? _handleContinue : () {}),
        isDisabled: showVerifyButton ? !canVerify : !canContinue,
      ),
    );
  }
}
