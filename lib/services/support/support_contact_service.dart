import 'package:get/get.dart';
import 'package:nwt_app/constants/strings.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:nwt_app/utils/whatsapp_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support context types for different support flows
enum SupportContext { deleteAccount, generalSupport }

/// Service for handling support contact (email or WhatsApp) based on Remote Config
class SupportContactService {
  // Constants for contact types
  static const String contactTypeWhatsApp = 'whatsapp';
  static const String contactTypeEmail = 'email';

  // Constants for JSON config keys
  static const String jsonKeyContactType = 'contact_type';
  static const String jsonKeySupportEmail = 'support_email';
  static const String jsonKeySupportWhatsappNumber = 'support_whatsapp_number';
  static const String jsonKeyMessageTemplate = 'message_template';

  // Constants for context keys
  static const String contextKeyDeleteAccount = 'delete_account';
  static const String contextKeyGeneralSupport = 'general_support';

  // Constants for template variables
  static const String templateVarPhone = 'phone';
  static const String templateVarEmail = 'email';

  // Default fallback email
  static const String defaultSupportEmail = 'support@pivotmoney.app';

  /// Get effective contact type for UI display
  ///
  /// This method checks WhatsApp installation before returning contact type.
  /// Use this in UI to determine which contact option to show.
  ///
  /// Returns the effective contact type considering:
  /// - WhatsApp installation status
  /// - User phone number availability
  /// - NRI status
  static Future<String> getEffectiveContactType(SupportContext context) async {
    return await _getContactTypeForContext(context);
  }

  /// Contact support based on the context
  ///
  /// [context] - The support context (deleteAccount, generalSupport, etc.)
  /// [templateVariables] - Optional additional template variables to substitute in message
  ///
  /// Returns `true` if successful, `false` if failed.
  /// Implements automatic fallback: WhatsApp → Email
  static Future<bool> contactSupport({
    required SupportContext context,
    Map<String, String>? templateVariables,
  }) async {
    try {
      final contactType = await _getContactTypeForContext(context);
      AppLogger.info('SupportContactService: contactType=$contactType for context=$context', tag: 'SupportContactService');

      if (contactType == contactTypeWhatsApp) {
        final phoneNumber = _getSupportWhatsAppNumber(context);
        AppLogger.info('SupportContactService: phoneNumber=$phoneNumber', tag: 'SupportContactService');
        if (phoneNumber.isEmpty) {
          SnackbarHelper.showInfo(
            title: AppStrings.whatsAppNotConfigured,
            message: AppStrings.openingEmailInstead,
          );
          return await _launchEmail(context);
        }

        final whatsappSuccess = await _launchWhatsApp(
          context,
          templateVariables,
        );

        if (!whatsappSuccess) {
          SnackbarHelper.showInfo(
            title: AppStrings.whatsAppNotAvailable,
            message: AppStrings.openingEmailInstead,
          );
          return await _launchEmail(context);
        }
        return true;
      } else {
        return await _launchEmail(context);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error contacting support: $e',
        tag: 'SupportContactService',
        stackTrace: stackTrace,
      );

      final supportEmail = _getSupportEmail(context);
      SnackbarHelper.showError(
        title: AppStrings.unableToContactSupport,
        message: '${AppStrings.pleaseTryAgainOrEmailUsAt}$supportEmail',
      );

      return false;
    }
  }

  /// Get contact type for the given context with smart selection
  ///
  /// Checks:
  /// 1. If contact_type is "whatsapp" but WhatsApp is not installed → use email
  /// 2. If contact_type is "whatsapp" but user has no phone → use email
  /// 3. If contact_type is "whatsapp" but user is NRI with only email → use email
  ///
  /// Otherwise returns the configured contact type.
  static Future<String> _getContactTypeForContext(
    SupportContext context,
  ) async {
    final config = RemoteConfigService.to.supportContactConfig.value;
    String? contactType;

    if (config != null) {
      final contextKey = _getContextKey(context);
      final contextConfig = config[contextKey];
      if (contextConfig != null && contextConfig[jsonKeyContactType] != null) {
        contactType = contextConfig[jsonKeyContactType] as String;
      }
    }

    contactType ??= contactTypeWhatsApp;
    AppLogger.info('SupportContactService: Final resolved contactType=$contactType', tag: 'SupportContactService');

    // FORCE WhatsApp if installed and we are NOT explicitly wanting email for a good reason
    // User wants WhatsApp button to always open WhatsApp.
    if (await WhatsAppUtils.isWhatsAppInstalled()) {
      final phoneNumber = _getSupportWhatsAppNumber(context);
      if (phoneNumber.isNotEmpty) {
        return contactTypeWhatsApp;
      }
    }

    return contactType;
  }

