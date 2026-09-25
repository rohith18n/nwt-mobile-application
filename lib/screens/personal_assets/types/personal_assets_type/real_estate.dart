import '../nominee.dart';

class RealEstateAssetResponse {
  final int statusCode;
  final String message;
  final RealEstateAssetData? data;

  RealEstateAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory RealEstateAssetResponse.fromJson(Map<String, dynamic> json) {
    return RealEstateAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data:
          json['data'] != null
              ? RealEstateAssetData.fromJson(json['data'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class RealEstateAssetData {
  final int id;
  final String type;
  final double purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String location;
  final String propertytype;
  final double areasqft;
  final String ownershiptype;

  RealEstateAssetData({
    required this.id,
    required this.type,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.nominees,
    this.usersharepercentage,
    required this.location,
    required this.propertytype,
    required this.areasqft,
    required this.ownershiptype,
  });

  factory RealEstateAssetData.fromJson(Map<String, dynamic> json) {
    return RealEstateAssetData(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      purchasedvalue: (json['purchasedvalue'] ?? 0).toDouble(),
      purchaseddate: json['purchaseddate'] ?? '',
      notes: json['notes'],
      nominees:
          (json['nominees'] as List<dynamic>? ?? [])
              .map((nominee) => Nominee.fromJson(nominee))
              .toList(),
      usersharepercentage: (json['usersharepercentage'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      propertytype: json['propertytype'] ?? '',
      areasqft: (json['areasqft'] ?? 0).toDouble(),
      ownershiptype: json['ownershiptype'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'purchasedvalue': purchasedvalue,
      'purchaseddate': purchaseddate,
      if (notes != null) 'notes': notes,
      'nominees': nominees.map((nominee) => nominee.toJson()).toList(),
      if (usersharepercentage != null)
        'usersharepercentage': usersharepercentage,
      'location': location,
      'propertytype': propertytype,
      'areasqft': areasqft,
      'ownershiptype': ownershiptype,
    };
  }

  @override
  String toString() {
    return 'RealEstateAssetData(id: $id, type: $type, purchasedvalue: $purchasedvalue, location: $location, propertytype: $propertytype, areasqft: $areasqft, ownershiptype: $ownershiptype, nominees: $nominees)';
  }
}
