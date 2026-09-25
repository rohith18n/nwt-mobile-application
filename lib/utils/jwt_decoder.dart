import 'dart:convert';
import 'package:nwt_app/utils/logger.dart';

/// Utility class for decoding and validating JWT tokens
class JwtDecoder {
  /// Decode JWT token and extract payload
  /// Returns null if token is invalid or malformed
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        AppLogger.warning('Invalid JWT format: expected 3 parts', tag: 'JwtDecoder');
        return null;
      }
      
      // Decode payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error decoding JWT', error: e, tag: 'JwtDecoder');
      return null;
    }
  }
  
  /// Check if token is expired
  /// Returns true if expired or invalid, false if still valid
  static bool isExpired(String token) {
    final expiryDate = getExpiryDate(token);
    if (expiryDate == null) {
      AppLogger.warning('Could not get expiry date from token', tag: 'JwtDecoder');
      return true;
    }
    
    final isExpired = DateTime.now().isAfter(expiryDate);
    
    if (isExpired) {
      AppLogger.info('Token is expired', tag: 'JwtDecoder');
    } else {
      final remaining = getTimeRemaining(token);
      AppLogger.info(
        'Token valid for ${remaining?.inMinutes ?? 0} more minutes',
        tag: 'JwtDecoder',
      );
    }
    
    return isExpired;
  }
  
  /// Get expiry date from token
  /// Returns null if token is invalid or doesn't contain exp claim
  static DateTime? getExpiryDate(String token) {
    final payload = decode(token);
    if (payload == null || !payload.containsKey('exp')) {
      return null;
    }
    
    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    
    return null;
  }
  
  /// Get time remaining until token expires
  /// Returns null if token is invalid or expired
  static Duration? getTimeRemaining(String token) {
    final expiryDate = getExpiryDate(token);
    if (expiryDate == null) return null;
    
    final remaining = expiryDate.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
  
  /// Get user ID from token payload
  static String? getUserId(String token) {
    final payload = decode(token);
    return payload?['user_id'] as String?;
  }
  
  /// Get email from token payload
  static String? getEmail(String token) {
    final payload = decode(token);
    return payload?['email'] as String?;
  }
}
