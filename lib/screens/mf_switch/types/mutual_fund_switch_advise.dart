class MutualFundSwitchAdvisory {
  int status;
  String message;
  MutualFundSwitchAdvise? data;

  MutualFundSwitchAdvisory({
    required this.status,
    required this.message,
    this.data,
  });

  factory MutualFundSwitchAdvisory.fromJson(Map<String, dynamic> json) =>
      MutualFundSwitchAdvisory(
        status: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? MutualFundSwitchAdvise.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class MutualFundSwitchAdvise {
  double investment;
  double held;
  double regularplanvalue;
  double directplanvalue;
  double commissionpaid;
  List<Regtodirplan> regtodirplans;

  MutualFundSwitchAdvise({
    required this.investment,
    required this.held,
    required this.regularplanvalue,
    required this.directplanvalue,
    required this.commissionpaid,
    required this.regtodirplans,
  });

  factory MutualFundSwitchAdvise.fromJson(Map<String, dynamic> json) =>
      MutualFundSwitchAdvise(
        investment: json["investment"]?.toDouble() ?? 0.0,
        held: json["held"]?.toDouble() ?? 0.0,
        regularplanvalue: json["regularplanvalue"]?.toDouble() ?? 0.0,
        directplanvalue: json["directplanvalue"]?.toDouble() ?? 0.0,
        commissionpaid: json["commissionpaid"]?.toDouble() ?? 0.0,
        regtodirplans: List<Regtodirplan>.from(
          json["regtodirplans"].map((x) => Regtodirplan.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "investment": investment,
    "held": held,
    "regularplanvalue": regularplanvalue,
    "directplanvalue": directplanvalue,
    "commissionpaid": commissionpaid,
    "regtodirplans": List<dynamic>.from(regtodirplans.map((x) => x.toJson())),
  };
}

class Regtodirplan {
  String regfundname;
  double regexpratio;
  double ltcgtax;
  double gain;
  String dirfundname;
  double direxpratio;

  Regtodirplan({
    required this.regfundname,
    required this.regexpratio,
    required this.ltcgtax,
    required this.gain,
    required this.dirfundname,
    required this.direxpratio,
  });

  factory Regtodirplan.fromJson(Map<String, dynamic> json) => Regtodirplan(
    regfundname: json["regfundname"],
    regexpratio: json["regexpratio"]?.toDouble() ?? 0.0,
    ltcgtax: json["ltcgtax"]?.toDouble() ?? 0.0,
    gain: json["gain"]?.toDouble() ?? 0.0,
    dirfundname: json["dirfundname"],
    direxpratio: json["direxpratio"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "regfundname": regfundname,
    "regexpratio": regexpratio,
    "ltcgtax": ltcgtax,
    "gain": gain,
    "dirfundname": dirfundname,
    "direxpratio": direxpratio,
  };
}
