import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_records_model.dart';
import '../domain/examination_actor.dart';
import 'exam_conduct_repository.dart';
import 'exam_repository.dart';
import 'examination_store.dart';

/// Screens 7 and 8: results calculation, report card approval, publishing and
/// the student / parent view.
class ExamResultRepository {
  final ExaminationStore _store;
  final ExamConductRepository _conduct;
  ExamResultRepository(this._store, this._conduct);

  void _requireManage(ExaminationActor actor) {
    if (!actor.permissions.canManageResults) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can manage results.',
      );
    }
  }

  Future<List<GradeBand>> getGradeScale() async {
    final data = await _store.load();
    final bands = _store.listOf(data, 'grade_scale').map(GradeBand.fromJson).toList();
    bands.sort((a, b) => b.minPercent.compareTo(a.minPercent));
    return bands.isEmpty ? GradeBand.defaults : bands;
  }

  GradeBand _bandFor(double pct, List<GradeBand> bands) {
    for (final b in bands) {
      if (pct >= b.minPercent) return b;
    }
    return bands.last;
  }

  double _round2(double v) => (v * 100).round() / 100;

  Future<List<ReportCard>> getReportCards({
    String? examId,
    String? sectionId,
    String? studentId,
    bool publishedOnly = false,
  }) async {
    final data = await _store.load();
    final list = _store
        .listOf(data, 'report_cards')
        .map(ReportCard.fromJson)
        .where((c) => examId == null || c.examScheduleId == examId)
        .where((c) => sectionId == null || c.classSectionId == sectionId)
        .where((c) => studentId == null || c.studentId == studentId)
        .where((c) => !publishedOnly || (c.isPublished && c.status == 'PUBLISHED'))
        .toList();
    list.sort((a, b) {
      final c = a.classRank.compareTo(b.classRank);
      return c != 0 ? c : a.studentId.compareTo(b.studentId);
    });
    return list;
  }

  /// Results can only be calculated when every paper of the class-section has
  /// reviewed marks.
  Future<ResultReadiness> readiness({
    required String examId,
    required String sectionId,
    required ExamMasterData master,
  }) async {
    final data = await _store.load();
    final papers = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) =>
            p.examScheduleId == examId && p.classSectionId == sectionId && !p.isCancelled)
        .toList();
    if (papers.isEmpty) {
      return const ResultReadiness(ready: false, pending: ['No exam papers for this class-section.']);
    }
    final students = master.studentsForSection(sectionId);
    if (students.isEmpty) {
      return const ResultReadiness(ready: false, pending: ['No enrolled students in this class-section.']);
    }
    final marks = _store.listOf(data, 'student_exam_marks').map(ExamMark.fromJson).toList();
    final att = _store.listOf(data, 'exam_attendance').map(ExamAttendance.fromJson).toList();
    final pending = <String>[];
    for (final p in papers) {
      final s = _conduct.summarize(paper: p, students: students, marks: marks, attendance: att);
      if (s.status != 'REVIEWED') {
        pending.add(
          '${master.subjectName(p.subjectId)}: marks ${s.status.replaceAll('_', ' ').toLowerCase()}',
        );
      }
    }
    return ResultReadiness(ready: pending.isEmpty, pending: pending);
  }

  /// Calculates total, percentage, grade, GPA and class rank for every student
  /// of a class-section. Never typed by hand.
  Future<ResultCalcSummary> calculate({
    required String examId,
    required String sectionId,
    required ExamMasterData master,
    required ExaminationActor actor,
  }) async {
    _requireManage(actor);
    final ready = await readiness(examId: examId, sectionId: sectionId, master: master);
    if (!ready.ready) {
      throw ExamValidationException('Cannot calculate yet. ${ready.pending.join('; ')}');
    }
    final data = await _store.load();
    final bands = await getGradeScale();
    final papers = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) =>
            p.examScheduleId == examId && p.classSectionId == sectionId && !p.isCancelled)
        .toList();
    final students = master.studentsForSection(sectionId);
    final marks = _store.listOf(data, 'student_exam_marks').map(ExamMark.fromJson).toList();
    final att = _store.listOf(data, 'exam_attendance').map(ExamAttendance.fromJson).toList();
    final remarks = _store
        .listOf(data, 'exam_student_remarks')
        .map(StudentRemarks.fromJson)
        .where((r) => r.examScheduleId == examId)
        .toList();

    final rows = <_Calc>[];
    for (final st in students) {
      final subjects = <SubjectResult>[];
      var total = 0.0;
      var max = 0.0;
      for (final p in papers) {
        final absent = att.any(
          (a) => a.examPaperId == p.id && a.studentId == st.id && a.isAbsent,
        );
        final mark = marks
            .where((m) => m.examPaperId == p.id && m.studentId == st.id)
            .firstOrNull;
        final got = absent ? 0.0 : (mark?.marksObtained ?? 0.0);
        total += got;
        max += p.maxMarks;
        subjects.add(SubjectResult(
          paperId: p.id,
          subjectId: p.subjectId ?? '',
          subjectName: master.subjectName(p.subjectId),
          marks: got,
          maxMarks: p.maxMarks,
          passingMarks: p.passingMarks,
          absent: absent,
        ));
      }
      rows.add(_Calc(st, subjects, total, max));
    }

    // Rank: highest total first, equal totals share the same rank.
    final sorted = [...rows]..sort((a, b) => b.total.compareTo(a.total));
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].total == sorted[i - 1].total) {
        sorted[i].rank = sorted[i - 1].rank;
      } else {
        sorted[i].rank = i + 1;
      }
    }

    final cards = _store.listOf(data, 'report_cards');
    final now = _store.nowIso();
    var passed = 0;
    var failed = 0;
    for (final r in rows) {
      final pct = r.max > 0 ? _round2(r.total / r.max * 100) : 0.0;
      final band = _bandFor(pct, bands);
      final rem = remarks.where((x) => x.studentId == r.student.id).firstOrNull;
      final i = cards.indexWhere((c) =>
          (c['exam_schedule_id'] ?? '').toString() == examId &&
          (c['student_id'] ?? '').toString() == r.student.id);
      final card = ReportCard(
        id: i >= 0
            ? (cards[i]['report_card_id'] ?? cards[i]['id'] ?? _store.newId('rc')).toString()
            : _store.newId('rc'),
        examScheduleId: examId,
        studentId: r.student.id,
        classSectionId: sectionId,
        totalMarks: r.total,
        totalMaxMarks: r.max,
        percentage: pct,
        grade: band.grade,
        gpa: band.gpaPoint,
        classRank: r.rank,
        subjects: r.subjects,
        remarks: rem?.combined ?? '',
        status: 'PENDING_APPROVAL',
        generatedAt: now,
        updatedAt: now,
      );
      if (card.passed) {
        passed++;
      } else {
        failed++;
      }
      if (i >= 0) {
        cards[i] = card.toJson();
      } else {
        cards.add(card.toJson());
      }
    }
    _store.setList(data, 'report_cards', cards);
    await _store.save(data);
    return ResultCalcSummary(
      studentsProcessed: rows.length,
      passed: passed,
      failed: failed,
    );
  }

  Future<void> _updateCards({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
    required bool Function(Map<String, dynamic> card) when,
    required void Function(Map<String, dynamic> card, String now) change,
    required String emptyMessage,
  }) async {
    _requireManage(actor);
    final data = await _store.load();
    final cards = _store.listOf(data, 'report_cards');
    final now = _store.nowIso();
    var count = 0;
    for (final c in cards) {
      if ((c['exam_schedule_id'] ?? '').toString() == examId &&
          (c['class_section_id'] ?? '').toString() == sectionId &&
          when(c)) {
        change(c, now);
        c['updated_at'] = now;
        count++;
      }
    }
    if (count == 0) throw ExamValidationException(emptyMessage);
    _store.setList(data, 'report_cards', cards);
    await _store.save(data);
  }

  Future<void> approveSection({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
  }) {
    return _updateCards(
      examId: examId,
      sectionId: sectionId,
      actor: actor,
      when: (c) => (c['stale'] != true),
      change: (c, now) {
        c['status'] = 'APPROVED';
        c['approved_by_id'] = actor.userId;
        c['approved_at'] = now;
        c['send_back_reason'] = '';
      },
      emptyMessage: 'No up-to-date report cards to approve. Calculate the results again.',
    );
  }

  Future<void> sendBackSection({
    required String examId,
    required String sectionId,
    required String reason,
    required ExaminationActor actor,
  }) {
    if (reason.trim().isEmpty) {
      throw const ExamValidationException('Please write the reason for sending back.');
    }
    return _updateCards(
      examId: examId,
      sectionId: sectionId,
      actor: actor,
      when: (c) => true,
      change: (c, now) {
        c['status'] = 'SENT_BACK';
        c['is_published'] = false;
        c['send_back_reason'] = reason.trim();
        c['approved_by_id'] = '';
        c['approved_at'] = '';
      },
      emptyMessage: 'No report cards found for this class-section.',
    );
  }

  /// Publishing is a separate action and only allowed after approval.
  Future<void> publishSection({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
  }) {
    return _updateCards(
      examId: examId,
      sectionId: sectionId,
      actor: actor,
      when: (c) => (c['status'] ?? '').toString() == 'APPROVED',
      change: (c, now) {
        c['status'] = 'PUBLISHED';
        c['is_published'] = true;
        c['published_at'] = now;
      },
      emptyMessage: 'Approve the report cards before publishing them.',
    );
  }

  Future<void> unpublishSection({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
  }) {
    return _updateCards(
      examId: examId,
      sectionId: sectionId,
      actor: actor,
      when: (c) => (c['status'] ?? '').toString() == 'PUBLISHED',
      change: (c, now) {
        c['status'] = 'APPROVED';
        c['is_published'] = false;
        c['published_at'] = '';
      },
      emptyMessage: 'There are no published report cards to unpublish.',
    );
  }

  Future<void> deleteSectionCards({
    required String examId,
    required String sectionId,
    required ExaminationActor actor,
  }) async {
    _requireManage(actor);
    final data = await _store.load();
    final cards = _store.listOf(data, 'report_cards')
      ..removeWhere((c) =>
          (c['exam_schedule_id'] ?? '').toString() == examId &&
          (c['class_section_id'] ?? '').toString() == sectionId);
    _store.setList(data, 'report_cards', cards);
    await _store.save(data);
  }
}

class _Calc {
  final ExamStudentInfo student;
  final List<SubjectResult> subjects;
  final double total;
  final double max;
  int rank = 0;
  _Calc(this.student, this.subjects, this.total, this.max);
}
