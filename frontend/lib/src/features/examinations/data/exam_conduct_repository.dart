import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_records_model.dart';
import '../domain/examination_actor.dart';
import 'exam_repository.dart';
import 'examination_store.dart';

class HallGenerationResult {
  final int created;
  final int alreadyIssued;
  const HallGenerationResult({required this.created, required this.alreadyIssued});
}

/// Screens 3 to 6: hall tickets, exam-day attendance, marks entry, marks
/// review and class in-charge remarks.
class ExamConductRepository {
  final ExaminationStore _store;
  ExamConductRepository(this._store);

  // -------------------------------------------------------------------------
  // HALL TICKETS
  // -------------------------------------------------------------------------
  static const Map<String, String> _typeCodes = {
    'UNIT_TEST': 'UT',
    'PERIODIC_TEST': 'PT',
    'MID_TERM': 'MID',
    'HALF_YEARLY': 'HY',
    'PRE_FINAL': 'PF',
    'ANNUAL': 'AN',
    'PRACTICAL': 'PR',
    'INTERNAL_ASSESSMENT': 'IA',
  };

  String _examCode(Map<String, dynamic> exam) {
    final type = (exam['exam_type'] ?? '').toString().toUpperCase();
    final start = (exam['start_date'] ?? '').toString();
    final yy = start.length >= 4 ? start.substring(2, 4) : '';
    return '${_typeCodes[type] ?? 'EX'}$yy';
  }

  Future<List<HallTicket>> getHallTickets({String? examId, String? studentId}) async {
    final data = await _store.load();
    final list = _store
        .listOf(data, 'hall_tickets')
        .map(HallTicket.fromJson)
        .where((t) => examId == null || t.examScheduleId == examId)
        .where((t) => studentId == null || t.studentId == studentId)
        .toList();
    list.sort((a, b) => a.hallTicketNumber.compareTo(b.hallTicketNumber));
    return list;
  }

