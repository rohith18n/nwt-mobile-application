class AaDataFetchOptionsResponse {
  final int statusCode;
  final String message;
  final AaDataFetchSummary? summary;
  final AaDataFetchOptionsData? data;
  final int totalRefreshRemaining;

  AaDataFetchOptionsResponse({
    required this.statusCode,
    required this.message,
    this.summary,
    this.data,
    this.totalRefreshRemaining = 0,
  });

  factory AaDataFetchOptionsResponse.fromJson(Map<String, dynamic> json) {
    AaDataFetchSummary? summary;
    if (json["summary"] != null) {
      summary = AaDataFetchSummary.fromJson(json["summary"]);
    }

    AaDataFetchOptionsData? data;
    if (json["data"] != null) {
      final flatData = json["flatdata"] as List?;
      data = AaDataFetchOptionsData.fromCategorizedJson(
        json["data"],
        flatData: flatData,
        summary: summary,
      );
    }

    int? totalRemaining;

    // List of keys to check for the total count
    final possibleKeys = [
      "totalrefreshremaining",
      "total_refresh_remaining",
      "totalRefreshRemaining",
      "adhoc_remaining",
      "adhoc_remaining_count",
      "overalladhoccount",
      "adhoccount",
    ];

    // Helper to attempt parsing from multiple sources
    for (final key in possibleKeys) {
      // 1. Check root
      if (json[key] != null) {
        totalRemaining = double.tryParse(json[key].toString())?.toInt();
        if (totalRemaining != null) break;
      }
      // 2. Check "data" object
      if (json["data"] != null &&
          json["data"] is Map &&
          json["data"][key] != null) {
        totalRemaining = double.tryParse(json["data"][key].toString())?.toInt();
        if (totalRemaining != null) break;
      }
      // 3. Check "summary" object
      if (json["summary"] != null &&
          json["summary"] is Map &&
          json["summary"][key] != null) {
        totalRemaining =
            double.tryParse(json["summary"][key].toString())?.toInt();
        if (totalRemaining != null) break;
      }
    }

    return AaDataFetchOptionsResponse(
      statusCode: json["statusCode"] ?? 0,
      message: json["message"] ?? "",
      summary: summary,
      data: data,
      totalRefreshRemaining: totalRemaining ?? 0,
    );
  }

  factory AaDataFetchOptionsResponse.fromDynamic(dynamic json) {
    if (json is List) {
      return AaDataFetchOptionsResponse(
        statusCode: 200,
        message: "Success",
        data: AaDataFetchOptionsData.fromDynamic(json),
        totalRefreshRemaining: 0,
      );
    } else if (json is Map<String, dynamic>) {
      return AaDataFetchOptionsResponse.fromJson(json);
    }

    return AaDataFetchOptionsResponse(
      statusCode: 0,
      message: "Unknown response format",
      data: null,
      totalRefreshRemaining: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "statusCode": statusCode,
      "message": message,
      "summary": summary?.toJson(),
      "data": data?.toJson(),
      "totalrefreshremaining": totalRefreshRemaining,
    };
  }
}

class AaDataFetchSummary {
  final int overallAdhocCount;
  final int activeConsentCount;
  final int canFetchConsentCount;
  final int optionCount;

  AaDataFetchSummary({
    required this.overallAdhocCount,
    required this.activeConsentCount,
    required this.canFetchConsentCount,
    required this.optionCount,
  });

  factory AaDataFetchSummary.fromJson(Map<String, dynamic> json) {
    return AaDataFetchSummary(
      overallAdhocCount:
          int.tryParse(json["overalladhoccount"].toString()) ?? 0,
      activeConsentCount:
          int.tryParse(json["activeconsentcount"].toString()) ?? 0,
      canFetchConsentCount:
          int.tryParse(json["canfetchconsentcount"].toString()) ?? 0,
      optionCount: int.tryParse(json["optioncount"].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "overalladhoccount": overallAdhocCount,
      "activeconsentcount": activeConsentCount,
      "canfetchconsentcount": canFetchConsentCount,
      "optioncount": optionCount,
    };
  }
}

class AaDataFetchOptionsData {
  final int adhocRemainingCount;
  final int overallAdhocCount;
  final List<AaFetchOption> fetchOptions;

  // Categorized data
  final List<AaFetchOption> deposit;
  final List<AaFetchOption> mutualFunds;
  final List<AaFetchOption> equities;
  final List<AaFetchOption> etf;
  final List<AaFetchOption> equitiesEtf;
  final List<AaFetchOption> insurance;
  final List<AaFetchOption> nps;
  final List<AaFetchOption> others;

  AaDataFetchOptionsData({
    required this.adhocRemainingCount,
    this.overallAdhocCount = 0,
    required this.fetchOptions,
    this.deposit = const [],
    this.mutualFunds = const [],
    this.equities = const [],
    this.etf = const [],
    this.equitiesEtf = const [],
    this.insurance = const [],
    this.nps = const [],
    this.others = const [],
  });

