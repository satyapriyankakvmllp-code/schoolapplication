import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_paper_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../../domain/examination_actor.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';

/// Screen 2: exam papers (the timetable).
class ExamPapersPanel extends ConsumerStatefulWidget {
  /// Set when shown inside Exam Details. Otherwise the shared selector is used.
  final String? examId;
  const ExamPapersPanel({super.key, this.examId});

  @override
  ConsumerState<ExamPapersPanel> createState() => _ExamPapersPanelState();
}

class _ExamPapersPanelState extends ConsumerState<ExamPapersPanel> {
  String? _sectionFilter;
  String? _subjectFilter;
  String? _statusFilter;

  Future<void> _addOrEdit(String examId, {ExamPaper? existing}) async {
    final saved = await ExamPaperFormDialog.show(context, examId: examId, existing: existing);
    if (saved == true && mounted) {
      showExamSnack(context, existing == null ? 'Paper added to the timetable.' : 'Paper updated.');
    }
  }

  Future<void> _delete(ExamPaper paper, ExamMasterData master) async {
    final actor = ref.read(currentExamActorProvider);
    final repo = ref.read(examPaperRepositoryProvider);
    final counts = await repo.linkedCounts(paper.id);
    final name = '${master.subjectName(paper.subjectId)} (${master.sectionLabel(paper.classSectionId)})';
    if (!mounted) return;
    final ok = await confirmExam(
      context,
      title: 'Delete paper?',
      confirmText: 'Delete',
      danger: true,
      message: counts.total > 0
          ? 'This paper has ${counts.summary()}. Deleting "$name" will remove all of them. This cannot be undone.'
          : 'Delete "$name" from the timetable? This cannot be undone.',
    );
    if (!ok) return;
    try {
      await repo.deletePaper(paper.id, actor: actor);
      bumpExamData(ref);
      if (mounted) showExamSnack(context, 'Paper deleted.');
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  Future<void> _cancel(ExamPaper paper, ExamMasterData master) async {
    final reason = await askExamText(
      context,
      title: 'Cancel paper',
      label: 'Reason for cancelling *',
      hint: 'e.g. Holiday declared',
      confirmText: 'Cancel paper',
      danger: true,
      message: '${master.subjectName(paper.subjectId)} (${master.sectionLabel(paper.classSectionId)}) will be marked as cancelled.',
    );
    if (reason == null) return;
    try {
      await ref
          .read(examPaperRepositoryProvider)
          .cancelPaper(paper.id, reason, actor: ref.read(currentExamActorProvider));
      bumpExamData(ref);
      if (mounted) showExamSnack(context, 'Paper cancelled.');
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  Future<void> _view(ExamPaper paper, ExamMasterData master) async {
    final counts = await ref.read(examPaperRepositoryProvider).linkedCounts(paper.id);
    if (!mounted) return;
    await showExamDialog<void>(
      context,
      (ctx) => ExamDialogFrame(
        title: '${master.subjectName(paper.subjectId)} paper',
        subtitle: master.sectionLabel(paper.classSectionId),
        icon: Icons.description_outlined,
        maxWidth: 480,
        actions: [ExamPrimaryButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop())],
        child: Column(
          children: [
            ExamInfoRow('Date', '${examFmtDate(paper.examDate)} ${examFmtDay(paper.examDate)}'),
            ExamInfoRow('Time', '${examFmtTime(paper.startTime)} to ${examFmtTime(paper.endTime)}'),
            ExamInfoRow('Room', master.roomName(paper.roomId)),
            ExamInfoRow('Invigilator', master.teacherName(paper.invigilatorId)),
            ExamInfoRow('Max marks', examFmtMarks(paper.maxMarks)),
            ExamInfoRow('Passing marks', examFmtMarks(paper.passingMarks)),
            ExamInfoRow('Status', paper.status, trailing: ExamBadge(paper.status)),
            if ((paper.cancelReason ?? '').isNotEmpty)
              ExamInfoRow('Cancel reason', paper.cancelReason!),
            if (counts.total > 0) ExamInfoRow('Linked data', counts.summary()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final examId = resolveExamId(ref, widget.examId);
    final masterAsync = ref.watch(examMasterProvider);
    final examsAsync = ref.watch(allExamsProvider);
    final papersAsync = ref.watch(examPapersProvider(examId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: 'Exam Papers (Timetable)',
          subtitle: 'Subject, date, time, room and invigilator for each paper.',
          actions: [
            if (perms.canManagePapers && examId != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                onPressed: () => _addOrEdit(examId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Paper'),
              ),
          ],
        ),
        if (widget.examId == null) ...[
          ExamCard(child: ExamSelector(where: (e) => true)),
          const SizedBox(height: 12),
        ],
        if (examId == null)
          const ExamEmpty(icon: Icons.event_note, message: 'Select an exam to see its timetable.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => papersAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (all) {
                final exam = examsAsync.valueOrNull
                    ?.where((e) => e.examScheduleId == examId)
                    .firstOrNull;
                var papers = scopePapers(all, actor, master);
                final sectionIds = papers.map((p) => p.classSectionId).whereType<String>().toSet();
                final subjectIds = papers.map((p) => p.subjectId).whereType<String>().toSet();
                papers = papers.where((p) {
                  if (_sectionFilter != null && p.classSectionId != _sectionFilter) return false;
                  if (_subjectFilter != null && p.subjectId != _subjectFilter) return false;
                  if (_statusFilter != null && p.status != _statusFilter) return false;
                  return true;
                }).toList();
                return _buildBody(context, exam, papers, sectionIds, subjectIds, master, perms);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExamSchedule? exam,
    List<ExamPaper> papers,
    Set<String> sectionIds,
    Set<String> subjectIds,
    ExamMasterData master,
    ExaminationPermissions perms,
  ) {
    final canManage = perms.canManagePapers;
    final examId = exam?.examScheduleId ?? widget.examId ?? ref.read(selectedExamIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exam != null && exam.isCancelled)
          const ExamNotice('This exam is cancelled.', warning: true),
        ExamCard(
          child: ExamFieldRow(
            children: [
              ExamDropdown<String?>(
                label: 'Class - Section',
                value: _sectionFilter,
                options: [
                  const ExamOption<String?>(null, 'All'),
                  ...sectionIds.map((s) => ExamOption<String?>(s, master.sectionLabel(s))),
                ],
                onChanged: (v) => setState(() => _sectionFilter = v),
              ),
              ExamDropdown<String?>(
                label: 'Subject',
                value: _subjectFilter,
                options: [
                  const ExamOption<String?>(null, 'All'),
                  ...subjectIds.map((s) => ExamOption<String?>(s, master.subjectName(s))),
                ],
                onChanged: (v) => setState(() => _subjectFilter = v),
              ),
              ExamDropdown<String?>(
                label: 'Status',
                value: _statusFilter,
                options: const [
                  ExamOption<String?>(null, 'All'),
                  ExamOption<String?>('SCHEDULED', 'Scheduled'),
                  ExamOption<String?>('ONGOING', 'Ongoing'),
                  ExamOption<String?>('COMPLETED', 'Completed'),
                  ExamOption<String?>('CANCELLED', 'Cancelled'),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (papers.isEmpty)
          ExamEmpty(
            icon: Icons.event_busy,
            message: canManage
                ? 'No papers scheduled yet. Add the first paper.'
                : 'No papers are scheduled for you in this exam yet.',
            action: canManage && examId != null
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                    onPressed: () => _addOrEdit(examId),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Paper'),
                  )
                : null,
          )
        else
          ExamTable(
            minWidth: 900,
            columns: [
              'Date',
              'Class - Section',
              'Subject',
              'Time',
              'Room',
              'Invigilator',
              if (!perms.isStudentOrParent) 'Marks (max / pass)',
              'Status',
              'Actions',
            ],
            rows: papers.map((p) {
              return [
                Text('${examFmtDate(p.examDate)}\n${examFmtDay(p.examDate)}',
                    style: const TextStyle(fontSize: 12.5)),
                Text(master.sectionLabel(p.classSectionId), style: const TextStyle(fontSize: 12.5)),
                Text(master.subjectName(p.subjectId),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text('${examFmtTime(p.startTime)} to\n${examFmtTime(p.endTime)}',
                    style: const TextStyle(fontSize: 12.5)),
                Text(master.roomName(p.roomId), style: const TextStyle(fontSize: 12.5)),
                Text(master.teacherName(p.invigilatorId), style: const TextStyle(fontSize: 12.5)),
                if (!perms.isStudentOrParent)
                  Text('${examFmtMarks(p.maxMarks)} / ${examFmtMarks(p.passingMarks)}',
                      style: const TextStyle(fontSize: 12.5)),
                ExamBadge(p.status),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExamIconAction(
                      icon: Icons.visibility_outlined,
                      tooltip: 'View',
                      onPressed: () => _view(p, master),
                    ),
                    if (canManage) ...[
                      ExamIconAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit',
                        onPressed: () => _addOrEdit(p.examScheduleId, existing: p),
                      ),
                      if (p.status == 'SCHEDULED' || p.status == 'ONGOING')
                        ExamIconAction(
                          icon: Icons.block,
                          tooltip: 'Cancel paper',
                          color: Colors.orange.shade700,
                          onPressed: () => _cancel(p, master),
                        ),
                      ExamIconAction(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        color: Colors.red.shade600,
                        onPressed: () => _delete(p, master),
                      ),
                    ],
                  ],
                ),
              ];
            }).toList(),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ADD / EDIT PAPER (dialog)
// ---------------------------------------------------------------------------
class ExamPaperFormDialog extends ConsumerStatefulWidget {
  final String examId;
  final ExamPaper? existing;
  const ExamPaperFormDialog({super.key, required this.examId, this.existing});

  static Future<bool?> show(BuildContext context, {required String examId, ExamPaper? existing}) {
    return showExamDialog<bool>(
      context,
      (ctx) => ExamPaperFormDialog(examId: examId, existing: existing),
    );
  }

  @override
  ConsumerState<ExamPaperFormDialog> createState() => _ExamPaperFormDialogState();
}

class _ExamPaperFormDialogState extends ConsumerState<ExamPaperFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _date;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _max;
  late final TextEditingController _pass;
  late final TextEditingController _reason;

  String? _sectionId;
  String? _subjectId;
  String? _roomId;
  String? _invigilatorId;
  String _status = 'SCHEDULED';
  bool _statusTouched = false;
  bool _busy = false;
  String? _error;
  PaperCheckResult _check = const PaperCheckResult();
  ExamMasterData _master = ExamMasterData.empty;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _date = TextEditingController(text: p?.examDate ?? '');
    _start = TextEditingController(text: p?.startTime ?? '09:30');
    _end = TextEditingController(text: p?.endTime ?? '12:00');
    _max = TextEditingController(text: examFmtMarks(p?.maxMarks ?? 100));
    _pass = TextEditingController(text: examFmtMarks(p?.passingMarks ?? 35));
    _reason = TextEditingController(text: p?.cancelReason ?? '');
    _sectionId = p?.classSectionId;
    _subjectId = p?.subjectId;
    _roomId = p?.roomId;
    _invigilatorId = p?.invigilatorId;
    _status = p?.status ?? 'SCHEDULED';
    WidgetsBinding.instance.addPostFrameCallback((_) => _liveCheck());
  }

  @override
  void dispose() {
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _max.dispose();
    _pass.dispose();
    _reason.dispose();
    super.dispose();
  }

  ExamPaper _draft() {
    final base = widget.existing;
    final date = _date.text.trim();
    final computed = ExamPaper.computeStatus(
      rawStatus: 'SCHEDULED',
      manual: false,
      examDate: date,
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
    );
    final bool manual;
    if (_status == 'CANCELLED') {
      manual = false;
    } else if (_statusTouched) {
      manual = _status != computed;
    } else {
      manual = base?.manualStatus ?? false;
    }
    return ExamPaper(
      id: base?.id ?? '',
      examScheduleId: widget.examId,
      classSectionId: _sectionId,
      subjectId: _subjectId,
      examDate: date.isEmpty ? null : date,
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
      maxMarks: double.tryParse(_max.text.trim()) ?? 0,
      passingMarks: double.tryParse(_pass.text.trim()) ?? 0,
      invigilatorId: _invigilatorId,
      roomId: _roomId,
      status: _statusTouched || base == null
          ? _status
          : ((base.manualStatus || base.isCancelled) ? base.status : computed),
      manualStatus: manual,
      cancelReason: _status == 'CANCELLED' ? _reason.text.trim() : null,
      createdAt: base?.createdAt ?? '',
      updatedAt: base?.updatedAt ?? '',
    );
  }

  Future<void> _liveCheck() async {
    if (!mounted) return;
    final repo = ref.read(examPaperRepositoryProvider);
    final draft = _draft();
    // Only check clashes once the basics are filled in.
    if ((draft.classSectionId ?? '').isEmpty ||
        (draft.subjectId ?? '').isEmpty ||
        (draft.examDate ?? '').isEmpty) {
      if (_check.errors.isNotEmpty || _check.warnings.isNotEmpty) {
        setState(() => _check = const PaperCheckResult());
      }
      return;
    }
    final result = await repo.check(draft, excludeId: widget.existing?.id, master: _master);
    if (mounted) setState(() => _check = result);
  }

  Future<void> _save({required bool addAnother}) async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final draft = _draft();
    if (_status == 'CANCELLED' && _reason.text.trim().isEmpty) {
      setState(() => _error = 'A cancellation reason is required.');
      return;
    }
    final result = await ref
        .read(examPaperRepositoryProvider)
        .check(draft, excludeId: widget.existing?.id, master: _master);
    if (result.hasErrors) {
      setState(() => _error = result.errors.first);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(examPaperRepositoryProvider).savePaper(
            draft,
            actor: ref.read(currentExamActorProvider),
            master: _master,
          );
      bumpExamData(ref);
      if (!mounted) return;
      if (addAnother) {
        showExamSnack(context, 'Paper saved. Add the next one.');
        setState(() {
          _busy = false;
          _subjectId = null;
          _date.clear();
          _check = const PaperCheckResult();
        });
      } else {
        Navigator.of(context).pop(true);
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
    final masterAsync = ref.watch(examMasterProvider);
    final exams = ref.watch(allExamsProvider).valueOrNull ?? const [];
    final exam = exams.where((e) => e.examScheduleId == widget.examId).firstOrNull;
    _master = masterAsync.valueOrNull ?? ExamMasterData.empty;
    final master = _master;
    final subjects = master.subjectsForSection(_sectionId);
    final computed = ExamPaper.computeStatus(
      rawStatus: 'SCHEDULED',
      manual: false,
      examDate: _date.text.trim(),
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
    );

    return ExamDialogFrame(
      title: _isEdit ? 'Edit Paper' : 'Add Exam Paper',
      subtitle: exam?.examName,
      icon: _isEdit ? Icons.edit_calendar : Icons.add_circle_outline,
      maxWidth: 620,
      actions: [
        ExamCancelButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false)),
        if (!_isEdit)
          OutlinedButton(
            onPressed: _busy ? null : () => _save(addAnother: true),
            child: const Text('Save & Add Another'),
          ),
        ExamPrimaryButton(
          label: _isEdit ? 'Save Changes' : 'Save Paper',
          busy: _busy,
          onPressed: () => _save(addAnother: false),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ExamNotice(_error!),
            for (final e in _check.errors)
              if (e != _error) ExamNotice(e),
            for (final w in _check.warnings) ExamNotice(w, warning: true),
            if (_isEdit && widget.existing!.isCompleted)
              const ExamNotice(
                'This paper is already completed. Changes may affect marks already entered.',
                warning: true,
              ),
            ExamTextField(
              label: 'Exam',
              controller: TextEditingController(text: exam?.examName ?? ''),
              enabled: false,
            ),
            const SizedBox(height: 14),
            ExamFieldRow(
              children: [
                ExamDropdown<String>(
                  label: 'Class - Section *',
                  value: _sectionId,
                  hint: 'Select class-section',
                  options: master.sections
                      .map((s) => ExamOption(s.id, master.sectionLabel(s.id)))
                      .toList(),
                  validator: (v) => v == null ? 'This field is required.' : null,
                  onChanged: (v) {
                    setState(() {
                      _sectionId = v;
                      _subjectId = null;
                    });
                    _liveCheck();
                  },
                ),
                ExamDropdown<String>(
                  label: 'Subject *',
                  value: _subjectId,
                  hint: _sectionId == null ? 'Select class-section first' : 'Select subject',
                  options: subjects.map((s) => ExamOption(s.id, s.name)).toList(),
                  validator: (v) => v == null ? 'This field is required.' : null,
                  onChanged: _sectionId == null
                      ? null
                      : (v) {
                          setState(() {
                            _subjectId = v;
                            final s = master.subjectById(v);
                            if (!_isEdit && s != null) {
                              _max.text = examFmtMarks(s.maxMarks);
                              _pass.text = examFmtMarks(s.passMarks);
                            }
                          });
                          _liveCheck();
                        },
                ),
              ],
            ),
            const SizedBox(height: 14),
            ExamDateField(
              label: 'Exam Date *',
              controller: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              validator: (v) => (v == null || v.isEmpty) ? 'This field is required.' : null,
              onPicked: (_) {
                setState(() {});
                _liveCheck();
              },
            ),
            const SizedBox(height: 14),
            ExamFieldRow(
              children: [
                ExamTimeField(
                  label: 'Start Time *',
                  controller: _start,
                  validator: (v) => (v == null || v.isEmpty) ? 'This field is required.' : null,
                  onPicked: (_) {
                    setState(() {});
                    _liveCheck();
                  },
                ),
                ExamTimeField(
                  label: 'End Time *',
                  controller: _end,
                  validator: (v) => (v == null || v.isEmpty) ? 'This field is required.' : null,
                  onPicked: (_) {
                    setState(() {});
                    _liveCheck();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            ExamFieldRow(
              children: [
                ExamTextField(
                  label: 'Max Marks *',
                  controller: _max,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    return (n == null || n <= 0) ? 'Enter marks above 0.' : null;
                  },
                  onChanged: (_) => _liveCheck(),
                ),
                ExamTextField(
                  label: 'Passing Marks *',
                  controller: _pass,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    final m = double.tryParse(_max.text.trim()) ?? 0;
                    if (n == null || n <= 0) return 'Enter marks above 0.';
                    if (n > m) return 'More than max marks.';
                    return null;
                  },
                  onChanged: (_) => _liveCheck(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ExamFieldRow(
              children: [
                ExamDropdown<String?>(
                  label: 'Classroom / Room',
                  value: _roomId,
                  options: [
                    const ExamOption<String?>(null, 'None (Unassigned)'),
                    ...master.rooms.map((r) => ExamOption<String?>(r.id, r.name)),
                  ],
                  onChanged: (v) {
                    setState(() => _roomId = v);
                    _liveCheck();
                  },
                ),
                ExamDropdown<String?>(
                  label: 'Invigilator',
                  value: _invigilatorId,
                  options: [
                    const ExamOption<String?>(null, 'None (Unassigned)'),
                    ...master.teachers.map((t) => ExamOption<String?>(t.id, t.name)),
                  ],
                  onChanged: (v) {
                    setState(() => _invigilatorId = v);
                    _liveCheck();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            ExamDropdown<String>(
              label: 'Status',
              value: (_statusTouched ||
                      (_isEdit &&
                          (widget.existing!.manualStatus || widget.existing!.isCancelled)))
                  ? _status
                  : computed,
              options: const [
                ExamOption('SCHEDULED', 'Scheduled'),
                ExamOption('ONGOING', 'Ongoing'),
                ExamOption('COMPLETED', 'Completed'),
                ExamOption('CANCELLED', 'Cancelled'),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _status = v;
                  _statusTouched = true;
                });
              },
            ),
            if (_status == 'CANCELLED') ...[
              const SizedBox(height: 14),
              ExamTextField(
                label: 'Reason for cancelling *',
                controller: _reason,
                hint: 'e.g. Holiday declared',
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
