// class PanVerificationResponse {
//   int status;
//   String message;
//   bool get success => status == 200 || status == 201;

//   PanVerificationResponse({required this.status, required this.message});

//   factory PanVerificationResponse.fromJson(Map<String, dynamic> json) =>
//       PanVerificationResponse(
//         status: json["statusCode"],
//         message: json["message"],
//       );

//   Map<String, dynamic> toJson() => {"status": status, "message": message};
// }


// To parse this JSON data, do
//
//     final panVerificationResponse = panVerificationResponseFromJson(jsonString);
class PanVerificationResponse {
    String message;
    Data? data;
    int status;
    bool get success => status == 200 || status == 201;

    PanVerificationResponse({
        required this.message,
        required this.data,
        required this.status,
    });

    factory PanVerificationResponse.fromJson(Map<String, dynamic> json) => PanVerificationResponse(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "data": data?.toJson(),
        "status": status,
    };
}

class Data {
    String pan;
    String type;
    int referenceId;
    String nameProvided;
    String registeredName;
    String fatherName;
    bool valid;
    String message;
    String ?dob;
    String? full_address;
    String? city;
    String? state;
    String? country;
    String? pin_code;

    Data({
        required this.pan,
        required this.type,
        required this.referenceId,
        required this.nameProvided,
        required this.registeredName,
        required this.fatherName,
        required this.valid,
        required this.message,
        this.dob,
        this.full_address,
        this.city,
        this.state,
        this.country,
        this.pin_code,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        pan: json["pan"],
        type: json["type"],
        referenceId: json["reference_id"],
        nameProvided: json["name_provided"],
        registeredName: json["registered_name"],
        fatherName: json["father_name"],
        valid: json["valid"],
        message: json["message"],
        dob: json["dob"]??'',
        full_address: json["full_address"]??'',
        city: json["city"]??'',
        state: json["state"]??'',
        country: json["country"]??'',
        pin_code: json["pin_code"]??'',
      );

    Map<String, dynamic> toJson() => {
        "pan": pan,
        "type": type,
        "reference_id": referenceId,
        "name_provided": nameProvided,
        "registered_name": registeredName,
        "father_name": fatherName,
        "valid": valid,
        "message": message,
        "dob": dob,
        "full_address": full_address,
        "city": city,
        "state": state,
        "country": country,
        "pin_code": pin_code,
    };
}
