import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/pan_verification_screen.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/holder_management.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/bank_management.dart';
// import 'package:nwt_app/screens/bse_star_v2/widgets/address_management.dart'; // Merged with HolderManagement
import 'package:nwt_app/screens/bse_star_v2/widgets/secondary_holder_management.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/nominee_management.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/signature_management.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/secondary_signature_management.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/otp_verification_management.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/document_upload_management.dart';
// import 'package:nwt_app/screens/bse_star_v2/widgets/fatca_management.dart'; // Not required
import 'package:nwt_app/screens/bse_star/types/tax_status.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/bse_onboarding.dart'
    hide BseOnboardingResponse;
import 'package:nwt_app/services/bse_star_v2/ucc_management/submission_service.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_submission.dart';
import 'package:nwt_app/screens/bse_star_v2/widgets/submission_status_screen.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/bse_onboarding_details_service.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class BSEStartjourney extends StatefulWidget {
  const BSEStartjourney({super.key, this.onBack, this.initialStatus});
  final VoidCallback? onBack;
  final String? initialStatus;

  @override
  State<BSEStartjourney> createState() => _BSEStartjourneyState();
}

class _BSEStartjourneyState extends State<BSEStartjourney> {
  int currentScreenIndex = 0;
  final int totalSteps = 7; // Bank, Personal Info, Secondary Holder, Nominee, Signature, OTP, Submission
  bool _isSubmitting = false;
  bool _showPanVerification = true; // Show PAN verification first
  bool _isPanVerified = false;
  bool _hasSecondaryHolder = false; // Track if secondary holder exists

  // Submission state
  bool _isFinalSubmitting = false;
  BseSubmissionResponse? _submissionResponse;
  String? _submissionError;
  BseOnboardingResponse? _onboardingDetails;

  // Controllers for form fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Bank controllers
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountHolderNameController =
      TextEditingController();
  final TextEditingController bankPhoneController = TextEditingController();

  // Address controllers
  final TextEditingController line1Controller = TextEditingController();
  final TextEditingController line2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  // State variables
  String selectedGender = 'M';
  String selectedMaritalStatus = 'S';
  TaxStatus? selectedTaxStatus;

