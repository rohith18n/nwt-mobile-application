import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class RemoveMemberResponse {
  final int statusCode;
  final String message;
  final dynamic data;

  RemoveMemberResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory RemoveMemberResponse.fromJson(Map<String, dynamic> json) {
    return RemoveMemberResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? 'Unknown error',
      data: json['data'],
    );
  }
}

class FamilyMemberRemoveService {
  /// Shows a styled confirmation dialog for removing a family member
  ///
  /// [context] - The build context
  /// [memberName] - The name of the member to remove
  /// [onConfirm] - Callback when removal is confirmed
  void showStyledRemoveConfirmation({
    required BuildContext context,
    required String memberName,
    required VoidCallback onConfirm,
  }) {
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
                      Icons.person_remove,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Remove Family Member",
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
                    "Are you sure you want to remove $memberName from your family?",
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

                      // Remove button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Execute the removal callback
                            onConfirm();
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
                            "Remove",
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

  /// Shows a styled confirmation dialog for resending an invitation to a family member
  ///
  /// [context] - The build context
  /// [memberName] - The name of the member to resend invitation to
  /// [onConfirm] - Callback when resend is confirmed
  void showStyledResendConfirmation({
    required BuildContext context,
    required String memberName,
    required VoidCallback onConfirm,
  }) {
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
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Resend Invitation",
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
                    "Are you sure you want to resend invitation to $memberName?",
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

                      // Resend button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Close the dialog first
                            Navigator.of(context).pop();

                            // Execute the resend callback
                            onConfirm();
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
                            "Resend",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.success,
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

  Future<RemoveMemberResponse> removeFamilyMember({
    required String targetUserGuid,
    required String familyId,
    required String familyHeadUserGuid,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Construct the URL with path parameters
      final url =
          "${ApiURLs.REMOVE_FAMILY_MEMBER}/$familyHeadUserGuid/$familyId/$targetUserGuid";

      AppLogger.info(
        'Remove Family Member Request: URL=$url',
        tag: 'FamilyMemberRemoveService',
      );

      final response = await NetworkAPIHelper().post(
        url,
        {}, // Empty body as parameters are in URL
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          AppLogger.info(
            'Remove Family Member Response: ${responseData.toString()}',
            tag: 'FamilyMemberRemoveService',
          );
          return RemoveMemberResponse.fromJson(responseData);
        } else {
          AppLogger.error(
            'Remove Family Member Error: Status ${response.statusCode}, Response: ${response.body}',
            tag: 'FamilyMemberRemoveService',
          );
          return RemoveMemberResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Server error occurred. Please try again.',
          );
        }
      } else {
        AppLogger.error(
          'Remove Family Member Error: Null response from server',
          tag: 'FamilyMemberRemoveService',
        );
        return RemoveMemberResponse(
          statusCode: 400,
          message:
              'Failed to connect to server. Please check your internet connection.',
        );
      }
    } catch (e, subTrace) {
      AppLogger.error(
        'Remove Family Member Error',
        error: e,
        tag: 'FamilyMemberRemoveService',
        stackTrace: subTrace,
      );
      return RemoveMemberResponse(statusCode: 0, message: e.toString());
    } finally {
      onLoading(false);
    }
  }
}
