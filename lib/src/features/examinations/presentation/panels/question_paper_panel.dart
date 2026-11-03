import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../data/question_paper_builder.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_paper_model.dart';
import '../../domain/exam_planning_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';

/// Screen 11: question paper builder and approval.
class QuestionPaperPanel extends ConsumerWidget {
  const QuestionPaperPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final examId = ref.watch(selectedExamIdProvider);
    final masterAsync = ref.watch(examMasterProvider);
    final papersAsync = ref.watch(examPapersProvider(examId));
    final patterns = ref.watch(patternsProvider(examId)).valueOrNull ?? const <ExamPattern>[];
    final qps = ref.watch(questionPapersProvider(null)).valueOrNull ?? const <QuestionPaper>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExamPanelHeader(
          title: 'Question Papers',
          subtitle: 'Build each paper from the question bank, check it against the pattern, then send it for approval.',
        ),
        ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
        const SizedBox(height: 12),
        if (examId == null)
          const ExamEmpty(icon: Icons.description_outlined, message: 'Select an exam first.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => papersAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (all) {
                final papers = scopePapers(all, actor, master).where((p) => !p.isCancelled).toList();
                if (papers.isEmpty) {
                  return const ExamEmpty(
                    icon: Icons.event_busy,
                    message: 'No papers for you in this exam.',
                  );
                }
                return ExamTable(
                  minWidth: 960,
                  columns: const [
                    'Date',
                    'Class - Section',
                    'Subject',
                    'Pattern',
                    'Question paper',
                    'Status',
                    'Actions',
                  ],
                  rows: papers.map((p) {
                    final pattern = patterns
                        .where((x) =>
                            x.examScheduleId == p.examScheduleId &&
                            x.classSectionId == p.classSectionId &&
                            x.subjectId == p.subjectId)
                        .firstOrNull;
                    final qp = qps.where((x) => x.examPaperId == p.id).firstOrNull;
                    return [
                      Text(examFmtDate(p.examDate), style: const TextStyle(fontSize: 12.5)),
                      Text(master.sectionLabel(p.classSectionId), style: const TextStyle(fontSize: 12.5)),
                      Text(master.subjectName(p.subjectId),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      pattern == null
                          ? const Text('No pattern', style: TextStyle(fontSize: 12.5, color: Colors.grey))
                          : Text(pattern.patternName, style: const TextStyle(fontSize: 12.5)),
                      Text(qp?.paperCode ?? 'Not created', style: const TextStyle(fontSize: 12.5)),
                      qp == null ? const ExamBadge('NOT_STARTED') : ExamBadge(qp.status),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (qp == null)
                            FilledButton.tonal(
                              onPressed: !perms.canWriteQuestions || pattern == null
                                  ? null
                                  : () async {
                                      try {
                                        final created = await ref
                                            .read(examPlanningRepositoryProvider)
                                            .createQuestionPaper(
                                              examPaper: p,
                                              pattern: pattern,
                                              actor: actor,
                                            );
                                        bumpExamData(ref);
                                        if (context.mounted) {
                                          await showQuestionPaperBuilder(
                                            context,
                                            examPaper: p,
                                            pattern: pattern,
                                            questionPaperId: created.id,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          showExamSnack(context, examErrorText(e), error: true);
                                        }
                                      }
                                    },
                              child: Text(pattern == null ? 'Needs pattern' : 'Create'),
                            )
                          else ...[
                            FilledButton.tonal(
                              onPressed: pattern == null
                                  ? null
                                  : () => showQuestionPaperBuilder(
                                        context,
                                        examPaper: p,
                                        pattern: pattern,
                                        questionPaperId: qp.id,
                                      ),
                              child: const Text('Open'),
                            ),
                            if (perms.isAdminOrPrincipal ||
                                (perms.isTeacher && qp.status == 'DRAFT'))
                              ExamIconAction(
                                icon: Icons.delete_outline,
                                tooltip: 'Delete',
                                color: Colors.red.shade600,
                                onPressed: () async {
                                  final ok = await confirmExam(
                                    context,
                                    title: 'Delete question paper?',
                                    message: 'Delete ${qp.paperCode}? The selected questions are removed from it.',
                                    confirmText: 'Delete',
                                    danger: true,
                                  );
                                  if (!ok) return;
                                  try {
                                    await ref
                                        .read(examPlanningRepositoryProvider)
                                        .deleteQuestionPaper(qp.id, actor: actor);
                                    bumpExamData(ref);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showExamSnack(context, examErrorText(e), error: true);
                                    }
                                  }
                                },
                              ),
                          ],
                        ],
                      ),
                    ];
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}

Future<void> showQuestionPaperBuilder(
  BuildContext context, {
  required ExamPaper examPaper,
  required ExamPattern pattern,
  required String questionPaperId,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => _BuilderDialog(
      examPaper: examPaper,
      pattern: pattern,
      questionPaperId: questionPaperId,
    ),
  );
}

class _BuilderDialog extends ConsumerStatefulWidget {
  final ExamPaper examPaper;
  final ExamPattern pattern;
  final String questionPaperId;
  const _BuilderDialog({
    required this.examPaper,
    required this.pattern,
    required this.questionPaperId,
  });

  @override
  ConsumerState<_BuilderDialog> createState() => _BuilderDialogState();
}

class _BuilderDialogState extends ConsumerState<_BuilderDialog> {
  QuestionPaper? _qp;
  List<QuestionPaperItem> _items = [];
  Map<String, Question> _bank = {};
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(examPlanningRepositoryProvider);
    final qps = await repo.getQuestionPapers(examPaperId: widget.examPaper.id);
    final qs = await repo.getQuestions(subjectId: widget.examPaper.subjectId);
    _qp = qps.where((q) => q.id == widget.questionPaperId).firstOrNull;
    _items = [...(_qp?.items ?? const <QuestionPaperItem>[])];
    _bank = {for (final q in qs) q.id: q};
    if (mounted) setState(() => _loaded = true);
  }

  bool get _canEdit {
    final qp = _qp;
    if (qp == null) return false;
    final p = ref.read(currentExamActorProvider).permissions;
    if (p.isAdminOrPrincipal) return qp.status != 'LOCKED';
    if (p.isTeacher) return qp.status == 'DRAFT' || qp.status == 'CORRECTION_REQUIRED';
    return false;
  }

  PaperPatternCheck get _check => QuestionPaperBuilder.evaluate(
        pattern: widget.pattern,
        items: _items,
        questions: _bank,
      );

  Future<void> _addTo(PatternSection sec) async {
    final used = _items.map((i) => i.questionId).toSet();
    final q = await showExamDialog<Question>(
      context,
      (ctx) => _PickerDialog(
        bank: _bank.values.toList(),
        section: sec,
        used: used,
        pattern: widget.pattern,
      ),
    );
    if (q == null) return;
    setState(() {
      _items = QuestionPaperBuilder.renumber([
        ..._items,
        QuestionPaperItem(
          id: '',
          questionPaperId: widget.questionPaperId,
          questionId: q.id,
          sectionName: sec.sectionName,
          questionNumber: 0,
          marks: sec.marksEach,
        ),
      ], widget.pattern);
    });
  }

  void _remove(QuestionPaperItem item) {
    setState(() {
      _items = QuestionPaperBuilder.renumber(
        _items.where((i) => !identical(i, item)).toList(),
        widget.pattern,
      );
    });
  }

  void _autoPick() {
    final before = _items.length;
    final picked = QuestionPaperBuilder.autoPick(
      pattern: widget.pattern,
      bank: _bank.values.toList(),
      existing: _items,
      questionPaperId: widget.questionPaperId,
      newId: () => '',
    );
    setState(() => _items = picked);
    final added = picked.length - before;
    showExamSnack(
      context,
      added > 0
          ? 'Added $added question${added == 1 ? '' : 's'} from the question bank.'
          : 'Nothing to add. The question bank has no more matching questions.',
    );
  }

  Future<bool> _saveItems() async {
    try {
      await ref.read(examPlanningRepositoryProvider).saveItems(
            questionPaperId: widget.questionPaperId,
            items: _items,
            actor: ref.read(currentExamActorProvider),
          );
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = examErrorText(e));
      return false;
    }
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      bumpExamData(ref);
      await _load();
      if (mounted && done != null) showExamSnack(context, done);
    } catch (e) {
      if (mounted) setState(() => _error = examErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(String status, {String comment = '', String? done}) {
    return _run(() async {
      final ok = _canEdit ? await _saveItems() : true;
      if (!ok) return;
      await ref.read(examPlanningRepositoryProvider).changePaperStatus(
            questionPaperId: widget.questionPaperId,
            newStatus: status,
            comment: comment,
            actor: ref.read(currentExamActorProvider),
            check: status == 'SUBMITTED' ? _check : null,
          );
    }, done: done);
  }

  @override
  Widget build(BuildContext context) {
    final master = ref.watch(examMasterProvider).valueOrNull ?? ExamMasterData.empty;
    final perms = ref.watch(examinationPermissionsProvider);
    final qp = _qp;
    final pattern = widget.pattern;
    final check = _loaded ? _check : const PaperPatternCheck();
    final status = qp?.status ?? 'DRAFT';
    final editable = _canEdit;
    final admin = perms.canApproveQuestionPapers;

    final actions = <Widget>[
      const ExamCancelButton(label: 'Close'),
      if (_loaded)
        OutlinedButton.icon(
          onPressed: () => showExamDialog<void>(
            context,
            (ctx) => _PreviewDialog(
              examPaper: widget.examPaper,
              pattern: pattern,
              items: _items,
              bank: _bank,
              master: master,
            ),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Preview'),
        ),
      if (_loaded && editable)
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await _saveItems();
                  }, done: 'Draft saved.'),
          child: const Text('Save Draft'),
        ),
      if (_loaded && editable && (status == 'DRAFT' || status == 'CORRECTION_REQUIRED'))
        ExamPrimaryButton(
          label: 'Submit for Review',
          icon: Icons.send,
          busy: _busy,
          onPressed: () => _changeStatus('SUBMITTED', done: 'Question paper submitted for review.'),
        ),
      if (_loaded && admin && status == 'SUBMITTED')
        OutlinedButton(
          onPressed: _busy ? null : () => _changeStatus('UNDER_REVIEW', done: 'Review started.'),
          child: const Text('Start Review'),
        ),
      if (_loaded && admin && (status == 'SUBMITTED' || status == 'UNDER_REVIEW' || status == 'APPROVED'))
        OutlinedButton(
          onPressed: _busy
              ? null
              : () async {
                  final c = await askExamText(
                    context,
                    title: 'Request correction',
                    label: 'What needs to change? *',
                    confirmText: 'Send back',
                    danger: true,
                  );
                  if (c != null) {
                    await _changeStatus('CORRECTION_REQUIRED', comment: c, done: 'Sent back to the teacher.');
                  }
                },
          child: const Text('Request Correction'),
        ),
      if (_loaded &&
          admin &&
          (status == 'SUBMITTED' || status == 'UNDER_REVIEW' || status == 'CORRECTION_REQUIRED'))
        ExamPrimaryButton(
          label: 'Approve',
          icon: Icons.verified_outlined,
          busy: _busy,
          onPressed: () => _changeStatus('APPROVED', done: 'Question paper approved.'),
        ),
      if (_loaded && admin && status == 'APPROVED')
        ExamPrimaryButton(
          label: 'Lock',
          icon: Icons.lock_outline,
          color: const Color(0xFF2563EB),
          busy: _busy,
          onPressed: () => _changeStatus('LOCKED', done: 'Question paper locked.'),
        ),
      if (_loaded && admin && (status == 'LOCKED' || status == 'APPROVED'))
        TextButton(
          onPressed: _busy ? null : () => _changeStatus('DRAFT', done: 'Moved back to draft.'),
          child: Text(status == 'LOCKED' ? 'Unlock' : 'Back to draft'),
        ),
    ];

    return ExamDialogFrame(
      title: '${master.subjectName(widget.examPaper.subjectId)} question paper',
      subtitle: '${master.sectionLabel(widget.examPaper.classSectionId)} | ${pattern.patternName}',
      icon: Icons.description_outlined,
      maxWidth: 820,
      actions: actions,
      child: !_loaded
          ? const ExamLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExamBadge(status),
                    if (qp != null) Text(qp.paperCode, style: const TextStyle(fontSize: 12.5)),
                    Text(
                      '${examFmtMarks(pattern.maxMarks)} marks | ${pattern.examDuration} min',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_error != null) ExamNotice(_error!),
                if (status == 'CORRECTION_REQUIRED' && (qp?.reviewComment ?? '').isNotEmpty)
                  ExamNotice('Correction requested: ${qp!.reviewComment}', warning: true),
                if (!editable)
                  ExamNotice(
                    status == 'LOCKED'
                        ? 'This paper is locked. Admin can unlock it.'
                        : 'This question paper cannot be edited at the moment (${status.replaceAll('_', ' ').toLowerCase()}).',
                    info: true,
                  ),
                if (editable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _autoPick,
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Auto-pick remaining questions'),
                      ),
                    ),
                  ),
                for (final sec in pattern.sections) _sectionCard(sec, check, editable, master),
                const SizedBox(height: 6),
                if (check.blockers.isEmpty)
                  const ExamNotice(
                    'The paper matches the pattern. It can be submitted.',
                    info: true,
                  )
                else ...[
                  const Text('Fix these before submitting:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  for (final b in check.blockers) ExamNotice(b),
                ],
                for (final w in check.warnings) ExamNotice(w, warning: true),
              ],
            ),
    );
  }

  Widget _sectionCard(
    PatternSection sec,
    PaperPatternCheck check,
    bool editable,
    ExamMasterData master,
  ) {
    final chosen = _items.where((i) => i.sectionName == sec.sectionName).toList();
    final done = chosen.length == sec.noOfQuestions;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: examIsDark(context) ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? Colors.green.shade300 : const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18, color: done ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${sec.sectionName}: ${questionTypeLabel(sec.questionType)}, '
                  '${sec.noOfQuestions} x ${examFmtMarks(sec.marksEach)} marks'
                  '${sec.attemptCount != sec.noOfQuestions ? ' (attempt any ${sec.attemptCount})' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              ExamBadge('${chosen.length} / ${sec.noOfQuestions}',
                  status: done ? 'APPROVED' : 'PENDING_APPROVAL'),
            ],
          ),
          const SizedBox(height: 8),
          for (final it in chosen)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: examIsDark(context) ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('Q${it.questionNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(
                      _bank[it.questionId]?.text ?? '(question removed)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Text(examFmtMarks(it.marks), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  if (editable)
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _remove(it),
                      icon: const Icon(Icons.close, size: 17),
                    ),
                ],
              ),
            ),
          if (editable && chosen.length < sec.noOfQuestions)
            TextButton.icon(
              onPressed: () => _addTo(sec),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add question'),
            ),
        ],
      ),
    );
  }
}

