enum ResolutionType {
  MANUAL_RECONCILED,
  CREDIT_NOTE_ISSUED,
  REFUNDED;

  String get displayName {
    switch (this) {
      case ResolutionType.MANUAL_RECONCILED:
        return 'Manual Reconciled';
      case ResolutionType.CREDIT_NOTE_ISSUED:
        return 'Credit Note Issued';
      case ResolutionType.REFUNDED:
        return 'Refunded';
    }
  }

  static ResolutionType? fromString(String? value) {
    if (value == null) return null;
    for (final r in ResolutionType.values) {
      if (r.name.toUpperCase() == value.toUpperCase()) return r;
    }
    return null;
  }
}

enum TicketStatus {
  OPEN,
  UNDER_REVIEW,
  RESOLVED;

  String get displayName {
    switch (this) {
      case TicketStatus.OPEN:
        return 'Open';
      case TicketStatus.UNDER_REVIEW:
        return 'Under Review';
      case TicketStatus.RESOLVED:
        return 'Resolved';
    }
  }

  static TicketStatus fromString(String? value) {
    if (value == null) return TicketStatus.OPEN;
    for (final s in TicketStatus.values) {
      if (s.name.toUpperCase() == value.toUpperCase()) return s;
    }
    return TicketStatus.OPEN;
  }
}

/// Represents an issue ticket raised when a payment gateway deduction requires reconciliation.
/// Persisted in backend "Module 5 Finance" collection `payment_reconciliation_tickets`.
class PaymentReconciliationTicket {
  final String id;
  final String transactionId;
  final String parentId;
  final String issueDescription;
  final ResolutionType? resolutionType;
  final String? resolutionNotes;
  final String? resolvedByOfficerId;
  final TicketStatus status;
  final String createdAt;
  final String updatedAt;

  const PaymentReconciliationTicket({
    required this.id,
    required this.transactionId,
    required this.parentId,
    required this.issueDescription,
    this.resolutionType,
    this.resolutionNotes,
    this.resolvedByOfficerId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentReconciliationTicket copyWith({
    String? id,
    String? transactionId,
    String? parentId,
    String? issueDescription,
    ResolutionType? resolutionType,
    String? resolutionNotes,
    String? resolvedByOfficerId,
    TicketStatus? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PaymentReconciliationTicket(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      parentId: parentId ?? this.parentId,
      issueDescription: issueDescription ?? this.issueDescription,
      resolutionType: resolutionType ?? this.resolutionType,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedByOfficerId: resolvedByOfficerId ?? this.resolvedByOfficerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PaymentReconciliationTicket.fromJson(Map<String, dynamic> json) {
    return PaymentReconciliationTicket(
      id: (json['id'] ?? '').toString(),
      transactionId: (json['transaction_id'] ?? '').toString(),
      parentId: (json['parent_id'] ?? '').toString(),
      issueDescription: (json['issue_description'] ?? '').toString(),
      resolutionType: ResolutionType.fromString(json['resolution_type']?.toString()),
      resolutionNotes: json['resolution_notes']?.toString(),
      resolvedByOfficerId: json['resolved_by_officer_id']?.toString(),
      status: TicketStatus.fromString(json['status']?.toString()),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'parent_id': parentId,
      'issue_description': issueDescription,
      if (resolutionType != null) 'resolution_type': resolutionType!.name,
      'resolution_notes': resolutionNotes,
      'resolved_by_officer_id': resolvedByOfficerId,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

