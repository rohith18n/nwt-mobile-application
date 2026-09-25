class GlobalSearchResponse {
  int statusCode;
  String message;
  List<GlobalSearchResult>? data;

  GlobalSearchResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) {
    // Robustly extract status
    int status = 0;
    if (json["statusCode"] != null) status = json["statusCode"] as int;
    else if (json["status"] != null) status = json["status"] as int;
    else if (json["success"] == true) status = 200;

    // Handle nested data or direct list
    List<GlobalSearchResult> results = [];
    if (json["data"] != null) {
      if (json["data"] is List) {
        results = List<GlobalSearchResult>.from(
          json["data"].map((x) => GlobalSearchResult.fromJson(x)),
        );
      } else if (json["data"] is Map && json["data"]["schemes"] != null) {
        results = List<GlobalSearchResult>.from(
          json["data"]["schemes"].map((x) => GlobalSearchResult.fromJson(x)),
        );
      }
    }

    return GlobalSearchResponse(
      statusCode: status,
      message: json["message"] ?? "",
      data: results,
    );
  }

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": List<dynamic>.from(data?.map((x) => x.toJson()) ?? []),
  };
}

class GlobalSearchResult {
  int id;
  String assetname;
  String assettype;
  String assetguid;
  String isincode;
  String? icon;
  double? minimumAmount;

  GlobalSearchResult({
    required this.id,
    required this.assetname,
    required this.assettype,
    required this.assetguid,
    required this.isincode,
    this.icon,
    this.minimumAmount,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) =>
      GlobalSearchResult(
        id: json["id"] ?? 0,
        assetname: json["assetname"] ?? json["scheme_name"] ?? json["name"] ?? "",
        assettype: json["assettype"] ?? "MUTUAL_FUNDS",
        assetguid: json["assetguid"] ?? json["scheme_code"] ?? "",
        isincode: json["isincode"] ?? json["scheme_isin"] ?? json["isin"] ?? "",
        icon: json["icon"],
        minimumAmount: (json["minimum_amount"] ?? json["min_amount"])?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "assetname": assetname,
    "assettype": assettype,
    "assetguid": assetguid,
    "isincode": isincode,
    "icon": icon,
  };
}
