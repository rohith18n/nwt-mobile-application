import '../nominee.dart';

class OtherAssetResponse {
  final int statusCode;
  final String message;
  final OtherAssetData? data;

  OtherAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory OtherAssetResponse.fromJson(Map<String, dynamic> json) {
    return OtherAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data:
          json['data'] != null ? OtherAssetData.fromJson(json['data']) : null,
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

class OtherAssetData {
  final int id;
  final String type;
  final String? assetname;
  final double purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<String> supportingdocs;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String description;
  final String ownershiptype;

  OtherAssetData({
    required this.id,
    required this.type,
    this.assetname,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.supportingdocs,
    required this.nominees,
    this.usersharepercentage,
    required this.description,
    required this.ownershiptype,
  });

  factory OtherAssetData.fromJson(Map<String, dynamic> json) {
    return OtherAssetData(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      assetname: json['assetname'],
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
      description: json['description'] ?? '',
      ownershiptype: json['ownershiptype'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (assetname != null) 'assetname': assetname,
      'purchasedvalue': purchasedvalue,
      'purchaseddate': purchaseddate,
      if (notes != null) 'notes': notes,
      'supportingdocs': supportingdocs,
      'nominees': nominees.map((nominee) => nominee.toJson()).toList(),
      if (usersharepercentage != null)
        'usersharepercentage': usersharepercentage,
      'description': description,
      'ownershiptype': ownershiptype,
    };
  }

  @override
  String toString() {
    return 'OtherAssetData(id: $id, type: $type, assetname: $assetname, purchasedvalue: $purchasedvalue, description: $description, ownershiptype: $ownershiptype, nominees: $nominees)';
  }
}
