class FamilyMemberAddResponse {
  int statusCode;
  String message;
  FamilyMemberAddResponseData? data;

  FamilyMemberAddResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyMemberAddResponse.fromJson(Map<String, dynamic> json) =>
      FamilyMemberAddResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyMemberAddResponseData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyMemberAddResponseData {
  String creatorfirstname;
  String creatorlastname;
  String familyid;
  String invitationid;
  String memberfirstname;
  String memberlastname;
  String memberphonenumber;
  String expiresat;
  String updatedat;

  FamilyMemberAddResponseData({
    required this.creatorfirstname,
    required this.creatorlastname,
    required this.familyid,
    required this.invitationid,
    required this.memberfirstname,
    required this.memberlastname,
    required this.memberphonenumber,
    required this.expiresat,
    required this.updatedat,
  });

  factory FamilyMemberAddResponseData.fromJson(Map<String, dynamic> json) =>
      FamilyMemberAddResponseData(
        creatorfirstname: json["creatorfirstname"],
        creatorlastname: json["creatorlastname"],
        familyid: json["familyid"],
        invitationid: json["invitationid"],
        memberfirstname: json["memberfirstname"],
        memberlastname: json["memberlastname"],
        memberphonenumber: json["memberphonenumber"],
        expiresat: json["expiresat"],
        updatedat: json["updatedat"],
      );

  Map<String, dynamic> toJson() => {
    "creatorfirstname": creatorfirstname,
    "creatorlastname": creatorlastname,
    "familyid": familyid,
    "invitationid": invitationid,
    "memberfirstname": memberfirstname,
    "memberlastname": memberlastname,
    "memberphonenumber": memberphonenumber,
    "expiresat": expiresat,
    "updatedat": updatedat,
  };
}
