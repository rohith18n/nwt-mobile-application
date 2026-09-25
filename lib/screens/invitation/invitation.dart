import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/family_finance/types/invitation.dart';
import 'package:nwt_app/services/family_finance/invitation.dart';
import 'package:nwt_app/services/family_finance/invitation_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/string_utils.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class FamilyFinanceInvitationScreen extends StatefulWidget {
  final String? inviteId;

  const FamilyFinanceInvitationScreen({super.key, this.inviteId});

  @override
  State<FamilyFinanceInvitationScreen> createState() =>
      _FamilyFinanceInvitationScreenState();
}

class _FamilyFinanceInvitationScreenState
    extends State<FamilyFinanceInvitationScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  // Auto-skip functionality
  Timer? _autoSkipTimer;
  int _countdownSeconds = 3;
  bool _isAutoSkipping = false;

  // Invitation services
  final InvitationService _invitationService = InvitationService();
  final FamilyInvitationService _familyInvitationService =
      FamilyInvitationService();

  // Invitation data
  InvitationData? _invitationData;
  String _inviterName = '';
  String _familyName = '';
  String _status = "";
  String _invitationId = "";
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();

    // Log the invite ID
    AppLogger.info(
      'Invitation Screen opened with ID: ${widget.inviteId}',
      tag: 'Invitation',
    );

    // Initialize main animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse animation for invitation icon
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _animationController.forward();
    _pulseAnimationController.repeat(reverse: true);

    // Fetch invitation details using the invite ID
    _fetchInvitationDetails();
  }

  Future<void> _fetchInvitationDetails() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Check if we have an invitation ID
    if (widget.inviteId == null || widget.inviteId!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid invitation ID';
      });
      _startAutoSkipTimer();
      return;
    }

    _invitationId = widget.inviteId!;

    try {
      // Fetch invitation details using the service
      final response = await _invitationService.getInvitationDetails(
        invitationId: _invitationId,
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );

      // Check if the request was successful
      if (response.statusCode == 200 && response.data != null) {
        // Store the invitation data
        // Check if invitation is expired using the same condition as in family_management.dart
        final bool isExpired =
            response.data!.status.toLowerCase() == 'invited' &&
            DateTime.now().isAfter(
              DateTime.tryParse(response.data!.expiresAt) ?? DateTime.now(),
            );

        if (mounted) {
          setState(() {
            _invitationData = response.data;
            _inviterName =
                '${StringUtils.capitalize(response.data!.userFirstName)} ${StringUtils.capitalize(response.data!.userLastName)}';
            _familyName = StringUtils.capitalize(response.data!.familyName);
            _status = response.data!.status;
            _isExpired = isExpired;
          });
          
          // Start auto-skip timer if invitation is expired
          if (isExpired) {
            _startAutoSkipTimer();
          }
        }
        AppLogger.info(
          'Invitation details fetched successfully: $_inviterName, $_familyName',
          tag: 'Invitation',
        );
      } else {
        // Handle error response
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
          });
          _startAutoSkipTimer();
        }
        AppLogger.error(
          'Failed to fetch invitation details: ${response.message}',
          tag: 'Invitation',
        );
      }
    } catch (e) {
      // Handle exceptions
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch invitation details: $e';
        });
        _startAutoSkipTimer();
      }

      AppLogger.error(
        'Exception while fetching invitation details',
        error: e,
        tag: 'Invitation',
      );
    }
  }

  void _acceptInvitation() async {
    AppLogger.info('Accepting invitation: $_invitationData', tag: 'Invitation');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_invitationData == null) {
        setState(() {
          _errorMessage = 'Invitation data not available';
        });
        return;
      }

      // Check if the invitation is expired
      if (_isExpired) {
        setState(() {
          _errorMessage =
              'This invitation has expired. Please request a new invitation.';
        });
        return;
      }

      // Call the API to accept the invitation
      final response = await _familyInvitationService.acceptFamilyInvitation(
        memberUserId: _invitationData!.memberGuid,
        familyId: _invitationData!.familyId,
        onLoading: (isLoading) {
          // This is handled by our own loading state
        },
      );

      if (response.isSuccess) {
        // Show success message
        // Get.snackbar(
        //   'Success',
        //   'You have joined the family finance group!',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        // );

        // Navigate to the dashboard
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      } else if (response.isAlreadyAccepted) {
        // // Show already accepted message
        // Get.snackbar(
        //   'Already Joined',
        //   'You have already joined this family finance group',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.amber,
        //   colorText: Colors.black,
        // );

        // Navigate to the dashboard
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      } else {
        // Show error message
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      // Show error message using _errorMessage
      setState(() {
        _errorMessage = 'Failed to accept invitation. Please try again.';
      });

      AppLogger.error(
        'Failed to accept invitation',
        error: e,
        tag: 'Invitation',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _declineInvitation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if the invitation is expired
    if (_isExpired) {
      setState(() {
        _errorMessage =
            'This invitation has expired. Please request a new invitation.';
        _isLoading = false;
      });
      return;
    }

    try {
      if (_invitationData == null) {
        setState(() {
          _errorMessage = 'Invitation data not available';
        });
        return;
      }

      // Call the API to reject the invitation
      final response = await _familyInvitationService.rejectFamilyInvitation(
        memberUserId: _invitationData!.memberGuid,
        familyId: _invitationData!.familyId,
        onLoading: (isLoading) {
          // This is handled by our own loading state
        },
      );

      if (response.isSuccess) {
        // Show message
        // Get.snackbar(
        //   'Declined',
        //   'You have declined the invitation',
        //   snackPosition: SnackPosition.BOTTOM,
        // );

        // Navigate to the dashboard
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      } else {
        // Show error message
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      // Show error message using _errorMessage
      setState(() {
        _errorMessage = 'Failed to decline invitation. Please try again.';
      });

      AppLogger.error(
        'Failed to decline invitation',
        error: e,
        tag: 'Invitation',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to check if invitation is already accepted
  bool _isInvitationAccepted() {
    return _status.toLowerCase() == 'accepted';
  }

  // Navigate to dashboard
  void _navigateToDashboard() {
    Get.offAll(() => StackedNavbar(selectedIdx: 0));
  }

  // Start auto-skip timer for error states
  void _startAutoSkipTimer() {
    _autoSkipTimer?.cancel();
    setState(() {
      _countdownSeconds = 3;
      _isAutoSkipping = true;
    });

    _autoSkipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        _navigateToDashboard();
      }
    });
  }

  // Stop auto-skip timer
  void _stopAutoSkipTimer() {
    _autoSkipTimer?.cancel();
    setState(() {
      _isAutoSkipping = false;
      _countdownSeconds = 3;
    });
  }

  // Build UI for already accepted invitations
  Widget _buildAlreadyAcceptedUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 32.h),

        // Logo with subtle glow effect
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/app/pivot.money.png',
            height: 42.h,
            width: 130.w,
            fit: BoxFit.contain,
          ),
        ),

        SizedBox(height: 50.h),

        // Success illustration
        Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 60.sp,
            ),
          ),
        ),

        SizedBox(height: 40.h),

        // Success title
        Text(
          'Already Joined!',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // Success description
        Text(
          'You have already joined ${_familyName.isNotEmpty ? "${StringUtils.capitalize(_familyName)}'s" : "the"} Family.',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 24.h),

        // Family info card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.green,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${StringUtils.capitalize(_familyName)}\'s Family',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_inviterName.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  'Invited by $_inviterName',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 100.h),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _autoSkipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to Dashboard when back gesture is used
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Stack(
                children: [
                  // Background design elements
                  Positioned(
                    top: -100.h,
                    right: -100.w,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2196F3).withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80.h,
                    left: -80.w,
                    child: Container(
                      width: 180.w,
                      height: 180.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF673AB7).withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Main content container with blur effect
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // Main content
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child:
                          _errorMessage != null && !_isLoading
                              // Show error state UI if there's an error
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Logo with subtle glow effect
                                  SizedBox(height: 32.h),
                                  Center(
                                    child: Image.asset(
                                      'assets/app/pivot.money.png',
                                      height: 42.h,
                                      width: 130.w,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  SizedBox(height: 50.h),

                                  // Error illustration
                                  Center(
                                    child: Container(
                                      width: 120.w,
                                      height: 120.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error.withOpacity(
                                          0.08,
                                        ),
                                        border: Border.all(
                                          color: AppColors.error.withOpacity(
                                            0.15,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.link_off_rounded,
                                          color: AppColors.error,
                                          size: 60.sp,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 40.h),

                                  // Error title
                                  Text(
                                    'Invalid Invitation',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 16.h),

                                  // Error description
                                  Text(
                                    'We couldn\'t find the invitation you\'re looking for.',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: Colors.white.withOpacity(0.7),
                                      height: 1.4,
                                    ),
                                  ),

                                  SizedBox(height: 8.h),

                                  // Error details
                                  Container(
                                    margin: EdgeInsets.only(top: 8.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            'This invitation link may have expired or been removed.',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              // Show already accepted UI if invitation is accepted
                              : _isInvitationAccepted() && !_isLoading
                              ? _buildAlreadyAcceptedUI()
                              // Show normal invitation UI if no error
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 32.h),

                                  // Logo with subtle glow effect
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.15),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/app/pivot.money.png',
                                      height: 42.h,
                                      width: 130.w,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  SizedBox(height: 50.h),

                                  // Invitation header with animated container
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Your Invite to join',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  SizedBox(height: 16.h),

                                  // Family name text
                                  Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _familyName.isNotEmpty
                                          ? '${StringUtils.capitalize(_familyName)}\'s Family'
                                          : 'Family',
                                      style: TextStyle(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  SizedBox(height: 40.h),

                                  // Animated family illustration
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      height: 200.h,
                                      width: 200.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF2196F3,
                                            ).withOpacity(0.2),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/app/invitation.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 40.h),

                                  // Invitation message in a card
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width -
                                        2 *
                                            AppSizing
                                                .scaffoldHorizontalPadding -
                                        30,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Inviter info without avatar
                                        if (_inviterName.isNotEmpty &&
                                            !_isLoading)
                                          Text(
                                            'Invitation from $_inviterName',
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),

                                        if (_inviterName.isNotEmpty &&
                                            !_isLoading)
                                          SizedBox(height: 16.h),

                                        // Invitation text
                                        SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            _isLoading && _inviterName.isEmpty
                                                ? 'Loading invitation details...'
                                                : 'You have an invite request to join ${_familyName.isNotEmpty ? "${StringUtils.capitalize(_familyName)}'s" : "the"} Family.',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              height: 1.5,
                                              letterSpacing: 0.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // Show expired invitation message
                                        if (_isExpired && !_isLoading) ...[
                                          SizedBox(height: 24.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.error
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.error_outline_rounded,
                                                  color: AppColors.error,
                                                  size: 20.sp,
                                                ),
                                                SizedBox(width: 10.w),
                                                Flexible(
                                                  child: Text(
                                                    'This invitation has expired. Please request a new invitation.',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.error,
                                                      height: 1.4,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar:
            _isInvitationAccepted()
                ? Container(
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
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Go to Dashboard',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed: () {
                                Get.offAll(() => StackedNavbar(selectedIdx: 0));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                : _isExpired || (_errorMessage != null && !_isLoading)
                ? Container(
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
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Skip to Dashboard ($_countdownSeconds)',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed: () {
                                _stopAutoSkipTimer();
                                _navigateToDashboard();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedErrorMessage(errorMessage: _errorMessage),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Accept Request',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed: _acceptInvitation,
                              isLoading: _isLoading,
                              isDisabled: _isExpired,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed:
                            (_isLoading || _isExpired)
                                ? null
                                : _declineInvitation,
                        child:
                            _isLoading
                                ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.error,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    AppText(
                                      "Rejecting...",
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.bold,
                                      colorType: AppTextColorType.error,
                                    ),
                                  ],
                                )
                                : AppText(
                                  "Reject Request",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.error,
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
