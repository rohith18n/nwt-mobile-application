class HolderResponse {
  final bool success;
  final String? message;
  final HolderData data;

  HolderResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory HolderResponse.fromJson(Map<String, dynamic> json) {
    return HolderResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: HolderData.fromJson(json['data'] ?? {}),
    );
  }
}

class HolderData {
  final List<Holder>? holders;
  final Holder? holder;
  final int? count;

  HolderData({
    this.holders,
    this.holder,
    this.count,
  });

  factory HolderData.fromJson(Map<String, dynamic> json) {
    return HolderData(
      holders: json['holders'] != null
          ? (json['holders'] as List).map((i) => Holder.fromJson(i)).toList()
          : null,
      holder: json['holder'] != null ? Holder.fromJson(json['holder']) : null,
      count: json['count'],
    );
  }
}

class Holder {
  final int id;
  final String name;
  final String panNumber;
  final String? dob;
  final String? tin;
  final String investorResidency;
  final String? email;
  final String? phoneNumber;
  final String? fatherName;
  final String? gender;
  final Map<String, dynamic>? address;
  final String? maskedAadhaar;
  final bool? aadhaarLinked;
  final bool isVerified;
  final bool hasSignature;
  final String? createdAt;
  final String? updatedAt;

  Holder({
    required this.id,
    required this.name,
    required this.panNumber,
    this.dob,
    this.tin,
    required this.investorResidency,
    this.email,
    this.phoneNumber,
    this.fatherName,
    this.gender,
    this.address,
    this.maskedAadhaar,
    this.aadhaarLinked,
    required this.isVerified,
    required this.hasSignature,
    this.createdAt,
    this.updatedAt,
  });

  factory Holder.fromJson(Map<String, dynamic> json) {
    return Holder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? "0") ?? 0,
      name: json['name']?.toString() ?? "",
      panNumber: json['pan_number']?.toString() ?? "",
      dob: json['dob']?.toString(),
      tin: json['tin']?.toString(),
      investorResidency: json['investor_residency']?.toString() ?? "Resident",
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      fatherName: json['father_name']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address'] != null ? Map<String, dynamic>.from(json['address']) : null,
      maskedAadhaar: json['masked_aadhaar']?.toString(),
      aadhaarLinked: json['aadhaar_linked'] is bool ? json['aadhaar_linked'] : (json['aadhaar_linked']?.toString() == 'true'),
      isVerified: json['is_verified'] is bool ? json['is_verified'] : (json['is_verified']?.toString() == 'true'),
      hasSignature: json['has_signature'] is bool ? json['has_signature'] : (json['has_signature']?.toString() == 'true'),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'dob': dob,
      'tin': tin,
      'investor_residency': investorResidency,
      'gender': gender,
      'father_name': fatherName,
      'address': address,
    };
  }
}