  /// Get support email for the given context (with fallback to hardcoded email)
  static String _getSupportEmail(SupportContext context) {
    final config = RemoteConfigService.to.supportContactConfig.value;
    if (config != null) {
      final contextKey = _getContextKey(context);
      final contextConfig = config[contextKey];
      if (contextConfig != null && contextConfig[jsonKeySupportEmail] != null) {
        return contextConfig[jsonKeySupportEmail] as String;
      }
    }
    return defaultSupportEmail;
  }

  /// Get support WhatsApp number for the given context (JSON only)
  static String _getSupportWhatsAppNumber(SupportContext context) {
    final config = RemoteConfigService.to.supportContactConfig.value;
    if (config != null) {
      final contextKey = _getContextKey(context);
      final contextConfig = config[contextKey];
      if (contextConfig != null &&
          contextConfig[jsonKeySupportWhatsappNumber] != null &&
          (contextConfig[jsonKeySupportWhatsappNumber] as String).isNotEmpty) {
        return contextConfig[jsonKeySupportWhatsappNumber] as String;
      }
    }
    return RemoteConfigService.to.whatsappNumber.value;
  }

  /// Get message template for the given context
  /// Template is shared between email and WhatsApp and stored at context level
  static String _getMessageTemplate(SupportContext context) {
    final config = RemoteConfigService.to.supportContactConfig.value;
    if (config != null) {
      final contextKey = _getContextKey(context);
      final contextConfig = config[contextKey];
      if (contextConfig != null &&
          contextConfig[jsonKeyMessageTemplate] != null) {
        return contextConfig[jsonKeyMessageTemplate] as String;
      }
    }
    switch (context) {
      case SupportContext.deleteAccount:
        return 'Hello, I would like to delete my account.';
      case SupportContext.generalSupport:
        return 'Hello, I need support.';
    }
  }

  /// Get context key string for JSON lookup
  static String _getContextKey(SupportContext context) {
    switch (context) {
      case SupportContext.deleteAccount:
        return contextKeyDeleteAccount;
      case SupportContext.generalSupport:
        return contextKeyGeneralSupport;
    }
  }

