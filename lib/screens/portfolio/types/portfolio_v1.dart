import 'package:nwt_app/utils/logger.dart';

class PortfolioMFOrderV1 {
  final dynamic id;
  final String? bseOrderId;
  final String uiStatus;
  final String amount;
  final String? folioNumber;
  final String schemeName;
  final String? placedAt;
  final String createdAt;
  final String? isin;
  final String? schemeCode;
  final String? ucc;
  final String? bseLifecycleStatus;
  final String? internalStatus;
  final String? allotmentDate;
  final String? allotmentUnits;
  final String? allotmentPrice;

  PortfolioMFOrderV1({
    required this.id,
    this.bseOrderId,
    required this.uiStatus,
    required this.amount,
    this.folioNumber,
    required this.schemeName,
    this.placedAt,
    required this.createdAt,
    this.isin,
    this.schemeCode,
    this.ucc,
    this.bseLifecycleStatus,
    this.internalStatus,
    this.allotmentDate,
    this.allotmentUnits,
    this.allotmentPrice,
  });

  factory PortfolioMFOrderV1.fromJson(Map<String, dynamic> json) {
    return PortfolioMFOrderV1(
      id: json['id'],
      bseOrderId: json['bse_order_id'],
      uiStatus: json['ui_status'] ?? 'UNKNOWN',
      amount: json['amount'].toString(),
      folioNumber: json['folio_number'],
      schemeName: json['scheme_name'] ?? json['scheme'] ?? 'Unknown Scheme',
      placedAt: json['placed_at'],
      createdAt: json['created_at'] ?? '',
      isin: json['isin'] ?? json['scheme_isin'] ?? json['isin_code'],
      schemeCode: json['scheme_code'] ?? json['bse_scheme'] ?? json['scheme'],
      ucc: json['ucc'] ?? json['ucc_client_code'],
      bseLifecycleStatus: json['bse_lifecycle_status'],
      internalStatus: json['internal_status'],
      allotmentDate: json['allotment_date'],
      allotmentUnits: json['allotment_units']?.toString(),
      allotmentPrice: json['allotment_price']?.toString(),
    );
  }

