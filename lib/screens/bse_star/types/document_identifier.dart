class DocumentIdentifierTypeResponse {
    int statusCode;
    List<Datum> data;
    String message;

    DocumentIdentifierTypeResponse({
        required this.statusCode,
        required this.data,
        required this.message,
    });

    factory DocumentIdentifierTypeResponse.fromJson(Map<String, dynamic> json) => DocumentIdentifierTypeResponse(
        statusCode: json["statusCode"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "message": message,
    };
}

class Datum {
    String identifierType;
    String identifierValue;

    Datum({
        required this.identifierType,
        required this.identifierValue,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        identifierType: json["identifier_type"],
        identifierValue: json["identifier_value"],
    );

    Map<String, dynamic> toJson() => {
        "identifier_type": identifierType,
        "identifier_value": identifierValue,
    };
}
