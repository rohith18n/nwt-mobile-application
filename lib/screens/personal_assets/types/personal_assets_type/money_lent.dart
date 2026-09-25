import '../nominee.dart';

class MoneyLentAssetResponse {
  final int statusCode;
  final String message;
  final MoneyLentAssetData? data;

  MoneyLentAssetResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory MoneyLentAssetResponse.fromJson(Map<String, dynamic> json) {
    return MoneyLentAssetResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? MoneyLentAssetData.fromJson(json['data']) : null,
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

class MoneyLentAssetData {
  final int id;
  final String type;
  final double purchasedvalue;
  final String purchaseddate;
  final String? notes;
  final List<String> supportingdocs;
  final List<Nominee> nominees;
  final double? usersharepercentage;
  final String lentto;
  final double amount;
  final double roipercent;
  final int timelinemonths;
  final String lentdate;

  MoneyLentAssetData({
    required this.id,
    required this.type,
    required this.purchasedvalue,
    required this.purchaseddate,
    this.notes,
    required this.supportingdocs,
    required this.nominees,
    this.usersharepercentage,
    required this.lentto,
    required this.amount,
    required this.roipercent,
    required this.timelinemonths,
    required this.lentdate,
  });

  factory MoneyLentAssetData.fromJson(Map<String, dynamic> json) {
    return MoneyLentAssetData(
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
      lentto: json['lentto'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      roipercent: (json['roipercent'] ?? 0).toDouble(),
      timelinemonths: json['timelinemonths'] ?? 0,
      lentdate: json['lentdate'] ?? '',
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
      'lentto': lentto,
      'amount': amount,
      'roipercent': roipercent,
      'timelinemonths': timelinemonths,
      'lentdate': lentdate,
    };
  }

  @override
  String toString() {
    return 'MoneyLentAssetData(id: $id, type: $type, purchasedvalue: $purchasedvalue, lentto: $lentto, amount: $amount, roipercent: $roipercent, timelinemonths: $timelinemonths, nominees: $nominees)';
  }
}
