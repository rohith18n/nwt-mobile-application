class PersonalAssetItem {
  final int id;
  final String title;
  final String subtitle;
  final double amount;
  final String type;

  PersonalAssetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
  });

  factory PersonalAssetItem.fromJson(Map<String, dynamic> json) {
    return PersonalAssetItem(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'type': type,
    };
  }
}

class PersonalAssetsListResponse {
  final int statusCode;
  final String message;
  final List<PersonalAssetItem> data;

  PersonalAssetsListResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  bool get success => statusCode == 200;

  factory PersonalAssetsListResponse.fromJson(Map<String, dynamic> json) {
    return PersonalAssetsListResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => PersonalAssetItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class PersonalAssetsTotalValueResponse {
  final int statusCode;
  final String message;
  final double totalValue;

  PersonalAssetsTotalValueResponse({
    required this.statusCode,
    required this.message,
    required this.totalValue,
  });

  bool get success => statusCode == 200;

  factory PersonalAssetsTotalValueResponse.fromJson(Map<String, dynamic> json) {
    return PersonalAssetsTotalValueResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      totalValue: (json['data']?['totalvalue'] ?? 0).toDouble(),
    );
  }
}
