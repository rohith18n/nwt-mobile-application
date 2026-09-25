class DashboardAssetsResponse {
  int statusCode;
  String message;
  List<AssetData> data;
  bool get success => statusCode == 200 || statusCode == 201;

  DashboardAssetsResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory DashboardAssetsResponse.fromJson(Map<String, dynamic> json) =>
      DashboardAssetsResponse(
        statusCode: _parseSafeInt(json["statusCode"] ?? json["status"]) ?? 0,
        message: json["message"],
        data: List<AssetData>.from(
          json["data"].map((x) => AssetData.fromJson(x)),
        ),
      );

  static int? _parseSafeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class AssetData {
  String id;
  String title;
  double value;
  double deltavalue;
  double deltapercentage;
  bool islinked;

  AssetData({
    required this.id,
    required this.title,
    required this.value,
    required this.deltavalue,
    required this.deltapercentage,
    required this.islinked,
  });

  factory AssetData.fromJson(Map<String, dynamic> json) => AssetData(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    value: json["value"]?.toDouble() ?? 0.0,
    deltavalue: json["deltavalue"]?.toDouble() ?? 0.0,
    deltapercentage: json["deltapercentage"]?.toDouble() ?? 0.0,
    islinked: json["islinked"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "value": value,
    "deltavalue": deltavalue,
    "deltapercentage": deltapercentage,
    "islinked": islinked,
  };
}
