class PanConsentResponse {
  int statusCode;
  String message;
  Data? data;

  PanConsentResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PanConsentResponse.fromJson(Map<String, dynamic> json) =>
      PanConsentResponse(
        statusCode:
            json["statusCode"] ??
            json["status"] ??
            (json["success"] == true ? 200 : 400),
        message: json["message"] ?? "",
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  bool isPanVerified;
  String panNumber;
  String registeredName;
  String? onboardingStatus;

  Data({
    required this.isPanVerified,
    required this.panNumber,
    required this.registeredName,
    this.onboardingStatus,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    isPanVerified: json["is_pan_verified"] ?? json["kyc_status"] == "VALID",
    panNumber: json["pan_number"] ?? "",
    registeredName: json["registered_name"] ?? json["name_at_source"] ?? "",
    onboardingStatus: json["onboarding_status"],
  );

  Map<String, dynamic> toJson() => {
    "is_pan_verified": isPanVerified,
    "pan_number": panNumber,
    "registered_name": registeredName,
    "onboarding_status": onboardingStatus,
  };
}
