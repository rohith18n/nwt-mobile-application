// To parse this JSON data, do
//
//     final tinResponseData = tinResponseDataFromJson(jsonString);

import 'dart:convert';

TinResponseData tinResponseDataFromJson(String str) => TinResponseData.fromJson(json.decode(str));

String tinResponseDataToJson(TinResponseData data) => json.encode(data.toJson());

class TinResponseData {
    int statusCode;
    Data data;
    String message;

    TinResponseData({
        required this.statusCode,
        required this.data,
        required this.message,
    });

    factory TinResponseData.fromJson(Map<String, dynamic> json) => TinResponseData(
        statusCode: json["statusCode"],
        data: Data.fromJson(json["data"]),
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "data": data.toJson(),
        "message": message,
    };
}

class Data {
    String? country;
    String? countryCode;
    String? tinStructureIndividuals;
    String? tinFormatIndividuals;
    String? tinStructureLegalEntities;
    String? tinFormatLegalEntities;
    String? comment;
    int? tinLogic;
    String? status;

    Data({
         this.country,
         this.countryCode,
         this.tinStructureIndividuals,
         this.tinFormatIndividuals,
         this.tinStructureLegalEntities,
         this.tinFormatLegalEntities,
         this.comment,
         this.tinLogic,
         this.status,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        country: json["country"],
        countryCode: json["country_code"],
        tinStructureIndividuals: json["tin_structure_individuals"],
        tinFormatIndividuals: json["tin_format_individuals"],
        tinStructureLegalEntities: json["tin_structure_legal_entities"],
        tinFormatLegalEntities: json["tin_format_legal_entities"],
        comment: json["comment"],
        tinLogic: json["tin_logic"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "country": country,
        "country_code": countryCode,
        "tin_structure_individuals": tinStructureIndividuals,
        "tin_format_individuals": tinFormatIndividuals,
        "tin_structure_legal_entities": tinStructureLegalEntities,
        "tin_format_legal_entities": tinFormatLegalEntities,
        "comment": comment,
        "tin_logic": tinLogic,
        "status": status,
    };
}
