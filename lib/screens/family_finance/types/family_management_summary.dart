class FamilyManagementSummaryResponse {
  int statusCode;
  String message;
  FamilyManagementSummaryData? data;

  FamilyManagementSummaryResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory FamilyManagementSummaryResponse.fromJson(Map<String, dynamic> json) =>
      FamilyManagementSummaryResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data:
            json["data"] != null
                ? FamilyManagementSummaryData.fromJson(json["data"])
                : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FamilyManagementSummaryData {
  String firstname;
  String lastname;
  String? panname;
  String? gender;
  String guid;
  DateTime createdat;
  DateTime updatedat;
  double totalsum;
  String lastfetch;
  String relation;
  String relationid;
  String phonenumber;

  FamilyManagementSummaryData({
    required this.firstname,
    required this.lastname,
    this.panname,
    this.gender,
    required this.guid,
    required this.createdat,
    required this.updatedat,
    required this.totalsum,
    required this.lastfetch,
    required this.relation,
    required this.relationid,
    required this.phonenumber,
  });

  factory FamilyManagementSummaryData.fromJson(Map<String, dynamic> json) =>
      FamilyManagementSummaryData(
        firstname: json["firstname"],
        lastname: json["lastname"],
        panname: json["panname"],
        gender: json["gender"],
        guid: json["guid"],
        createdat: DateTime.parse(json["createdat"]),
        updatedat: DateTime.parse(json["updatedat"]),
        totalsum: json["totalsum"]?.toDouble(),
        lastfetch: json["lastfetch"],
        relation: json["relation"],
        relationid: json["relationid"],
        phonenumber: json["phonenumber"],
      );

  Map<String, dynamic> toJson() => {
    "firstname": firstname,
    "lastname": lastname,
    "panname": panname,
    "gender": gender,
    "guid": guid,
    "createdat": createdat.toIso8601String(),
    "updatedat": updatedat.toIso8601String(),
    "totalsum": totalsum,
    "lastfetch": lastfetch,
    "relation": relation,
    "relationid": relationid,
    "phonenumber": phonenumber,
  };
}
