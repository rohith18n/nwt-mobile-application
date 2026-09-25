class FcmTokenResponse {
  int status;
  String message;

  FcmTokenResponse({required this.status, required this.message});

  factory FcmTokenResponse.fromJson(Map<String, dynamic> json) =>
      FcmTokenResponse(status: json["statusCode"], message: json["message"]);

  Map<String, dynamic> toJson() => {"status": status, "message": message};
}
