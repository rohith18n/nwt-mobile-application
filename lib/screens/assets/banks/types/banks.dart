class BankSummaryResponse {
  int status;
  String message;
  BankSummaryData? data;
  bool get success => status == 200 || status == 201;

  BankSummaryResponse({required this.status, required this.message, this.data});

  factory BankSummaryResponse.fromJson(
    Map<String, dynamic> json,
  ) => BankSummaryResponse(
    status: json["statusCode"],
    message: json["message"],
    data: json["data"] != null ? BankSummaryData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class BankSummaryData {
  List<Bank> banks;
  double totalbalance;
  double totalamount;
  double totalpercentage;
  double? deltavalue;
  double? deltapercentage;
  String? latestbalancedatetime;

  BankSummaryData({
    required this.banks,
    required this.totalbalance,
    required this.totalamount,
    required this.totalpercentage,
    this.deltavalue,
    this.deltapercentage,
    this.latestbalancedatetime,
  });

  factory BankSummaryData.fromJson(Map<String, dynamic> json) =>
      BankSummaryData(
        banks: List<Bank>.from(json["banks"].map((x) => Bank.fromJson(x))),
        totalbalance: (json["totalbalance"] as num).toDouble(),
        totalamount: (json["totalamount"] as num).toDouble(),
        totalpercentage: (json["totalpercentage"] as num).toDouble(),
        deltavalue:
            json["deltavalue"] != null
                ? (json["deltavalue"] as num).toDouble()
                : null,
        deltapercentage:
            json["deltapercentage"] != null
                ? (json["deltapercentage"] as num).toDouble()
                : null,
        latestbalancedatetime:
            json["latestbalancedatetime"]?.toString() ??
            DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
    "banks": List<dynamic>.from(banks.map((x) => x.toJson())),
    "totalbalance": totalbalance,
    "totalamount": totalamount,
    "totalpercentage": totalpercentage,
    "deltavalue": deltavalue,
    "deltapercentage": deltapercentage,
    "latestbalancedatetime": latestbalancedatetime,
  };
}

class Bank {
  String guid;
  String? fitype;
  String fipid;
  String fipname;
  String linkrefnumber;
  String maskedaccountid;
  double currentvalue;
  DateTime? balancedatetime;
  bool isprimary;
  DateTime addedat;
  double deltavalue;
  double? interestrate;
  double? recurringamount;
  double? principalamount;
  double deltapercentage;
  bool havedata;
  String? type;
  String? branch;
  String? ifsc;
  Profile profile;

  Bank({
    required this.guid,
    required this.fipid,
    required this.fipname,
    required this.linkrefnumber,
    required this.maskedaccountid,
    required this.currentvalue,
    this.balancedatetime,
    required this.isprimary,
    required this.addedat,
    required this.deltavalue,
    this.interestrate,
    this.recurringamount,
    this.principalamount,
    required this.deltapercentage,
    required this.havedata,
    this.type,
    this.branch,
    this.ifsc,
    required this.profile,
  });

  // Helper to parse numeric values that can be strings or numbers
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  // Helper to parse DateTime that can be timestamp (int) or ISO string
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // Timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
    guid: json["guid"] ?? json["linkedAccRef"] ?? json["accountguid"] ?? '',
    fipid: json["fipid"] ?? json["fipId"] ?? '',
    fipname: json["fipname"] ?? json["fipName"] ?? '',
    linkrefnumber: json["linkrefnumber"] ?? json["linkRefNumber"] ?? '',
    maskedaccountid:
        json["maskedaccountid"] ??
        json["maskedAccNumber"] ??
        json["maskedaccnumber"] ??
        '',
    currentvalue: _parseDouble(json["currentvalue"] ?? json["currentBalance"]),
    balancedatetime: _parseDateTime(
      json["balancedatetime"] ?? json["balanceDateTime"],
    ),
    isprimary: json["isprimary"] ?? false,
    addedat: _parseDateTime(json["addedat"]) ?? DateTime.now(),
    deltavalue: _parseDouble(json["deltavalue"]),
    interestrate:
        json["interestrate"] != null
            ? _parseDouble(json["interestrate"])
            : (json["interestRate"] != null
                ? _parseDouble(json["interestRate"])
                : null),
    recurringamount:
        json["recurringamount"] != null
            ? _parseDouble(json["recurringamount"])
            : null,
    principalamount:
        json["principalamount"] != null
            ? _parseDouble(json["principalamount"])
            : null,
    deltapercentage: _parseDouble(json["deltapercentage"]),
    havedata: json["havedata"] ?? true,
    type: json["type"] ?? json["account_type"],
    branch: json["branch"],
    ifsc: json["ifsc"] ?? json["ifscCode"],
    profile:
        json["profile"] != null
            ? Profile.fromJson(json["profile"])
            : Profile(nominee: ''),
  );

  Map<String, dynamic> toJson() => {
    "guid": guid,
    "fipid": fipid,
    "fipname": fipname,
    "linkrefnumber": linkrefnumber,
    "maskedaccountid": maskedaccountid,
    "currentvalue": currentvalue,
    "balancedatetime": balancedatetime?.toIso8601String(),
    "isprimary": isprimary,
    "addedat": addedat.toIso8601String(),
    "deltavalue": deltavalue,
    "interestrate": interestrate,
    "recurringamount": recurringamount,
    "principalamount": principalamount,
    "deltapercentage": deltapercentage,
    "havedata": havedata,
    "type": type,
    "branch": branch,
    "ifsc": ifsc,
    "profile": profile.toJson(),
  };
}

class Profile {
  // int id;
  // String accountguid;
  String? name;
  // String dob;
  // String mobile;
  String? nominee;
  // String? landline;
  // String address;
  // String email;
  // String pan;
  // bool ckycregistered;
  // DateTime createdat;
  // DateTime updatedat;
  // String userguid;
  // String type;

  Profile({
    // required this.id,
    // required this.accountguid,
    this.name,
    // required this.dob,
    // required this.mobile,
    this.nominee,
    // this.landline,
    // required this.address,
    // required this.email,
    // required this.pan,
    // required this.ckycregistered,
    // required this.createdat,
    // required this.updatedat,
    // required this.userguid,
    // required this.type,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    // id: json["id"],
    // accountguid: json["accountguid"],
    name: json["name"],
    // dob: json["dob"],
    // mobile: json["mobile"],
    nominee: json["nominee"],
    // landline: json["landline"],
    // address: json["address"],
    // email: json["email"],
    // pan: json["pan"],
    // ckycregistered: json["ckycregistered"],
    // createdat: DateTime.parse(json["createdat"]),
    // updatedat: DateTime.parse(json["updatedat"]),
    // userguid: json["userguid"],
    // type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    // "id": id,
    // "accountguid": accountguid,
    "name": name,
    // "dob": dob,
    // "mobile": mobile,
    "nominee": nominee,
    // "landline": landline,
    // "address": address,
    // "email": email,
    // "pan": pan,
    // "ckycregistered": ckycregistered,
    // "createdat": createdat.toIso8601String(),
    // "updatedat": updatedat.toIso8601String(),
    // "userguid": userguid,
    // "type": type,
  };
}
