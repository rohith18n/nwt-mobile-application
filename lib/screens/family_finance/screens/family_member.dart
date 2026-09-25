import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/family_finance/screens/family_management.dart';
import 'package:nwt_app/screens/family_finance/screens/family_member_add.dart';
import 'package:nwt_app/services/family_finance/family_member_remove.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FamilyMember extends StatefulWidget {
  final double? networth;
  final String firstName;
  final String lastName;
  final String relation;
  final String? gender;
  final String? userGuid;
  final String? relationId;
  final String phoneNumber;
  final String familyId;
  final String familyHeadUserGuid;

  const FamilyMember({
    super.key,
    this.networth,
    required this.firstName,
    required this.lastName,
    required this.relation,
    this.gender,
    this.userGuid,
    this.relationId,
    required this.phoneNumber,
    required this.familyId,
    required this.familyHeadUserGuid,
  });

  @override
  State<FamilyMember> createState() => _FamilyMemberState();
}

class _FamilyMemberState extends State<FamilyMember> {
  bool _isLoading = false;
  String? _errorMessage;
  final FamilyMemberRemoveService _removeService = FamilyMemberRemoveService();
  // Method to handle member removal
  Future<void> _removeMember() async {
    if (widget.userGuid == null) {
      setState(() {
        _errorMessage = 'User ID is missing';
      });
      return;
    }

    final response = await _removeService.removeFamilyMember(
      targetUserGuid: widget.userGuid!,
      familyId: widget.familyId,
      familyHeadUserGuid: widget.familyHeadUserGuid,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      AppLogger.info(
        'Remove Family Member Response: Success',
        tag: 'FamilyMemberScreen',
      );

      // Navigate back to family management screen with refresh
      Get.off(() => const FamilyManagement());
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = response.message;
        });
      }
    }
  }

  // Show confirmation dialog before removing member
  void _showRemoveConfirmation() {
    // Use the styled confirmation dialog from the service
    _removeService.showStyledRemoveConfirmation(
      context: context,
      memberName: "${widget.firstName} ${widget.lastName}",
      onConfirm: _removeMember,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.regular,
            colorType: AppTextColorType.secondary,
          ),
          AppText(
            value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              "Family Member",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              // Profile card with avatar and amount
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.darkCardBG, Color(0xFF1A1A1A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.linkColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.linkColor.withOpacity(0.03),
                        ),
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          // Avatar with border
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.linkColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.linkColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Avatar(
                              path:
                                  widget.gender == null
                                      ? ''
                                      : widget.gender?.toLowerCase() == 'female'
                                      ? 'assets/svgs/dashboard/female.png'
                                      : 'assets/svgs/dashboard/male.png',
                              errorWidget: CircleAvatar(
                                backgroundColor: AppColors.darkButtonBorder,
                                child: Text(
                                  widget.firstName.isNotEmpty
                                      ? widget.firstName[0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Monserrat',
                                  ),
                                ),
                              ),
                              width: 52,
                              height: 52,
                              isNetworkImage: false,
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Amount and Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  widget.networth != null
                                      ? CurrencyFormatter.formatRupee(
                                        widget.networth!,
                                      )
                                      : "--",
                                  variant: AppTextVariant.headline4,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  "${widget.firstName} ${widget.lastName}",
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Member details
              _buildInfoRow("First Name:", widget.firstName),
              _buildInfoRow("Last Name:", widget.lastName),
              _buildInfoRow("Relation:", widget.relation),
              _buildInfoRow("Mobile Number:", widget.phoneNumber),
            ],
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
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Edit Member Details',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: () {
                      Get.to(
                        () => FamilyMemberAddScreen(
                          isEditMode: true,
                          userGuid: widget.userGuid,
                          firstName: widget.firstName,
                          lastName: widget.lastName,
                          phoneNumber: widget.phoneNumber,
                          relationId: widget.relationId,
                          relationName: widget.relation,
                        ),
                      );
                    },
                    isLoading: false,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _isLoading ? null : _showRemoveConfirmation,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.error,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          AppText(
                            "Removing...",
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.error,
                          ),
                        ],
                      )
                      : AppText(
                        "Remove Member",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.error,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
