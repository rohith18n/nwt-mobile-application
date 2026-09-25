class FamilyFinanceAssetsInsuranceResponse {
  int statusCode;
  String message;
  FamilyFinanceAssetsInsuranceData? data;

  FamilyFinanceAssetsInsuranceResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyFinanceAssetsInsuranceResponse.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsuranceResponse(
    statusCode: json["statusCode"],
    message: json["message"],
    data:
        json["data"] != null
            ? FamilyFinanceAssetsInsuranceData.fromJson(json["data"])
            : null,
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyFinanceAssetsInsuranceData {
  List<FamilyFinanceAssetsInsuranceMember> members;
  FamilyFinanceAssetsInsuranceSummary summary;

  FamilyFinanceAssetsInsuranceData({
    required this.members,
    required this.summary,
  });

  factory FamilyFinanceAssetsInsuranceData.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsuranceData(
    members: List<FamilyFinanceAssetsInsuranceMember>.from(
      json["members"].map(
        (x) => FamilyFinanceAssetsInsuranceMember.fromJson(x),
      ),
    ),
    summary: FamilyFinanceAssetsInsuranceSummary.fromJson(json["summary"]),
  );

  Map<String, dynamic> toJson() => {
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "summary": summary.toJson(),
  };
}

class FamilyFinanceAssetsInsuranceMember {
  FamilyFinanceAssetsInsuranceAssets assets;
  String lastname;
  String userguid;
  String firstname;

  FamilyFinanceAssetsInsuranceMember({
    required this.assets,
    required this.lastname,
    required this.userguid,
    required this.firstname,
  });

  factory FamilyFinanceAssetsInsuranceMember.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsuranceMember(
    assets: FamilyFinanceAssetsInsuranceAssets.fromJson(json["assets"]),
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

class FamilyFinanceAssetsInsuranceAssets {
  FamilyFinanceAssetsLifeInsurance lifeInsurance;
  FamilyFinanceAssetsGeneralInsurance generalInsurance;
  FamilyFinanceAssetsInsurancePolicies insurancePolicies;

  FamilyFinanceAssetsInsuranceAssets({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.insurancePolicies,
  });

  factory FamilyFinanceAssetsInsuranceAssets.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsuranceAssets(
    lifeInsurance: FamilyFinanceAssetsLifeInsurance.fromJson(
      json["life_insurance"],
    ),
    generalInsurance: FamilyFinanceAssetsGeneralInsurance.fromJson(
      json["general_insurance"],
    ),
    insurancePolicies: FamilyFinanceAssetsInsurancePolicies.fromJson(
      json["insurance_policies"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "life_insurance": lifeInsurance.toJson(),
    "general_insurance": generalInsurance.toJson(),
    "insurance_policies": insurancePolicies.toJson(),
  };
}

class FamilyFinanceAssetsLifeInsurance {
  List<FamilyFinanceAssetsLifeInsuranceDatum> data;
  String name;
  FamilyFinanceAssetsLifeInsuranceSummary summary;

  FamilyFinanceAssetsLifeInsurance({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceAssetsLifeInsurance.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsLifeInsurance(
    data: List<FamilyFinanceAssetsLifeInsuranceDatum>.from(
      json["data"].map(
        (x) => FamilyFinanceAssetsLifeInsuranceDatum.fromJson(x),
      ),
    ),
    name: json["name"],
    summary: FamilyFinanceAssetsLifeInsuranceSummary.fromJson(json["summary"]),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceAssetsLifeInsuranceDatum {
  String fipid;
  String fipname;
  String userguid;
  String assignment;
  String exclusions;
  String holdername;
  String policytype;
  double sumassured;
  String accountguid;
  double tenureyears;
  String policystatus;
  String linkrefnumber;
  String? policyenddate;
  double premiumamount;
  double surrendervalue;
  String maskedaccnumber;
  String? policystartdate;
  String policyloanstatus;
  String premiumfrequency;
  double premiumpaymentyears;

  FamilyFinanceAssetsLifeInsuranceDatum({
    required this.fipid,
    required this.fipname,
    required this.userguid,
    required this.assignment,
    required this.exclusions,
    required this.holdername,
    required this.policytype,
    required this.sumassured,
    required this.accountguid,
    required this.tenureyears,
    required this.policystatus,
    required this.linkrefnumber,
    this.policyenddate,
    required this.premiumamount,
    required this.surrendervalue,
    required this.maskedaccnumber,
    this.policystartdate,
    required this.policyloanstatus,
    required this.premiumfrequency,
    required this.premiumpaymentyears,
  });

  factory FamilyFinanceAssetsLifeInsuranceDatum.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsLifeInsuranceDatum(
    fipid: json["fipid"],
    fipname: json["fipname"],
    userguid: json["userguid"],
    assignment: json["assignment"],
    exclusions: json["exclusions"],
    holdername: json["holdername"],
    policytype: json["policytype"],
    sumassured: json["sumassured"]?.toDouble() ?? 0.0,
    accountguid: json["accountguid"],
    tenureyears: json["tenureyears"]?.toDouble() ?? 0.0,
    policystatus: json["policystatus"],
    linkrefnumber: json["linkrefnumber"],
    policyenddate: json["policyenddate"],
    premiumamount: json["premiumamount"]?.toDouble() ?? 0.0,
    surrendervalue: json["surrendervalue"]?.toDouble() ?? 0.0,
    maskedaccnumber: json["maskedaccnumber"],
    policystartdate: json["policystartdate"],
    policyloanstatus: json["policyloanstatus"],
    premiumfrequency: json["premiumfrequency"],
    premiumpaymentyears: json["premiumpaymentyears"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "fipid": fipid,
    "fipname": fipname,
    "userguid": userguid,
    "assignment": assignment,
    "exclusions": exclusions,
    "holdername": holdername,
    "policytype": policytype,
    "sumassured": sumassured,
    "accountguid": accountguid,
    "tenureyears": tenureyears,
    "policystatus": policystatus,
    "linkrefnumber": linkrefnumber,
    "policyenddate": policyenddate,
    "premiumamount": premiumamount,
    "surrendervalue": surrendervalue,
    "maskedaccnumber": maskedaccnumber,
    "policystartdate": policystartdate,
    "policyloanstatus": policyloanstatus,
    "premiumfrequency": premiumfrequency,
    "premiumpaymentyears": premiumpaymentyears,
  };
}

class FamilyFinanceAssetsLifeInsuranceSummary {
  double totalsum;
  double avgpremium;
  double totalsurrendervalue;

  FamilyFinanceAssetsLifeInsuranceSummary({
    required this.totalsum,
    required this.avgpremium,
    required this.totalsurrendervalue,
  });

  factory FamilyFinanceAssetsLifeInsuranceSummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsLifeInsuranceSummary(
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    avgpremium: json["avgpremium"]?.toDouble() ?? 0.0,
    totalsurrendervalue: json["totalsurrendervalue"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "totalsum": totalsum,
    "avgpremium": avgpremium,
    "totalsurrendervalue": totalsurrendervalue,
  };
}

class FamilyFinanceAssetsGeneralInsurance {
  List<FamilyFinanceAssetsGeneralInsuranceDatum> data;
  String name;
  FamilyFinanceAssetsGeneralInsuranceSummary summary;

  FamilyFinanceAssetsGeneralInsurance({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceAssetsGeneralInsurance.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsGeneralInsurance(
    data: List<FamilyFinanceAssetsGeneralInsuranceDatum>.from(
      json["data"].map(
        (x) => FamilyFinanceAssetsGeneralInsuranceDatum.fromJson(x),
      ),
    ),
    name: json["name"],
    summary: FamilyFinanceAssetsGeneralInsuranceSummary.fromJson(
      json["summary"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceAssetsGeneralInsuranceDatum {
  String fipid;
  String fipname;
  String userguid;
  String uinnumber;
  String policyname;
  String policytype;
  double sumassured;
  String accountguid;
  String policynumber;
  String policystatus;
  double tenuremonths;
  String insurancetype;
  String linkrefnumber;
  double premiumamount;
  String policystartdate;
  String policyexpirydate;
  String premiumfrequency;
  String policydescription;
  String maskedpolicynumber;
  String nextpremiumduedate;
  double premiumpaymentyears;

  FamilyFinanceAssetsGeneralInsuranceDatum({
    required this.fipid,
    required this.fipname,
    required this.userguid,
    required this.uinnumber,
    required this.policyname,
    required this.policytype,
    required this.sumassured,
    required this.accountguid,
    required this.policynumber,
    required this.policystatus,
    required this.tenuremonths,
    required this.insurancetype,
    required this.linkrefnumber,
    required this.premiumamount,
    required this.policystartdate,
    required this.policyexpirydate,
    required this.premiumfrequency,
    required this.policydescription,
    required this.maskedpolicynumber,
    required this.nextpremiumduedate,
    required this.premiumpaymentyears,
  });

  factory FamilyFinanceAssetsGeneralInsuranceDatum.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsGeneralInsuranceDatum(
    fipid: json["fipid"],
    fipname: json["fipname"],
    userguid: json["userguid"],
    uinnumber: json["uinnumber"],
    policyname: json["policyname"],
    policytype: json["policytype"],
    sumassured: json["sumassured"]?.toDouble() ?? 0.0,
    accountguid: json["accountguid"],
    policynumber: json["policynumber"],
    policystatus: json["policystatus"],
    tenuremonths: json["tenuremonths"]?.toDouble() ?? 0.0,
    insurancetype: json["insurancetype"],
    linkrefnumber: json["linkrefnumber"],
    premiumamount: json["premiumamount"]?.toDouble() ?? 0.0,
    policystartdate: json["policystartdate"],
    policyexpirydate: json["policyexpirydate"],
    premiumfrequency: json["premiumfrequency"],
    policydescription: json["policydescription"],
    maskedpolicynumber: json["maskedpolicynumber"],
    nextpremiumduedate: json["nextpremiumduedate"],
    premiumpaymentyears: json["premiumpaymentyears"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "fipid": fipid,
    "fipname": fipname,
    "userguid": userguid,
    "uinnumber": uinnumber,
    "policyname": policyname,
    "policytype": policytype,
    "sumassured": sumassured,
    "accountguid": accountguid,
    "policynumber": policynumber,
    "policystatus": policystatus,
    "tenuremonths": tenuremonths,
    "insurancetype": insurancetype,
    "linkrefnumber": linkrefnumber,
    "premiumamount": premiumamount,
    "policystartdate": policystartdate,
    "policyexpirydate": policyexpirydate,
    "premiumfrequency": premiumfrequency,
    "policydescription": policydescription,
    "maskedpolicynumber": maskedpolicynumber,
    "nextpremiumduedate": nextpremiumduedate,
    "premiumpaymentyears": premiumpaymentyears,
  };
}

class FamilyFinanceAssetsGeneralInsuranceSummary {
  double totalsum;
  double avgpremium;

  FamilyFinanceAssetsGeneralInsuranceSummary({
    required this.totalsum,
    required this.avgpremium,
  });

  factory FamilyFinanceAssetsGeneralInsuranceSummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsGeneralInsuranceSummary(
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    avgpremium: json["avgpremium"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "totalsum": totalsum,
    "avgpremium": avgpremium,
  };
}

class FamilyFinanceAssetsInsurancePolicies {
  List<FamilyFinanceAssetsInsurancePoliciesDatum> data;
  String name;
  FamilyFinanceAssetsInsurancePoliciesSummary summary;

  FamilyFinanceAssetsInsurancePolicies({
    required this.data,
    required this.name,
    required this.summary,
  });

  factory FamilyFinanceAssetsInsurancePolicies.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsurancePolicies(
    data: List<FamilyFinanceAssetsInsurancePoliciesDatum>.from(
      json["data"].map(
        (x) => FamilyFinanceAssetsInsurancePoliciesDatum.fromJson(x),
      ),
    ),
    name: json["name"],
    summary: FamilyFinanceAssetsInsurancePoliciesSummary.fromJson(
      json["summary"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "name": name,
    "summary": summary.toJson(),
  };
}

class FamilyFinanceAssetsInsurancePoliciesDatum {
  String fipid;
  String? branch;
  String? covers;
  String fipname;
  String nominee;
  String userguid;
  String policyname;
  String policytype;
  double? sumassured;
  String accountguid;
  String? insurername;
  String? nomineetype;
  double tenureyears;
  String policynumber;
  double tenuremonths;
  String linkrefnumber;
  String? modeofholding;
  String? policyenddate;
  double premiumamount;
  double coverageamount;
  String? maturitybenefit;
  String policystartdate;
  String premiumfrequency;
  double premiumpaymentyears;
  double premiumpaymentmonths;

  FamilyFinanceAssetsInsurancePoliciesDatum({
    required this.fipid,
    this.branch,
    this.covers,
    required this.fipname,
    required this.nominee,
    required this.userguid,
    required this.policyname,
    required this.policytype,
    this.sumassured,
    required this.accountguid,
    this.insurername,
    this.nomineetype,
    required this.tenureyears,
    required this.policynumber,
    required this.tenuremonths,
    required this.linkrefnumber,
    this.modeofholding,
    this.policyenddate,
    required this.premiumamount,
    required this.coverageamount,
    this.maturitybenefit,
    required this.policystartdate,
    required this.premiumfrequency,
    required this.premiumpaymentyears,
    required this.premiumpaymentmonths,
  });

  factory FamilyFinanceAssetsInsurancePoliciesDatum.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsurancePoliciesDatum(
    fipid: json["fipid"],
    branch: json["branch"],
    covers: json["covers"],
    fipname: json["fipname"],
    nominee: json["nominee"],
    userguid: json["userguid"],
    policyname: json["policyname"],
    policytype: json["policytype"],
    sumassured: json["sumassured"]?.toDouble(),
    accountguid: json["accountguid"],
    insurername: json["insurername"],
    nomineetype: json["nomineetype"],
    tenureyears: json["tenureyears"]?.toDouble() ?? 0.0,
    policynumber: json["policynumber"],
    tenuremonths: json["tenuremonths"]?.toDouble() ?? 0.0,
    linkrefnumber: json["linkrefnumber"],
    modeofholding: json["modeofholding"],
    policyenddate: json["policyenddate"],
    premiumamount: json["premiumamount"]?.toDouble() ?? 0.0,
    coverageamount: json["coverageamount"]?.toDouble() ?? 0.0,
    maturitybenefit: json["maturitybenefit"],
    policystartdate: json["policystartdate"],
    premiumfrequency: json["premiumfrequency"],
    premiumpaymentyears: json["premiumpaymentyears"]?.toDouble() ?? 0.0,
    premiumpaymentmonths: json["premiumpaymentmonths"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "fipid": fipid,
    "branch": branch,
    "covers": covers,
    "fipname": fipname,
    "nominee": nominee,
    "userguid": userguid,
    "policyname": policyname,
    "policytype": policytype,
    "sumassured": sumassured,
    "accountguid": accountguid,
    "insurername": insurername,
    "nomineetype": nomineetype,
    "tenureyears": tenureyears,
    "policynumber": policynumber,
    "tenuremonths": tenuremonths,
    "linkrefnumber": linkrefnumber,
    "modeofholding": modeofholding,
    "policyenddate": policyenddate,
    "premiumamount": premiumamount,
    "coverageamount": coverageamount,
    "maturitybenefit": maturitybenefit,
    "policystartdate": policystartdate,
    "premiumfrequency": premiumfrequency,
    "premiumpaymentyears": premiumpaymentyears,
    "premiumpaymentmonths": premiumpaymentmonths,
  };
}

class FamilyFinanceAssetsInsurancePoliciesSummary {
  double totalsum;
  double avgpremium;
  double totalcoverage;

  FamilyFinanceAssetsInsurancePoliciesSummary({
    required this.totalsum,
    required this.avgpremium,
    required this.totalcoverage,
  });

  factory FamilyFinanceAssetsInsurancePoliciesSummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsurancePoliciesSummary(
    totalsum: json["totalsum"]?.toDouble() ?? 0.0,
    avgpremium: json["avgpremium"]?.toDouble() ?? 0.0,
    totalcoverage: json["totalcoverage"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "totalsum": totalsum,
    "avgpremium": avgpremium,
    "totalcoverage": totalcoverage,
  };
}

class FamilyFinanceAssetsInsuranceSummary {
  FamilyFinanceAssetsLifeInsuranceSummary lifeInsurance;
  FamilyFinanceAssetsGeneralInsuranceSummary generalInsurance;
  FamilyFinanceAssetsInsurancePoliciesSummary insurancePolicies;

  FamilyFinanceAssetsInsuranceSummary({
    required this.lifeInsurance,
    required this.generalInsurance,
    required this.insurancePolicies,
  });

  factory FamilyFinanceAssetsInsuranceSummary.fromJson(
    Map<String, dynamic> json,
  ) => FamilyFinanceAssetsInsuranceSummary(
    lifeInsurance: FamilyFinanceAssetsLifeInsuranceSummary.fromJson(
      json["life_insurance"],
    ),
    generalInsurance: FamilyFinanceAssetsGeneralInsuranceSummary.fromJson(
      json["general_insurance"],
    ),
    insurancePolicies: FamilyFinanceAssetsInsurancePoliciesSummary.fromJson(
      json["insurance_policies"],
    ),
  );

  Map<String, dynamic> toJson() => {
    "life_insurance": lifeInsurance.toJson(),
    "general_insurance": generalInsurance.toJson(),
    "insurance_policies": insurancePolicies.toJson(),
  };
}
