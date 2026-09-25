class AaDataFetchAllResponse {
  final int statusCode;
  final String message;
  final AaDataFetchAllSummary summary;

  AaDataFetchAllResponse({
    required this.statusCode,
    required this.message,
    required this.summary,
  });

  factory AaDataFetchAllResponse.fromJson(Map<String, dynamic> json) {
    return AaDataFetchAllResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      summary: AaDataFetchAllSummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'summary': summary.toJson(),
    };
  }
}

class AaDataFetchAllSummary {
  final int total;
  final int triggered;
  final int skipped;
  final int failed;
  final int overallAdhocCount;
  final DateTime? latestStartedAt;
  final int estimatedDurationSec;
  final int pollEverySec;
  final int timeoutSec;

  AaDataFetchAllSummary({
    required this.total,
    required this.triggered,
    required this.skipped,
    required this.failed,
    required this.overallAdhocCount,
    this.latestStartedAt,
    required this.estimatedDurationSec,
    required this.pollEverySec,
    required this.timeoutSec,
  });

  factory AaDataFetchAllSummary.fromJson(Map<String, dynamic> json) {
    return AaDataFetchAllSummary(
      total: json['total'] ?? 0,
      triggered: json['triggered'] ?? 0,
      skipped: json['skipped'] ?? 0,
      failed: json['failed'] ?? 0,
      overallAdhocCount: json['overalladhoccount'] ?? 0,
      latestStartedAt: json['lateststartedat'] != null
          ? DateTime.tryParse(json['lateststartedat'])
          : null,
      estimatedDurationSec: json['estimateddurationsec'] ?? 300,
      pollEverySec: json['polleverysec'] ?? 5,
      timeoutSec: json['timeoutsec'] ?? 900,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'triggered': triggered,
      'skipped': skipped,
      'failed': failed,
      'overalladhoccount': overallAdhocCount,
      'lateststartedat': latestStartedAt?.toIso8601String(),
      'estimateddurationsec': estimatedDurationSec,
      'polleverysec': pollEverySec,
      'timeoutsec': timeoutSec,
    };
  }
}
