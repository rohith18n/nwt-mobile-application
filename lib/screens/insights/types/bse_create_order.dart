class BseCreateOrderResponse {
  int statusCode;
  String message;
  Data? data;

  BseCreateOrderResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory BseCreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      BseCreateOrderResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  String id;
  String status;
  String? bseScheme;
  String? type;
  int amount;
  String? cur;

  DateTime? placedAt;
  double? nav;
  DateTime? navDate;
  double? units;

  String? rejectedBy;
  String? reason;

  DateTime? settlementDate;
  String? bseOrderId;
  String? userId;
  String? uccId;

  bool? isUnits;
  bool? isFresh;
  String? physOrDemat;

  DateTime createdAt;

  String? redirectLink;
  String? fundName;
  String? fundLogo;
  String? schemeIsin;

  Data({
    required this.id,
    required this.status,
    this.bseScheme,
    this.type,
    required this.amount,
    this.cur,
    this.placedAt,
    this.nav,
    this.navDate,
    this.units,
    this.rejectedBy,
    this.reason,
    this.settlementDate,
    this.bseOrderId,
    this.userId,
    this.uccId,
    this.isUnits,
    this.isFresh,
    this.physOrDemat,
    required this.createdAt,
    this.redirectLink,
    this.fundName,
    this.fundLogo,
    this.schemeIsin,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"].toString(),
        status: json["status"],
        bseScheme: json["bse_scheme"],
        type: json["type"],
        amount: json["amount"] ?? 0,
        cur: json["cur"],
        placedAt: json["placed_at"] != null
            ? DateTime.parse(json["placed_at"])
            : null,
        nav: json["nav"]?.toDouble(),
        navDate:
            json["nav_date"] != null ? DateTime.parse(json["nav_date"]) : null,
        units: json["units"]?.toDouble(),
        rejectedBy: json["rejected_by"],
        reason: json["reason"],
        settlementDate: json["settlement_date"] != null
            ? DateTime.parse(json["settlement_date"])
            : null,
        bseOrderId: json["bse_order_id"]?.toString(),
        userId: json["user_id"],
        uccId: json["ucc_id"]?.toString(),
        isUnits: json["is_units"],
        isFresh: json["is_fresh"],
        physOrDemat: json["phys_or_demat"],
        createdAt: DateTime.parse(json["created_at"]),
        redirectLink: json["redirect_link"],
        fundName: json["fund_name"],
        fundLogo: json["fund_logo"],
        schemeIsin: json["scheme_isin"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "status": status,
        "bse_scheme": bseScheme,
        "type": type,
        "amount": amount,
        "cur": cur,
        "placed_at": placedAt?.toIso8601String(),
        "nav": nav,
        "nav_date": navDate?.toIso8601String(),
        "units": units,
        "rejected_by": rejectedBy,
        "reason": reason,
        "settlement_date": settlementDate?.toIso8601String(),
        "bse_order_id": bseOrderId,
        "user_id": userId,
        "ucc_id": uccId,
        "is_units": isUnits,
        "is_fresh": isFresh,
        "phys_or_demat": physOrDemat,
        "created_at": createdAt.toIso8601String(),
        "redirect_link": redirectLink,
        "fund_name": fundName,
        "fund_logo": fundLogo,
        "scheme_isin": schemeIsin,
      };
}