class _PickerDialog extends StatefulWidget {
  final List<Question> bank;
  final PatternSection section;
  final Set<String> used;
  final ExamPattern pattern;
  const _PickerDialog({
    required this.bank,
    required this.section,
    required this.used,
    required this.pattern,
  });

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  final _search = TextEditingController();
  String? _chapter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = widget.bank.where((x) {
      if (x.type != widget.section.questionType) return false;
      if (widget.used.contains(x.id)) return false;
      if (_chapter != null && x.topicId != _chapter) return false;
      if (q.isNotEmpty && !x.text.toLowerCase().contains(q)) return false;
      return true;
    }).toList()
      ..sort((a, b) => (b.isApproved ? 1 : 0).compareTo(a.isApproved ? 1 : 0));
    final chapters = widget.pattern.topics;

    return ExamDialogFrame(
      title: 'Add to ${widget.section.sectionName}',
      subtitle: '${questionTypeLabel(widget.section.questionType)} questions from the bank',
      icon: Icons.playlist_add,
      maxWidth: 640,
      actions: const [ExamCancelButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExamFieldRow(children: [
            ExamTextField(
              label: 'Search',
              controller: _search,
              hint: 'Search in question text',
              onChanged: (_) => setState(() {}),
            ),
            if (chapters.isNotEmpty)
              ExamDropdown<String?>(
                label: 'Chapter',
                value: _chapter,
                options: [
                  const ExamOption<String?>(null, 'All chapters'),
                  ...chapters.map((t) => ExamOption<String?>(t.topicId, t.topicTitle)),
                ],
                onChanged: (v) => setState(() => _chapter = v),
              ),
          ]),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const ExamEmpty(
              icon: Icons.quiz_outlined,
              message: 'No matching questions. Add more questions in the Question Bank.',
            )
          else
            for (final x in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: examIsDark(context) ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: ListTile(
                  onTap: () => Navigator.of(context).pop(x),
                  title: Text(x.text, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(spacing: 6, children: [
                      ExamBadge(x.difficulty, color: const Color(0xFF475569)),
                      ExamBadge(x.status),
                    ]),
                  ),
                  trailing: const Icon(Icons.add_circle_outline, color: kExamTeal),
                ),
              ),
        ],
      ),
    );
  }
}

