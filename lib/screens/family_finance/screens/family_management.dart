import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/family_finance/screens/family_member.dart';
import 'package:nwt_app/screens/family_finance/screens/family_member_add.dart';
import 'package:nwt_app/screens/family_finance/screens/family_setting.dart';
import 'package:nwt_app/screens/family_finance/types/family_management_summary.dart';
import 'package:nwt_app/screens/family_finance/types/family_member_summary.dart';
import 'package:nwt_app/screens/family_finance/widgets/family_member_card.dart';
import 'package:nwt_app/services/family_finance/family_delete.dart';
import 'package:nwt_app/services/family_finance/family_head_member_summary.dart';
import 'package:nwt_app/services/family_finance/family_leave.dart';
import 'package:nwt_app/services/family_finance/family_member_add.dart';
import 'package:nwt_app/services/family_finance/family_member_remove.dart';
import 'package:nwt_app/services/family_finance/family_member_summary.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class FamilyManagement extends StatefulWidget {
  const FamilyManagement({super.key});
  @override
  State<FamilyManagement> createState() => _FamilyManagementState();
}

class _FamilyManagementState extends State<FamilyManagement> {
  bool isLoading = true;
  bool _isAmountVisible = true;
  FamilyManagementSummaryResponse? familyHeadMemberSummaryResponse;
  FamilyMemberSummaryResponse? familyMemberSummaryResponse;
  double _networthAmount = 0;
  String _lastName = '';
  String _lastFetchedTime = '';
  String _headMemberName = '';
  String _headMemberGender = '';
  String _headMemberId = '';
  bool _isHeadMember = false;
  bool _isFamilyMemberAndHead = false;
  bool _isFamilyJoined = false;
  String relationid = '';
  String phoneNumber = '';
  String familyId = '';
  String expiresAt = DateTime.now().toIso8601String();
  String invitedAt = DateTime.now().toIso8601String();
  List<Member> _familyMembers = [];
  final familyHeadMemberSummaryService = FamilyHeadMemberSummaryService();
  final familyMemberSummaryService = FamilyMemberSummaryService();
  final familyMemberRemoveService = FamilyMemberRemoveService();
  final familyMemberAddService = FamilyMemberAddService();
  final familyDeleteService = FamilyDeleteService();
  final familyLeaveService = FamilyLeaveService();
  bool _isRemovingMember = false;
  bool _isResendingInvite = false;
  bool _isDeletingFamily = false;
  bool _isLeavingFamily = false;
  String? _errorMessage;
  final bool _isAssetConsentGiven = false;
  final UserController _userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    init();
  }

  // Show confirmation dialog before deleting family
  void _showDeleteFamilyConfirmation() {
    showDialog(
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
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Delete Family",
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
                    "Are you sure you want to delete your family? This action cannot be undone and will remove all family members.",
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

                      // Delete button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Execute the deletion
                            _deleteFamily();
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

  // Method to handle family deletion
  Future<void> _deleteFamily() async {
    if (_headMemberId.isEmpty || familyId.isEmpty) {
      setState(() {
        _errorMessage = 'Missing required information to delete family';
      });
      return;
    }

    final response = await familyDeleteService.deleteFamily(
      headMemberUserGuid: _headMemberId,
      familyId: familyId,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isDeletingFamily = isLoading;
          });
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info(
        'Delete Family Response: Success',
        tag: 'FamilyManagement',
      );

      // Clear family mode storage key to switch back to individual dashboard
      StorageService.remove(StorageKeys.FAMILY_MODE_KEY);
      AppLogger.info(
        'Cleared family mode storage key after family deletion',
        tag: 'FamilyManagement',
      );

      // Navigate back to previous screen after successful deletion
      if (mounted) {
        Navigator.pop(context);
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = response.message;
        });
      }
    }
  }

  // Show confirmation dialog before leaving family
  void _showLeaveFamilyConfirmation() {
    showDialog(
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
                      color: AppColors.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.warning,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Leave Family",
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
                    "Are you sure you want to leave this family? You will no longer have access to family financial data.",
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

                      // Leave button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Execute the leave callback
                            _leaveFamily();
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
                            "Leave",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.warning,
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

  // Method to handle family leave
  Future<void> _leaveFamily() async {
    if (_userController.userData?.guid == null || familyId.isEmpty) {
      setState(() {
        _errorMessage = 'Missing required information to leave family';
      });
      return;
    }

    final response = await familyLeaveService.leaveFamily(
      userGuid: _userController.userData!.guid!,
      familyId: familyId,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLeavingFamily = isLoading;
          });
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info('Leave Family Response: Success', tag: 'FamilyManagement');
      // Clear family mode storage key to switch back to individual dashboard
      StorageService.remove(StorageKeys.FAMILY_MODE_KEY);

      // Navigate back to previous screen after successful leave
      if (mounted) {
        Navigator.pop(context);
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = response.message;
        });
      }
    }
  }

  // Show confirmation dialog before removing member
  void _showRemoveConfirmation(Member member) {
    // Use the styled confirmation dialog from the service
    familyMemberRemoveService.showStyledRemoveConfirmation(
      context: context,
      memberName: "${member.firstname} ${member.lastname}",
      onConfirm: () => _removeMember(member),
    );
  }

  // Method to resend invitation to a family member
  Future<void> _resendInvitation(Member member) async {
    if (_isResendingInvite) return; // Prevent multiple calls

    setState(() {
      _isResendingInvite = true;
      _errorMessage = null;
    });

    try {
      // Use the updated service that handles Branch link creation internally
      final response = await familyMemberAddService.inviteFamilyMember(
        familyLastName: _lastName,
        firstName: member.firstname,
        lastName: member.lastname,
        mobileNumber: member.phonenumber,
        relation: member.relation,
        shouldCreateShareLink:
            true, // Enable automatic link creation and sharing
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              // We're handling loading state separately
            });
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info(
          'Resend Invitation Response: Success',
          tag: 'FamilyManagement',
        );

        // Small delay to ensure share dialog appears before refreshing
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the family members list after sharing is complete
        if (mounted) {
          init();
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error resending invitation',
        error: e,
        tag: 'FamilyManagement',
      );

      setState(() {
        _errorMessage = 'Failed to resend invitation: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isResendingInvite = false;
      });
    }
  }

  // Method to handle member removal
  Future<void> _removeMember(Member member) async {
    if (member.userguid.isEmpty) {
      setState(() {
        _errorMessage = 'User ID is missing';
      });
      return;
    }

    final response = await familyMemberRemoveService.removeFamilyMember(
      targetUserGuid: member.userguid,
      familyId: member.familyid,
      familyHeadUserGuid: _headMemberId,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isRemovingMember = isLoading;
          });
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info(
        'Remove Family Member Response: Success',
        tag: 'FamilyManagement',
      );

      // Refresh the family members list
      init();
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = response.message;
        });
      }
    }
  }

  Future<void> init() async {
    // Set loading state to true at the beginning
    setState(() {
      isLoading = true;
    });

    // Step 1: Fetch user profile first
    await _userController.fetchUserProfile(
      onLoading: (_) {}, // Handle loading state manually
    );

    if (!mounted) return;

    // Step 2: Determine if user is part of a family
    _isFamilyJoined =
        _userController.userData?.isfamily != null &&
        _userController.userData?.isfamily == true;

    try {
      if (_isFamilyJoined) {
        // Step 3a: User is part of a family, fetch family members
        final response = await familyMemberSummaryService.getFamilyMembers(
          onLoading: (_) {}, // Handle loading state manually
        );

        if (!mounted) return;

        familyMemberSummaryResponse = response;
        AppLogger.info(
          'Family Member Summary Response MANAGEMENT: ${response.data?.toJson()}',
          tag: 'FamilyMemberSummaryService',
        );

        if (response.data != null) {
          // Access family data from the correct path in the response
          _networthAmount = response.data!.family.totalsum;
          _lastName = response.data!.family.lastname;
          // Handle lastfetch with proper empty string checks
          final lastFetchString = response.data!.family.lastfetch;
          if (lastFetchString.isNotEmpty) {
            try {
              _lastFetchedTime = DateFormatter.formatToDateTimeWithAmPm(
                DateTime.parse(lastFetchString),
              );
            } catch (e) {
              AppLogger.warning(
                'Failed to parse lastfetch date: $lastFetchString',
                tag: 'FamilyManagement',
              );
              _lastFetchedTime = DateFormatter.formatToDateTimeWithAmPm(
                DateTime.now(),
              );
            }
          } else {
            _lastFetchedTime = DateFormatter.formatToDateTimeWithAmPm(
              DateTime.now(),
            );
          }

          // Find the head member from the members list
          if (response.data!.members.isNotEmpty) {
            // Sort members to ensure head member (Creator) is always at the top
            AppLogger.info(
              'Family Member Summary Response MANAGEMENT: ${response.data?.toJson()}',
              tag: 'FamilyMemberSummaryService',
            );
            final sortedMembers = List<Member>.from(response.data!.members);
            sortedMembers.sort((a, b) {
              // Creator should be first
              if (a.relation == 'Creator') return -1;
              if (b.relation == 'Creator') return 1;
              return 0;
            });

            // Store all family members for display
            _familyMembers = sortedMembers;

            // Find the head member from the members list
            final headMember = response.data!.members.firstWhere(
              (member) => member.relation == 'Creator',
              orElse: () => response.data!.members.first,
            );

            _headMemberName = headMember.firstname;
            _headMemberGender = headMember.gender ?? '';
            _isHeadMember = headMember.relation == 'Creator';
            _headMemberId = headMember.userguid;
            phoneNumber = headMember.phonenumber;
            _isFamilyMemberAndHead =
                _userController.userData?.isfamily == true &&
                _userController.userData?.guid != null &&
                _userController.userData?.guid == _headMemberId;
            familyId = headMember.familyid;
          }
        }

        AppLogger.info(
          'Get Family Members Response: ${response.data}',
          tag: 'FamilyMemberSummaryService',
        );
      } else {
        // Step 3b: User is not part of a family, fetch family head member summary
        final response = await familyHeadMemberSummaryService
            .getFamilyHeadMemberSummary(
              onLoading: (_) {}, // Handle loading state manually
            );

        if (!mounted) return;

        familyHeadMemberSummaryResponse = response;
        AppLogger.info(
          'Family Head Member Summary Response management: ${response.data?.toJson()}',
          tag: 'FamilyMemberSummaryService',
        );

        _networthAmount = response.data?.totalsum ?? 0;
        _lastName = response.data?.lastname ?? '';
        _lastFetchedTime =
            response.data?.lastfetch != ""
                ? DateFormatter.formatToDateTimeWithAmPm(
                  DateTime.parse(
                    response.data?.lastfetch ??
                        DateTime.now().toIso8601String(),
                  ),
                )
                : DateFormatter.formatToDateTimeWithAmPm(DateTime.now());
        _headMemberName = response.data?.firstname ?? '';
        _headMemberGender = response.data?.gender ?? '';
        _isHeadMember = response.data?.relation == 'Creator';
        _headMemberId = response.data?.guid ?? '';
        phoneNumber = response.data?.phonenumber ?? '';
        _isFamilyMemberAndHead =
            _userController.userData?.isfamily == true &&
            _userController.userData?.guid != null &&
            _userController.userData?.guid == _headMemberId;
        relationid = response.data?.relationid ?? '';

        AppLogger.info(
          'Get Family Head Member Summary Response: ${response.data}',
          tag: 'FamilyHeadMemberSummaryService',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading family data',
        error: e,
        tag: 'FamilyManagement',
        stackTrace: stackTrace,
      );
    } finally {
      // Step 4: Set loading to false when all operations are complete
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.to(
                      () => StackedNavbar(selectedIdx: 0),
                      transition: Transition.rightToLeft,
                    ),
                child: const Icon(Icons.chevron_left, size: 32),
              ),
              AppText(
                "Family Managements",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
              const SizedBox(width: 20),
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
              onTap: () => Get.to(
                    () => StackedNavbar(selectedIdx: 0),
                    transition: Transition.rightToLeft,
                  ),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Family Management",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            (_isFamilyJoined)
                ? GestureDetector(
                  onTap:
                      () => Get.to(
                        () => FamilySetting(
                          familyId: familyId,
                          userGuid: _userController.userData?.guid ?? '',
                          assetConsent: _isAssetConsentGiven,
                        ),
                      ),
                  child: const Icon(Icons.settings_outlined, size: 20),
                )
                : const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            init();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              spacing: 12,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "$_lastName's Networth",
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.secondary,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedAmount(
                                isLoading: isLoading,
                                amount: CurrencyFormatter.formatRupee(
                                  _networthAmount,
                                ),
                                isAmountVisible: _isAmountVisible,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAmountVisible = !_isAmountVisible;
                                      });
                                    },
                                    child: Icon(
                                      _isAmountVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color:
                                          AppColors.darkButtonPrimaryBackground,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ],
                          ),
                          AppText(
                            _lastFetchedTime,
                            variant: AppTextVariant.tiny,
                            weight: AppTextWeight.semiBold,
                            colorType: AppTextColorType.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Display all family members if available
                if (_familyMembers.isNotEmpty)
                  ..._familyMembers.map((member) {
                    final isCreator = member.relation == 'Creator';
                    return FamilyMemberCard(
                      name: "${member.firstname} ${member.lastname}",
                      gender: member.gender?.toLowerCase(),
                      isHeadMember: isCreator,
                      status: member.status,
                      message:
                          member.status == 'Invited' &&
                                  DateTime.now().isAfter(
                                    DateTime.tryParse(member.expiresat ?? '') ??
                                        DateTime.now(),
                                  )
                              ? "You can resend the invite now!"
                              : null,
                      // Pass the necessary parameters for editing
                      userGuid: member.userguid,
                      firstName: member.firstname,
                      lastName: member.lastname,
                      phoneNumber:
                          member.userguid, // Using userguid as phone number
                      relationId:
                          member.relationid, // Using familyuserid as relationId
                      relationName: member.relation,
                      invitedAt: member.invitedat,
                      expiresAt: member.expiresat,
                      onTap: () {
                        // Check if this is the Creator and if the current user is also the Creator
                        final isCurrentUserCreator =
                            _userController.userData?.guid == _headMemberId;
                        final isThisMemberCreator =
                            member.relation == 'Creator';

                        // Only navigate if this is not the Creator's own card
                        if (!(isCurrentUserCreator && isThisMemberCreator)) {
                          Get.to(
                            () => FamilyMember(
                              firstName: member.firstname,
                              lastName: member.lastname,
                              relation: member.relation,
                              networth: member.networth,
                              gender: member.gender,
                              userGuid: member.userguid,
                              relationId: member.relationid, // Using relationid
                              phoneNumber: member.phonenumber,
                              familyId: member.familyid,
                              familyHeadUserGuid: _headMemberId,
                            ),
                          );
                        } else {
                          // Optionally show a message that Creator can't view their own details
                          AppLogger.info(
                            'Creator attempted to view their own details',
                            tag: 'FamilyManagement',
                          );
                        }
                      },

                      onActionTap:
                          member.status == 'Invited'
                              ? () {
                                // Handle resend action
                                AppLogger.info(
                                  'Resend invite tapped for ${member.firstname}',
                                  tag: 'FamilyManagement',
                                );
                                // Show confirmation dialog before resending
                                familyMemberRemoveService
                                    .showStyledResendConfirmation(
                                      context: context,
                                      memberName:
                                          "${member.firstname} ${member.lastname}",
                                      onConfirm:
                                          () => _resendInvitation(member),
                                    );
                              }
                              : null,
                      onCancelTap:
                          member.status == 'Invited'
                              ? () {
                                // Don't allow cancel action if already removing a member
                                if (_isRemovingMember) return;
                                _showRemoveConfirmation(member);
                              }
                              : null,
                    );
                  })
                else
                  FamilyMemberCard(
                    name: _headMemberName,
                    gender: _headMemberGender,
                    isHeadMember: _isHeadMember,
                    status: "Accepted",
                    userGuid: _headMemberId,
                    onTap: () {
                      // Check if this is the Creator and if the current user is also the Creator
                      final isCurrentUserCreator =
                          _userController.userData?.guid == _headMemberId;

                      // Only navigate if this is not the Creator's own card or the user is not the Creator
                      if (!isCurrentUserCreator || !_isHeadMember) {
                        Get.to(
                          () => FamilyMember(
                            firstName: _headMemberName,
                            lastName: _lastName,
                            relation: _isHeadMember ? "Creator" : "Member",
                            phoneNumber: phoneNumber,
                            userGuid: _headMemberId,
                            relationId: relationid,
                            networth: _networthAmount,
                            gender: _headMemberGender,
                            familyId: familyId,
                            familyHeadUserGuid: _headMemberId,
                          ),
                        );
                      } else {
                        // Optionally show a message that Creator can't view their own details
                        AppLogger.info(
                          'Creator attempted to view their own details',
                          tag: 'FamilyManagement',
                        );
                      }
                      // Navigate to member profile or details
                    },
                  ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.darkTextMuted,
                        size: 18,
                      ),
                      Expanded(
                        child: AppText(
                          "You can add upto 5 members in your family.",
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
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedErrorMessage(errorMessage: _errorMessage),
            SizedBox(height: 10),
            if (_isFamilyJoined && !_isFamilyMemberAndHead)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Leave Family',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed:
                          _isLeavingFamily
                              ? () {}
                              : _showLeaveFamilyConfirmation,
                      isLoading: _isLeavingFamily,
                    ),
                  ),
                ],
              ),
            if (_isFamilyMemberAndHead || !_isFamilyJoined)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text:
                          _isFamilyMemberAndHead
                              ? 'Add Member'
                              : 'Create Family',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed:
                          () => Get.to(() => const FamilyMemberAddScreen()),
                      isLoading: false,
                    ),
                  ),
                ],
              ),
            (_isFamilyMemberAndHead)
                ? TextButton(
                  onPressed:
                      _isDeletingFamily ? null : _showDeleteFamilyConfirmation,
                  child:
                      _isDeletingFamily
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              ),
                              SizedBox(width: 8),
                              AppText(
                                "Deleting Family...",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.bold,
                                colorType: AppTextColorType.error,
                              ),
                            ],
                          )
                          : AppText(
                            "Delete Family",
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.error,
                          ),
                )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
