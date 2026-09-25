class MutualFundInsightRespose {
  int status;
  String message;
  InsightsSummary? data;

  MutualFundInsightRespose({
    required this.status,
    required this.message,
    this.data,
  });

  factory MutualFundInsightRespose.fromJson(
    Map<String, dynamic> json,
  ) {
    // Robustly extract status
    int status = 0;
    if (json["statusCode"] != null) status = json["statusCode"] as int;
    else if (json["status"] != null) status = json["status"] as int;
    else if (json["success"] == true) status = 200;
    else status = 400;

    return MutualFundInsightRespose(
      status: status,
      message: json["message"] ?? "",
      data: json["data"] != null ? InsightsSummary.fromJson(json["data"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class InsightsSummary {
  String? objective;
  String? icon;
  String? sebicategoryname;
  String? schemeCode;
  String fundname;
  String fundtype;
  double nav;
  double navdelta;
  FundReturns returns;
  Mfreturnandsipreturn mfreturnandsipreturn;
  Funddetail funddetail;
  Assetallocation assetallocation;
  Sipdetail sipdetail;
  Funddistributionequity funddistributionequity;
  Funddistributiondebtcash funddistributiondebtcash;
  Sectorallocation sectorallocation;
  List<Dividendhistory> dividendhistory;
  List<TopHoldings> topHoldings;
  Riskometer riskometer;
  int? categoryrank;
  int? categorytotal;

  InsightsSummary({
    this.objective,
    this.icon,
    this.sebicategoryname,
    this.schemeCode,
    required this.fundname,
    required this.fundtype,
    required this.nav,
    required this.navdelta,
    required this.returns,
    required this.mfreturnandsipreturn,
    required this.funddetail,
    required this.assetallocation,
    required this.sipdetail,
    required this.funddistributionequity,
    required this.funddistributiondebtcash,
    required this.sectorallocation,
    required this.dividendhistory,
    required this.topHoldings,
    required this.riskometer,
    this.categoryrank,
    this.categorytotal,
  });

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      InsightsSummary(
        objective: json["objective"] ?? "",
        icon: json["icon"],
        sebicategoryname: json["sebicategoryname"] ?? json["scheme_category"],
        schemeCode: json["scheme_code"],
        fundname: json["fundname"] ?? json["scheme_name"] ?? json["name"] ?? "Unknown Fund",
        fundtype: json["fundtype"] ?? json["scheme_type"] ?? "",
        nav: (json["nav"] ?? json["latest_nav"])?.toDouble() ?? 0.0,
        navdelta: json["navdelta"]?.toDouble() ?? 0.0,
        returns: FundReturns.fromJson(json["returns"] ?? {}),
        mfreturnandsipreturn: Mfreturnandsipreturn.fromJson(
          json["mfreturnandsipreturn"] ?? {},
        ),
        funddetail: Funddetail.fromJson(json["funddetail"] ?? {}),
        assetallocation: Assetallocation.fromJson(json["assetallocation"] ?? {}),
        sipdetail: Sipdetail.fromJson(json["sipdetail"] ?? json["sip_limits"] ?? {}),
        funddistributionequity: Funddistributionequity.fromJson(
          json["funddistributionequity"] ?? {},
        ),
        funddistributiondebtcash: Funddistributiondebtcash.fromJson(
          json["funddistributiondebtcash"] ?? {},
        ),
        sectorallocation: Sectorallocation.fromJson(
          (json["sectorallocation"] ?? []) as List<dynamic>,
        ),
        dividendhistory: List<Dividendhistory>.from(
          json["dividendhistory"] != null
              ? json["dividendhistory"].map((x) => Dividendhistory.fromJson(x))
              : [],
        ),
        topHoldings:
            json["topholding"] != null
                ? List<TopHoldings>.from(
                  json["topholding"].map((x) => TopHoldings.fromJson(x)),
                )
                : [],
        riskometer: Riskometer.fromJson(json["riskometer"] ?? {"name": "Moderate"}),
        categoryrank: json["categoryrank"],
        categorytotal: json["categorytotal"],
      );

  Map<String, dynamic> toJson() => {
    "objective": objective,
    "icon": icon,
    "fundname": fundname,
    "fundtype": fundtype,
    "nav": nav,
    "navdelta": navdelta,
    "returns": returns.toJson(),
    "mfreturnandsipreturn": mfreturnandsipreturn.toJson(),
    "funddetail": funddetail.toJson(),
    "assetallocation": assetallocation.toJson(),
    "sipdetail": sipdetail.toJson(),
    "funddistributionequity": funddistributionequity.toJson(),
    "funddistributiondebtcash": funddistributiondebtcash.toJson(),
    "sectorallocation": sectorallocation.toJson(),
    "dividendhistory": List<dynamic>.from(
      dividendhistory.map((x) => x.toJson()),
    ),
    "topholding": List<dynamic>.from(topHoldings.map((x) => x.toJson())),
    "riskometer": riskometer.toJson(),
  };
}

class Assetallocation {
  double equity;
  double debt;
  double hybrid;

  Assetallocation({
    required this.equity,
    required this.debt,
    required this.hybrid,
  });

  factory Assetallocation.fromJson(Map<String, dynamic> json) =>
      Assetallocation(
        equity: json["equity"]?.toDouble() ?? 0.0,
        debt: json["debt"]?.toDouble() ?? 0.0,
        hybrid: json["hybrid"]?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "equity": equity,
    "debt": debt,
    "hybrid": hybrid,
  };
}

class Dividendhistory {
  DateTime recorddate;
  double dividend;

  Dividendhistory({required this.recorddate, required this.dividend});

  factory Dividendhistory.fromJson(Map<String, dynamic> json) =>
      Dividendhistory(
        recorddate: json["recorddate"] != null ? DateTime.parse(json["recorddate"]) : DateTime.now(),
        dividend: (json["dividend"] ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "recorddate":
        "${recorddate.year.toString().padLeft(4, '0')}-${recorddate.month.toString().padLeft(2, '0')}-${recorddate.day.toString().padLeft(2, '0')}",
    "dividend": dividend,
  };
}

class Funddetail {
  double expenseratio;
  double churn;
  String investmentstyle;
  List<FundManager> fundmanager;
  String aum;
  String exitload;

  Funddetail({
    required this.expenseratio,
    required this.churn,
    required this.investmentstyle,
    required this.fundmanager,
    required this.aum,
    required this.exitload,
  });

  factory Funddetail.fromJson(Map<String, dynamic> json) => Funddetail(
    expenseratio: (json["expenseratio"] ?? 0.0).toDouble(),
    churn: (json["churn"] ?? 0.0).toDouble(),
    investmentstyle: json["investmentstyle"] ?? "",
    fundmanager: json["fundmanager"] != null 
      ? List<FundManager>.from(json["fundmanager"].map((x) => FundManager.fromJson(x)))
      : [],
    aum: json["aum"]?.toString() ?? "",
    exitload: json["exitload"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "expenseratio": expenseratio,
    "churn": churn,
    "investmentstyle": investmentstyle,
    "fundmanager": List<dynamic>.from(fundmanager.map((x) => x.toJson())),
    "aum": aum,
    "exitload": exitload,
  };
}

class Funddistributiondebtcash {
  double aaa;

  Funddistributiondebtcash({required this.aaa});

  factory Funddistributiondebtcash.fromJson(Map<String, dynamic> json) =>
      Funddistributiondebtcash(aaa: json["aaa"]?.toDouble() ?? 0.0);

  Map<String, dynamic> toJson() => {"aaa": aaa};
}

class Funddistributionequity {
  double midcap;
  double largecap;
  double smallcap;

  Funddistributionequity({
    required this.midcap,
    required this.largecap,
    required this.smallcap,
  });

  factory Funddistributionequity.fromJson(Map<String, dynamic> json) =>
      Funddistributionequity(
        midcap: json["midcap"]?.toDouble() ?? 0.0,
        largecap: json["largecap"]?.toDouble() ?? 0.0,
        smallcap: json["smallcap"]?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    "midcap": midcap,
    "largecap": largecap,
    "smallcap": smallcap,
  };
}

class Mfreturnandsipreturn {
  Return mfreturnandsipreturnReturn;
  // Return sipreturn;

  Mfreturnandsipreturn({
    required this.mfreturnandsipreturnReturn,
    // required this.sipreturn,
  });

  factory Mfreturnandsipreturn.fromJson(Map<String, dynamic> json) =>
      Mfreturnandsipreturn(
        mfreturnandsipreturnReturn: Return.fromJson(json["return"] ?? {}),
        // sipreturn: Return.fromJson(json["sipreturn"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
    "return": mfreturnandsipreturnReturn.toJson(),
    // "sipreturn": sipreturn.toJson(),
  };
}

class Return {
  List<MFPerformanceDataPoint> oneMonth;
  List<MFPerformanceDataPoint> threeMonths;
  List<MFPerformanceDataPoint> sixMonths;
  List<MFPerformanceDataPoint> oneYear;
  List<MFPerformanceDataPoint> threeYears;
  List<MFPerformanceDataPoint> fiveYears;
  List<MFPerformanceDataPoint> tenYears;
  List<MFPerformanceDataPoint> all;

  Return({
    required this.oneMonth,
    required this.threeMonths,
    required this.sixMonths,
    required this.oneYear,
    required this.threeYears,
    required this.fiveYears,
    required this.tenYears,
    required this.all,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      oneMonth:
          json["1m"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["1m"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      threeMonths:
          json["3m"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["3m"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      sixMonths:
          json["6m"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["6m"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      oneYear:
          json["1y"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["1y"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      threeYears:
          json["3y"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["3y"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      fiveYears:
          json["5y"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["5y"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      tenYears:
          json["10y"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["10y"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
      all:
          json["all"] == null
              ? []
              : List<MFPerformanceDataPoint>.from(
                json["all"].map((x) => MFPerformanceDataPoint.fromJson(x)),
              ),
    );
  }

  Map<String, dynamic> toJson() => {
    "1m": List<dynamic>.from(oneMonth.map((x) => x.toJson())),
    "3m": List<dynamic>.from(threeMonths.map((x) => x.toJson())),
    "6m": List<dynamic>.from(sixMonths.map((x) => x.toJson())),
    "1y": List<dynamic>.from(oneYear.map((x) => x.toJson())),
    "5y": List<dynamic>.from(fiveYears.map((x) => x.toJson())),
    "10y": List<dynamic>.from(tenYears.map((x) => x.toJson())),
    "all": all.map((x) => x.toJson()),
  };
}

class MFPerformanceDataPoint {
  String date;
  double value;

  MFPerformanceDataPoint({required this.date, required this.value});

  factory MFPerformanceDataPoint.fromJson(Map<String, dynamic> json) =>
      MFPerformanceDataPoint(
        date: json["date"] ?? "",
        value: (json["value"] ?? 0.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {"date": date, "value": value};
}

class Riskometer {
  String name;

  Riskometer({required this.name});

  factory Riskometer.fromJson(Map<String, dynamic> json) =>
      Riskometer(name: json["name"] ?? "Moderate");

  Map<String, dynamic> toJson() => {"name": name};
}

class Sectorallocation {
  List<SectorData> sectors;

  Sectorallocation({required this.sectors});

  factory Sectorallocation.fromJson(List<dynamic> json) => Sectorallocation(
    sectors: List<SectorData>.from(
      json.map((x) => SectorData.fromJson(x as Map<String, dynamic>)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "sectors": List<dynamic>.from(sectors.map((x) => x.toJson())),
  };
}

class SectorData {
  final double percentage;
  final int sectorCode;
  final String sectorName;
  final double value;

  SectorData({
    required this.percentage,
    required this.sectorCode,
    required this.sectorName,
    required this.value,
  });

  factory SectorData.fromJson(Map<String, dynamic> json) => SectorData(
    percentage: json["percentage"]?.toDouble() ?? 0.0,
    sectorCode: json["sectorcode"] ?? 0,
    sectorName: json["sectorname"] ?? "",
    value: json["value"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "percentage": percentage,
    "sectorcode": sectorCode,
    "sectorname": sectorName,
    "value": value,
  };
}

class Sipdetail {
  double minimumsip;
  double maximumsip;
  double? minimumlumpsum;
  List<String> frequency;
  double lockinperiod;

  Sipdetail({
    required this.minimumsip,
    required this.maximumsip,
    this.minimumlumpsum,
    required this.frequency,
    required this.lockinperiod,
  });

  factory Sipdetail.fromJson(Map<String, dynamic> json) => Sipdetail(
    minimumsip: (json["minimumsip"] ?? json["min_installment_amount"] ?? json["min"])?.toDouble() ?? 0.0,
    maximumsip: (json["maximumsip"] ?? json["max_installment_amount"] ?? json["max"])?.toDouble() ?? 0.0,
    minimumlumpsum: (json["minimum_lumpsum"] ?? json["min_purchase_amount"] ?? json["min"])?.toDouble(),
    frequency: json["frequency"] != null ? List<String>.from(json["frequency"]) : [],
    lockinperiod: (json["lockinperiod"] ?? json["lockin_period"])?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "minimumsip": minimumsip,
    "maximumsip": maximumsip,
    "minimum_lumpsum": minimumlumpsum,
    "frequency": frequency,
    "lockinperiod": lockinperiod,
  };
}

class TopHoldings {
  String name;
  double value;

  TopHoldings({required this.name, required this.value});

  factory TopHoldings.fromJson(Map<String, dynamic> json) =>
      TopHoldings(name: json["name"] ?? "", value: (json["value"] ?? 0.0).toDouble());

  Map<String, dynamic> toJson() => {"name": name, "value": value};
}

class FundManager {
  String name;
  int personid;

  FundManager({required this.name, required this.personid});

  factory FundManager.fromJson(Map<String, dynamic> json) =>
      FundManager(name: json["name"] ?? "", personid: json["person_id"] ?? 0);

  Map<String, dynamic> toJson() => {"name": name, "person_id": personid};
}

class FundReturns {
  ReturnPeriod oneDay;
  ReturnPeriod oneWeek;
  ReturnPeriod oneMonth;
  ReturnPeriod threeMonths;
  ReturnPeriod sixMonths;
  ReturnPeriod oneYear;
  ReturnPeriod threeYears;
  ReturnPeriod fiveYears;
  ReturnPeriod all;

  FundReturns({
    required this.oneDay,
    required this.oneWeek,
    required this.oneMonth,
    required this.threeMonths,
    required this.sixMonths,
    required this.oneYear,
    required this.threeYears,
    required this.fiveYears,
    required this.all,
  });

  factory FundReturns.fromJson(Map<String, dynamic> json) => FundReturns(
    oneDay: ReturnPeriod.fromJson(json["1d"] ?? {}),
    oneWeek: ReturnPeriod.fromJson(json["1w"] ?? {}),
    oneMonth: ReturnPeriod.fromJson(json["1m"] ?? {}),
    threeMonths: ReturnPeriod.fromJson(json["3m"] ?? {}),
    sixMonths: ReturnPeriod.fromJson(json["6m"] ?? {}),
    oneYear: ReturnPeriod.fromJson(json["1y"] ?? {}),
    threeYears: ReturnPeriod.fromJson(json["3y"] ?? {}),
    fiveYears: ReturnPeriod.fromJson(json["5y"] ?? {}),
    all: ReturnPeriod.fromJson(json["max"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "1d": oneDay.toJson(),
    "1w": oneWeek.toJson(),
    "1m": oneMonth.toJson(),
    "3m": threeMonths.toJson(),
    "6m": sixMonths.toJson(),
    "1y": oneYear.toJson(),
    "3y": threeYears.toJson(),
    "5y": fiveYears.toJson(),
    "all": all.toJson(),
  };
}

class ReturnPeriod {
  double absolute;
  double annualized;

  ReturnPeriod({required this.absolute, required this.annualized});

  factory ReturnPeriod.fromJson(Map<String, dynamic> json) => ReturnPeriod(
    absolute: (json["absolute"] ?? 0.0).toDouble(),
    annualized: (json["annualized"] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "absolute": absolute,
    "annualized": annualized,
  };
}

// Performance Score API Response Types
class PerformanceScoreResponse {
  int statusCode;
  String message;
  List<PerformanceScore> scores;
  int green;
  int yellow;
  int red;
  int white;

  PerformanceScoreResponse({
    required this.statusCode,
    required this.message,
    required this.scores,
    required this.green,
    required this.yellow,
    required this.red,
    required this.white,
  });

  factory PerformanceScoreResponse.fromJson(Map<String, dynamic> json) =>
      PerformanceScoreResponse(
        statusCode: json["statusCode"] ?? 0,
        message: json["message"] ?? "",
        scores: List<PerformanceScore>.from(
          json["data"].map((x) => PerformanceScore.fromJson(x)),
        ),
        green: json["green"] ?? 0,
        yellow: json["yellow"] ?? 0,
        red: json["red"] ?? 0,
        white: json["white"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": List<dynamic>.from(scores.map((x) => x.toJson())),
    "green": green,
    "yellow": yellow,
    "red": red,
    "white": white,
  };
}

class PerformanceScore {
  String slug;
  String line1;
  String line2;
  String value;
  String signal;

  PerformanceScore({
    required this.slug,
    required this.line1,
    required this.line2,
    required this.value,
    required this.signal,
  });

  factory PerformanceScore.fromJson(Map<String, dynamic> json) =>
      PerformanceScore(
        slug: json["slug"] ?? "",
        line1: json["line1"] ?? "",
        line2: json["line2"] ?? "",
        value: json["value"] ?? "",
        signal: json["signal"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "slug": slug,
    "line1": line1,
    "line2": line2,
    "value": value,
    "signal": signal,
  };
}
