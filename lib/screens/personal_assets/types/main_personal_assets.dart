class PersonalAssetsResponse {
  int status;
  String message;
  bool get success => status == 200 || status == 201;

  PersonalAssetsResponse({required this.status, required this.message});

  factory PersonalAssetsResponse.fromJson(Map<String, dynamic> json) =>
      PersonalAssetsResponse(
        status: json["statusCode"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {"status": status, "message": message};
}