  String get displayLifecycleStatus {
    if (bseLifecycleStatus == null || bseLifecycleStatus!.isEmpty) return 'N/A';
    return bseLifecycleStatus!.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String get displayInternalStatus {
    if (internalStatus == null || internalStatus!.isEmpty) return 'N/A';
    return internalStatus!.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class PortfolioSIPRegistrationV1 {
  final dynamic id;
  final String? sxpId;
  final String schemeName;
  final String status;
  final String? amount;
  final String? frequency;
  final String? nextInstallmentDate;

  PortfolioSIPRegistrationV1({
    required this.id,
    this.sxpId,
    required this.schemeName,
    required this.status,
    this.amount,
    this.frequency,
    this.nextInstallmentDate,
  });

  factory PortfolioSIPRegistrationV1.fromJson(Map<String, dynamic> json) {
    try {
      return PortfolioSIPRegistrationV1(
        id: json['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        sxpId: json['sxp_id']?.toString(),
        schemeName: json['scheme_name']?.toString() ?? 'Unknown Scheme',
        status: json['status']?.toString() ?? 'UNKNOWN',
        amount: json['amount']?.toString() ?? '0.00',
        frequency: json['frequency']?.toString() ?? 'Monthly',
        nextInstallmentDate: json['next_installment_date']?.toString(),
      );
    } catch (e) {
      AppLogger.error(
        'Parsing error in PortfolioSIPRegistrationV1: $e | Data: $json',
      );
      return PortfolioSIPRegistrationV1(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        schemeName: 'Parsing Error',
        status: 'ERROR',
      );
    }
  }
}

class PortfolioSIPDetailV1 {
  final dynamic id;
  final String? sxpId;
  final String schemeName;
  final String status;
  final int? totalInstallments;
  final int? currentInstallment;
  final List<SIPInstallmentV1> installments;

  PortfolioSIPDetailV1({
    required this.id,
    this.sxpId,
    required this.schemeName,
    required this.status,
    this.totalInstallments,
    this.currentInstallment,
    required this.installments,
  });

  factory PortfolioSIPDetailV1.fromJson(Map<String, dynamic> json) {
    return PortfolioSIPDetailV1(
      id: json['id'],
      sxpId: json['sxp_id'],
      schemeName: json['scheme_name'] ?? 'Unknown Scheme',
      status: json['status'] ?? 'UNKNOWN',
      totalInstallments: json['total_installments'],
      currentInstallment: json['current_installment'],
      installments:
          (json['installments'] as List? ?? [])
              .map((e) => SIPInstallmentV1.fromJson(e))
              .toList(),
    );
  }
}

class SIPInstallmentV1 {
  final int number;
  final String dueDate;
  final String status;
  final String uiStatus;

  SIPInstallmentV1({
    required this.number,
    required this.dueDate,
    required this.status,
    required this.uiStatus,
  });

  factory SIPInstallmentV1.fromJson(Map<String, dynamic> json) {
    return SIPInstallmentV1(
      number: json['number'] ?? 0,
      dueDate: json['due_date'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      uiStatus: json['ui_status'] ?? 'UNKNOWN',
    );
  }
}

class SellablePortfolioItemV1 {
  final dynamic id;
  final String schemeName;
  final String? schemeCode;
  final String? isin;
  final String? folioNumber;
  final String? ucc;
  final String amount;
  final String? units;
  final double? nav;

  SellablePortfolioItemV1({
    required this.id,
    required this.schemeName,
    this.schemeCode,
    this.isin,
    this.folioNumber,
    this.ucc,
    required this.amount,
    this.units,
    this.nav,
  });

  factory SellablePortfolioItemV1.fromJson(Map<String, dynamic> json) {
    return SellablePortfolioItemV1(
      id: json['id'],
      schemeName: json['scheme_name'] ?? 'Unknown Scheme',
      schemeCode: json['scheme_code'],
      isin: json['isin'],
      folioNumber: json['folio_number'],
      ucc: json['ucc'],
      amount: json['amount'].toString(),
      units: json['allotment_units']?.toString(),
      nav: (json['allotment_details']?['allotment_nav'] ?? 0.0).toDouble(),
    );
  }
}

class PortfolioMFOrderDetailV1 {
  final dynamic id;
  final String? bseOrderId;
  final String? internalStatus;
  final String uiStatus;
  final String amount;
  final String? folioNumber;
  final String? allotmentUnits;
  final String? allotmentPrice;
  final PaymentInfoV1? payment;

  PortfolioMFOrderDetailV1({
    required this.id,
    this.bseOrderId,
    this.internalStatus,
    required this.uiStatus,
    required this.amount,
    this.folioNumber,
    this.allotmentUnits,
    this.allotmentPrice,
    this.payment,
  });

  factory PortfolioMFOrderDetailV1.fromJson(Map<String, dynamic> json) {
    return PortfolioMFOrderDetailV1(
      id: json['id'],
      bseOrderId: json['bse_order_id'],
      internalStatus: json['internal_status'],
      uiStatus: json['ui_status'] ?? 'UNKNOWN',
      amount: json['amount'].toString(),
      folioNumber: json['folio_number'],
      allotmentUnits: json['allotment_units']?.toString(),
      allotmentPrice: json['allotment_price']?.toString(),
      payment:
          json['payment'] != null
              ? PaymentInfoV1.fromJson(json['payment'])
              : null,
    );
  }
}

class PaymentInfoV1 {
  final String? paymentStatus;
  final String? bsePaymentRefId;

  PaymentInfoV1({this.paymentStatus, this.bsePaymentRefId});

  factory PaymentInfoV1.fromJson(Map<String, dynamic> json) {
    return PaymentInfoV1(
      paymentStatus: json['payment_status'],
      bsePaymentRefId: json['bse_payment_ref_id'],
    );
  }
}
