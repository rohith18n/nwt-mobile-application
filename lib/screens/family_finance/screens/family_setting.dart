import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/family_finance/family_asset_consent.dart';
import 'package:nwt_app/services/family_finance/family_member_summary.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/custom_switch.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

// Extension to add assetConsent to User model if it doesn't exist
extension UserAssetConsentExtension on dynamic {
  bool? get assetConsent => this is Map ? this['assetConsent'] : null;
  set assetConsent(bool? value) {
    if (this is Map) {
      this['assetConsent'] = value;
    }
  }

  String? get familyId => this is Map ? this['familyId'] : null;
}

class FamilySetting extends StatefulWidget {
  final String? familyId;
  final String? userGuid;
  final bool? assetConsent;

  const FamilySetting({
    super.key,
    this.familyId,
    this.userGuid,
    this.assetConsent,
  });

  @override
  State<FamilySetting> createState() => _FamilySettingState();
}

class _FamilySettingState extends State<FamilySetting> {
  final UserController _userController = Get.find<UserController>();
  final FamilyAssetConsentService _assetConsentService =
      FamilyAssetConsentService();
  final FamilyMemberSummaryService _familyMemberSummaryService =
      FamilyMemberSummaryService();

  String _familyId = '';
  String _userGuid = '';
  bool _assetConsentEnabled = false;
  bool _isInitialLoading = false;
  bool _isUpdating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // First try to use the values passed from the parent widget
    if (widget.familyId != null &&
        widget.familyId!.isNotEmpty &&
        widget.userGuid != null &&
        widget.userGuid!.isNotEmpty) {
      setState(() {
        _familyId = widget.familyId!;
        _userGuid = widget.userGuid!;

        // Use the passed assetConsent if available
        if (widget.assetConsent != null) {
          _assetConsentEnabled = widget.assetConsent!;
          AppLogger.info(
            'Family Settings: Using passed asset consent value: $_assetConsentEnabled',
            tag: 'FamilySettings',
          );
        }
      });

      // Fetch family members to get the correct asset consent status
      _fetchMemberAssetConsentStatus();

      AppLogger.info(
        'Family Settings: Using passed values - User GUID: $_userGuid, Family ID: $_familyId, Asset Consent: $_assetConsentEnabled',
        tag: 'FamilySettings',
      );
    }
    // Fallback to user controller data if needed
    else if (_userController.userData != null) {
      setState(() {
        _userGuid = _userController.userData!.guid ?? '';
        // Get family ID from user data
        _familyId = _userController.userData!.familyId ?? '';
        // Get asset consent status from user controller as fallback
        _assetConsentEnabled = _userController.userData!.assetConsent ?? false;
      });

      // Still fetch family members to ensure we have the correct data
      _fetchMemberAssetConsentStatus();

      AppLogger.info(
        'Family Settings: Using controller data - User GUID: $_userGuid, Family ID: $_familyId, Asset Consent: $_assetConsentEnabled',
        tag: 'FamilySettings',
      );
    }
  }

  Future<void> _fetchMemberAssetConsentStatus() async {
    try {
      setState(() {
        _isInitialLoading = true;
      });

      // Fetch family members
      final response = await _familyMemberSummaryService.getFamilyMembers(
        onLoading: (isLoading) {
          // We're handling loading state manually
        },
      );

      if (response.data != null && response.data!.members.isNotEmpty) {
        // Find the member with the matching userGuid
        final matchingMembers =
            response.data!.members
                .where((member) => member.userguid == _userGuid)
                .toList();

        if (matchingMembers.isNotEmpty) {
          // Found the specific member
          final member = matchingMembers.first;

          // Update the asset consent status
          setState(() {
            _assetConsentEnabled = member.assetconsent;
          });

          AppLogger.info(
            'Found member asset consent status: ${member.assetconsent} for user $_userGuid',
            tag: 'FamilySettings',
          );
        } else {
          // Member not found, use passed value or fallback to user controller data
          setState(() {
            if (widget.assetConsent != null) {
              _assetConsentEnabled = widget.assetConsent!;
            } else {
              _assetConsentEnabled =
                  _userController.userData?.assetConsent ?? false;
            }
          });

          AppLogger.info(
            'Member not found, using fallback consent value: $_assetConsentEnabled',
            tag: 'FamilySettings',
          );
        }
      } else {
        // No family members found, use passed value or fallback to user controller data
        setState(() {
          if (widget.assetConsent != null) {
            _assetConsentEnabled = widget.assetConsent!;
          } else {
            _assetConsentEnabled =
                _userController.userData?.assetConsent ?? false;
          }
        });

        AppLogger.info(
          'No family members found, using fallback consent value: $_assetConsentEnabled',
          tag: 'FamilySettings',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching member asset consent status',
        error: e,
        tag: 'FamilySettings',
        stackTrace: stackTrace,
      );

      // Fallback to passed value or user controller data on error
      setState(() {
        if (widget.assetConsent != null) {
          _assetConsentEnabled = widget.assetConsent!;
        } else {
          _assetConsentEnabled =
              _userController.userData?.assetConsent ?? false;
        }
      });
    } finally {
      // Clear loading state
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _updateAssetConsent(bool newValue) {
    if (_familyId.isEmpty || _userGuid.isEmpty) {
      setState(() {
        _errorMessage = 'Missing family ID or user GUID';
      });
      return;
    }

    // Show confirmation dialog before updating
    _showConfirmationDialog(newValue);
  }

  void _showConfirmationDialog(bool newValue) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top icon section
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      newValue ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.darkPrimary,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Confirm Asset Consent Change",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    newValue
                        ? "Are you sure you want to enable asset consent? This will allow other family members to view your asset balances."
                        : "Are you sure you want to disable asset consent? This will hide your asset balances from other family members.",
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Action buttons with divider
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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

                      // Vertical divider
                      Container(
                        height: 52,
                        width: 1,
                        color: AppColors.darkInputBorder.withOpacity(0.5),
                      ),

                      // Confirm button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Process the update
                            _processAssetConsentUpdate(newValue);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Confirm",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
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

  Future<void> _processAssetConsentUpdate(bool newValue) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = '';
    });

    final response = await _assetConsentService.updateAssetConsent(
      familyId: _familyId,
      userGuid: _userGuid,
      assetConsent: newValue,
      onLoading: (isLoading) {
        if (!mounted) return;
        setState(() {
          _isUpdating = isLoading;
        });
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        _assetConsentEnabled = newValue;
        _errorMessage = '';
      });

      // Only update the user controller if the updated user is the current user
      if (_userController.userData != null &&
          _userController.userData!.guid == _userGuid) {
        _userController.userData!.assetConsent = newValue;
        _userController.update();
      }

      AppLogger.info(
        'Asset consent updated successfully for user $_userGuid to $newValue',
        tag: 'FamilySettings',
      );
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to update asset consent';
      });

      AppLogger.error(
        'Failed to update asset consent',
        error: response.message,
        tag: 'FamilySettings',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left, size: 32),
              ),
              AppText(
                "Settings",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
              const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
            ],
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(strokeCap: StrokeCap.round),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Settings",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: AnimatedErrorMessage(errorMessage: _errorMessage),
                ),

              // No separate loading indicator needed
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.darkButtonBorder),
                ),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.darkPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        "Show your Individual assets balance to other members",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.primary,
                      ),
                    ),
                    CustomSwitch(
                      value: _assetConsentEnabled,
                      onChanged: _updateAssetConsent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.darkButtonBorder),
                ),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.darkTextMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        "The head member can view all your asset balances.",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
