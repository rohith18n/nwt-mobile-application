class BseHolderManagement {
    int statusCode;
    String message;
    Data? data;

    BseHolderManagement({
        required this.statusCode,
        required this.message,
        required this.data,
    });

    factory BseHolderManagement.fromJson(Map<String, dynamic> json) => BseHolderManagement(
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
    int ?holderRank;
    String? firstName;
    dynamic middleName;
    String? lastName;
    String? pan;
    DateTime? dob;
    String? gender;
    dynamic ckycNumber;
    String? phone;
    String? email;
    String? politicallyExposedPerson;
    String? id;
    bool? isPrimary;
    bool? isPhoneVerified;
    bool? isEmailVerified;

    Data({
         this.holderRank,
         this.firstName,
         this.middleName,
         this.lastName,
         this.pan,
         this.dob,
         this.gender,
         this.ckycNumber,
         this.phone,
         this.email,
         this.politicallyExposedPerson,
         this.id,
         this.isPrimary,
         this.isPhoneVerified,
         this.isEmailVerified,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        holderRank: json["holder_rank"],
        firstName: json["first_name"],
        middleName: json["middle_name"],
        lastName: json["last_name"],
        pan: json["pan"],
        dob: DateTime.parse(json["dob"]),
        gender: json["gender"],
        ckycNumber: json["ckyc_number"],
        phone: json["phone"],
        email: json["email"],
        politicallyExposedPerson: json["politically_exposed_person"],
        id: json["id"],
        isPrimary: json["is_primary"],
        isPhoneVerified: json["is_phone_verified"],
        isEmailVerified: json["is_email_verified"],
    );

    Map<String, dynamic> toJson() => {
        "holder_rank": holderRank,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "pan": pan,
        "dob": dob?.toIso8601String(),
        "gender": gender,
        "ckyc_number": ckycNumber,
        "phone": phone,
        "email": email,
        "politically_exposed_person": politicallyExposedPerson,
        "id": id,
        "is_primary": isPrimary,
        "is_phone_verified": isPhoneVerified,
        "is_email_verified": isEmailVerified,
    };
}
