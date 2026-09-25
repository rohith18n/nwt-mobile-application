import '../nominee.dart';

class PreciousMetalAssetResponse {
  final int statusCode;
  final String message;
  final PreciousMetalAssetData? data;

  PreciousMetalAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory PreciousMetalAssetResponse.fromJson(Map<String, dynamic> json) {
    return PreciousMetalAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data:
          json['data'] != null ? PreciousMetalAssetData.fromJson(json['data']) : null,
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

class PreciousMetalAssetData {
  final int id;
  final String type;
  final double purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<String> supportingdocs;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String metaltype;
  final double weightgm;
  final String details;
  final String? purity;

  PreciousMetalAssetData({
    required this.id,
    required this.type,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.supportingdocs,
    required this.nominees,
    this.usersharepercentage,
    required this.metaltype,
    required this.weightgm,
    required this.details,
    this.purity,
  });

  factory PreciousMetalAssetData.fromJson(Map<String, dynamic> json) {
    return PreciousMetalAssetData(
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
      metaltype: json['metaltype'] ?? '',
      weightgm: (json['weightgm'] ?? 0).toDouble(),
      details: json['details'] ?? '',
      purity: json['purity'],
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
      'metaltype': metaltype,
      'weightgm': weightgm,
      'details': details,
      if (purity != null) 'purity': purity,
    };
  }

  @override
  String toString() {
    return 'PreciousMetalAssetData(id: $id, type: $type, purchasedvalue: $purchasedvalue, metaltype: $metaltype, weightgm: $weightgm, details: $details, nominees: $nominees)';
  }
}
