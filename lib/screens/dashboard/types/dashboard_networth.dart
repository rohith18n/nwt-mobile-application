class DashboardNetworthResponse {
  int status;
  String message;
  DashboardData? data;

  DashboardNetworthResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DashboardNetworthResponse.fromJson(Map<String, dynamic> json) =>
      DashboardNetworthResponse(
        status: _parseSafeInt(json["statusCode"] ?? json["status"]) ?? 0,
        message: json["message"],
        data:
            json["data"] != null ? DashboardData.fromJson(json["data"]) : null,
      );

  static int? _parseSafeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class DashboardData {
  String? balancedatetime;
  double totalNetWorth;
  double? xirr;
  double? deltapercentage;
  double? deltaamount;
  SpendsData? spends;
  InvestmentsData? investments;

  DashboardData({
    this.balancedatetime,
    required this.totalNetWorth,
    this.xirr,
    this.deltapercentage,
    this.deltaamount,
    this.spends,
    this.investments,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    balancedatetime: json["balancedatetime"],
    totalNetWorth: json["totalnetworth"]?.toDouble() ?? 0.0,
    xirr: json["xirr"]?.toDouble(),
    deltapercentage: json["deltapercentage"]?.toDouble(),
    deltaamount: json["deltaamount"]?.toDouble(),
    spends: json["spends"] != null ? SpendsData.fromJson(json["spends"]) : null,
    investments:
        json["investments"] != null
            ? InvestmentsData.fromJson(json["investments"])
            : null,
  );

  Map<String, dynamic> toJson() => {
    "totalNetWorth": totalNetWorth,
    "balancedatetime": balancedatetime,
    "xirr": xirr,
    "spends": spends?.toJson(),
    "investments": investments?.toJson(),
  };
}

class FinancialData {
  double amount;
  double delta;
  String deltarange;
  bool islinked;
  String? spendrange; // Optional field for spends data
  double? deltaamount; // Delta amount field
  double? spendslast30days; // New field for spends last 30 days

  FinancialData({
    required this.amount,
    required this.delta,
    required this.deltarange,
    required this.islinked,
    this.spendrange,
    this.deltaamount,
    this.spendslast30days,
  });

  factory FinancialData.fromJson(Map<String, dynamic> json) => FinancialData(
    amount: json["amount"]?.toDouble() ?? 0.0,
    delta: json["delta"]?.toDouble() ?? 0.0,
    deltarange: json["deltarange"] ?? "",
    islinked: json["islinked"] ?? false,
    spendrange: json["spendrange"], // Only present for spends data
    deltaamount: json["deltaamount"]?.toDouble(),
    spendslast30days: json["spendslast30days"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "delta": delta,
    "deltarange": deltarange,
    "islinked": islinked,
    if (spendrange != null) "spendrange": spendrange,
    if (spendslast30days != null) "spendslast30days": spendslast30days,
  };

  // Factory constructors for specific types
  factory FinancialData.spends({
    required double amount,
    required double delta,
    required String spendrange,
    required String deltarange,
    required bool islinked,
    double? spendslast30days,
  }) => FinancialData(
    amount: amount,
    delta: delta,
    deltarange: deltarange,
    islinked: islinked,
    spendrange: spendrange,
    spendslast30days: spendslast30days,
  );

  factory FinancialData.investments({
    required double amount,
    required double delta,
    required String deltarange,
    required bool islinked,
    double? deltaamount,
  }) => FinancialData(
    amount: amount,
    delta: delta,
    deltarange: deltarange,
    islinked: islinked,
    deltaamount: deltaamount,
  );
}

// Type aliases for backward compatibility
typedef SpendsData = FinancialData;
typedef InvestmentsData = FinancialData;
