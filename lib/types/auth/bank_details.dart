class ProfileBankDetailsResponse {
  final bool success;
  final String? onboardingStatus;
  final ProfileBankDetailsData? data;
  final String? message;

  ProfileBankDetailsResponse({
    required this.success,
    this.onboardingStatus,
    this.data,
    this.message,
  });

  factory ProfileBankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ProfileBankDetailsResponse(
      success: json['success'] ?? false,
      onboardingStatus: json['onboarding_status'],
      message: json['message'],
      data: json['data'] != null ? ProfileBankDetailsData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'onboarding_status': onboardingStatus,
        'message': message,
        'data': data?.toJson(),
      };
}

class ProfileBankDetailsData {
  final String accountNumber;
  final String ifscCode;
  final String bankType;
  final String bankName;
  final String? upiId;
  final String? onboardingStatus;

  ProfileBankDetailsData({
    required this.accountNumber,
    required this.ifscCode,
    required this.bankType,
    required this.bankName,
    this.upiId,
    this.onboardingStatus,
  });

  factory ProfileBankDetailsData.fromJson(Map<String, dynamic> json) {
    return ProfileBankDetailsData(
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      bankType: json['bank_type'] ?? 'SB',
      bankName: json['bank_name'] ?? '',
      upiId: json['upi_id'],
      onboardingStatus: json['onboarding_status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'bank_type': bankType,
        'bank_name': bankName,
        'upi_id': upiId,
        'onboarding_status': onboardingStatus,
      };
}
