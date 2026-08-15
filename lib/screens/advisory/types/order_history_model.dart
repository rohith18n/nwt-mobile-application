class OrderHistoryModel {
  final dynamic id;
  final dynamic bseOrderId;
  final String status;
  final String? bseScheme;
  final String? scheme;
  final dynamic amount;
  final String? type;
  final bool? isUnits;
  final String? cur;
  final String? createdAt;
  final String? placedAt;
  final dynamic nav;
  final String? navDate;
  final dynamic units;
  final String? fundName;
  final String? fundLogo;
  final String? isin;

  final String? bseLifecycleStatus;
  final String? folioNumber;
  final String? allotmentDate;
  final dynamic allotmentUnits;
  final dynamic allotmentPrice;
  final String? internalStatus;
  final String? uiStatus;

  OrderHistoryModel({
    this.id,
    this.bseOrderId,
    required this.status,
    this.bseScheme,
    this.scheme,
    this.amount,
    this.type,
    this.isUnits,
    this.cur,
    this.createdAt,
    this.placedAt,
    this.nav,
    this.navDate,
    this.units,
    this.fundName,
    this.fundLogo,
    this.isin,
    this.bseLifecycleStatus,
    this.folioNumber,
    this.allotmentDate,
    this.allotmentUnits,
    this.allotmentPrice,
    this.internalStatus,
    this.uiStatus,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      id: json['id'],
      bseOrderId: json['bse_order_id'],
      status: (json['ui_status'] ?? json['status'])?.toString() ?? 'UNKNOWN',
      bseScheme: json['bse_scheme']?.toString(),
      scheme: json['scheme']?.toString(),
      amount: json['amount'],
      type: json['type']?.toString(),
      isUnits: _parseBool(json['is_units']),
      cur: json['cur']?.toString(),
      createdAt: json['created_at']?.toString(),
      placedAt: json['placed_at']?.toString(),
      nav: json['nav'],
      navDate: json['nav_date']?.toString(),
      units: json['units'],
      fundName:
          json['fund_name']?.toString() ?? json['scheme_name']?.toString(),
      fundLogo: json['fund_logo']?.toString(),
      isin:
          (json['isin'] ?? json['isin_code'] ?? json['scheme_isin'])
              ?.toString(),
      bseLifecycleStatus: json['bse_lifecycle_status']?.toString(),
      folioNumber: json['folio_number']?.toString(),
      allotmentDate: json['allotment_date']?.toString(),
      allotmentUnits: json['allotment_units'],
      allotmentPrice: json['allotment_price'],
      internalStatus: json['internal_status']?.toString(),
      uiStatus: json['ui_status']?.toString(),
    );
  }

  /// Safe bool parser
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

  /// Fund name fallback
  String get displayFundName {
    return fundName ?? scheme ?? bseScheme ?? 'Unknown Fund';
  }

  /// User friendly status
  String get displayStatus {
    final rawStatus = status.toLowerCase();

    switch (rawStatus) {
      case 'done':
      case 'success':
        return 'Done';

      case 'failed':
        return 'Failed';

      case 'processing':
        return 'Processing';

      case 'payment_pending':
        return 'Pending Payment';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';

      case 'pending_execution':
        return 'Pending Execution';

      default:
        if (status.isEmpty) return status;
        return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
    }
  }

  bool get isSuccess {
    final rawStatus = status.toLowerCase();
    return rawStatus == 'done' || rawStatus == 'success';
  }

  bool get isProcessing {
    final rawStatus = status.toLowerCase();
    return rawStatus == 'processing';
  }

  bool get isFailed {
    final rawStatus = status.toLowerCase();
    return rawStatus == 'failed' ||
        rawStatus == 'rejected' ||
        rawStatus == 'expired';
  }

  bool get isRedemption {
    return type?.toUpperCase() == 'R';
  }

  bool get isPaymentPending {
    final rawStatus = status.toLowerCase();
    return rawStatus == 'payment_pending';
  }

  String get displayNav {
    if (nav != null) {
      final doubleVal = double.tryParse(nav.toString());
      if (doubleVal != null) {
        return '₹${doubleVal.toStringAsFixed(2)}';
      }
    }
    return 'N/A';
  }

  String get displayUnits {
    if (units != null) {
      final doubleVal = double.tryParse(units.toString());
      if (doubleVal != null) {
        return doubleVal.toStringAsFixed(3);
      }
    }
    return 'N/A';
  }

  String get displayOrderId {
    return bseOrderId?.toString() ?? id?.toString() ?? 'N/A';
  }

  String get displayLifecycleStatus {
    if (bseLifecycleStatus == null || bseLifecycleStatus!.isEmpty) return 'N/A';
    return bseLifecycleStatus!
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String get displayInternalStatus {
    if (internalStatus == null || internalStatus!.isEmpty) return 'N/A';
    return internalStatus!
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String get displayFolioNumber {
    if (folioNumber == null || folioNumber!.isEmpty) return 'N/A';
    return folioNumber!;
  }

  String get displayAllotmentDate {
    if (allotmentDate == null || allotmentDate!.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(allotmentDate!);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return allotmentDate!.split('T')[0];
    }
  }

  String get displayAllotmentUnits {
    if (allotmentUnits != null) {
      final doubleVal = double.tryParse(allotmentUnits.toString());
      if (doubleVal != null) {
        return doubleVal.toStringAsFixed(3);
      }
    }
    return 'N/A';
  }

  String get displayAllotmentPrice {
    if (allotmentPrice != null) {
      final doubleVal = double.tryParse(allotmentPrice.toString());
      if (doubleVal != null) {
        return '₹${doubleVal.toStringAsFixed(2)}';
      }
    }
    return 'N/A';
  }
}
