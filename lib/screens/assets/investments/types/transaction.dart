class InvestmentTransactions {
  int statusCode;
  String message;
  Data? data;

  InvestmentTransactions({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory InvestmentTransactions.fromJson(Map<String, dynamic> json) =>
      InvestmentTransactions(
        statusCode: json["statusCode"] ?? 0,
        message: json["message"] ?? '',
        data: json['data'] != null ? Data.fromJson(json['data']) : null,
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  List<Investment> etfs;
  List<Investment> equities;
  List<Investment> mfs;

  Data({required this.etfs, required this.equities, required this.mfs});

  factory Data.fromJson(Map<String, dynamic> json) {
    final rawEtfs = (json["etfs"] ?? json["etf"] ?? []) as List? ?? [];
    final rawEquities =
        (json["equities"] ?? json["equity"] ?? []) as List? ?? [];
    final rawMfs = (json["mfs"] ?? json["mf"] ?? []) as List? ?? [];

    return Data(
      etfs:
          rawEtfs
              .map((x) => Investment.fromJson(x as Map<String, dynamic>))
              .toList(),
      equities:
          rawEquities
              .map((x) => Investment.fromJson(x as Map<String, dynamic>))
              .toList(),
      mfs:
          rawMfs
              .map((x) => Investment.fromJson(x as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "etf": List<dynamic>.from(etfs.map((x) => x.toJson())),
    "equity": List<dynamic>.from(equities.map((x) => x.toJson())),
    "mf": List<dynamic>.from(mfs.map((x) => x.toJson())),
  };
}

class Investment {
  String? category;
  DateTime? date;
  double? quantity;
  double? avgBuyPrice;
  double? investedValue;
  double? currentMarketPrice;
  double? currentValue;
  double? exchange;
  String? name;
  String? type;
  double? daysGainValue;
  double? daysGainPercent;
  double? totalGainValue;
  double? totalGainPercent;
  double? xirrPercent;
  double? ltcgValue;
  double? stcgValue;
  double? txnamount;
  String? image_url;
  String? description;
  String? folio_no;
  String? brokercode;
  String? registrar;
  String? brokername;
  String? isin;

  String get uniqueKey {
    return generateKey(
      isin: isin ?? brokercode,
      date: date,
      quantity: quantity,
      txnamount: txnamount,
      type: type,
      name: name,
      description: description,
      category: category,
    );
  }

  /// Unified key generator for investment transactions across all controllers/stores
  static String generateKey({
    String? isin,
    DateTime? date,
    double? quantity,
    double? txnamount,
    String? type,
    String? name,
    String? description,
    String? category,
  }) {
    final isinVal = (isin ?? '').trim().toLowerCase();

    // For Mutual Funds, we truncate the time entirely (YYYY-MM-DD) because multiple identical
    // records (amount, qty, desc) on the same day are effectively duplicates in AA data.
    final isMf = (category ?? '').toUpperCase().contains('MUTUAL');
    final dt = date ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateVal =
        isMf
            ? dt
                .toIso8601String()
                .split('T')
                .first // YYYY-MM-DD
            : dt.toIso8601String().split('.').first; // YYYY-MM-DDTHH:MM:SS

    final qtyVal = quantity?.toStringAsFixed(6) ?? '0.0';
    final amtVal = txnamount?.toStringAsFixed(2) ?? '0.0';
    final typeVal = (type ?? '').trim().toLowerCase();
    final nameVal = (name ?? '').trim().toLowerCase();
    final descVal = (description ?? '').trim().toLowerCase();

    // If we have an ISIN, we don't need Name or Description for uniqueness.
    // This allows us to merge "ghost" duplicates that are missing names.
    if (isinVal.isNotEmpty) {
      return 'itxn:$isinVal|$dateVal|$qtyVal|$amtVal|$typeVal';
    }

    return 'itxn:$isinVal|$dateVal|$qtyVal|$amtVal|$typeVal|$nameVal|$descVal';
  }

  /// Unified key generator for investment holdings (summaries) to avoid duplicate snapshot cards
  static String generateHoldingKey({
    String? isin,
    String? folio,
    String? name,
    String? category,
  }) {
    final isinVal = (isin ?? '').trim().toLowerCase();
    final folioVal = (folio ?? '').trim().toLowerCase();
    final nameVal = (name ?? '').trim().toLowerCase();
    final catVal = (category ?? '').trim().toLowerCase();
    
    // Primary identity is ISIN + Folio. If ISIN is empty, fallback to Name + Folio.
    return isinVal.isNotEmpty 
        ? 'holding:$catVal|$isinVal|$folioVal' 
        : 'holding:$catVal|$nameVal|$folioVal';
  }

  Investment({
    this.category,
    this.date,
    this.quantity,
    this.avgBuyPrice,
    this.investedValue,
    this.currentMarketPrice,
    this.currentValue,
    this.exchange,
    this.name,
    this.type,
    this.daysGainValue,
    this.daysGainPercent,
    this.totalGainValue,
    this.totalGainPercent,
    this.xirrPercent,
    this.ltcgValue,
    this.stcgValue,
    this.txnamount,
    this.image_url,
    this.description,
    this.folio_no,
    this.brokercode,
    this.registrar,
    this.brokername,
    this.isin,
  });

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    category: json["category"] ?? "",
    date:
        DateTime.tryParse(json["date"]?.toString() ?? "") ??
        DateTime.fromMillisecondsSinceEpoch(0),
    quantity:
        (json["quantity"] == null) ? 0.0 : (json["quantity"] as num).toDouble(),
    avgBuyPrice:
        (json["avg_buy_price"] ?? json["avgBuyPrice"]) == null
            ? 0.0
            : ((json["avg_buy_price"] ?? json["avgBuyPrice"]) as num).toDouble(),
    investedValue:
        (json["invested_value"] ?? json["investedValue"]) == null
            ? 0.0
            : ((json["invested_value"] ?? json["investedValue"]) as num).toDouble(),
    currentMarketPrice:
        (json["current_market_price"] ?? json["currentMarketPrice"]) == null
            ? 0.0
            : ((json["current_market_price"] ?? json["currentMarketPrice"]) as num).toDouble(),
    currentValue:
        (json["current_value"] ?? json["currentValue"]) == null
            ? 0.0
            : ((json["current_value"] ?? json["currentValue"]) as num).toDouble(),
    exchange:
        (json["exchange"] == null) ? 0.0 : (json["exchange"] as num).toDouble(),
    name: json["name"] ?? "",
    type: json["type"] ?? "",
    daysGainValue:
        (json["days_gain_value"] ?? json["daysGainValue"]) == null
            ? 0.0
            : ((json["days_gain_value"] ?? json["daysGainValue"]) as num).toDouble(),
    daysGainPercent:
        (json["days_gain_percent"] ?? json["daysGainPercent"]) == null
            ? 0.0
            : ((json["days_gain_percent"] ?? json["daysGainPercent"]) as num).toDouble(),
    totalGainValue:
        (json["total_gain_value"] ?? json["totalGainValue"]) == null
            ? 0.0
            : ((json["total_gain_value"] ?? json["totalGainValue"]) as num).toDouble(),
    totalGainPercent:
        (json["total_gain_percent"] ?? json["totalGainPercent"]) == null
            ? 0.0
            : ((json["total_gain_percent"] ?? json["totalGainPercent"]) as num).toDouble(),
    xirrPercent:
        (json["xirr_percent"] ?? json["xirrPercent"]) == null
            ? 0.0
            : ((json["xirr_percent"] ?? json["xirrPercent"]) as num).toDouble(),
    ltcgValue:
        (json["ltcg_value"] ?? json["ltcgValue"]) == null
            ? 0.0
            : ((json["ltcg_value"] ?? json["ltcgValue"]) as num).toDouble(),
    stcgValue:
        (json["stcg_value"] ?? json["stcgValue"]) == null
            ? 0.0
            : ((json["stcg_value"] ?? json["stcgValue"]) as num).toDouble(),
    txnamount:
        (json["txnamount"] ?? json["txnAmount"]) == null
            ? null
            : ((json["txnamount"] ?? json["txnAmount"]) as num).toDouble(),
    image_url:
        (json["image_url"] == null) ? null : (json["image_url"] as String),
    description:
        (json["description"] == null) ? null : (json["description"] as String),
    folio_no: (json["folio_no"] == null) ? null : (json["folio_no"] as String),
    brokercode:
        (json["brokercode"] == null) ? null : (json["brokercode"] as String),
    registrar:
        (json["registrar"] == null) ? null : (json["registrar"] as String),
    brokername:
        (json["brokername"] == null) ? null : (json["brokername"] as String),
    isin: (json["isin"] == null) ? null : (json["isin"] as String),
  );

  Map<String, dynamic> toJson() => {
    "category": category,
    "date": date,
    "quantity": quantity,
    "avg_buy_price": avgBuyPrice,
    "invested_value": investedValue,
    "current_market_price": currentMarketPrice,
    "current_value": currentValue,
    "exchange": exchange,
    "name": name,
    "type": type,
    "days_gain_value": daysGainValue,
    "days_gain_percent": daysGainPercent,
    "total_gain_value": totalGainValue,
    "total_gain_percent": totalGainPercent,
    "xirr_percent": xirrPercent,
    "ltcg_value": ltcgValue,
    "stcg_value": stcgValue,
    "txnamount": txnamount,
    "image_url": image_url,
    "description": description,
    "folio_no": folio_no,
    "brokercode": brokercode,
    "registrar": registrar,
    "isin": isin,
  };
}
