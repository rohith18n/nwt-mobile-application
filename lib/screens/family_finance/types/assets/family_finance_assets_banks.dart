class FamilyFinanceBanksResponse {
  int statusCode;
  String message;
  FamilyFinanceBanksData? data;

  FamilyFinanceBanksResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyFinanceBanksResponse.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceBanksResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyFinanceBanksData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyFinanceBanksData {
  List<Member> members;
  Summary summary;

  FamilyFinanceBanksData({required this.members, required this.summary});

  factory FamilyFinanceBanksData.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceBanksData(
        members: List<Member>.from(
          json["members"].map((x) => Member.fromJson(x)),
        ),
        summary: Summary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

class Member {
  Assets assets;
  String lastname;
  String userguid;
  String firstname;

  Member({
    required this.assets,
    required this.lastname,
    required this.userguid,
    required this.firstname,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    assets: Assets.fromJson(json["assets"]),
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

class Assets {
  AssetsDeposit deposit;

  Assets({required this.deposit});

  factory Assets.fromJson(Map<String, dynamic> json) =>
      Assets(deposit: AssetsDeposit.fromJson(json["deposit"]));

  Map<String, dynamic> toJson() => {"deposit": deposit.toJson()};
}

class AssetsDeposit {
  List<FamilyFinanceBankAccount> data;
  String name;
  SummaryClass summary;

  AssetsDeposit({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory AssetsDeposit.fromJson(Map<String, dynamic> json) => AssetsDeposit(
    data: List<FamilyFinanceBankAccount>.from(
      json["data"].map((x) => FamilyFinanceBankAccount.fromJson(x)),
    ),
    name: json["name"],
    summary: SummaryClass.fromJson(json["summary"]),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceBankAccount {
  String guid;
  String type;
  double delta;
  String fipid;
  String acctype;
  String fipname;
  double totalsum;
  String userguid;
  double? deltavalue;
  double currentvalue;
  String linkrefnumber;
  String maskedaccountid;

  FamilyFinanceBankAccount({
    required this.guid,
    required this.type,
    required this.delta,
    required this.fipid,
    required this.acctype,
    required this.fipname,
    required this.totalsum,
    required this.userguid,
    this.deltavalue,
    required this.currentvalue,
    required this.linkrefnumber,
    required this.maskedaccountid,
  });

  factory FamilyFinanceBankAccount.fromJson(Map<String, dynamic> json) =>
      FamilyFinanceBankAccount(
        guid: json["guid"],
        type: json["type"],
        delta: json["delta"]?.toDouble() ?? 0.0,
        fipid: json["fipid"],
        acctype: json["acctype"],
        fipname: json["fipname"],
        totalsum: json["totalsum"]?.toDouble() ?? 0.0,
        userguid: json["userguid"],
        deltavalue: json["deltavalue"] == null ? 0.0 : json["deltavalue"]?.toDouble() ?? 0.0,
        currentvalue: json["currentvalue"] == null ? 0.0 : json["currentvalue"]?.toDouble() ?? 0.0,
        linkrefnumber: json["linkrefnumber"],
        maskedaccountid: json["maskedaccountid"],
      );

  Map<String, dynamic> toJson() => {
    "guid": guid,
    "type": type,
    "delta": delta,
    "fipid": fipid,
    "acctype": acctype,
    "fipname": fipname,
    "totalsum": totalsum,
    "userguid": userguid,
    "deltavalue": deltavalue,
    "currentvalue": currentvalue,
    "linkrefnumber": linkrefnumber,
    "maskedaccountid": maskedaccountid,
  };
}

class SummaryClass {
  double avgdelta;
  double totalsum;
  double avgdeltavalue;
  double avgcurrentvalue;

  SummaryClass({
    required this.avgdelta,
    required this.totalsum,
    required this.avgdeltavalue,
    required this.avgcurrentvalue,
  });

  factory SummaryClass.fromJson(Map<String, dynamic> json) => SummaryClass(
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

class Summary {
  SummaryClass deposit;
  Deposit termDeposit;
  Deposit recurringDeposit;

  Summary({
    required this.deposit,
    required this.termDeposit,
    required this.recurringDeposit,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    deposit: SummaryClass.fromJson(json["deposit"]),
    termDeposit: Deposit.fromJson(json["term_deposit"]),
    recurringDeposit: Deposit.fromJson(json["recurring_deposit"]),
  );

  Map<String, dynamic> toJson() => {
    "deposit": deposit.toJson(),
    "term_deposit": termDeposit.toJson(),
    "recurring_deposit": recurringDeposit.toJson(),
  };
}

class Deposit {
  double totalsum;
  double accountcount;
  double avginterestrate;

  Deposit({
    required this.totalsum,
    required this.accountcount,
    required this.avginterestrate,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    accountcount: json["accountcount"]?.toDouble() ?? 0.0,
    avginterestrate: json["avginterestrate"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "totalsum": totalsum,
    "accountcount": accountcount,
    "avginterestrate": avginterestrate,
  };
}
