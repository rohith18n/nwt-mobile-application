class AdhocRemaingResponse {
    int statusCode;
    String message;
    Data? data;

    AdhocRemaingResponse({
        required this.statusCode,
        required this.message,
        this.data,
    });

    factory AdhocRemaingResponse.fromJson(Map<String, dynamic> json) => AdhocRemaingResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    double adhocRemaining;

    Data({
        required this.adhocRemaining,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        adhocRemaining: json["adhoc_remaining"]?.toDouble() ?? 0.0,
    );

    Map<String, dynamic> toJson() => {
        "adhoc_remaining": adhocRemaining,
    };
}
