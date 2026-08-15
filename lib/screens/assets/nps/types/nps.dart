class NpsRespone {
  int statusCode;
  String message;
  NPSData? data;

  NpsRespone({required this.statusCode, required this.message, this.data});

  factory NpsRespone.fromJson(Map<String, dynamic> json) => NpsRespone(
    statusCode: json["statusCode"] ?? 0,
    message: json["message"] ?? "",
    data: json["data"] != null ? NPSData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class NPSData {
  double totalholdings;
  Tier tier1;
  Tier tier2;
  List<Profile> profiles;

  NPSData({
    required this.totalholdings,
    required this.tier1,
    required this.tier2,
    required this.profiles,
  });

  factory NPSData.fromJson(Map<String, dynamic> json) => NPSData(
    totalholdings: (json["totalholdings"] as num?)?.toDouble() ?? 0.0,
    tier1: Tier.fromJson(json["tier1"] ?? {}),
    tier2: Tier.fromJson(json["tier2"] ?? {}),
    profiles:
        json["profiles"] != null
            ? List<Profile>.from(
              json["profiles"].map((x) => Profile.fromJson(x)),
            )
            : [],
  );

  Map<String, dynamic> toJson() => {
    "totalholdings": totalholdings,
    "tier1": tier1.toJson(),
    "tier2": tier2.toJson(),
    "profiles": List<dynamic>.from(profiles.map((x) => x.toJson())),
  };
}

class Tier {
  double value;
  String? schemetype;
  List<Fund> funds;

  Tier({required this.value, this.schemetype, required this.funds});

  factory Tier.fromJson(Map<String, dynamic> json) => Tier(
    value: (json["value"] as num?)?.toDouble() ?? 0.0,
    schemetype: json["schemetype"],
    funds:
        json["funds"] != null
            ? List<Fund>.from(json["funds"].map((x) => Fund.fromJson(x)))
            : [],
  );

  Map<String, dynamic> toJson() => {
    "value": value,
    "schemetype": schemetype,
    "funds": List<dynamic>.from(funds.map((x) => x.toJson())),
  };
}

class Fund {
  String schemename;
  double units;
  double nav;
  double value;
  double deltapercentage;
  double deltavalue;
  int? count;
  List<List<dynamic>> transactions;

  Fund({
    required this.schemename,
    required this.units,
    required this.nav,
    required this.value,
    required this.deltapercentage,
    required this.deltavalue,
    this.count,
    this.transactions = const [],
  });

  factory Fund.fromJson(Map<String, dynamic> json) => Fund(
    schemename: json["schemename"] ?? "",
    units: (json["units"] as num?)?.toDouble() ?? 0.0,
    nav: (json["nav"] as num?)?.toDouble() ?? 0.0,
    value: (json["value"] as num?)?.toDouble() ?? 0.0,
    deltapercentage: (json["deltapercentage"] as num?)?.toDouble() ?? 0.0,
    deltavalue: (json["deltavalue"] as num?)?.toDouble() ?? 0.0,
    count: (json["count"] as num?)?.toInt(),
    transactions:
        json["transactions"] != null
            ? List<List<dynamic>>.from(
              (json["transactions"] as List).map((x) => List<dynamic>.from(x)),
            )
            : [],
  );

  Map<String, dynamic> toJson() => {
    "schemename": schemename,
    "units": units,
    "nav": nav,
    "value": value,
    "deltapercentage": deltapercentage,
    "deltavalue": deltavalue,
    "count": count,
    "transactions": transactions,
  };
}

class Profile {
  String nominee;
  String fipname;

  Profile({required this.nominee, required this.fipname});

  factory Profile.fromJson(Map<String, dynamic> json) =>
      Profile(nominee: json["nominee"] ?? "", fipname: json["fipname"] ?? "");

  Map<String, dynamic> toJson() => {"nominee": nominee, "fipname": fipname};
}
