import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// Response model for asset consent update
class AssetConsentResponse {
  final int statusCode;
  final String message;

  AssetConsentResponse({required this.statusCode, required this.message});

  factory AssetConsentResponse.fromJson(Map<String, dynamic> json) {
    return AssetConsentResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? 'Unknown response',
    );
  }
}

/// Service to handle family member asset consent
class FamilyAssetConsentService {
  /// Updates the asset consent for a family member
  ///
  /// [familyId] - The ID of the family
  /// [userGuid] - The user GUID of the family member
  /// [assetConsent] - Whether to grant asset consent (true) or revoke it (false)
  /// [onLoading] - Callback for loading state
  Future<AssetConsentResponse> updateAssetConsent({
    required String familyId,
    required String userGuid,
    required bool assetConsent,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      AppLogger.info(
        'Updating asset consent: familyId=$familyId, userGuid=$userGuid, assetConsent=$assetConsent',
        tag: 'FamilyAssetConsentService',
      );

      final url = ApiURLs.FAMILY_ASSET_CONSENT;
      final body = {
        'familyId': familyId,
        'userGuid': userGuid,
        'assetConsent': assetConsent,
      };

      final response = await NetworkAPIHelper().patch(url, body);

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Asset consent update response: $responseData',
          tag: 'FamilyAssetConsentService',
        );

        if (response.statusCode == 200) {
          return AssetConsentResponse.fromJson(responseData);
        } else {
          return AssetConsentResponse(
            statusCode: response.statusCode,
            message:
                responseData['message'] ??
                'Server error occurred. Please try again.',
          );
        }
      } else {
        return AssetConsentResponse(
          statusCode: 400,
          message:
              'Failed to connect to server. Please check your internet connection.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating asset consent',
        error: e,
        tag: 'FamilyAssetConsentService',
        stackTrace: stackTrace,
      );
      return AssetConsentResponse(statusCode: 0, message: e.toString());
    } finally {
      onLoading(false);
    }
  }

  /// Shows a confirmation dialog for updating asset consent
  void showAssetConsentConfirmation({
    required BuildContext context,
    required String memberName,
    required bool currentConsent,
    required Function(bool newConsent) onConfirm,
  }) {
    final bool newConsentValue = !currentConsent;
    final String action = newConsentValue ? 'grant' : 'revoke';
    final String actionCapitalized = newConsentValue ? 'Grant' : 'Revoke';

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
                      color:
                          newConsentValue
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      newConsentValue
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color:
                          newConsentValue ? AppColors.success : AppColors.error,
                      size: 28,
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "$actionCapitalized Asset Access",
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
                    "Are you sure you want to $action asset access for $memberName? ${newConsentValue ? 'They will be able to view your financial assets.' : 'They will no longer be able to view your financial assets.'}",
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

                            // Execute the callback with the new consent value
                            onConfirm(newConsentValue);
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
                            actionCapitalized,
                            variant: AppTextVariant.bodyMedium,
                            colorType:
                                newConsentValue
                                    ? AppTextColorType.success
                                    : AppTextColorType.error,
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
}
