import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';
import 'package:nwt_app/services/profile/investment_readiness_service.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/holder_details_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/bank_verification_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/occupation_details_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/signature_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/onboarding_success_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/ucc_wizard_screen.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/analytics_drop_off_detector.dart';

/// Refactored BSE V2 Final Journey
/// 
/// Step numbering (NEW):
/// - Step 0: Universal PAN Verification (Phone + OTP + PAN) - UNIVERSAL WIDGET
/// - Step 1: Holder Details (was Step 2)
/// - Step 2: Bank Verification (was Step 3)
/// - Step 3: Occupation Details (was Step 4)
/// - Step 4: Signature (was Step 5)
/// - Step 5: Success Screen (was Step 6)
class BseV2FinalJourneyRefactored extends StatefulWidget {
  final String? fundName;
  final String? isin;
  final String? schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;

  const BseV2FinalJourneyRefactored({
    super.key,
    this.fundName,
    this.isin,
    this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
  });

  @override
  State<BseV2FinalJourneyRefactored> createState() => _BseV2FinalJourneyRefactoredState();
}

class _BseV2FinalJourneyRefactoredState extends State<BseV2FinalJourneyRefactored> 
    with DropOffTrackingMixin {
  final OnboardingV2Service _onboardingService = OnboardingV2Service();
  final DateTime _journeyStartTime = DateTime.now();

  @override
  String get screenName => 'bse_v2_journey';
  final InvestmentReadinessService _readinessService = InvestmentReadinessService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 0 data (Universal PAN Verification)
  String? _pan;
  String? _phone;
  String? _email;
  bool _isPhoneValidated = false;
  bool _isEmailValidated = false;
  bool _needsEmailVerification = false;
  
  // Step 1 data (Holder Details - was Step 2)
  Map<String, dynamic>? _holderData;
  int? _holderId;

  @override
  void initState() {
    super.initState();
    AppLogger.info('BSE V2 Final Journey (Refactored) started', tag: 'BseV2FinalJourney');
    
    // Track BSE V2 journey start
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.bseV2JourneyStarted,
      parameters: {
        'screen_name': screenName,
        'fund_name': widget.fundName ?? '',
        'isin': widget.isin ?? '',
        'scheme_code': widget.schemeCode ?? '',
        'min_amount': widget.minAmount?.toString() ?? '',
        'journey_start_time': _journeyStartTime.toIso8601String(),
      },
    );
    
    _checkInvestmentReadiness();
  }

  /// Check if user can skip onboarding steps
  Future<void> _checkInvestmentReadiness() async {
    setState(() => _isLoading = true);

    try {
      // First check if PAN and phone are already verified
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();
      
      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        final panStatus = data['pan']?['status'];
        final phoneStatus = data['phone']?['status'];
        final emailStatus = data['email']?['status'];
        final context = data['context'] as Map<String, dynamic>?;
        final needsEmail = context?['needs_email'] == true;
        
        AppLogger.info(
          'BSE Journey - Validation status - PAN: $panStatus, Phone: $phoneStatus, Email: $emailStatus, NeedsEmail: $needsEmail',
          tag: 'BseV2FinalJourney',
        );
        
        // Get user data for pre-filling
        final userController = Get.find<UserController>();
        final userData = userController.userData;
        
        // Store verification states for Step 0
        setState(() {
          _isPhoneValidated = phoneStatus == 'verified';
          _isEmailValidated = emailStatus == 'verified';
          _needsEmailVerification = !_isEmailValidated && (needsEmail || emailStatus == 'pending');
          _phone = userData?.phonenumber;
          _email = userData?.email;
        });
        
        // If PAN, phone AND email are all verified, skip step 0
        if (panStatus == 'verified' && phoneStatus == 'verified' && emailStatus == 'verified') {
          AppLogger.info(
            'PAN, phone and email already verified - skipping step 0',
            tag: 'BseV2FinalJourney',
          );
          
          // Get PAN from UserController
          final panNumber = userData?.pannumber;
          
          if (panNumber != null) {
            setState(() {
              _pan = panNumber;
              _currentStep = 1; // Skip to step 1 (Holder Details)
            });
            
            // Track PAN verification completion (skipped)
            AnalyticsService.to.logEvent(
              name: AnalyticsEvents.bseV2PanVerificationCompleted,
              parameters: {
                'screen_name': screenName,
                'verification_method': 'already_verified',
                'step_skipped': true,
              },
            );
            
            // Fetch profile details for step 1
            _fetchProfileDetails();
            return;
          }
        }
      }
      
      final readiness = await _readinessService.canInvestDirectly();

      if (readiness['canInvest'] == true) {
        // ✅ User has completed all steps - skip to order screen
        AppLogger.info('User is investment ready - skipping onboarding', tag: 'BseV2FinalJourney');
        
        setState(() => _isLoading = false);
        
        // Replace current screen with order screen
        Get.off(
          () => CreateOrderV1Screen(
            fundName: widget.fundName ?? '',
            isin: widget.isin ?? '',
            schemeCode: widget.schemeCode ?? '',
            nav: widget.nav,
            minAmount: widget.minAmount,
          ),
        );
      } else {
        // Check if it's just UCC creation needed
        final nextStep = readiness['nextStep'];
        
        if (nextStep == 'create_ucc') {
          // Profile complete, just need UCC - skip to UCC wizard
          AppLogger.info('Profile complete, skipping to UCC creation', tag: 'BseV2FinalJourney');
          setState(() => _isLoading = false);
          
          // Navigate to UCC wizard directly
          Get.off(
            () => UccWizardScreen(
              fundName: widget.fundName,
              isin: widget.isin,
              schemeCode: widget.schemeCode,
              nav: widget.nav,
              minAmount: widget.minAmount,
            ),
          );
        } else {
          // User needs to complete onboarding steps
          AppLogger.info('User needs onboarding: ${readiness['reason']}', tag: 'BseV2FinalJourney');
          setState(() => _isLoading = false);
          // Continue with normal flow (step 0)
        }
      }
    } catch (e) {
      AppLogger.error('Error checking readiness: $e', tag: 'BseV2FinalJourney');
      setState(() => _isLoading = false);
      // Continue with normal flow on error
    }
  }

  // Step 0: Universal PAN Verification (Phone + OTP + PAN)
  void _handlePanVerificationSuccess(Map<String, dynamic> panData) {
    setState(() {
      _pan = panData['pan_number'];
    });

    AppLogger.info(
      'Step 0 complete - PAN verified: $_pan',
      tag: 'BseV2FinalJourney',
    );

    // Identify user in CleverTap with email from verification data
    final userId = panData['user_id']?.toString();
    final email = panData['email'] as String? ?? '';
    final phoneNumber = panData['phone_number'] as String? ?? '';
    final name = panData['name'] as String? ?? '';

    if (userId != null && userId.isNotEmpty) {
      AnalyticsService.to.identifyUser(
        userId: userId,
        phoneNumber: phoneNumber,
        name: name,
        email: email,
      );
      AppLogger.info(
        'User identified in CleverTap - ID: $userId, Email: $email',
        tag: 'BseV2FinalJourney',
      );
    }

    // Check if user is self or joint holder
    final isSelf = panData['self'] == true;

    if (isSelf) {
      // User is adding their own PAN (primary holder)
      AppLogger.info('Self PAN detected - fetching profile details', tag: 'BseV2FinalJourney');
      _fetchProfileDetails();
    } else {
      // User is adding a joint holder
      _addHolder();
    }
  }

  void _handlePanVerificationError(String error) {
    AppLogger.error('PAN verification error: $error', tag: 'BseV2FinalJourney');
    _showError(error);
  }

  // Fetch Profile Details (when user verifies their own PAN)
  Future<void> _fetchProfileDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.getProfileDetails();

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info('Profile details fetched', tag: 'BseV2FinalJourney');
        
        final data = response['data'];
        setState(() {
          _holderData = data;
          _holderId = data?['id'];
        });
        
        // Move to Step 1 (Holder Details)
        setState(() {
          _currentStep = 1;
        });
      } else {
        _showError(response?['message'] ?? 'Failed to fetch profile details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error fetching profile details', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to fetch profile details. Please try again.');
    }
  }

  // Add Holder (when user adds a joint holder)
  Future<void> _addHolder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.addHolder(
        panNumber: _pan!,
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info('Holder added successfully', tag: 'BseV2FinalJourney');
        
        final data = response['data'];
        setState(() {
          _holderData = data;
          _holderId = data?['id'];
        });
        
        // Move to Step 1 (Holder Details)
        setState(() {
          _currentStep = 1;
        });
      } else {
        _showError(response?['message'] ?? 'Failed to add holder');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error adding holder', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to add holder. Please try again.');
    }
  }

  // Step 1: Holder Details (was Step 2)
  Future<void> _handleHolderDetailsSubmit(Map<String, dynamic> addressData) async {
    AppLogger.info('Step 1 complete - Holder details submitted', tag: 'BseV2FinalJourney');
    
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic>? response;
      
      if (_holderId != null) {
        // Joint holder - update holder address
        response = await _onboardingService.updateHolder(
          holderId: _holderId!,
          address: addressData,
        );
      } else {
        // Self (primary holder) - update profile address and gender
        final gender = addressData['gender'];
        response = await _onboardingService.updateProfileDetails(
          address: addressData,
          gender: gender,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        setState(() {
          _currentStep = 2; // Move to Step 2 (Bank Verification)
        });
      } else {
        _showError(response?['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error updating address', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to update address. Please try again.');
    }
  }

  // Step 2: Bank Verification (was Step 3)
  Future<void> _handleBankVerificationComplete(Map<String, dynamic> bankData) async {
    AppLogger.info('Step 2 complete - Bank verified', tag: 'BseV2FinalJourney');
    
    try {
      // If bank was pre-verified, skip API calls
      if (bankData['was_pre_verified'] == true) {
        AppLogger.info(
          'Bank was pre-verified - proceeding to occupation details',
          tag: 'BseV2FinalJourney',
        );
        setState(() {
          _currentStep = 3; // Move to Step 3 (Occupation Details)
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      final mode = bankData['mode'];
      Map<String, dynamic>? response;

      if (mode == 'upi') {
        // UPI flow: lookup then confirm
        final upiId = bankData['upi_id'];
        
        // Step 1: Lookup UPI
        final lookupResponse = await _onboardingService.upiLookup(upiId: upiId);
        
        if (lookupResponse != null && lookupResponse['success'] == true) {
          // Step 2: Confirm UPI
          final accountType = _mapAccountType(bankData['account_type']);
          final residency = _mapResidency(bankData['account_type']);
          
          response = await _onboardingService.upiConfirm(
            upiId: upiId,
            accountType: accountType,
            investorResidency: residency,
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          _showError(lookupResponse?['message'] ?? 'Failed to verify UPI ID');
          return;
        }
      } else {
        // Manual bank flow
        final accountType = _mapAccountType(bankData['account_type']);
        final residency = _mapResidency(bankData['account_type']);
        
        response = await _onboardingService.manualBank(
          accountNumber: bankData['account_number'],
          ifscCode: bankData['ifsc_code'],
          accountType: accountType,
          investorResidency: residency,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        setState(() {
          _currentStep = 3; // Move to Step 3 (Occupation Details)
        });
      } else {
        _showError(response?['message'] ?? 'Failed to verify bank');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error verifying bank', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to verify bank. Please try again.');
    }
  }

  String _mapAccountType(String displayType) {
    if (displayType.contains('Savings')) return 'savings';
    if (displayType.contains('NRE') || displayType.contains('NRO')) return 'savings';
    return 'savings';
  }

  String _mapResidency(String displayType) {
    if (displayType.contains('NRE')) return 'NRI-NRE';
    if (displayType.contains('NRO')) return 'NRI-NRO';
    return 'Resident';
  }

  // Step 3: Occupation Details (was Step 4)
  Future<void> _handleOccupationDetailsSubmit(Map<String, dynamic> occupationData) async {
    AppLogger.info('Step 3 complete - Occupation details submitted', tag: 'BseV2FinalJourney');
    
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.updateProfileDetails(
        occupation: occupationData['occupation_code'] as String?,
        incomeSlab: occupationData['income_slab'] as String?,
        pep: occupationData['pep'] == true ? 'Y' : 'N',
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        setState(() {
          _currentStep = 4; // Move to Step 4 (Signature)
        });
      } else {
        _showError(response?['message'] ?? 'Failed to update occupation details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error updating occupation details', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to update occupation details. Please try again.');
    }
  }

  // Step 4: Signature (was Step 5)
  Future<void> _handleSignatureComplete(String signatureBase64) async {
    AppLogger.info('Step 4 complete - Signature captured', tag: 'BseV2FinalJourney');
    
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.updateProfileDetails(
        signature: signatureBase64,
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        // Navigate directly to success screen
        _navigateToSuccessScreen();
      } else {
        _showError(response?['message'] ?? 'Failed to update signature');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error updating signature', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to update signature. Please try again.');
    }
  }

  // Navigate to Success Screen
  void _navigateToSuccessScreen() {
    AppLogger.info('BSE V2 journey complete - navigating to success screen', tag: 'BseV2FinalJourney');
    
    Get.offAll(
      () => OnboardingSuccessScreen(
        fundName: widget.fundName,
        isin: widget.isin,
        schemeCode: widget.schemeCode,
        nav: widget.nav,
        fundLogo: widget.fundLogo,
        minAmount: widget.minAmount,
      ),
      transition: Transition.fadeIn,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildCurrentStep();
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Step 0: Universal PAN Verification (Phone/Email + OTP + PAN)
        return UniversalPanVerificationWidget(
          phoneNumber: _phone,
          isPhoneValidated: _isPhoneValidated,
          isEmailValidated: _isEmailValidated,
          needsEmailVerification: _needsEmailVerification,
          email: _email,
          panNumber: _pan,
          onSuccess: _handlePanVerificationSuccess,
          onError: _handlePanVerificationError,
          showProgress: true,
          currentStep: 1, // Display as "Question 1 of 6"
          totalSteps: 6,
        );

      case 1:
        // Step 1: Holder Details (was Step 2)
        return HolderDetailsScreen(
          holderData: _holderData!,
          onNext: _handleHolderDetailsSubmit,
          onBack: () {
            setState(() {
              _currentStep = 0; // Go back to PAN verification
            });
          },
        );

      case 2:
        // Step 2: Bank Verification (was Step 3)
        return BankVerificationScreen(
          onNext: _handleBankVerificationComplete,
          onBack: () {
            setState(() {
              _currentStep = 1;
            });
          },
        );

      case 3:
        // Step 3: Occupation Details (was Step 4)
        return OccupationDetailsScreen(
          onNext: _handleOccupationDetailsSubmit,
          onBack: () {
            setState(() {
              _currentStep = 2;
            });
          },
        );

      case 4:
        // Step 4: Signature (was Step 5)
        return SignatureScreen(
          onNext: _handleSignatureComplete,
          onBack: () {
            setState(() {
              _currentStep = 3;
            });
          },
        );

      case 5:
        // This case should never be reached as we navigate directly to success screen
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );

      default:
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Center(
            child: Text('Unknown step: $_currentStep'),
          ),
        );
    }
  }
}
