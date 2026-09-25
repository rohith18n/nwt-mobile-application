import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:share_plus/share_plus.dart';

class BranchService extends GetxController {
  static BranchService get to => Get.find();

  Future<void> init() async {
    await FlutterBranchSdk.init(
      enableLogging: true,
      branchAttributionLevel: BranchAttributionLevel.FULL,
    );
  }

  /// Creates and shares a dynamic link with customizable parameters
  ///
  /// [route] - The route path for the deep link
  /// [messageText] - Custom message to show in the share sheet
  /// [metadata] - Map of custom metadata to include with the link
  /// [title] - Title of the content being shared
  /// [description] - Description of the content being shared
  /// [imageUrl] - URL of the image to show with the shared content
  /// [feature] - Feature name for analytics (e.g., 'invitation_share', 'content_share')
  /// [channel] - Channel name for analytics (e.g., 'app', 'sms', 'email')
  Future<void> createLink({
    required String route,
    String? messageText,
    Map<String, dynamic>? metadata,
    String? title,
    String? description,
    String? imageUrl,
    String? feature,
    String? channel,
  }) async {
    try {
      AppLogger.info(
        'Starting createLink with route: $route',
        tag: 'BranchService',
      );

      // Create metadata object with any custom data provided
      final contentMetadata = BranchContentMetaData();

      // Add all metadata key-value pairs if provided
      if (metadata != null) {
        metadata.forEach((key, value) {
          contentMetadata.addCustomMetadata(key, value.toString());
        });
      }

      // Create a canonical identifier that includes the route
      String canonicalId = 'pivot.money';
      if (route.startsWith('/')) {
        // Remove leading slash if present
        canonicalId += route.substring(1);
      } else {
        canonicalId += '/$route';
      }

      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: canonicalId,
        title: title ?? 'Pivot Money',
        imageUrl:
            imageUrl ??
            'https://framerusercontent.com/images/rtz6gOCM9R0hXJVSdFHwlx7If0.png',
        contentDescription: description ?? 'Check out Pivot Money',
        keywords: ['Finance', 'Networth', 'Pivot'],
        publiclyIndex: true,
        locallyIndex: true,
        contentMetadata: contentMetadata,
      );

      // Create the link properties without an alias to avoid conflicts
      // Let Branch auto-generate unique URLs to prevent alias conflicts
      BranchLinkProperties lp = BranchLinkProperties(
        channel: channel ?? 'app',
        feature: feature ?? 'share',
        // Removed alias to prevent conflicts when resending invitations
      );

      // Add the route to the link data instead of using it as an alias
      lp.addControlParam('route', route);

      // Generate the Branch link
      AppLogger.info('Generating Branch link', tag: 'BranchService');
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: lp,
      );

      if (response.success) {
        final String shortUrl = response.result;
        AppLogger.info(
          'Link generated successfully: $shortUrl',
          tag: 'BranchService',
        );

        // Format the message text based on the feature type
        String formattedMessage;

        if (feature == 'family_invitation' &&
            metadata != null &&
            metadata.containsKey('inviterName') &&
            metadata.containsKey('inviteeName')) {
          // Use the custom format for family invitations
          formattedMessage =
              '''
          Hi ${metadata['inviteeName']}, ${metadata['inviterName']} is inviting you to manage family finances together on Pivot Money App by Networth Tracker!  

🔒 Private views for all your accounts
🔍 Free MF portfolio health scan  
📈 Expert equity strategies  
👨‍👩‍👧 Unified tracking + alerts  

Join now: $shortUrl  
'''.trim();
        } else {
          // Use the default message or the provided one
          formattedMessage =
              messageText != null
                  ? '$messageText\n\n$shortUrl'
                  : 'Check out Pivot Money: $shortUrl';
        }

        // Use share_plus to share the formatted message
        AppLogger.info(
          'Sharing message with length: ${formattedMessage.length}',
          tag: 'BranchService',
        );

        // Platform-specific share approach
        if (Platform.isIOS) {
          // On iOS, we need to handle sharing differently
          AppLogger.info(
            'Using iOS-specific sharing approach',
            tag: 'BranchService',
          );

          // For iOS, we'll use a simpler message format to avoid issues
          final iosMessage =
              messageText != null
                  ? '$messageText\n\n$shortUrl'
                  : 'Check out Pivot Money: $shortUrl';

          // Use Share.share with minimal parameters for iOS
          await Share.share(
            iosMessage,
            subject: title ?? 'Pivot Money Invitation',
          );
        } else {
          // Android and other platforms
          await Share.share(
            formattedMessage,
            subject: title ?? 'Pivot Money Invitation',
          );
        }

        AppLogger.info('Share.share called successfully', tag: 'BranchService');
      } else {
        AppLogger.error(
          'Error generating link: ${response.errorCode} - ${response.errorMessage}',
          tag: 'BranchService',
        );

        // If we can't generate a link, try sharing a generic message
        if (messageText != null) {
          await Share.share(messageText, subject: title ?? 'Pivot Money');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception during link generation or sharing: $e',
        tag: 'BranchService',
      );
      AppLogger.error('Stack trace: $stackTrace', tag: 'BranchService');

      // Try a direct share as fallback
      try {
        final fallbackMessage = messageText ?? 'Check out Pivot Money';
        await Share.share(fallbackMessage, subject: title ?? 'Pivot Money');
      } catch (shareError) {
        AppLogger.error(
          'Fallback share also failed: $shareError',
          tag: 'BranchService',
        );
      }
    }
  }

  Future<void> shareLink({required String link}) async {
    // BranchResponse response =
    //         await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
  }

  StreamSubscription<Map> trackLink(
    Function(Map<dynamic, dynamic> data) onListen, {
    VoidCallback? onError,
  }) {
    StreamSubscription<Map> streamSubscription = FlutterBranchSdk.listSession()
        .listen(
          (data) {
            if (data.containsKey("+clicked_branch_link") &&
                data["+clicked_branch_link"] == true) {
              //Link clicked. Add logic to get link data
              onListen(data);
            }
          },
          onError: (error) {
            if (onError != null) onError();
          },
        );
    return streamSubscription;
  }
}
