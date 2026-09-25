/// MF Central Linked Account
/// Represents a single linked mutual fund scheme from MF Central
class MFCentralLinkedAccount {
  final String fundSchemeName;
  final String folioNumber;
  final String lastUpdated;
  final String status;
  final String amcname;

  MFCentralLinkedAccount({
    required this.fundSchemeName,
    required this.folioNumber,
    required this.lastUpdated,
    required this.status,
    required this.amcname,
  });

  factory MFCentralLinkedAccount.fromJson(Map<String, dynamic> json) {
    return MFCentralLinkedAccount(
      fundSchemeName: json['fund_scheme_name'] ?? '',
      folioNumber: json['folio_number'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      status: json['status'] ?? 'PENDING',
      amcname: json['amcname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_scheme_name': fundSchemeName,
      'folio_number': folioNumber,
      'last_updated': lastUpdated,
      'status': status,
      'amcname': amcname,
    };
  }
}

/// MF Central Linked Accounts Response
class MFCentralLinkedAccountsResponse {
  final bool success;
  final List<MFCentralLinkedAccount> data;
  final String? message;

  MFCentralLinkedAccountsResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory MFCentralLinkedAccountsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return MFCentralLinkedAccountsResponse(
      success: json['success'] ?? false,
      data: dataList
          .map((e) => MFCentralLinkedAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}
