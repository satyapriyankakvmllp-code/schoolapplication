import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/examination_actor.dart';
import 'exam_repository.dart';
import 'examination_store.dart';

class PaperLinkedCounts {
  final int attendance;
  final int marks;
  final int questionPapers;
  const PaperLinkedCounts({this.attendance = 0, this.marks = 0, this.questionPapers = 0});
  int get total => attendance + marks + questionPapers;

  String summary() {
    final parts = <String>[];
    if (attendance > 0) parts.add('$attendance attendance record${attendance == 1 ? '' : 's'}');
    if (marks > 0) parts.add('$marks mark${marks == 1 ? '' : 's'}');
    if (questionPapers > 0) {
      parts.add('$questionPapers question paper${questionPapers == 1 ? '' : 's'}');
    }
    return parts.join(', ');
  }
}

/// Screen 2: the exam timetable (one paper per subject per class-section).
class ExamPaperRepository {
  final ExaminationStore _store;
  ExamPaperRepository(this._store);

  void _requireManage(ExaminationActor actor) {
    if (!actor.permissions.canManagePapers) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can change the timetable.',
      );
    }
  }

  Future<List<ExamPaper>> getPapers({String? examId}) async {
    final data = await _store.load();
    final list = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) => examId == null || p.examScheduleId == examId)
        .toList();
    list.sort((a, b) {
      final c = (a.examDate ?? '').compareTo(b.examDate ?? '');
      if (c != 0) return c;
      return a.startTime.compareTo(b.startTime);
    });
    return list;
  }

  Future<ExamPaper?> getPaper(String id) async {
    final all = await getPapers();
    return all.where((p) => p.id == id).firstOrNull;
  }

  bool _overlaps(ExamPaper a, ExamPaper b) {
    if (a.examDate == null || a.examDate != b.examDate) return false;
    final as = ExamPaper.minutesOf(a.startTime);
    final ae = ExamPaper.minutesOf(a.endTime);
    final bs = ExamPaper.minutesOf(b.startTime);
    final be = ExamPaper.minutesOf(b.endTime);
    if (as < 0 || ae < 0 || bs < 0 || be < 0) return false;
    return as < be && bs < ae;
  }

  /// Validates a paper. Errors block saving, warnings are only shown.
  Future<PaperCheckResult> check(
    ExamPaper draft, {
    String? excludeId,
    ExamMasterData master = ExamMasterData.empty,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    if (draft.examScheduleId.isEmpty) errors.add('Exam is required.');
    if ((draft.classSectionId ?? '').isEmpty) errors.add('Class-section is required.');
    if ((draft.subjectId ?? '').isEmpty) errors.add('Subject is required.');
    if ((draft.examDate ?? '').isEmpty) errors.add('Exam date is required.');

    final sm = ExamPaper.minutesOf(draft.startTime);
    final em = ExamPaper.minutesOf(draft.endTime);
    if (sm < 0 || em < 0) {
      errors.add('Start time and end time are required.');
    } else if (em <= sm) {
      errors.add('End time must be after the start time.');
    }

    if (draft.maxMarks <= 0) errors.add('Max marks must be greater than 0.');
    if (draft.passingMarks <= 0) {
      errors.add('Passing marks must be greater than 0.');
    } else if (draft.passingMarks > draft.maxMarks) {
      errors.add('Passing marks cannot be more than max marks.');
    }
    if (errors.isNotEmpty) return PaperCheckResult(errors: errors, warnings: warnings);

    final data = await _store.load();
    final exams = _store.listOf(data, 'exam_schedules');
    final exam = exams
        .where((e) => (e['exam_schedule_id'] ?? e['id']).toString() == draft.examScheduleId)
        .firstOrNull;
    if (exam != null) {
      final s = (exam['start_date'] ?? '').toString();
      final e = (exam['end_date'] ?? '').toString();
      final d = draft.examDate ?? '';
      if (s.isNotEmpty && e.isNotEmpty && (d.compareTo(s) < 0 || d.compareTo(e) > 0)) {
        warnings.add('Date is outside the exam period ($s to $e). You can still save it.');
      }
    }

    final others = _store
        .listOf(data, 'exam_papers')
        .map(ExamPaper.fromJson)
        .where((p) => p.id != excludeId && !p.isCancelled)
        .toList();

    for (final p in others) {
      if (p.examScheduleId == draft.examScheduleId &&
          p.classSectionId == draft.classSectionId &&
          p.subjectId == draft.subjectId) {
        errors.add(
          '${master.subjectName(draft.subjectId)} already has a paper for '
          '${master.sectionLabel(draft.classSectionId)} in this exam.',
        );
        break;
      }
    }
    for (final p in others) {
      if (p.classSectionId == draft.classSectionId && _overlaps(draft, p)) {
        errors.add(
          '${master.sectionLabel(draft.classSectionId)} already has '
          '${master.subjectName(p.subjectId)} at ${p.startTime} to ${p.endTime} on that day.',
        );
        break;
      }
    }
    if (draft.roomId != null) {
      for (final p in others) {
        if (p.roomId == draft.roomId && _overlaps(draft, p)) {
          errors.add(
            '${master.roomName(draft.roomId)} is already used for '
            '${master.subjectName(p.subjectId)} (${master.sectionLabel(p.classSectionId)}) at that time.',
          );
          break;
        }
      }
    }
    if (draft.invigilatorId != null) {
      for (final p in others) {
        if (p.invigilatorId == draft.invigilatorId && _overlaps(draft, p)) {
          warnings.add(
            '${master.teacherName(draft.invigilatorId)} is already invigilating '
            '${master.subjectName(p.subjectId)} at that time.',
          );
          break;
        }
      }
    }
    return PaperCheckResult(errors: errors, warnings: warnings);
  }

  Future<ExamPaper> savePaper(
    ExamPaper paper, {
    required ExaminationActor actor,
    ExamMasterData master = ExamMasterData.empty,
  }) async {
    _requireManage(actor);
    final isNew = paper.id.isEmpty;
    final check = await this.check(
      paper,
      excludeId: isNew ? null : paper.id,
      master: master,
    );
    if (check.hasErrors) throw ExamValidationException(check.errors.first);

    if (paper.status == 'CANCELLED' && (paper.cancelReason ?? '').trim().isEmpty) {
      throw const ExamValidationException('A cancellation reason is required.');
    }

    final data = await _store.load();
    final list = _store.listOf(data, 'exam_papers');
    final now = _store.nowIso();

    // Status stays automatic unless the admin picked one.
    final computed = ExamPaper.computeStatus(
      rawStatus: paper.status,
      manual: paper.manualStatus,
      examDate: paper.examDate,
      startTime: paper.startTime,
      endTime: paper.endTime,
    );
    final saved = paper.copyWith(
      id: isNew ? _store.newId('ex-paper') : paper.id,
      status: computed,
      createdAt: isNew ? now : paper.createdAt,
      updatedAt: now,
      clearCancelReason: computed != 'CANCELLED',
    );

    if (isNew) {
      list.add(saved.toJson());
    } else {
      final i = list.indexWhere((m) => (m['id'] ?? m['paper_id']).toString() == paper.id);
      if (i < 0) throw const ExamValidationException('Paper not found.');
      list[i] = saved.toJson();
    }
    _store.setList(data, 'exam_papers', list);
    await _store.save(data);
    return saved;
  }

  Future<PaperLinkedCounts> linkedCounts(String paperId) async {
    final data = await _store.load();
    int count(String key) => _store
        .listOf(data, key)
        .where((m) => (m['exam_paper_id'] ?? m['paper_id']).toString() == paperId)
        .length;
    return PaperLinkedCounts(
      attendance: count('exam_attendance'),
      marks: count('student_exam_marks'),
      questionPapers: count('question_papers'),
    );
  }

  Future<void> cancelPaper(
    String id,
    String reason, {
    required ExaminationActor actor,
  }) async {
    _requireManage(actor);
    if (reason.trim().isEmpty) {
      throw const ExamValidationException('A cancellation reason is required.');
    }
    final paper = await getPaper(id);
    if (paper == null) throw const ExamValidationException('Paper not found.');
    if (paper.status != 'SCHEDULED' && paper.status != 'ONGOING') {
      throw ExamValidationException(
        'Only SCHEDULED or ONGOING papers can be cancelled (current status: ${paper.status}).',
      );
    }
    await savePaper(
      paper.copyWith(status: 'CANCELLED', cancelReason: reason.trim()),
      actor: actor,
    );
  }

  /// Deletes a paper in ANY status together with everything linked to it.
  Future<void> deletePaper(String id, {required ExaminationActor actor}) async {
    _requireManage(actor);
    final data = await _store.load();
    final papers = _store.listOf(data, 'exam_papers');
    final index = papers.indexWhere((m) => (m['id'] ?? m['paper_id']).toString() == id);
    if (index < 0) throw const ExamValidationException('Paper not found.');
    papers.removeAt(index);
    _store.setList(data, 'exam_papers', papers);

    for (final key in ['exam_attendance', 'student_exam_marks']) {
      final l = _store.listOf(data, key)
        ..removeWhere((m) => (m['exam_paper_id'] ?? m['paper_id']).toString() == id);
      _store.setList(data, key, l);
    }

    final qps = _store.listOf(data, 'question_papers');
    final qpIds = qps
        .where((m) => (m['exam_paper_id'] ?? '').toString() == id)
        .map((m) => (m['question_paper_id'] ?? m['id']).toString())
        .toSet();
    qps.removeWhere((m) => (m['exam_paper_id'] ?? '').toString() == id);
    _store.setList(data, 'question_papers', qps);
    final items = _store.listOf(data, 'question_paper_items')
      ..removeWhere((m) => qpIds.contains((m['question_paper_id'] ?? '').toString()));
    _store.setList(data, 'question_paper_items', items);

    await _store.save(data);
  }
}
