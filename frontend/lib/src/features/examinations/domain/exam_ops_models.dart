class StudentRef {
  final String id;
  final String name;
  final String rollNumber;
  final String admissionNumber;
  final String classSectionId;
  const StudentRef(this.id, this.name, this.rollNumber, this.admissionNumber,
      this.classSectionId);
}

class HallTicket {
  final String id, examScheduleId, studentId, ticketNumber, token, issueDate, status;
  const HallTicket({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.ticketNumber,
    required this.token,
    required this.issueDate,
    this.status = 'ISSUED',
  });
  factory HallTicket.fromJson(Map<String, dynamic> j) => HallTicket(
        id: j['id'].toString(),
        examScheduleId: j['exam_schedule_id'].toString(),
        studentId: j['student_id'].toString(),
        ticketNumber: j['hall_ticket_number'].toString(),
        token: (j['barcode_or_qr_token'] ?? '').toString(),
        issueDate: (j['issue_date'] ?? '').toString(),
        status: (j['status'] ?? 'ISSUED').toString(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'hall_ticket_number': ticketNumber,
        'barcode_or_qr_token': token,
        'issue_date': issueDate,
        'status': status,
      };
}

/// status: PRESENT | ABSENT | MALPRACTICE
class ExamAttendance {
  final String examPaperId, studentId, status, remarks;
  const ExamAttendance(this.examPaperId, this.studentId, this.status, [this.remarks = '']);
  factory ExamAttendance.fromJson(Map<String, dynamic> j) => ExamAttendance(
        j['exam_paper_id'].toString(),
        j['student_id'].toString(),
        (j['status'] ?? 'PRESENT').toString(),
        (j['remarks'] ?? '').toString(),
      );
  Map<String, dynamic> toJson() => {
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'status': status,
        'remarks': remarks,
        'marked_at': DateTime.now().toIso8601String(),
      };
}

/// status: DRAFT | SUBMITTED | CORRECTION_REQUESTED | REVIEWED
class StudentMark {
  final String examPaperId, studentId, status, remarks;
  final double? marks;
  const StudentMark(this.examPaperId, this.studentId, this.marks, this.status,
      [this.remarks = '']);
  factory StudentMark.fromJson(Map<String, dynamic> j) => StudentMark(
        j['exam_paper_id'].toString(),
        j['student_id'].toString(),
        (j['marks_obtained'] as num?)?.toDouble(),
        (j['status'] ?? 'DRAFT').toString(),
        (j['remarks'] ?? '').toString(),
      );
  Map<String, dynamic> toJson() => {
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'marks_obtained': marks,
        'status': status,
        'remarks': remarks,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
