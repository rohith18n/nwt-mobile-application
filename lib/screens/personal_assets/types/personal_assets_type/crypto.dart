import '../nominee.dart';

class CryptoAssetResponse {
  final int statusCode;
  final String message;
  final CryptoAssetData? data;

  CryptoAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory CryptoAssetResponse.fromJson(Map<String, dynamic> json) {
    return CryptoAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data:
          json['data'] != null ? CryptoAssetData.fromJson(json['data']) : null,
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

class CryptoAssetData {
  final int id;
  final String type;
  final double purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<String> supportingdocs;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String scriptname;
  final double quantity;

  CryptoAssetData({
    required this.id,
    required this.type,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.supportingdocs,
    required this.nominees,
    this.usersharepercentage,
    required this.scriptname,
    required this.quantity,
  });

  factory CryptoAssetData.fromJson(Map<String, dynamic> json) {
    return CryptoAssetData(
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
      scriptname: json['scriptname'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
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
      'scriptname': scriptname,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'CryptoAssetData(id: $id, type: $type, purchasedvalue: $purchasedvalue, scriptname: $scriptname, quantity: $quantity, nominees: $nominees)';
  }
}
