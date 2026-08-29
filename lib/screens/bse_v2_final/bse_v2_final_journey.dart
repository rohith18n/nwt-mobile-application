import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/holder_details_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/bank_verification_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/occupation_details_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/signature_screen.dart';
import 'package:nwt_app/screens/bse_v2_final/widgets/onboarding_success_screen.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class BseV2FinalJourney extends StatefulWidget {
  final String? fundName;
  final String? isin;
  final String? schemeCode;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;
  final bool showMfBrowse;
  final bool skipPanVerification;
  final bool fromPersonalizeFlow;

  const BseV2FinalJourney({
    super.key,
    this.fundName,
    this.isin,
    this.schemeCode,
    this.nav,
    this.fundLogo,
    this.minAmount,
    this.showMfBrowse = false,
    this.skipPanVerification = false,
    this.fromPersonalizeFlow = false,
  });

  @override
  State<BseV2FinalJourney> createState() => _BseV2FinalJourneyState();
}

class _BseV2FinalJourneyState extends State<BseV2FinalJourney> {
  final OnboardingV2Service _onboardingService = OnboardingV2Service();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _skippedPanVerification = false; // Track if we skipped step 0
  
  // Step 1 data
  String? _pan;
  String? _phone;
  String? _email;
  bool _isPhoneValidated = false;
  bool _isEmailValidated = false;
  bool _needsEmailVerification = false;
  
  // Step 2 data (from PAN verification)
  Map<String, dynamic>? _holderData;
  int? _holderId;

  // Validate API context passed to HolderDetailsScreen
  String _validateMode = 'address'; // 'address' | 'ri_address' | 'nri_address'
  Map<String, dynamic> _validateContext = {};

  @override
  void initState() {
    super.initState();
    AppLogger.info('BSE V2 Final Journey started', tag: 'BseV2FinalJourney');
    _checkInvestmentReadiness();
  }

  /// Route to the correct onboarding step using /profile/validate next_step.
  /// Only the starting step is changed — all step handlers remain untouched.
  Future<void> _checkInvestmentReadiness() async {
    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse == null || validateResponse['success'] != true) {
        AppLogger.warning(
          'profile/validate failed - defaulting to step 0',
          tag: 'BseV2FinalJourney',
        );
        setState(() => _isLoading = false);
        return;
      }

      final data = validateResponse['data'] as Map<String, dynamic>;
      final nextStep = data['next_step'] as String? ?? 'contact_and_pan';
      final context = data['context'] as Map<String, dynamic>?;
      final panStatus = data['pan']?['status'];
      final phoneStatus = data['phone']?['status'];
      final emailStatus = data['email']?['status'];
      final needsEmail = context?['needs_email'] == true;

      AppLogger.info(
        'profile/validate next_step: $nextStep, PAN: $panStatus, Phone: $phoneStatus, Email: $emailStatus, NeedsEmail: $needsEmail',
        tag: 'BseV2FinalJourney',
      );

      // Prefill PAN + phone + email from UserController for steps that skip step 0
      final userController = Get.find<UserController>();
      final userData = userController.userData;
      final panNumber = userData?.pannumber;
      final phoneNumber = userData?.phonenumber;
      final email = userData?.email;
      
      // Store verification states for Step 0
      setState(() {
        _isPhoneValidated = phoneStatus == 'verified';
        _isEmailValidated = emailStatus == 'verified';
        _needsEmailVerification = !_isEmailValidated && (needsEmail || emailStatus == 'pending');
        _phone = phoneNumber;
        _email = email;
      });

