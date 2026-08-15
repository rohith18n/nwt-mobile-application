class TaxAdvisoryResponse {
  int statusCode;
  String message;
  Data? taxAdvisoryResponseData;
  bool get success => statusCode == 200 || statusCode == 201;

  TaxAdvisoryResponse({
    required this.statusCode,
    required this.message,
    this.taxAdvisoryResponseData,
  });

  factory TaxAdvisoryResponse.fromJson(Map<String, dynamic> json) =>
      TaxAdvisoryResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        taxAdvisoryResponseData:
            json["data"] != null ? Data.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": taxAdvisoryResponseData?.toJson(),
  };
}

class Data {
  Shortterm shortterm;
  Longterm longterm;
  Total total;
  List<Detail> details;
  AdjustmentDetails adjustmentDetails;

  Data({
    required this.shortterm,
    required this.longterm,
    required this.total,
    required this.details,
    required this.adjustmentDetails,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    shortterm: Shortterm.fromJson(json["shortterm"]),
    longterm: Longterm.fromJson(json["longterm"]),
    total: Total.fromJson(json["total"]),
    details: List<Detail>.from(json["details"].map((x) => Detail.fromJson(x))),
    adjustmentDetails: AdjustmentDetails.fromJson(json["adjustmentDetails"]),
  );

  Map<String, dynamic> toJson() => {
    "shortterm": shortterm.toJson(),
    "longterm": longterm.toJson(),
    "total": total.toJson(),
    "details": List<dynamic>.from(details.map((x) => x.toJson())),
    "adjustmentDetails": adjustmentDetails.toJson(),
  };
}

class AdjustmentDetails {
  double totallosses;
  double adjustmentamount;
  double remaininglossesforoffset;
  bool istaxadjustable;
  double slabrate;

  AdjustmentDetails({
    required this.totallosses,
    required this.adjustmentamount,
    required this.remaininglossesforoffset,
    required this.istaxadjustable,
    required this.slabrate,
  });

  factory AdjustmentDetails.fromJson(Map<String, dynamic> json) =>
      AdjustmentDetails(
        totallosses: json["totallosses"].toDouble(),
        adjustmentamount: json["adjustmentamount"].toDouble(),
        remaininglossesforoffset: json["remaininglossesforoffset"].toDouble(),
        istaxadjustable: json["istaxadjustable"],
        slabrate: json["slabrate"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "totallosses": totallosses,
    "adjustmentamount": adjustmentamount,
    "remaininglossesforoffset": remaininglossesforoffset,
    "istaxadjustable": istaxadjustable,
    "slabrate": slabrate,
  };
}

class Detail {
  String fundname;
  String isin;
  String icon;
  double marketvalue;
  double investedvalue;
  double totalgain;
  double totalgainpct;
  FundBreakDown breakdown;

  Detail({
    required this.fundname,
    required this.isin,
    required this.icon,
    required this.marketvalue,
    required this.investedvalue,
    required this.totalgain,
    required this.totalgainpct,
    required this.breakdown,
  });

  factory Detail.fromJson(Map<String, dynamic> json) => Detail(
    fundname: json["fundname"],
    isin: json["isin"],
    icon: json["icon"],
    marketvalue: json["marketvalue"].toDouble(),
    investedvalue: json["investedvalue"].toDouble(),
    totalgain: json["totalgain"].toDouble(),
    totalgainpct: json["totalgainpct"]?.toDouble(),
    breakdown: FundBreakDown.fromJson(json["breakdown"]),
  );

  Map<String, dynamic> toJson() => {
    "fundname": fundname,
    "isin": isin,
    "icon": icon,
    "marketvalue": marketvalue,
    "investedvalue": investedvalue,
    "totalgain": totalgain,
    "totalgainpct": totalgainpct,
    "breakdown": breakdown.toJson(),
  };
}

class FundBreakDown {
  BreakdownValue ltcg;
  BreakdownValue stcg;

  FundBreakDown({
    required this.ltcg,
    required this.stcg,
  });

  factory FundBreakDown.fromJson(Map<String, dynamic> json) => FundBreakDown(
    ltcg: BreakdownValue.fromJson(json["ltcg"]),
    stcg: BreakdownValue.fromJson(json["stcg"]),
  );

  Map<String, dynamic> toJson() => {
    "ltcg": ltcg.toJson(),
    "stcg": stcg.toJson(),
  };
}

class BreakdownValue {
  double amount;
  double taxrate;
  double taxpayable;

  BreakdownValue({
    required this.amount,
    required this.taxrate,
    required this.taxpayable,
  });

  factory BreakdownValue.fromJson(Map<String, dynamic> json) => BreakdownValue(
    amount: json["amount"].toDouble(),
    taxrate: json["taxrate"].toDouble(),
    taxpayable: json["taxpayable"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "taxrate": taxrate,
    "taxpayable": taxpayable,
  };
}

class Longterm {
  String label;
  double gain;
  double gainwithoutadjustment;
  double taxpayable;
  double taxrate;
  double equitytaxrate;
  double debttaxrate;
  double taxondebt;
  double taxonequity;
  String assettype;
  bool isexemptionallowed;
  double exemptionapplied;
  double exemptionlimit;

