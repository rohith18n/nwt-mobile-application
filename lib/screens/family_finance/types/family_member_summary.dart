class FamilyMemberSummaryResponse {
  int statusCode;
  String message;
  FamilyMemberSummaryResponseData? data;

  FamilyMemberSummaryResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyMemberSummaryResponse.fromJson(Map<String, dynamic> json) =>
      FamilyMemberSummaryResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyMemberSummaryResponseData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyMemberSummaryResponseData {
  FamilyMemberSummaryResponseFamily family;
  List<Member> members;

  FamilyMemberSummaryResponseData({
    required this.family,
    required this.members,
  });

  factory FamilyMemberSummaryResponseData.fromJson(Map<String, dynamic> json) =>
      FamilyMemberSummaryResponseData(
        family: FamilyMemberSummaryResponseFamily.fromJson(json["family"]),
        members: List<Member>.from(
          json["members"].map((x) => Member.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "family": family.toJson(),
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
  };
}

class FamilyMemberSummaryResponseFamily {
  String familyid;
  String lastname;
  DateTime createdat;
  DateTime updatedat;
  double totalsum;
  String lastfetch;

  FamilyMemberSummaryResponseFamily({
    required this.familyid,
    required this.lastname,
    required this.createdat,
    required this.updatedat,
    required this.totalsum,
    required this.lastfetch,
  });

  factory FamilyMemberSummaryResponseFamily.fromJson(
    Map<String, dynamic> json,
  ) => FamilyMemberSummaryResponseFamily(
    familyid: json["familyid"],
    lastname: json["lastname"],
    createdat: DateTime.parse(json["createdat"]),
    updatedat: DateTime.parse(json["updatedat"]),
    totalsum: json["totalsum"]?.toDouble(),
    lastfetch: json["lastfetch"],
  );

  Map<String, dynamic> toJson() => {
    "familyid": familyid,
    "lastname": lastname,
    "createdat": createdat.toIso8601String(),
    "updatedat": updatedat.toIso8601String(),
    "totalsum": totalsum,
    "lastfetch": lastfetch,
  };
}

class Member {
  String familyuserid;
  String familyid;
  String userguid;
  String status;
  String relation;
  String relationid; // Added relationid field
  String? gender;
  String firstname;
  String lastname;
  String? panname;
  String? expiresat;
  double? networth;
  String phonenumber;
  bool assetconsent;
  String invitedat;

  Member({
    required this.familyuserid,
    required this.familyid,
    required this.userguid,
    required this.status,
    required this.relation,
    required this.relationid,
    this.gender,
    required this.firstname,
    required this.lastname,
    this.panname,
    required this.expiresat,
    this.networth,
    required this.phonenumber,
    required this.assetconsent,
    required this.invitedat,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    familyuserid: json["familyuserid"],
    familyid: json["familyid"],
    userguid: json["userguid"],
    status: json["status"],
    relation: json["relation"],
    relationid: json["relationid"],
    gender: json["gender"],
    firstname: json["firstname"],
    lastname: json["lastname"],
    panname: json["panname"],
    expiresat: json["expiresat"],
    networth: json["networth"]?.toDouble(),
    phonenumber: json["phonenumber"],
    assetconsent: json["assetconsent"],
    invitedat: json["invitedat"],
  );

  Map<String, dynamic> toJson() => {
    "familyuserid": familyuserid,
    "familyid": familyid,
    "userguid": userguid,
    "status": status,
    "relation": relation,
    "relationid": relationid,
    "gender": gender,
    "firstname": firstname,
    "lastname": lastname,
    "panname": panname,
    "expiresat": expiresat,
    "networth": networth,
    "phonenumber": phonenumber,
    "assetconsent": assetconsent,
    "invitedat": invitedat,
  };
}