      switch (nextStep) {
        case 'complete':
        case 'mf_central':
        case 'financial_aggregator':
          // Profile onboarding done — go straight to order screen.
          // CreateOrderV1Screen handles UCC creation internally.
          AppLogger.info(
            'Profile complete ($nextStep) — going to order screen',
            tag: 'BseV2FinalJourney',
          );
          setState(() => _isLoading = false);
          Get.off(
            () => CreateOrderV1Screen(
              fundName: widget.fundName ?? '',
              isin: widget.isin ?? '',
              schemeCode: widget.schemeCode ?? '',
              nav: widget.nav,
              minAmount: widget.minAmount,
            ),
          );

        case 'address':
        case 'ri_address':
        case 'nri_address':
          // PAN + phone done, jump straight to Step 1 (address/holder details)
          _pan = panNumber;
          _phone = phoneNumber;
          _skippedPanVerification = true;
          _validateMode = nextStep; // 'address' | 'ri_address' | 'nri_address'
          _validateContext = (data['context'] as Map<String, dynamic>?) ?? {};
          AppLogger.info(
            'Jumping to Step 1 (mode: $nextStep, context: $_validateContext)',
            tag: 'BseV2FinalJourney',
          );
          await _fetchProfileDetails(); // populates _holderData, sets _currentStep = 1

        case 'bank':
          // Address done, jump straight to Step 2 (bank)
          _pan = panNumber;
          _phone = phoneNumber;
          _skippedPanVerification = true;
          await _fetchProfileDetails(); // ensure _holderData is populated
          if (mounted) setState(() => _currentStep = 2);

        case 'details':
          // Bank done — always show Occupation first (Step 3)
          _pan = panNumber;
          _phone = phoneNumber;
          _skippedPanVerification = true;
          await _fetchProfileDetails();
          if (mounted) {
            AppLogger.info('details → jumping to step 3 (Occupation)', tag: 'BseV2FinalJourney');
            setState(() => _currentStep = 3);
          }

        case 'contact_and_pan':
        case 'pan':
        default:
          // Need phone/PAN — start from Step 0 as normal
          AppLogger.info('Starting from step 0 (next_step: $nextStep)', tag: 'BseV2FinalJourney');
          setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error in _checkInvestmentReadiness: $e', tag: 'BseV2FinalJourney');
      setState(() => _isLoading = false);
      // Fall through to step 0 on any error
    }
  }

  // Refetch Profile Data (when navigating back)
  Future<void> _refetchProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.getProfileDetails();

      if (response != null && response['success'] == true) {
        AppLogger.info('Profile data refetched successfully', tag: 'BseV2FinalJourney');
        
        final data = response['data'];
        
        if (data != null) {
          setState(() {
            _holderData = {'holder': data}; // Update with fresh data
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error refetching profile', error: e, tag: 'BseV2FinalJourney');
    }
  }

  // Fetch Profile Details (for self/primary holder)
  Future<void> _fetchProfileDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _onboardingService.getProfileDetails();

      if (response != null && response['success'] == true) {
        AppLogger.info('Profile details fetched successfully', tag: 'BseV2FinalJourney');
        
        // Extract profile data
        final data = response['data'];
        
        if (data != null) {
          setState(() {
            _holderData = {'holder': data}; // Wrap in same format as holder API
            _holderId = null; // No holder ID for self
            _currentStep = 1; // Move to Step 2
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _showError('Failed to fetch profile details');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(response?['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error('Error fetching profile', error: e, tag: 'BseV2FinalJourney');
      _showError('Failed to fetch profile. Please try again.');
    }
  }

  // Step 2: Handle Address Submit
  Future<void> _handleAddressSubmit(Map<String, dynamic> address) async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic>? response;
      
      if (_holderId != null) {
        // Joint holder - update holder address
        response = await _onboardingService.updateHolder(
          holderId: _holderId!,
          address: address,
        );
      } else {
        // Self (primary holder) - update profile address and gender
        // Extract gender from address payload
        final gender = address['gender'];
        
        // Use new API format: address fields go directly in extended_profile
        response = await _onboardingService.updateProfileDetails(
          address: address,  // Service will map to extended_profile format
          gender: gender,    // Add gender
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info('Address updated successfully', tag: 'BseV2FinalJourney');
        await _routeNextStep(); // re-validate: backend may return bank, ri_address, nri_address, etc.
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

  // Step 3: Handle Bank Submit
  Future<void> _handleBankSubmit(Map<String, dynamic> bankData) async {
    try {
      // If bank was pre-verified from GET API, skip validation and proceed directly
      if (bankData['was_pre_verified'] == true) {
        AppLogger.info(
          'Bank was pre-verified - skipping API calls and proceeding to dashboard',
          tag: 'BseV2FinalJourney',
        );
        
        // Bank already verified — re-validate to get correct next step
        await _routeNextStep();
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
        AppLogger.info('Bank verified successfully', tag: 'BseV2FinalJourney');
        await _routeNextStep(); // re-validate: backend may return ri_address, nri_address, details, etc.
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

  // Step 4: Handle Occupation Details Submit
  Future<void> _handleOccupationSubmit(Map<String, dynamic> occupationData) async {
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
        AppLogger.info('Occupation details updated successfully', tag: 'BseV2FinalJourney');
        // Go directly to Signature (Step 4) — re-validating would return 'details'
        // again and loop back to Occupation since signature is still pending.
        if (mounted) setState(() => _currentStep = 4);
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

  // Step 5: Handle Signature Submit
  Future<void> _handleSignatureSubmit(String signatureBase64) async {
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
        AppLogger.info('Signature updated successfully', tag: 'BseV2FinalJourney');

        if (widget.fromPersonalizeFlow) {
          // From personalize flow — show success screen then go to MF listing
          Get.offAll(
            () => OnboardingSuccessScreen(showMfBrowse: true),
            transition: Transition.fadeIn,
          );
        } else {
          // Navigate to dashboard (existing flow)
          _navigateToDashboard();
        }
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

  /// Re-calls /profile/validate after a step completes and routes to whatever
  /// the backend says is next. This ensures no step is ever skipped or missed.
  Future<void> _routeNextStep() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse == null || validateResponse['success'] != true) {
        AppLogger.warning(
          '_routeNextStep: validate failed - staying on current step',
          tag: 'BseV2FinalJourney',
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = validateResponse['data'] as Map<String, dynamic>;
      final nextStep = data['next_step'] as String? ?? 'contact_and_pan';

      AppLogger.info(
        '_routeNextStep: next_step = $nextStep',
        tag: 'BseV2FinalJourney',
      );

      if (!mounted) return;

      switch (nextStep) {
        case 'complete':
        case 'mf_central':
        case 'financial_aggregator':
          // Profile onboarding done
          AppLogger.info(
            '_routeNextStep: profile complete ($nextStep)',
            tag: 'BseV2FinalJourney',
          );
          setState(() => _isLoading = false);
          if (widget.fromPersonalizeFlow) {
            // From personalize flow — show success screen then go to MF listing
            Get.offAll(
              () => OnboardingSuccessScreen(showMfBrowse: true),
              transition: Transition.fadeIn,
            );
          } else {
            // Existing flow — go straight to order screen
            Get.off(() => CreateOrderV1Screen(
              fundName: widget.fundName ?? '',
              isin: widget.isin ?? '',
              schemeCode: widget.schemeCode ?? '',
              nav: widget.nav,
              minAmount: widget.minAmount,
            ));
          }

        case 'address':
        case 'ri_address':
        case 'nri_address':
          _validateMode = nextStep;
          _validateContext = (data['context'] as Map<String, dynamic>?) ?? {};
          await _fetchProfileDetails(); // sets _currentStep = 1

        case 'bank':
          await _fetchProfileDetails();
          if (mounted) setState(() { _isLoading = false; _currentStep = 2; });

        case 'details':
          await _fetchProfileDetails();
          if (mounted) {
            AppLogger.info('_routeNextStep details → step 3 (Occupation)', tag: 'BseV2FinalJourney');
            setState(() { _isLoading = false; _currentStep = 3; });
          }

        case 'contact_and_pan':
        case 'pan':
        default:
          // Unexpected regression — send back to step 0
          AppLogger.warning(
            '_routeNextStep: unexpected next_step "$nextStep" — resetting to step 0',
            tag: 'BseV2FinalJourney',
          );
          setState(() { _isLoading = false; _currentStep = 0; });
      }
    } catch (e) {
      AppLogger.error('_routeNextStep error: $e', tag: 'BseV2FinalJourney');
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _navigateToDashboard() {
    AppLogger.info('BSE V2 journey complete - navigating to success screen', tag: 'BseV2FinalJourney');
    
    Get.offAll(
      () => OnboardingSuccessScreen(
        fundName: widget.fundName,
        isin: widget.isin,
        schemeCode: widget.schemeCode,
        nav: widget.nav,
        fundLogo: widget.fundLogo,
        minAmount: widget.minAmount,
        showMfBrowse: widget.showMfBrowse,
      ),
      transition: Transition.fadeIn,
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.darkPrimary,
          ),
        ),
      );
    }

    // Step navigation
    switch (_currentStep) {
      case 0:
        return UniversalPanVerificationWidget(
          phoneNumber: _phone,
          isPhoneValidated: _isPhoneValidated,
          isEmailValidated: _isEmailValidated,
          needsEmailVerification: _needsEmailVerification,
          email: _email,
          panNumber: _pan,
          onSuccess: (panData) async {
            // Extract pan + phone + email from verified data
            _pan = panData['pan_number'] as String? ?? _pan;
            _phone = panData['phone_number'] as String? ?? _phone;
            _email = panData['email'] as String? ?? _email;

            // Identify user in CleverTap
            final userId = panData['user_id']?.toString();
            if (userId != null && userId.isNotEmpty) {
              AnalyticsService.to.identifyUser(
                userId: userId,
                phoneNumber: _phone,
                name: panData['name'] as String? ?? '',
                email: _email,
              );
              AppLogger.info(
                'User identified in CleverTap from BSE V2 journey - ID: $userId, Email: $_email',
                tag: 'BseV2FinalJourney',
              );
            }

            AppLogger.info(
              'PAN verified via UniversalPanVerificationWidget — routing next step',
              tag: 'BseV2FinalJourney',
            );
            await _routeNextStep();
          },
          onError: (error) => _showError(error),
          showProgress: true,
          currentStep: 1,
          totalSteps: 5,
        );
      
      case 1:
        return HolderDetailsScreen(
          holderData: _holderData!,
          validateMode: _validateMode,
          validateContext: _validateContext,
          onNext: _handleAddressSubmit,
          onBack: () async {
            // If we skipped PAN verification, exit BSE journey
            if (_skippedPanVerification) {
              Get.back();
            } else {
              // Otherwise go back to PAN step
              setState(() {
                _currentStep = 0;
              });
            }
          },
        );
      
      case 2:
        return BankVerificationScreen(
          onNext: _handleBankSubmit,
          onBack: () async {
            // Refetch profile data before going back to address step
            await _refetchProfileData();
            setState(() {
              _currentStep = 1; // Go back to holder details (address)
            });
          },
        );
      
      case 3:
        return OccupationDetailsScreen(
          onNext: _handleOccupationSubmit,
          onBack: () async {
            setState(() {
              _currentStep = 2; // Go back to bank verification
            });
          },
        );
      
      case 4:
        return SignatureScreen(
          onNext: _handleSignatureSubmit,
          onBack: () async {
            setState(() {
              _currentStep = 3; // Go back to occupation details
            });
          },
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
