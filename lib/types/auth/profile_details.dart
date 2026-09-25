import 'package:nwt_app/types/auth/bank_details.dart';

class ProfileDetailsResponse {
  final bool success;
  final String? onboardingStatus;
  final ProfileDetailsData? data;
  final String? message;

  ProfileDetailsResponse({
    required this.success,
    this.onboardingStatus,
    this.data,
    this.message,
  });

  factory ProfileDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsResponse(
      success: json['success'] ?? false,
      onboardingStatus: json['onboarding_status'],
      message: json['message'],
      data: json['data'] != null ? ProfileDetailsData.fromJson(json['data']) : null,
    );
  }
}

class ProfileDetailsData {
  final String id;
  final String name;
  final String phoneNumber;
  final String panNumber;
  final String dob;
  final String email;
  final String? investorResidency;
  final Map<String, dynamic>? uccProfile;
  final ProfileBankDetailsData? defaultBank; // Using existing model
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? kyc;
  final bool kycDone;
  final bool needsKycVerification;
  final bool kycNameMismatch;
  final String? nameSuggestedFromPan;
  final List<dynamic>? uccAccounts;
  final String onboardingStatus;
  final List<String> profileIssues;
  final bool identityVerified;
  final bool profileComplete;
  final ProfileRequirements? profileRequirements;

  ProfileDetailsData({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.panNumber,
    required this.dob,
    required this.email,
    this.investorResidency,
    this.uccProfile,
    this.defaultBank,
    this.createdAt,
    this.updatedAt,
    this.kyc,
    required this.kycDone,
    required this.needsKycVerification,
    required this.kycNameMismatch,
    this.nameSuggestedFromPan,
    this.uccAccounts,
    required this.onboardingStatus,
    required this.profileIssues,
    required this.identityVerified,
    required this.profileComplete,
    this.profileRequirements,
  });

  factory ProfileDetailsData.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      dob: json['dob'] ?? '',
      email: json['email'] ?? '',
      investorResidency: json['investor_residency'],
      uccProfile: json['ucc_profile'] as Map<String, dynamic>?,
      defaultBank: json['default_bank'] != null ? ProfileBankDetailsData.fromJson(json['default_bank']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      kyc: json['kyc'] as Map<String, dynamic>?,
      kycDone: json['kyc_done'] ?? false,
      needsKycVerification: json['needs_kyc_verification'] ?? true,
      kycNameMismatch: json['kyc_name_mismatch'] ?? false,
      nameSuggestedFromPan: json['name_suggested_from_pan'],
      uccAccounts: json['ucc_accounts'] as List<dynamic>?,
      onboardingStatus: json['onboarding_status'] ?? '',
      profileIssues: List<String>.from(json['profile_issues'] ?? []),
      identityVerified: json['identity_verified'] ?? false,
      profileComplete: json['profile_complete'] ?? false,
      profileRequirements: json['profile_requirements'] != null
          ? ProfileRequirements.fromJson(json['profile_requirements'])
          : null,
    );
  }
}

class ProfileRequirements {
  final String investorResidency;
  final List<ProfileSection> sections;
  final List<String> optionalFieldKeys;
  final List<String> notes;

  ProfileRequirements({
    required this.investorResidency,
    required this.sections,
    required this.optionalFieldKeys,
    required this.notes,
  });

  factory ProfileRequirements.fromJson(Map<String, dynamic> json) {
    return ProfileRequirements(
      investorResidency: json['investor_residency'] ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ProfileSection.fromJson(e))
              .toList() ??
          [],
      optionalFieldKeys: List<String>.from(json['optional_field_keys'] ?? []),
      notes: List<String>.from(json['notes'] ?? []),
    );
  }
}

class ProfileSection {
  final String id;
  final String title;
  final List<dynamic> requiredFields;
  final List<dynamic> optionalFields;

  ProfileSection({
    required this.id,
    required this.title,
    required this.requiredFields,
    required this.optionalFields,
  });

  factory ProfileSection.fromJson(Map<String, dynamic> json) {
    return ProfileSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      requiredFields: json['required'] ?? [],
      optionalFields: json['optional'] ?? [],
    );
  }
}
