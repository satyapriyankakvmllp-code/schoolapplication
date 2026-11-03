import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_planning_model.dart';
import '../domain/examination_actor.dart';
import 'exam_repository.dart';
import 'examination_store.dart';

/// Screens 9 to 11: syllabus & exam pattern, question bank, question papers.
class ExamPlanningRepository {
  final ExaminationStore _store;
  ExamPlanningRepository(this._store);

  // -------------------------------------------------------------------------
  // PATTERNS
  // -------------------------------------------------------------------------
  void _requirePatterns(ExaminationActor actor) {
    if (!actor.permissions.canManagePatterns) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can set the exam pattern.',
      );
    }
  }

  List<ExamPattern> _patterns(Map<String, dynamic> data) {
    final secs = _store.listOf(data, 'pattern_sections').map(PatternSection.fromJson).toList();
    final tops = _store.listOf(data, 'pattern_topics').map(PatternTopic.fromJson).toList();
    return _store.listOf(data, 'exam_syllabus_patterns').map((m) {
      final id = (m['pattern_id'] ?? m['id']).toString();
      return ExamPattern.fromJson(
        m,
        sections: secs.where((s) => s.patternId == id).toList(),
        topics: tops.where((t) => t.patternId == id).toList(),
      );
    }).toList();
  }

  Future<List<ExamPattern>> getPatterns({String? examId, String? sectionId}) async {
    final data = await _store.load();
    final list = _patterns(data)
        .where((p) => examId == null || p.examScheduleId == examId)
        .where((p) => sectionId == null || p.classSectionId == sectionId)
        .toList();
    list.sort((a, b) => a.patternName.compareTo(b.patternName));
    return list;
  }

  Future<ExamPattern> savePattern(ExamPattern p, {required ExaminationActor actor}) async {
    _requirePatterns(actor);
    if (p.patternName.trim().isEmpty) throw const ExamValidationException('Pattern name is required.');
    if (p.examScheduleId.isEmpty) throw const ExamValidationException('Exam is required.');
    if (p.classSectionId.isEmpty) throw const ExamValidationException('Class-section is required.');
    if (p.subjectId.isEmpty) throw const ExamValidationException('Subject is required.');
    if (p.maxMarks <= 0) throw const ExamValidationException('Max marks must be greater than 0.');
    if (p.examDuration <= 0) throw const ExamValidationException('Duration must be greater than 0.');
    for (final s in p.sections) {
      if (s.sectionName.trim().isEmpty) {
        throw const ExamValidationException('Every section needs a name.');
      }
      if (s.noOfQuestions <= 0 || s.marksEach <= 0) {
        throw ExamValidationException(
          '${s.sectionName}: number of questions and marks each must be greater than 0.',
        );
      }
      if (s.choiceCount < 0 || s.choiceCount > s.noOfQuestions) {
        throw ExamValidationException(
          '${s.sectionName}: "attempt any" cannot be more than the number of questions.',
        );
      }
    }
    final names = p.sections.map((s) => s.sectionName.trim().toLowerCase()).toList();
    if (names.toSet().length != names.length) {
      throw const ExamValidationException('Section names must be different from each other.');
    }
    for (final t in p.topics) {
      if (t.weightagePercent < 0 || t.weightagePercent > 100) {
        throw const ExamValidationException('Chapter weightage must be between 0 and 100.');
      }
    }
    final topicIds = p.topics.map((t) => t.topicId).toList();
    if (topicIds.toSet().length != topicIds.length) {
      throw const ExamValidationException('A chapter can only be added once.');
    }
    if (p.status == 'ACTIVE') {
      final problems = p.activationProblems();
      if (problems.isNotEmpty) {
        throw ExamValidationException('Cannot activate: ${problems.first}');
      }
    }

    final data = await _store.load();
    final isNew = p.id.isEmpty;
    final existing = _patterns(data);
    final dup = existing.any((x) =>
        x.id != p.id &&
        x.examScheduleId == p.examScheduleId &&
        x.classSectionId == p.classSectionId &&
        x.subjectId == p.subjectId);
    if (dup) {
      throw const ExamValidationException(
        'A pattern already exists for this exam, class-section and subject. Edit that one instead.',
      );
    }

    final id = isNew ? _store.newId('pat') : p.id;
    final now = _store.nowIso();
    final head = ExamPattern(
      id: id,
      examScheduleId: p.examScheduleId,
      classSectionId: p.classSectionId,
      subjectId: p.subjectId,
      patternName: p.patternName.trim(),
      maxMarks: p.maxMarks,
      examDuration: p.examDuration,
      syllabusDetails: p.syllabusDetails.trim(),
      status: p.status,
      createdAt: isNew ? now : p.createdAt,
      updatedAt: now,
    );
    final heads = _store.listOf(data, 'exam_syllabus_patterns');
    final i = heads.indexWhere((m) => (m['pattern_id'] ?? m['id']).toString() == id);
    if (i >= 0) {
      heads[i] = head.toJson();
    } else {
      heads.add(head.toJson());
    }
    _store.setList(data, 'exam_syllabus_patterns', heads);

    final secs = _store.listOf(data, 'pattern_sections')
      ..removeWhere((m) => (m['pattern_id'] ?? '').toString() == id);
    for (final s in p.sections) {
      secs.add(PatternSection(
        id: s.id.isEmpty ? _store.newId('psec') : s.id,
        patternId: id,
        sectionName: s.sectionName.trim(),
        questionType: s.questionType,
        noOfQuestions: s.noOfQuestions,
        marksEach: s.marksEach,
        choiceCount: s.choiceCount,
      ).toJson());
    }
    _store.setList(data, 'pattern_sections', secs);

    final tops = _store.listOf(data, 'pattern_topics')
      ..removeWhere((m) => (m['pattern_id'] ?? '').toString() == id);
    for (final t in p.topics) {
      tops.add(PatternTopic(
        id: t.id.isEmpty ? _store.newId('ptop') : t.id,
        patternId: id,
        topicId: t.topicId,
        topicTitle: t.topicTitle,
        weightagePercent: t.weightagePercent,
      ).toJson());
    }
    _store.setList(data, 'pattern_topics', tops);
    await _store.save(data);

    return _patterns(await _store.load()).firstWhere((x) => x.id == id);
  }

  /// Number of question papers that use a pattern.
  Future<int> patternUsage(String patternId) async {
    final data = await _store.load();
    return _store
        .listOf(data, 'question_papers')
        .where((m) => (m['pattern_id'] ?? '').toString() == patternId)
        .length;
  }

  Future<void> deletePattern(String id, {required ExaminationActor actor}) async {
    _requirePatterns(actor);
    final data = await _store.load();
    final heads = _store.listOf(data, 'exam_syllabus_patterns');
    if (!heads.any((m) => (m['pattern_id'] ?? m['id']).toString() == id)) {
      throw const ExamValidationException('Pattern not found.');
    }
    heads.removeWhere((m) => (m['pattern_id'] ?? m['id']).toString() == id);
    _store.setList(data, 'exam_syllabus_patterns', heads);
    for (final key in ['pattern_sections', 'pattern_topics']) {
      final l = _store.listOf(data, key)..removeWhere((m) => (m['pattern_id'] ?? '').toString() == id);
      _store.setList(data, key, l);
    }
    final qps = _store.listOf(data, 'question_papers');
    final qpIds = qps
        .where((m) => (m['pattern_id'] ?? '').toString() == id)
        .map((m) => (m['question_paper_id'] ?? m['id']).toString())
        .toSet();
    qps.removeWhere((m) => (m['pattern_id'] ?? '').toString() == id);
    _store.setList(data, 'question_papers', qps);
    final items = _store.listOf(data, 'question_paper_items')
      ..removeWhere((m) => qpIds.contains((m['question_paper_id'] ?? '').toString()));
    _store.setList(data, 'question_paper_items', items);
    await _store.save(data);
  }

  // -------------------------------------------------------------------------
  // QUESTION BANK
  // -------------------------------------------------------------------------
  List<Question> _questions(Map<String, dynamic> data) {
    final opts = _store.listOf(data, 'question_options').map(QuestionOption.fromJson).toList();
    return _store.listOf(data, 'question_bank').map((m) {
      final id = (m['question_id'] ?? m['id']).toString();
      return Question.fromJson(m, options: opts.where((o) => o.questionId == id).toList());
    }).toList();
  }

  Future<List<Question>> getQuestions({String? subjectId}) async {
    final data = await _store.load();
    final list = _questions(data).where((q) => subjectId == null || q.subjectId == subjectId).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<int> questionUsage(String questionId) async {
    final data = await _store.load();
    return _store
        .listOf(data, 'question_paper_items')
        .where((m) => (m['question_id'] ?? '').toString() == questionId)
        .length;
  }

  Future<Question> saveQuestion(
    Question q,
    List<QuestionOption> options, {
    required ExaminationActor actor,
  }) async {
    if (!actor.permissions.canWriteQuestions) {
      throw const ExamPermissionException(
        'Permission denied: Only teachers and Admin can write questions.',
      );
    }
    if (q.text.trim().isEmpty) throw const ExamValidationException('Question text is required.');
    if (q.subjectId.isEmpty) throw const ExamValidationException('Subject is required.');
    if (q.marks <= 0) throw const ExamValidationException('Marks must be greater than 0.');
    final opts = options.where((o) => o.text.trim().isNotEmpty).toList();
    if (q.type == 'MCQ') {
      if (opts.length < 2) throw const ExamValidationException('An MCQ needs at least 2 options.');
      if (!opts.any((o) => o.isCorrect)) {
        throw const ExamValidationException('Mark at least one option as correct.');
      }
    }
    if (q.type == 'TRUE_FALSE' && !opts.any((o) => o.isCorrect)) {
      throw const ExamValidationException('Choose whether the statement is True or False.');
    }

    final data = await _store.load();
    final isNew = q.id.isEmpty;
    final list = _store.listOf(data, 'question_bank');
    final now = _store.nowIso();
    final id = isNew ? _store.newId('q') : q.id;

    final i = list.indexWhere((m) => (m['question_id'] ?? m['id']).toString() == id);
    Question? old;
    if (i >= 0) old = Question.fromJson(list[i]);
    if (old != null &&
        actor.permissions.isTeacher &&
        old.createdBy.isNotEmpty &&
        old.createdBy != actor.userId) {
      throw const ExamPermissionException('You can only edit questions you wrote.');
    }

    // A teacher's edit sends an approved question back to DRAFT.
    final status = actor.permissions.isAdminOrPrincipal
        ? q.status
        : 'DRAFT';
    final saved = Question(
      id: id,
      subjectId: q.subjectId,
      topicId: q.topicId,
      text: q.text.trim(),
      type: q.type,
      marks: q.marks,
      difficulty: q.difficulty,
      answerKey: q.answerKey.trim(),
      status: status,
      createdBy: isNew ? actor.userId : (old?.createdBy ?? actor.userId),
      createdAt: isNew ? now : (old?.createdAt ?? now),
      updatedAt: now,
    );
    if (i >= 0) {
      list[i] = saved.toJson();
    } else {
      list.add(saved.toJson());
    }
    _store.setList(data, 'question_bank', list);

    final all = _store.listOf(data, 'question_options')
      ..removeWhere((m) => (m['question_id'] ?? '').toString() == id);
    for (final o in opts) {
      all.add(QuestionOption(
        id: _store.newId('opt'),
        questionId: id,
        text: o.text.trim(),
        isCorrect: o.isCorrect,
      ).toJson());
    }
    _store.setList(data, 'question_options', all);
    await _store.save(data);
    return saved;
  }

  Future<void> setQuestionStatus(
    String id,
    String status, {
    required ExaminationActor actor,
  }) async {
    if (!actor.permissions.canApproveQuestionPapers) {
      throw const ExamPermissionException('Only Admin or Principal can approve questions.');
    }
    final data = await _store.load();
    final list = _store.listOf(data, 'question_bank');
    final i = list.indexWhere((m) => (m['question_id'] ?? m['id']).toString() == id);
    if (i < 0) throw const ExamValidationException('Question not found.');
    list[i]['status'] = status;
    list[i]['updated_at'] = _store.nowIso();
    _store.setList(data, 'question_bank', list);
    await _store.save(data);
  }

  Future<void> deleteQuestion(String id, {required ExaminationActor actor}) async {
    if (!actor.permissions.canWriteQuestions) {
      throw const ExamPermissionException('Permission denied.');
    }
    final data = await _store.load();
    final list = _store.listOf(data, 'question_bank');
    final i = list.indexWhere((m) => (m['question_id'] ?? m['id']).toString() == id);
    if (i < 0) throw const ExamValidationException('Question not found.');
    final owner = (list[i]['created_by_teacher_id'] ?? '').toString();
    if (actor.permissions.isTeacher && owner.isNotEmpty && owner != actor.userId) {
      throw const ExamPermissionException('You can only delete questions you wrote.');
    }
    final used = _store
        .listOf(data, 'question_paper_items')
        .where((m) => (m['question_id'] ?? '').toString() == id)
        .length;
    if (used > 0 && !actor.permissions.isAdminOrPrincipal) {
      throw ExamValidationException(
        'This question is used in $used question paper${used == 1 ? '' : 's'}. Ask Admin to remove it.',
      );
    }
    list.removeAt(i);
    _store.setList(data, 'question_bank', list);
    final opts = _store.listOf(data, 'question_options')
      ..removeWhere((m) => (m['question_id'] ?? '').toString() == id);
    _store.setList(data, 'question_options', opts);
    final items = _store.listOf(data, 'question_paper_items')
      ..removeWhere((m) => (m['question_id'] ?? '').toString() == id);
    _store.setList(data, 'question_paper_items', items);
    await _store.save(data);
  }

  // -------------------------------------------------------------------------
  // QUESTION PAPERS
  // -------------------------------------------------------------------------
  List<QuestionPaper> _papers(Map<String, dynamic> data) {
    final items = _store.listOf(data, 'question_paper_items').map(QuestionPaperItem.fromJson).toList();
    return _store.listOf(data, 'question_papers').map((m) {
      final id = (m['question_paper_id'] ?? m['id']).toString();
      final mine = items.where((i) => i.questionPaperId == id).toList()
        ..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
      return QuestionPaper.fromJson(m, items: mine);
    }).toList();
  }

  Future<List<QuestionPaper>> getQuestionPapers({String? examPaperId}) async {
    final data = await _store.load();
    return _papers(data).where((p) => examPaperId == null || p.examPaperId == examPaperId).toList();
  }

  bool _canEditPaper(QuestionPaper qp, ExaminationActor actor) {
    if (actor.permissions.isAdminOrPrincipal) return qp.status != 'LOCKED';
    if (actor.permissions.isTeacher) {
      return qp.status == 'DRAFT' || qp.status == 'CORRECTION_REQUIRED';
    }
    return false;
  }

  Future<QuestionPaper> createQuestionPaper({
    required ExamPaper examPaper,
    required ExamPattern pattern,
    required ExaminationActor actor,
  }) async {
    if (!actor.permissions.canWriteQuestions) {
      throw const ExamPermissionException('Only teachers and Admin can create question papers.');
    }
    if (pattern.examScheduleId != examPaper.examScheduleId ||
        pattern.classSectionId != examPaper.classSectionId ||
        pattern.subjectId != examPaper.subjectId) {
      throw const ExamValidationException(
        'The pattern does not belong to this exam, class-section and subject.',
      );
    }
    final data = await _store.load();
    final existing = _papers(data).where((p) => p.examPaperId == examPaper.id);
    if (existing.isNotEmpty) {
      throw const ExamValidationException('A question paper already exists for this exam paper.');
    }
    final now = _store.nowIso();
    final id = _store.newId('qp');
    final qp = QuestionPaper(
      id: id,
      examPaperId: examPaper.id,
      patternId: pattern.id,
      version: 1,
      paperCode: 'QP-${id.substring(3).toUpperCase()}',
      status: 'DRAFT',
      createdBy: actor.userId,
      createdAt: now,
      updatedAt: now,
    );
    final list = _store.listOf(data, 'question_papers')..add(qp.toJson());
    _store.setList(data, 'question_papers', list);
    await _store.save(data);
    return qp;
  }

  Future<void> saveItems({
    required String questionPaperId,
    required List<QuestionPaperItem> items,
    required ExaminationActor actor,
  }) async {
    final data = await _store.load();
    final qp = _papers(data).where((p) => p.id == questionPaperId).firstOrNull;
    if (qp == null) throw const ExamValidationException('Question paper not found.');
    if (!_canEditPaper(qp, actor)) {
      throw ExamValidationException(
        'This question paper is ${qp.status.replaceAll('_', ' ').toLowerCase()} and cannot be edited.',
      );
    }
    final all = _store.listOf(data, 'question_paper_items')
      ..removeWhere((m) => (m['question_paper_id'] ?? '').toString() == questionPaperId);
    for (final it in items) {
      all.add(QuestionPaperItem(
        id: it.id.isEmpty ? _store.newId('qpi') : it.id,
        questionPaperId: questionPaperId,
        questionId: it.questionId,
        sectionName: it.sectionName,
        questionNumber: it.questionNumber,
        marks: it.marks,
      ).toJson());
    }
    _store.setList(data, 'question_paper_items', all);
    final heads = _store.listOf(data, 'question_papers');
    for (final h in heads) {
      if ((h['question_paper_id'] ?? h['id']).toString() == questionPaperId) {
        h['updated_at'] = _store.nowIso();
      }
    }
    _store.setList(data, 'question_papers', heads);
    await _store.save(data);
  }

  /// Moves a question paper along the approval flow.
  /// Teacher: submit. Admin: start review, request correction, approve, lock,
  /// unlock. Submitting is blocked until the pattern is satisfied.
  Future<void> changePaperStatus({
    required String questionPaperId,
    required String newStatus,
    String comment = '',
    required ExaminationActor actor,
    PaperPatternCheck? check,
  }) async {
    final data = await _store.load();
    final heads = _store.listOf(data, 'question_papers');
    final i = heads.indexWhere((m) => (m['question_paper_id'] ?? m['id']).toString() == questionPaperId);
    if (i < 0) throw const ExamValidationException('Question paper not found.');
    final current = (heads[i]['status'] ?? 'DRAFT').toString().toUpperCase();
    final admin = actor.permissions.canApproveQuestionPapers;

    bool allowed;
    switch (newStatus) {
      case 'SUBMITTED':
        allowed = (current == 'DRAFT' || current == 'CORRECTION_REQUIRED') &&
            actor.permissions.canWriteQuestions;
        if (allowed && check != null && !check.ok) {
          throw ExamValidationException('Cannot submit yet. ${check.blockers.first}');
        }
        break;
      case 'UNDER_REVIEW':
        allowed = admin && current == 'SUBMITTED';
        break;
      case 'CORRECTION_REQUIRED':
        allowed = admin && (current == 'SUBMITTED' || current == 'UNDER_REVIEW' || current == 'APPROVED');
        if (allowed && comment.trim().isEmpty) {
          throw const ExamValidationException('Please write what needs to be corrected.');
        }
        break;
      case 'APPROVED':
        allowed = admin && (current == 'SUBMITTED' || current == 'UNDER_REVIEW' || current == 'CORRECTION_REQUIRED');
        break;
      case 'LOCKED':
        allowed = admin && current == 'APPROVED';
        break;
      case 'DRAFT':
        allowed = admin && (current == 'LOCKED' || current == 'APPROVED');
        break;
      default:
        allowed = false;
    }
    if (!allowed) {
      throw ExamValidationException('You cannot change this question paper from $current to $newStatus.');
    }
    final now = _store.nowIso();
    heads[i]['status'] = newStatus;
    heads[i]['updated_at'] = now;
    if (newStatus == 'CORRECTION_REQUIRED') heads[i]['review_comment'] = comment.trim();
    if (newStatus == 'APPROVED') {
      heads[i]['approved_by_id'] = actor.userId;
      heads[i]['approved_at'] = now;
      heads[i]['review_comment'] = '';
    }
    if (newStatus == 'DRAFT') {
      heads[i]['approved_by_id'] = '';
      heads[i]['approved_at'] = '';
    }
    _store.setList(data, 'question_papers', heads);
    await _store.save(data);
  }

  Future<void> deleteQuestionPaper(String id, {required ExaminationActor actor}) async {
    final data = await _store.load();
    final qp = _papers(data).where((p) => p.id == id).firstOrNull;
    if (qp == null) throw const ExamValidationException('Question paper not found.');
    final allowed = actor.permissions.isAdminOrPrincipal ||
        (actor.permissions.isTeacher && qp.status == 'DRAFT' && qp.createdBy == actor.userId);
    if (!allowed) throw const ExamPermissionException('You cannot delete this question paper.');
    final heads = _store.listOf(data, 'question_papers')
      ..removeWhere((m) => (m['question_paper_id'] ?? m['id']).toString() == id);
    _store.setList(data, 'question_papers', heads);
    final items = _store.listOf(data, 'question_paper_items')
      ..removeWhere((m) => (m['question_paper_id'] ?? '').toString() == id);
    _store.setList(data, 'question_paper_items', items);
    await _store.save(data);
  }

  /// Chapters available for a subject (from the Classes curriculum).
  List<ExamChapterInfo> chaptersFor(ExamMasterData master, String subjectId) =>
      master.chaptersFor(subjectId);
}