  Longterm({
    required this.label,
    required this.gain,
    required this.gainwithoutadjustment,
    required this.taxpayable,
    required this.taxrate,
    required this.equitytaxrate,
    required this.debttaxrate,
    required this.taxondebt,
    required this.taxonequity,
    required this.assettype,
    required this.isexemptionallowed,
    required this.exemptionapplied,
    required this.exemptionlimit,
  });

  factory Longterm.fromJson(Map<String, dynamic> json) => Longterm(
    label: json["label"],
    gain: json["gain"].toDouble(),
    gainwithoutadjustment: json["gainwithoutadjustment"].toDouble(),
    taxpayable: json["taxpayable"].toDouble(),
    taxrate: json["taxrate"].toDouble(),
    equitytaxrate: json["equitytaxrate"].toDouble(),
    debttaxrate: json["debttaxrate"].toDouble(),
    taxondebt: json["taxondebt"].toDouble(),
    taxonequity: json["taxonequity"].toDouble(),
    assettype: json["assettype"],
    isexemptionallowed: json["isexemptionallowed"],
    exemptionapplied: json["exemptionapplied"].toDouble(),
    exemptionlimit: json["exemptionlimit"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "label": label,
    "gain": gain,
    "gainwithoutadjustment": gainwithoutadjustment,
    "taxpayable": taxpayable,
    "taxrate": taxrate,
    "equitytaxrate": equitytaxrate,
    "debttaxrate": debttaxrate,
    "taxondebt": taxondebt,
    "taxonequity": taxonequity,
    "assettype": assettype,
    "isexemptionallowed": isexemptionallowed,
    "exemptionapplied": exemptionapplied,
    "exemptionlimit": exemptionlimit,
  };
}

class Shortterm {
  String label;
  double gain;
  double gainwithoutadjustment;
  double taxpayable;
  double equitytaxrate;
  double debttaxrate;
  double taxondebt;
  double taxonequity;

  Shortterm({
    required this.label,
    required this.gain,
    required this.gainwithoutadjustment,
    required this.taxpayable,
    required this.equitytaxrate,
    required this.debttaxrate,
    required this.taxondebt,
    required this.taxonequity,
  });

  factory Shortterm.fromJson(Map<String, dynamic> json) => Shortterm(
    label: json["label"],
    gain: json["gain"].toDouble(),
    gainwithoutadjustment: json["gainwithoutadjustment"].toDouble(),
    taxpayable: json["taxpayable"].toDouble(),
    equitytaxrate: json["equitytaxrate"].toDouble(),
    debttaxrate: json["debttaxrate"].toDouble(),
    taxondebt: json["taxondebt"].toDouble(),
    taxonequity: json["taxonequity"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "label": label,
    "gain": gain,
    "gainwithoutadjustment": gainwithoutadjustment,
    "taxpayable": taxpayable,
    "equitytaxrate": equitytaxrate,
    "debttaxrate": debttaxrate,
    "taxondebt": taxondebt,
    "taxonequity": taxonequity,
  };
}

class Total {
  String label;
  double gain;
  double gainwithoutadjustment;
  double taxpayable;
  TotalBreakdown breakdown;

  Total({
    required this.label,
    required this.gain,
    required this.gainwithoutadjustment,
    required this.taxpayable,
    required this.breakdown,
  });

  factory Total.fromJson(Map<String, dynamic> json) => Total(
    label: json["label"],
    gain: json["gain"].toDouble(),
    gainwithoutadjustment: json["gainwithoutadjustment"].toDouble(),
    taxpayable: json["taxpayable"].toDouble(),
    breakdown: TotalBreakdown.fromJson(json["breakdown"]),
  );

  Map<String, dynamic> toJson() => {
    "label": label,
    "gain": gain,
    "gainwithoutadjustment": gainwithoutadjustment,
    "taxpayable": taxpayable,
    "breakdown": breakdown.toJson(),
  };
}

class TotalBreakdown {
  BreakdownType equity;
  BreakdownType debt;

  TotalBreakdown({required this.equity, required this.debt});

  factory TotalBreakdown.fromJson(Map<String, dynamic> json) => TotalBreakdown(
    equity: BreakdownType.fromJson(json["equity"]),
    debt: BreakdownType.fromJson(json["debt"]),
  );

  Map<String, dynamic> toJson() => {
    "equity": equity.toJson(),
    "debt": debt.toJson(),
  };
}

class BreakdownType {
  double gain;
  double taxpayable;

  BreakdownType({required this.gain, required this.taxpayable});

  factory BreakdownType.fromJson(Map<String, dynamic> json) => BreakdownType(
    gain: json["gain"].toDouble(),
    taxpayable: json["taxpayable"].toDouble(),
  );

  Map<String, dynamic> toJson() => {"gain": gain, "taxpayable": taxpayable};
}
