import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_paper_model.dart';
import '../../domain/exam_records_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';

/// Screen 5: marks entry (subject teacher). Admin can edit marks any time.
class MarksEntryPanel extends ConsumerWidget {
  final String? examId;
  const MarksEntryPanel({super.key, this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final id = resolveExamId(ref, examId);
    final masterAsync = ref.watch(examMasterProvider);
    final papersAsync = ref.watch(examPapersProvider(id));
    final marksAsync = ref.watch(marksForExamProvider(id));
    final attAsync = ref.watch(attendanceForExamProvider(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: perms.isAdminOrPrincipal ? 'Marks Monitoring & Entry' : 'My Exam Papers - Marks Entry',
          subtitle: perms.isAdminOrPrincipal
              ? 'See the marks status of every paper. Admin can edit marks at any time.'
              : 'Enter marks for the papers of your subject, then submit them.',
        ),
        if (examId == null) ...[
          ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
          const SizedBox(height: 12),
        ],
        if (id == null)
          const ExamEmpty(icon: Icons.edit_note, message: 'Select an exam first.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => papersAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (all) {
                final marks = marksAsync.valueOrNull ?? const <ExamMark>[];
                final att = attAsync.valueOrNull ?? const <ExamAttendance>[];
                final papers = scopePapers(all, actor, master).where((p) => !p.isCancelled).toList();
                if (papers.isEmpty) {
                  return ExamEmpty(
                    icon: Icons.edit_off,
                    message: perms.isAdminOrPrincipal
                        ? 'No papers in this exam yet. Add papers in the timetable first.'
                        : 'No papers of your subject in this exam.',
                  );
                }
                final conduct = ref.read(examConductRepositoryProvider);
                return ExamTable(
                  minWidth: 900,
                  columns: const [
                    'Date',
                    'Class - Section',
                    'Subject',
                    'Subject teacher',
                    'Students',
                    'Marks entered',
                    'Absent',
                    'Status',
                    'Action',
                  ],
                  rows: papers.map((p) {
                    final students = master.studentsForSection(p.classSectionId);
                    final s = conduct.summarize(
                      paper: p,
                      students: students,
                      marks: marks,
                      attendance: att,
                    );
                    final locked = s.status == 'SUBMITTED' || s.status == 'REVIEWED';
                    final canEdit = perms.canEnterMarks && (perms.isAdminOrPrincipal || !locked);
                    final label = !perms.canEnterMarks
                        ? 'View'
                        : (locked && !perms.isAdminOrPrincipal
                            ? 'View'
                            : (perms.isAdminOrPrincipal && locked ? 'Edit' : 'Enter marks'));
                    return [
                      Text('${examFmtDate(p.examDate)}\n${examFmtDay(p.examDate)}',
                          style: const TextStyle(fontSize: 12.5)),
                      Text(master.sectionLabel(p.classSectionId), style: const TextStyle(fontSize: 12.5)),
                      Text(master.subjectName(p.subjectId),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text(master.teacherName(master.subjectById(p.subjectId)?.teacherId),
                          style: const TextStyle(fontSize: 12.5)),
                      Text('${students.length}', style: const TextStyle(fontSize: 12.5)),
                      Text('${s.entered} / ${s.expected}', style: const TextStyle(fontSize: 12.5)),
                      Text('${s.absent}', style: const TextStyle(fontSize: 12.5)),
                      ExamBadge(s.status),
                      FilledButton.tonal(
                        onPressed: () => showMarksEntryDialog(
                          context,
                          paper: p,
                          master: master,
                          canEdit: canEdit,
                        ),
                        child: Text(label),
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

Future<void> showMarksEntryDialog(
  BuildContext context, {
  required ExamPaper paper,
  required ExamMasterData master,
  required bool canEdit,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => _MarksEntryDialog(paper: paper, master: master, canEdit: canEdit),
  );
}

class _MarksEntryDialog extends ConsumerStatefulWidget {
  final ExamPaper paper;
  final ExamMasterData master;
  final bool canEdit;
  const _MarksEntryDialog({required this.paper, required this.master, required this.canEdit});

  @override
  ConsumerState<_MarksEntryDialog> createState() => _MarksEntryDialogState();
}

class _MarksEntryDialogState extends ConsumerState<_MarksEntryDialog> {
  final Map<String, TextEditingController> _marks = {};
  final Map<String, TextEditingController> _remarks = {};
  final Set<String> _absent = {};
  final Map<String, String?> _errors = {};
  bool _loaded = false;
  bool _busy = false;
  String? _error;
  String _status = 'NOT_STARTED';
  String _correction = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._marks.values, ..._remarks.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final conduct = ref.read(examConductRepositoryProvider);
    final marks = await conduct.getMarks(paperId: widget.paper.id);
    final att = await conduct.getAttendance(paperId: widget.paper.id);
    final students = widget.master.studentsForSection(widget.paper.classSectionId);
    for (final a in att.where((a) => a.isAbsent)) {
      _absent.add(a.studentId);
    }
    for (final s in students) {
      final m = marks.where((x) => x.studentId == s.id).firstOrNull;
      _marks[s.id] = TextEditingController(
        text: m?.marksObtained == null ? '' : examFmtMarks(m!.marksObtained!),
      );
      _remarks[s.id] = TextEditingController(text: m?.remarks ?? '');
      if ((m?.correctionComment ?? '').isNotEmpty) _correction = m!.correctionComment;
    }
    _status = conduct
        .summarize(paper: widget.paper, students: students, marks: marks, attendance: att)
        .status;
    if (mounted) setState(() => _loaded = true);
  }

  List<MarkInput>? _collect() {
    _errors.clear();
    var ok = true;
    final out = <MarkInput>[];
    for (final entry in _marks.entries) {
      if (_absent.contains(entry.key)) continue;
      final t = entry.value.text.trim();
      double? v;
      if (t.isNotEmpty) {
        v = double.tryParse(t);
        if (v == null) {
          _errors[entry.key] = 'Numbers only';
          ok = false;
        } else if (v < 0 || v > widget.paper.maxMarks) {
          _errors[entry.key] = '0 to ${examFmtMarks(widget.paper.maxMarks)}';
          ok = false;
        }
      }
      out.add(MarkInput(
        studentId: entry.key,
        marks: v,
        remarks: _remarks[entry.key]?.text.trim() ?? '',
      ));
    }
    setState(() {});
    return ok ? out : null;
  }

  Future<void> _save({required bool submit}) async {
    setState(() => _error = null);
    final inputs = _collect();
    if (inputs == null) {
      setState(() => _error = 'Please fix the marks shown in red.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(examConductRepositoryProvider).saveMarks(
            paper: widget.paper,
            inputs: inputs,
            submit: submit,
            actor: ref.read(currentExamActorProvider),
            master: widget.master,
          );
      bumpExamData(ref);
      if (mounted) {
        Navigator.of(context).pop();
        showExamSnack(context, submit ? 'Marks submitted for review.' : 'Marks saved.');
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
    final paper = widget.paper;
    final master = widget.master;
    final perms = ref.watch(examinationPermissionsProvider);
    final students = master.studentsForSection(paper.classSectionId);
    final locked = _status == 'SUBMITTED' || _status == 'REVIEWED';
    final editable = widget.canEdit && (perms.isAdminOrPrincipal || !locked);
    final wide = MediaQuery.sizeOf(context).width > 640;

    return ExamDialogFrame(
      title: '${master.subjectName(paper.subjectId)} marks',
      subtitle:
          '${master.sectionLabel(paper.classSectionId)} | Max ${examFmtMarks(paper.maxMarks)} | Pass ${examFmtMarks(paper.passingMarks)}',
      icon: Icons.edit_note,
      maxWidth: 760,
      actions: [
        ExamCancelButton(label: editable ? 'Cancel' : 'Close'),
        if (editable && locked)
          ExamPrimaryButton(
            label: 'Save Changes',
            busy: _busy,
            onPressed: () => _save(submit: false),
          ),
        if (editable && !locked) ...[
          OutlinedButton(
            onPressed: _busy ? null : () => _save(submit: false),
            child: const Text('Save Draft'),
          ),
          ExamPrimaryButton(
            label: 'Submit Marks',
            busy: _busy,
            icon: Icons.send,
            onPressed: () => _save(submit: true),
          ),
        ],
      ],
      child: !_loaded
          ? const ExamLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Status: ', style: TextStyle(fontSize: 12.5)),
                  ExamBadge(_status),
                ]),
                const SizedBox(height: 10),
                if (_error != null) ExamNotice(_error!),
                if (_status == 'CORRECTION_REQUIRED' && _correction.isNotEmpty)
                  ExamNotice('Correction requested: $_correction', warning: true),
                if (!editable && locked && !perms.isAdminOrPrincipal)
                  const ExamNotice(
                    'Marks are submitted. Ask the Class In-charge to send them back if you need to change them.',
                    info: true,
                  ),
                if (perms.isAdminOrPrincipal && locked)
                  const ExamNotice(
                    'Marks are already submitted. Changing them marks the report cards of this class as outdated.',
                    warning: true,
                  ),
                if (students.isEmpty)
                  const ExamEmpty(icon: Icons.group_off, message: 'No enrolled students in this class-section.')
                else
                  ...students.map((s) {
                    final absent = _absent.contains(s.id);
                    final markField = SizedBox(
                      width: 96,
                      child: absent
                          ? Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Text('AB',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800, color: Colors.red.shade600)),
                            )
                          : TextFormField(
                              controller: _marks[s.id],
                              enabled: editable,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              decoration: examInputDecoration(
                                context,
                                hint: '0',
                                enabled: editable,
                              ).copyWith(errorText: _errors[s.id], errorStyle: const TextStyle(fontSize: 10)),
                            ),
                    );
                    final remarkField = TextFormField(
                      controller: _remarks[s.id],
                      enabled: editable && !absent,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: examInputDecoration(
                        context,
                        hint: absent ? 'Absent' : 'Remarks (optional)',
                        enabled: editable && !absent,
                      ),
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: examIsDark(context) ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(s.rollNumber,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(s.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                markField,
                                const SizedBox(width: 10),
                                Expanded(flex: 3, child: remarkField),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${s.rollNumber}.  ',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Expanded(
                                      child: Text(s.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    markField,
                                  ],
                                ),
                                const SizedBox(height: 8),
                                remarkField,
                              ],
                            ),
                    );
                  }),
              ],
            ),
    );
  }
}
