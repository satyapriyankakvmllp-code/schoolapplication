import 'money.dart';

enum TransactionStatus {
  INITIATED,
  SUCCESS,
  FAILED,
  REFUNDED;

  String get displayName {
    switch (this) {
      case TransactionStatus.INITIATED:
        return 'Initiated';
      case TransactionStatus.SUCCESS:
        return 'Success';
      case TransactionStatus.FAILED:
        return 'Failed';
      case TransactionStatus.REFUNDED:
        return 'Refunded';
    }
  }

  static TransactionStatus fromString(String? value) {
    if (value == null) return TransactionStatus.INITIATED;
    for (final s in TransactionStatus.values) {
      if (s.name.toUpperCase() == value.toUpperCase()) return s;
    }
    return TransactionStatus.INITIATED;
  }
}

/// Represents a payment transaction made toward a student fee invoice.
/// Persisted in backend "Module 5 Finance" collection `fee_payment_transactions`.
class FeePaymentTransaction {
  final String id;
  final String invoiceId;
  final String transactionReference;
  final String gatewayName;
  final double amount;
  final TransactionStatus status;
  final String paymentMethod;
  final String? receiptUrl;
  final String? settledAt;
  final String createdAt;
  final String updatedAt;

  const FeePaymentTransaction({
    required this.id,
    required this.invoiceId,
    required this.transactionReference,
    required this.gatewayName,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.receiptUrl,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  int get amountPaise => Money.rupeesToPaise(amount);

  FeePaymentTransaction copyWith({
    String? id,
    String? invoiceId,
    String? transactionReference,
    String? gatewayName,
    double? amount,
    TransactionStatus? status,
    String? paymentMethod,
    String? receiptUrl,
    String? settledAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return FeePaymentTransaction(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      transactionReference: transactionReference ?? this.transactionReference,
      gatewayName: gatewayName ?? this.gatewayName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FeePaymentTransaction.fromJson(Map<String, dynamic> json) {
    return FeePaymentTransaction(
      id: (json['id'] ?? '').toString(),
      invoiceId: (json['invoice_id'] ?? '').toString(),
      transactionReference: (json['transaction_reference'] ?? '').toString(),
      gatewayName: (json['gateway_name'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: TransactionStatus.fromString(json['status']?.toString()),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      receiptUrl: json['receipt_url']?.toString(),
      settledAt: json['settled_at']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'transaction_reference': transactionReference,
      'gateway_name': gatewayName,
      'amount': amount,
      'status': status.name,
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'settled_at': settledAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

