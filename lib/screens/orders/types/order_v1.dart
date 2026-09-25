class UccAccountRespose {
  final bool success;
  final List<UccAccount> accounts;

  UccAccountRespose({required this.success, required this.accounts});

  factory UccAccountRespose.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final accountsList = data?['accounts'] as List? ?? [];
    return UccAccountRespose(
      success: json['success'] ?? false,
      accounts: accountsList.map((e) => UccAccount.fromJson(e)).toList(),
    );
  }
}

class UccAccount {
  final String id;
  final String clientCode;
  final String holdingNature;
  final bool isActive;
  final String? secondaryHolderName;

  UccAccount({
    required this.id,
    required this.clientCode,
    required this.holdingNature,
    required this.isActive,
    this.secondaryHolderName,
  });

  factory UccAccount.fromJson(Map<String, dynamic> json) {
    return UccAccount(
      id: json['id'] ?? '',
      clientCode: json['client_code'] ?? '',
      holdingNature: json['holding_nature'] ?? '',
      isActive: json['is_active'] ?? false,
      secondaryHolderName: json['secondary_holder_name'],
    );
  }
}

class FolioResponse {
  final bool success;
  final List<String> folios;

  FolioResponse({required this.success, required this.folios});

  factory FolioResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return FolioResponse(
      success: json['success'] ?? false,
      folios: List<String>.from(data?['folios'] ?? []),
    );
  }
}

class OrderCreateResponse {
  final bool success;
  final String message;
  final OrderData? data;
  final Map<String, dynamic>? details;

  OrderCreateResponse({
    required this.success,
    required this.message,
    this.data,
    this.details,
  });

  factory OrderCreateResponse.fromJson(Map<String, dynamic> json) {
    return OrderCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OrderData.fromJson(json['data']) : null,
      details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
    );
  }
}

class OrderData {
  final int orderId;
  final String bseOrderId;
  final String amount;
  final List<BankDetail> bankDetails;
  final String? upiId;

  OrderData({
    required this.orderId,
    required this.bseOrderId,
    required this.amount,
    required this.bankDetails,
    this.upiId,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    final banks = json['bank_details'] as List? ?? [];
    return OrderData(
      orderId: json['order_id'] ?? 0,
      bseOrderId: json['bse_order_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      bankDetails: banks.map((e) => BankDetail.fromJson(e)).toList(),
      upiId: json['upi_id'],
    );
  }
}

class BankDetail {
  final String bankName;
  final String accountNumber;
  final String ifscCode;

  BankDetail({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
  });

  factory BankDetail.fromJson(Map<String, dynamic> json) {
    return BankDetail(
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
    );
  }
}

class PaymentResponse {
  final bool success;
  final String message;
  final PaymentData? data;

  PaymentResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
    );
  }
}

class PaymentData {
  final String paymentMode;
  final int orderId;
  final String bsePaymentRefId;
  final String? paymentUrl;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentParams;

  PaymentData({
    required this.paymentMode,
    required this.orderId,
    required this.bsePaymentRefId,
    this.paymentUrl,
    this.paymentMethod,
    this.paymentParams,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      paymentMode: json['payment_mode'] ?? '',
      orderId: json['order_id'] ?? 0,
      bsePaymentRefId: json['bse_payment_ref_id']?.toString() ?? '',
      paymentUrl: json['payment_url'],
      paymentMethod: json['payment_method'],
      paymentParams: json['payment_params'] != null
          ? Map<String, dynamic>.from(json['payment_params'])
          : null,
    );
  }
}

class PaymentStatusResponse {
  final bool success;
  final PaymentStatusData? data;

  PaymentStatusResponse({required this.success, this.data});

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? PaymentStatusData.fromJson(json['data']) : null,
    );
  }
}

class PaymentStatusData {
  final String paymentStatus;
  final String orderStatus;

  PaymentStatusData({required this.paymentStatus, required this.orderStatus});

  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    return PaymentStatusData(
      paymentStatus: json['payment_status'] ?? '',
      orderStatus: json['order_status'] ?? '',
    );
  }
}

class RedeemResponse {
  final bool success;
  final String message;
  final RedeemData? data;

  RedeemResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RedeemResponse.fromJson(Map<String, dynamic> json) {
    return RedeemResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? RedeemData.fromJson(json['data']) : null,
    );
  }
}

class RedeemData {
  final int orderId;
  final String bseOrderId;
  final String amount;

  RedeemData({
    required this.orderId,
    required this.bseOrderId,
    required this.amount,
  });

  factory RedeemData.fromJson(Map<String, dynamic> json) {
    return RedeemData(
      orderId: json['order_id'] ?? 0,
      bseOrderId: json['bse_order_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.0',
    );
  }
}
