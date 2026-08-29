class BseAddressManagement {
    int statusCode;
    String message;
    Data ?data;

    BseAddressManagement({
        required this.statusCode,
        required this.message,
        required this.data,
    });

    factory BseAddressManagement.fromJson(Map<String, dynamic> json) => BseAddressManagement(
        statusCode: json["statusCode"],
        message: json["message"],
        data:  json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String addressType;
    String line1;
    String line2;
    dynamic line3;
    String city;
    String state;
    String country;
    String postalCode;
    String id;
    String holderId;

    Data({
        required this.addressType,
        required this.line1,
        required this.line2,
        required this.line3,
        required this.city,
        required this.state,
        required this.country,
        required this.postalCode,
        required this.id,
        required this.holderId,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        addressType: json["address_type"],
        line1: json["line1"],
        line2: json["line2"],
        line3: json["line3"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        postalCode: json["postal_code"],
        id: json["id"],
        holderId: json["holder_id"],
    );

    Map<String, dynamic> toJson() => {
        "address_type": addressType,
        "line1": line1,
        "line2": line2,
        "line3": line3,
        "city": city,
        "state": state,
        "country": country,
        "postal_code": postalCode,
        "id": id,
        "holder_id": holderId,
    };
}
