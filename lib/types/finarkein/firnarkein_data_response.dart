class FinarkeinDataResponse {
  int statusCode;
  String message;
  FinarkeinData? data;

  bool get success => statusCode == 200 || statusCode == 201;

  FinarkeinDataResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FinarkeinDataResponse.fromJson(Map<String, dynamic> json) =>
      FinarkeinDataResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] == null ? null : FinarkeinData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FinarkeinData {
  Map<String, double?> summary;
  Gainsbyasset gainsbyasset;
  Details details;
  AaData aaData;
  Meta meta;

  FinarkeinData({
    required this.summary,
    required this.gainsbyasset,
    required this.details,
    required this.aaData,
    required this.meta,
  });

  factory FinarkeinData.fromJson(Map<String, dynamic> json) {
    // Collect all asset-specific keys (*.summary, *.transactions, *.holders)
    // from both top-level and 'aaData' object.
    final assetData = <String, dynamic>{};
    final aaDataJson = json["aaData"];
    if (aaDataJson is Map<String, dynamic>) {
      assetData.addAll(aaDataJson);
    }
    for (final entry in json.entries) {
      final k = entry.key;
      if (k.endsWith(".summary") ||
          k.endsWith(".transactions") ||
          k.endsWith(".holders")) {
        assetData[k] = entry.value;
      }
    }

    return FinarkeinData(
      summary:
          json["summary"] == null
              ? {}
              : Map.from(
                json["summary"],
              ).map((k, v) => MapEntry<String, double?>(k, v?.toDouble())),
      gainsbyasset: Gainsbyasset.fromJson(json["gainsbyasset"] ?? {}),
      details: Details.fromJson(json["details"] ?? {}),
      aaData: AaData.fromJson(assetData),
      meta: Meta.fromJson(json["meta"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "summary": Map.from(
        summary,
      ).map((k, v) => MapEntry<String, dynamic>(k, v)),
      "gainsbyasset": gainsbyasset.toJson(),
      "details": details.toJson(),
      "meta": meta.toJson(),
    };
    // Merge all asset keys from aaData into the top level to match API structure
    map.addAll(aaData.allData);
    return map;
  }
}

class AaData {
  final Map<String, List<List<dynamic>>> allData;

  AaData({required this.allData});

  factory AaData.fromJson(Map<String, dynamic> json) {
    final all = <String, List<List<dynamic>>>{};
    for (final entry in json.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v is List) {
        all[k] = List<List<dynamic>>.from(
          v.map((x) => x is List ? List<dynamic>.from(x) : []),
        );
      }
    }
    return AaData(allData: all);
  }

  Map<String, dynamic> toJson() => allData;

  // Compatibility getters for existing code if any (though grep showed none)
  List<List<dynamic>> get equitiesSummary => allData["equities.summary"] ?? [];
  List<List<dynamic>> get depositSummary => allData["deposit.summary"] ?? [];
  List<List<dynamic>> get mutualFundsSummary =>
      allData["mutual_funds.summary"] ?? [];
}

class Details {
  List<Mf> mf;
  List<Equity> equities;
  List<dynamic> etf;
  Map<String, int>? transactioncount;

  Details({
    required this.mf,
    required this.equities,
    required this.etf,
    this.transactioncount,
  });

  factory Details.fromJson(Map<String, dynamic> json) => Details(
    mf: List<Mf>.from((json["mf"] ?? []).map((x) => Mf.fromJson(x))),
    equities: List<Equity>.from(
      (json["equities"] ?? []).map((x) => Equity.fromJson(x)),
    ),
    etf: List<dynamic>.from((json["etf"] ?? []).map((x) => x)),
    transactioncount: json["transactioncount"] != null
        ? Map<String, int>.from(json["transactioncount"].map(
            (k, v) => MapEntry(k.toString(), (v is int) ? v : (v?.toInt() ?? 0)),
          ))
        : null,
  );

  Map<String, dynamic> toJson() => {
    "mf": List<dynamic>.from(mf.map((x) => x.toJson())),
    "equities": List<dynamic>.from(equities.map((x) => x.toJson())),
    "etf": List<dynamic>.from(etf.map((x) => x)),
    if (transactioncount != null) "transactioncount": transactioncount,
  };
}

class Equity {
  String accountguid;
  dynamic fipname;
  String isin;
  String name;
  double? quantity;
  double? rate;
  dynamic investedamount;
  double? currentvalue;
  dynamic gain;
  dynamic gainpercentage;
  dynamic totalgain;
  dynamic totalgainpercentage;
  double? dailygain;
  double? dailygainpercentage;
  double? xirr;
  dynamic investedderived;
  dynamic lasttransactiondate;
  dynamic icon;
  String issuername;
  int? count;
  String? broker;
  String? brokername;
  String? fipid;

  Equity({
    required this.accountguid,
    required this.fipname,
    required this.isin,
    required this.name,
    this.quantity,
    this.rate,
    required this.investedamount,
    this.currentvalue,
    required this.gain,
    required this.gainpercentage,
    required this.totalgain,
    required this.totalgainpercentage,
    this.dailygain,
    this.dailygainpercentage,
    this.xirr,
    required this.investedderived,
    required this.lasttransactiondate,
    required this.icon,
    required this.issuername,
    this.count,
    this.broker,
    this.brokername,
    this.fipid,
  });

  factory Equity.fromJson(Map<String, dynamic> json) => Equity(
    accountguid: json["accountguid"],
    fipname: json["fipname"],
    isin: json["isin"],
    name: json["name"],
    quantity: json["quantity"]?.toDouble(),
    rate: json["rate"]?.toDouble(),
    investedamount: json["investedamount"],
    currentvalue: json["currentvalue"]?.toDouble(),
    gain: json["gain"],
    gainpercentage: json["gainpercentage"],
    totalgain: json["totalgain"],
    totalgainpercentage: json["totalgainpercentage"],
    dailygain: json["dailygain"]?.toDouble(),
    dailygainpercentage: json["dailygainpercentage"]?.toDouble(),
    xirr: json["xirr"]?.toDouble(),
    investedderived: json["investedderived"],
    lasttransactiondate: json["lasttransactiondate"],
    icon: json["icon"],
    issuername: json["issuername"],
    count: json["count"]?.toInt(),
    broker: json["broker"] ?? json["fipid"] ?? json["fipname"],
    brokername: json["brokername"] ?? json["fipname"] ?? json["fipid"],
    fipid: json["fipid"],
  );

  Map<String, dynamic> toJson() => {
    "accountguid": accountguid,
    "fipname": fipname,
    "isin": isin,
    "name": name,
    "quantity": quantity,
    "rate": rate,
    "investedamount": investedamount,
    "currentvalue": currentvalue,
    "gain": gain,
    "gainpercentage": gainpercentage,
    "totalgain": totalgain,
    "totalgainpercentage": totalgainpercentage,
    "dailygain": dailygain,
    "dailygainpercentage": dailygainpercentage,
    "xirr": xirr,
    "investedderived": investedderived,
    "lasttransactiondate": lasttransactiondate,
    "icon": icon,
    "issuername": issuername,
    "count": count,
    "broker": broker,
    "brokername": brokername,
    "fipid": fipid,
  };
}

class Mf {
  String accountguid;
  String fipname;
  String isin;
  String name;
  String folio;
  String schemecode;
  double units;
  double investedamount;
  double currentvalue;
  double gain;
  double gainpercentage;
  double? totalgain;
  double? totalgainpercentage;
  double? dailygain;
  double? dailygainpercentage;
  double? xirr;
  bool investedderived;
  double? avgbuyprice;
  int? count;

  Mf({
    required this.accountguid,
    required this.fipname,
    required this.isin,
    required this.name,
    required this.folio,
    required this.schemecode,
    required this.units,
    required this.investedamount,
    required this.currentvalue,
    required this.gain,
    required this.gainpercentage,
    this.totalgain,
    this.totalgainpercentage,
    this.dailygain,
    this.dailygainpercentage,
    this.xirr,
    required this.investedderived,
    this.avgbuyprice,
    this.count,
  });

  factory Mf.fromJson(Map<String, dynamic> json) => Mf(
    accountguid: json["accountguid"] ?? '',
    fipname: json["fipname"] ?? '',
    isin: json["isin"] ?? '',
    name: json["name"] ?? '',
    folio: json["folio"] ?? '',
    schemecode: json["schemecode"] ?? '',
    units: json["units"]?.toDouble() ?? 0.0,
    investedamount: json["investedamount"]?.toDouble() ?? 0.0,
    currentvalue: json["currentvalue"]?.toDouble() ?? 0.0,
    gain: json["gain"]?.toDouble() ?? 0.0,
    gainpercentage: json["gainpercentage"]?.toDouble() ?? 0.0,
    totalgain: json["totalgain"]?.toDouble(),
    totalgainpercentage: json["totalgainpercentage"]?.toDouble(),
    dailygain: json["dailygain"]?.toDouble(),
    dailygainpercentage: json["dailygainpercentage"]?.toDouble(),
    xirr: json["xirr"]?.toDouble(),
    investedderived: json["investedderived"] ?? false,
    avgbuyprice: json["avgbuyprice"]?.toDouble(),
    count: json["count"]?.toInt() ?? json["transactioncount"]?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "accountguid": accountguid,
    "fipname": fipname,
    "isin": isin,
    "name": name,
    "folio": folio,
    "schemecode": schemecode,
    "units": units,
    "investedamount": investedamount,
    "currentvalue": currentvalue,
    "gain": gain,
    "gainpercentage": gainpercentage,
    "totalgain": totalgain,
    "totalgainpercentage": totalgainpercentage,
    "dailygain": dailygain,
    "dailygainpercentage": dailygainpercentage,
    "xirr": xirr,
    "investedderived": investedderived,
    "avgbuyprice": avgbuyprice,
    "count": count,
  };
}

class Gainsbyasset {
  Bank mf;
  Bank equities;
  Bank etf;
  Bank bank;
  Bank nps;
  Bank insurance;

  Gainsbyasset({
    required this.mf,
    required this.equities,
    required this.etf,
    required this.bank,
    required this.nps,
    required this.insurance,
  });

  factory Gainsbyasset.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Gainsbyasset(
      mf: Bank.fromJson(json["mf"] ?? {}),
      equities: Bank.fromJson(json["equities"] ?? {}),
      etf: Bank.fromJson(json["etf"] ?? {}),
      bank: Bank.fromJson(json["bank"] ?? {}),
      nps: Bank.fromJson(json["nps"] ?? {}),
      insurance: Bank.fromJson(json["insurance"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "mf": mf.toJson(),
    "equities": equities.toJson(),
    "etf": etf.toJson(),
    "bank": bank.toJson(),
    "nps": nps.toJson(),
    "insurance": insurance.toJson(),
  };
}

class Bank {
  double? investedamount;
  double? currentvalue;
  double? gain;
  double? gainpercentage;
  double? totalgain;
  double? totalgainpercentage;
  double dailygain;
  double dailygainpercentage;
  double? unrealisedgain;
  dynamic realisedgain;
  double xirr;
  double? allocationpercentage;
  double accountcount;
  BankCoverage coverage;

  Bank({
    required this.investedamount,
    required this.currentvalue,
    required this.gain,
    required this.gainpercentage,
    required this.totalgain,
    required this.totalgainpercentage,
    required this.dailygain,
    required this.dailygainpercentage,
    required this.unrealisedgain,
    required this.realisedgain,
    required this.xirr,
    required this.allocationpercentage,
    required this.accountcount,
    required this.coverage,
  });

  factory Bank.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Bank(
      investedamount: json["investedamount"]?.toDouble(),
      currentvalue: json["currentvalue"]?.toDouble(),
      gain: json["gain"]?.toDouble(),
      gainpercentage: json["gainpercentage"]?.toDouble(),
      totalgain: json["totalgain"]?.toDouble(),
      totalgainpercentage: json["totalgainpercentage"]?.toDouble(),
      dailygain: json["dailygain"]?.toDouble() ?? 0.0,
      dailygainpercentage: json["dailygainpercentage"]?.toDouble() ?? 0.0,
      unrealisedgain: json["unrealisedgain"]?.toDouble(),
      realisedgain: json["realisedgain"],
      xirr: json["xirr"]?.toDouble() ?? 0.0,
      allocationpercentage: json["allocationpercentage"]?.toDouble(),
      accountcount: json["accountcount"]?.toDouble() ?? 0.0,
      coverage: BankCoverage.fromJson(json["coverage"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "investedamount": investedamount,
    "currentvalue": currentvalue,
    "gain": gain,
    "gainpercentage": gainpercentage,
    "totalgain": totalgain,
    "totalgainpercentage": totalgainpercentage,
    "dailygain": dailygain,
    "dailygainpercentage": dailygainpercentage,
    "unrealisedgain": unrealisedgain,
    "realisedgain": realisedgain,
    "xirr": xirr,
    "allocationpercentage": allocationpercentage,
    "accountcount": accountcount,
    "coverage": coverage.toJson(),
  };
}

class BankCoverage {
  double holdingsWithCost;
  double holdingsTotal;
  double accountsWithHoldings;
  bool usedSummaryFallbackForCurrentValue;
  bool investedDerived;

  BankCoverage({
    required this.holdingsWithCost,
    required this.holdingsTotal,
    required this.accountsWithHoldings,
    required this.usedSummaryFallbackForCurrentValue,
    required this.investedDerived,
  });

  factory BankCoverage.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return BankCoverage(
      holdingsWithCost: json["holdingsWithCost"]?.toDouble() ?? 0.0,
      holdingsTotal: json["holdingsTotal"]?.toDouble() ?? 0.0,
      accountsWithHoldings: json["accountsWithHoldings"]?.toDouble() ?? 0.0,
      usedSummaryFallbackForCurrentValue:
          json["usedSummaryFallbackForCurrentValue"] ?? false,
      investedDerived: json["investedDerived"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "holdingsWithCost": holdingsWithCost,
    "holdingsTotal": holdingsTotal,
    "accountsWithHoldings": accountsWithHoldings,
    "usedSummaryFallbackForCurrentValue": usedSummaryFallbackForCurrentValue,
    "investedDerived": investedDerived,
  };
}

class Meta {
  double activeconsents;
  double totalaccounts;
  DateTime generatedat;
  String calculationVersion;
  String calculationBasis;
  bool isAuditGrade;
  List<String> pendingMetrics;
  MetaCoverage coverage;

  Meta({
    required this.activeconsents,
    required this.totalaccounts,
    required this.generatedat,
    required this.calculationVersion,
    required this.calculationBasis,
    required this.isAuditGrade,
    required this.pendingMetrics,
    required this.coverage,
  });

  factory Meta.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Meta(
      activeconsents: json["activeconsents"]?.toDouble() ?? 0.0,
      totalaccounts: json["totalaccounts"]?.toDouble() ?? 0.0,
      generatedat:
          json["generatedat"] != null
              ? DateTime.parse(json["generatedat"])
              : DateTime.now(),
      calculationVersion: json["calculationVersion"] ?? "",
      calculationBasis: json["calculationBasis"] ?? "",
      isAuditGrade: json["isAuditGrade"] ?? false,
      pendingMetrics: List<String>.from(
        (json["pendingMetrics"] ?? []).map((x) => x),
      ),
      coverage: MetaCoverage.fromJson(json["coverage"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "activeconsents": activeconsents,
    "totalaccounts": totalaccounts,
    "generatedat": generatedat.toIso8601String(),
    "calculationVersion": calculationVersion,
    "calculationBasis": calculationBasis,
    "isAuditGrade": isAuditGrade,
    "pendingMetrics": List<dynamic>.from(pendingMetrics.map((x) => x)),
    "coverage": coverage.toJson(),
  };
}

class MetaCoverage {
  double holdingsWithCost;
  double holdingsTotal;
  double accountsWithHoldings;
  double accountsTotal;

  MetaCoverage({
    required this.holdingsWithCost,
    required this.holdingsTotal,
    required this.accountsWithHoldings,
    required this.accountsTotal,
  });

  factory MetaCoverage.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return MetaCoverage(
      holdingsWithCost: json["holdingsWithCost"]?.toDouble() ?? 0.0,
      holdingsTotal: json["holdingsTotal"]?.toDouble() ?? 0.0,
      accountsWithHoldings: json["accountsWithHoldings"]?.toDouble() ?? 0.0,
      accountsTotal: json["accountsTotal"]?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "holdingsWithCost": holdingsWithCost,
    "holdingsTotal": holdingsTotal,
    "accountsWithHoldings": accountsWithHoldings,
    "accountsTotal": accountsTotal,
  };
}
