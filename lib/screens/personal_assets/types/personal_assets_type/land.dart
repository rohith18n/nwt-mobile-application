import '../nominee.dart';

class LandAssetResponse {
  final int statusCode;
  final String message;
  final LandAssetData? data;

  LandAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory LandAssetResponse.fromJson(Map<String, dynamic> json) {
    return LandAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? LandAssetData.fromJson(json['data']) : null,
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

class LandAssetData {
  final int id;
  final String type;
  final double? purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<String> supportingdocs;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String location;
  final String landtype;
  final double areasqft;
  final String ownershiptype;

  LandAssetData({
    required this.id,
    required this.type,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.supportingdocs,
    required this.nominees,
    this.usersharepercentage,
    required this.location,
    required this.landtype,
    required this.areasqft,
    required this.ownershiptype,
  });

  factory LandAssetData.fromJson(Map<String, dynamic> json) {
    return LandAssetData(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      purchasedvalue: (json['purchasedvalue'] ?? 0).toDouble(),
      purchaseddate: json['purchaseddate'] ?? '',
      notes: json['notes'],
      supportingdocs:
          (json['supportingdocs'] as List<dynamic>? ?? [])
              .map((doc) => doc.toString())
              .toList(),
      nominees:
          (json['nominees'] as List<dynamic>? ?? [])
              .map((nominee) => Nominee.fromJson(nominee))
              .toList(),
      usersharepercentage: (json['usersharepercentage'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      landtype: json['landtype'] ?? '',
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
      'supportingdocs': supportingdocs,
      'nominees': nominees.map((nominee) => nominee.toJson()).toList(),
      if (usersharepercentage != null)
        'usersharepercentage': usersharepercentage,
      'location': location,
      'landtype': landtype,
      'areasqft': areasqft,
      'ownershiptype': ownershiptype,
    };
  }

  @override
  String toString() {
    return 'LandAssetData(id: $id, type: $type, purchasedvalue: $purchasedvalue, location: $location, landtype: $landtype, areasqft: $areasqft, ownershiptype: $ownershiptype, nominees: $nominees)';
  }
}
