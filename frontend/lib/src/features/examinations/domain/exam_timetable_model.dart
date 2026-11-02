/// Model representing an Exam Timetable entry (formerly ExamPaper).
/// Stores timetable data in the unified examination store while
/// keeping backwards compatibility with legacy `exam_papers` records.
class ExamTimetableEntry {
  final String id;
  final String examScheduleId;
  final String? classId;
  final String? classSectionId;
  final String? subjectId;
  final String? examDate; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final double maxMarks;
  final double passingMarks;
  final String? invigilatorId;
  final String? roomId;
  final String? status; // SCHEDULED | COMPLETED | CANCELLED
  final String createdAt;
  final String updatedAt;

  const ExamTimetableEntry({
    required this.id,
    required this.examScheduleId,
    this.classId,
    this.classSectionId,
    this.subjectId,
    this.examDate,
    this.startTime = '09:00',
    this.endTime = '12:00',
    this.maxMarks = 100.0,
    this.passingMarks = 35.0,
    this.invigilatorId,
    this.roomId,
    this.status = 'SCHEDULED',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isCancelled => (status ?? '').toUpperCase() == 'CANCELLED';
  bool get isCompleted => (status ?? '').toUpperCase() == 'COMPLETED';
  bool get isScheduled => !isCancelled && !isCompleted;

  /// Duration in minutes auto-calculated from startTime and endTime.
  int get durationMinutes {
    try {
      final s = startTime.split(':').map(int.parse).toList();
      final e = endTime.split(':').map(int.parse).toList();
      final sm = s[0] * 60 + s[1];
      final em = e[0] * 60 + e[1];
      return em > sm ? em - sm : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Formatted duration string, e.g. "3h 00m" or "2h 30m".
  String get formattedDuration {
    final dm = durationMinutes;
    if (dm <= 0) return '0 min';
    final hrs = dm ~/ 60;
    final mins = dm % 60;
    if (hrs == 0) return '${mins}m';
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins.toString().padLeft(2, '0')}m';
  }

  static String _hhmm(dynamic v, String fallback) {
    final s = (v ?? '').toString();
    if (s.length >= 5) return s.substring(0, 5);
    return fallback;
  }

  factory ExamTimetableEntry.fromJson(Map<String, dynamic> json) {
    return ExamTimetableEntry(
      id: (json['id'] ?? json['exam_paper_id'] ?? json['timetable_id'] ?? json['paper_id'] ?? '').toString(),
      examScheduleId: (json['exam_schedule_id'] ?? '').toString(),
      classId: json['class_id']?.toString(),
      classSectionId: (json['class_section_id'] ?? json['section_id'])?.toString(),
      subjectId: json['subject_id']?.toString(),
      examDate: (json['exam_date'] ?? json['paper_date'])?.toString(),
      startTime: _hhmm(json['start_time'], '09:00'),
      endTime: _hhmm(json['end_time'], '12:00'),
      maxMarks: (json['max_marks'] as num?)?.toDouble() ?? 100.0,
      passingMarks: (json['passing_marks'] as num?)?.toDouble() ?? 35.0,
      invigilatorId: json['invigilator_id']?.toString(),
      roomId: json['room_id']?.toString(),
      status: (json['status'] ?? 'SCHEDULED').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        if (classId != null && classId!.isNotEmpty) 'class_id': classId,
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
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ExamTimetableEntry copyWith({
    String? examScheduleId,
    String? classId,
    String? classSectionId,
    String? subjectId,
    String? examDate,
    String? startTime,
    String? endTime,
    double? maxMarks,
    double? passingMarks,
    String? invigilatorId,
    String? roomId,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExamTimetableEntry(
      id: id,
      examScheduleId: examScheduleId ?? this.examScheduleId,
      classId: classId ?? this.classId,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxMarks: maxMarks ?? this.maxMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      invigilatorId: invigilatorId ?? this.invigilatorId,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Backwards-compatibility alias
typedef ExamPaper = ExamTimetableEntry;

