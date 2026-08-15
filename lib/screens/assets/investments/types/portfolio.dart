class InvestmentPortfolioResponse {
  int status;
  String message;
  InvestmentPortfolio? data;
  bool get success => status == 200 || status == 201;

  InvestmentPortfolioResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory InvestmentPortfolioResponse.fromJson(Map<String, dynamic> json) =>
      InvestmentPortfolioResponse(
        status: _parseSafeInt(json["statusCode"] ?? json["status"]) ?? 0,
        message: json["message"],
        data:
            json["data"] != null
                ? InvestmentPortfolio.fromJson(json["data"])
                : null,
      );

  static int? _parseSafeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class InvestmentPortfolio {
  double value;
  double invested;
  double? gain;
  String? latestbalancedatetime;
  double deltavalue;
  double deltapercentage;
  Coverage coverage;
  CoverageLinked? coverageLinked; // Added coverageLinked
  double etf_total;
  double mf_total;
  double stocks_total;
  double? etf_invested;
  double? mf_invested;
  double? stocks_invested;
  double? etf_gain;
  double? mf_gain;
  double? stocks_gain;

  InvestmentPortfolio({
    required this.value,
    required this.invested,
    this.gain,
    this.latestbalancedatetime,
    required this.deltavalue,
    required this.deltapercentage,
    required this.coverage,
    this.coverageLinked,
    required this.etf_total,
    required this.mf_total,
    required this.stocks_total,
    this.etf_invested,
    this.mf_invested,
    this.stocks_invested,
    this.etf_gain,
    this.mf_gain,
    this.stocks_gain,
  });

  factory InvestmentPortfolio.fromJson(Map<String, dynamic> json) =>
      InvestmentPortfolio(
        value:
            (json["value"] ?? json["total"] ?? json["totalvalue"])
                ?.toDouble() ??
            0.0,
        invested: (json["invested"] ?? json["investedvalue"])?.toDouble() ?? 0.0,
        gain: (json["gain"] ?? json["gainloss"])?.toDouble() ?? 0.0,
        latestbalancedatetime:
            (json["latestbalancedatetime"] ?? json["latestBalanceDateTime"])
                ?.toString(),
        deltavalue:
            (json["deltavalue"] ?? json["deltaValue"])?.toDouble() ?? 0.0,
        deltapercentage:
            (json["deltapercentage"] ?? json["deltaPercentage"])?.toDouble() ??
            0.0,
        coverage: Coverage.fromJson(
          (json["coverage"] is Map<String, dynamic>)
              ? (json["coverage"] as Map<String, dynamic>)
              : const <String, dynamic>{},
        ),
        coverageLinked:
            json["coverageLinked"] != null
                ? CoverageLinked.fromJson(json["coverageLinked"])
                : null,
        etf_total:
            (json["etf_total"] ?? json["etfTotal"] ?? json["totaletfamount"])
                ?.toDouble() ??
            0.0,
        mf_total:
            (json["mf_total"] ?? json["mfTotal"] ?? json["totalmfamount"])
                ?.toDouble() ??
            0.0,
        stocks_total:
            (json["stocks_total"] ??
                    json["stocksTotal"] ??
                    json["totalequitiesamount"])
                ?.toDouble() ??
            0.0,
        etf_invested:
            (json["etf_invested"] ?? json["totaletfinvestedamount"])
                ?.toDouble(),
        mf_invested:
            (json["mf_invested"] ?? json["totalmfinvestedamount"])?.toDouble(),
        stocks_invested:
            (json["stocks_invested"] ?? json["totalequitiesinvestedamount"])
                ?.toDouble(),
        etf_gain: (json["etf_gain"] ?? json["etfGain"])?.toDouble(),
        mf_gain: (json["mf_gain"] ?? json["mfGain"])?.toDouble(),
        stocks_gain: (json["stocks_gain"] ?? json["stocksGain"])?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "value": value,
    "invested": invested,
    "gain": gain,
    "latestbalancedatetime": latestbalancedatetime,
    "deltavalue": deltavalue,
    "deltapercentage": deltapercentage,
    "coverage": coverage.toJson(),
    "coverageLinked": coverageLinked?.toJson(),
    "etf_total": etf_total,
    "mf_total": mf_total,
    "stocks_total": stocks_total,
    "etf_invested": etf_invested,
    "mf_invested": mf_invested,
    "stocks_invested": stocks_invested,
    "etf_gain": etf_gain,
    "mf_gain": mf_gain,
    "stocks_gain": stocks_gain,
  };
}

class Coverage {
  double stocks;
  double mutualfunds;
  double etf;
  double fo; // Added fo

  Coverage({
    required this.stocks,
    required this.mutualfunds,
    required this.etf,
    required this.fo,
  });

  factory Coverage.fromJson(Map<String, dynamic> json) => Coverage(
    stocks: json["stocks"]?.toDouble() ?? 0.0,
    mutualfunds: json["mutualfunds"]?.toDouble() ?? 0.0,
    etf: json["etf"]?.toDouble() ?? 0.0,
    fo: json["fo"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "stocks": stocks,
    "mutualfunds": mutualfunds,
    "etf": etf,
    "fo": fo,
  };
}

class CoverageLinked {
  bool stocks;
  bool mutualfunds;
  bool etf;
  bool fo;

  CoverageLinked({
    required this.stocks,
    required this.mutualfunds,
    required this.etf,
    required this.fo,
  });

  factory CoverageLinked.fromJson(Map<String, dynamic> json) => CoverageLinked(
    stocks: json["stocks"] ?? false,
    mutualfunds: json["mutualfunds"] ?? false,
    etf: json["etf"] ?? false,
    fo: json["fo"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "stocks": stocks,
    "mutualfunds": mutualfunds,
    "etf": etf,
    "fo": fo,
  };
}