  factory AaDataFetchOptionsData.fromJson(Map<String, dynamic> json) {
    return AaDataFetchOptionsData(
      adhocRemainingCount:
          json["adhoc_remaining_count"] ?? json["adhoccount"] ?? 0,
      overallAdhocCount: json["overalladhoccount"] ?? 0,
      fetchOptions:
          json["fetch_options"] != null
              ? List<AaFetchOption>.from(
                (json["fetch_options"] as List).map(
                  (x) => AaFetchOption.fromJson(Map<String, dynamic>.from(x)),
                ),
              )
              : [],
    );
  }

  factory AaDataFetchOptionsData.fromCategorizedJson(
    Map<String, dynamic> json, {
    List<dynamic>? flatData,
    AaDataFetchSummary? summary,
  }) {
    final deposit = _parseList(json["deposit"] ?? json["deposits"]);
    final mutualfunds = _parseList(json["mutualfunds"] ?? json["mutual_funds"]);
    final equities = _parseList(json["equities"] ?? json["stocks"]);
    final etf = _parseList(json["etf"] ?? json["etfs"]);
    final insurance = _parseList(json["insurance"] ?? json["policies"]);
    final nps = _parseList(json["nps"]);
    final others = _parseList(json["others"]);

    // Combine equities and etf for the legacy equitiesEtf field if needed
    final combinedEquitiesEtf = [...equities, ...etf];

    final allOptions =
        flatData != null
            ? flatData
                .map(
                  (x) => AaFetchOption.fromJson(Map<String, dynamic>.from(x)),
                )
                .toList()
            : [
              ...deposit,
              ...mutualfunds,
              ...combinedEquitiesEtf,
              ...insurance,
              ...nps,
              ...others,
            ];

    return AaDataFetchOptionsData(
      adhocRemainingCount: summary?.overallAdhocCount ?? 0,
      overallAdhocCount: summary?.overallAdhocCount ?? 0,
      fetchOptions: allOptions,
      deposit: deposit,
      mutualFunds: mutualfunds,
      equities: equities,
      etf: etf,
      equitiesEtf: combinedEquitiesEtf,
      insurance: insurance,
      nps: nps,
      others: others,
    );
  }

  static List<AaFetchOption> _parseList(dynamic list) {
    if (list is List) {
      final parsed =
          list
              .map((x) => AaFetchOption.fromJson(Map<String, dynamic>.from(x)))
              .toList();
      parsed.sort((a, b) {
        int nameCompare = (a.fipName).compareTo(b.fipName);
        if (nameCompare != 0) return nameCompare;
        return a.id.compareTo(b.id);
      });
      return parsed;
    }
    return [];
  }

  factory AaDataFetchOptionsData.fromDynamic(dynamic json) {
    if (json is List) {
      return AaDataFetchOptionsData(
        adhocRemainingCount: 0,
        overallAdhocCount: 0,
        fetchOptions:
            json
                .map(
                  (x) => AaFetchOption.fromJson(Map<String, dynamic>.from(x)),
                )
                .toList(),
      );
    } else if (json is Map<String, dynamic>) {
      return AaDataFetchOptionsData.fromJson(json);
    }

    return AaDataFetchOptionsData(
      adhocRemainingCount: 0,
      overallAdhocCount: 0,
      fetchOptions: [],
    );
  }

  AaDataFetchOptionsData copyWith({
    int? adhocRemainingCount,
    int? overallAdhocCount,
    List<AaFetchOption>? fetchOptions,
    List<AaFetchOption>? deposit,
    List<AaFetchOption>? mutualFunds,
    List<AaFetchOption>? equities,
    List<AaFetchOption>? etf,
    List<AaFetchOption>? equitiesEtf,
    List<AaFetchOption>? insurance,
    List<AaFetchOption>? nps,
    List<AaFetchOption>? others,
  }) {
    return AaDataFetchOptionsData(
      adhocRemainingCount: adhocRemainingCount ?? this.adhocRemainingCount,
      overallAdhocCount: overallAdhocCount ?? this.overallAdhocCount,
      fetchOptions: fetchOptions ?? this.fetchOptions,
      deposit: deposit ?? this.deposit,
      mutualFunds: mutualFunds ?? this.mutualFunds,
      equities: equities ?? this.equities,
      etf: etf ?? this.etf,
      equitiesEtf: equitiesEtf ?? this.equitiesEtf,
      insurance: insurance ?? this.insurance,
      nps: nps ?? this.nps,
      others: others ?? this.others,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "adhoc_remaining_count": adhocRemainingCount,
      "overalladhoccount": overallAdhocCount,
      "fetch_options": fetchOptions.map((x) => x.toJson()).toList(),
      "deposit": deposit.map((x) => x.toJson()).toList(),
      "mutualfunds": mutualFunds.map((x) => x.toJson()).toList(),
      "equitiesetf": equitiesEtf.map((x) => x.toJson()).toList(),
      "insurance": insurance.map((x) => x.toJson()).toList(),
      "nps": nps.map((x) => x.toJson()).toList(),
      "others": others.map((x) => x.toJson()).toList(),
    };
  }
}

class AaFetchOption {
  final String id;
  final String fipName;
  final String status;
  final DateTime? lastFetchedTime;
  final String? consentHandle;
  final String? requestHandle;
  final String? fipId;
  final int adhocRemainingCount;
  final Quota? quota;
  final String? accountType;
  final String? maskedAccNumber;
  final String? unmaskedAccNumber;
  final DateTime? fetchStatusUpdatedAt;