  void _requireTickets(ExaminationActor actor) {
    if (!actor.permissions.canManageHallTickets) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can manage hall tickets.',
      );
    }
  }

  /// Creates one hall ticket per enrolled student. Safe to run again: students
  /// who already have a ticket are skipped (no duplicates).
  Future<HallGenerationResult> generateHallTickets({
    required String examId,
    required String sectionId,
    required ExamMasterData master,
    required ExaminationActor actor,
  }) async {
    _requireTickets(actor);
    final data = await _store.load();
    final exam = _store
        .listOf(data, 'exam_schedules')
        .where((e) => (e['exam_schedule_id'] ?? e['id']).toString() == examId)
        .firstOrNull;
    if (exam == null) throw const ExamValidationException('Exam not found.');

    final papers = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) =>
            p.examScheduleId == examId && p.classSectionId == sectionId && !p.isCancelled);
    if (papers.isEmpty) {
      throw const ExamValidationException(
        'Add exam papers for this class-section first. Hall tickets show the timetable.',
      );
    }
    final students = master.studentsForSection(sectionId);
    if (students.isEmpty) {
      throw const ExamValidationException('No enrolled students found in this class-section.');
    }

    final tickets = _store.listOf(data, 'hall_tickets');
    final used = tickets
        .where((t) => (t['exam_schedule_id'] ?? '').toString() == examId)
        .map((t) => (t['hall_ticket_number'] ?? '').toString())
        .toSet();

    var created = 0;
    var existing = 0;
    final now = _store.nowIso();
    final code = _examCode(exam);
    final sec = master.sectionCode(sectionId);

    for (final st in students) {
      final has = tickets.any((t) =>
          (t['exam_schedule_id'] ?? '').toString() == examId &&
          (t['student_id'] ?? '').toString() == st.id);
      if (has) {
        existing++;
        continue;
      }
      final roll = st.rollNumber.isEmpty ? '000' : st.rollNumber.padLeft(3, '0');
      var number = '$code-$sec-$roll';
      var n = 2;
      while (used.contains(number)) {
        number = '$code-$sec-$roll-$n';
        n++;
      }
      used.add(number);
      final ticket = HallTicket(
        id: _store.newId('hall'),
        examScheduleId: examId,
        studentId: st.id,
        hallTicketNumber: number,
        qrToken: 'QR-${_store.newId('t').substring(2).toUpperCase()}',
        issueDate: _store.todayStr(),
        createdAt: now,
        updatedAt: now,
      );
      tickets.add(ticket.toJson());
      created++;
    }
    _store.setList(data, 'hall_tickets', tickets);
    await _store.save(data);
    return HallGenerationResult(created: created, alreadyIssued: existing);
  }

  Future<void> setHallTicketStatus(
    String ticketId,
    String status, {
    required ExaminationActor actor,
  }) async {
    _requireTickets(actor);
    final data = await _store.load();
    final list = _store.listOf(data, 'hall_tickets');
    final i = list.indexWhere((t) => (t['hall_ticket_id'] ?? t['id']).toString() == ticketId);
    if (i < 0) throw const ExamValidationException('Hall ticket not found.');
    list[i] = HallTicket.fromJson(list[i])
        .copyWith(status: status, updatedAt: _store.nowIso())
        .toJson();
    _store.setList(data, 'hall_tickets', list);
    await _store.save(data);
  }

  Future<void> deleteHallTicket(String ticketId, {required ExaminationActor actor}) async {
    _requireTickets(actor);
    final data = await _store.load();
    final list = _store.listOf(data, 'hall_tickets')
      ..removeWhere((t) => (t['hall_ticket_id'] ?? t['id']).toString() == ticketId);
    _store.setList(data, 'hall_tickets', list);
    await _store.save(data);
  }

  // -------------------------------------------------------------------------
  // ATTENDANCE (exam day)
  // -------------------------------------------------------------------------
  Future<List<ExamAttendance>> getAttendance({String? paperId, String? examId}) async {
    final data = await _store.load();
    Set<String>? paperIds;
    if (examId != null) {
      paperIds = _store
          .listOf(data, 'exam_papers')
          .where((p) => (p['exam_schedule_id'] ?? '').toString() == examId)
          .map((p) => (p['id'] ?? p['paper_id']).toString())
          .toSet();
    }
    return _store
        .listOf(data, 'exam_attendance')
        .map(ExamAttendance.fromJson)
        .where((a) => paperId == null || a.examPaperId == paperId)
        .where((a) => paperIds == null || paperIds.contains(a.examPaperId))
        .toList();
  }

  /// Saves Present / Absent for every student of a paper. An ABSENT student
  /// has no marks, so any marks row of that student is removed.
  Future<void> saveAttendance({
    required String paperId,
    required Map<String, String> statusByStudent,
    Map<String, String> remarksByStudent = const {},
    required ExaminationActor actor,
  }) async {
    if (!actor.permissions.canMarkAttendance) {
      throw const ExamPermissionException(
        'Permission denied: Only invigilators and Admin can mark exam attendance.',
      );
    }
    final data = await _store.load();
    final paper = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) => p.id == paperId)
        .firstOrNull;
    if (paper == null) throw const ExamValidationException('Paper not found.');
    if (paper.isCancelled) {
      throw const ExamValidationException('This paper is cancelled.');
    }
    if (actor.permissions.isTeacher &&
        paper.invigilatorId != null &&
        paper.invigilatorId != actor.teacherId) {
      throw const ExamPermissionException(
        'Only the invigilator of this paper (or Admin) can mark attendance.',
      );
    }

    final list = _store.listOf(data, 'exam_attendance');
    final now = _store.nowIso();
    final absentIds = <String>{};
    statusByStudent.forEach((studentId, status) {
      final st = status.toUpperCase() == 'ABSENT' ? 'ABSENT' : 'PRESENT';
      if (st == 'ABSENT') absentIds.add(studentId);
      final rec = ExamAttendance(
        id: '',
        examPaperId: paperId,
        studentId: studentId,
        status: st,
        markedBy: actor.userId,
        markedAt: now,
        remarks: remarksByStudent[studentId] ?? '',
      ).toJson();
      final i = list.indexWhere((a) =>
          (a['exam_paper_id'] ?? a['paper_id']).toString() == paperId &&
          (a['student_id'] ?? '').toString() == studentId);
      if (i >= 0) {
        rec['attendance_id'] = list[i]['attendance_id'] ?? list[i]['id'] ?? _store.newId('att');
        list[i] = rec;
      } else {
        rec['attendance_id'] = _store.newId('att');
        list.add(rec);
      }
    });
    _store.setList(data, 'exam_attendance', list);

    if (absentIds.isNotEmpty) {
      final marks = _store.listOf(data, 'student_exam_marks')
        ..removeWhere((m) =>
            (m['exam_paper_id'] ?? m['paper_id']).toString() == paperId &&
            absentIds.contains((m['student_id'] ?? '').toString()));
      _store.setList(data, 'student_exam_marks', marks);
    }
    await _store.save(data);
  }

  // -------------------------------------------------------------------------
  // MARKS
  // -------------------------------------------------------------------------
  Future<List<ExamMark>> getMarks({String? paperId, String? examId}) async {
    final data = await _store.load();
    Set<String>? paperIds;
    if (examId != null) {
      paperIds = _store
          .listOf(data, 'exam_papers')
          .where((p) => (p['exam_schedule_id'] ?? '').toString() == examId)
          .map((p) => (p['id'] ?? p['paper_id']).toString())
          .toSet();
    }
    return _store
        .listOf(data, 'student_exam_marks')
        .map(ExamMark.fromJson)
        .where((m) => paperId == null || m.examPaperId == paperId)
        .where((m) => paperIds == null || paperIds.contains(m.examPaperId))
        .toList();
  }

  /// Marks state of one paper: who should get marks, how many are entered and
  /// the overall status.
  PaperMarksSummary summarize({
    required ExamPaper paper,
    required List<ExamStudentInfo> students,
    required List<ExamMark> marks,
    required List<ExamAttendance> attendance,
  }) {
    final absent = attendance
        .where((a) => a.examPaperId == paper.id && a.isAbsent)
        .map((a) => a.studentId)
        .toSet();
    final expectedStudents = students.where((s) => !absent.contains(s.id)).toList();
    final rows = marks
        .where((m) =>
            m.examPaperId == paper.id && expectedStudents.any((s) => s.id == m.studentId))
        .toList();
    final entered = rows.where((m) => m.marksObtained != null).length;

    String status;
    if (rows.isEmpty) {
      status = 'NOT_STARTED';
    } else if (rows.any((m) => m.status == 'CORRECTION_REQUIRED')) {
      status = 'CORRECTION_REQUIRED';
    } else if (rows.any((m) => m.status == 'DRAFT') || entered < expectedStudents.length) {
      status = 'DRAFT';
    } else if (rows.every((m) => m.status == 'REVIEWED')) {
      status = 'REVIEWED';
    } else {
      status = 'SUBMITTED';
    }
    return PaperMarksSummary(
      paperId: paper.id,
      expected: expectedStudents.length,
      absent: absent.length,
      entered: entered,
      status: status,
    );
  }

  bool _teacherOwnsPaper(ExamPaper paper, ExamMasterData master, ExaminationActor actor) {
    final subject = master.subjectById(paper.subjectId);
    return actor.teacherId != null &&
        (subject?.teacherId == actor.teacherId || paper.invigilatorId == actor.teacherId);
  }

  Future<void> saveMarks({
    required ExamPaper paper,
    required List<MarkInput> inputs,
    required bool submit,
    required ExaminationActor actor,
    required ExamMasterData master,
  }) async {
    if (!actor.permissions.canEnterMarks) {
      throw const ExamPermissionException(
        'Permission denied: Only the subject teacher or Admin can enter marks.',
      );
    }
    if (paper.isCancelled) {
      throw const ExamValidationException('This paper is cancelled.');
    }
    final isAdmin = actor.permissions.isAdminOrPrincipal;
    if (!isAdmin && !_teacherOwnsPaper(paper, master, actor)) {
      throw const ExamPermissionException(
        'You can only enter marks for papers of your own subject.',
      );
    }

    final data = await _store.load();
    final marks = _store.listOf(data, 'student_exam_marks');
    final attendance = _store
        .listOf(data, 'exam_attendance')
        .map(ExamAttendance.fromJson)
        .where((a) => a.examPaperId == paper.id && a.isAbsent)
        .map((a) => a.studentId)
        .toSet();

    // Teachers cannot change marks once they are submitted.
    if (!isAdmin) {
      final locked = marks.any((m) =>
          (m['exam_paper_id'] ?? m['paper_id']).toString() == paper.id &&
          ['SUBMITTED', 'REVIEWED'].contains((m['status'] ?? '').toString().toUpperCase()));
      if (locked) {
        throw const ExamValidationException(
          'Marks are already submitted. Ask the Class In-charge to send them back for correction.',
        );
      }
    }

    final rowsToSave = inputs.where((i) => !attendance.contains(i.studentId)).toList();
    for (final r in rowsToSave) {
      final v = r.marks;
      if (v != null) {
        if (v < 0 || v > paper.maxMarks) {
          throw ExamValidationException(
            '${master.studentName(r.studentId)}: marks must be between 0 and '
            '${paper.maxMarks.toStringAsFixed(paper.maxMarks % 1 == 0 ? 0 : 1)}.',
          );
        }
      }
    }
    if (submit) {
      // Every student who sat the paper must have marks, whether they are in
      // this request or were saved earlier.
      var missing = 0;
      for (final s in master.studentsForSection(paper.classSectionId)) {
        if (attendance.contains(s.id)) continue;
        final typed = rowsToSave.where((r) => r.studentId == s.id).firstOrNull;
        dynamic value;
        if (typed != null) {
          value = typed.marks;
        } else {
          value = marks
              .where((m) =>
                  (m['exam_paper_id'] ?? m['paper_id']).toString() == paper.id &&
                  (m['student_id'] ?? '').toString() == s.id)
              .firstOrNull?['marks_obtained'];
        }
        if (value == null) missing++;
      }
      if (missing > 0) {
        throw ExamValidationException(
          'Marks are missing for $missing student${missing == 1 ? '' : 's'}. Enter marks for everyone before submitting.',
        );
      }
    }

    final now = _store.nowIso();
    var changed = false;
    for (final r in rowsToSave) {
      final i = marks.indexWhere((m) =>
          (m['exam_paper_id'] ?? m['paper_id']).toString() == paper.id &&
          (m['student_id'] ?? '').toString() == r.studentId);
      if (i >= 0) {
        final old = ExamMark.fromJson(marks[i]);
        if (old.marksObtained != r.marks) changed = true;
        final keep = ['SUBMITTED', 'REVIEWED', 'CORRECTION_REQUIRED'].contains(old.status);
        marks[i] = ExamMark(
          id: old.id,
          examPaperId: paper.id,
          studentId: r.studentId,
          marksObtained: r.marks,
          status: submit ? 'SUBMITTED' : (keep ? old.status : 'DRAFT'),
          enteredBy: actor.userId,
          submittedAt: submit ? now : old.submittedAt,
          reviewedBy: submit ? '' : old.reviewedBy,
          reviewedAt: submit ? '' : old.reviewedAt,
          remarks: r.remarks,
          correctionComment: submit ? '' : old.correctionComment,
          createdAt: old.createdAt,
          updatedAt: now,
        ).toJson();
      } else {
        if (r.marks != null) changed = true;
        marks.add(ExamMark(
          id: _store.newId('mark'),
          examPaperId: paper.id,
          studentId: r.studentId,
          marksObtained: r.marks,
          status: submit ? 'SUBMITTED' : 'DRAFT',
          enteredBy: actor.userId,
          submittedAt: submit ? now : '',
          remarks: r.remarks,
          createdAt: now,
          updatedAt: now,
        ).toJson());
      }
    }
    _store.setList(data, 'student_exam_marks', marks);

    // Report cards of this class were calculated from older marks.
    if (changed) {
      final cards = _store.listOf(data, 'report_cards');
      var touched = false;
      for (final c in cards) {
        if ((c['exam_schedule_id'] ?? '').toString() == paper.examScheduleId &&
            (c['class_section_id'] ?? '').toString() == paper.classSectionId) {
          c['stale'] = true;
          touched = true;
        }
      }
      if (touched) _store.setList(data, 'report_cards', cards);
    }
    await _store.save(data);
  }

  void _requireReviewer(ExaminationActor actor, ExamPaper paper) {
    if (!actor.permissions.canReviewMarks) {
      throw const ExamPermissionException(
        'Permission denied: Only the Class In-charge or Admin can review marks.',
      );
    }
    if (actor.permissions.isClassIncharge && actor.sectionId != paper.classSectionId) {
      throw const ExamPermissionException(
        'You can only review marks of your own class-section.',
      );
    }
  }

  Future<ExamPaper> _paper(Map<String, dynamic> data, String paperId) async {
    final paper = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) => p.id == paperId)
        .firstOrNull;
    if (paper == null) throw const ExamValidationException('Paper not found.');
    return paper;
  }

  /// Class in-charge sends one subject back to the teacher.
  Future<void> flagCorrection({
    required String paperId,
    required String comment,
    required ExaminationActor actor,
  }) async {
    if (comment.trim().isEmpty) {
      throw const ExamValidationException('Please write what needs to be corrected.');
    }
    final data = await _store.load();
    final paper = await _paper(data, paperId);
    _requireReviewer(actor, paper);
    final marks = _store.listOf(data, 'student_exam_marks');
    var any = false;
    final now = _store.nowIso();
    for (final m in marks) {
      if ((m['exam_paper_id'] ?? m['paper_id']).toString() == paperId) {
        m['status'] = 'CORRECTION_REQUIRED';
        m['correction_comment'] = comment.trim();
        m['updated_at'] = now;
        any = true;
      }
    }
    if (!any) throw const ExamValidationException('No marks have been entered for this subject yet.');
    _store.setList(data, 'student_exam_marks', marks);
    await _store.save(data);
  }

  /// Approves all subjects of a class-section for the admin. Returns the
  /// number of subjects approved. Subjects that are not submitted yet are
  /// reported in the error message.
  Future<int> approveSection({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
    required ExamMasterData master,
  }) async {
    if (!actor.permissions.canReviewMarks) {
      throw const ExamPermissionException(
        'Permission denied: Only the Class In-charge or Admin can approve marks.',
      );
    }
    if (actor.permissions.isClassIncharge && actor.sectionId != sectionId) {
      throw const ExamPermissionException(
        'You can only approve marks of your own class-section.',
      );
    }
    final data = await _store.load();
    final papers = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) =>
            p.examScheduleId == examId && p.classSectionId == sectionId && !p.isCancelled)
        .toList();
    if (papers.isEmpty) throw const ExamValidationException('No papers in this class-section.');

    final students = master.studentsForSection(sectionId);
    final marks = _store.listOf(data, 'student_exam_marks').map(ExamMark.fromJson).toList();
    final att = _store.listOf(data, 'exam_attendance').map(ExamAttendance.fromJson).toList();

    final pending = <String>[];
    for (final p in papers) {
      final s = summarize(paper: p, students: students, marks: marks, attendance: att);
      if (s.status != 'SUBMITTED' && s.status != 'REVIEWED') {
        pending.add('${master.subjectName(p.subjectId)} (${s.status.replaceAll('_', ' ').toLowerCase()})');
      }
    }
    if (pending.isNotEmpty) {
      throw ExamValidationException('Not ready: ${pending.join(', ')}.');
    }

    final rows = _store.listOf(data, 'student_exam_marks');
    final now = _store.nowIso();
    final paperIds = papers.map((p) => p.id).toSet();
    for (final m in rows) {
      if (paperIds.contains((m['exam_paper_id'] ?? m['paper_id']).toString())) {
        m['status'] = 'REVIEWED';
        m['reviewed_by'] = actor.userId;
        m['reviewed_at'] = now;
        m['correction_comment'] = '';
      }
    }
    _store.setList(data, 'student_exam_marks', rows);
    await _store.save(data);
    return papers.length;
  }

  // -------------------------------------------------------------------------
  // CLASS IN-CHARGE REMARKS
  // -------------------------------------------------------------------------
  Future<List<StudentRemarks>> getRemarks({String? examId, String? sectionId}) async {
    final data = await _store.load();
    return _store
        .listOf(data, 'exam_student_remarks')
        .map(StudentRemarks.fromJson)
        .where((r) => examId == null || r.examScheduleId == examId)
        .where((r) => sectionId == null || r.classSectionId == sectionId)
        .toList();
  }

  Future<void> saveRemarks(StudentRemarks remarks, {required ExaminationActor actor}) async {
    if (!actor.permissions.canReviewMarks) {
      throw const ExamPermissionException(
        'Permission denied: Only the Class In-charge or Admin can add remarks.',
      );
    }
    if (actor.permissions.isClassIncharge && actor.sectionId != remarks.classSectionId) {
      throw const ExamPermissionException('You can only add remarks for your own class-section.');
    }
    final data = await _store.load();
    final list = _store.listOf(data, 'exam_student_remarks');
    final now = _store.nowIso();
    final i = list.indexWhere((r) =>
        (r['exam_schedule_id'] ?? '').toString() == remarks.examScheduleId &&
        (r['student_id'] ?? '').toString() == remarks.studentId);
    final saved = StudentRemarks(
      id: i >= 0 ? (list[i]['id'] ?? _store.newId('rem')).toString() : _store.newId('rem'),
      examScheduleId: remarks.examScheduleId,
      studentId: remarks.studentId,
      classSectionId: remarks.classSectionId,
      academic: remarks.academic,
      conduct: remarks.conduct,
      participation: remarks.participation,
      improvement: remarks.improvement,
      remarks: remarks.remarks,
      updatedAt: now,
    );
    if (i >= 0) {
      list[i] = saved.toJson();
    } else {
      list.add(saved.toJson());
    }
    _store.setList(data, 'exam_student_remarks', list);

    // Keep an existing report card in step with the latest remarks.
    final cards = _store.listOf(data, 'report_cards');
    for (final c in cards) {
      if ((c['exam_schedule_id'] ?? '').toString() == remarks.examScheduleId &&
          (c['student_id'] ?? '').toString() == remarks.studentId) {
        c['class_incharge_remarks'] = saved.combined;
        c['updated_at'] = now;
      }
    }
    _store.setList(data, 'report_cards', cards);
    await _store.save(data);
  }
}
