class AaCreateConsentResponse {
  int statusCode;
  String message;
  CreateConsentResponse data;

  AaCreateConsentResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory AaCreateConsentResponse.fromJson(Map<String, dynamic> json) =>
      AaCreateConsentResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: CreateConsentResponse.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data.toJson(),
  };
}

class CreateConsentResponse {
  String fi;
  String reqdate;
  String ecreq;
  String url;

  CreateConsentResponse({
    required this.fi,
    required this.reqdate,
    required this.ecreq,
    required this.url,
  });

  factory CreateConsentResponse.fromJson(Map<String, dynamic> json) =>
      CreateConsentResponse(
        fi: json["fi"],
        reqdate: json["reqdate"],
        ecreq: json["ecreq"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
    "fi": fi,
    "reqdate": reqdate,
    "ecreq": ecreq,
    "url": url,
  };
}
