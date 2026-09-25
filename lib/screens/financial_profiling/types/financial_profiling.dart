class FinanceProfilingResponse {
    int statusCode;
    String message;
    List<Datum> data;

    FinanceProfilingResponse({
        required this.statusCode,
        required this.message,
        required this.data,
    });

    factory FinanceProfilingResponse.fromJson(Map<String, dynamic> json) => FinanceProfilingResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    int id;
    String questiontext;
    String subtitle;
    Type type;
    String category;
    List<Option> options;

    Datum({
        required this.id,
        required this.questiontext,
        required this.subtitle,
        required this.type,
        required this.category,
        required this.options,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        questiontext: json["questiontext"],
        subtitle: json["subtitle"],
        type: typeValues.map[json["type"]]!,
        category: json["category"],
        options: List<Option>.from(json["options"].map((x) => Option.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "questiontext": questiontext,
        "subtitle": subtitle,
        "type": typeValues.reverse[type],
        "category": category,
        "options": List<dynamic>.from(options.map((x) => x.toJson())),
    };
}

class Option {
    int id;
    String optiontext;
    String optionvalue;
    int displayorder;

    Option({
        required this.id,
        required this.optiontext,
        required this.optionvalue,
        required this.displayorder,
    });

    factory Option.fromJson(Map<String, dynamic> json) => Option(
        id: json["id"],
        optiontext: json["optiontext"],
        optionvalue: json["optionvalue"],
        displayorder: json["displayorder"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "optiontext": optiontext,
        "optionvalue": optionvalue,
        "displayorder": displayorder,
    };
}

enum Type {
    MULTI,
    RANGE,
    SINGLE
}

final typeValues = EnumValues({
    "multi": Type.MULTI,
    "range": Type.RANGE,
    "single": Type.SINGLE
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
