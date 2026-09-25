import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request a single permission with a custom rationale dialog
  Future<bool> requestPermission(
    Permission permission, {
    String? title,
    String? message,
    bool showRationale = true,
  }) async {
    // Check if permission is already granted
    if (await permission.isGranted) {
      return true;
    }

    // Show rationale dialog if needed
    if (showRationale) {
      final shouldProceed = await _showRationaleDialog(
        title ?? _getPermissionTitle(permission),
        message ?? _getPermissionMessage(permission),
      );
      if (!shouldProceed) return false;
    }

    // Request the permission
    final status = await permission.request();

    // Handle the result
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(permission);
      return false;
    }

    return status.isGranted;
  }

  /// Request multiple permissions at once
  Future<Map<Permission, bool>> requestPermissions(
    List<Permission> permissions, {
    String? title,
    String? message,
    bool showRationale = true,
  }) async {
    final Map<Permission, bool> results = {};
    
    // Check which permissions are not granted
    final permissionsToRequest = <Permission>[];
    for (final permission in permissions) {
      if (await permission.isGranted) {
        results[permission] = true;
      } else {
        permissionsToRequest.add(permission);
      }
    }

    if (permissionsToRequest.isEmpty) {
      return results;
    }

    // Show rationale for remaining permissions
    if (showRationale) {
      final shouldProceed = await _showRationaleDialog(
        title ?? 'Permissions Required',
        message ?? 'These permissions are required for the app to function properly.',
      );
      if (!shouldProceed) {
        for (final permission in permissionsToRequest) {
          results[permission] = false;
        }
        return results;
      }
    }

    // Request remaining permissions
    for (final permission in permissionsToRequest) {
      final status = await permission.request();
      results[permission] = status.isGranted;
      
      if (status.isPermanentlyDenied) {
        await _showSettingsDialog(permission);
      }
    }

    return results;
  }

  Future<bool> _showRationaleDialog(String title, String message) async {
    return await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: AppText(
              title,
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            content: AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const AppText(
                      'Not Now',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const AppText(
                      'Continue',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showSettingsDialog(Permission permission) async {
    Get.snackbar(
      'Permission Required',
      'Please enable ${_getPermissionTitle(permission).toLowerCase()} access in settings',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () => openAppSettings(),
        child: const Text(
          'Open Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera Access';
      case Permission.photos:
        return 'Photo Access';
      case Permission.microphone:
        return 'Microphone Access';
      case Permission.storage:
        return 'Storage Access';
      case Permission.location:
        return 'Location Access';
      case Permission.notification:
        return 'Notification Access';
      default:
        return 'Permission Required';
    }
  }

  String _getPermissionMessage(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera access is required to take photos.';
      case Permission.photos:
        return 'Photo access is required to select images from your gallery.';
      case Permission.microphone:
        return 'Microphone access is required for voice features.';
      case Permission.storage:
        return 'Storage access is required to save files.';
      case Permission.location:
        return 'Location access is required for location-based features.';
      case Permission.notification:
        return 'Notification access is required to receive important updates.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }
}