  /// Launch email for support
  /// Returns `true` if successful, `false` if failed
  static Future<bool> _launchEmail(SupportContext context) async {
    final email = _getSupportEmail(context);

    if (email.isEmpty) {
      AppLogger.error(
        'Support email not configured',
        tag: 'SupportContactService',
      );
      return false;
    }

    // Get message template and substitute variables
    String body = _getMessageTemplate(context);
    final variables = <String, String>{};

    try {
      final userController = Get.find<UserController>();
      final user = userController.userData;
      if (user != null) {
        if (user.phonenumber != null && user.phonenumber!.isNotEmpty) {
          variables[templateVarPhone] = user.phonenumber!;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          variables[templateVarEmail] = user.email!;
        }
      }
    } catch (e) {
      // Template will work without user data
    }

    body = _substituteTemplateVariables(body, variables);

    // Generate subject based on context
    String subject;
    switch (context) {
      case SupportContext.deleteAccount:
        subject = AppStrings.accountDeletionRequest;
        break;
      case SupportContext.generalSupport:
        subject = AppStrings.supportRequest;
        break;
    }

    // Append phone number to subject if available
    if (variables.containsKey(templateVarPhone)) {
      subject = '$subject - ${variables[templateVarPhone]}';
    }

    // Use Uri.encodeQueryComponent to properly encode spaces as %20 instead of +
    final encodedSubject = Uri.decodeQueryComponent(subject);
    final encodedBody = Uri.decodeQueryComponent(body);

    final Uri emailUri = Uri.parse(
      'mailto:$email?subject=$encodedSubject&body=$encodedBody\n',
    );

    return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  /// Launch WhatsApp for support
  /// Returns `true` if successful, `false` if failed
  static Future<bool> _launchWhatsApp(
    SupportContext context,
    Map<String, String>? additionalVariables,
  ) async {
    final phoneNumber = _getSupportWhatsAppNumber(context);

    if (phoneNumber.isEmpty) {
      return false;
    }

    String message = _getMessageTemplate(context);
    final variables = <String, String>{};

    try {
      final userController = Get.find<UserController>();
      final user = userController.userData;
      if (user != null) {
        if (user.phonenumber != null && user.phonenumber!.isNotEmpty) {
          variables[templateVarPhone] = user.phonenumber!;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          variables[templateVarEmail] = user.email!;
        }
      }
    } catch (e) {
      // Template will work without user data
    }

    if (additionalVariables != null) {
      variables.addAll(additionalVariables);
    }

    message = _substituteTemplateVariables(message, variables);

    return await WhatsAppUtils.openWhatsApp(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  /// Substitute template variables in message
  ///
  /// Replaces {{variableName}} with actual values
  /// Removes entire label-value pairs (e.g., "Phone: {{phone}}" or "Email: {{email}}")
  /// when the variable is not available
  static String _substituteTemplateVariables(
    String template,
    Map<String, String> variables,
  ) {
    String result = template;

    // Step 1: Replace all available variables with their values
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }

    // Step 2: Remove label-value pairs for missing variables
    // This handles patterns like "Phone: {{phone}}" or "Email: {{email}}"
    if (!variables.containsKey(templateVarPhone)) {
      result = _removeLabelValuePair(result, 'phone', ['Phone', 'phone']);
    }

    if (!variables.containsKey(templateVarEmail)) {
      result = _removeLabelValuePair(result, 'email', ['Email', 'email']);
    }

    // Step 3: Remove any remaining template variables that weren't substituted
    result = _removeRemainingTemplateVariables(result);

    // Step 4: Clean up formatting (commas, spaces)
    result = _cleanupFormatting(result);

    return result;
  }

  /// Remove a label-value pair from the template (e.g., "Phone: {{phone}}")
  ///
  /// Handles various formats:
  /// - "Phone: {{phone}}"
  /// - "phone: {{phone}}"
  /// - "Phone:{{phone}}"
  /// - ", Phone: {{phone}},"
  static String _removeLabelValuePair(
    String text,
    String variableName,
    List<String> labelVariations,
  ) {
    String result = text;
    final variablePattern = '{{$variableName}}';

    // Remove label-value pairs for each label variation
    for (final label in labelVariations) {
      // Pattern matches: optional comma, optional whitespace, label, optional whitespace,
      // colon, optional whitespace, {{variable}}, optional whitespace, optional comma
      final pattern = ',?\\s*$label\\s*:\\s*\\{\\{$variableName\\}\\}\\s*,?';
      result = result.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }

    // Remove standalone {{variable}} if it still exists (fallback)
    result = result.replaceAll(variablePattern, '');

    return result;
  }

  /// Remove any remaining template variables that weren't substituted
  static String _removeRemainingTemplateVariables(String text) {
    // Remove any {{...}} patterns that remain
    return text.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
  }

  /// Clean up formatting issues (extra commas, spaces)
  static String _cleanupFormatting(String text) {
    String result = text;

    // Remove multiple consecutive commas
    result = result.replaceAll(RegExp(r',\s*,+'), ',');

    // Remove trailing comma
    result = result.replaceAll(RegExp(r',\s*$'), '');

    // Remove leading comma
    result = result.replaceAll(RegExp(r'^\s*,+\s*'), '');

    // Normalize multiple spaces to single space
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Trim whitespace
    result = result.trim();

    return result;
  }
}
