class BseOnboardingResponse {
  String message;
  Data? data;
  List<dynamic>? details;

  BseOnboardingResponse({required this.message, this.data, this.details});

  factory BseOnboardingResponse.fromJson(Map<String, dynamic> json) =>
      BseOnboardingResponse(
        message: json["message"] ?? json["error"] ?? "Unknown Error",
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
        details: json["details"],
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  Onboarding onboarding;
  List<HolderElement> holders;
  List<Bank> banks;
  List<Nominee> nominees;
  List<dynamic> documents;

  Data({
    required this.onboarding,
    required this.holders,
    required this.banks,
    required this.nominees,
    required this.documents,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    onboarding: Onboarding.fromJson(json["onboarding"] ?? {}),
    holders:
        json["holders"] != null
            ? List<HolderElement>.from(
              json["holders"].map((x) => HolderElement.fromJson(x)),
            )
            : [],
    banks:
        json["banks"] != null
            ? List<Bank>.from(json["banks"].map((x) => Bank.fromJson(x)))
            : [],
    nominees:
        json["nominees"] != null
            ? List<Nominee>.from(
              json["nominees"].map((x) => Nominee.fromJson(x)),
            )
            : [],
    documents:
        json["documents"] != null
            ? List<dynamic>.from(json["documents"].map((x) => x))
            : [],
  );

  Map<String, dynamic> toJson() => {
    "onboarding": onboarding.toJson(),
    "holders": List<dynamic>.from(holders.map((x) => x.toJson())),
    "banks": List<dynamic>.from(banks.map((x) => x.toJson())),
    "nominees": List<dynamic>.from(nominees.map((x) => x.toJson())),
    "documents": List<dynamic>.from(documents.map((x) => x)),
  };
}

class Bank {
  String? id;
  String? onboardingId;
  String? bankName;
  String? ifscCode;
  String? accountNumber;
  String? accountType;
  String? accountHolderName;
  dynamic micrCode;
  String? bankCountry;
  bool isPrimary;
  bool isVerified;
  DateTime? verifiedAt;
  String? verificationReferenceId;
  String? verificationUtr;

  Bank({
    this.id,
    this.onboardingId,
    this.bankName,
    this.ifscCode,
    this.accountNumber,
    this.accountType,
    this.accountHolderName,
    this.micrCode,
    this.bankCountry,
    this.isPrimary = false,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationReferenceId,
    this.verificationUtr,
  });

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
    id: json["id"],
    onboardingId: json["onboarding_id"],
    bankName: json["bank_name"],
    ifscCode: json["ifsc_code"],
    accountNumber: json["account_number"],
    accountType: json["account_type"],
    accountHolderName: json["account_holder_name"],
    micrCode: json["micr_code"],
    bankCountry: json["bank_country"],
    isPrimary: json["is_primary"] ?? false,
    isVerified: json["is_verified"] ?? false,
    verifiedAt:
        json["verified_at"] != null
            ? DateTime.parse(json["verified_at"])
            : null,
    verificationReferenceId: json["verification_reference_id"],
    verificationUtr: json["verification_utr"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "onboarding_id": onboardingId,
    "bank_name": bankName,
    "ifsc_code": ifscCode,
    "account_number": accountNumber,
    "account_type": accountType,
    "account_holder_name": accountHolderName,
    "micr_code": micrCode,
    "bank_country": bankCountry,
    "is_primary": isPrimary,
    "is_verified": isVerified,
    "verified_at": verifiedAt?.toIso8601String(),
    "verification_reference_id": verificationReferenceId,
    "verification_utr": verificationUtr,
  };
}

class HolderElement {
  HolderHolder holder;
  List<Address> addresses;
  PersonalDetails? personalDetails;

  HolderElement({
    required this.holder,
    required this.addresses,
    this.personalDetails,
  });

  factory HolderElement.fromJson(Map<String, dynamic> json) => HolderElement(
    holder: HolderHolder.fromJson(json["holder"]),
    addresses:
        json["addresses"] != null
            ? List<Address>.from(
              json["addresses"].map((x) => Address.fromJson(x)),
            )
            : [],
    personalDetails:
        json["personal_details"] != null
            ? PersonalDetails.fromJson(json["personal_details"])
            : null,
  );

  Map<String, dynamic> toJson() => {
    "holder": holder.toJson(),
    "addresses": List<dynamic>.from(addresses.map((x) => x.toJson())),
    "personal_details": personalDetails?.toJson(),
  };
}

class Address {
  String? addressType;
  String? line1;
  String? line2;
  dynamic line3;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  String? id;
  String? holderId;

  Address({
    this.addressType,
    this.line1,
    this.line2,
    this.line3,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.id,
    this.holderId,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
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

class HolderHolder {
  int? holderRank;
  String? firstName;
  dynamic middleName;
  String? lastName;
  String? pan;
  DateTime? dob;
  String? gender;
  dynamic ckycNumber;
  String? phone;
  String? countryCode;
  String? email;
  String? politicallyExposedPerson;
  String? taxStatus;
  String? communicationMode;
  String? id;
  bool isPrimary;
  bool isPhoneVerified;
  bool isEmailVerified;

  HolderHolder({
    this.holderRank,
    this.firstName,
    this.middleName,
    this.lastName,
    this.pan,
    this.dob,
    this.gender,
    this.ckycNumber,
    this.phone,
    this.countryCode,
    this.email,
    this.politicallyExposedPerson,
    this.taxStatus,
    this.communicationMode,
    this.id,
    this.isPrimary = false,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
  });

  factory HolderHolder.fromJson(Map<String, dynamic> json) => HolderHolder(
    holderRank: json["holder_rank"],
    firstName: json["first_name"],
    middleName: json["middle_name"],
    lastName: json["last_name"],
    pan: json["pan"],
    dob: json["dob"] != null ? DateTime.parse(json["dob"]) : null,
    gender: json["gender"],
    ckycNumber: json["ckyc_number"],
    phone: json["phone"] ?? json["phone_number"],
    countryCode: json["country_code"],
    email: json["email"] ?? json["email_address"] ?? json["email_id"],
    politicallyExposedPerson: json["politically_exposed_person"],
    taxStatus: json["tax_status"],
    communicationMode: json["communication_mode"],
    id: json["id"],
    isPrimary: json["is_primary"] ?? false,
    isPhoneVerified: json["is_phone_verified"] ?? false,
    isEmailVerified: json["is_email_verified"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "holder_rank": holderRank,
    "first_name": firstName,
    "middle_name": middleName,
    "last_name": lastName,
    "pan": pan,
    "dob":
        dob != null
            ? "${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}"
            : null,
    "gender": gender,
    "ckyc_number": ckycNumber,
    "phone": phone,
    "country_code": countryCode,
    "email": email,
    "politically_exposed_person": politicallyExposedPerson,
    "tax_status": taxStatus,
    "communication_mode": communicationMode,
    "id": id,
    "is_primary": isPrimary,
    "is_phone_verified": isPhoneVerified,
    "is_email_verified": isEmailVerified,
  };
}

class PersonalDetails {
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
  String? placeOfBirth;
  String? countryOfBirth;
  String? id;
  String? holderId;

  PersonalDetails({
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

  factory PersonalDetails.fromJson(Map<String, dynamic> json) =>
      PersonalDetails(
        fatherName: json["father_name"],
        motherName: json["mother_name"],
        spouseName: json["spouse_name"],
        occupationCode: json["occupation_code"],
        annualIncome: json["annual_income"],
        sourceOfWealth: json["source_of_wealth"],
        netWorth: json["net_worth"],
        netWorthDate:
            json["net_worth_date"] != null
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
    "net_worth_date":
        netWorthDate != null
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

class Nominee {
  String? name;
  String? relation;
  DateTime? dob;
  int? nomineePercent;
  dynamic nomineeAddress;
  String? addressLine1;
  dynamic addressLine2;
  dynamic addressLine3;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  dynamic nomineeNationality;
  String? nomineeEmail;
  String? nomineeContactNumber;
  String? nomineeCountryCode;
  dynamic nomineeContactType;
  dynamic nomineeCommMode;
  String? nomineePan;
  dynamic guardianName;
  dynamic guardianRelation;
  dynamic guardianPan;
  dynamic guardianDob;
  String? id;
  String? onboardingId;
  bool isMinor;

  Nominee({
    this.name,
    this.relation,
    this.dob,
    this.nomineePercent,
    this.nomineeAddress,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.nomineeNationality,
    this.nomineeEmail,
    this.nomineeContactNumber,
    this.nomineeCountryCode,
    this.nomineeContactType,
    this.nomineeCommMode,
    this.nomineePan,
    this.guardianName,
    this.guardianRelation,
    this.guardianPan,
    this.guardianDob,
    this.id,
    this.onboardingId,
    this.isMinor = false,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    // Handle both formats: "name" field OR "first_name" + "last_name"
    String? fullName = json["name"];
    if (fullName == null && (json["first_name"] != null || json["last_name"] != null)) {
      final firstName = json["first_name"] ?? '';
      final lastName = json["last_name"] ?? '';
      fullName = '$firstName $lastName'.trim();
    }
    
    return Nominee(
      name: fullName,
      relation: json["relation"],
      dob: json["dob"] != null ? DateTime.parse(json["dob"]) : null,
      nomineePercent: json["nominee_percent"] ?? json["percent"],
    nomineeAddress: json["nominee_address"],
    addressLine1: json["address_line1"],
    addressLine2: json["address_line2"],
    addressLine3: json["address_line3"],
    city: json["city"],
    state: json["state"],
    country: json["country"],
    postalCode: json["postal_code"],
    nomineeNationality: json["nominee_nationality"],
    nomineeEmail: json["nominee_email"],
    nomineeContactNumber: json["nominee_contact_number"],
    nomineeCountryCode: json["nominee_country_code"],
    nomineeContactType: json["nominee_contact_type"],
    nomineeCommMode: json["nominee_comm_mode"],
    nomineePan: json["nominee_pan"],
    guardianName: json["guardian_name"],
    guardianRelation: json["guardian_relation"],
    guardianPan: json["guardian_pan"],
    guardianDob:
        json["guardian_dob"] != null
            ? (json["guardian_dob"] is String
                ? DateTime.tryParse(json["guardian_dob"])
                : json["guardian_dob"])
            : null,
      id: json["id"],
      onboardingId: json["onboarding_id"],
      isMinor: json["is_minor"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "relation": relation,
    "dob":
        dob != null
            ? "${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}"
            : null,
    "nominee_percent": nomineePercent,
    "nominee_address": nomineeAddress,
    "address_line1": addressLine1,
    "address_line2": addressLine2,
    "address_line3": addressLine3,
    "city": city,
    "state": state,
    "country": country,
    "postal_code": postalCode,
    "nominee_nationality": nomineeNationality,
    "nominee_email": nomineeEmail,
    "nominee_contact_number": nomineeContactNumber,
    "nominee_country_code": nomineeCountryCode,
    "nominee_contact_type": nomineeContactType,
    "nominee_comm_mode": nomineeCommMode,
    "nominee_pan": nomineePan,
    "guardian_name": guardianName,
    "guardian_relation": guardianRelation,
    "guardian_pan": guardianPan,
    "guardian_dob": guardianDob,
    "id": id,
    "onboarding_id": onboardingId,
    "is_minor": isMinor,
  };
}

class Onboarding {
  String? id;
  String? userId;
  String? holdingNature;
  String? investorCategory;
  String? status;
  String? sourceChannel;
  bool isNomineeOpted;
  bool isNomineeOptedVerified;
  DateTime? createdAt;
  DateTime? updatedAt;

  Onboarding({
    this.id,
    this.userId,
    this.holdingNature,
    this.investorCategory,
    this.status,
    this.sourceChannel,
    this.isNomineeOpted = false,
    this.isNomineeOptedVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Onboarding.fromJson(Map<String, dynamic> json) => Onboarding(
    id: json["id"],
    userId: json["user_id"],
    holdingNature: json["holding_nature"],
    investorCategory: json["investor_category"],
    status: json["status"],
    sourceChannel: json["source_channel"],
    isNomineeOpted: json["is_nominee_opted"] ?? false,
    isNomineeOptedVerified: json["is_nominee_opted_verified"] ?? false,
    createdAt:
        json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    updatedAt:
        json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "holding_nature": holdingNature,
    "investor_category": investorCategory,
    "status": status,
    "source_channel": sourceChannel,
    "is_nominee_opted": isNomineeOpted,
    "is_nominee_opted_verified": isNomineeOptedVerified,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
