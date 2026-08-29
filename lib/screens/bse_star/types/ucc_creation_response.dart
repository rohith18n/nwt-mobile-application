class UccResponse {
    String? message;
    Data? data;

    UccResponse({
        this.message,
        this.data,
    });

    factory UccResponse.fromJson(Map<String, dynamic> json) => UccResponse(
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String? panNumber;
    String? panName;
    String? dob;
    bool? isNri;
    String? email;
    String? ifscCode;
    String? bankAccountNumber;
    String? bankAccountType;
    String? gender;
    String? maritalStatus;
    SecondaryHolder? secondaryHolder;
    List<dynamic>? nominees;
    String? occupation;
    String? currentPage;
    bool? completed;
    String? address;
    String? city;
    String? state;
    String? country;
    String? pincode;
    int? currentStep;
    String? tin;
    bool? sameAsApplicantAddress;
    bool?is_nri;
    String? country_iso_code;
    String?taxCode;
    String?primaryOccCode;
    String?primaryFatcaName;
    String?primaryFatcaOccCode;
    String?primaryFatcaDob;
    String?primaryLogName;
    String?primaryPlaceOfBirth;
    String?primaryCountryOfBirth;
    String?primaryIdentifierNumber;
    String? primaryWealthSource;
    String?primaryIncomeSlab;
    String?primaryNetWorth;
    String?primaryFatherName;
    String?primaryDateOfNetWorth;
    String?primaryPoliticallyExposed;
    String?secondaryHolderFatcaName;
    String?secondaryHolderFatcaOccCode;
    String?secondaryHolderFatcaDob;
    String?secondHolderLogName;
    String?secondHolderPlaceOfBirth;
    String?secondHolderCountryOfBirth;
    String?secondHolderIdentifierNumber;
    String? secondHolderWealthSource;
    String?secondHolderIncomeSlab;
    String?secondHolderNetWorth;
    String?secondHolderDateOfNetWorth;
    String?secondHolderPoliticallyExposed;
    String?second_holder_gender;
    String?secondHolderFatherName;

    Data({
        this.panNumber,
        this.panName,
        this.dob,
        this.isNri,
        this.email,
        this.ifscCode,
        this.bankAccountNumber,
        this.bankAccountType,
        this.gender,
        this.maritalStatus,
        this.secondaryHolder,
        this.nominees,
        this.occupation,
        this.currentPage,
        this.completed,
        this.address,
        this.city,
        this.state,
        this.country,
        this.pincode,
        this.currentStep,
        this.tin,
        this.sameAsApplicantAddress,
        this.is_nri,
        this.country_iso_code,
        this.taxCode,
        this.primaryOccCode,
        this.primaryFatcaName,
        this.primaryFatcaOccCode,
        this.primaryFatcaDob,
        this.primaryLogName,
        this.primaryPlaceOfBirth,
        this.primaryCountryOfBirth,
        this.primaryIdentifierNumber,
        this.primaryWealthSource,
      this.primaryIncomeSlab,
        this.primaryNetWorth,
        this.primaryDateOfNetWorth,
        this.primaryFatherName,
        this.primaryPoliticallyExposed,
        this.secondaryHolderFatcaName,
        this.secondaryHolderFatcaOccCode,
        this.secondaryHolderFatcaDob,
        this.secondHolderLogName,
        this.secondHolderPlaceOfBirth,
        this.secondHolderCountryOfBirth,
        this.secondHolderIdentifierNumber,
        this.secondHolderWealthSource,
      this.secondHolderIncomeSlab,
        this.secondHolderNetWorth,
        this.secondHolderDateOfNetWorth,
        this.secondHolderPoliticallyExposed,
        this.second_holder_gender,
        this. secondHolderFatherName
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        panNumber: json["pan_number"],
        panName: json["pan_name"],
        dob: json["dob"],
        isNri: json["is_nri"],
        email: json["email"],
        ifscCode: json["ifsc_code"],
        bankAccountNumber: json["bank_account_number"],
        bankAccountType: json["bank_account_type"],
        gender: json["gender"],
        maritalStatus: json["marital_status"],
        secondaryHolder: json["secondary_holder"] != null ? SecondaryHolder.fromJson(json["secondary_holder"]) : null,
        nominees: json["nominees"] == null ? null : List<dynamic>.from((json["nominees"] as List).map((x) => x)),
        occupation: json["occupation"],
        currentPage: json["current_page"],
        completed: json["completed"],
        address: json["address"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        pincode: json["pincode"],
        currentStep: json["current_step"],
        tin: json["tin"],
        sameAsApplicantAddress: json["same_as_applicant_address"],
        is_nri: json["is_nri"],
        country_iso_code: json["country_iso_code"],
        taxCode: json["taxCode"],
        primaryOccCode: json["primaryOccCode"],
        primaryFatcaName: json["primaryFatcaName"],
        primaryFatcaOccCode: json["primaryFatcaOccCode"],
        primaryFatcaDob: json["primaryFatcaDob"],
        primaryLogName: json["primaryLogName"],
        primaryPlaceOfBirth: json["primaryPlaceOfBirth"],
        primaryCountryOfBirth: json["primaryCountryOfBirth"],
        primaryIdentifierNumber: json["primaryIdentifierNumber"],
        primaryWealthSource: json["primaryWealthSource"],
        primaryIncomeSlab: json["primaryIncomeSlab"],
        primaryNetWorth: json["primaryNetWorth"],
        primaryDateOfNetWorth: json["primaryDateOfNetWorth"],
        primaryFatherName:  json['primaryFatherName'], 
        primaryPoliticallyExposed: json["primaryPoliticallyExposed"],
        secondaryHolderFatcaName: json["secondaryHolderFatcaName"],
        secondaryHolderFatcaOccCode: json["secondaryHolderFatcaOccCode"],
        secondaryHolderFatcaDob: json["secondaryHolderFatcaDob"],
        secondHolderLogName: json["secondHolderLogName"],
        secondHolderPlaceOfBirth: json["secondHolderPlaceOfBirth"],
        secondHolderCountryOfBirth: json["secondHolderCountryOfBirth"],
        secondHolderIdentifierNumber: json["secondHolderIdentifierNumber"],
        secondHolderWealthSource: json["secondHolderWealthSource"],
        secondHolderIncomeSlab: json["secondHolderIncomeSlab"],
        secondHolderNetWorth: json["secondHolderNetWorth"],
        secondHolderDateOfNetWorth: json["secondHolderDateOfNetWorth"],
        secondHolderPoliticallyExposed: json["secondHolderPoliticallyExposed"],
        second_holder_gender: json["second_holder_gender"],
        secondHolderFatherName:json["secondHolderFatherName"]
    );

    Map<String, dynamic> toJson() => {
        "pan_number": panNumber,
        "pan_name": panName,
        "dob": dob,
        "is_nri": isNri,
        "email": email,
        "ifsc_code": ifscCode,
        "bank_account_number": bankAccountNumber,
        "bank_account_type": bankAccountType,
        "gender": gender,
        "marital_status": maritalStatus,
        "secondary_holder": secondaryHolder?.toJson(),
        "nominees": nominees == null ? null : List<dynamic>.from(nominees!.map((x) => x)),
        "occupation": occupation,
        "current_page": currentPage,
        "completed": completed,
        "address": address,
        "city": city,
        "state": state,
        "country": country,
        "pincode": pincode,
        "current_step": currentStep,
        "tin": tin,
        "same_as_applicant_address": sameAsApplicantAddress,
        "country_iso_code": country_iso_code,
        "taxCode": taxCode,
        "primaryOccCode": primaryOccCode,
        "primaryFatcaName": primaryFatcaName,
        "primaryFatcaOccCode": primaryFatcaOccCode,
        "primaryFatcaDob": primaryFatcaDob,
        "primaryLogName": primaryLogName,
        "primaryPlaceOfBirth": primaryPlaceOfBirth,
        "primaryCountryOfBirth": primaryCountryOfBirth,
        "primaryIdentifierNumber": primaryIdentifierNumber,
        "primaryWealthSource": primaryWealthSource,
        "primaryIncomeSlab": primaryIncomeSlab,
        "primaryNetWorth": primaryNetWorth,
        "primaryDateOfNetWorth": primaryDateOfNetWorth,
        "primaryFatherName":primaryFatherName,
        "primaryPoliticallyExposed": primaryPoliticallyExposed,
        "secondaryHolderFatcaName": secondaryHolderFatcaName,
        "secondaryHolderFatcaOccCode": secondaryHolderFatcaOccCode,
        "secondaryHolderFatcaDob": secondaryHolderFatcaDob,
        "secondHolderLogName": secondHolderLogName,
        "secondHolderPlaceOfBirth": secondHolderPlaceOfBirth,
        "secondHolderCountryOfBirth": secondHolderCountryOfBirth,
        "secondHolderIdentifierNumber": secondHolderIdentifierNumber,
        "secondHolderWealthSource": secondHolderWealthSource,
        "secondHolderIncomeSlab": secondHolderIncomeSlab,
        "secondHolderNetWorth": secondHolderNetWorth,
        "secondHolderDateOfNetWorth": secondHolderDateOfNetWorth,
        "secondHolderPoliticallyExposed": secondHolderPoliticallyExposed,
        "second_holder_gender":second_holder_gender,
        "secondHolderFatherName":secondHolderFatherName
    };
}

class SecondaryHolder {
    String? firstName;
    String? dob;
    String? relationship;
    String? pan;
    String? email;
    String? mobile;
    String? city;
    String? state;
    String? country;
    String? pincode;

    SecondaryHolder({
        this.firstName,
        this.dob,
        this.relationship,
        this.pan,
        this.email,
        this.mobile,
        this.city,
        this.state,
        this.country,
        this.pincode,
    });

    factory SecondaryHolder.fromJson(Map<String, dynamic> json) => SecondaryHolder(
        firstName: json["first_name"],
        dob: json["dob"],
        relationship: json["relationship"],
        pan: json["pan"],
        email: json["email"],
        mobile: json["mobile"],
        city: json["city"],
        state: json["state"],
        country: json["country"],
        pincode: json["pincode"],
    );

    Map<String, dynamic> toJson() => {
        "first_name": firstName,
        "dob": dob,
        "relationship": relationship,
        "pan": pan,
        "email": email,
        "mobile": mobile,
         "city": city,
        "state": state,
        "country": country,
        "pincode": pincode,
    };
}
