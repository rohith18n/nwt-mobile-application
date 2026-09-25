import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FamilyMemberCard extends StatefulWidget {
  final String name;
  final String? gender; // 'male' or 'female'
  final bool isHeadMember;
  final String
  status; // 'Accepted', 'Joined', 'Invited', 'Resend', 'Requested', 'Cancel'
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onCancelTap;
  final String? message;
  final String? userGuid;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? relationId;
  final String? relationName;
  final String? expiresAt;
  final String? invitedAt;

  const FamilyMemberCard({
    super.key,
    required this.name,
    this.gender,
    this.isHeadMember = false,
    required this.status,
    this.onTap,
    this.onActionTap,
    this.onCancelTap,
    this.message,
    this.userGuid,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.relationId,
    this.relationName,
    this.expiresAt,
    this.invitedAt,
  });

  @override
  State<FamilyMemberCard> createState() => _FamilyMemberCardState();
}

class _FamilyMemberCardState extends State<FamilyMemberCard> {
  bool isExpired = false;
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    AppLogger.info(
      'FamilyMemberCard init ${widget.expiresAt} ${widget.invitedAt}',
      tag: 'FamilyMemberCardExpire',
    );
    if (widget.expiresAt != null) {
      try {
        final expiresAtDate = DateTime.parse(widget.expiresAt!);
        isExpired = DateTime.now().isAfter(expiresAtDate);
      } catch (e) {
        isExpired = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        padding: const EdgeInsets.all(15),
        // margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side: Avatar and name
            Expanded(
              child: Row(
                children: [
                  // Avatar
                  Avatar(
                    path:
                        widget.gender == null
                            ? ''
                            : widget.gender?.toLowerCase() == 'female'
                            ? 'assets/svgs/dashboard/female.png'
                            : 'assets/svgs/dashboard/male.png',
                    placeholder: CircleAvatar(
                      backgroundColor: AppColors.darkButtonBorder,
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    errorWidget: CircleAvatar(
                      backgroundColor: AppColors.darkButtonBorder,
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    width: 32,
                    height: 32,
                    isNetworkImage: false,
                  ),
                  const SizedBox(width: 12),

                  // Name and message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          widget.name,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                        if (widget.message != null && !widget.isHeadMember) ...[
                          AppText(
                            widget.message!,
                            variant: AppTextVariant.bodySmall,
                            weight: AppTextWeight.regular,
                            colorType: AppTextColorType.secondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right side: Status or Actions
            if (isExpired && widget.status == "Invited") ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onActionTap,
                    child: AppText(
                      "Resend",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.link,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status or cancel button
                  widget.status == "Invited" && widget.onCancelTap != null
                      ? GestureDetector(
                        onTap: widget.onActionTap,
                        child: AppText(
                          "Resend",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.link,
                        ),
                      )
                      : _buildStatusWidget(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    // For head member, use the default primary color
    // For other statuses, use custom colors based on status
    if (widget.isHeadMember) {
      return AppText(
        "Head Member",
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.bold,
        colorType: AppTextColorType.primary,
      );
    }

    switch (widget.status) {
      case "Joined":
        return AppText(
          "Joined",
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.success,
        );
      case "Resend":
        return GestureDetector(
          onTap: widget.onActionTap,
          child: AppText(
            "Resend",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.link,
          ),
        );
      case "Requested":
        return AppText(
          "Requested",
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.secondary,
        );
      case "Invited":
        return AppText(
          "Invited",
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.primary,
        );
      case "Cancel":
        return GestureDetector(
          onTap: widget.onActionTap,
          child: AppText(
            "Cancel",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.error,
          ),
        );
      default: // Accepted
        return AppText(
          "Accepted",
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.success,
        );
    }
  }
}
