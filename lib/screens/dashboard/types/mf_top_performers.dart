class MutualFundTopPerformersRespose {
  int statusCode;
  String message;
  List<MFPerformers>? data;
  bool? hasMore;

  MutualFundTopPerformersRespose({
    required this.statusCode,
    required this.message,
    this.data,
    this.hasMore,
  });

  factory MutualFundTopPerformersRespose.fromJson(Map<String, dynamic> json) {
    // Handle V1 API structure where data contains a nested list under 'schemes'
    dynamic rawData = json["data"];
    List<MFPerformers>? performers;
    
    if (rawData != null) {
      if (rawData is List) {
        performers = List<MFPerformers>.from(rawData.map((x) => MFPerformers.fromJson(x)));
      } else if (rawData is Map && rawData["schemes"] != null) {
        performers = List<MFPerformers>.from(rawData["schemes"].map((x) => MFPerformers.fromJson(x)));
      }
    }

    return MutualFundTopPerformersRespose(
      statusCode: (json["statusCode"] ?? (json["success"] == true ? 200 : 400)) as int,
      message: json["message"] ?? "",
      data: performers,
      hasMore: rawData is Map ? rawData["has_more"] : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data":
        data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : null,
  };
}

class Returns {
  double? oneYear;
  double? threeYear;
  double? fiveYear;

  Returns({this.oneYear, this.threeYear, this.fiveYear});

  factory Returns.fromJson(Map<String, dynamic> json) => Returns(
    oneYear: json["1y"]?.toDouble(),
    threeYear: json["3y"]?.toDouble(),
    fiveYear: json["5y"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "1y": oneYear,
    "3y": threeYear,
    "5y": fiveYear,
  };
}

class FormatReturn {
  double? absolute;
  double? annualized;

  FormatReturn({this.absolute, this.annualized});

  factory FormatReturn.fromJson(Map<String, dynamic> json) => FormatReturn(
    absolute: json["absolute"]?.toDouble(),
    annualized: json["annualized"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "absolute": absolute,
    "annualized": annualized,
  };
}

class FormatReturns {
  FormatReturn? oneWeek;
  FormatReturn? oneMonth;
  FormatReturn? threeMonth;
  FormatReturn? sixMonth;
  FormatReturn? oneYear;
  FormatReturn? threeYear;
  FormatReturn? fiveYear;
  FormatReturn? all;

  FormatReturns({
    this.oneWeek,
    this.oneMonth,
    this.threeMonth,
    this.sixMonth,
    this.oneYear,
    this.threeYear,
    this.fiveYear,
    this.all,
  });

  factory FormatReturns.fromJson(Map<String, dynamic> json) => FormatReturns(
    oneWeek: json["1w"] != null ? FormatReturn.fromJson(json["1w"]) : null,
    oneMonth: json["1m"] != null ? FormatReturn.fromJson(json["1m"]) : null,
    threeMonth: json["3m"] != null ? FormatReturn.fromJson(json["3m"]) : null,
    sixMonth: json["6m"] != null ? FormatReturn.fromJson(json["6m"]) : null,
    oneYear: json["1y"] != null ? FormatReturn.fromJson(json["1y"]) : null,
    threeYear: json["3y"] != null ? FormatReturn.fromJson(json["3y"]) : null,
    fiveYear: json["5y"] != null ? FormatReturn.fromJson(json["5y"]) : null,
    all: json["all"] != null ? FormatReturn.fromJson(json["all"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "1w": oneWeek?.toJson(),
    "1m": oneMonth?.toJson(),
    "3m": threeMonth?.toJson(),
    "6m": sixMonth?.toJson(),
    "1y": oneYear?.toJson(),
    "3y": threeYear?.toJson(),
    "5y": fiveYear?.toJson(),
    "all": all?.toJson(),
  };
}

class MFPerformers {
  String? isincode;
  String? name;
  String? schemeCode;
  String? category;
  String? icon;
  double? expenseratio;
  String? aumcr;
  Returns? returns;
  FormatReturns? formatreturn;
  String? amcname;
  double? nav;
  String? fundtype;
  double? minAmount;

  MFPerformers({
    this.isincode,
    this.name,
    this.schemeCode,
    this.category,
    this.icon,
    this.expenseratio,
    this.aumcr,
    this.returns,
    this.formatreturn,
    this.amcname,
    this.nav,
    this.fundtype,
    this.minAmount,
  });

  factory MFPerformers.fromJson(Map<String, dynamic> json) => MFPerformers(
    isincode: json["isincode"] ?? json["scheme_isin"],
    name: json["name"] ?? json["scheme_name"],
    schemeCode: json["scheme_code"],
    category: json["category"],
    icon: json["icon"],
    expenseratio: json["expenseratio"]?.toDouble(),
    aumcr: json["aumcr"],
    returns: json["returns"] != null ? Returns.fromJson(json["returns"]) : null,
    formatreturn:
        json["formatreturn"] != null
            ? FormatReturns.fromJson(json["formatreturn"])
            : null,
    amcname: json["amcname"],
    nav: json["nav"]?.toDouble(),
    fundtype: json["fundtype"],
    minAmount: (json["min_initial_investment_amount"] ?? json["minimum_amount"])?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "isincode": isincode,
    "name": name,
    "category": category,
    "icon": icon,
    "expenseratio": expenseratio,
    "aumcr": aumcr,
    "returns": returns?.toJson(),
    "formatreturn": formatreturn?.toJson(),
    "amcname": amcname,
    "nav": nav,
    "fundtype": fundtype,
    "minimum_lumpsum": minAmount,
  };
}
