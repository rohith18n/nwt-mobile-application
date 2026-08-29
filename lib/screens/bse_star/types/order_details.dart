class BseOrderDetailsResponse {
    int statusCode;
    String message;
    Data?data;

    BseOrderDetailsResponse({
        required this.statusCode,
        required this.message,
         this.data,
    });

    factory BseOrderDetailsResponse.fromJson(Map<String, dynamic> json) => BseOrderDetailsResponse(
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
    String? id;
    String? status;
    String? scheme;
    String? type;
    double? amount;
    String? cur;
    DateTime? placedAt;
    String? redirectLink;
    String? bseOrderId;
    String? userId;
    String? uccId;
    bool? isUnits;
    bool? isFresh;
    String? physOrDemat;
    DateTime? createdAt;

    Data({
        this.id,
        this.status,
        this.scheme,
        this.type,
        this.amount,
        this.cur,
        this.placedAt,
        this.redirectLink,
        this.bseOrderId,
        this.userId,
        this.uccId,
        this.isUnits,
        this.isFresh,
        this.physOrDemat,
        this.createdAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        status: json["status"],
        scheme: json["scheme"],
        type: json["type"],
        amount: json["amount"]?.toDouble(),
        cur: json["cur"],
        placedAt: json["placed_at"] != null ? DateTime.parse(json["placed_at"]) : null,
        redirectLink: json["redirect_link"],
        bseOrderId: json["bse_order_id"],
        userId: json["user_id"],
        uccId: json["ucc_id"],
        isUnits: json["is_units"],
        isFresh: json["is_fresh"],
        physOrDemat: json["phys_or_demat"],
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "status": status,
        "scheme": scheme,
        "type": type,
        "amount": amount,
        "cur": cur,
        "placed_at": placedAt?.toIso8601String(),
        "redirect_link": redirectLink,
        "bse_order_id": bseOrderId,
        "user_id": userId,
        "ucc_id": uccId,
        "is_units": isUnits,
        "is_fresh": isFresh,
        "phys_or_demat": physOrDemat,
        "created_at": createdAt?.toIso8601String(),
    };
}
