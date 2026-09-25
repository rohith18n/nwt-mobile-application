class FamilyFinanceNpsResponse {
  int statusCode;
  String message;
  FamilyFinanceNpsData? data;

  FamilyFinanceNpsResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyFinanceNpsResponse.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNpsResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyFinanceNpsData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyFinanceNpsData {
  List<FamilyFinanceNpsMember> members;
  FamilyFinanceNpsSummary summary;

  FamilyFinanceNpsData({required this.members, required this.summary});

  factory FamilyFinanceNpsData.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNpsData(
        members: List<FamilyFinanceNpsMember>.from(
          json["members"].map((x) => FamilyFinanceNpsMember.fromJson(x)),
        ),
        summary: FamilyFinanceNpsSummary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

class FamilyFinanceNpsMember {
  FamilyFinanceNpsAssets assets;
  String lastname;
  String userguid;
  String firstname;

  FamilyFinanceNpsMember({
    required this.assets,
    required this.lastname,
    required this.userguid,
    required this.firstname,
  });

  factory FamilyFinanceNpsMember.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNpsMember(
        assets: FamilyFinanceNpsAssets.fromJson(json["assets"]),
        lastname: json["lastname"],
        userguid: json["userguid"],
        firstname: json["firstname"],
      );

  Map<String, dynamic> toJson() => {
    "assets": assets.toJson(),
    "lastname": lastname,
    "userguid": userguid,
    "firstname": firstname,
  };
}

class FamilyFinanceNpsAssets {
  FamilyFinanceNps nps;

  FamilyFinanceNpsAssets({required this.nps});

  factory FamilyFinanceNpsAssets.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNpsAssets(nps: FamilyFinanceNps.fromJson(json["nps"]));

  Map<String, dynamic> toJson() => {"nps": nps.toJson()};
}

class FamilyFinanceNps {
  List<FamilyFinanceNPSData> data;
  String name;
  FamilyFinanceNPSSummaryParent summary;

  FamilyFinanceNps({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceNps.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNps(
        data: List<FamilyFinanceNPSData>.from(
          json["data"].map((x) => FamilyFinanceNPSData.fromJson(x)),
        ),
        name: json["name"],
        summary: FamilyFinanceNPSSummaryParent.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceNPSSummaryParent {
  FamilyFinanceNpsSummary summary;

  FamilyFinanceNPSSummaryParent({required this.summary});

  factory FamilyFinanceNPSSummaryParent.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNPSSummaryParent(
        summary: FamilyFinanceNpsSummary.fromJson(json),
      );

  Map<String, dynamic> toJson() => {"summary": summary.toJson()};
}

class FamilyFinanceNpsSummary {
  double avgNav;
  double avgGain;
  double avgValue;
  double totalSum;
  double totalGain;
  double tier1Value;
  double tier2Value;
  double avgCostValue;

  FamilyFinanceNpsSummary({
    required this.avgNav,
    required this.avgGain,
    required this.avgValue,
    required this.totalSum,
    required this.totalGain,
    required this.tier1Value,
    required this.tier2Value,
    required this.avgCostValue,
  });

  // Getter methods to support UI code that uses lowercase property names
  double get totalsum => totalSum;
  double get tier1value => tier1Value;
  double get tier2value => tier2Value;
  double get avgnav => avgNav;
  double get avggain => avgGain;
  double get avgvalue => avgValue;
  double get totalgain => totalGain;
  double get avgcostvalue => avgCostValue;

  factory FamilyFinanceNpsSummary.fromJson(Map<String, dynamic> json) {
    // Check if the json contains the nps key directly or if it's the nps object itself
    final Map<String, dynamic> npsData =
        json.containsKey("nps") ? json["nps"] as Map<String, dynamic> : json;

    return FamilyFinanceNpsSummary(
      avgNav: npsData["avgnav"]?.toDouble() ?? 0.0,
      avgGain: npsData["avggain"]?.toDouble() ?? 0.0,
      avgValue: npsData["avgvalue"]?.toDouble() ?? 0.0,
      totalSum: npsData["totalsum"]?.toDouble() ?? 0.0,
      totalGain: npsData["totalgain"]?.toDouble() ?? 0.0,
      tier1Value: npsData["tier1value"]?.toDouble() ?? 0.0,
      tier2Value: npsData["tier2value"]?.toDouble() ?? 0.0,
      avgCostValue: npsData["avgcostvalue"]?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "nps": {
      "avgnav": avgNav,
      "avggain": avgGain,
      "avgvalue": avgValue,
      "totalsum": totalSum,
      "totalgain": totalGain,
      "tier1value": tier1Value,
      "tier2value": tier2Value,
      "avgcostvalue": avgCostValue,
    },
  };
}

class FamilyFinanceNPSData {
  Tier tier1;
  Tier tier2;

  FamilyFinanceNPSData({required this.tier1, required this.tier2});

  factory FamilyFinanceNPSData.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceNPSData(
        tier1: Tier.fromJson(json["tier1"]),
        tier2: Tier.fromJson(json["tier2"]),
      );

  Map<String, dynamic> toJson() => {
    "tier1": tier1.toJson(),
    "tier2": tier2.toJson(),
  };
}

class Tier {
  List<Fund> funds;
  double value;
  String schemetype;

  Tier({required this.funds, required this.value, required this.schemetype});

  factory Tier.fromJson(Map<String, dynamic> json) => Tier(
    funds: List<Fund>.from(json["funds"].map((x) => Fund.fromJson(x))),
    value: json["value"]?.toDouble(),
    schemetype: json["schemetype"],
  );

  Map<String, dynamic> toJson() => {
    "funds": List<dynamic>.from(funds.map((x) => x.toJson())),
    "value": value,
    "schemetype": schemetype,
  };
}

class Fund {
  int id;
  double nav;
  double units;
  double value;
  int deltavalue;
  String schemename;
  int deltapercentage;

  Fund({
    required this.id,
    required this.nav,
    required this.units,
    required this.value,
    required this.deltavalue,
    required this.schemename,
    required this.deltapercentage,
  });

  factory Fund.fromJson(Map<String, dynamic> json) => Fund(
    id: json["id"],
    nav: json["nav"]?.toDouble(),
    units: json["units"]?.toDouble(),
    value: json["value"]?.toDouble(),
    deltavalue: json["deltavalue"],
    schemename: json["schemename"],
    deltapercentage: json["deltapercentage"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nav": nav,
    "units": units,
    "value": value,
    "deltavalue": deltavalue,
    "schemename": schemename,
    "deltapercentage": deltapercentage,
  };
}
