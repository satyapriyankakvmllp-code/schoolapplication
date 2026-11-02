import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../domain/exam_flow_models.dart';
import '../domain/exam_timetable_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import '../domain/grade_scale_config.dart';
import 'exam_repository.dart';
import 'examination_local_datasource.dart';

/// Repository for Hall Tickets, Attendance, Marks Entry, Review, Results, and Report Cards.
/// Persists everything in `examination.json` using the local datasource.
class ExamFlowRepository {
  final ExaminationLocalDataSource _ds;
  final Uuid _uuid = const Uuid();
  List<StudentRef>? _studentsCache;

  ExamFlowRepository({ExaminationLocalDataSource? dataSource})
      : _ds = dataSource ?? ExaminationLocalDataSource();

  // ------------------------------------------------------------------ IO
  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await _ds.readExaminationJson()) as Map<String, dynamic>;

  Future<void> _save(Map<String, dynamic> d) async =>
      _ds.writeExaminationJson(const JsonEncoder.withIndent('  ').convert(d));

  List<Map<String, dynamic>> _list(Map<String, dynamic> raw, String key) =>
      (raw[key] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();

  String _now() => DateTime.now().toIso8601String();
  String _today() => _now().substring(0, 10);

  void _need(bool ok, String msg) {
    if (!ok) throw ExamPermissionException(msg);
  }

  // ------------------------------------------------------------ Students
  Future<List<StudentRef>> getStudents() async {
    if (_studentsCache != null) return _studentsCache!;

    Future<dynamic> asset(String p) async {
      try {
        final content = await rootBundle.loadString(p);
        return jsonDecode(content);
      } catch (_) {
        return null;
      }
    }

    final globalDb = (await asset('assets/data/global_school_database.json') as Map<String, dynamic>?) ?? {};
    final sp = (await asset('assets/data/students/students_and_parents.json') as Map<String, dynamic>?) ?? {};
    final users = await asset('assets/data/auth/users.json');

    final userList = [
      ...((globalDb['users'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((users is List ? users : (users as Map<String, dynamic>?)?['users'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];

    final userMap = {
      for (final u in userList)
        '${u['id']}': {
          'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
          'photo': u['profile_photo_url']?.toString(),
        },
    };

    final rawStudents = [
      ...((globalDb['student_profiles'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((sp['student_profiles'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];

    final seen = <String>{};
    final list = <StudentRef>[];
    for (final s in rawStudents) {
      final id = '${s['id']}';
      if (seen.add(id)) {
        final uid = '${s['user_id']}';
        final u = userMap[uid];
        final name = u?['name']?.isNotEmpty == true ? u!['name']! : 'Student ${s['roll_number']}';
        list.add(StudentRef(
          id: id,
          name: name,
          admissionNumber: '${s['admission_number'] ?? ''}',
          rollNumber: '${s['roll_number'] ?? ''}',
          sectionId: '${s['current_class_id'] ?? ''}',
          photoUrl: u?['photo'],
        ));
      }
    }
    return _studentsCache = list;
  }

  static String? teacherIdFor(ExaminationActor a) {
    switch (a.role) {
      case ExamRole.teacher:
        return 'tch-prof-302';
      case ExamRole.classIncharge:
        return 'tch-prof-301';
      default:
        return null;
    }
  }

  static const String demoStudentId = 'std-prof-501';
  static const String inchargeSectionId = 'cls-sec-10a';

  Future<List<ExamTimetableEntry>> _papers(Map<String, dynamic> raw, String examId) async =>
      (raw['exam_papers'] as List<dynamic>? ?? raw['exam_timetables'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((p) => '${p['exam_schedule_id']}' == examId)
          .map(ExamTimetableEntry.fromJson)
          .toList();

  // ------------------------------------------------- SCREEN 3: Hall Tickets
  Future<List<HallTicket>> getHallTickets(String examId) async =>
      _list(await _load(), 'hall_tickets')
          .where((h) => '${h['exam_schedule_id']}' == examId)
          .map(HallTicket.fromJson)
          .toList();

  /// Generates hall tickets for a specific section or for all sections with timetable entries.
  /// Skips students with no timetable entries and prevents duplicates.
  Future<Map<String, int>> generateHallTickets(
    ExamSchedule exam,
    ExaminationActor a, {
    String? sectionId,
    List<String>? selectedStudentIds,
  }) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can generate hall tickets.');
    if (exam.isCancelled) {
      throw const ExamValidationException('Cancelled exams cannot have hall tickets.');
    }
    final raw = await _load();
    final timetable = await _papers(raw, exam.examScheduleId);
    if (timetable.isEmpty) {
      throw const ExamValidationException('Add exam timetable entries before generating hall tickets.');
    }

    final sectionsWithEntries = timetable.map((p) => p.classSectionId).whereType<String>().toSet();

    var students = await getStudents();
    if (sectionId != null && sectionId != 'ALL') {
      students = students.where((s) => s.sectionId == sectionId).toList();
    }
    if (selectedStudentIds != null && selectedStudentIds.isNotEmpty) {
      final idSet = selectedStudentIds.toSet();
      students = students.where((s) => idSet.contains(s.id)).toList();
    }

    final tickets = _list(raw, 'hall_tickets');
    final have = tickets
        .where((h) => '${h['exam_schedule_id']}' == exam.examScheduleId)
        .map((h) => '${h['student_id']}')
        .toSet();

    var created = 0;
    var skipped = 0;
    var seq = tickets.where((h) => '${h['exam_schedule_id']}' == exam.examScheduleId).length;

    for (final s in students) {
      if (have.contains(s.id)) continue;

      // Skip students whose section has no timetable entries
      if (!sectionsWithEntries.contains(s.sectionId)) {
        skipped++;
        continue;
      }

      seq++;
      created++;
      final year = exam.startDate.substring(0, 4);
      final seatNo = 'S-${s.rollNumber.padLeft(3, '0')}';

      tickets.add(HallTicket(
        id: 'ht-${_uuid.v4().substring(0, 8)}',
        examScheduleId: exam.examScheduleId,
        studentId: s.id,
        number: 'HT-$year-${seq.toString().padLeft(4, '0')}',
        token: _uuid.v4().substring(0, 12).toUpperCase(),
        issueDate: _today(),
        status: 'ISSUED',
        seatNumber: seatNo,
      ).toJson());
    }

    raw['hall_tickets'] = tickets;
    await _save(raw);
    return {'created': created, 'skipped': skipped};
  }

  Future<void> setHallTicketStatus(String id, String status, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can change hall ticket status.');
    final raw = await _load();
    final t = _list(raw, 'hall_tickets');
    final i = t.indexWhere((h) => '${h['id']}' == id);
    if (i >= 0) t[i]['status'] = status;
    raw['hall_tickets'] = t;
    await _save(raw);
  }

  /// Manually create or update a single hall ticket (Admin manual workflow)
  Future<HallTicket> saveHallTicket(HallTicket ticket, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can issue or edit hall tickets.');
    final raw = await _load();
    final tickets = _list(raw, 'hall_tickets');
    final i = tickets.indexWhere((h) =>
        '${h['id']}' == ticket.id ||
        ('${h['exam_schedule_id']}' == ticket.examScheduleId && '${h['student_id']}' == ticket.studentId));

    final jsonTicket = ticket.toJson();
    if (i >= 0) {
      tickets[i] = jsonTicket;
    } else {
      tickets.add(jsonTicket);
    }
    raw['hall_tickets'] = tickets;
    await _save(raw);
    return ticket;
  }

  // --------------------------------------------- SCREEN 4: Attendance
  Future<List<AttendanceRecord>> getAttendance(String paperId) async =>
      _list(await _load(), 'exam_attendance')
          .where((r) => '${r['exam_paper_id']}' == paperId)
          .map(AttendanceRecord.fromJson)
          .toList();

  Future<List<StudentRef>> studentsForPaper(ExamTimetableEntry p) async =>
      (await getStudents()).where((s) => s.sectionId == p.classSectionId).toList();

  Future<void> saveAttendance(ExamTimetableEntry paper, Map<String, String> statuses,
      Map<String, String> remarks, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.permissions.isTeacher || a.permissions.isClassIncharge,
        'You do not have permission to mark exam attendance.');
    final raw = await _load();
    final list = _list(raw, 'exam_attendance');

    for (final e in statuses.entries) {
      final i = list.indexWhere(
          (r) => '${r['exam_paper_id']}' == paper.id && '${r['student_id']}' == e.key);
      final rec = AttendanceRecord(
        id: i >= 0 ? '${list[i]['id']}' : 'att-${_uuid.v4().substring(0, 8)}',
        examPaperId: paper.id,
        studentId: e.key,
        status: e.value,
        markedBy: teacherIdFor(a) ?? a.userId,
        markedAt: _now(),
        remarks: remarks[e.key],
      ).toJson();
      if (i >= 0) {
        list[i] = rec;
      } else {
        list.add(rec);
      }
    }
    raw['exam_attendance'] = list;
    await _save(raw);
  }

  // ------------------------------------------------ SCREEN 5: Marks Entry
  Future<List<StudentMark>> getMarks(String paperId) async =>
      _list(await _load(), 'student_exam_marks')
          .where((m) => '${m['exam_paper_id']}' == paperId)
          .map(StudentMark.fromJson)
          .toList();

  Future<List<StudentMark>> getMarksForExam(String examId) async {
    final raw = await _load();
    final ids = (await _papers(raw, examId)).map((p) => p.id).toSet();
    return _list(raw, 'student_exam_marks')
        .where((m) => ids.contains('${m['exam_paper_id']}'))
        .map(StudentMark.fromJson)
        .toList();
  }

  /// Saves marks for students in a timetable entry.
  /// - Absent students cannot get marks (input disabled).
  /// - Numbers only, 0 to max_marks.
  /// - If [submit] is true: blocked if any present student has no marks (lists names).
  /// - Transitions: DRAFT or SUBMITTED.
  Future<void> saveMarks(
    ExamTimetableEntry paper,
    Map<String, double?> values,
    bool submit,
    ExaminationActor a,
  ) async {
    _need(
      a.permissions.isAdminOrPrincipal || a.permissions.isTeacher || a.permissions.isClassIncharge,
      'You cannot enter marks.',
    );

    final raw = await _load();
    final list = _list(raw, 'student_exam_marks');
    final att = _list(raw, 'exam_attendance')
        .where((r) => '${r['exam_paper_id']}' == paper.id && '${r['status']}' == 'ABSENT')
        .map((r) => '${r['student_id']}')
        .toSet();

    final allStudents = await studentsForPaper(paper);

    // Validation: marks bounds
    for (final e in values.entries) {
      final v = e.value;
      if (v != null) {
        if (v < 0) {
          throw const ExamValidationException('Marks cannot be negative.');
        }
        if (v > paper.maxMarks) {
          throw ExamValidationException(
              'Marks cannot exceed max marks of ${paper.maxMarks.toStringAsFixed(0)}.');
        }
      }
    }

    // Submit Validation: every present student must have marks
    if (submit) {
      final missingNames = <String>[];
      for (final st in allStudents) {
        if (att.contains(st.id)) continue; // Absent student
        final val = values[st.id];
        if (val == null) {
          missingNames.add('${st.rollNumber.isNotEmpty ? "${st.rollNumber}. " : ""}${st.name}');
        }
      }
      if (missingNames.isNotEmpty) {
        final preview = missingNames.take(3).join(', ');
        final rest = missingNames.length > 3 ? ' and ${missingNames.length - 3} more' : '';
        throw ExamValidationException(
            'Cannot submit: Marks are missing for $preview$rest.');
      }
    }

    for (final e in values.entries) {
      final i = list.indexWhere(
          (m) => '${m['exam_paper_id']}' == paper.id && '${m['student_id']}' == e.key);

      if (i >= 0) {
        final curStatus = '${list[i]['status']}';
        // Submitted or Approved marks cannot be overwritten unless rejected
        if ((curStatus == 'SUBMITTED' || curStatus == 'UNDER_REVIEW' || curStatus == 'APPROVED') &&
            !a.permissions.isAdminOrPrincipal) {
          continue;
        }
      }

      final prev = i >= 0 ? list[i] : <String, dynamic>{};
      final isAbsent = att.contains(e.key);

      final rec = StudentMark(
        id: i >= 0 ? '${prev['id']}' : 'mark-${_uuid.v4().substring(0, 8)}',
        examPaperId: paper.id,
        studentId: e.key,
        marksObtained: isAbsent ? null : e.value,
        status: submit ? 'SUBMITTED' : 'DRAFT',
        submittedAt: submit ? _now() : prev['submitted_at']?.toString(),
        enteredBy: teacherIdFor(a) ?? a.userId,
        remarks: isAbsent ? 'Absent' : prev['remarks']?.toString(),
        rejectionReason: null, // cleared upon re-submission
      ).toJson();

      if (i >= 0) {
        list[i] = rec;
      } else {
        list.add(rec);
      }
    }

    raw['student_exam_marks'] = list;
    await _save(raw);
  }

  // ------------------------------------------------ SCREEN 6: Marks Review
  /// Move submitted marks to UNDER_REVIEW
  Future<int> markUnderReview(String paperId, ExaminationActor a) async {
    _need(a.permissions.isClassIncharge || a.permissions.isAdminOrPrincipal,
        'Only Class In-charge or Admin can review marks.');
    final raw = await _load();
    final list = _list(raw, 'student_exam_marks');
    var count = 0;
    for (final m in list) {
      if ('${m['exam_paper_id']}' == paperId && '${m['status']}' == 'SUBMITTED') {
        m['status'] = 'UNDER_REVIEW';
        m['reviewer_name'] = a.name;
        m['reviewed_by'] = a.userId;
        m['reviewed_at'] = _now();
        count++;
      }
    }
    raw['student_exam_marks'] = list;
    await _save(raw);
    return count;
  }

  /// Reject mark with a required reason. Unlocks mark for the teacher to edit.
  Future<void> rejectMark(String markId, String reason, ExaminationActor a) async {
    _need(a.permissions.isClassIncharge || a.permissions.isAdminOrPrincipal,
        'Only Class In-charge or Admin can reject marks.');
    if (reason.trim().isEmpty) {
      throw const ExamValidationException('A rejection reason is required.');
    }
    final raw = await _load();
    final list = _list(raw, 'student_exam_marks');
    final i = list.indexWhere((m) => '${m['id']}' == markId);
    if (i < 0) throw const ExamValidationException('Mark not found.');

    list[i]['status'] = 'REJECTED';
    list[i]['rejection_reason'] = reason.trim();
    list[i]['reviewer_name'] = a.name;
    list[i]['reviewed_by'] = a.userId;
    list[i]['reviewed_at'] = _now();

    raw['student_exam_marks'] = list;
    await _save(raw);
  }

  /// Approve single mark
  Future<void> approveMark(String markId, ExaminationActor a) async {
    _need(a.permissions.isClassIncharge || a.permissions.isAdminOrPrincipal,
        'Only Class In-charge or Admin can approve marks.');
    final raw = await _load();
    final list = _list(raw, 'student_exam_marks');
    final i = list.indexWhere((m) => '${m['id']}' == markId);
    if (i < 0) throw const ExamValidationException('Mark not found.');

    list[i]['status'] = 'APPROVED';
    list[i]['reviewer_name'] = a.name;
    list[i]['reviewed_by'] = a.userId;
    list[i]['reviewed_at'] = _now();

    raw['student_exam_marks'] = list;
    await _save(raw);
  }

  /// Bulk approve all submitted or under-review marks for a paper or section
  Future<int> bulkApproveMarks({
    required String examId,
    String? paperId,
    String? sectionId,
    required ExaminationActor a,
  }) async {
    _need(a.permissions.isClassIncharge || a.permissions.isAdminOrPrincipal,
        'Only Class In-charge or Admin can approve marks.');
    final raw = await _load();
    final list = _list(raw, 'student_exam_marks');

    Set<String> targetPaperIds;
    if (paperId != null) {
      targetPaperIds = {paperId};
    } else if (sectionId != null) {
      final papers = (await _papers(raw, examId))
          .where((p) => p.classSectionId == sectionId)
          .map((p) => p.id)
          .toSet();
      targetPaperIds = papers;
    } else {
      final papers = (await _papers(raw, examId)).map((p) => p.id).toSet();
      targetPaperIds = papers;
    }

    var approvedCount = 0;
    for (final m in list) {
      if (targetPaperIds.contains('${m['exam_paper_id']}')) {
        final st = '${m['status']}';
        if (st == 'SUBMITTED' || st == 'UNDER_REVIEW') {
          m['status'] = 'APPROVED';
          m['reviewer_name'] = a.name;
          m['reviewed_by'] = a.userId;
          m['reviewed_at'] = _now();
          approvedCount++;
        }
      }
    }
    raw['student_exam_marks'] = list;
    await _save(raw);
    return approvedCount;
  }

  // ---------------------------------------- SCREEN 7: Results & Report Cards
  Future<List<ReportCard>> getReportCards(String examId) async =>
      _list(await _load(), 'report_cards')
          .where((r) => '${r['exam_schedule_id']}' == examId)
          .map(ReportCard.fromJson)
          .toList();

  /// Calculates results using ONLY APPROVED marks.
  Future<int> calculateResults(ExamSchedule exam, ExaminationActor a, {String? sectionId}) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can calculate results.');
    final raw = await _load();
    final allPapers = (await _papers(raw, exam.examScheduleId)).where((p) => !p.isCancelled).toList();
    if (allPapers.isEmpty) throw const ExamValidationException('This exam has no timetable entries.');

    final papers = sectionId != null && sectionId.isNotEmpty && sectionId != 'ALL'
        ? allPapers.where((p) => p.classSectionId == sectionId).toList()
        : allPapers;
    if (papers.isEmpty) {
      throw const ExamValidationException('No timetable entries found for the selected section.');
    }

    final students = await getStudents();
    final marks = _list(raw, 'student_exam_marks').map(StudentMark.fromJson).toList();
    final att = _list(raw, 'exam_attendance').map(AttendanceRecord.fromJson).toList();

    final bySection = <String, List<StudentRef>>{};
    for (final p in papers) {
      for (final s in students.where((s) => s.sectionId == p.classSectionId)) {
        bySection.putIfAbsent(s.sectionId, () => []);
        if (!bySection[s.sectionId]!.any((x) => x.id == s.id)) bySection[s.sectionId]!.add(s);
      }
    }

    final computed = <String, Map<String, dynamic>>{};
    for (final entry in bySection.entries) {
      final sectionPapers = papers.where((p) => p.classSectionId == entry.key).toList();
      for (final s in entry.value) {
        double total = 0, max = 0;
        bool pass = true;

        for (final p in sectionPapers) {
          final m = marks.where((m) => m.examPaperId == p.id && m.studentId == s.id).firstOrNull;
          final absent = att.any((r) => r.examPaperId == p.id && r.studentId == s.id && r.status == 'ABSENT');

          if (m == null && !absent) {
            throw ExamValidationException(
                'Marks are missing for ${s.name} in one or more subjects.');
          }
          if (m != null && m.status != 'APPROVED') {
            throw ExamValidationException(
                'Marks for ${s.name} are not approved yet (Status: ${m.status}). Only Admin-approved marks may feed results.');
          }

          max += p.maxMarks;
          final got = m?.marksObtained ?? 0;
          total += got;
          if (got < p.passingMarks) pass = false;
        }

        final pct = max == 0 ? 0.0 : total / max * 100;
        computed[s.id] = {
          'section': entry.key,
          'total': total,
          'max': max,
          'pct': double.parse(pct.toStringAsFixed(2)),
          'pass': pass,
        };
      }
    }

    // Rank within section descending by percentage
    final ranks = <String, int>{};
    for (final sec in bySection.keys) {
      final ids = computed.entries.where((e) => e.value['section'] == sec).map((e) => e.key).toList()
        ..sort((x, y) => (computed[y]!['pct'] as double).compareTo(computed[x]!['pct'] as double));
      for (var i = 0; i < ids.length; i++) {
        final tie = i > 0 && computed[ids[i]]!['pct'] == computed[ids[i - 1]]!['pct'];
        ranks[ids[i]] = tie ? ranks[ids[i - 1]]! : i + 1;
      }
    }

    final cards = _list(raw, 'report_cards');
    var n = 0;
    for (final e in computed.entries) {
      final i = cards.indexWhere(
          (c) => '${c['exam_schedule_id']}' == exam.examScheduleId && '${c['student_id']}' == e.key);
      if (i >= 0 && '${cards[i]['status']}' == 'PUBLISHED') continue;

      final v = e.value;
      final pct = v['pct'] as double;
      final passed = v['pass'] as bool;

      final card = ReportCard(
        id: i >= 0 ? '${cards[i]['id']}' : 'rc-${_uuid.v4().substring(0, 8)}',
        examScheduleId: exam.examScheduleId,
        studentId: e.key,
        classSectionId: v['section'] as String,
        totalMarks: v['total'] as double,
        totalMaxMarks: v['max'] as double,
        percentage: pct,
        gpa: GradeScaleConfig.gpaFor(pct, passed: passed),
        grade: GradeScaleConfig.gradeFor(pct, passed: passed),
        performance: GradeScaleConfig.performanceFor(pct, passed: passed),
        rank: ranks[e.key] ?? 0,
        passed: passed,
        status: 'PENDING_APPROVAL',
        inchargeRemarks: i >= 0 ? cards[i]['class_incharge_remarks']?.toString() : null,
        principalRemarks: i >= 0 ? cards[i]['principal_remarks']?.toString() : null,
        generatedAt: _now(),
      ).toJson();

      if (i >= 0) {
        cards[i] = card;
      } else {
        cards.add(card);
      }
      n++;
    }

    raw['report_cards'] = cards;
    raw['exam_results'] = cards;
    await _save(raw);
    return n;
  }

  Future<void> saveRemarks({
    required String cardId,
    String? inchargeRemarks,
    String? principalRemarks,
    required ExaminationActor a,
  }) async {
    final raw = await _load();
    final cards = _list(raw, 'report_cards');
    final i = cards.indexWhere((c) => '${c['id']}' == cardId);
    if (i >= 0) {
      if ('${cards[i]['status']}' == 'PUBLISHED' && !a.permissions.isAdminOrPrincipal) {
        throw const ExamValidationException('Published report cards cannot be edited.');
      }
      if (inchargeRemarks != null) {
        cards[i]['class_incharge_remarks'] = inchargeRemarks.trim();
      }
      if (principalRemarks != null) {
        cards[i]['principal_remarks'] = principalRemarks.trim();
      }
    }
    raw['report_cards'] = cards;
    raw['exam_results'] = cards;
    await _save(raw);
  }

  /// Advance report cards: APPROVE or PUBLISH or UNPUBLISH
  Future<int> advanceReportCards(String examId, String action, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can approve or publish report cards.');
    final raw = await _load();
    final cards = _list(raw, 'report_cards').where((c) => '${c['exam_schedule_id']}' == examId).toList();
    var n = 0;
    for (final c in cards) {
      if (action == 'APPROVE' && '${c['status']}' == 'PENDING_APPROVAL') {
        c['status'] = 'APPROVED';
        c['approved_by_id'] = a.userId;
        c['approved_at'] = _now();
        n++;
      } else if (action == 'PUBLISH' && '${c['status']}' == 'APPROVED') {
        c['status'] = 'PUBLISHED';
        c['is_published'] = true;
        c['published_at'] = _now();
        n++;
      } else if (action == 'UNPUBLISH' && '${c['status']}' == 'PUBLISHED') {
        c['status'] = 'APPROVED';
        c['is_published'] = false;
        c['published_at'] = null;
        n++;
      }
    }
    if (n == 0) {
      throw ExamValidationException(action == 'APPROVE'
          ? 'No report cards are waiting for approval.'
          : action == 'PUBLISH'
              ? 'Approve report cards before publishing.'
              : 'No published report cards found to unpublish.');
    }
    final allCards = _list(raw, 'report_cards');
    raw['exam_results'] = allCards;
    await _save(raw);
    return n;
  }

  Future<List<ReportCard>> getStudentReportCards(String studentId, {bool publishedOnly = true}) async =>
      _list(await _load(), 'report_cards')
          .where((r) => '${r['student_id']}' == studentId)
          .map(ReportCard.fromJson)
          .where((r) => !publishedOnly || r.isPublished)
          .toList();

  // ------------------------------------------------------------- Syllabus
  Future<List<SyllabusChapter>> getSyllabus({
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    final raw = await _load();
    var list = _list(raw, 'syllabus').map(SyllabusChapter.fromJson).toList();

    // Matching class: check direct match or numeric alias
    if (classId != null && classId.isNotEmpty) {
      final targetDigits = RegExp(r'\d+').firstMatch(classId)?.group(0);
      list = list.where((ch) {
        if (ch.classId == classId) return true;
        if (targetDigits != null && RegExp(r'\d+').firstMatch(ch.classId)?.group(0) == targetDigits) {
          return true;
        }
        return false;
      }).toList();
    }

    // Matching section
    if (sectionId != null && sectionId.isNotEmpty) {
      list = list.where((ch) => ch.classSectionId == null || ch.classSectionId!.isEmpty || ch.classSectionId == sectionId).toList();
    }

    // Matching subject
    if (subjectId != null && subjectId.isNotEmpty) {
      list = list.where((ch) => ch.subjectId == subjectId).toList();
    }

    list.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return list;
  }

  Future<SyllabusChapter> saveSyllabusChapter(SyllabusChapter chapter, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can add or edit syllabus chapters.');

    if (chapter.title.trim().isEmpty) {
      throw const ExamValidationException('Chapter title is required.');
    }
    if (chapter.subjectId.trim().isEmpty) {
      throw const ExamValidationException('Subject must be selected.');
    }

    final raw = await _load();
    final list = _list(raw, 'syllabus');
    final now = _now();

    final id = chapter.id.isEmpty ? 'syl-${_uuid.v4().substring(0, 8)}' : chapter.id;
    final item = chapter.copyWith(id: id);
    final map = item.toJson();
    if (chapter.id.isEmpty) {
      map['created_at'] = now;
      map['updated_at'] = now;
      list.add(map);
    } else {
      final i = list.indexWhere((x) => '${x['id']}' == id);
      if (i >= 0) {
        map['created_at'] = list[i]['created_at'] ?? now;
        map['updated_at'] = now;
        list[i] = map;
      } else {
        map['created_at'] = now;
        map['updated_at'] = now;
        list.add(map);
      }
    }

    raw['syllabus'] = list;
    await _save(raw);
    return SyllabusChapter.fromJson(map);
  }

  Future<void> deleteSyllabusChapter(String chapterId, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can delete syllabus chapters.');

    final raw = await _load();
    final list = _list(raw, 'syllabus');
    list.removeWhere((x) => '${x['id']}' == chapterId);
    raw['syllabus'] = list;
    await _save(raw);
  }

  // ------------------------------------------------------------- Exam Patterns
  Future<List<ExamPattern>> getExamPatterns({
    String? examScheduleId,
    String? classId,
    String? subjectId,
  }) async {
    final raw = await _load();
    var list = _list(raw, 'exam_patterns').map(ExamPattern.fromJson).toList();

    if (examScheduleId != null && examScheduleId.isNotEmpty) {
      list = list.where((p) => p.examScheduleId == examScheduleId || p.examScheduleId.isEmpty).toList();
    }
    if (classId != null && classId.isNotEmpty) {
      final targetDigits = RegExp(r'\d+').firstMatch(classId)?.group(0);
      list = list.where((p) {
        if (p.classId == null || p.classId!.isEmpty || p.classId == classId) return true;
        if (targetDigits != null && RegExp(r'\d+').firstMatch(p.classId!)?.group(0) == targetDigits) {
          return true;
        }
        return false;
      }).toList();
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      list = list.where((p) => p.subjectId == null || p.subjectId!.isEmpty || p.subjectId == subjectId).toList();
    }
    return list;
  }

  Future<ExamPattern> saveExamPattern(ExamPattern pattern, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can configure exam patterns.');

    if (pattern.title.trim().isEmpty) {
      throw const ExamValidationException('Pattern title is required.');
    }
    if (pattern.sections.isEmpty) {
      throw const ExamValidationException('At least one section must be configured.');
    }

    final raw = await _load();
    final list = _list(raw, 'exam_patterns');
    final now = _now();

    final id = pattern.id.isEmpty ? 'pat-${_uuid.v4().substring(0, 8)}' : pattern.id;
    final item = pattern.copyWith(id: id);
    final map = item.toJson();

    final i = list.indexWhere((x) => '${x['id']}' == id);
    if (i >= 0) {
      map['created_at'] = list[i]['created_at'] ?? now;
      map['updated_at'] = now;
      list[i] = map;
    } else {
      map['created_at'] = now;
      map['updated_at'] = now;
      list.add(map);
    }

    raw['exam_patterns'] = list;
    await _save(raw);
    return ExamPattern.fromJson(map);
  }

  Future<void> deleteExamPattern(String patternId, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can delete exam patterns.');

    final raw = await _load();
    final list = _list(raw, 'exam_patterns');
    list.removeWhere((x) => '${x['id']}' == patternId);
    raw['exam_patterns'] = list;
    await _save(raw);
  }

  // --------------------------------------------------------- Question Papers
  Future<List<UploadedQuestionPaper>> getQuestionPapers({
    String? examScheduleId,
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    final raw = await _load();
    var list = _list(raw, 'question_papers').map(UploadedQuestionPaper.fromJson).toList();

    if (examScheduleId != null && examScheduleId.isNotEmpty) {
      list = list.where((p) => p.examScheduleId == examScheduleId || p.examScheduleId.isEmpty).toList();
    }
    if (classId != null && classId.isNotEmpty) {
      final targetDigits = RegExp(r'\d+').firstMatch(classId)?.group(0);
      list = list.where((p) {
        if (p.classId == classId) return true;
        if (targetDigits != null && RegExp(r'\d+').firstMatch(p.classId)?.group(0) == targetDigits) {
          return true;
        }
        return false;
      }).toList();
    }
    if (sectionId != null && sectionId.isNotEmpty) {
      list = list.where((p) => p.classSectionId == sectionId).toList();
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      list = list.where((p) => p.subjectId == subjectId).toList();
    }

    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  Future<UploadedQuestionPaper> uploadQuestionPaper(UploadedQuestionPaper paper, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can upload question papers.');

    if (paper.subjectId.trim().isEmpty) {
      throw const ExamValidationException('Subject must be selected or entered.');
    }
    if (paper.classId.trim().isEmpty) {
      throw const ExamValidationException('Class must be selected.');
    }

    final raw = await _load();
    final list = _list(raw, 'question_papers');
    final now = _now();

    final id = paper.id.isEmpty ? 'qp-${_uuid.v4().substring(0, 8)}' : paper.id;
    final map = paper.toJson();
    map['id'] = id;
    if (map['uploaded_at'] == null || (map['uploaded_at'] as String).isEmpty) {
      map['uploaded_at'] = now;
    }

    final i = list.indexWhere((x) => '${x['id']}' == id);
    if (i >= 0) {
      list[i] = map;
    } else {
      list.insert(0, map);
    }

    raw['question_papers'] = list;
    await _save(raw);
    return UploadedQuestionPaper.fromJson(map);
  }

  Future<void> reviewQuestionPaper(String paperId, String status, String? remarks, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal, 'Only Admin or Principal can review and approve question papers.');

    final raw = await _load();
    final list = _list(raw, 'question_papers');
    final i = list.indexWhere((x) => '${x['id']}' == paperId);
    if (i >= 0) {
      list[i]['status'] = status;
      if (remarks != null && remarks.trim().isNotEmpty) {
        list[i]['review_remarks'] = remarks.trim();
      }
      raw['question_papers'] = list;
      await _save(raw);
    }
  }

  Future<void> deleteQuestionPaper(String paperId, ExaminationActor a) async {
    _need(a.permissions.isAdminOrPrincipal || a.role == ExamRole.teacher || a.role == ExamRole.classIncharge,
        'Only Admin, Principal, or Faculty can delete question papers.');

    final raw = await _load();
    final list = _list(raw, 'question_papers');
    list.removeWhere((x) => '${x['id']}' == paperId);
    raw['question_papers'] = list;
    await _save(raw);
  }
}
