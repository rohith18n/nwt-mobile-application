class FamilyDashboardAssetsResponse {
  int statusCode;
  String message;
  FamilyDashboardAssetsData? data;

  FamilyDashboardAssetsResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyDashboardAssetsResponse.fromJson(Map<String, dynamic> json) =>
      FamilyDashboardAssetsResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyDashboardAssetsData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyDashboardAssetsData {
  List<Member> members;
  List<Summary> summary;
  double total;
  String familylastname;
  String familyid;

  FamilyDashboardAssetsData({
    required this.members,
    required this.summary,
    required this.total,
    required this.familylastname,
    required this.familyid,
  });

  factory FamilyDashboardAssetsData.fromJson(Map<String, dynamic> json) =>
      FamilyDashboardAssetsData(
        members: List<Member>.from(
          json["members"].map((x) => Member.fromJson(x)),
        ),
        summary: List<Summary>.from(
          json["summary"].map((x) => Summary.fromJson(x)),
        ),
        total: json["total"]?.toDouble() ?? 0.0,
        familylastname: json["familylastname"],
        familyid: json["familyid"],
      );

  Map<String, dynamic> toJson() => {
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "summary": List<dynamic>.from(summary.map((x) => x.toJson())),
    "total": total,
    "familylastname": familylastname,
    "familyid": familyid,
  };
}

class Member {
  String userguid;
  String firstname;
  String lastname;
  double individualtotal;

  Member({
    required this.userguid,
    required this.firstname,
    required this.lastname,
    required this.individualtotal,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    userguid: json["userguid"],
    firstname: json["firstname"],
    lastname: json["lastname"],
    individualtotal: json["individualtotal"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "userguid": userguid,
    "firstname": firstname,
    "lastname": lastname,
    "individualtotal": individualtotal,
  };
}

class Summary {
  String id;
  String title;
  double value;
  double deltapercentage;
  double deltavalue;

  Summary({
    required this.id,
    required this.title,
    required this.value,
    required this.deltapercentage,
    required this.deltavalue,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    id: json["id"],
    title: json["title"],
    value: json["value"]?.toDouble() ?? 0.0,
    deltapercentage: json["deltapercentage"]?.toDouble() ?? 0.0,
    deltavalue: json["deltavalue"]?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "value": value,
    "deltapercentage": deltapercentage,
    "deltavalue": deltavalue,
  };
}
