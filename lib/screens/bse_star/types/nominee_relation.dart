class BseNomineeRelationResponse {
    String message;
    List<Datum> ?data;

    BseNomineeRelationResponse({
        required this.message,
         this.data,
    });

    factory BseNomineeRelationResponse.fromJson(Map<String, dynamic> json) => BseNomineeRelationResponse(
        message: json["message"],
        data: json["data"] != null ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))) : null,
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "data": data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : null,
    };
}

class Datum {
    String id;
    String name;

    Datum({
        required this.id,
        required this.name,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}
