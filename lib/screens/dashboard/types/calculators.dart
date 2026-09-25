class CalculatorResponse {
  final int statusCode;
  final String message;
  final CalculatorData data;

  CalculatorResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory CalculatorResponse.fromJson(Map<String, dynamic> json) {
    return CalculatorResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      data: CalculatorData.fromJson(json['data']),
    );
  }

  bool get success => statusCode == 200 || statusCode == 201;
}

class CalculatorData {
  final List<CalculatorItem> calculators;

  CalculatorData({required this.calculators});

  factory CalculatorData.fromJson(Map<String, dynamic> json) {
    return CalculatorData(
      calculators:
          (json['calculators'] as List)
              .map((i) => CalculatorItem.fromJson(i))
              .toList(),
    );
  }
}

class CalculatorItem {
  final String id;
  final String name;
  final String description;
  final String url;

  CalculatorItem({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
  });

  factory CalculatorItem.fromJson(Map<String, dynamic> json) {
    return CalculatorItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      url: json['url'],
    );
  }
}
