/// Individual subject paper (one row of the exam timetable).
class ExamPaper {
  final String id;
  final String examScheduleId;
  final String? examDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? classSectionId;
  final String? subjectId;
  final double maxMarks;
  final double passingMarks;
  final String? invigilatorId;
  final String? roomId;
  final String status; // SCHEDULED | ONGOING | COMPLETED | CANCELLED
  final bool manualStatus;
  final String? cancelReason;
  final String createdAt;
  final String updatedAt;

  const ExamPaper({
    required this.id,
    required this.examScheduleId,
    this.examDate,
    this.startTime = '09:30',
    this.endTime = '12:00',
    this.classSectionId,
    this.subjectId,
    this.maxMarks = 100.0,
    this.passingMarks = 35.0,
    this.invigilatorId,
    this.roomId,
    this.status = 'SCHEDULED',
    this.manualStatus = false,
    this.cancelReason,
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isOngoing => status == 'ONGOING';

  static String normTime(String? t) {
    if (t == null || t.isEmpty) return '';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  /// Minutes since midnight for HH:mm (or -1 when invalid).
  static int minutesOf(String t) {
    try {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    } catch (_) {
      return -1;
    }
  }

  /// Paper status is computed from date and time, unless it was cancelled or
  /// the admin picked a status manually.
  static String computeStatus({
    required String rawStatus,
    required bool manual,
    required String? examDate,
    required String startTime,
    required String endTime,
    DateTime? now,
  }) {
    final raw = rawStatus.toUpperCase();
    if (raw == 'CANCELLED') return 'CANCELLED';
    if (manual) return raw;
    if (examDate == null || examDate.isEmpty) return 'SCHEDULED';
    try {
      final n = now ?? DateTime.now();
      final d = examDate.split('-').map(int.parse).toList();
      final sm = minutesOf(startTime);
      final em = minutesOf(endTime);
      final start = DateTime(d[0], d[1], d[2], sm ~/ 60, sm % 60);
      final end = DateTime(d[0], d[1], d[2], em ~/ 60, em % 60);
      if (n.isAfter(end)) return 'COMPLETED';
      if (!n.isBefore(start)) return 'ONGOING';
      return 'SCHEDULED';
    } catch (_) {
      return raw.isEmpty ? 'SCHEDULED' : raw;
    }
  }

  ExamPaper copyWith({
    String? id,
    String? examScheduleId,
    String? examDate,
    String? startTime,
    String? endTime,
    String? classSectionId,
    String? subjectId,
    double? maxMarks,
    double? passingMarks,
    String? invigilatorId,
    bool clearInvigilator = false,
    String? roomId,
    bool clearRoom = false,
    String? status,
    bool? manualStatus,
    String? cancelReason,
    bool clearCancelReason = false,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExamPaper(
      id: id ?? this.id,
      examScheduleId: examScheduleId ?? this.examScheduleId,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      maxMarks: maxMarks ?? this.maxMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      invigilatorId: clearInvigilator ? null : (invigilatorId ?? this.invigilatorId),
      roomId: clearRoom ? null : (roomId ?? this.roomId),
      status: status ?? this.status,
      manualStatus: manualStatus ?? this.manualStatus,
      cancelReason: clearCancelReason ? null : (cancelReason ?? this.cancelReason),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExamPaper.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'SCHEDULED').toString();
    final manual = json['status_manual'] == true;
    final date = (json['exam_date'] ?? json['paper_date'])?.toString();
    final start = normTime(json['start_time']?.toString());
    final end = normTime(json['end_time']?.toString());
    return ExamPaper(
      id: (json['id'] ?? json['paper_id'] ?? json['exam_paper_id'] ?? '').toString(),
      examScheduleId: (json['exam_schedule_id'] ?? '').toString(),
      examDate: date,
      startTime: start.isEmpty ? '09:30' : start,
      endTime: end.isEmpty ? '12:00' : end,
      classSectionId: json['class_section_id']?.toString(),
      subjectId: json['subject_id']?.toString(),
      maxMarks: (json['max_marks'] as num?)?.toDouble() ?? 100.0,
      passingMarks: (json['passing_marks'] as num?)?.toDouble() ?? 35.0,
      invigilatorId: _nullIfEmpty(json['invigilator_id']),
      roomId: _nullIfEmpty(json['room_id']),
      status: computeStatus(
        rawStatus: rawStatus == 'ACTIVE' ? 'SCHEDULED' : rawStatus,
        manual: manual,
        examDate: date,
        startTime: start.isEmpty ? '09:30' : start,
        endTime: end.isEmpty ? '12:00' : end,
      ),
      manualStatus: manual,
      cancelReason: json['cancel_reason']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  static String? _nullIfEmpty(dynamic v) {
    final s = v?.toString();
    return (s == null || s.isEmpty || s == 'null') ? null : s;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_schedule_id': examScheduleId,
      'class_section_id': classSectionId,
      'subject_id': subjectId,
      'exam_date': examDate,
      'start_time': startTime,
      'end_time': endTime,
      'max_marks': maxMarks,
      'passing_marks': passingMarks,
      'invigilator_id': invigilatorId,
      'room_id': roomId,
      'status': status,
      'status_manual': manualStatus,
      'cancel_reason': cancelReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// Result of validating a paper before saving.
class PaperCheckResult {
  final List<String> errors;
  final List<String> warnings;
  const PaperCheckResult({this.errors = const [], this.warnings = const []});
  bool get hasErrors => errors.isNotEmpty;
}
