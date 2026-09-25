class ZerodhaResponse {
  int status;
  String message;
  ZerodhaData? data;
  bool get success => status == 200 || status == 201;

  ZerodhaResponse({required this.status, required this.message, this.data});

  factory ZerodhaResponse.fromJson(Map<String, dynamic> json) =>
      ZerodhaResponse(
        status: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? ZerodhaData.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class ZerodhaData {
  String loginurl;

  ZerodhaData({required this.loginurl});

  factory ZerodhaData.fromJson(Map<String, dynamic> json) =>
      ZerodhaData(loginurl: json["loginurl"]);

  Map<String, dynamic> toJson() => {"loginurl": loginurl};
}
