import 'money.dart';

enum PaymentStatus {
  UNPAID,
  PARTIALLY_PAID,
  PAID,
  OVERDUE;

  String get displayName {
    switch (this) {
      case PaymentStatus.UNPAID:
        return 'Unpaid';
      case PaymentStatus.PARTIALLY_PAID:
        return 'Partially Paid';
      case PaymentStatus.PAID:
        return 'Paid';
      case PaymentStatus.OVERDUE:
        return 'Overdue';
    }
  }

  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.UNPAID;
    for (final s in PaymentStatus.values) {
      if (s.name.toUpperCase() == value.toUpperCase()) return s;
    }
    return PaymentStatus.UNPAID;
  }
}

/// Represents an issued invoice for a student.
/// Persisted in backend "Module 5 Finance" collection `student_fee_invoices`.
/// Notice: base_amount is a snapshot copy of the fee structure total_fee at creation time.
class StudentFeeInvoice {
  final String id;
  final String invoiceNumber;
  final String studentId;
  final String feeStructureId;
  final double baseAmount;
  final double concessionAmount;
  final double lateFineAmount;
  final double totalPayable;
  final double amountPaid;
  final PaymentStatus paymentStatus;
  final String dueDate;
  final String createdAt;
  final String updatedAt;

  const StudentFeeInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.studentId,
    required this.feeStructureId,
    required this.baseAmount,
    required this.concessionAmount,
    required this.lateFineAmount,
    required this.totalPayable,
    required this.amountPaid,
    required this.paymentStatus,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  int get baseAmountPaise => Money.rupeesToPaise(baseAmount);
  int get concessionAmountPaise => Money.rupeesToPaise(concessionAmount);
  int get lateFineAmountPaise => Money.rupeesToPaise(lateFineAmount);
  int get totalPayablePaise => Money.rupeesToPaise(totalPayable);
  int get amountPaidPaise => Money.rupeesToPaise(amountPaid);
  int get pendingPaise => (totalPayablePaise - amountPaidPaise).clamp(0, totalPayablePaise);
  double get pendingRupees => Money.paiseToRupees(pendingPaise);

  StudentFeeInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? studentId,
    String? feeStructureId,
    double? baseAmount,
    double? concessionAmount,
    double? lateFineAmount,
    double? totalPayable,
    double? amountPaid,
    PaymentStatus? paymentStatus,
    String? dueDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return StudentFeeInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      studentId: studentId ?? this.studentId,
      feeStructureId: feeStructureId ?? this.feeStructureId,
      baseAmount: baseAmount ?? this.baseAmount,
      concessionAmount: concessionAmount ?? this.concessionAmount,
      lateFineAmount: lateFineAmount ?? this.lateFineAmount,
      totalPayable: totalPayable ?? this.totalPayable,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudentFeeInvoice.fromJson(Map<String, dynamic> json) {
    return StudentFeeInvoice(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoice_number'] ?? '').toString(),
      studentId: (json['student_id'] ?? '').toString(),
      feeStructureId: (json['fee_structure_id'] ?? '').toString(),
      baseAmount: (json['base_amount'] is num)
          ? (json['base_amount'] as num).toDouble()
          : double.tryParse(json['base_amount']?.toString() ?? '0') ?? 0.0,
      concessionAmount: (json['concession_amount'] is num)
          ? (json['concession_amount'] as num).toDouble()
          : double.tryParse(json['concession_amount']?.toString() ?? '0') ?? 0.0,
      lateFineAmount: (json['late_fine_amount'] is num)
          ? (json['late_fine_amount'] as num).toDouble()
          : double.tryParse(json['late_fine_amount']?.toString() ?? '0') ?? 0.0,
      totalPayable: (json['total_payable'] is num)
          ? (json['total_payable'] as num).toDouble()
          : double.tryParse(json['total_payable']?.toString() ?? '0') ?? 0.0,
      amountPaid: (json['amount_paid'] is num)
          ? (json['amount_paid'] as num).toDouble()
          : double.tryParse(json['amount_paid']?.toString() ?? '0') ?? 0.0,
      paymentStatus: PaymentStatus.fromString(json['payment_status']?.toString()),
      dueDate: (json['due_date'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'student_id': studentId,
      'fee_structure_id': feeStructureId,
      'base_amount': baseAmount,
      'concession_amount': concessionAmount,
      'late_fine_amount': lateFineAmount,
      'total_payable': totalPayable,
      'amount_paid': amountPaid,
      'payment_status': paymentStatus.name,
      'due_date': dueDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

