import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/types/auth/bank_details.dart';
import 'package:nwt_app/types/auth/profile_details.dart';

class ProfileService {
  /// Get profile validation status - checks if PAN, phone, etc. are verified
  /// GET /api/v2/profile/validate/
  Future<Map<String, dynamic>?> getProfileValidate() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_VALIDATE);
      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Get Profile Validate Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPanDetails() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_PAN);
      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Get PAN Details Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyPan({
    required String name,
    required String panNumber,
    required String dob,
  }) async {
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.PROFILE_PAN_VERIFY, {
        "name": name,
        "pan_number": panNumber,
        "dob": dob,
      });
      if (response != null) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Verify PAN Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  Future<ProfileBankDetailsResponse?> getBankDetails() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_BANK_DETAILS);
      if (response != null && response.statusCode == 200) {
        return ProfileBankDetailsResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('Get Bank Details Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  Future<ProfileBankDetailsResponse?> updateBankDetails({
    required String accountNumber,
    required String ifscCode,
    String bankType = "SB",
    String? upiId,
    String? bankName,
  }) async {
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.PROFILE_BANK_DETAILS, {
        "account_number": accountNumber,
        "ifsc_code": ifscCode,
        "bank_type": bankType,
        if (upiId != null) "upi_id": upiId,
        if (bankName != null) "bank_name": bankName,
      });
      if (response != null) {
        return ProfileBankDetailsResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('Update Bank Details Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  Future<ProfileDetailsResponse?> getProfileDetails() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_DETAILS);
      if (response != null && response.statusCode == 200) {
        return ProfileDetailsResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('Get Profile Details Error', error: e, tag: 'ProfileService');
      return null;
    }
  }

  /// Helper method to build extended_profile with correct field names
  /// Based on backend profile.md documentation
  Map<String, dynamic> buildExtendedProfile({
    // Personal Information
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? gender, // 'M', 'F', 'O'
    String? pep, // 'N', 'Y', 'R'
    String? occupation, // '01'-'08'
    String? incomeSlab, // '31'-'35'
    String? sourceOfWealth, // '1'-'8'
    String? maritalStatus, // 'S', 'M', 'W', 'D'
    String? fatherName,
    String? motherName,
    String? placeOfBirth,
    String? mobile,
    
    // Address (Correspondence)
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? city,
    String? state,
    String? pincode,
    String? country,
    
    // NRI Indian Address (optional)
    String? indAddressLine1,
    String? indCity,
    String? indState,
    String? indPincode,
    
    // Signature
    String? primarySignature,
    String? secondarySignature,
    
    // Tax ID for NRI
    String? primaryTaxId,
    
    // Secondary Holder (for Joint Account)
    String? secondaryFirstName,
    String? secondaryMiddleName,
    String? secondaryLastName,
    String? secondaryPan,
    String? secondaryDob,
    String? secondaryMobile,
    String? secondaryEmail,
    String? secondaryGender,
    String? secondaryTaxStatus,
    String? secondaryTaxId,
    String? secondaryCountry,
    String? secondaryAddressLine1,
    String? secondaryCity,
    String? secondaryState,
    String? secondaryPincode,
  }) {
    final profile = <String, dynamic>{};
    
    // Personal Information
    if (firstName != null) profile['primary_first_name'] = firstName;
    if (middleName != null && middleName.isNotEmpty) profile['primary_middle_name'] = middleName;
    if (lastName != null) profile['primary_last_name'] = lastName;
    if (email != null) profile['primary_email'] = email;
    if (gender != null) profile['primary_gender'] = gender;
    if (pep != null) profile['primary_pep'] = pep;
    if (occupation != null) profile['primary_occupation'] = occupation;
    if (incomeSlab != null) profile['primary_income_slab'] = incomeSlab;
    if (sourceOfWealth != null) profile['primary_source_of_wealth'] = sourceOfWealth;
    if (maritalStatus != null) profile['primary_marital_status'] = maritalStatus;
    if (fatherName != null) profile['primary_father_name'] = fatherName;
    if (motherName != null) profile['primary_mother_name'] = motherName;
    if (placeOfBirth != null) profile['primary_pob'] = placeOfBirth;
    if (mobile != null) profile['primary_mobile'] = mobile;
    
    // Address
    if (addressLine1 != null) profile['address_line_1'] = addressLine1;
    if (addressLine2 != null && addressLine2.isNotEmpty) profile['address_line_2'] = addressLine2;
    if (addressLine3 != null && addressLine3.isNotEmpty) profile['address_line_3'] = addressLine3;
    if (city != null) profile['city'] = city;
    if (state != null) profile['state'] = state;
    if (pincode != null) profile['pincode'] = pincode;
    if (country != null) profile['country'] = country;
    
    // NRI Indian Address
    if (indAddressLine1 != null) profile['ind_address_line_1'] = indAddressLine1;
    if (indCity != null) profile['ind_city'] = indCity;
    if (indState != null) profile['ind_state'] = indState;
    if (indPincode != null) profile['ind_pincode'] = indPincode;
    
    // Signature
    if (primarySignature != null) profile['primary_signature'] = primarySignature;
    if (secondarySignature != null) profile['secondary_signature'] = secondarySignature;
    
    // Tax ID
    if (primaryTaxId != null) profile['primary_tax_id'] = primaryTaxId;
    
    // Secondary Holder
    if (secondaryFirstName != null) profile['secondary_first_name'] = secondaryFirstName;
    if (secondaryMiddleName != null && secondaryMiddleName.isNotEmpty) profile['secondary_middle_name'] = secondaryMiddleName;
    if (secondaryLastName != null) profile['secondary_last_name'] = secondaryLastName;
    if (secondaryPan != null) profile['secondary_pan'] = secondaryPan;
    if (secondaryDob != null) profile['secondary_dob'] = secondaryDob;
    if (secondaryMobile != null) profile['secondary_mobile'] = secondaryMobile;
    if (secondaryEmail != null) profile['secondary_email'] = secondaryEmail;
    if (secondaryGender != null) profile['secondary_gender'] = secondaryGender;
    if (secondaryTaxStatus != null) profile['secondary_tax_status'] = secondaryTaxStatus;
    if (secondaryTaxId != null) profile['secondary_tax_id'] = secondaryTaxId;
    if (secondaryCountry != null) profile['secondary_country'] = secondaryCountry;
    if (secondaryAddressLine1 != null) profile['secondary_address_line_1'] = secondaryAddressLine1;
    if (secondaryCity != null) profile['secondary_city'] = secondaryCity;
    if (secondaryState != null) profile['secondary_state'] = secondaryState;
    if (secondaryPincode != null) profile['secondary_pincode'] = secondaryPincode;
    
    return profile;
  }

  Future<ProfileDetailsResponse?> updateProfileDetails({
    Map<String, dynamic>? extendedProfile,
    String? investorResidency,
    String? phoneNumber,
    String? dob,
    String? panNumber,
    String? name,
    bool submitProfile = false,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      // Add top-level fields if provided
      if (investorResidency != null) body['investor_residency'] = investorResidency;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (dob != null) body['dob'] = dob;
      if (panNumber != null) body['pan_number'] = panNumber;
      if (name != null) body['name'] = name;
      if (extendedProfile != null) body['extended_profile'] = extendedProfile;
      if (submitProfile) body['submit_profile'] = true;

      AppLogger.info(
        'Updating profile details: ${body.keys.toList()}',
        tag: 'ProfileService',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.PROFILE_DETAILS_UPDATE,
        body,
      );
      
      if (response != null) {
        final jsonResponse = jsonDecode(response.body);
        AppLogger.info(
          'Profile update response: success=${jsonResponse['success']}, status=${jsonResponse['onboarding_status']}',
          tag: 'ProfileService',
        );
        return ProfileDetailsResponse.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      AppLogger.error('Update Profile Details Error', error: e, tag: 'ProfileService');
      return null;
    }
  }
}
