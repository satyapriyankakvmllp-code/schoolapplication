import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/exam_ops_models.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import 'exam_repository.dart';
import 'examination_local_datasource.dart';

/// Screens 3-6: hall tickets, exam-day attendance, marks entry and review.
/// Stored in the same examination.json as new top-level lists.
class ExamOpsRepository {
  final ExaminationLocalDataSource _ds;
  List<StudentRef>? _students;
  ExamOpsRepository({ExaminationLocalDataSource? dataSource})
      : _ds = dataSource ?? ExaminationLocalDataSource();

  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await _ds.readExaminationJson()) as Map<String, dynamic>;
  Future<void> _save(Map<String, dynamic> d) async =>
      _ds.writeExaminationJson(const JsonEncoder.withIndent('  ').convert(d));
  List<Map<String, dynamic>> _list(Map<String, dynamic> raw, String key) =>
      (raw[key] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();

  void _needAdmin(ExaminationActor a) {
    if (!a.permissions.isAdminOrPrincipal) {
      throw const ExamPermissionException('Permission denied: Admin or Principal only.');
    }
  }

  // ---------------- students ----------------
  Future<List<StudentRef>> getStudents() async {
    if (_students != null) return _students!;
    Map<String, dynamic> db = {};
    try {
      db = jsonDecode(await rootBundle.loadString('assets/data/global_school_database.json')) as Map<String, dynamic>;
    } catch (_) {
      try {
        db = jsonDecode(await rootBundle.loadString('assets/data/students/students_and_parents.json')) as Map<String, dynamic>;
      } catch (_) {}
    }

    final users = (db['users'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    final names = {
      for (final u in users)
        u['id'].toString(): '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
    };
    final rawStudents = (db['student_profiles'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();

    return _students = rawStudents
        .map((s) => StudentRef(
              s['id'].toString(),
              names[s['user_id']] ?? s['admission_number'].toString(),
              s['roll_number'].toString(),
              s['admission_number'].toString(),
              s['current_class_id'].toString(),
            ))
        .toList();
  }

  Future<List<StudentRef>> studentsForSection(String sectionId) async =>
      (await getStudents()).where((s) => s.classSectionId == sectionId).toList()
        ..sort((a, b) => (int.tryParse(a.rollNumber) ?? 0).compareTo(int.tryParse(b.rollNumber) ?? 0));

  // ---------------- hall tickets (screen 3) ----------------
  Future<List<HallTicket>> getHallTickets(String examId) async =>
      _list(await _load(), 'hall_tickets')
          .where((t) => t['exam_schedule_id'] == examId)
          .map(HallTicket.fromJson)
          .toList();

  /// Generates a ticket for every student of every class that has a paper.
  /// Existing tickets are kept. Returns number newly created.
  Future<int> generateHallTickets(ExamSchedule exam, List<ExamPaper> papers,
      {required ExaminationActor actor}) async {
    _needAdmin(actor);
    if (exam.isCancelled) {
      throw const ExamValidationException('Cannot generate tickets for a cancelled exam.');
    }
    if (papers.isEmpty) {
      throw const ExamValidationException('Add exam papers before generating hall tickets.');
    }
    final raw = await _load();
    final tickets = _list(raw, 'hall_tickets');
    final sections = papers.map((p) => p.classSectionId).whereType<String>().toSet();
    var created = 0;
    for (final sec in sections) {
      for (final st in await studentsForSection(sec)) {
        final exists = tickets.any(
            (t) => t['exam_schedule_id'] == exam.examScheduleId && t['student_id'] == st.id);
        if (exists) continue;
        final n = tickets.where((t) => t['exam_schedule_id'] == exam.examScheduleId).length + 1;
        final yr = exam.startDate.substring(0, 4);
        tickets.add(HallTicket(
          id: 'ht-${exam.examScheduleId}-${st.id}',
          examScheduleId: exam.examScheduleId,
          studentId: st.id,
          ticketNumber: 'HT-$yr-${n.toString().padLeft(4, '0')}',
          token: '${exam.examScheduleId}|${st.id}',
          issueDate: DateTime.now().toIso8601String().substring(0, 10),
        ).toJson());
        created++;
      }
    }
    raw['hall_tickets'] = tickets;
    await _save(raw);
    return created;
  }

  Future<void> revokeHallTicket(String id, {required ExaminationActor actor}) async {
    _needAdmin(actor);
    final raw = await _load();
    final tickets = _list(raw, 'hall_tickets');
    for (final t in tickets) {
      if (t['id'] == id) t['status'] = t['status'] == 'REVOKED' ? 'ISSUED' : 'REVOKED';
    }
    raw['hall_tickets'] = tickets;
    await _save(raw);
  }

  // ---------------- attendance (screen 4) ----------------
  Future<Map<String, ExamAttendance>> getAttendance(String paperId) async => {
        for (final a in _list(await _load(), 'exam_attendance')
            .where((a) => a['exam_paper_id'] == paperId)
            .map(ExamAttendance.fromJson))
          a.studentId: a,
      };

  Future<void> saveAttendance(String paperId, List<ExamAttendance> rows,
      {required ExaminationActor actor}) async {
    if (actor.permissions.isStudentOrParent) {
      throw const ExamPermissionException('Permission denied.');
    }
    final raw = await _load();
    final all = _list(raw, 'exam_attendance')..removeWhere((a) => a['exam_paper_id'] == paperId);
    all.addAll(rows.map((r) => r.toJson()..['marked_by'] = actor.userId));
    raw['exam_attendance'] = all;
    await _save(raw);
  }

  // ---------------- marks (screens 5 & 6) ----------------
  Future<Map<String, StudentMark>> getMarks(String paperId) async => {
        for (final m in _list(await _load(), 'student_exam_marks')
            .where((m) => m['exam_paper_id'] == paperId)
            .map(StudentMark.fromJson))
          m.studentId: m,
      };

  Future<Map<String, StudentMark>> getAllMarks() async => {
        for (final m in _list(await _load(), 'student_exam_marks').map(StudentMark.fromJson))
          '${m.examPaperId}|${m.studentId}': m,
      };

  /// Teacher saves a draft or submits. Submitted marks are locked until a correction is requested.
  Future<void> saveMarks(ExamPaper paper, List<StudentMark> rows,
      {required bool submit, required ExaminationActor actor}) async {
    final p = actor.permissions;
    if (!(p.isAdminOrPrincipal || p.isTeacher || p.isClassIncharge)) {
      throw const ExamPermissionException('Permission denied: you cannot enter marks.');
    }
    final existing = await getMarks(paper.id);
    for (final r in rows) {
      final cur = existing[r.studentId];
      if (cur != null && (cur.status == 'SUBMITTED' || cur.status == 'REVIEWED')) {
        throw const ExamValidationException(
            'Marks are already submitted and locked. Ask the class in-charge for a correction.');
      }
      if (r.marks != null && (r.marks! < 0 || r.marks! > paper.maxMarks)) {
        throw ExamValidationException(
            'Marks must be between 0 and ${paper.maxMarks.toStringAsFixed(0)}.');
      }
      if (submit && r.marks == null) {
        throw const ExamValidationException('Enter marks for every student before submitting.');
      }
    }
    final raw = await _load();
    final all = _list(raw, 'student_exam_marks')
      ..removeWhere((m) =>
          m['exam_paper_id'] == paper.id && rows.any((r) => r.studentId == m['student_id']));
    all.addAll(rows.map((r) => StudentMark(paper.id, r.studentId, r.marks,
            submit ? 'SUBMITTED' : 'DRAFT', r.remarks)
        .toJson()
      ..['entered_by'] = actor.userId
      ..['submitted_at'] = submit ? DateTime.now().toIso8601String() : null));
    raw['student_exam_marks'] = all;
    await _save(raw);
  }

  /// Class in-charge / admin: approve (REVIEWED) or flag correction.
  Future<void> reviewMarks(String paperId, {required bool approve, String remarks = '',
      required ExaminationActor actor}) async {
    final p = actor.permissions;
    if (!(p.isAdminOrPrincipal || p.isClassIncharge)) {
      throw const ExamPermissionException('Permission denied: only class in-charge or admin can review.');
    }
    if (!approve && remarks.trim().isEmpty) {
      throw const ExamValidationException('Enter a remark describing the correction needed.');
    }
    final raw = await _load();
    final all = _list(raw, 'student_exam_marks');
    var touched = 0;
    for (final m in all.where((m) => m['exam_paper_id'] == paperId)) {
      m['status'] = approve ? 'REVIEWED' : 'CORRECTION_REQUESTED';
      m['reviewed_by'] = actor.userId;
      m['reviewed_at'] = DateTime.now().toIso8601String();
      if (!approve) m['remarks'] = remarks.trim();
      touched++;
    }
    if (touched == 0) throw const ExamValidationException('No marks have been entered for this paper.');
    raw['student_exam_marks'] = all;
    await _save(raw);
  }
}
