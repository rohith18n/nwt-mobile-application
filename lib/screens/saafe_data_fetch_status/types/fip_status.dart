import 'dart:convert';

class FipStatusResponse {
  int statusCode;
  String message;
  List<Datum>? FIPStatusData;
  DateTime? last_fetch_date_time_mfc;
  bool can_fetch_mfc;

  FipStatusResponse({
    required this.statusCode,
    required this.message,
    this.FIPStatusData,
    this.last_fetch_date_time_mfc,
    required this.can_fetch_mfc,
  });

  factory FipStatusResponse.fromJson(dynamic json) {
    if (json is List) {
      // Handle direct list of consents
      return FipStatusResponse(
        statusCode: 200,
        message: 'success',
        can_fetch_mfc: true,
        FIPStatusData: json.map((x) => Datum.fromConsentJson(x)).toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      // Handle wrapped consents response
      if (json.containsKey("consents") && json["consents"] is List) {
        return FipStatusResponse(
          statusCode: 200,
          message: json["message"] ?? "success",
          can_fetch_mfc: true,
          FIPStatusData:
              (json["consents"] as List)
                  .map((x) => Datum.fromConsentJson(x))
                  .toList(),
        );
      }

      // Handle original status response
      return FipStatusResponse(
        statusCode: json["statusCode"] ?? 200,
        message: json["message"] ?? "success",
        FIPStatusData:
            json["data"] != null
                ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
                : null,
        last_fetch_date_time_mfc:
            json["last_fetch_date_time_mfc"] != null
                ? DateTime.parse(json["last_fetch_date_time_mfc"])
                : null,
        can_fetch_mfc: json["can_fetch_mfc"] ?? true,
      );
    }

    return FipStatusResponse(
      statusCode: 0,
      message: "invalid response",
      can_fetch_mfc: false,
    );
  }

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data":
        FIPStatusData != null
            ? List<dynamic>.from(FIPStatusData!.map((x) => x.toJson()))
            : null,
    "last_fetch_date_time_mfc": last_fetch_date_time_mfc?.toIso8601String(),
    "can_fetch_mfc": can_fetch_mfc,
  };
}

class Datum {
  String userguid;
  String type;
  bool activestatus;
  DateTime fetchstatusupdatedat;
  String guid;
  String fipid;
  String fipname;
  String fetchstatus;
  DateTime balancedatetime;
  String? imageurl;
  String? maskedaccno;

  Datum({
    required this.userguid,
    required this.type,
    required this.activestatus,
    required this.fetchstatusupdatedat,
    required this.guid,
    required this.fipid,
    required this.fipname,
    required this.fetchstatus,
    required this.balancedatetime,
    this.imageurl,
    this.maskedaccno,
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    final fipIdVal = json["fipid"] ?? json["fipId"];
    return Datum(
      userguid: json["userguid"] ?? "",
      type: json["type"] ?? "",
      activestatus: json["activestatus"] ?? false,
      fetchstatusupdatedat: DateTime.parse(
        json["fetchstatusupdatedat"] ?? DateTime.now().toIso8601String(),
      ),
      guid: json["guid"] ?? "",
      fipid: fipIdVal ?? "",
      fipname:
          (fipIdVal != null && fipIdVal.toString().toLowerCase() != 'finarkein')
              ? fipIdVal.toString()
              : (json["fipname"] ?? "Unknown"),
      fetchstatus: json["fetchstatus"] ?? "",
      balancedatetime: DateTime.parse(
        json["balancedatetime"] ?? DateTime.now().toIso8601String(),
      ),
      imageurl: json["imageurl"] as String?,
      maskedaccno: json["maskedaccno"] as String?,
    );
  }

  factory Datum.fromConsentJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?)?.toUpperCase() ?? '';
    // Map consent status to fetch status
    // ACTIVE consent means data was successfully fetched (SUCCESS)
    // PENDING consent means it's still being processed (PENDING)
    String fetchStatus = 'PENDING';
    if (status == 'ACTIVE') {
      fetchStatus = 'SUCCESS';
    } else if (status == 'FAILED' ||
        status == 'EXPIRED' ||
        status == 'REVOKED') {
      fetchStatus = 'FAILED';
    }

    // Get account info if available
    String type = 'DEPOSIT';
    String? maskedAcc;
    String? fipId;

    dynamic raw = json['rawConsentData'] ?? json['raw_consent_data'];
    // Handle case where rawConsentData is a JSON-encoded string
    if (raw != null && raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        // Not a JSON string
      }
    }

    if (raw != null && raw is Map) {
      final accounts = raw['Accounts'] ?? raw['accounts'];
      if (accounts is List && accounts.isNotEmpty) {
        final acc = accounts[0];
        type = acc['fiType'] ?? acc['type'] ?? 'DEPOSIT';
        maskedAcc = acc['maskedAccNumber'] ?? acc['maskedAccNo'];
        fipId = acc['fipId'] ?? acc['fipid'] ?? acc['fip_id'];
      }
    }

    // Prioritize fipId from multiple possible locations
    String? finalFipId =
        json['fipId']?.toString() ??
        json['fipid']?.toString() ??
        json['FIPID']?.toString() ??
        fipId;

    // Use SUCCESS only if ACTIVE AND has actually fetched data
    if (status == 'ACTIVE' &&
        (json['lastFetchAt'] != null || json['last_fetch_at'] != null)) {
      fetchStatus = 'SUCCESS';
    }

    return Datum(
      userguid: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      type: type,
      activestatus: status == 'ACTIVE',
      fetchstatusupdatedat: _parseDate(
        json['lastFetchAt'] ?? json['last_fetch_at'],
      ),
      guid: json['id']?.toString() ?? '',
      fipid: finalFipId ?? json['provider'] ?? '',
      fipname:
          (finalFipId != null &&
                  finalFipId.toString().toLowerCase() != 'finarkein')
              ? finalFipId.toString()
              : (json['provider']?.toString() ?? 'Unknown'),
      fetchstatus: fetchStatus,
      balancedatetime: _parseDate(json['lastFetchAt'] ?? json['last_fetch_at']),
      maskedaccno: maskedAcc,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
    "userguid": userguid,
    "type": type,
    "activestatus": activestatus,
    "fetchstatusupdatedat": fetchstatusupdatedat.toIso8601String(),
    "guid": guid,
    "fipid": fipid,
    "fipname": fipname,
    "fetchstatus": fetchstatus,
    "balancedatetime": balancedatetime.toIso8601String(),
    "imageurl": imageurl,
    "maskedaccno": maskedaccno,
  };
}
