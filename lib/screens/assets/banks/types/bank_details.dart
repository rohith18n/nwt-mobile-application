class BankDetailsResponse {
  int statusCode;
  String message;
  Data data;

  BankDetailsResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory BankDetailsResponse.fromJson(Map<String, dynamic> json) =>
      BankDetailsResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  String? guid;
  String? accountguid;
  String? accounttype;
  String? accountsubtype;
  String? branch;
  String? ifsc;
  String? openingdate;
  String? fipname;
  String? maskedaccnumber;
  int? tenureyears;
  String? linkrefnumber;
  double? maturityamount;
  String? maturitydate;
  int? tenuredays;
  int? tenuremonths;
  String? createdat;
  String? updatedat;
  String? interestpayout;
  Profile? profile;

  Data({
    this.guid,
    this.accountguid,
    this.accounttype,
    this.accountsubtype,
    this.branch,
    this.ifsc,
    this.openingdate,
    this.fipname,
    this.maskedaccnumber,
    this.tenureyears,
    this.linkrefnumber,
    this.maturityamount,
    this.maturitydate,
    this.tenuredays,
    this.tenuremonths,
    this.createdat,
    this.updatedat,
    this.interestpayout,
    this.profile,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    guid: json["guid"],
    accountguid: json["accountguid"],
    accounttype: json["accounttype"],
    accountsubtype: json["accountsubtype"],
    branch: json["branch"],
    ifsc: json["ifsc"],
    openingdate: json["openingdate"],
    fipname: json["fipname"],
    maskedaccnumber: json["maskedaccnumber"],
    tenureyears: json["tenureyears"],
    linkrefnumber: json["linkrefnumber"],
    maturityamount: json["maturityamount"]?.toDouble(),
    maturitydate: json["maturitydate"],
    tenuredays: json["tenuredays"],
    tenuremonths: json["tenuremonths"],
    createdat: json["createdat"],
    updatedat: json["updatedat"],
    interestpayout: json["interestpayout"],
    profile: Profile.fromJson(json["profile"]),
  );

  Map<String, dynamic> toJson() => {
    "guid": guid,
    "accountguid": accountguid,
    "accounttype": accounttype,
    "accountsubtype": accountsubtype,
    "branch": branch,
    "ifsc": ifsc,
    "openingdate": openingdate,
    "fipname": fipname,
    "maskedaccnumber": maskedaccnumber,
    "tenureyears": tenureyears,
    "linkrefnumber": linkrefnumber,
    "maturityamount": maturityamount,
    "maturitydate": maturitydate,
    "tenuredays": tenuredays,
    "tenuremonths": tenuremonths,
    "createdat": createdat,
    "updatedat": updatedat,
    "profile": profile?.toJson(),
  };
}

class Profile {
  int? id;
  String? name;
  String? nominee;
  bool? ckycregistered;
  String? createdat;
  String? updatedat;
  String? userguid;

  Profile({
    this.id,
    this.name,
    this.nominee,
    this.ckycregistered,
    this.createdat,
    this.updatedat,
    this.userguid,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json["id"],
    name: json["name"],
    nominee: json["nominee"],
    ckycregistered: json["ckycregistered"],
    createdat: json["createdat"],
    updatedat: json["updatedat"],
    userguid: json["userguid"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "nominee": nominee,
    "ckycregistered": ckycregistered,
    "createdat": createdat,
    "updatedat": updatedat,
    "userguid": userguid,
  };
}
