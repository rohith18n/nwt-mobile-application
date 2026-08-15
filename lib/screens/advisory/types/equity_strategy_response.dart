class EquityBasketResponse {
    int statusCode;
    String message;
    bool success;
    Data? data;

    EquityBasketResponse({
        required this.statusCode,
        required this.message,
        required this.success,
        this.data,
    });

    factory EquityBasketResponse.fromJson(Map<String, dynamic> json) => EquityBasketResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        success: json["success"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "success": success,
        "data": data?.toJson(),
    };
}

class Data {
    Strategies strategies;

    Data({
        required this.strategies,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        strategies: Strategies.fromJson(json["strategies"]),
    );

    Map<String, dynamic> toJson() => {
        "strategies": strategies.toJson(),
    };
}

class Strategies {
    CapMomentum midcapMomentum;
    CapMomentum smallcapMomentum;

    Strategies({
        required this.midcapMomentum,
        required this.smallcapMomentum,
    });

    factory Strategies.fromJson(Map<String, dynamic> json) => Strategies(
        midcapMomentum: CapMomentum.fromJson(json["midcap_momentum"]),
        smallcapMomentum: CapMomentum.fromJson(json["smallcap_momentum"]),
    );

    Map<String, dynamic> toJson() => {
        "midcap_momentum": midcapMomentum.toJson(),
        "smallcap_momentum": smallcapMomentum.toJson(),
    };
}

class CapMomentum {
    String id;
    String name;
    String subtitle;
    int stockCount;
    String index;
    double yearlyReturn;
    int benchmark;
    String riskLabel;
    String returnsLabel;
    String description;
    Category category;
    List<Stock> stocks;

    CapMomentum({
        required this.id,
        required this.name,
        required this.subtitle,
        required this.stockCount,
        required this.index,
        required this.yearlyReturn,
        required this.benchmark,
        required this.riskLabel,
        required this.returnsLabel,
        required this.description,
        required this.category,
        required this.stocks,
    });

    factory CapMomentum.fromJson(Map<String, dynamic> json) => CapMomentum(
        id: json["id"],
        name: json["name"],
        subtitle: json["subtitle"],
        stockCount: json["stockCount"],
        index: json["index"],
        yearlyReturn: json["yearlyReturn"]?.toDouble(),
        benchmark: json["benchmark"],
        riskLabel: json["riskLabel"],
        returnsLabel: json["returnsLabel"],
        description: json["description"],
        category: categoryValues.map[json["category"]]!,
        stocks: List<Stock>.from(json["stocks"].map((x) => Stock.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "subtitle": subtitle,
        "stockCount": stockCount,
        "index": index,
        "yearlyReturn": yearlyReturn,
        "benchmark": benchmark,
        "riskLabel": riskLabel,
        "returnsLabel": returnsLabel,
        "description": description,
        "category": categoryValues.reverse[category],
        "stocks": List<dynamic>.from(stocks.map((x) => x.toJson())),
    };
}

enum Category {
    MIDCAP,
    SMALLCAP
}

final categoryValues = EnumValues({
    "midcap": Category.MIDCAP,
    "smallcap": Category.SMALLCAP
});

class Stock {
    String name;
    String isin;
    double currentMarketValue;
    double nav;
    Category category;

    Stock({
        required this.name,
        required this.isin,
        required this.currentMarketValue,
        required this.nav,
        required this.category,
    });

    factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        name: json["name"],
        isin: json["isin"],
        currentMarketValue: json["currentMarketValue"]?.toDouble(),
        nav: json["nav"]?.toDouble(),
        category: categoryValues.map[json["category"]]!,
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "isin": isin,
        "currentMarketValue": currentMarketValue,
        "nav": nav,
        "category": categoryValues.reverse[category],
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
