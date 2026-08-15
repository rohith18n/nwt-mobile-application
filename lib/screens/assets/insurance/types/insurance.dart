class InsuranceResponse {
  int statusCode;
  String message;
  InsuranceData? data;

  InsuranceResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory InsuranceResponse.fromJson(Map<String, dynamic> json) =>
      InsuranceResponse(
        statusCode: json["statusCode"] ?? 0,
        message: json["message"] ?? "",
        data:
            json["data"] != null ? InsuranceData.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class InsuranceData {
  double totalCoverage;
  List<Insurance> items;

  InsuranceData({required this.totalCoverage, required this.items});

  factory InsuranceData.fromJson(Map<String, dynamic> json) => InsuranceData(
    totalCoverage: (json["totalCoverage"] as num?)?.toDouble() ?? 0.0,
    items: json["items"] != null
        ? List<Insurance>.from(
            json["items"].map((x) => Insurance.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    "totalCoverage": totalCoverage,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class Insurance {
  String accountguid;
  String policyname;
  String policynumber;
  double sumassured;
  String fipname;
  String type;
  String subcategory;
  double premiumamount;
  double currentvalue;
  String premiumfrequency;
  DateTime? policystartdate;
  DateTime? nextpremiumduedate;
  int? tenureyears;
  int? premiumpaymentyears;
  String? policystatus;
  DateTime? policyexpirydate;
  String? linkedaccref;
  int? count;
  List<List<dynamic>> transactions;

  Insurance({
    required this.accountguid,
    required this.policyname,
    required this.policynumber,
    required this.sumassured,
    required this.fipname,
    required this.type,
    required this.subcategory,
    required this.premiumamount,
    required this.currentvalue,
    required this.premiumfrequency,
    this.policystartdate,
    this.nextpremiumduedate,
    this.tenureyears,
    this.premiumpaymentyears,
    this.policystatus,
    this.policyexpirydate,
    this.linkedaccref,
    this.count,
    required this.transactions,
  });

  factory Insurance.fromJson(Map<String, dynamic> json) => Insurance(
    accountguid: json["accountguid"]?.toString() ?? '',
    policyname: json["policyname"]?.toString() ?? '',
    policynumber: json["policynumber"]?.toString() ?? '',
    sumassured: (json["sumassured"] as num?)?.toDouble() ?? 0.0,
    fipname: json["fipname"]?.toString() ?? '',
    type: json["type"]?.toString() ?? '',
    subcategory: json["subcategory"]?.toString() ?? '',
    premiumamount: (json["premiumamount"] as num?)?.toDouble() ?? 0.0,
    currentvalue: (json["currentvalue"] as num?)?.toDouble() ?? 0.0,
    premiumfrequency: json["premiumfrequency"]?.toString() ?? 'ANNUALLY',
    policystartdate: json["policystartdate"] != null ? DateTime.tryParse(json["policystartdate"]) : null,
    nextpremiumduedate: json["nextpremiumduedate"] != null ? DateTime.tryParse(json["nextpremiumduedate"]) : null,
    tenureyears: (json["tenureyears"] as num?)?.toInt(),
    premiumpaymentyears: (json["premiumpaymentyears"] as num?)?.toInt(),
    policystatus: json["policystatus"]?.toString(),
    policyexpirydate: json["policyexpirydate"] != null ? DateTime.tryParse(json["policyexpirydate"]) : null,
    linkedaccref: json["linkedaccref"]?.toString(),
    count: (json["count"] as num?)?.toInt(),
    transactions: json["transactions"] != null
        ? List<List<dynamic>>.from(
            (json["transactions"] as List).map((x) => List<dynamic>.from(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    "accountguid": accountguid,
    "policyname": policyname,
    "policynumber": policynumber,
    "sumassured": sumassured,
    "fipname": fipname,
    "type": type,
    "subcategory": subcategory,
    "premiumamount": premiumamount,
    "currentvalue": currentvalue,
    "transactions": transactions,
  };
}

class InsuranceDetailsResponse {
  int statusCode;
  String message;
  InsuranceDetailsData? data;

  InsuranceDetailsResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory InsuranceDetailsResponse.fromJson(Map<String, dynamic> json) =>
      InsuranceDetailsResponse(
        statusCode: json["statusCode"] ?? 0,
        message: json["message"] ?? "",
        data:
            json["data"] != null
                ? InsuranceDetailsData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class InsuranceDetailsData {
  String maininsurancetype;
  String fipname;
  String? policyname;
  String? policynumber;
  String? type;
  DateTime? policystartdate;
  DateTime? policyenddate;
  DateTime? nextpremiumduedate;
  double premiumamount;
  String premiumfrequency;
  int? premiumpaymentyears;
  double? sumassured;
  String policytype;
  int? tenureyears;
  int id;
  String guid;
  String accountguid;
  String linkrefnumber;
  double? coverageamount;
  DateTime? createdat;
  DateTime? updatedat;
  double? surrendervalue;
  String userguid;

  InsuranceDetailsData({
    required this.maininsurancetype,
    required this.fipname,
    this.policyname,
    this.policynumber,
    this.type,
    this.policystartdate,
    this.policyenddate,
    this.nextpremiumduedate,
    required this.premiumamount,
    required this.premiumfrequency,
    this.premiumpaymentyears,
    this.sumassured,
    required this.policytype,
    this.tenureyears,
    required this.id,
    required this.guid,
    required this.accountguid,
    required this.linkrefnumber,
    this.coverageamount,
    this.createdat,
    this.updatedat,
    this.surrendervalue,
    required this.userguid,
  });

  factory InsuranceDetailsData.fromJson(Map<String, dynamic> json) {
    return InsuranceDetailsData(
      maininsurancetype: json["maininsurancetype"] ?? "",
      fipname: json["fipname"] ?? "",
      policyname: json["policyname"],
      policynumber: json["policynumber"],
      type: json["type"],
      policystartdate:
          json["policystartdate"] != null
              ? DateTime.tryParse(json["policystartdate"])
              : null,
      policyenddate:
          json["policyenddate"] != null
              ? DateTime.tryParse(json["policyenddate"])
              : null,
      nextpremiumduedate:
          json["nextpremiumduedate"] != null
              ? DateTime.tryParse(json["nextpremiumduedate"])
              : null,
      premiumamount: (json["premiumamount"] as num?)?.toDouble() ?? 0.0,
      premiumfrequency: json["premiumfrequency"] ?? "ANNUALLY",
      premiumpaymentyears: (json["premiumpaymentyears"] as num?)?.toInt(),
      sumassured: (json["sumassured"] as num?)?.toDouble() ?? 0.0,
      policytype: json["policytype"] ?? "",
      tenureyears: (json["tenureyears"] as num?)?.toInt(),
      id: json["id"] ?? 0,
      guid: json["guid"] ?? "",
      accountguid: json["accountguid"] ?? "",
      linkrefnumber: json["linkrefnumber"] ?? "",
      coverageamount: (json["coverageamount"] as num?)?.toDouble(),
      createdat:
          json["createdat"] != null ? DateTime.tryParse(json["createdat"]) : null,
      updatedat:
          json["updatedat"] != null ? DateTime.tryParse(json["updatedat"]) : null,
      surrendervalue: (json["surrendervalue"] as num?)?.toDouble(),
      userguid: json["userguid"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "maininsurancetype": maininsurancetype,
    "fipname": fipname,
    "policyname": policyname,
    "policynumber": policynumber,
    "type": type,
    "policystartdate": policystartdate?.toIso8601String(),
    "policyenddate": policyenddate?.toIso8601String(),
    "nextpremiumduedate": nextpremiumduedate?.toIso8601String(),
    "premiumamount": premiumamount,
    "premiumfrequency": premiumfrequency,
    "premiumpaymentyears": premiumpaymentyears,
    "sumassured": sumassured,
    "policytype": policytype,
    "tenureyears": tenureyears,
    "id": id,
    "guid": guid,
    "accountguid": accountguid,
    "linkrefnumber": linkrefnumber,
    "coverageamount": coverageamount,
    "createdat": createdat?.toIso8601String(),
    "updatedat": updatedat?.toIso8601String(),
    "surrendervalue": surrendervalue,
    "userguid": userguid,
  };
}