String questionPaperText({
  required ExamPaper examPaper,
  required ExamPattern pattern,
  required List<QuestionPaperItem> items,
  required Map<String, Question> bank,
  required ExamMasterData master,
}) {
  final b = StringBuffer()
    ..writeln('${master.subjectName(examPaper.subjectId)} - ${master.sectionLabel(examPaper.classSectionId)}')
    ..writeln('Max marks: ${examFmtMarks(pattern.maxMarks)}    Time: ${pattern.examDuration} minutes')
    ..writeln('');
  for (final sec in pattern.sections) {
    b.writeln(
      '${sec.sectionName} (${sec.noOfQuestions} x ${examFmtMarks(sec.marksEach)} marks'
      '${sec.attemptCount != sec.noOfQuestions ? ', attempt any ${sec.attemptCount}' : ''})',
    );
    for (final it in items.where((i) => i.sectionName == sec.sectionName)) {
      final q = bank[it.questionId];
      b.writeln('${it.questionNumber}. ${q?.text ?? ''} [${examFmtMarks(it.marks)}]');
      if (q != null && q.type == 'MCQ') {
        for (var i = 0; i < q.options.length; i++) {
          b.writeln('   ${String.fromCharCode(97 + i)}) ${q.options[i].text}');
        }
      }
    }
    b.writeln('');
  }
  return b.toString();
}

