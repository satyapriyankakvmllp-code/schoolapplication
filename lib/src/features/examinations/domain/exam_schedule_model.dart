class ExamSchedule {
  final String examScheduleId;
  final String examName;
  final String examType;
  final String academicYear;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final String description;
  final String status; // PLANNED | ONGOING | COMPLETED | CANCELLED
  final String? cancelReason;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final int paperCount;

  const ExamSchedule({
    required this.examScheduleId,
    required this.examName,
    required this.examType,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.status,
    this.cancelReason,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.paperCount = 0,
  });

  bool get isPlanned => status.toUpperCase() == 'PLANNED';
  bool get isOngoing => status.toUpperCase() == 'ONGOING';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Rule 4 (Revised): Admin/Principal can Edit an exam in ANY status at any time. All fields are editable.
  bool get canBeEdited => true;
  bool get canOnlyEditLimitedFields => false;

  /// Rule 3: Cancel is manual, needs a reason, and is allowed only from PLANNED or ONGOING.
  bool get canBeCancelled => isPlanned || isOngoing;

  /// Rule 8 (Revised): Delete is allowed in ANY status.
  bool get canBeDeleted => true;

  ExamSchedule copyWith({
    String? examScheduleId,
    String? examName,
    String? examType,
    String? academicYear,
    String? startDate,
    String? endDate,
    String? description,
    String? status,
    String? cancelReason,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    int? paperCount,
  }) {
    return ExamSchedule(
      examScheduleId: examScheduleId ?? this.examScheduleId,
      examName: examName ?? this.examName,
      examType: examType ?? this.examType,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paperCount: paperCount ?? this.paperCount,
    );
  }

  factory ExamSchedule.fromJson(Map<String, dynamic> json, {int paperCount = 0}) {
    final rawStatus = (json['status'] ?? 'PLANNED').toString();
    final start = (json['start_date'] ?? '').toString();
    final end = (json['end_date'] ?? '').toString();

    final computedStatus = computeStatus(
      rawStatus: rawStatus,
      startDate: start,
      endDate: end,
    );

    return ExamSchedule(
      examScheduleId: (json['exam_schedule_id'] ?? json['id'] ?? '').toString(),
      examName: (json['exam_name'] ?? json['name'] ?? json['title'] ?? '').toString(),
      examType: (json['exam_type'] ?? json['type'] ?? 'UNIT_TEST').toString(),
      academicYear: (json['academic_year'] ?? '2026-2027').toString(),
      startDate: start,
      endDate: end,
      description: (json['description'] ?? '').toString(),
      status: computedStatus,
      cancelReason: json['cancel_reason']?.toString(),
      createdBy: (json['created_by'] ?? 'u1').toString(),
      createdAt: (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      updatedAt: (json['updated_at'] ?? DateTime.now().toIso8601String()).toString(),
      paperCount: paperCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_schedule_id': examScheduleId,
      'exam_name': examName,
      'exam_type': examType,
      'academic_year': academicYear,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'status': status,
      'cancel_reason': cancelReason,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Rule 2: Status is computed when data is read:
  /// PLANNED becomes ONGOING when today reaches start_date;
  /// ONGOING becomes COMPLETED when today passes end_date.
  /// CANCELLED never changes.
  static String computeStatus({
    required String rawStatus,
    required String startDate,
    required String endDate,
    DateTime? referenceDate,
  }) {
    if (rawStatus.toUpperCase() == 'CANCELLED') {
      return 'CANCELLED';
    }

    if (startDate.isEmpty || endDate.isEmpty) {
      return rawStatus.toUpperCase();
    }

    try {
      final now = referenceDate ?? DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final startParts = startDate.split('-').map(int.parse).toList();
      final endParts = endDate.split('-').map(int.parse).toList();
      final start = DateTime(startParts[0], startParts[1], startParts[2]);
      final end = DateTime(endParts[0], endParts[1], endParts[2]);

      if (today.isAfter(end)) {
        return 'COMPLETED';
      } else if (!today.isBefore(start)) {
        return 'ONGOING';
      } else {
        return 'PLANNED';
      }
    } catch (_) {
      return rawStatus.toUpperCase();
    }
  }
}

class ExamLinkedDataCounts {
  final int papers;
  final int hallTickets;
  final int attendance;
  final int marks;
  final int reportCards;

  const ExamLinkedDataCounts({
    this.papers = 0,
    this.hallTickets = 0,
    this.attendance = 0,
    this.marks = 0,
    this.reportCards = 0,
  });

  int get total => papers + hallTickets + attendance + marks + reportCards;
  bool get hasLinkedData => total > 0;

  String formatSummary() {
    final parts = <String>[];
    if (papers > 0) parts.add('$papers paper${papers == 1 ? '' : 's'}');
    if (hallTickets > 0) parts.add('$hallTickets hall ticket${hallTickets == 1 ? '' : 's'}');
    if (attendance > 0) parts.add('$attendance attendance record${attendance == 1 ? '' : 's'}');
    if (marks > 0) parts.add('$marks mark${marks == 1 ? '' : 's'}');
    if (reportCards > 0) parts.add('$reportCards report card${reportCards == 1 ? '' : 's'}');

    if (parts.isEmpty) {
      return '';
    } else if (parts.length == 1) {
      return 'This exam has ${parts.first}. Deleting will remove all of them. This cannot be undone.';
    } else {
      final last = parts.removeLast();
      return 'This exam has ${parts.join(', ')} and $last. Deleting will remove all of them. This cannot be undone.';
    }
  }
}