  AaFetchOption({
    required this.id,
    required this.fipName,
    required this.status,
    this.lastFetchedTime,
    this.consentHandle,
    this.requestHandle,
    this.fipId,
    this.adhocRemainingCount = 0,
    this.quota,
    this.accountType,
    this.maskedAccNumber,
    this.unmaskedAccNumber,
    this.fetchStatusUpdatedAt,
  });

  factory AaFetchOption.fromJson(Map<String, dynamic> json) {
    return AaFetchOption(
      id: json["id"]?.toString() ?? "",
      fipName:
          (json["displayname"] ?? json["fipname"] ?? json["name"])
              ?.toString() ??
          "",
      status: json["status"]?.toString() ?? "",
      lastFetchedTime:
          json["lastdatafetchedat"] != null &&
                  json["lastdatafetchedat"].toString().isNotEmpty
              ? DateTime.tryParse(json["lastdatafetchedat"].toString())
              : null,
      consentHandle:
          json["consenthandle"]?.toString() ??
          json["consent_handle"]?.toString(),
      requestHandle: json["request_handle"]?.toString(),
      fipId: json["fipid"]?.toString() ?? json["fip_id"]?.toString(),
      adhocRemainingCount:
          (json["adhoccount"] ?? json["adhoc_remaining"]) != null
              ? int.tryParse(
                    (json["adhoccount"] ?? json["adhoc_remaining"]).toString(),
                  ) ??
                  0
              : 0,
      quota:
          json["quota"] != null
              ? Quota.fromJson(Map<String, dynamic>.from(json["quota"]))
              : null,
      accountType: json["accounttype"]?.toString(),
      maskedAccNumber:
          json["maskedaccnumber"]?.toString() == "N"
              ? null
              : json["maskedaccnumber"]?.toString(),
      unmaskedAccNumber:
          json["unmaskedaccnumber"]?.toString() == "N"
              ? null
              : json["unmaskedaccnumber"]?.toString(),
      fetchStatusUpdatedAt:
          json["fetchstatusupdatedat"] != null &&
                  json["fetchstatusupdatedat"].toString().isNotEmpty
              ? DateTime.tryParse(json["fetchstatusupdatedat"].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": fipName,
      "displayname": fipName,
      "status": status,
      "lastdatafetchedat": lastFetchedTime?.toIso8601String(),
      "consent_handle": consentHandle,
      "consenthandle": consentHandle,
      "request_handle": requestHandle,
      "fip_id": fipId,
      "fipid": fipId,
      "adhoccount": adhocRemainingCount,
      "adhoc_remaining": adhocRemainingCount,
      "quota": quota?.toJson(),
      "accounttype": accountType,
      "maskedaccnumber": maskedAccNumber,
      "unmaskedaccnumber": unmaskedAccNumber,
      "fetchstatusupdatedat": fetchStatusUpdatedAt?.toIso8601String(),
    };
  }

  AaFetchOption copyWith({
    String? id,
    String? status,
    String? fipName,
    DateTime? lastFetchedTime,
    int? adhocRemainingCount,
    String? consentHandle,
    String? requestHandle,
    String? fipId,
    Quota? quota,
    String? accountType,
    String? maskedAccNumber,
    DateTime? fetchStatusUpdatedAt,
  }) {
    return AaFetchOption(
      id: id ?? this.id,
      status: status ?? this.status,
      fipName: fipName ?? this.fipName,
      lastFetchedTime: lastFetchedTime ?? this.lastFetchedTime,
      adhocRemainingCount: adhocRemainingCount ?? this.adhocRemainingCount,
      consentHandle: consentHandle ?? this.consentHandle,
      requestHandle: requestHandle ?? this.requestHandle,
      fipId: fipId ?? this.fipId,
      quota: quota ?? this.quota,
      accountType: accountType ?? this.accountType,
      maskedAccNumber: maskedAccNumber ?? this.maskedAccNumber,
      unmaskedAccNumber: unmaskedAccNumber ?? this.unmaskedAccNumber,
      fetchStatusUpdatedAt: fetchStatusUpdatedAt ?? this.fetchStatusUpdatedAt,
    );
  }
}

class Quota {
  final int maxFetches;
  final int fetchesUsed;
  final int remainingFetches;
  final bool canFetch;
  final String? reason;

  Quota({
    required this.maxFetches,
    required this.fetchesUsed,
    required this.remainingFetches,
    required this.canFetch,
    this.reason,
  });

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      maxFetches: json["maxfetches"] ?? 0,
      fetchesUsed: json["fetchesused"] ?? 0,
      remainingFetches: json["remainingfetches"] ?? 0,
      canFetch: json["canfetch"] ?? false,
      reason: json["reason"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "maxfetches": maxFetches,
      "fetchesused": fetchesUsed,
      "remainingfetches": remainingFetches,
      "canfetch": canFetch,
      "reason": reason,
    };
  }
}
