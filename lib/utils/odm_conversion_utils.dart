import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Utilities for normalizing and hashing email/phone for Firebase On-Device
/// Conversion Measurement (ODM). Per Google: normalize, then SHA256 (32 raw bytes).
/// https://firebase.google.com/docs/tutorials/ads-ios-on-device-measurement/step-3

/// Normalizes an email address per Google Analytics API rules (before SHA256).
///
/// 1. Convert entire email to lowercase.
/// 2. If domain is @googlemail.com, replace with @gmail.com.
/// 3. For @gmail.com only: remove periods from local part and apply substitutions
///    (I/i/1 → l, 0 → o, 2 → z, 5 → s).
///
/// Returns null if [email] is null or empty/whitespace-only.
String? normalizeEmailForOdm(String? email) {
  if (email == null) return null;
  final trimmed = email.trim();
  if (trimmed.isEmpty) return null;

  String normalized = trimmed.toLowerCase();

  if (normalized.endsWith('@googlemail.com')) {
    normalized =
        '${normalized.substring(0, normalized.length - 16)}@gmail.com';
  }

  if (normalized.endsWith('@gmail.com')) {
    final atIndex = normalized.indexOf('@');
    String emailAddress = normalized.substring(0, atIndex);
    final domain = normalized.substring(atIndex);

    emailAddress = emailAddress.replaceAll('.', '');
    normalized = emailAddress + domain;
  }

  return normalized;
}

/// Returns SHA256 of [normalizedString] (UTF-8) as base64.
/// Hash is 32 raw bytes (not hex). Used to pass to iOS for Firebase hashed ODM API.
String? sha256Base64ForOdm(String? normalizedString) {
  if (normalizedString == null || normalizedString.isEmpty) return null;
  final bytes = utf8.encode(normalizedString);
  final digest = sha256.convert(bytes);
  return base64Encode(digest.bytes);
}

/// Default country code used when normalizing phone numbers that lack a leading +.
/// E.g. 10-digit Indian numbers become +91XXXXXXXXXX.
const String _defaultCountryCode = '+91';

/// Normalizes a phone number to E.164 format for ODM.
///
/// - Trims and removes spaces, dashes, parentheses.
/// - If the result does not start with + and has 10 digits, prepends [_defaultCountryCode].
/// - Returns a string starting with + and digits only, or null if invalid/empty.
///
/// E.164: prefix +, 1–3 digit country code, max 15 digits total (including country code).
String? normalizePhoneToE164ForOdm(String? phone) {
  if (phone == null) return null;
  final digitsOnly = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
  if (digitsOnly.isEmpty) return null;

  if (digitsOnly.startsWith('+')) {
    if (RegExp(r'^\+[0-9]{1,15}$').hasMatch(digitsOnly)) {
      return digitsOnly;
    }
    return null;
  }

  final onlyDigits = digitsOnly.replaceAll(RegExp(r'[^0-9]'), '');
  if (onlyDigits.length == 10) {
    return '$_defaultCountryCode$onlyDigits';
  }
  if (onlyDigits.length >= 11 && onlyDigits.length <= 15) {
    return '+$onlyDigits';
  }
  return null;
}
