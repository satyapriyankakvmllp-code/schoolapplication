// Records created while an exam is being conducted and graded:
// hall tickets, attendance, marks, remarks and report cards.

double _num(dynamic v, [double fallback = 0]) =>
    (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? fallback);

String _str(dynamic v, [String fallback = '']) {
  final s = v?.toString();
  return (s == null || s == 'null') ? fallback : s;
}

// ---------------------------------------------------------------------------
// HALL TICKET
// ---------------------------------------------------------------------------
class HallTicket {
  final String id;
  final String examScheduleId;
  final String studentId;
  final String hallTicketNumber;
  final String qrToken;
  final String issueDate; // yyyy-MM-dd
  final String status; // ISSUED | REVOKED
  final String createdAt;
  final String updatedAt;

  const HallTicket({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.hallTicketNumber,
    required this.qrToken,
    required this.issueDate,
    this.status = 'ISSUED',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isIssued => status == 'ISSUED';

  factory HallTicket.fromJson(Map<String, dynamic> j) => HallTicket(
        id: _str(j['hall_ticket_id'] ?? j['id']),
        examScheduleId: _str(j['exam_schedule_id']),
        studentId: _str(j['student_id']),
        hallTicketNumber: _str(j['hall_ticket_number']),
        qrToken: _str(j['barcode_or_qr_token']),
        issueDate: _str(j['issue_date']),
        status: _str(j['status'], 'ISSUED').toUpperCase(),
        createdAt: _str(j['created_at']),
        updatedAt: _str(j['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'hall_ticket_id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'hall_ticket_number': hallTicketNumber,
        'barcode_or_qr_token': qrToken,
        'issue_date': issueDate,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  HallTicket copyWith({String? status, String? updatedAt}) => HallTicket(
        id: id,
        examScheduleId: examScheduleId,
        studentId: studentId,
        hallTicketNumber: hallTicketNumber,
        qrToken: qrToken,
        issueDate: issueDate,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// EXAM-DAY ATTENDANCE (the only place where absence is stored)
// ---------------------------------------------------------------------------
class ExamAttendance {
  final String id;
  final String examPaperId;
  final String studentId;
  final String status; // PRESENT | ABSENT
  final String markedBy;
  final String markedAt;
  final String remarks;

  const ExamAttendance({
    required this.id,
    required this.examPaperId,
    required this.studentId,
    required this.status,
    this.markedBy = '',
    this.markedAt = '',
    this.remarks = '',
  });

  bool get isAbsent => status == 'ABSENT';

  factory ExamAttendance.fromJson(Map<String, dynamic> j) => ExamAttendance(
        id: _str(j['attendance_id'] ?? j['id']),
        examPaperId: _str(j['exam_paper_id'] ?? j['paper_id']),
        studentId: _str(j['student_id']),
        status: _str(j['status'], 'PRESENT').toUpperCase(),
        markedBy: _str(j['marked_by_teacher_id']),
        markedAt: _str(j['marked_at']),
        remarks: _str(j['remarks']),
      );

  Map<String, dynamic> toJson() => {
        'attendance_id': id,
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'status': status,
        'marked_by_teacher_id': markedBy,
        'marked_at': markedAt,
        'remarks': remarks,
      };
}

// ---------------------------------------------------------------------------
// MARKS
// ---------------------------------------------------------------------------
class ExamMark {
  final String id;
  final String examPaperId;
  final String studentId;
  final double? marksObtained;
  final String status; // DRAFT | SUBMITTED | CORRECTION_REQUIRED | REVIEWED
  final String enteredBy;
  final String submittedAt;
  final String reviewedBy;
  final String reviewedAt;
  final String remarks;
  final String correctionComment;
  final String createdAt;
  final String updatedAt;

  const ExamMark({
    required this.id,
    required this.examPaperId,
    required this.studentId,
    this.marksObtained,
    this.status = 'DRAFT',
    this.enteredBy = '',
    this.submittedAt = '',
    this.reviewedBy = '',
    this.reviewedAt = '',
    this.remarks = '',
    this.correctionComment = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ExamMark.fromJson(Map<String, dynamic> j) => ExamMark(
        id: _str(j['mark_id'] ?? j['id']),
        examPaperId: _str(j['exam_paper_id'] ?? j['paper_id']),
        studentId: _str(j['student_id']),
        marksObtained: j['marks_obtained'] == null ? null : _num(j['marks_obtained']),
        status: _str(j['status'], 'REVIEWED').toUpperCase(),
        enteredBy: _str(j['entered_by_teacher_id']),
        submittedAt: _str(j['submitted_at']),
        reviewedBy: _str(j['reviewed_by']),
        reviewedAt: _str(j['reviewed_at']),
        remarks: _str(j['remarks']),
        correctionComment: _str(j['correction_comment']),
        createdAt: _str(j['created_at']),
        updatedAt: _str(j['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'mark_id': id,
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'marks_obtained': marksObtained,
        'status': status,
        'entered_by_teacher_id': enteredBy,
        'submitted_at': submittedAt,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt,
        'remarks': remarks,
        'correction_comment': correctionComment,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

/// One line typed in the marks-entry table.
class MarkInput {
  final String studentId;
  final double? marks;
  final String remarks;
  const MarkInput({required this.studentId, this.marks, this.remarks = ''});
}

/// Aggregate marks state of one paper.
class PaperMarksSummary {
  final String paperId;
  final int expected; // students who should have marks (not absent)
  final int absent;
  final int entered;
  final String status; // NOT_STARTED | DRAFT | SUBMITTED | CORRECTION_REQUIRED | REVIEWED
  const PaperMarksSummary({
    required this.paperId,
    required this.expected,
    required this.absent,
    required this.entered,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// CLASS IN-CHARGE REMARKS (copied into the report card on calculation)
// ---------------------------------------------------------------------------
class StudentRemarks {
  final String id;
  final String examScheduleId;
  final String studentId;
  final String classSectionId;
  final String academic;
  final String conduct;
  final String participation;
  final String improvement;
  final String remarks;
  final String updatedAt;

  const StudentRemarks({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.classSectionId,
    this.academic = '',
    this.conduct = '',
    this.participation = '',
    this.improvement = '',
    this.remarks = '',
    this.updatedAt = '',
  });

  /// Text stored on the report card.
  String get combined {
    final parts = <String>[];
    if (remarks.trim().isNotEmpty) parts.add(remarks.trim());
    if (academic.isNotEmpty) parts.add('Academic: $academic');
    if (conduct.isNotEmpty) parts.add('Conduct: $conduct');
    if (participation.isNotEmpty) parts.add('Participation: $participation');
    if (improvement.trim().isNotEmpty) parts.add('Improvement: ${improvement.trim()}');
    return parts.join(' | ');
  }

  factory StudentRemarks.fromJson(Map<String, dynamic> j) => StudentRemarks(
        id: _str(j['id']),
        examScheduleId: _str(j['exam_schedule_id']),
        studentId: _str(j['student_id']),
        classSectionId: _str(j['class_section_id']),
        academic: _str(j['academic_performance']),
        conduct: _str(j['conduct']),
        participation: _str(j['participation']),
        improvement: _str(j['improvement']),
        remarks: _str(j['remarks']),
        updatedAt: _str(j['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'class_section_id': classSectionId,
        'academic_performance': academic,
        'conduct': conduct,
        'participation': participation,
        'improvement': improvement,
        'remarks': remarks,
        'updated_at': updatedAt,
      };
}

// ---------------------------------------------------------------------------
// GRADING
// ---------------------------------------------------------------------------
class GradeBand {
  final double minPercent;
  final double maxPercent;
  final String grade;
  final double gpaPoint;
  const GradeBand({
    required this.minPercent,
    required this.maxPercent,
    required this.grade,
    required this.gpaPoint,
  });

  factory GradeBand.fromJson(Map<String, dynamic> j) => GradeBand(
        minPercent: _num(j['min_percent']),
        maxPercent: _num(j['max_percent'], 100),
        grade: _str(j['grade']),
        gpaPoint: _num(j['gpa_point']),
      );

  Map<String, dynamic> toJson() => {
        'min_percent': minPercent,
        'max_percent': maxPercent,
        'grade': grade,
        'gpa_point': gpaPoint,
      };

  static const List<GradeBand> defaults = [
    GradeBand(minPercent: 90, maxPercent: 100, grade: 'A+', gpaPoint: 10),
    GradeBand(minPercent: 80, maxPercent: 89.99, grade: 'A', gpaPoint: 9),
    GradeBand(minPercent: 70, maxPercent: 79.99, grade: 'B+', gpaPoint: 8),
    GradeBand(minPercent: 60, maxPercent: 69.99, grade: 'B', gpaPoint: 7),
    GradeBand(minPercent: 50, maxPercent: 59.99, grade: 'C', gpaPoint: 6),
    GradeBand(minPercent: 35, maxPercent: 49.99, grade: 'D', gpaPoint: 5),
    GradeBand(minPercent: 0, maxPercent: 34.99, grade: 'F', gpaPoint: 0),
  ];
}

// ---------------------------------------------------------------------------
// REPORT CARD
// ---------------------------------------------------------------------------
class SubjectResult {
  final String paperId;
  final String subjectId;
  final String subjectName;
  final double marks;
  final double maxMarks;
  final double passingMarks;
  final bool absent;

  const SubjectResult({
    required this.paperId,
    required this.subjectId,
    required this.subjectName,
    required this.marks,
    required this.maxMarks,
    required this.passingMarks,
    this.absent = false,
  });

  bool get failed => absent || marks < passingMarks;

  factory SubjectResult.fromJson(Map<String, dynamic> j) => SubjectResult(
        paperId: _str(j['paper_id']),
        subjectId: _str(j['subject_id']),
        subjectName: _str(j['subject_name']),
        marks: _num(j['marks']),
        maxMarks: _num(j['max_marks'], 100),
        passingMarks: _num(j['passing_marks'], 35),
        absent: j['absent'] == true,
      );

  Map<String, dynamic> toJson() => {
        'paper_id': paperId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'marks': marks,
        'max_marks': maxMarks,
        'passing_marks': passingMarks,
        'absent': absent,
      };
}

class ReportCard {
  final String id;
  final String examScheduleId;
  final String studentId;
  final String classSectionId;
  final double totalMarks;
  final double totalMaxMarks;
  final double percentage;
  final String grade;
  final double gpa;
  final int classRank;
  final List<SubjectResult> subjects;
  final String remarks;
  final String status; // PENDING_APPROVAL | APPROVED | SENT_BACK | PUBLISHED
  final String generatedAt;
  final String approvedById;
  final String approvedAt;
  final bool isPublished;
  final String publishedAt;
  final String sendBackReason;
  final bool stale; // marks changed after calculation
  final String updatedAt;

  const ReportCard({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.classSectionId,
    required this.totalMarks,
    required this.totalMaxMarks,
    required this.percentage,
    required this.grade,
    required this.gpa,
    required this.classRank,
    required this.subjects,
    this.remarks = '',
    this.status = 'PENDING_APPROVAL',
    this.generatedAt = '',
    this.approvedById = '',
    this.approvedAt = '',
    this.isPublished = false,
    this.publishedAt = '',
    this.sendBackReason = '',
    this.stale = false,
    this.updatedAt = '',
  });

  bool get isApproved => status == 'APPROVED' || status == 'PUBLISHED';
  int get failedSubjects => subjects.where((s) => s.failed).length;
  bool get passed => failedSubjects == 0;

  factory ReportCard.fromJson(Map<String, dynamic> j) => ReportCard(
        id: _str(j['report_card_id'] ?? j['id']),
        examScheduleId: _str(j['exam_schedule_id']),
        studentId: _str(j['student_id']),
        classSectionId: _str(j['class_section_id']),
        totalMarks: _num(j['total_marks'] ?? j['total_marks_obtained']),
        totalMaxMarks: _num(j['total_max_marks']),
        percentage: _num(j['percentage']),
        grade: _str(j['grade']),
        gpa: _num(j['gpa']),
        classRank: (j['class_rank'] as num?)?.toInt() ?? 0,
        subjects: (j['subject_results'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => SubjectResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        remarks: _str(j['class_incharge_remarks']),
        status: _str(j['status'], 'PENDING_APPROVAL').toUpperCase(),
        generatedAt: _str(j['generated_at']),
        approvedById: _str(j['approved_by_id']),
        approvedAt: _str(j['approved_at']),
        isPublished: j['is_published'] == true,
        publishedAt: _str(j['published_at']),
        sendBackReason: _str(j['send_back_reason']),
        stale: j['stale'] == true,
        updatedAt: _str(j['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'report_card_id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'class_section_id': classSectionId,
        'total_marks': totalMarks,
        'total_max_marks': totalMaxMarks,
        'percentage': percentage,
        'grade': grade,
        'gpa': gpa,
        'class_rank': classRank,
        'subject_results': subjects.map((s) => s.toJson()).toList(),
        'class_incharge_remarks': remarks,
        'status': status,
        'generated_at': generatedAt,
        'approved_by_id': approvedById,
        'approved_at': approvedAt,
        'is_published': isPublished,
        'published_at': publishedAt,
        'send_back_reason': sendBackReason,
        'stale': stale,
        'updated_at': updatedAt,
      };
}

/// Summary of what happened when results were calculated.
class ResultCalcSummary {
  final int studentsProcessed;
  final int passed;
  final int failed;
  const ResultCalcSummary({
    required this.studentsProcessed,
    required this.passed,
    required this.failed,
  });
}

/// Result of checking whether results can be calculated.
class ResultReadiness {
  final bool ready;
  final List<String> pending;
  const ResultReadiness({required this.ready, this.pending = const []});
}
