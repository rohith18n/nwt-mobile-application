/// Single consent from GET aa/consents (pm-mfu). Used for Finarkein adhoc remaining.
class AaConsent {
  final String? id;
  final String? consentHandle;
  final String? requestId;
  final int fetchesUsed;
  final int maxFetches;
  final String? status;
  final String? provider;
  final DateTime? lastFetchAt;
  final DateTime? consentExpiry;
  final List<ConsentAccount> accounts;

  AaConsent({
    this.id,
    this.consentHandle,
    this.requestId,
    required this.fetchesUsed,
    required this.maxFetches,
    this.status,
    this.provider,
    this.lastFetchAt,
    this.consentExpiry,
    this.accounts = const [],
  });

  int get remaining => (maxFetches - fetchesUsed).clamp(0, maxFetches);

  /// True when consent is ACTIVE and can be used for data/fetch and revoke. PENDING = journey not completed yet.
  bool get isActive => (status ?? '').trim().toUpperCase() == 'ACTIVE';

  factory AaConsent.fromJson(Map<String, dynamic> json) {
    final fetchesUsed = json['fetchesUsed'] ?? json['fetches_used'] ?? 0;
    final maxFetches = json['maxFetches'] ?? json['max_fetches'] ?? 45;
    
    List<ConsentAccount> accountsList = [];
    final raw = json['rawConsentData'];
    if (raw != null && raw is Map && raw['Accounts'] != null && raw['Accounts'] is List) {
      accountsList = (raw['Accounts'] as List)
          .map((a) => ConsentAccount.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return AaConsent(
      id: json['id']?.toString(),
      consentHandle: json['consentHandle'] ?? json['consent_handle'],
      requestId: json['requestId'] ?? json['request_id'],
      fetchesUsed: fetchesUsed is int ? fetchesUsed : int.tryParse(fetchesUsed.toString()) ?? 0,
      maxFetches: maxFetches is int ? maxFetches : int.tryParse(maxFetches.toString()) ?? 45,
      status: json['status']?.toString(),
      provider: json['provider']?.toString(),
      lastFetchAt: _parseDate(json['lastFetchAt'] ?? json['last_fetch_at']),
      consentExpiry: _parseDate(json['consentExpiry'] ?? json['consent_expiry']),
      accounts: accountsList,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}

class ConsentAccount {
  final String? fiType;
  final String? fipId;
  final String? accType;
  final String? maskedAccNumber;

  ConsentAccount({
    this.fiType,
    this.fipId,
    this.accType,
    this.maskedAccNumber,
  });

  factory ConsentAccount.fromJson(Map<String, dynamic> json) {
    return ConsentAccount(
      fiType: json['fiType']?.toString(),
      fipId: json['fipId']?.toString(),
      accType: json['accType']?.toString(),
      maskedAccNumber: json['maskedAccNumber']?.toString(),
    );
  }
}
