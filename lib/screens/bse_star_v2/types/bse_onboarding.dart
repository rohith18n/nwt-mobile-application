class BseOnboardingResponse {
    int statusCode;
    String message;
    Data? data;

    BseOnboardingResponse({
        required this.statusCode,
        required this.message,
        this.data,
    });

    factory BseOnboardingResponse.fromJson(Map<String, dynamic> json) => BseOnboardingResponse(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String id;
    String userId;
    String holdingNature;
    String investorCategory;
    String status;
    String sourceChannel;
    DateTime createdAt;
    dynamic updatedAt;

    Data({
        required this.id,
        required this.userId,
        required this.holdingNature,
        required this.investorCategory,
        required this.status,
        required this.sourceChannel,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        userId: json["user_id"],
        holdingNature: json["holding_nature"],
        investorCategory: json["investor_category"],
        status: json["status"],
        sourceChannel: json["source_channel"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "holding_nature": holdingNature,
        "investor_category": investorCategory,
        "status": status,
        "source_channel": sourceChannel,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt,
    };
}
