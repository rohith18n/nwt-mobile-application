import 'package:nwt_app/utils/logger.dart';

class FamilyFinanceInvestmentsResponse {
  int statusCode;
  String message;
  FamilyFinanceInvestmentsData? data;

  FamilyFinanceInvestmentsResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyFinanceInvestmentsResponse.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsResponse(
    statusCode: json["statusCode"],
    message: json["message"],
    data:
        json["data"] != null
            ? FamilyFinanceInvestmentsData.fromJson(json["data"])
            : null,
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyFinanceInvestmentsData {
  List<FamilyFinanceInvestmentsMember> members;
  FamilyFinanceInvestmentsSummary summary;

  FamilyFinanceInvestmentsData({required this.members, required this.summary});

  factory FamilyFinanceInvestmentsData.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsData(
        members: List<FamilyFinanceInvestmentsMember>.from(
          json["members"].map(
            (x) => FamilyFinanceInvestmentsMember.fromJson(x),
          ),
        ),
        summary: FamilyFinanceInvestmentsSummary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

class FamilyFinanceInvestmentsMember {
  FamilyFinanceInvestmentsAssets assets;
  String lastname;
  String userguid;
  String firstname;

  FamilyFinanceInvestmentsMember({
    required this.assets,
    required this.lastname,
    required this.userguid,
    required this.firstname,
  });

  factory FamilyFinanceInvestmentsMember.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsMember(
        assets: FamilyFinanceInvestmentsAssets.fromJson(json["assets"]),
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

class FamilyFinanceInvestmentsAssets {
  FamilyFinanceInvestmentsEtf etf;
  FamilyFinanceInvestmentsEquity equity;
  FamilyFinanceInvestmentsMutualFunds mutualFunds;

  FamilyFinanceInvestmentsAssets({
    required this.etf,
    required this.equity,
    required this.mutualFunds,
  });

  factory FamilyFinanceInvestmentsAssets.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsAssets(
        etf: FamilyFinanceInvestmentsEtf.fromJson(json["etf"]),
        equity: FamilyFinanceInvestmentsEquity.fromJson(json["equity"]),
        mutualFunds: FamilyFinanceInvestmentsMutualFunds.fromJson(
          json["mutual_funds"],
        ),
      );

  Map<String, dynamic> toJson() => {
    "etf": etf.toJson(),
    "equity": equity.toJson(),
    "mutual_funds": mutualFunds.toJson(),
  };
}

class FamilyFinanceInvestmentsEquity {
  List<FamilyFinanceInvestmentsEquityDatum> data;
  String name;
  FamilyFinanceInvestmentsEquitySummary summary;

  FamilyFinanceInvestmentsEquity({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceInvestmentsEquity.fromJson(Map<String, dynamic> json) {
    return FamilyFinanceInvestmentsEquity(
      data: List<FamilyFinanceInvestmentsEquityDatum>.from(
        json["data"].map(
          (x) => FamilyFinanceInvestmentsEquityDatum.fromJson(x),
        ),
      ),
      name: json["name"],
      summary: FamilyFinanceInvestmentsEquitySummary.fromJson(json["summary"]),
    );
  }
  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceInvestmentsEquityDatum {
  String guid;
  String name;
  double rate;
  String type;
  double? delta;
  double? gainloss;
  double? quantity;
  String userguid;
  double? costvalue;
  double deltavalue;
  String accountguid;
  double currentmktvalue;
  double? gainlosspercentage;
  String? buydate;
  double? deltaValue;
  double? averageholdingprice;
  String? navdate;
  String? icon;
  double? xirr;

  FamilyFinanceInvestmentsEquityDatum({
    required this.guid,
    required this.name,
    required this.rate,
    required this.type,
    this.delta,
    this.gainloss,
    this.quantity,
    required this.userguid,
    this.costvalue,
    required this.deltavalue,
    required this.accountguid,
    required this.currentmktvalue,
    this.gainlosspercentage,
    this.buydate,
    this.deltaValue,
    this.averageholdingprice,
    this.navdate,
    this.icon,
    this.xirr,
  });

  factory FamilyFinanceInvestmentsEquityDatum.fromJson(
    Map<String, dynamic> json,
  ) {
    AppLogger.info("FamilyFinanceInvestmentsEquityDatum.fromJson: $json");
    return FamilyFinanceInvestmentsEquityDatum(
      guid: json["guid"],
      name: json["name"],
      rate: json["rate"]?.toDouble() ?? 0.0,
      type: json["type"] ?? "",
      delta: json["delta"]?.toDouble() ?? 0.0,
      deltaValue: json["deltavalue"]?.toDouble() ?? 0.0,
      gainloss: json["gainloss"]?.toDouble(),
      quantity: json["quantity"]?.toDouble(),
      userguid: json["userguid"],
      costvalue: json["costvalue"]?.toDouble(),
      deltavalue: json["deltavalue"]?.toDouble() ?? 0.0,
      accountguid: json["accountguid"] ?? "",
      currentmktvalue: json["currentmktvalue"]?.toDouble() ?? 0.0,
      gainlosspercentage: json["gainlosspercentage"]?.toDouble(),
      buydate: json["buydate"],
      averageholdingprice: json["averageholdingprice"]?.toDouble(),
      navdate: json["navdate"],
      icon: json["icon"],
      xirr: json["xirr"]?.toDouble(),
    );
  }
  Map<String, dynamic> toJson() => {
    "guid": guid,
    "name": name,
    "rate": rate,
    "type": type,
    "delta": delta,
    "gainloss": gainloss,
    "quantity": quantity,
    "userguid": userguid,
    "costvalue": costvalue,
    "deltavalue": deltavalue,
    "accountguid": accountguid,
    "currentmktvalue": currentmktvalue,
    "gainlosspercentage": gainlosspercentage,
  };
}

class FamilyFinanceInvestmentsEtf {
  List<FamilyFinanceInvestmentsEtfDatum> data;
  String name;
  FamilyFinanceInvestmentsSummaryClass summary;

  FamilyFinanceInvestmentsEtf({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceInvestmentsEtf.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsEtf(
        data: List<FamilyFinanceInvestmentsEtfDatum>.from(
          json["data"].map((x) => FamilyFinanceInvestmentsEtfDatum.fromJson(x)),
        ),
        name: json["name"],
        summary: FamilyFinanceInvestmentsSummaryClass.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceInvestmentsEtfDatum {
  int? id;
  double nav;
  String guid;
  String? isin;
  String name;
  String? type;
  double delta;
  double units;
  String? status;
  String? foliono;
  double? gainloss;
  String? selldate;
  String userguid;
  double? costvalue;
  DateTime createdat;
  DateTime updatedat;
  double deltavalue;
  String? accountguid;
  bool? activestate;
  DateTime lastnavdate;
  DateTime balancedatetime;
  double currentmktvalue;
  String? isindescription;

  FamilyFinanceInvestmentsEtfDatum({
    required this.id,
    required this.nav,
    required this.guid,
    required this.isin,
    required this.name,
    required this.type,
    required this.delta,
    required this.units,
    required this.status,
    required this.foliono,
    required this.gainloss,
    required this.selldate,
    required this.userguid,
    required this.costvalue,
    required this.createdat,
    required this.updatedat,
    required this.deltavalue,
    required this.accountguid,
    required this.activestate,
    required this.lastnavdate,
    required this.balancedatetime,
    required this.currentmktvalue,
    required this.isindescription,
  });

  factory FamilyFinanceInvestmentsEtfDatum.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsEtfDatum(
    id: json["id"],
    nav: json["nav"]?.toDouble(),
    guid: json["guid"],
    isin: json["isin"],
    name: json["name"],
    type: json["type"],
    delta: json["delta"]?.toDouble(),
    units: json["units"]?.toDouble(),
    status: json["status"],
    foliono: json["foliono"],
    gainloss: json["gainloss"]?.toDouble(),
    selldate: json["selldate"],
    userguid: json["userguid"],
    costvalue: json["costvalue"]?.toDouble(),
    createdat: DateTime.parse(json["createdat"]),
    updatedat: DateTime.parse(json["updatedat"]),
    deltavalue: json["deltavalue"]?.toDouble(),
    accountguid: json["accountguid"],
    activestate: json["activestate"],
    lastnavdate:
        json["lastnavdate"] != null
            ? DateTime.parse(json["lastnavdate"])
            : DateTime.now(),
    balancedatetime: DateTime.parse(json["balancedatetime"]),
    currentmktvalue: json["currentmktvalue"]?.toDouble(),
    isindescription: json["isindescription"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nav": nav,
    "guid": guid,
    "isin": isin,
    "name": name,
    "type": type,
    "delta": delta,
    "units": units,
    "status": status,
    "foliono": foliono,
    "gainloss": gainloss,
    "selldate": selldate,
    "userguid": userguid,
    "costvalue": costvalue,
    "createdat": createdat.toIso8601String(),
    "updatedat": updatedat.toIso8601String(),
    "deltavalue": deltavalue,
    "accountguid": accountguid,
    "activestate": activestate,
    "lastnavdate":
        "${lastnavdate.year.toString().padLeft(4, '0')}-${lastnavdate.month.toString().padLeft(2, '0')}-${lastnavdate.day.toString().padLeft(2, '0')}",
    "balancedatetime": balancedatetime.toIso8601String(),
    "currentmktvalue": currentmktvalue,
    "isindescription": isindescription,
  };
}

class FamilyFinanceInvestmentsSummaryClass {
  double avgnav;
  double totalsum;
  double totalunits;
  double avgcurrentvalue;

  FamilyFinanceInvestmentsSummaryClass({
    required this.avgnav,
    required this.totalsum,
    required this.totalunits,
    required this.avgcurrentvalue,
  });

  factory FamilyFinanceInvestmentsSummaryClass.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsSummaryClass(
    avgnav: json["avgnav"]?.toDouble() ?? 0.0,
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    totalunits: json["totalunits"]?.toDouble() ?? 0.0,
    avgcurrentvalue: json["avgcurrentvalue"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "avgnav": avgnav,
    "totalsum": totalsum,
    "totalunits": totalunits,
    "avgcurrentvalue": avgcurrentvalue,
  };
}

class FamilyFinanceInvestmentsEquitySummary {
  double avggain;
  double avgdelta;
  double totalsum;
  double totalgain;
  double avgcostvalue;
  double avgdeltavalue;
  double totalinvested;
  double avggainpercent;
  double avgcurrentvalue;

  FamilyFinanceInvestmentsEquitySummary({
    required this.avggain,
    required this.avgdelta,
    required this.totalsum,
    required this.totalgain,
    required this.avgcostvalue,
    required this.avgdeltavalue,
    required this.totalinvested,
    required this.avggainpercent,
    required this.avgcurrentvalue,
  });

  factory FamilyFinanceInvestmentsEquitySummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsEquitySummary(
    avggain: json["avggain"]?.toDouble() ?? 0.0,
    avgdelta: json["avgdelta"]?.toDouble() ?? 0.0,
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    totalgain: json["totalgain"]?.toDouble() ?? 0.0,
    avgcostvalue: json["avgcostvalue"]?.toDouble() ?? 0.0,
    avgdeltavalue: json["avgdeltavalue"]?.toDouble() ?? 0.0,
    totalinvested: json["totalinvested"]?.toDouble() ?? 0.0,
    avggainpercent: json["avggainpercent"]?.toDouble() ?? 0.0,
    avgcurrentvalue: json["avgcurrentvalue"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "avggain": avggain,
    "avgdelta": avgdelta,
    "totalsum": totalsum,
    "totalgain": totalgain,
    "avgcostvalue": avgcostvalue,
    "avgdeltavalue": avgdeltavalue,
    "totalinvested": totalinvested,
    "avggainpercent": avggainpercent,
    "avgcurrentvalue": avgcurrentvalue,
  };
}

class FamilyFinanceInvestmentsMutualFunds {
  List<FamilyFinanceInvestmentsMutualFundsDatum> data;
  String name;
  FamilyFinanceInvestmentsMutualFundsSummary summary;

  FamilyFinanceInvestmentsMutualFunds({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceInvestmentsMutualFunds.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsMutualFunds(
    data: List<FamilyFinanceInvestmentsMutualFundsDatum>.from(
      json["data"].map(
        (x) => FamilyFinanceInvestmentsMutualFundsDatum.fromJson(x),
      ),
    ),
    name: json["name"],
    summary: FamilyFinanceInvestmentsMutualFundsSummary.fromJson(
      json["summary"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceInvestmentsMutualFundsDatum {
  double nav;
  String guid;
  String name;
  double? gainloss;
  double? quantity;
  String userguid;
  double? costvalue;
  double? currentmktvalue;
  String isin;

  FamilyFinanceInvestmentsMutualFundsDatum({
    required this.nav,
    required this.guid,
    required this.name,
    required this.gainloss,
    required this.quantity,
    required this.userguid,
    required this.costvalue,
    required this.currentmktvalue,
    required this.isin,
  });

  factory FamilyFinanceInvestmentsMutualFundsDatum.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsMutualFundsDatum(
    nav: json["nav"]?.toDouble() ?? 0.0,
    guid: json["guid"],
    name: json["name"],
    gainloss: json["gainloss"]?.toDouble(),
    quantity: json["quantity"]?.toDouble(),
    userguid: json["userguid"],
    costvalue: json["costvalue"]?.toDouble(),
    currentmktvalue: json["currentmktvalue"]?.toDouble(),
    isin: json["isin"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "nav": nav,
    "guid": guid,
    "name": name,
    "gainloss": gainloss,
    "quantity": quantity,
    "userguid": userguid,
    "costvalue": costvalue,
    "currentmktvalue": currentmktvalue,
    "isin": isin,
  };
}

class FamilyFinanceInvestmentsMutualFundsSummary {
  double avgnav;
  double avggain;
  double totalsum;
  double totalgain;
  double avgcostvalue;
  double totalinvested;
  double avgcurrentvalue;

  FamilyFinanceInvestmentsMutualFundsSummary({
    required this.avgnav,
    required this.avggain,
    required this.totalsum,
    required this.totalgain,
    required this.avgcostvalue,
    required this.totalinvested,
    required this.avgcurrentvalue,
  });

  factory FamilyFinanceInvestmentsMutualFundsSummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceInvestmentsMutualFundsSummary(
    avgnav: json["avgnav"]?.toDouble(),
    avggain: json["avggain"]?.toDouble(),
    totalsum: json["totalsum"]?.toDouble(),
    totalgain: json["totalgain"]?.toDouble(),
    avgcostvalue: json["avgcostvalue"]?.toDouble(),
    totalinvested: json["totalinvested"]?.toDouble(),
    avgcurrentvalue: json["avgcurrentvalue"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "avgnav": avgnav,
    "avggain": avggain,
    "totalsum": totalsum,
    "totalgain": totalgain,
    "avgcostvalue": avgcostvalue,
    "totalinvested": totalinvested,
    "avgcurrentvalue": avgcurrentvalue,
  };
}

class FamilyFinanceInvestmentsSummary {
  FamilyFinanceInvestmentsSummaryClass etf;
  FamilyFinanceInvestmentsEquitySummary equity;
  FamilyFinanceInvestmentsMutualFundsSummary mutualFunds;

  FamilyFinanceInvestmentsSummary({
    required this.etf,
    required this.equity,
    required this.mutualFunds,
  });

  factory FamilyFinanceInvestmentsSummary.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsSummary(
        etf: FamilyFinanceInvestmentsSummaryClass.fromJson(json["etf"]),
        equity: FamilyFinanceInvestmentsEquitySummary.fromJson(json["equity"]),
        mutualFunds: FamilyFinanceInvestmentsMutualFundsSummary.fromJson(
          json["mutual_funds"],
        ),
      );

  Map<String, dynamic> toJson() => {
    "etf": etf.toJson(),
    "equity": equity.toJson(),
    "mutual_funds": mutualFunds.toJson(),
  };
}

class FamilyFinanceInvestmentsDeposit {
  double avgdelta;
  double totalsum;
  double avgdeltavalue;
  double avgcurrentvalue;

  FamilyFinanceInvestmentsDeposit({
    required this.avgdelta,
    required this.totalsum,
    required this.avgdeltavalue,
    required this.avgcurrentvalue,
  });

  factory FamilyFinanceInvestmentsDeposit.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceInvestmentsDeposit(
        avgdelta: json["avgdelta"]?.toDouble() ?? 0.0,
        totalsum: json["totalsum"]?.toDouble() ?? 0.0,
        avgdeltavalue: json["avgdeltavalue"]?.toDouble() ?? 0.0,
        avgcurrentvalue: json["avgcurrentvalue"]?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "avgdelta": avgdelta,
    "totalsum": totalsum,
    "avgdeltavalue": avgdeltavalue,
    "avgcurrentvalue": avgcurrentvalue,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
