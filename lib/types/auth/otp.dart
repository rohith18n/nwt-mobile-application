import 'package:nwt_app/types/auth/user.dart';

class GenerateOtpResponse {
  bool success;
  String message;
  String? type;
  GenerateOtpData? data;

  GenerateOtpResponse({
    required this.success,
    required this.message,
    this.type,
    this.data,
  });

  factory GenerateOtpResponse.fromJson(Map<String, dynamic> json) =>
      GenerateOtpResponse(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        type: json["type"],
        data: json["data"] == null ? null : GenerateOtpData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "type": type,
    "data": data?.toJson(),
  };
}

class GenerateOtpData {
  DateTime expireAt;

  GenerateOtpData({required this.expireAt});

  factory GenerateOtpData.fromJson(Map<String, dynamic> json) =>
      GenerateOtpData(expireAt: DateTime.parse(json["expireAt"]));

  Map<String, dynamic> toJson() => {"expireAt": expireAt.toIso8601String()};
}

class VerifyOtpResponse {
  bool success;
  String message;
  VerifyOtpData? data;
  int? status; // Keep status for backward compatibility if needed, but primarily use success

  VerifyOtpResponse({
    required this.success,
    required this.message,
    this.data,
    this.status,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        data: json["data"] == null ? null : VerifyOtpData.fromJson(json["data"]),
        status: json["statusCode"],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
    "status": status,
  };
}

class VerifyOtpData {
  String access;
  String refresh;
  User? user;

  VerifyOtpData({required this.access, required this.refresh, this.user});

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) => VerifyOtpData(
    access: json["access"] ?? "",
    refresh: json["refresh"] ?? "",
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "access": access,
    "refresh": refresh,
    "user": user?.toJson(),
  };
}