class _PreviewDialog extends StatelessWidget {
  final ExamPaper examPaper;
  final ExamPattern pattern;
  final List<QuestionPaperItem> items;
  final Map<String, Question> bank;
  final ExamMasterData master;
  const _PreviewDialog({
    required this.examPaper,
    required this.pattern,
    required this.items,
    required this.bank,
    required this.master,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111827);
    return ExamDialogFrame(
      title: 'Question paper preview',
      icon: Icons.visibility_outlined,
      maxWidth: 680,
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: questionPaperText(
                examPaper: examPaper,
                pattern: pattern,
                items: items,
                bank: bank,
                master: master,
              ),
            ));
            showExamSnack(context, 'Question paper copied. You can paste it to print.');
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy as text'),
        ),
        ExamPrimaryButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
      ],
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF9CA3AF)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: ink, fontSize: 13, height: 1.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${master.subjectName(examPaper.subjectId)} - ${master.sectionLabel(examPaper.classSectionId)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Center(
                child: Text(
                  'Max marks: ${examFmtMarks(pattern.maxMarks)}    Time: ${pattern.examDuration} minutes',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Divider(height: 22),
              for (final sec in pattern.sections) ...[
                Text(
                  '${sec.sectionName}  (${sec.noOfQuestions} x ${examFmtMarks(sec.marksEach)} marks'
                  '${sec.attemptCount != sec.noOfQuestions ? ', attempt any ${sec.attemptCount}' : ''})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final it in items.where((i) => i.sectionName == sec.sectionName)) ...[
                  Text('${it.questionNumber}. ${bank[it.questionId]?.text ?? ''}  [${examFmtMarks(it.marks)}]'),
                  if (bank[it.questionId]?.type == 'MCQ')
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 2, bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < bank[it.questionId]!.options.length; i++)
                            Text('${String.fromCharCode(97 + i)}) ${bank[it.questionId]!.options[i].text}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
