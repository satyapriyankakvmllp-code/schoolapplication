import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_planning_model.dart';
import '../../domain/examination_actor.dart';
import '../widgets/exam_ui.dart';

String subjectLabel(ExamMasterData master, ExamSubjectInfo s) {
  final c = master.classById(s.classId);
  return c == null ? s.name : '${s.name} (${c.name})';
}

/// Subjects a user may write questions for.
List<ExamSubjectInfo> subjectsForUser(ExamMasterData master, ExaminationActor actor) {
  if (actor.permissions.isTeacher && actor.teacherId != null) {
    final mine = master.subjects.where((s) => s.teacherId == actor.teacherId).toList();
    if (mine.isNotEmpty) return mine;
  }
  return master.subjects;
}

/// Screen 10: question bank.
class QuestionBankPanel extends ConsumerStatefulWidget {
  const QuestionBankPanel({super.key});

  @override
  ConsumerState<QuestionBankPanel> createState() => _QuestionBankPanelState();
}

class _QuestionBankPanelState extends ConsumerState<QuestionBankPanel> {
  String? _subject;
  String? _chapter;
  String? _type;
  String? _level;
  String? _status;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Question q) async {
    final repo = ref.read(examPlanningRepositoryProvider);
    final used = await repo.questionUsage(q.id);
    if (!mounted) return;
    final ok = await confirmExam(
      context,
      title: 'Delete question?',
      message: used > 0
          ? 'This question is used in $used question paper${used == 1 ? '' : 's'}. Deleting it removes it from them.'
          : 'Delete this question? This cannot be undone.',
      confirmText: 'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      await repo.deleteQuestion(q.id, actor: ref.read(currentExamActorProvider));
      bumpExamData(ref);
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  Future<void> _setStatus(Question q, String status) async {
    try {
      await ref
          .read(examPlanningRepositoryProvider)
          .setQuestionStatus(q.id, status, actor: ref.read(currentExamActorProvider));
      bumpExamData(ref);
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  Future<void> _view(Question q, ExamMasterData master) {
    return showExamDialog<void>(
      context,
      (ctx) => ExamDialogFrame(
        title: 'Question',
        subtitle:
            '${master.subjectName(q.subjectId)} | ${questionTypeLabel(q.type)} | ${examFmtMarks(q.marks)} marks',
        icon: Icons.help_outline,
        maxWidth: 560,
        actions: [ExamPrimaryButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop())],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.text, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 10),
            for (final o in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(o.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18, color: o.isCorrect ? Colors.green : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o.text)),
                ]),
              ),
            if (q.answerKey.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExamInfoRow('Answer key', q.answerKey),
            ],
            ExamInfoRow('Chapter', master.chapterById(q.topicId)?.title ?? '-'),
            ExamInfoRow('Difficulty', q.difficulty),
            ExamInfoRow('Status', q.status),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final masterAsync = ref.watch(examMasterProvider);
    final qAsync = ref.watch(questionsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: 'Question Bank',
          subtitle: 'Questions grouped by subject, chapter, type and difficulty.',
          actions: [
            if (perms.canWriteQuestions)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                onPressed: () => QuestionFormDialog.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Question'),
              ),
          ],
        ),
        masterAsync.when(
          loading: () => const ExamLoading(),
          error: (e, _) => ExamErrorView(e),
          data: (master) => qAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (all) {
              final mySubjects = subjectsForUser(master, actor);
              final myIds = mySubjects.map((s) => s.id).toSet();
              final chapters = _subject == null ? const <ExamChapterInfo>[] : master.chaptersFor(_subject);
              final q = _search.text.trim().toLowerCase();
              final list = all.where((x) {
                if (!perms.isAdminOrPrincipal && !myIds.contains(x.subjectId)) return false;
                if (_subject != null && x.subjectId != _subject) return false;
                if (_chapter != null && x.topicId != _chapter) return false;
                if (_type != null && x.type != _type) return false;
                if (_level != null && x.difficulty != _level) return false;
                if (_status != null && x.status != _status) return false;
                if (q.isNotEmpty && !x.text.toLowerCase().contains(q)) return false;
                return true;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExamCard(
                    child: Column(
                      children: [
                        ExamFieldRow(children: [
                          ExamDropdown<String?>(
                            label: 'Subject',
                            value: _subject,
                            options: [
                              const ExamOption<String?>(null, 'All'),
                              ...mySubjects.map((s) => ExamOption<String?>(s.id, subjectLabel(master, s))),
                            ],
                            onChanged: (v) => setState(() {
                              _subject = v;
                              _chapter = null;
                            }),
                          ),
                          ExamDropdown<String?>(
                            label: 'Chapter',
                            value: _chapter,
                            options: [
                              const ExamOption<String?>(null, 'All'),
                              ...chapters.map((c) => ExamOption<String?>(c.id, c.title)),
                            ],
                            onChanged: (v) => setState(() => _chapter = v),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ExamFieldRow(children: [
                          ExamDropdown<String?>(
                            label: 'Type',
                            value: _type,
                            options: [
                              const ExamOption<String?>(null, 'All'),
                              ...kQuestionTypes.map((t) => ExamOption<String?>(t, questionTypeLabel(t))),
                            ],
                            onChanged: (v) => setState(() => _type = v),
                          ),
                          ExamDropdown<String?>(
                            label: 'Difficulty',
                            value: _level,
                            options: [
                              const ExamOption<String?>(null, 'All'),
                              ...kDifficultyLevels.map((t) => ExamOption<String?>(t, t)),
                            ],
                            onChanged: (v) => setState(() => _level = v),
                          ),
                          ExamDropdown<String?>(
                            label: 'Status',
                            value: _status,
                            options: const [
                              ExamOption<String?>(null, 'All'),
                              ExamOption<String?>('DRAFT', 'Draft'),
                              ExamOption<String?>('APPROVED', 'Approved'),
                            ],
                            onChanged: (v) => setState(() => _status = v),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ExamTextField(
                          label: 'Search',
                          controller: _search,
                          hint: 'Search in question text',
                          onChanged: (_) => setState(() {}),
                          suffixIcon: const Icon(Icons.search, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    ExamEmpty(
                      icon: Icons.quiz_outlined,
                      message: all.isEmpty
                          ? 'The question bank is empty. Add the first question.'
                          : 'No questions match these filters.',
                    )
                  else
                    ExamTable(
                      minWidth: 960,
                      columns: const [
                        'Question',
                        'Subject',
                        'Chapter',
                        'Type',
                        'Marks',
                        'Level',
                        'Status',
                        'Actions',
                      ],
                      rows: list.map((x) {
                        final mine = perms.isAdminOrPrincipal ||
                            (perms.isTeacher && (x.createdBy.isEmpty || x.createdBy == actor.userId));
                        return [
                          SizedBox(
                            width: 260,
                            child: Text(x.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5)),
                          ),
                          Text(master.subjectName(x.subjectId), style: const TextStyle(fontSize: 12.5)),
                          SizedBox(
                            width: 130,
                            child: Text(master.chapterById(x.topicId)?.title ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Text(questionTypeLabel(x.type), style: const TextStyle(fontSize: 12.5)),
                          Text(examFmtMarks(x.marks), style: const TextStyle(fontSize: 12.5)),
                          ExamBadge(x.difficulty, color: switch (x.difficulty) {
                            'EASY' => const Color(0xFF059669),
                            'HARD' => const Color(0xFFDC2626),
                            _ => const Color(0xFFD97706),
                          }),
                          ExamBadge(x.status),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExamIconAction(
                                icon: Icons.visibility_outlined,
                                tooltip: 'View',
                                onPressed: () => _view(x, master),
                              ),
                              if (perms.canWriteQuestions && mine)
                                ExamIconAction(
                                  icon: Icons.edit_outlined,
                                  tooltip: 'Edit',
                                  onPressed: () => QuestionFormDialog.show(context, existing: x),
                                ),
                              if (perms.canApproveQuestionPapers)
                                ExamIconAction(
                                  icon: x.isApproved ? Icons.unpublished_outlined : Icons.verified_outlined,
                                  tooltip: x.isApproved ? 'Move back to draft' : 'Approve',
                                  color: x.isApproved ? Colors.orange.shade700 : Colors.green.shade700,
                                  onPressed: () => _setStatus(x, x.isApproved ? 'DRAFT' : 'APPROVED'),
                                ),
                              if (perms.canWriteQuestions && mine)
                                ExamIconAction(
                                  icon: Icons.delete_outline,
                                  tooltip: 'Delete',
                                  color: Colors.red.shade600,
                                  onPressed: () => _delete(x),
                                ),
                            ],
                          ),
                        ];
                      }).toList(),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OptRow {
  final TextEditingController text;
  bool correct;
  _OptRow({String text = '', this.correct = false}) : text = TextEditingController(text: text);
}

class QuestionFormDialog extends ConsumerStatefulWidget {
  final Question? existing;
  const QuestionFormDialog({super.key, this.existing});

  static Future<void> show(BuildContext context, {Question? existing}) {
    return showExamDialog<void>(context, (ctx) => QuestionFormDialog(existing: existing));
  }

  @override
  ConsumerState<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends ConsumerState<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final TextEditingController _marks;
  late final TextEditingController _answer;
  String? _subjectId;
  String? _topicId;
  String _type = 'MCQ';
  String _level = 'MEDIUM';
  String _status = 'DRAFT';
  bool _trueAnswer = true;
  final List<_OptRow> _opts = [];
  bool _busy = false;
  String? _error;
  bool _loadedOptions = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _text = TextEditingController(text: q?.text ?? '');
    _marks = TextEditingController(text: examFmtMarks(q?.marks ?? 1));
    _answer = TextEditingController(text: q?.answerKey ?? '');
    _subjectId = q?.subjectId;
    _topicId = q?.topicId;
    _type = q?.type ?? 'MCQ';
    _level = q?.difficulty ?? 'MEDIUM';
    _status = q?.status ?? 'DRAFT';
    if (q != null) {
      if (q.type == 'TRUE_FALSE') {
        _trueAnswer = q.options.where((o) => o.isCorrect).firstOrNull?.text.toLowerCase() != 'false';
      } else {
        for (final o in q.options) {
          _opts.add(_OptRow(text: o.text, correct: o.isCorrect));
        }
      }
    }
    if (_opts.isEmpty && _type == 'MCQ') {
      _opts.addAll([_OptRow(), _OptRow(), _OptRow(), _OptRow()]);
    }
    _loadedOptions = true;
  }

  @override
  void dispose() {
    _text.dispose();
    _marks.dispose();
    _answer.dispose();
    for (final o in _opts) {
      o.text.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final options = <QuestionOption>[];
    if (_type == 'MCQ') {
      for (final o in _opts) {
        options.add(QuestionOption(id: '', questionId: '', text: o.text.text, isCorrect: o.correct));
      }
    } else if (_type == 'TRUE_FALSE') {
      options.addAll([
        QuestionOption(id: '', questionId: '', text: 'True', isCorrect: _trueAnswer),
        QuestionOption(id: '', questionId: '', text: 'False', isCorrect: !_trueAnswer),
      ]);
    }
    setState(() => _busy = true);
    try {
      await ref.read(examPlanningRepositoryProvider).saveQuestion(
            Question(
              id: widget.existing?.id ?? '',
              subjectId: _subjectId ?? '',
              topicId: _topicId,
              text: _text.text,
              type: _type,
              marks: double.tryParse(_marks.text.trim()) ?? 0,
              difficulty: _level,
              answerKey: _answer.text,
              status: _status,
              createdBy: widget.existing?.createdBy ?? '',
              createdAt: widget.existing?.createdAt ?? '',
            ),
            options,
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) {
        Navigator.of(context).pop();
        showExamSnack(context, 'Question saved.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = examErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final master = ref.watch(examMasterProvider).valueOrNull ?? ExamMasterData.empty;
    final subjects = subjectsForUser(master, actor);
    final chapters = master.chaptersFor(_subjectId);
    final isAdmin = actor.permissions.isAdminOrPrincipal;
    final isEdit = widget.existing != null;

    return ExamDialogFrame(
      title: isEdit ? 'Edit Question' : 'Add Question',
      icon: Icons.help_outline,
      maxWidth: 640,
      actions: [
        ExamCancelButton(onPressed: _busy ? null : () => Navigator.of(context).pop()),
        ExamPrimaryButton(label: 'Save Question', busy: _busy, onPressed: _save),
      ],
      child: !_loadedOptions
          ? const ExamLoading()
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ExamNotice(_error!),
                  ExamFieldRow(children: [
                    ExamDropdown<String>(
                      label: 'Subject *',
                      value: _subjectId,
                      hint: 'Select subject',
                      options: subjects.map((s) => ExamOption(s.id, subjectLabel(master, s))).toList(),
                      validator: (v) => v == null ? 'This field is required.' : null,
                      onChanged: (v) => setState(() {
                        _subjectId = v;
                        _topicId = null;
                      }),
                    ),
                    ExamDropdown<String?>(
                      label: 'Chapter',
                      value: _topicId,
                      options: [
                        const ExamOption<String?>(null, 'Not set'),
                        ...chapters.map((c) => ExamOption<String?>(c.id, c.title)),
                      ],
                      onChanged: (v) => setState(() => _topicId = v),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  ExamFieldRow(children: [
                    ExamDropdown<String>(
                      label: 'Question type *',
                      value: _type,
                      options: kQuestionTypes.map((t) => ExamOption(t, questionTypeLabel(t))).toList(),
                      onChanged: (v) => setState(() {
                        _type = v ?? 'MCQ';
                        if (_type == 'MCQ' && _opts.isEmpty) {
                          _opts.addAll([_OptRow(), _OptRow(), _OptRow(), _OptRow()]);
                        }
                      }),
                    ),
                    ExamTextField(
                      label: 'Marks *',
                      controller: _marks,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? 'Above 0' : null;
                      },
                    ),
                    ExamDropdown<String>(
                      label: 'Difficulty',
                      value: _level,
                      options: kDifficultyLevels.map((t) => ExamOption(t, t)).toList(),
                      onChanged: (v) => setState(() => _level = v ?? 'MEDIUM'),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  ExamTextField(
                    label: 'Question *',
                    controller: _text,
                    hint: 'Type the question here',
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'This field is required.' : null,
                  ),
                  const SizedBox(height: 14),
                  if (_type == 'MCQ') ...[
                    Row(children: [
                      const Expanded(
                        child: Text('Options (tick the correct ones)',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _opts.add(_OptRow())),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add option'),
                      ),
                    ]),
                    for (var i = 0; i < _opts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Checkbox(
                            value: _opts[i].correct,
                            onChanged: (v) => setState(() => _opts[i].correct = v ?? false),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _opts[i].text,
                              decoration: examInputDecoration(
                                context,
                                hint: 'Option ${String.fromCharCode(65 + i)}',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: _opts.length <= 2
                                ? null
                                : () => setState(() {
                                      _opts.removeAt(i).text.dispose();
                                    }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ]),
                      ),
                  ] else if (_type == 'TRUE_FALSE') ...[
                    const ExamLabel('Correct answer'),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('True')),
                        ButtonSegment(value: false, label: Text('False')),
                      ],
                      selected: {_trueAnswer},
                      onSelectionChanged: (v) => setState(() => _trueAnswer = v.first),
                    ),
                  ] else
                    ExamTextField(
                      label: 'Answer key (for the evaluator)',
                      controller: _answer,
                      hint: 'Expected answer or marking points',
                      maxLines: 3,
                    ),
                  const SizedBox(height: 14),
                  ExamDropdown<String>(
                    label: 'Status',
                    value: isAdmin ? _status : 'DRAFT',
                    options: const [ExamOption('DRAFT', 'Draft'), ExamOption('APPROVED', 'Approved')],
                    onChanged: isAdmin ? (v) => setState(() => _status = v ?? 'DRAFT') : null,
                  ),
                  if (!isAdmin)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Questions you save start as Draft. Admin approves them before they are used in exam papers.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
