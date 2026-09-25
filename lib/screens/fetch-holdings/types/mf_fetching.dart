class MfCentralOtpResponse {
  int status;
  String message;
  MFCentralOTPData? data;

  MfCentralOtpResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory MfCentralOtpResponse.fromJson(
    Map<String, dynamic> json,
  ) => MfCentralOtpResponse(
    status: json["statusCode"],
    message: json["message"],
    data: json["data"] != null ? MFCentralOTPData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class MFCentralOTPData {
  DecryptedCASDetails decryptedcasdetails;
  String token;

  MFCentralOTPData({required this.decryptedcasdetails, required this.token});

  factory MFCentralOTPData.fromJson(Map<String, dynamic> json) =>
      MFCentralOTPData(
        decryptedcasdetails: DecryptedCASDetails.fromJson(
          json["decryptedcasdetails"],
        ),
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
    "decryptedcasdetails": decryptedcasdetails.toJson(),
    "token": token,
  };
}

class DecryptedCASDetails {
  int reqId;
  String otpRef;
  String userSubjectReference;
  String clientRefNo;

  DecryptedCASDetails({
    required this.reqId,
    required this.otpRef,
    required this.userSubjectReference,
    required this.clientRefNo,
  });

  factory DecryptedCASDetails.fromJson(Map<String, dynamic> json) =>
      DecryptedCASDetails(
        reqId: json["reqId"],
        otpRef: json["otpRef"],
        userSubjectReference: json["userSubjectReference"],
        clientRefNo: json["clientRefNo"],
      );

  Map<String, dynamic> toJson() => {
    "reqId": reqId,
    "otpRef": otpRef,
    "userSubjectReference": userSubjectReference,
    "clientRefNo": clientRefNo,
  };
}

class MfCentralVerifyOtpResponse {
  int status;
  String message;
  bool get success => status == 200 || status == 201;

  MfCentralVerifyOtpResponse({required this.status, required this.message});

  factory MfCentralVerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      MfCentralVerifyOtpResponse(
        status: json["statusCode"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {"status": status, "message": message};
}
