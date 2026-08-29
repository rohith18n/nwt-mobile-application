class BseNomineeManagement {
  int statusCode;
  String message;
  Data? data;
  List<dynamic>? details;

  BseNomineeManagement({
    required this.statusCode,
    required this.message,
    this.data,
    this.details,
  });

  factory BseNomineeManagement.fromJson(Map<String, dynamic> json) =>
      BseNomineeManagement(
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
  String name;
  String relation;
  String dob;
  int nomineePercent;
  String nomineePan;
  String nomineeContactNumber;
  String nomineeEmail;
  String addressLine1;
  String city;
  String state;
  String country;
  String postalCode;

  Data({
    required this.name,
    required this.relation,
    required this.dob,
    required this.nomineePercent,
    required this.nomineePan,
    required this.nomineeContactNumber,
    required this.nomineeEmail,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"],
    relation: json["relation"],
    dob: json["dob"],
    nomineePercent: json["nominee_percent"],
    nomineePan: json["nominee_pan"],
    nomineeContactNumber: json["nominee_contact_number"] ?? '',
    nomineeEmail: json["nominee_email"] ?? '',
    addressLine1: json["address_line1"] ?? '',
    city: json["city"] ?? '',
    state: json["state"] ?? '',
    country: json["country"] ?? '',
    postalCode: json["postal_code"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "relation": relation,
    "dob": dob,
    "nominee_percent": nomineePercent,
    "nominee_pan": nomineePan,
    "nominee_contact_number": nomineeContactNumber,
    "nominee_email": nomineeEmail,
    "address_line1": addressLine1,
    "city": city,
    "state": state,
    "country": country,
    "postal_code": postalCode,
  };
}
