class GlobalSearchTrendingResponse {
  int statusCode;
  String message;
  TrendingData? data;

  GlobalSearchTrendingResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory GlobalSearchTrendingResponse.fromJson(Map<String, dynamic> json) =>
      GlobalSearchTrendingResponse(
        statusCode: json["statusCode"] ?? json["status"] ?? 0,
        message: json["message"] ?? "",
        data: json["data"] != null ? TrendingData.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class TrendingData {
  List<TrendingResult> search;
  List<String> suggestion;

  TrendingData({required this.search, required this.suggestion});

  factory TrendingData.fromJson(Map<String, dynamic> json) => TrendingData(
    search:
        json["search"] != null
            ? List<TrendingResult>.from(
              json["search"]?.map((x) => TrendingResult.fromJson(x)) ?? [],
            )
            : [],
    suggestion:
        json["suggestion"] != null
            ? List<String>.from(json["suggestion"] ?? [])
            : [],
  );

  Map<String, dynamic> toJson() => {
    "search": List<dynamic>.from(search.map((x) => x.toJson())),
    "suggestion": List<dynamic>.from(suggestion),
  };
}

class TrendingResult {
  int id;
  String assetname;
  String assettype;
  String assetguid;
  int rank;
  String isin;

  TrendingResult({
    required this.id,
    required this.assetname,
    required this.assettype,
    required this.assetguid,
    required this.rank,
    required this.isin,
  });

  factory TrendingResult.fromJson(Map<String, dynamic> json) => TrendingResult(
    id: json["id"],
    assetname: json["assetname"] ?? "",
    assettype: json["assettype"] ?? "",
    assetguid: json["assetguid"] ?? "",
    rank: json["rank"] ?? 0,
    isin: json["isin"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "assetname": assetname,
    "assettype": assettype,
    "assetguid": assetguid,
    "rank": rank,
    "isin": isin,
  };
}
