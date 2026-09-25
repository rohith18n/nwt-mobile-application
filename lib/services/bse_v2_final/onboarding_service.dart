import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class OnboardingV2Service {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Send OTP to phone number
  /// POST /api/v2/profile/contact/otp/
  Future<Map<String, dynamic>?> sendContactOtp({
    required String kind, // "phone" or "email"
    required String value, // 10-digit phone or email
  }) async {
    try {
      final payload = {
        'kind': kind,
        'value': value,
      };
      
      AppLogger.info(
        '📤 POST ${ApiURLs.CONTACT_OTP_SEND}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.CONTACT_OTP_SEND,
        jsonEncode(payload),
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ OTP sent successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to send OTP\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in sendContactOtp',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Save non-Indian phone number (no OTP required)
  /// POST /api/v2/profile/contact/phone/save/
  Future<Map<String, dynamic>?> saveContactPhone({
    required String countryCode, // e.g., "+44"
    required String phoneNumber, // Digits only
  }) async {
    try {
      final payload = {
        'country_code': countryCode,
        'phone_number': phoneNumber,
      };
      
      AppLogger.info(
        '📤 POST ${ApiURLs.CONTACT_PHONE_SAVE}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.CONTACT_PHONE_SAVE,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Phone saved successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to save phone\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in saveContactPhone',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Verify OTP and save contact
  /// POST /api/v2/profile/contact/otp/verify/
  Future<Map<String, dynamic>?> verifyContactOtp({
    required String kind,
    required String value,
    required String otp,
  }) async {
    try {
      final payload = {
        'kind': kind,
        'value': value,
        'otp': otp,
      };
      
      AppLogger.info(
        '📤 POST ${ApiURLs.CONTACT_OTP_VERIFY}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.CONTACT_OTP_VERIFY,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Contact verified successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to verify OTP\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in verifyContactOtp',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Verify PAN
  /// POST /api/v2/profile/pan/verify/
  Future<Map<String, dynamic>?> verifyPan({
    required String panNumber,
  }) async {
    try {
      final payload = {
        'pan_number': panNumber,
      };
      
      AppLogger.info(
        '📤 POST ${ApiURLs.PAN_VERIFY_V2}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.PAN_VERIFY_V2,
        jsonEncode(payload),
      );

      if (response != null) {
        final data = jsonDecode(response.body);
        
        if (response.statusCode == 200) {
          AppLogger.info(
            '✅ PAN verified successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
            tag: 'bse_v2_final',
          );
          return data;
        } else {
          // Return error data for handling (e.g., 409 user_pan_exists)
          AppLogger.error(
            '❌ Failed to verify PAN\nStatus: ${response.statusCode}\nResponse: ${response.body}',
            tag: 'bse_v2_final',
          );
          return data;
        }
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in verifyPan',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// List all holders
  /// GET /api/v2/profile/holders/
  Future<Map<String, dynamic>?> listHolders() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.HOLDERS_ADD}',
        tag: 'bse_v2_final',
      );

      final response = await _api.get(ApiURLs.HOLDERS_ADD);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holders list fetched successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to fetch holders\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in listHolders',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Add holder (joint account)
  /// POST /api/v2/profile/holders/
  Future<Map<String, dynamic>?> addHolder({
    required String panNumber,
  }) async {
    try {
      final payload = {
        'pan_number': panNumber,
      };
      
      AppLogger.info(
        '📤 POST ${ApiURLs.HOLDERS_ADD}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.HOLDERS_ADD,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holder added successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to add holder\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in addHolder',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Get holder details
  /// GET /api/v2/profile/holders/<id>/
  Future<Map<String, dynamic>?> getHolderDetails({
    required int holderId,
  }) async {
    try {
      final url = ApiURLs.holderDetail(holderId);
      
      AppLogger.info(
        '📤 GET $url',
        tag: 'bse_v2_final',
      );

      final response = await _api.get(url);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holder details fetched successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to fetch holder\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in getHolderDetails',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Get profile details (for self/primary holder)
  /// GET /api/v2/profile/details/
  Future<Map<String, dynamic>?> getProfileDetails() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.PROFILE_DETAILS}',
        tag: 'bse_v2_final',
      );

      final response = await _api.get(ApiURLs.PROFILE_DETAILS);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Profile details fetched\nStatus: ${response.statusCode}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to fetch profile details\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in getProfileDetails',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Get all holders
  /// GET /api/v2/profile/holders/
  Future<Map<String, dynamic>?> getHolders() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.GET_HOLDERS}',
        tag: 'OnboardingService',
      );

      final response = await _api.get(ApiURLs.GET_HOLDERS);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holders fetched successfully\nStatus: ${response.statusCode}\nCount: ${data['data']?['count']}',
          tag: 'OnboardingService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to fetch holders\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'OnboardingService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in getHolders',
        error: e,
        tag: 'OnboardingService',
      );
      return null;
    }
  }

  /// Update holder signature
  /// PATCH /api/v2/profile/holders/{pk}/
  Future<Map<String, dynamic>?> updateHolderSignature({
    required int holderId,
    required String signature, // Base64 PNG, min 80 chars
  }) async {
    try {
      final url = ApiURLs.updateHolder(holderId);
      final payload = {
        'signature': signature,
      };

      AppLogger.info(
        '📤 PATCH $url\nPayload: signature length = ${signature.length}',
        tag: 'OnboardingService',
      );

      final response = await _api.patch(
        url,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holder signature updated\nStatus: ${response.statusCode}\nHolder ID: $holderId',
          tag: 'OnboardingService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to update holder signature\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'OnboardingService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in updateHolderSignature',
        error: e,
        tag: 'OnboardingService',
      );
      return null;
    }
  }

  /// Delete holder
  /// DELETE /api/v2/profile/holders/{pk}/
  Future<Map<String, dynamic>?> deleteHolder({
    required int holderId,
  }) async {
    try {
      final url = ApiURLs.holderDelete(holderId);

      AppLogger.info(
        '📤 DELETE $url',
        tag: 'OnboardingService',
      );

      final response = await _api.delete(url);

      if (response != null && response.statusCode == 204) {
        AppLogger.info(
          '✅ Holder deleted successfully\nStatus: ${response.statusCode}\nHolder ID: $holderId',
          tag: 'OnboardingService',
        );
        return {
          'success': true,
          'message': 'Holder deleted successfully',
        };
      } else if (response != null && response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        AppLogger.error(
          '❌ Cannot delete holder - in use by active UCC\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'OnboardingService',
        );
        return {
          'success': false,
          'message': errorData['message'] ?? 'Holder is in use by an active UCC',
          'data': errorData,
        };
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to delete holder\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'OnboardingService',
        );
        return {
          'success': false,
          'message': errorData?['message'] ?? 'Failed to delete holder',
          'data': errorData,
        };
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in deleteHolder',
        error: e,
        tag: 'OnboardingService',
      );
      return null;
    }
  }

  /// Update profile details (for self/primary holder)
  /// PATCH /api/v2/profile/update/
  Future<Map<String, dynamic>?> updateProfileDetails({
    Map<String, dynamic>? address,
    String? name,
    String? dob,
    String? fatherName,
    String? gender,
    String? placeOfBirth,
    String? tin,
    String? occupation,
    String? incomeSlab,
    String? pob,
    String? pep,
    String? signature,
    String? investorResidency,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      final Map<String, dynamic> extendedProfile = {};
      
      // Top-level fields (not in extended_profile)
      if (name != null) payload['name'] = name;
      if (dob != null) payload['dob'] = dob;
      if (investorResidency != null) payload['investor_residency'] = investorResidency;
      
      // Extended profile fields (new API format)
      if (address != null) {
        // Map address fields to extended_profile format
        if (address['address_line_1'] != null) extendedProfile['address_line_1'] = address['address_line_1'];
        if (address['address_line_2'] != null) extendedProfile['address_line_2'] = address['address_line_2'];
        if (address['address_line_3'] != null) extendedProfile['address_line_3'] = address['address_line_3'];
        if (address['city'] != null) extendedProfile['city'] = address['city'];
        if (address['state'] != null) extendedProfile['state'] = address['state'];
        if (address['pincode'] != null) extendedProfile['pincode'] = address['pincode'];
        if (address['country'] != null) extendedProfile['country'] = address['country'];
      }
      
      if (gender != null) extendedProfile['primary_gender'] = gender;
      if (placeOfBirth != null) extendedProfile['primary_pob'] = placeOfBirth;
      if (tin != null) extendedProfile['primary_tax_id'] = tin;
      if (occupation != null) extendedProfile['primary_occupation'] = occupation;
      if (incomeSlab != null) extendedProfile['primary_income_slab'] = incomeSlab;
      if (pob != null) extendedProfile['primary_pob'] = pob;
      if (pep != null) extendedProfile['primary_pep'] = pep;
      if (signature != null) extendedProfile['primary_signature'] = signature;
      
      // Add extended_profile to payload if not empty
      if (extendedProfile.isNotEmpty) {
        payload['extended_profile'] = extendedProfile;
      }

      AppLogger.info(
        '📤 POST ${ApiURLs.PROFILE_DETAILS_UPDATE}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.PROFILE_DETAILS_UPDATE,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Profile updated successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to update profile\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in updateProfileDetails',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Update holder details
  /// PATCH /api/v2/profile/holders/<id>/
  Future<Map<String, dynamic>?> updateHolder({
    required int holderId,
    Map<String, dynamic>? address,
    String? email,
    String? phoneNumber,
    String? signature,
    String? investorResidency,
    String? relationshipToPrimary,
    String? tin,
    String? gender,
    String? fatherName,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      if (address != null) payload['address'] = address;
      if (email != null) payload['email'] = email;
      if (phoneNumber != null) payload['phone_number'] = phoneNumber;
      if (signature != null) payload['signature'] = signature;
      if (investorResidency != null) payload['investor_residency'] = investorResidency;
      if (relationshipToPrimary != null) payload['relationship_to_primary'] = relationshipToPrimary;
      if (tin != null) payload['tin'] = tin;
      if (gender != null) payload['gender'] = gender;
      if (fatherName != null) payload['father_name'] = fatherName;

      final url = ApiURLs.holderUpdate(holderId);
      
      AppLogger.info(
        '📤 PATCH $url\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.patch(
        url,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Holder updated successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to update holder\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in updateHolder',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// UPI Bank Lookup
  /// POST /api/v2/profile/bank/upi/lookup/
  Future<Map<String, dynamic>?> upiLookup({
    required String upiId,
  }) async {
    try {
      final payload = {'upi_id': upiId};

      AppLogger.info(
        '📤 POST ${ApiURLs.BANK_UPI_LOOKUP}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.BANK_UPI_LOOKUP,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UPI lookup successful\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to lookup UPI\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in upiLookup',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// UPI Bank Confirm
  /// POST /api/v2/profile/bank/upi/confirm/
  Future<Map<String, dynamic>?> upiConfirm({
    required String upiId,
    String? bankName,
    String? accountType,
    String? investorResidency,
  }) async {
    try {
      final Map<String, dynamic> payload = {'upi_id': upiId};
      if (bankName != null) payload['bank_name'] = bankName;
      if (accountType != null) payload['account_type'] = accountType;
      if (investorResidency != null) payload['investor_residency'] = investorResidency;

      AppLogger.info(
        '📤 POST ${ApiURLs.BANK_UPI_CONFIRM}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.BANK_UPI_CONFIRM,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UPI confirmed successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to confirm UPI\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in upiConfirm',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }

  /// Manual Bank Entry
  /// POST /api/v2/profile/bank/manual/
  Future<Map<String, dynamic>?> manualBank({
    required String accountNumber,
    required String ifscCode,
    String? bankName,
    String? accountType,
    String? upiId,
    String? investorResidency,
    bool skipVerification = false,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      };
      if (bankName != null) payload['bank_name'] = bankName;
      if (accountType != null) payload['account_type'] = accountType;
      if (upiId != null) payload['upi_id'] = upiId;
      if (investorResidency != null) payload['investor_residency'] = investorResidency;
      if (skipVerification) payload['skip_verification'] = skipVerification;

      AppLogger.info(
        '📤 POST ${ApiURLs.BANK_MANUAL}\nPayload: ${jsonEncode(payload)}',
        tag: 'bse_v2_final',
      );

      final response = await _api.post(
        ApiURLs.BANK_MANUAL,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Manual bank added successfully\nStatus: ${response.statusCode}\nResponse: ${response.body}',
          tag: 'bse_v2_final',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Failed to add manual bank\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'bse_v2_final',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in manualBank',
        error: e,
        tag: 'bse_v2_final',
      );
      return null;
    }
  }
}
