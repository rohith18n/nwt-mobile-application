class BsePaymentLinkResponse {
  int statusCode;
  String message;
  PaymentData? data;

  BsePaymentLinkResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory BsePaymentLinkResponse.fromJson(Map<String, dynamic> json) =>
      BsePaymentLinkResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? PaymentData.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class PaymentData {
  String redirectLink;

  PaymentData({required this.redirectLink});

  factory PaymentData.fromJson(Map<String, dynamic> json) => PaymentData(
    redirectLink: json["redirect_link"],
  );

  Map<String, dynamic> toJson() => {
    "redirect_link": redirectLink,
  };
}