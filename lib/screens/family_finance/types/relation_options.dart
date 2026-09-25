class RelationOptionResponse {
  int statusCode;
  String message;
  List<RelationOption> data;

  RelationOptionResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory RelationOptionResponse.fromJson(Map<String, dynamic> json) =>
      RelationOptionResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: List<RelationOption>.from(
          json["data"].map((x) => RelationOption.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class RelationOption {
  String codeId;
  String name;

  RelationOption({required this.codeId, required this.name});

  factory RelationOption.fromJson(Map<String, dynamic> json) =>
      RelationOption(codeId: json["codeId"], name: json["name"]);

  Map<String, dynamic> toJson() => {"codeId": codeId, "name": name};
}
