import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/ucc_trade_service.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/otp_bottom_sheet.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/add_holder_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/edit_holder_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/signature_screen.dart';

/// UCC Wizard Screen - Simplified
/// Step 1: Select Holder (Single/Joint)
/// Step 2: Select Nominee (Provide/Skip)
/// Step 3: Create UCC
/// Step 4: OTP Verification
class UccWizardScreen extends StatefulWidget {
  final String? fundName;
  final String? isin;
  final String? schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;
  final bool isSipMode;

  const UccWizardScreen({
    super.key,
    this.fundName,
    this.isin,
    this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
    this.isSipMode = false,
  });

  @override
  State<UccWizardScreen> createState() => _UccWizardScreenState();
}

class _UccWizardScreenState extends State<UccWizardScreen> {
  final UccTradeService _uccService = UccTradeService();
  final OnboardingV2Service _onboardingService = OnboardingV2Service();

  bool _isLoading = false;
  bool _isOtpVerifying = false; // Separate flag for OTP bottom sheet
  int _currentStep = 0; // Only 1 step now: Nominee selection
  String _holdingNature = 'SI'; // Auto-determined: SI or AS
  int? _secondaryHolderId; // Auto-detected from holders
  List<Map<String, dynamic>> _holders = [];
  String _nominationChoice = 'skip'; // skip or provide
  int? _selectedNomineeHolderId;

  // Step 3: UCC Data
  String? _clientCode;
  String? _uccId;
  String? _nextAction;

  @override
  void initState() {
    super.initState();
    _loadHolders();
  }

