class BankTransactionResponse {
  int status;
  String message;
  TransactionData? data;
  bool get success => status == 200 || status == 201;

  BankTransactionResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory BankTransactionResponse.fromJson(
    Map<String, dynamic> json,
  ) => BankTransactionResponse(
    status: json["statusCode"],
    message: json["message"],
    data: json["data"] != null ? TransactionData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class TransactionData {
  List<Banktransation> banktransations;
  double maxamount;
  Pagination? pagination;

  TransactionData({
    required this.banktransations,
    this.pagination,
    required this.maxamount,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      banktransations: List<Banktransation>.from(
        json["transactions"]
            .map((x) => Banktransation.fromJson(x))
            .where((t) => t.type.isNotEmpty && t.narration.isNotEmpty),
      ),
      pagination:
          json["pagination"] != null
              ? Pagination.fromJson(json["pagination"])
              : null,
      maxamount: json["maxamount"]?.toDouble() ?? 10000,
    );
  }

  Map<String, dynamic> toJson() => {
    "transactions": List<dynamic>.from(banktransations.map((x) => x.toJson())),
    "pagination": pagination?.toJson(),
    "maxamount": maxamount,
  };
}

class Pagination {
  int total;
  int page;
  int limit;
  int totalpages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalpages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json["total"],
    page: json["page"],
    limit: json["limit"],
    totalpages: json["totalpages"],
  );

  Map<String, dynamic> toJson() => {
    "total": total,
    "page": page,
    "limit": limit,
    "totalpages": totalpages,
  };
}

class Banktransation {
  int id;
  String? guid;
  String accountguid;
  String userguid;
  String? txnid;
  String type;
  String mode;
  double amount;
  double balanceaftertransaction;
  DateTime transactiontimestamp;
  DateTime valuedate;
  String narration;
  String? reference;
  bool finishprocessed;
  DateTime createdat;
  DateTime updatedat;

  Banktransation({
    required this.id,
    this.guid,
    required this.accountguid,
    required this.userguid,
    this.txnid,
    required this.type,
    required this.mode,
    required this.amount,
    required this.balanceaftertransaction,
    required this.transactiontimestamp,
    required this.valuedate,
    required this.narration,
    this.reference,
    required this.finishprocessed,
    required this.createdat,
    required this.updatedat,
  });

  factory Banktransation.fromJson(Map<String, dynamic> json) => Banktransation(
    id: json["id"] ?? 0,
    guid: json["guid"],
    accountguid: json["accountguid"] ?? "",
    userguid: json["userguid"] ?? "",
    txnid: json["txnid"],
    type: json["type"] ?? "",
    mode: json["mode"] ?? "N/A",
    amount: json["amount"] != null ? json["amount"].toDouble() : 0.0,
    balanceaftertransaction:
        json["balanceaftertransaction"] != null
            ? json["balanceaftertransaction"].toDouble()
            : 0.0,
    transactiontimestamp:
        json["transactiontimestamp"] != null
            ? DateTime.tryParse(json["transactiontimestamp"]) ?? DateTime.now()
            : DateTime.now(),
    valuedate:
        json["valuedate"] != null
            ? DateTime.tryParse(json["valuedate"]) ?? DateTime.now()
            : DateTime.now(),
    narration: json["narration"] ?? "",
    reference: json["reference"],
    finishprocessed: json["finishprocessed"] ?? false,
    createdat:
        json["createdat"] != null
            ? DateTime.tryParse(json["createdat"]) ?? DateTime.now()
            : DateTime.now(),
    updatedat:
        json["updatedat"] != null
            ? DateTime.tryParse(json["updatedat"]) ?? DateTime.now()
            : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "guid": guid,
    "accountguid": accountguid,
    "userguid": userguid,
    "txnid": txnid,
    "type": type,
    "mode": mode,
    "amount": amount,
    "balanceaftertransaction": balanceaftertransaction,
    "transactiontimestamp": transactiontimestamp.toIso8601String(),
    "valuedate": valuedate.toIso8601String(),
    "narration": narration,
    "reference": reference,
    "finishprocessed": finishprocessed,
    "createdat": createdat.toIso8601String(),
    "updatedat": updatedat.toIso8601String(),
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