  // Bank state variables
  String selectedAccountType = 'NRE';
  bool setAsPrimary = true;

  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _initJourney();
  }

  Future<void> _checkForSecondaryHolder() async {
    try {
      final profileResponse = await ProfileService().getProfileDetails();
      if (profileResponse != null && profileResponse.success) {
        final ucc = profileResponse.data?.uccProfile;
        if (ucc != null) {
          final hasSecondary = ucc['secondary_first_name'] != null && 
                              ucc['secondary_first_name'].toString().isNotEmpty;
          if (mounted) {
            setState(() {
              _hasSecondaryHolder = hasSecondary;
            });
          }
          AppLogger.info(
            'Secondary holder check: $_hasSecondaryHolder',
            tag: 'BSEStartjourney',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error checking for secondary holder: $e', tag: 'BSEStartjourney');
    }
  }

  /// Determines the appropriate screen index based on completed onboarding data
  int _determineStartingScreenIndex(BseOnboardingResponse? details) {
    // If v1 initialStatus is provided, use it as the primary hint
    if (widget.initialStatus != null) {
      switch (widget.initialStatus) {
        case 'bank':
          return 0; // Bank Account is first
        case 'profile':
          return 1; // Personal Information (Holders)
        case 'ucc':
          return 4; // Nominee (UCC Flow)
      }
    }

    if (details == null || details.data == null) {
      return 0;
    }

    final data = details.data!;
    final onboardingStatus = data.onboarding.status;

    // 1. Check Bank (Index 0)
    final bank = data.banks.isNotEmpty ? data.banks.first : null;
    bool hasBankInfo =
        onboardingStatus == 'BANK_ADDED' ||
        onboardingStatus == 'NOMINEE_ADDED' ||
        (bank != null && (bank.bankName?.isNotEmpty ?? false));
    if (!hasBankInfo) {
      debugPrint('Starting at index 0 (Bank)');
      return 0;
    }

    // 2. Check Holder (Index 1)
    final holders = data.holders;
    final hasHolders = holders.isNotEmpty;
    final holder = hasHolders ? holders.first.holder : null;
    bool hasHolderInfo =
        onboardingStatus == 'PRIMARY_HOLDER_ADDED' ||
        onboardingStatus == 'ADDRESS_ADDED' ||
        onboardingStatus == 'FATCA_ADDED' ||
        onboardingStatus == 'NOMINEE_ADDED' ||
        (holder != null && (holder.firstName?.isNotEmpty ?? false));
    if (!hasHolderInfo) {
      debugPrint('Starting at index 1 (Personal Info)');
      return 1;
    }

    // 3. Check Address (Index 2)
    final addresses = hasHolders ? holders.first.addresses : [];
    bool hasAddressInfo =
        onboardingStatus == 'ADDRESS_ADDED' ||
        onboardingStatus == 'FATCA_ADDED' ||
        onboardingStatus == 'NOMINEE_ADDED' ||
        addresses.isNotEmpty;
    if (!hasAddressInfo) {
      debugPrint('Starting at index 2 (Address)');
      return 2;
    }

    // 4. Check FATCA (Index 3)
    final personalDetails = hasHolders ? holders.first.personalDetails : null;
    bool hasFatcaInfo =
        onboardingStatus == 'FATCA_ADDED' ||
        onboardingStatus == 'NOMINEE_ADDED' ||
        (personalDetails != null &&
            (personalDetails.occupationCode?.isNotEmpty ?? false));
    if (!hasFatcaInfo) {
      debugPrint('Starting at index 3 (FATCA)');
      return 3;
    }

    // 5. Check Nominee (Index 4)
    bool hasNomineeInfo =
        onboardingStatus == 'NOMINEE_ADDED' ||
        !data.onboarding.isNomineeOpted ||
        (data.nominees.isNotEmpty &&
            (data.nominees.first.name?.isNotEmpty ?? false));
    if (!hasNomineeInfo) {
      debugPrint('Starting at index 4 (Nominee)');
      return 4;
    }

    // 6. Else Signature (Index 5)
    debugPrint('Starting at index 5 (Signature)');
    return 5;
  }

  Future<void> _initJourney() async {
    // Set initial screen based on status immediately
    if (mounted) {
      setState(() {
        currentScreenIndex = _determineStartingScreenIndex(null);
      });
    }

    try {
      final response = await BseOnboardingService.createOnboarding();
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          response.data?.id != null) {
        final onboardingId = response.data!.id;
        // After creating/verifying onboarding, fetch full details for pre-filling
        final detailsResponse =
            await BseOnboardingDetailsService.getOnboardingDetails(
              onboardingId: onboardingId,
            );
        if (mounted) {
          setState(() {
            _onboardingDetails = detailsResponse;
            // Update currentScreenIndex based on available data
            currentScreenIndex = _determineStartingScreenIndex(detailsResponse);
          });

          // Ensure IDs are persisted for child widgets to use
          if (onboardingId.isNotEmpty) {
            await SecureStorage.write('bse_onboarding_id', onboardingId);
          }
          if (detailsResponse?.data?.holders.isNotEmpty == true) {
            final holderId = detailsResponse!.data!.holders.first.holder.id;
            await SecureStorage.write('primary_holder_id', holderId);
          }
        }
      }
    } catch (e) {
      // Fail silently to avoid blocking the V1 journey screens
      AppLogger.error(
        'Silent failure during BSE journey initialization: $e',
        tag: 'BSEStartjourney',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  // Submission Logic
  Future<void> _submitToBse() async {
    setState(() {
      _isFinalSubmitting = true;
      _submissionError = null;
    });

    try {
      final response = await SubmissionService.submitOnboarding();
      if (mounted) {
        setState(() {
          _isFinalSubmitting = false;
          // Store the response if we got one, regardless of internal status
          if (response != null) {
            _submissionResponse = response;
          }

          if (response != null &&
              response.data?.bseResponse?.status == 'success') {
            // Save client code to secure storage on success
            final clientCode = response.data?.bseResponse?.data?.clientCode;
            if (clientCode != null && clientCode.isNotEmpty) {
              SecureStorage.write('UCC_CLIENT_CODE', clientCode);
            }
          } else {
            String errorMessage =
                response?.message ?? 'Submission failed. Please try again.';
            if (response?.data?.bseResponse?.messages != null &&
                response!.data!.bseResponse!.messages!.isNotEmpty) {
              errorMessage = response.data!.bseResponse!.messages!
                  .map((m) => m.formattedMessage)
                  .join('\n');
            }
            _submissionError = errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFinalSubmitting = false;
          _submissionError = 'An unexpected error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Show PAN verification screen first
    if (_showPanVerification) {
      return PanVerificationScreen(
        onVerified: () {
          setState(() {
            _showPanVerification = false;
            _isPanVerified = true;
          });
        },
        onSkip: () {
          setState(() {
            _showPanVerification = false;
          });
        },
        onBack: widget.onBack,
      );
    }

    return PopScope(
      canPop: false, // Always handle pop manually to support onBack callback
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _handleBack,
                child: const Icon(
                  Icons.chevron_left,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              AppText(
                _getScreenTitle(),
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
                customColor: Colors.white,
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(color: Colors.black, child: _buildProgressBar()),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: _buildCurrentScreen(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            _shouldShowNextButton()
                ? SafeArea(child: _buildNextButton())
                : null,
      ),
    );
  }

  void _handleBack() async {
    if (currentScreenIndex > 0) {
      // Re-fetch data first to show updated state immediately when switching back
      await _refreshOnboardingDetails();

      if (mounted) {
        setState(() {
          currentScreenIndex--;
        });
      }
    } else {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refreshOnboardingDetails() async {
    final onboardingId = await SecureStorage.read('bse_onboarding_id');
    if (onboardingId != null && onboardingId.isNotEmpty) {
      final detailsResponse =
          await BseOnboardingDetailsService.getOnboardingDetails(
            onboardingId: onboardingId,
          );
      if (mounted) {
        setState(() {
          _onboardingDetails = detailsResponse;
        });
      }
    }
  }

  Future<void> _showResetJourneyDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: AppText(
          'Reset Onboarding',
          variant: AppTextVariant.headline6,
          customColor: Colors.white,
        ),
        content: AppText(
          'Are you sure you want to reset your complete onboarding journey? This will delete all entered information.',
          variant: AppTextVariant.bodyMedium,
          customColor: Colors.grey,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: AppText(
              'Cancel',
              variant: AppTextVariant.bodyMedium,
              customColor: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: AppText(
              'Reset',
              variant: AppTextVariant.bodyMedium,
              customColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _resetJourneyFunc();
    }
  }

  Future<void> _resetJourneyFunc() async {
    final onboardingId = await SecureStorage.read('bse_onboarding_id');
    if (onboardingId == null || onboardingId.isEmpty) return;

    setState(() {
      _isInitLoading = true;
    });

    try {
      final success = await BseOnboardingService.deleteOnboarding(onboardingId);
      if (success) {
        // Clear stored IDs
        await SecureStorage.write('bse_onboarding_id', '');
        await SecureStorage.write('primary_holder_id', '');

        // Restart journey
        _initJourney();
      } else {
        Get.snackbar(
          'Error',
          'Failed to reset onboarding journey. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  String _getScreenTitle() {
    switch (currentScreenIndex) {
      case 0:
        return 'Bank Account';
      case 1:
        return 'Personal Information';
      case 2:
        return 'Secondary Holder';
      case 3:
        return 'Nominee Details';
      case 4:
        return 'Primary Signature';
      case 5:
        return _hasSecondaryHolder ? 'Secondary Signature' : 'OTP Verification';
      case 6:
        return _hasSecondaryHolder ? 'OTP Verification' : 'Submission';
      case 7:
        return 'Submission';
      default:
        return 'BSE Star Journey';
    }
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (currentScreenIndex + 1) / totalSteps,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentScreenIndex) {
      case 0:
        return BankManagement(
          key: const ValueKey('bank_management'),
          taxStatus:
              _onboardingDetails?.data?.holders.isNotEmpty == true
                  ? _onboardingDetails!.data!.holders.first.holder.taxStatus
                  : null,
          initialData: _onboardingDetails?.data?.banks,
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            await _refreshOnboardingDetails();
            setState(() {
              _isSubmitting = false;
              currentScreenIndex++;
            });
          },
        );
      case 1:
        return HolderManagement(
          key: const ValueKey('holder_management'),
          initialData:
              _onboardingDetails?.data?.holders.isNotEmpty == true
                  ? _onboardingDetails!.data!.holders.first
                  : null,
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            await _refreshOnboardingDetails();
            setState(() {
              _isSubmitting = false;
              currentScreenIndex++;
            });
          },
        );
      // case 2:
      //   // Address Management is now merged with Personal Information (HolderManagement)
      //   return AddressManagement(
      //     key: const ValueKey('address_management'),
      //     taxStatus:
      //         _onboardingDetails?.data?.holders.isNotEmpty == true
      //             ? _onboardingDetails!.data!.holders.first.holder.taxStatus
      //             : null,
      //     initialData:
      //         _onboardingDetails?.data?.holders.isNotEmpty == true
      //             ? _onboardingDetails!.data!.holders.first.addresses
      //             : null,
      //     shouldSubmit: _isSubmitting,
      //     onError: () => setState(() => _isSubmitting = false),
      //     onNext: () async {
      //       await _refreshOnboardingDetails();
      //       setState(() {
      //         _isSubmitting = false;
      //         currentScreenIndex++;
      //       });
      //     },
      //   );
      // case 2:
      //   // Additional Details (FATCA Management) is not required
      //   return FatcaManagement(
      //     key: const ValueKey('fatca_management'),
      //     initialData:
      //         _onboardingDetails?.data?.holders.isNotEmpty == true
      //             ? _onboardingDetails!.data!.holders.first.personalDetails
      //             : null,
      //     taxStatus:
      //         _onboardingDetails?.data?.holders.isNotEmpty == true
      //             ? _onboardingDetails!.data!.holders.first.holder.taxStatus
      //             : null,
      //     shouldSubmit: _isSubmitting,
      //     onError: () => setState(() => _isSubmitting = false),
      //     onNext: () async {
      //       await _refreshOnboardingDetails();
      //       setState(() {
      //         _isSubmitting = false;
      //         currentScreenIndex++;
      //       });
      //     },
      //   );
      case 2:
        return SecondaryHolderManagement(
          key: const ValueKey('secondary_holder_management'),
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            await _refreshOnboardingDetails();
            setState(() {
              _isSubmitting = false;
              currentScreenIndex++;
            });
          },
          onSkip: () async {
            await _refreshOnboardingDetails();
            setState(() {
              currentScreenIndex++;
            });
          },
        );
      case 3:
        // Log nominee data for debugging
        AppLogger.info(
          'Building Nominee screen - Nominees count: ${_onboardingDetails?.data?.nominees?.length ?? 0}',
          tag: 'BSEStartjourney',
        );
        if (_onboardingDetails?.data?.nominees != null) {
          AppLogger.info(
            'Nominee data: ${_onboardingDetails!.data!.nominees.map((n) => n.name).toList()}',
            tag: 'BSEStartjourney',
          );
        }
        
        return NomineeManagement(
          key: const ValueKey('nominee_management'),
          initialData: _onboardingDetails?.data?.nominees,
          primaryHolderAddress:
              _onboardingDetails?.data?.holders.isNotEmpty == true &&
                      _onboardingDetails!
                              .data!
                              .holders
                              .first
                              .addresses
                              .isNotEmpty ==
                          true
                  ? _onboardingDetails!.data!.holders.first.addresses.first
                  : null,
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            await _refreshOnboardingDetails();
            setState(() {
              _isSubmitting = false;
              currentScreenIndex++;
            });
          },
        );
      case 4:
        return SignatureManagement(
          key: const ValueKey('signature_management'),
          existingDocuments: _onboardingDetails?.data?.documents,
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            AppLogger.info('Primary signature onNext called', tag: 'BSEStartjourney');
            await _refreshOnboardingDetails();
            
            // Check if secondary holder exists
            await _checkForSecondaryHolder();
            
            setState(() {
              _isSubmitting = false;
              currentScreenIndex++;
            });
            AppLogger.info('Primary signature complete, has secondary: $_hasSecondaryHolder', tag: 'BSEStartjourney');
          },
        );
      case 5:
        // Show secondary signature if secondary holder exists, otherwise show OTP
        return _hasSecondaryHolder
            ? SecondarySignatureManagement(
                key: const ValueKey('secondary_signature_management'),
                shouldSubmit: _isSubmitting,
                onError: () => setState(() => _isSubmitting = false),
                onNext: () async {
                  AppLogger.info('Secondary signature onNext called', tag: 'BSEStartjourney');
                  await _refreshOnboardingDetails();
                  setState(() {
                    _isSubmitting = false;
                    currentScreenIndex++;
                  });
                  AppLogger.info('Secondary signature complete', tag: 'BSEStartjourney');
                },
              )
            : OTPVerificationManagement(
          key: const ValueKey('otp_verification_management'),
          shouldSubmit: _isSubmitting,
          onError: () => setState(() => _isSubmitting = false),
          onNext: () async {
            // UCC creation is complete after OTP verification
            // Navigate to success screen
            AppLogger.info(
              'OTP verification complete, navigating to success screen',
              tag: 'BSEStartjourney',
            );
            
            if (mounted) {
              // Get client code from storage
              final clientCodesStr = await SecureStorage.read('ucc_client_codes');
              String clientCode = 'N/A';
              if (clientCodesStr != null && clientCodesStr.isNotEmpty) {
                try {
                  final codes = jsonDecode(clientCodesStr) as List;
                  if (codes.isNotEmpty) {
                    clientCode = codes.first;
                  }
                } catch (e) {
                  AppLogger.error('Error parsing client codes', error: e, tag: 'BSEStartjourney');
                }
              }
              
              // Create a success response for the success screen
              final successResponse = BseSubmissionResponse(
                message: 'Account created successfully!',
                data: SubmissionData(
                  bseResponse: BseResponse(
                    status: 'success',
                    data: BseResponseData(clientCode: clientCode),
                  ),
                ),
              );
              
              setState(() {
                _isSubmitting = false;
                _submissionResponse = successResponse;
                currentScreenIndex = 6; // Move to submission success screen
              });
            }
          },
        );
      case 6:
        return SubmissionStatusScreen(
          isSubmitting: _isFinalSubmitting,
          submissionResponse: _submissionResponse,
          submissionError: _submissionError,
          onRetry: _submitToBse,
          onRestart: _resetJourneyFunc,
          onDone: () {
            Get.offAll(() => StackedNavbar(selectedIdx: 0));
          },
        );
      default:
        return const Center(
          child: Text(
            'Screen coming soon...',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildNextButton() {
    // Show Skip button for Secondary Holder screen (index 2)
    final bool showSkipButton = currentScreenIndex == 2;
    
    return Container(
      color: Colors.black, // Match Scaffold background
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: showSkipButton
          ? Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      // Skip secondary holder
                      setState(() {
                        currentScreenIndex++;
                      });
                    },
                    text: 'Skip',
                    isFullWidth: true,
                    variant: AppButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    onPressed: _handleNext,
                    text: 'Next',
                    isLoading: _isSubmitting,
                    isFullWidth: true,
                  ),
                ),
              ],
            )
          : AppButton(
              onPressed: _handleNext,
              text: 'Next',
              isLoading: _isSubmitting,
              isFullWidth: true,
            ),
    );
  }

  bool _shouldShowNextButton() {
    return currentScreenIndex < totalSteps - 1;
  }

  void _handleNext() {
    debugPrint('Current screen index: $currentScreenIndex');
    debugPrint('Is submitting: $_isSubmitting');

    if (currentScreenIndex == 0 ||
        currentScreenIndex == 1 ||
        currentScreenIndex == 2 ||
        currentScreenIndex == 3 ||
        currentScreenIndex == 4 ||
        currentScreenIndex == 5) {
      // For all screens that need submission (including OTP verification)
      debugPrint('Triggering submission for screen $currentScreenIndex');
      // First reset to false to ensure state change is detected
      setState(() {
        _isSubmitting = false;
      });
      // Then set to true in next frame to trigger didUpdateWidget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isSubmitting = true;
          });
        }
      });
      debugPrint('Set _isSubmitting to true');
    } else if (currentScreenIndex < totalSteps - 1) {
      setState(() {
        currentScreenIndex++;
      });
    }
  }
}