  Future<void> _loadHolders() async {
    try {
      setState(() => _isLoading = true);

      final response = await _onboardingService.getHolders();

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final holdersList = data['holders'] as List<dynamic>? ?? [];

        setState(() {
          _holders = holdersList.cast<Map<String, dynamic>>();
        });

        AppLogger.info(
          'Holders loaded: ${_holders.length} holders found',
          tag: 'UccWizard',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Error loading holders', error: e, tag: 'UccWizard');
    }
  }

  Future<void> _handleHolderContinue() async {
    // If AS selected, validate holder is selected
    if (_holdingNature == 'AS') {
      if (_secondaryHolderId == null) {
        _showError('Please select a joint holder');
        return;
      }
    }

    // Continue to nominee selection (signature check happens later)
    setState(() => _currentStep = 1);
  }

  Future<void> _navigateToHolderSignature(Map<String, dynamic> holder) async {
    await Get.to(
      () => SignatureScreen(
        onNext: (signature) async {
          await _updateHolderSignature(holder, signature);
        },
        onBack: () {
          Get.back();
        },
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _updateHolderSignature(
    Map<String, dynamic> holder,
    String signature,
  ) async {
    try {
      AppLogger.info(
        'Updating holder signature for ${holder['name']} (ID: ${holder['id']})',
        tag: 'UccWizard',
      );

      final response = await _onboardingService.updateHolderSignature(
        holderId: holder['id'],
        signature: signature,
      );

      if (response != null && response['success'] == true) {
        AppLogger.info(
          '✅ Holder signature updated successfully',
          tag: 'UccWizard',
        );

        // Reload holders to get updated signature status
        await _loadHolders();

        Get.back(); // Close signature screen

        // Continue with UCC creation (signature was collected after nominee selection)
        await _resolveUcc();
      } else {
        throw Exception(response?['message'] ?? 'Failed to update signature');
      }
    } catch (e) {
      AppLogger.error(
        '❌ Error updating holder signature: $e',
        tag: 'UccWizard',
      );
      _showError('Error saving signature: $e');
    }
  }

  Future<void> _navigateToAddHolder() async {
    final result = await Get.to(
      () => const AddHolderScreen(),
      transition: Transition.rightToLeft,
    );

    if (result != null && result is Map<String, dynamic>) {
      // Holder added successfully
      AppLogger.info(
        'Holder added: ${result['name']} (ID: ${result['id']})',
        tag: 'UccWizard',
      );

      // Reload holders list
      await _loadHolders();

      // Auto-select the newly added holder
      setState(() {
        _secondaryHolderId = result['id'];
      });
    }
  }

  Future<void> _navigateToAddNominee() async {
    // Reuse AddHolderScreen for adding nominee (same as web)
    final result = await Get.to(
      () => const AddHolderScreen(),
      transition: Transition.rightToLeft,
    );
    // Dismiss any lingering keyboard from AddHolderScreen
    FocusManager.instance.primaryFocus?.unfocus();

    if (result != null && result is Map<String, dynamic>) {
      // Holder added successfully - use as nominee
      AppLogger.info(
        'Holder added as nominee: ${result['name']} (ID: ${result['id']})',
        tag: 'UccWizard',
      );

      // Reload holders list
      await _loadHolders();

      // Auto-select the newly added holder as nominee
      setState(() {
        _selectedNomineeHolderId = result['id'];
      });

      // Automatically proceed to UCC creation (don't go back to nominee screen)
      await _handleNomineeContinue();
    }
  }

  // Get available holders for nominee (excluding secondary holder)
  List<Map<String, dynamic>> get _availableNominees {
    if (_holdingNature == 'SI') {
      // For SI, all holders can be nominees
      return _holders;
    } else {
      // For AS, exclude the secondary holder
      return _holders.where((h) => h['id'] != _secondaryHolderId).toList();
    }
  }

  Future<void> _editHolder(int holderId) async {
    // Find the holder data
    final holder = _holders.firstWhere(
      (h) => h['id'] == holderId,
      orElse: () => {},
    );

    if (holder.isEmpty) {
      _showError('Holder not found');
      return;
    }

    // Navigate to edit screen
    final result = await Get.to(
      () => EditHolderScreen(holderData: holder),
      transition: Transition.rightToLeft,
    );

    if (result != null && result is Map<String, dynamic>) {
      AppLogger.info('✅ Holder updated, reloading list', tag: 'UccWizard');
      // Reload holders list
      await _loadHolders();
    }
  }

  Future<void> _deleteHolder(int holderId) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.darkCardBG,
        title: AppText(
          'Delete Holder',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.bold,
        ),
        content: AppText(
          'Are you sure you want to delete this holder? This action cannot be undone.',
          variant: AppTextVariant.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: AppText('Cancel', colorType: AppTextColorType.gray),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: AppText('Delete', customColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final response = await _onboardingService.deleteHolder(
        holderId: holderId,
      );

      if (response != null && response['success'] == true) {
        AppLogger.info('✅ Holder deleted successfully', tag: 'UccWizard');

        // Clear selection if this was the selected holder
        if (_secondaryHolderId == holderId) {
          setState(() => _secondaryHolderId = null);
        }
        if (_selectedNomineeHolderId == holderId) {
          setState(() => _selectedNomineeHolderId = null);
        }

        // Reload holders list
        await _loadHolders();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Holder deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response?['message'] ?? 'Failed to delete holder');
      }
    } catch (e) {
      AppLogger.error('❌ Error deleting holder: $e', tag: 'UccWizard');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNomineeContinue() async {
    // Validate if provide is selected but no nominee added
    if (_nominationChoice == 'provide' && _selectedNomineeHolderId == null) {
      _showError('Please add nominee details first');
      return;
    }

    // Check if secondary holder needs signature (AFTER nominee selection)
    if (_holdingNature == 'AS' && _secondaryHolderId != null) {
      final selectedHolder = _holders.firstWhere(
        (h) => h['id'] == _secondaryHolderId,
        orElse: () => {},
      );

      if (selectedHolder.isNotEmpty &&
          selectedHolder['has_signature'] != true) {
        AppLogger.info(
          'Secondary holder ${selectedHolder['name']} missing signature - collecting now',
          tag: 'UccWizard',
        );
        // Navigate to signature collection
        await _navigateToHolderSignature(selectedHolder);
        return; // Will continue after signature is collected
      }
    }

    try {
      setState(() => _isLoading = true);
      await _resolveUcc();
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Error resolving UCC', error: e, tag: 'UccWizard');
      _showError('Failed to resolve UCC. Please try again.');
    }
  }

  Future<void> _resolveUcc() async {
    try {
      setState(() => _isLoading = true);

      AppLogger.info(
        'Resolving UCC: holding=$_holdingNature, nomination=$_nominationChoice',
        tag: 'UccWizard',
      );

      final response = await _uccService.resolveUcc(
        holdingNature: _holdingNature,
        secondaryHolderId: _secondaryHolderId?.toString(),
        nomination: _nominationChoice,
        nomineeHolderId: _selectedNomineeHolderId?.toString(),
      );

      setState(() => _isLoading = false);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final exists = data['exists'] == true;
        final investmentReady = data['investment_ready'] == true;

        if (exists && investmentReady) {
          // UCC exists and ready - go to orders
          _navigateToOrders(
            uccId: data['ucc_id'],
            clientCode: data['client_code'],
          );
        } else if (exists && data['ucc_sync_pending'] == true) {
          // Show API message or fallback to default
          _showError(
            response['message'] ??
            data['message'] ??
            'UCC is being synced with BSE. Please wait.',
          );
        } else {
          // UCC doesn't exist - create draft
          await _createUccDraft();
        }
      } else {
        _showError(response?['message'] ?? 'Failed to resolve UCC');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Error resolving UCC', error: e, tag: 'UccWizard');
      _showError('Failed to resolve UCC. Please try again.');
    }
  }

  Future<void> _createUccDraft() async {
    try {
      setState(() => _isLoading = true);

      final response = await _uccService.createUccDraft(
        holdingNature: _holdingNature,
        secondaryHolderId: _secondaryHolderId?.toString(),
      );

      setState(() => _isLoading = false);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        setState(() {
          _clientCode = data['client_code'];
          _uccId = data['ucc_id'];
        });

        // Now set nomination
        await _setNomination();
      } else {
        _showError(response?['message'] ?? 'Failed to create UCC draft');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Error creating UCC draft', error: e, tag: 'UccWizard');
      _showError('Failed to create UCC draft. Please try again.');
    }
  }

  Future<void> _setNomination() async {
    try {
      setState(() => _isLoading = true);

      final response = await _uccService.setNomination(
        clientCode: _clientCode!,
        choice: _nominationChoice,
        nomineeHolderId: _selectedNomineeHolderId?.toString(),
      );

      setState(() => _isLoading = false);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final nextAction = data['next_action'];

        AppLogger.info(
          '✅ UCC Nomination Set Successfully\n'
          'Client Code: ${data['client_code']}\n'
          'UCC ID: ${data['ucc_id']}\n'
          'Next Action: $nextAction\n'
          'BSE Finished: ${data['bse_finished']}\n'
          'Nomination Choice: $_nominationChoice\n'
          'Delivery: ${data['delivery']}\n'
          'Full Response: $response',
          tag: 'bseCreationResult',
        );

        setState(() {
          _nextAction = nextAction;
          _uccId = data['ucc_id'];
        });

        // Match web logic: check nomination choice first
        if (_nominationChoice == 'skip') {
          // Skip path - check if email was sent
          final delivery = data['delivery'];
          if (delivery != null && delivery['email_sent'] == true) {
            AppLogger.info(
              '📧 Opt-out OTP sent to email - showing bottom sheet\n'
              'Email masked: ${delivery['email_masked']}',
              tag: 'bseCreationResult',
            );
            _showOptOutOtpBottomSheet();
          } else {
            AppLogger.error(
              '❌ Email not sent for opt-out OTP\n'
              'Delivery: $delivery',
              tag: 'bseCreationResult',
            );
            _showError(
              'Could not send opt-out code to your email. Please try again.',
            );
          }
        } else if (data['bse_finished'] == true ||
            nextAction == 'bse_finished') {
          // Provide path - BSE auto-finished
          AppLogger.info(
            '🎉 UCC Creation Complete - BSE Finished\n'
            'UCC ID: ${data['ucc_id']}\n'
            'Client Code: ${data['client_code']}\n'
            'Payment UPI: ${data['payment_upi_id']}',
            tag: 'bseCreationResult',
          );
          _navigateToOrders(
            uccId: data['ucc_id'],
            clientCode: data['client_code'],
          );
        } else {
          // Provide path - BSE OTP required
          AppLogger.info(
            '📧 BSE OTP required - showing bottom sheet',
            tag: 'bseCreationResult',
          );
          _showBseOtpBottomSheet();
        }
      } else {
        AppLogger.error(
          '❌ Failed to set nomination\n'
          'Response: $response',
          tag: 'bseCreationResult',
        );
        _showError(response?['message'] ?? 'Failed to set nomination');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppLogger.error('Error setting nomination', error: e, tag: 'UccWizard');
      _showError('Failed to set nomination. Please try again.');
    }
  }

  void _showOptOutOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder:
          (context) => OtpBottomSheet(
            phoneNumber: 'your email (Nominee Opt-out)',
            onVerify: _handleOptOutOtpVerify,
            onResend: _resendOptOutOtp,
          ),
    );
  }

  void _showBseOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder:
          (context) => OtpBottomSheet(
            phoneNumber: 'your email (BSE verification)',
            onVerify: _handleBseOtpVerify,
            onResend: () async {
              _showError('BSE OTP cannot be resent. Please check your email.');
            },
          ),
    );
  }

  Future<void> _handleOptOutOtpVerify(String otp) async {
    try {
      setState(() => _isOtpVerifying = true);

      final response = await _uccService.verifyOptOutOtp(
        clientCode: _clientCode!,
        otp: otp,
      );

      setState(() => _isOtpVerifying = false);

      if (response != null && response['success'] == true) {
        final data = response['data'];

        AppLogger.info(
          '✅ Opt-out OTP Verified Successfully\n'
          'UCC ID: ${data['ucc_id']}\n'
          'Client Code: ${data['client_code']}\n'
          'BSE Finished: ${data['bse_finished']}\n'
          'Next Action: ${data['next_action']}\n'
          'Payment UPI: ${data['payment_upi_id']}\n'
          'Full Response: $response',
          tag: 'bseCreationResult',
        );

        // Close OTP bottom sheet
        Get.back();

        // Navigate to orders
        _navigateToOrders(
          uccId: data['ucc_id'],
          clientCode: data['client_code'],
        );
      } else {
        AppLogger.error(
          '❌ Opt-out OTP Verification Failed\n'
          'Response: $response',
          tag: 'bseCreationResult',
        );
        // Close bottom sheet and show error on main screen
        Get.back();
        _showError(response?['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() => _isOtpVerifying = false);
      AppLogger.error(
        'Error verifying opt-out OTP',
        error: e,
        tag: 'UccWizard',
      );
      // Close bottom sheet and show error on main screen
      Get.back();
      _showError('Failed to verify OTP. Please try again.');
    }
  }

  Future<void> _handleBseOtpVerify(String otp) async {
    try {
      setState(() => _isOtpVerifying = true);

      final response = await _uccService.submitBseOtp(
        clientCode: _clientCode!,
        otp: otp,
      );

      setState(() => _isOtpVerifying = false);

      if (response != null && response['success'] == true) {
        final data = response['data'];

        AppLogger.info(
          '✅ BSE OTP Verified Successfully\n'
          'UCC ID: ${data['ucc_id']}\n'
          'Client Code: ${data['client_code']}\n'
          'Payment UPI: ${data['payment_upi_id']}\n'
          'Full Response: $response',
          tag: 'bseCreationResult',
        );

        // Close OTP bottom sheet
        Get.back();

        // Navigate to orders
        _navigateToOrders(
          uccId: data['ucc_id'],
          clientCode: data['client_code'],
        );
      } else {
        AppLogger.error(
          '❌ BSE OTP Verification Failed\n'
          'Response: $response',
          tag: 'bseCreationResult',
        );
        // Close bottom sheet and show error on main screen
        Get.back();
        _showError(response?['message'] ?? 'Invalid BSE OTP');
      }
    } catch (e) {
      setState(() => _isOtpVerifying = false);
      AppLogger.error(
        '❌ Exception during BSE OTP verification',
        error: e,
        tag: 'bseCreationResult',
      );
      // Close bottom sheet and show error on main screen
      Get.back();
      _showError('Failed to verify BSE OTP. Please try again.');
    }
  }

  Future<void> _resendOptOutOtp() async {
    try {
      setState(() => _isOtpVerifying = true);

      final response = await _uccService.resendOptOutOtp(
        clientCode: _clientCode!,
      );

      setState(() => _isOtpVerifying = false);

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(response?['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      setState(() => _isOtpVerifying = false);
      AppLogger.error('Error resending OTP', error: e, tag: 'UccWizard');
    }
  }

  void _navigateToOrders({String? uccId, String? clientCode}) {
    AppLogger.info(
      'UCC creation complete - returning to order screen\nUCC ID: $uccId\nClient Code: $clientCode',
      tag: 'UccWizard',
    );

    // Return to previous screen with UCC data
    Get.back(
      result: {'success': true, 'uccId': uccId, 'clientCode': clientCode},
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _currentStep == 0
        ? _buildHolderSelectionStep()
        : _buildNomineeSelectionStep();

    if (!_isLoading || _isOtpVerifying) return content;

    return Stack(
      children: [
        content,
        Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.darkPrimary),
                    const SizedBox(height: 16),
                    AppText(
                      'Please wait…',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHolderSelectionStep() {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Select Account Type',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'CONTINUE',
              onPressed: _handleHolderContinue,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Choose Account Holding',
              variant: AppTextVariant.headline5,
              weight: AppTextWeight.bold,
            ),
            SizedBox(height: 8.h),
            AppText(
              'Select whether you want to invest individually or jointly',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.gray,
            ),
            SizedBox(height: 32.h),
            _buildHolderOption(
              title: 'Single Holder',
              subtitle: 'Invest individually in your name only',
              value: 'SI',
              isSelected: _holdingNature == 'SI',
            ),
            SizedBox(height: 16.h),
            _buildHolderOption(
              title: 'Joint Holder',
              subtitle: 'Invest jointly with another person',
              value: 'AS',
              isSelected: _holdingNature == 'AS',
            ),
            if (_holdingNature == 'AS') ...[
              SizedBox(height: 24.h),
              AppText(
                'Select Joint Holder',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.semiBold,
              ),
              SizedBox(height: 12.h),

              // Holder cards
              ..._holders.map((holder) {
                final isSelected = _secondaryHolderId == holder['id'];
                final hasSignature = holder['has_signature'] == true;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.darkPrimary
                              : AppColors.darkInputBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap:
                        () => setState(() => _secondaryHolderId = holder['id']),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          // Radio indicator
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.darkPrimary
                                        : Colors.grey,
                                width: 2,
                              ),
                              color:
                                  isSelected
                                      ? AppColors.darkPrimary
                                      : Colors.transparent,
                            ),
                            child:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      size: 14.sp,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          SizedBox(width: 12.w),

                          // Holder info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  holder['name'] ?? 'Unknown',
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.semiBold,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  holder['pan_number'] ?? '',
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.gray,
                                ),
                                if (!hasSignature) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      AppText(
                                        'Signature required',
                                        variant: AppTextVariant.bodySmall,
                                        colorType: AppTextColorType.warning,
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      AppText(
                                        'Signature on file',
                                        variant: AppTextVariant.bodySmall,
                                        colorType: AppTextColorType.success,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Action buttons
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppColors.darkPrimary,
                              size: 20.sp,
                            ),
                            onPressed: () => _editHolder(holder['id']),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20.sp,
                            ),
                            onPressed: () => _deleteHolder(holder['id']),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Add new holder button
              InkWell(
                onTap: _navigateToAddHolder,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkPrimary,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.darkPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        'Add New Holder',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.primary,
                        weight: AppTextWeight.semiBold,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHolderOption({
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _holdingNature = value),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.darkButtonPrimaryBackground.withOpacity(0.1)
                  : AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.darkButtonPrimaryBackground
                    : AppColors.darkInputBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
                  isSelected
                      ? AppColors.darkButtonPrimaryBackground
                      : Colors.grey,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNomineeSelectionStep() {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AppText(
          'Select Nominee',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _currentStep = 0);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Continue',
              onPressed: _handleNomineeContinue,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Choose Nomination',
              variant: AppTextVariant.headline5,
              weight: AppTextWeight.bold,
            ),
            SizedBox(height: 8.h),
            AppText(
              'Select whether you want to provide a nominee or skip',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.gray,
            ),
            SizedBox(height: 32.h),
            _buildNomineeOption(
              title: 'Skip Nominee',
              subtitle: 'Proceed without adding a nominee (requires OTP)',
              value: 'skip',
              isSelected: _nominationChoice == 'skip',
            ),
            SizedBox(height: 16.h),
            _buildNomineeOption(
              title: 'Provide Nominee',
              subtitle: 'Add a nominee for your investment',
              value: 'provide',
              isSelected: _nominationChoice == 'provide',
            ),
            if (_nominationChoice == 'provide') ...[
              SizedBox(height: 24.h),
              AppText(
                'Select Nominee Holder',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.semiBold,
              ),
              SizedBox(height: 8.h),
              AppText(
                _holdingNature == 'SI'
                    ? 'Your holders on file'
                    : 'Holders excluding second holder',
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.gray,
              ),
              SizedBox(height: 12.h),

              if (_availableNominees.isEmpty) ...[
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AppText(
                          'No holders available. Add a holder below.',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ] else ...[
                // Nominee holder cards
                ..._availableNominees.map((holder) {
                  final isSelected = _selectedNomineeHolderId == holder['id'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.darkPrimary
                                : AppColors.darkInputBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap:
                          () => setState(
                            () => _selectedNomineeHolderId = holder['id'],
                          ),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            // Radio indicator
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.darkPrimary
                                          : Colors.grey,
                                  width: 2,
                                ),
                                color:
                                    isSelected
                                        ? AppColors.darkPrimary
                                        : Colors.transparent,
                              ),
                              child:
                                  isSelected
                                      ? Icon(
                                        Icons.check,
                                        size: 14.sp,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            SizedBox(width: 12.w),

                            // Holder info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    holder['name'] ?? 'Unknown',
                                    variant: AppTextVariant.bodyLarge,
                                    weight: AppTextWeight.semiBold,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    holder['pan_number'] ?? '',
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.gray,
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: AppColors.darkPrimary,
                                size: 20.sp,
                              ),
                              onPressed: () => _editHolder(holder['id']),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20.sp,
                              ),
                              onPressed: () => _deleteHolder(holder['id']),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              // Add new nominee button
              InkWell(
                onTap: _navigateToAddNominee,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkPrimary,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.darkPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        'Add Holder as Nominee',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.primary,
                        weight: AppTextWeight.semiBold,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNomineeOption({
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _nominationChoice = value),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.darkButtonPrimaryBackground.withOpacity(0.1)
                  : AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.darkButtonPrimaryBackground
                    : AppColors.darkInputBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
                  isSelected
                      ? AppColors.darkButtonPrimaryBackground
                      : Colors.grey,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
