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

/// Screen 6: marks review for the class in-charge (whole class, all subjects).
class MarksReviewPanel extends ConsumerStatefulWidget {
  final String? examId;
  const MarksReviewPanel({super.key, this.examId});

  @override
  ConsumerState<MarksReviewPanel> createState() => _MarksReviewPanelState();
}

class _MarksReviewPanelState extends ConsumerState<MarksReviewPanel> {
  String? _sectionId;

  Future<void> _approve(String examId, String sectionId, ExamMasterData master) async {
    final ok = await confirmExam(
      context,
      title: 'Approve marks for Admin?',
      message:
          'All subjects of ${master.sectionLabel(sectionId)} will be marked as reviewed and become ready for result calculation.',
      confirmText: 'Approve',
    );
    if (!ok) return;
    try {
      final n = await ref.read(examConductRepositoryProvider).approveSection(
            examId: examId,
            sectionId: sectionId,
            actor: ref.read(currentExamActorProvider),
            master: master,
          );
      bumpExamData(ref);
      if (mounted) showExamSnack(context, '$n subject${n == 1 ? '' : 's'} approved for Admin.');
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  Future<void> _flag(ExamPaper paper, ExamMasterData master) async {
    final comment = await askExamText(
      context,
      title: 'Send back ${master.subjectName(paper.subjectId)}',
      label: 'What needs to be corrected? *',
      hint: 'e.g. Marks of roll no 12 look wrong',
      confirmText: 'Send back',
      danger: true,
    );
    if (comment == null) return;
    try {
      await ref.read(examConductRepositoryProvider).flagCorrection(
            paperId: paper.id,
            comment: comment,
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) showExamSnack(context, 'Sent back to the subject teacher.');
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final examId = resolveExamId(ref, widget.examId);
    final masterAsync = ref.watch(examMasterProvider);
    final papersAsync = ref.watch(examPapersProvider(examId));
    final marksAsync = ref.watch(marksForExamProvider(examId));
    final attAsync = ref.watch(attendanceForExamProvider(examId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExamPanelHeader(
          title: 'Marks Review',
          subtitle: 'Check every subject of the class, send corrections back, add remarks and approve.',
        ),
        if (widget.examId == null) ...[
          ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
          const SizedBox(height: 12),
        ],
        if (examId == null)
          const ExamEmpty(icon: Icons.fact_check_outlined, message: 'Select an exam first.')
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
                final live = all.where((p) => !p.isCancelled).toList();
                var sectionIds = live.map((p) => p.classSectionId).whereType<String>().toSet().toList();
                if (perms.isClassIncharge) {
                  final mine = actorSectionId(actor, master);
                  sectionIds = sectionIds.where((s) => s == mine).toList();
                }
                if (sectionIds.isEmpty) {
                  return const ExamEmpty(
                    icon: Icons.event_busy,
                    message: 'No papers to review for your class in this exam.',
                  );
                }
                final sectionId = sectionIds.contains(_sectionId) ? _sectionId! : sectionIds.first;
                final papers = live.where((p) => p.classSectionId == sectionId).toList();
                final students = master.studentsForSection(sectionId);
                final conduct = ref.read(examConductRepositoryProvider);
                final summaries = {
                  for (final p in papers)
                    p.id: conduct.summarize(paper: p, students: students, marks: marks, attendance: att),
                };
                final remarks = ref
                        .watch(remarksProvider((examId: examId, sectionId: sectionId)))
                        .valueOrNull ??
                    const <StudentRemarks>[];
                final canReview = perms.canReviewMarks;
                final allReady = summaries.values.every(
                  (s) => s.status == 'SUBMITTED' || s.status == 'REVIEWED',
                );
                final allReviewed = summaries.values.every((s) => s.status == 'REVIEWED');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExamCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sectionIds.length > 1)
                            SectionDropdown(
                              sections: master.sections.where((s) => sectionIds.contains(s.id)).toList(),
                              master: master,
                              value: sectionId,
                              onChanged: (v) => setState(() => _sectionId = v),
                            )
                          else
                            Text(master.sectionLabel(sectionId),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          const Text('Subjects', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: papers.map((p) {
                              final s = summaries[p.id]!;
                              return Container(
                                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(master.subjectName(p.subjectId),
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    ExamBadge(s.status),
                                    if (canReview &&
                                        (s.status == 'SUBMITTED' || s.status == 'REVIEWED'))
                                      TextButton(
                                        onPressed: () => _flag(p, master),
                                        child: const Text('Send back', style: TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          if (canReview) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                                  onPressed: allReady ? () => _approve(examId, sectionId, master) : null,
                                  icon: const Icon(Icons.verified_outlined, size: 18),
                                  label: Text(allReviewed ? 'Approved for Admin' : 'Approve for Admin'),
                                ),
                                if (!allReady)
                                  const Text(
                                    'Every subject must be submitted first.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (students.isEmpty)
                      const ExamEmpty(icon: Icons.group_off, message: 'No enrolled students in this class-section.')
                    else
                      ExamTable(
                        minWidth: 640,
                        columns: [
                          'Roll',
                          'Student',
                          ...papers.map((p) => master.subjectName(p.subjectId)),
                          'Total',
                          '%',
                          'Remarks',
                        ],
                        rows: students.map((st) {
                          var total = 0.0;
                          var max = 0.0;
                          final cells = <Widget>[];
                          for (final p in papers) {
                            final absent = att.any(
                                (a) => a.examPaperId == p.id && a.studentId == st.id && a.isAbsent);
                            final m = marks
                                .where((x) => x.examPaperId == p.id && x.studentId == st.id)
                                .firstOrNull;
                            max += p.maxMarks;
                            if (absent) {
                              cells.add(Text('AB',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800, color: Colors.red.shade600)));
                            } else if (m?.marksObtained == null) {
                              cells.add(const Text('-'));
                            } else {
                              total += m!.marksObtained!;
                              final fail = m.marksObtained! < p.passingMarks;
                              cells.add(Text(
                                examFmtMarks(m.marksObtained!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: fail ? Colors.red.shade600 : null,
                                ),
                              ));
                            }
                          }
                          final rem = remarks.where((r) => r.studentId == st.id).firstOrNull;
                          return [
                            Text(st.rollNumber),
                            Text(st.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ...cells,
                            Text(examFmtMarks(total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(max > 0 ? '${(total / max * 100).toStringAsFixed(1)}%' : '-'),
                            canReview
                                ? TextButton.icon(
                                    onPressed: () => showStudentRemarksDialog(
                                      context,
                                      examId: examId,
                                      sectionId: sectionId,
                                      student: st,
                                      existing: rem,
                                    ),
                                    icon: Icon(
                                      rem == null ? Icons.add_comment_outlined : Icons.edit_note,
                                      size: 16,
                                    ),
                                    label: Text(rem == null ? 'Add' : 'Edit'),
                                  )
                                : Text(rem == null ? '-' : 'Added'),
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

Future<void> showStudentRemarksDialog(
  BuildContext context, {
  required String examId,
  required String sectionId,
  required ExamStudentInfo student,
  StudentRemarks? existing,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => _RemarksDialog(
      examId: examId,
      sectionId: sectionId,
      student: student,
      existing: existing,
    ),
  );
}

class _RemarksDialog extends ConsumerStatefulWidget {
  final String examId;
  final String sectionId;
  final ExamStudentInfo student;
  final StudentRemarks? existing;
  const _RemarksDialog({
    required this.examId,
    required this.sectionId,
    required this.student,
    this.existing,
  });

  @override
  ConsumerState<_RemarksDialog> createState() => _RemarksDialogState();
}

class _RemarksDialogState extends ConsumerState<_RemarksDialog> {
  late final TextEditingController _improvement;
  late final TextEditingController _remarks;
  String? _academic;
  String? _conduct;
  String? _participation;
  bool _busy = false;
  String? _error;

  static const _academicOptions = ['Excellent', 'Very Good', 'Good', 'Satisfactory', 'Needs Improvement'];
  static const _conductOptions = ['Excellent', 'Good', 'Satisfactory', 'Needs Attention'];
  static const _participationOptions = ['Very Good', 'Good', 'Average', 'Low'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _improvement = TextEditingController(text: e?.improvement ?? '');
    _remarks = TextEditingController(text: e?.remarks ?? '');
    _academic = (e?.academic ?? '').isEmpty ? null : e!.academic;
    _conduct = (e?.conduct ?? '').isEmpty ? null : e!.conduct;
    _participation = (e?.participation ?? '').isEmpty ? null : e!.participation;
  }

  @override
  void dispose() {
    _improvement.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(examConductRepositoryProvider).saveRemarks(
            StudentRemarks(
              id: '',
              examScheduleId: widget.examId,
              studentId: widget.student.id,
              classSectionId: widget.sectionId,
              academic: _academic ?? '',
              conduct: _conduct ?? '',
              participation: _participation ?? '',
              improvement: _improvement.text.trim(),
              remarks: _remarks.text.trim(),
            ),
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) {
        Navigator.of(context).pop();
        showExamSnack(context, 'Remarks saved.');
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
    return ExamDialogFrame(
      title: 'Remarks for ${widget.student.name}',
      subtitle: 'Roll ${widget.student.rollNumber}',
      icon: Icons.add_comment_outlined,
      maxWidth: 520,
      actions: [
        const ExamCancelButton(),
        ExamPrimaryButton(label: 'Save Remarks', busy: _busy, onPressed: _save),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ExamNotice(_error!),
          ExamDropdown<String>(
            label: 'Academic performance',
            value: _academic,
            hint: 'Select',
            options: _academicOptions.map((o) => ExamOption(o, o)).toList(),
            onChanged: (v) => setState(() => _academic = v),
          ),
          const SizedBox(height: 14),
          ExamFieldRow(
            children: [
              ExamDropdown<String>(
                label: 'Conduct',
                value: _conduct,
                hint: 'Select',
                options: _conductOptions.map((o) => ExamOption(o, o)).toList(),
                onChanged: (v) => setState(() => _conduct = v),
              ),
              ExamDropdown<String>(
                label: 'Participation',
                value: _participation,
                hint: 'Select',
                options: _participationOptions.map((o) => ExamOption(o, o)).toList(),
                onChanged: (v) => setState(() => _participation = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ExamTextField(
            label: 'Growth / improvement notes',
            controller: _improvement,
            hint: 'e.g. Needs more practice in problem solving',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          ExamTextField(
            label: 'Class in-charge remarks',
            controller: _remarks,
            hint: 'Overall comment shown on the report card',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
