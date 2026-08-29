class BseBankManagement {
    int statusCode;
    String message;
    Data? data;

    BseBankManagement({
        required this.statusCode,
        required this.message,
        required this.data,
    });

    factory BseBankManagement.fromJson(Map<String, dynamic> json) => BseBankManagement(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String id;
    String onboardingId;
    String bankName;
    String ifscCode;
    String accountNumber;
    String accountType;
    String accountHolderName;
    dynamic micrCode;
    dynamic bankCountry;
    bool isPrimary;
    bool isVerified;
    dynamic verifiedAt;
    dynamic verificationReferenceId;
    dynamic verificationUtr;

    Data({
        required this.id,
        required this.onboardingId,
        required this.bankName,
        required this.ifscCode,
        required this.accountNumber,
        required this.accountType,
        required this.accountHolderName,
        required this.micrCode,
        required this.bankCountry,
        required this.isPrimary,
        required this.isVerified,
        required this.verifiedAt,
        required this.verificationReferenceId,
        required this.verificationUtr,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        onboardingId: json["onboarding_id"],
        bankName: json["bank_name"],
        ifscCode: json["ifsc_code"],
        accountNumber: json["account_number"],
        accountType: json["account_type"],
        accountHolderName: json["account_holder_name"],
        micrCode: json["micr_code"],
        bankCountry: json["bank_country"],
        isPrimary: json["is_primary"],
        isVerified: json["is_verified"],
        verifiedAt: json["verified_at"],
        verificationReferenceId: json["verification_reference_id"],
        verificationUtr: json["verification_utr"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "onboarding_id": onboardingId,
        "bank_name": bankName,
        "ifsc_code": ifscCode,
        "account_number": accountNumber,
        "account_type": accountType,
        "account_holder_name": accountHolderName,
        "micr_code": micrCode,
        "bank_country": bankCountry,
        "is_primary": isPrimary,
        "is_verified": isVerified,
        "verified_at": verifiedAt,
        "verification_reference_id": verificationReferenceId,
        "verification_utr": verificationUtr,
    };
}
