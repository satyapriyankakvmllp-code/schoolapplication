import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_planning_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';

/// Screen 9: syllabus & exam pattern.
class PatternPanel extends ConsumerWidget {
  const PatternPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final examId = ref.watch(selectedExamIdProvider);
    final masterAsync = ref.watch(examMasterProvider);
    final patternsAsync = ref.watch(patternsProvider(examId));
    final exams = ref.watch(allExamsProvider).valueOrNull ?? const <ExamSchedule>[];
    final exam = exams.where((e) => e.examScheduleId == examId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: 'Syllabus & Exam Pattern',
          subtitle: 'Chapters covered, marks per section and question types for each paper.',
          actions: [
            if (perms.canManagePatterns && examId != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                onPressed: () => PatternFormDialog.show(context, examId: examId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Pattern'),
              ),
          ],
        ),
        ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
        const SizedBox(height: 12),
        if (examId == null)
          const ExamEmpty(icon: Icons.rule_folder_outlined, message: 'Select an exam first.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => patternsAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (all) {
                var patterns = all;
                if (!perms.isAdminOrPrincipal && !perms.isTeacher) {
                  final sec = actorSectionId(actor, master);
                  patterns = patterns.where((p) => p.classSectionId == sec && p.isActive).toList();
                }
                if (patterns.isEmpty) {
                  return ExamEmpty(
                    icon: Icons.rule_folder_outlined,
                    message: perms.canManagePatterns
                        ? 'No pattern for ${exam?.examName ?? 'this exam'} yet. Create one for each subject paper.'
                        : 'The exam pattern has not been published yet.',
                  );
                }
                return Column(
                  children: patterns
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatternCard(pattern: p, master: master),
                          ))
                      .toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PatternCard extends ConsumerWidget {
  final ExamPattern pattern;
  final ExamMasterData master;
  const _PatternCard({required this.pattern, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(examinationPermissionsProvider);
    final p = pattern;
    return ExamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.patternName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(
                      '${master.subjectName(p.subjectId)} | ${master.sectionLabel(p.classSectionId)} | '
                      '${examFmtMarks(p.maxMarks)} marks | ${p.examDuration} min',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              ExamBadge(p.status),
              if (perms.canManagePatterns) ...[
                ExamIconAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  onPressed: () =>
                      PatternFormDialog.show(context, examId: p.examScheduleId, existing: p),
                ),
                ExamIconAction(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  color: Colors.red.shade600,
                  onPressed: () async {
                    final repo = ref.read(examPlanningRepositoryProvider);
                    final used = await repo.patternUsage(p.id);
                    if (!context.mounted) return;
                    final ok = await confirmExam(
                      context,
                      title: 'Delete pattern?',
                      message: used > 0
                          ? 'This pattern is used by $used question paper${used == 1 ? '' : 's'}. Deleting it removes them too.'
                          : 'Delete "${p.patternName}"?',
                      confirmText: 'Delete',
                      danger: true,
                    );
                    if (!ok) return;
                    try {
                      await repo.deletePattern(p.id, actor: ref.read(currentExamActorProvider));
                      bumpExamData(ref);
                    } catch (e) {
                      if (context.mounted) showExamSnack(context, examErrorText(e), error: true);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Text('Sections', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: p.sections
                .map((s) => ExamBadge(
                      '${s.sectionName}: ${s.noOfQuestions} x ${examFmtMarks(s.marksEach)} ${questionTypeLabel(s.questionType)}'
                      '${s.attemptCount != s.noOfQuestions ? ' (attempt ${s.attemptCount})' : ''}'
                      ' = ${examFmtMarks(s.totalMarks)}',
                      color: const Color(0xFF2563EB),
                    ))
                .toList(),
          ),
          if (p.topics.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Chapters (weightage)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: p.topics
                  .map((t) => ExamBadge(
                        '${t.topicTitle}: ${examFmtMarks(t.weightagePercent)}%',
                        color: const Color(0xFF7C3AED),
                      ))
                  .toList(),
            ),
          ],
          if (p.syllabusDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.syllabusDetails, style: const TextStyle(fontSize: 12.5)),
          ],
          if (p.activationProblems().isNotEmpty && perms.canManagePatterns) ...[
            const SizedBox(height: 10),
            ExamNotice(p.activationProblems().first, warning: true),
          ],
        ],
      ),
    );
  }
}

class _SecRow {
  final TextEditingController name;
  final TextEditingController count;
  final TextEditingController marks;
  final TextEditingController choice;
  String type;
  _SecRow({
    String name = '',
    String count = '',
    String marks = '',
    String choice = '0',
    this.type = 'MCQ',
  })  : name = TextEditingController(text: name),
        count = TextEditingController(text: count),
        marks = TextEditingController(text: marks),
        choice = TextEditingController(text: choice);

  void dispose() {
    name.dispose();
    count.dispose();
    marks.dispose();
    choice.dispose();
  }
}

class _TopicRow {
  String? topicId;
  final TextEditingController weight;
  _TopicRow({this.topicId, String weight = ''}) : weight = TextEditingController(text: weight);
  void dispose() => weight.dispose();
}

class PatternFormDialog extends ConsumerStatefulWidget {
  final String examId;
  final ExamPattern? existing;
  const PatternFormDialog({super.key, required this.examId, this.existing});

  static Future<void> show(BuildContext context, {required String examId, ExamPattern? existing}) {
    return showExamDialog<void>(
      context,
      (ctx) => PatternFormDialog(examId: examId, existing: existing),
    );
  }

  @override
  ConsumerState<PatternFormDialog> createState() => _PatternFormDialogState();
}

class _PatternFormDialogState extends ConsumerState<PatternFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _max;
  late final TextEditingController _duration;
  late final TextEditingController _details;
  String? _sectionId;
  String? _subjectId;
  String _status = 'DRAFT';
  final List<_SecRow> _secs = [];
  final List<_TopicRow> _tops = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.patternName ?? '');
    _max = TextEditingController(text: examFmtMarks(p?.maxMarks ?? 100));
    _duration = TextEditingController(text: '${p?.examDuration ?? 120}');
    _details = TextEditingController(text: p?.syllabusDetails ?? '');
    _sectionId = p?.classSectionId;
    _subjectId = p?.subjectId;
    _status = p?.status ?? 'DRAFT';
    for (final s in p?.sections ?? const <PatternSection>[]) {
      _secs.add(_SecRow(
        name: s.sectionName,
        count: '${s.noOfQuestions}',
        marks: examFmtMarks(s.marksEach),
        choice: '${s.choiceCount}',
        type: s.questionType,
      ));
    }
    for (final t in p?.topics ?? const <PatternTopic>[]) {
      _tops.add(_TopicRow(topicId: t.topicId, weight: examFmtMarks(t.weightagePercent)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    _duration.dispose();
    _details.dispose();
    for (final s in _secs) {
      s.dispose();
    }
    for (final t in _tops) {
      t.dispose();
    }
    super.dispose();
  }

  double get _sectionsTotal {
    var total = 0.0;
    for (final s in _secs) {
      final n = int.tryParse(s.count.text.trim()) ?? 0;
      final m = double.tryParse(s.marks.text.trim()) ?? 0;
      final c = int.tryParse(s.choice.text.trim()) ?? 0;
      final attempt = (c > 0 && c < n) ? c : n;
      total += attempt * m;
    }
    return total;
  }

  double get _weightTotal =>
      _tops.fold<double>(0, (a, t) => a + (double.tryParse(t.weight.text.trim()) ?? 0));

  void _preset() {
    setState(() {
      for (final s in _secs) {
        s.dispose();
      }
      _secs
        ..clear()
        ..addAll([
          _SecRow(name: 'Section A', count: '20', marks: '1', type: 'MCQ'),
          _SecRow(name: 'Section B', count: '10', marks: '3', type: 'SHORT'),
          _SecRow(name: 'Section C', count: '5', marks: '10', type: 'LONG'),
        ]);
      _max.text = '100';
    });
  }

  void _splitChapters(List<ExamChapterInfo> chapters) {
    if (chapters.isEmpty) return;
    setState(() {
      for (final t in _tops) {
        t.dispose();
      }
      _tops.clear();
      final each = 100 / chapters.length;
      var left = 100.0;
      for (var i = 0; i < chapters.length; i++) {
        final w = i == chapters.length - 1 ? left : double.parse(each.toStringAsFixed(1));
        left -= w;
        _tops.add(_TopicRow(topicId: chapters[i].id, weight: examFmtMarks(w)));
      }
    });
  }

  Future<void> _save(ExamMasterData master) async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final patternId = widget.existing?.id ?? '';
    final sections = _secs
        .map((s) => PatternSection(
              id: '',
              patternId: patternId,
              sectionName: s.name.text.trim(),
              questionType: s.type,
              noOfQuestions: int.tryParse(s.count.text.trim()) ?? 0,
              marksEach: double.tryParse(s.marks.text.trim()) ?? 0,
              choiceCount: int.tryParse(s.choice.text.trim()) ?? 0,
            ))
        .toList();
    final topics = _tops
        .where((t) => t.topicId != null)
        .map((t) => PatternTopic(
              id: '',
              patternId: patternId,
              topicId: t.topicId!,
              topicTitle: master.chapterById(t.topicId)?.title ?? t.topicId!,
              weightagePercent: double.tryParse(t.weight.text.trim()) ?? 0,
            ))
        .toList();
    setState(() => _busy = true);
    try {
      await ref.read(examPlanningRepositoryProvider).savePattern(
            ExamPattern(
              id: patternId,
              examScheduleId: widget.examId,
              classSectionId: _sectionId ?? '',
              subjectId: _subjectId ?? '',
              patternName: _name.text,
              maxMarks: double.tryParse(_max.text.trim()) ?? 0,
              examDuration: int.tryParse(_duration.text.trim()) ?? 0,
              syllabusDetails: _details.text,
              status: _status,
              createdAt: widget.existing?.createdAt ?? '',
              sections: sections,
              topics: topics,
            ),
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) {
        Navigator.of(context).pop();
        showExamSnack(context, 'Pattern saved.');
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
    final master = ref.watch(examMasterProvider).valueOrNull ?? ExamMasterData.empty;
    final subjects = master.subjectsForSection(_sectionId);
    final chapters = master.chaptersFor(_subjectId);
    final maxMarks = double.tryParse(_max.text.trim()) ?? 0;
    final secTotal = _sectionsTotal;
    final weightTotal = _weightTotal;
    final isEdit = widget.existing != null;

    return ExamDialogFrame(
      title: isEdit ? 'Edit Pattern' : 'New Exam Pattern',
      icon: Icons.rule_folder_outlined,
      maxWidth: 720,
      actions: [
        ExamCancelButton(onPressed: _busy ? null : () => Navigator.of(context).pop()),
        ExamPrimaryButton(label: 'Save Pattern', busy: _busy, onPressed: () => _save(master)),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ExamNotice(_error!),
            ExamFieldRow(children: [
              ExamDropdown<String>(
                label: 'Class - Section *',
                value: _sectionId,
                hint: 'Select class-section',
                options: master.sections
                    .map((s) => ExamOption(s.id, master.sectionLabel(s.id)))
                    .toList(),
                validator: (v) => v == null ? 'This field is required.' : null,
                onChanged: (v) => setState(() {
                  _sectionId = v;
                  _subjectId = null;
                }),
              ),
              ExamDropdown<String>(
                label: 'Subject *',
                value: _subjectId,
                hint: _sectionId == null ? 'Select class-section first' : 'Select subject',
                options: subjects.map((s) => ExamOption(s.id, s.name)).toList(),
                validator: (v) => v == null ? 'This field is required.' : null,
                onChanged: _sectionId == null
                    ? null
                    : (v) => setState(() {
                          _subjectId = v;
                          for (final t in _tops) {
                            t.dispose();
                          }
                          _tops.clear();
                        }),
              ),
            ]),
            const SizedBox(height: 14),
            ExamTextField(
              label: 'Pattern name *',
              controller: _name,
              hint: 'e.g. Physics Mid-Term Pattern',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required.' : null,
            ),
            const SizedBox(height: 14),
            ExamFieldRow(children: [
              ExamTextField(
                label: 'Max marks *',
                controller: _max,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return (n == null || n <= 0) ? 'Enter marks above 0.' : null;
                },
              ),
              ExamTextField(
                label: 'Duration (minutes) *',
                controller: _duration,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n <= 0) ? 'Enter minutes above 0.' : null;
                },
              ),
              ExamDropdown<String>(
                label: 'Status',
                value: _status,
                options: const [ExamOption('DRAFT', 'Draft'), ExamOption('ACTIVE', 'Active')],
                onChanged: (v) => setState(() => _status = v ?? 'DRAFT'),
              ),
            ]),
            const SizedBox(height: 14),
            ExamTextField(
              label: 'Syllabus details',
              controller: _details,
              hint: 'Extra notes about the syllabus',
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text('Sections', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                TextButton(onPressed: _preset, child: const Text('Use standard pattern')),
                TextButton.icon(
                  onPressed: () => setState(() => _secs.add(_SecRow(
                        name: 'Section ${String.fromCharCode(65 + _secs.length)}',
                        count: '5',
                        marks: '2',
                      ))),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add section'),
                ),
              ],
            ),
            for (var i = 0; i < _secs.length; i++) _sectionEditor(i),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: ExamBadge(
                'Sections total ${examFmtMarks(secTotal)} of ${examFmtMarks(maxMarks)} marks',
                status: (secTotal - maxMarks).abs() < 0.001 ? 'APPROVED' : 'CANCELLED',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text('Chapters (mixed modules)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                if (chapters.isNotEmpty)
                  TextButton(
                    onPressed: () => _splitChapters(chapters),
                    child: const Text('Add all, split evenly'),
                  ),
                TextButton.icon(
                  onPressed: chapters.isEmpty ? null : () => setState(() => _tops.add(_TopicRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add chapter'),
                ),
              ],
            ),
            if (_subjectId != null && chapters.isEmpty)
              const ExamNotice(
                'This subject has no chapters in the Classes curriculum yet. You can still save the pattern without chapters.',
                info: true,
              ),
            for (var i = 0; i < _tops.length; i++) _topicEditor(i, chapters),
            if (_tops.isNotEmpty)
              ExamBadge(
                'Weightage total ${examFmtMarks(weightTotal)}% (must be 100%)',
                status: (weightTotal - 100).abs() < 0.01 ? 'APPROVED' : 'CANCELLED',
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionEditor(int i) {
    final s = _secs[i];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        color: examIsDark(context) ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
      ),
      child: Column(
        children: [
          ExamFieldRow(children: [
            ExamTextField(
              label: 'Section name',
              controller: s.name,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            ExamDropdown<String>(
              label: 'Question type',
              value: s.type,
              options: kQuestionTypes.map((t) => ExamOption(t, questionTypeLabel(t))).toList(),
              onChanged: (v) => setState(() => s.type = v ?? 'MCQ'),
            ),
          ]),
          const SizedBox(height: 10),
          ExamFieldRow(children: [
            ExamTextField(
              label: 'No. of questions',
              controller: s.count,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'Above 0' : null;
              },
            ),
            ExamTextField(
              label: 'Marks each',
              controller: s.marks,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'Above 0' : null;
              },
            ),
            ExamTextField(
              label: 'Attempt any (0 = all)',
              controller: s.choice,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _secs.removeAt(i).dispose();
              }),
              icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade600),
              label: Text('Remove section', style: TextStyle(color: Colors.red.shade600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicEditor(int i, List<ExamChapterInfo> chapters) {
    final t = _tops[i];
    final taken = _tops.where((x) => x != t).map((x) => x.topicId).toSet();
    final options = chapters.where((c) => !taken.contains(c.id)).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: ExamDropdown<String>(
              label: 'Chapter',
              value: t.topicId,
              hint: 'Select chapter',
              options: options.map((c) => ExamOption(c.id, c.title)).toList(),
              onChanged: (v) => setState(() => t.topicId = v),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: ExamTextField(
              label: 'Weightage %',
              controller: t.weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => setState(() {
              _tops.removeAt(i).dispose();
            }),
            icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }
}
