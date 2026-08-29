class BseFatcaManagement {
  int statusCode;
  String message;
  Data? data;

  BseFatcaManagement({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory BseFatcaManagement.fromJson(Map<String, dynamic> json) =>
      BseFatcaManagement(
        statusCode: json["statusCode"] ?? 200,
        message: json["message"] ?? 'Request completed',
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
    String? fatherName;
    String? motherName;
    String? spouseName;
    String? occupationCode;
    String? annualIncome;
    String? sourceOfWealth;
    String? netWorth;
    DateTime? netWorthDate;
    String? taxResidence;
    String? tin;
    String? maritalStatus;
    String? nationality;
    dynamic placeOfBirth;
    String? countryOfBirth;
    String? id;
    String? holderId;

    Data({
        this.fatherName,
        this.motherName,
        this.spouseName,
        this.occupationCode,
        this.annualIncome,
        this.sourceOfWealth,
        this.netWorth,
        this.netWorthDate,
        this.taxResidence,
        this.tin,
        this.maritalStatus,
        this.nationality,
        this.placeOfBirth,
        this.countryOfBirth,
        this.id,
        this.holderId,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        fatherName: json["father_name"],
        motherName: json["mother_name"],
        spouseName: json["spouse_name"],
        occupationCode: json["occupation_code"],
        annualIncome: json["annual_income"],
        sourceOfWealth: json["source_of_wealth"],
        netWorth: json["net_worth"],
        netWorthDate: json["net_worth_date"] != null
            ? DateTime.parse(json["net_worth_date"])
            : null,
        taxResidence: json["tax_residence"],
        tin: json["tin"],
        maritalStatus: json["marital_status"],
        nationality: json["nationality"],
        placeOfBirth: json["place_of_birth"],
        countryOfBirth: json["country_of_birth"],
        id: json["id"],
        holderId: json["holder_id"],
    );

    Map<String, dynamic> toJson() => {
        "father_name": fatherName,
        "mother_name": motherName,
        "spouse_name": spouseName,
        "occupation_code": occupationCode,
        "annual_income": annualIncome,
        "source_of_wealth": sourceOfWealth,
        "net_worth": netWorth,
        "net_worth_date": netWorthDate != null
            ? "${netWorthDate!.year.toString().padLeft(4, '0')}-${netWorthDate!.month.toString().padLeft(2, '0')}-${netWorthDate!.day.toString().padLeft(2, '0')}"
            : null,
        "tax_residence": taxResidence,
        "tin": tin,
        "marital_status": maritalStatus,
        "nationality": nationality,
        "place_of_birth": placeOfBirth,
        "country_of_birth": countryOfBirth,
        "id": id,
        "holder_id": holderId,
    };
}
