import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_records_model.dart';
import '../../domain/examination_actor.dart';
import '../../domain/exam_schedule_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';
import 'hall_tickets_panel.dart' show kSchoolName;

String reportCardText({
  required ReportCard card,
  required ExamSchedule? exam,
  required ExamStudentInfo? student,
  required ExamMasterData master,
}) {
  final b = StringBuffer()
    ..writeln(kSchoolName)
    ..writeln('REPORT CARD - ${exam?.examName ?? card.examScheduleId} (${exam?.academicYear ?? ''})')
    ..writeln('Student: ${student?.name ?? card.studentId}   Roll: ${student?.rollNumber ?? '-'}')
    ..writeln('Class: ${master.sectionLabel(card.classSectionId)}')
    ..writeln('');
  for (final s in card.subjects) {
    b.writeln(
      '${s.subjectName}: ${s.absent ? 'AB' : examFmtMarks(s.marks)} / ${examFmtMarks(s.maxMarks)}  ${s.failed ? 'FAIL' : 'PASS'}',
    );
  }
  b
    ..writeln('')
    ..writeln('Total: ${examFmtMarks(card.totalMarks)} / ${examFmtMarks(card.totalMaxMarks)}')
    ..writeln('Percentage: ${card.percentage.toStringAsFixed(2)}%   Grade: ${card.grade}   GPA: ${examFmtMarks(card.gpa)}')
    ..writeln('Class rank: ${card.classRank}   Result: ${card.passed ? 'PASS' : 'FAIL'}');
  if (card.remarks.isNotEmpty) b.writeln('Remarks: ${card.remarks}');
  return b.toString();
}

/// Printable report card (Screen 7 review and Screen 8 student view).
class ReportCardView extends StatelessWidget {
  final ReportCard card;
  final ExamSchedule? exam;
  final ExamStudentInfo? student;
  final ExamMasterData master;
  const ReportCardView({
    super.key,
    required this.card,
    required this.exam,
    required this.student,
    required this.master,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111827);
    const muted = Color(0xFF6B7280);
    Widget cell(String t, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            t,
            style: TextStyle(fontSize: 12.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: ink, fontSize: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(kSchoolName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            Center(
              child: Text(
                'REPORT CARD - ${(exam?.examName ?? '').toUpperCase()} (${exam?.academicYear ?? ''})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kExamTeal),
              ),
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 24,
              runSpacing: 4,
              children: [
                Text('Student: ${student?.name ?? card.studentId}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Class: ${master.sectionLabel(card.classSectionId)}'),
                Text('Roll No: ${student?.rollNumber ?? '-'}'),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: const Color(0xFFD1D5DB)),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                    children: ['Subject', 'Marks', 'Max', 'Passing', 'Result']
                        .map((h) => cell(h, bold: true))
                        .toList(),
                  ),
                  for (final s in card.subjects)
                    TableRow(children: [
                      cell(s.subjectName),
                      cell(s.absent ? 'AB' : examFmtMarks(s.marks),
                          bold: true, color: s.failed ? Colors.red.shade700 : null),
                      cell(examFmtMarks(s.maxMarks)),
                      cell(examFmtMarks(s.passingMarks)),
                      cell(s.failed ? 'FAIL' : 'PASS',
                          bold: true, color: s.failed ? Colors.red.shade700 : const Color(0xFF047857)),
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric('Total', '${examFmtMarks(card.totalMarks)} / ${examFmtMarks(card.totalMaxMarks)}'),
                _metric('Percentage', '${card.percentage.toStringAsFixed(2)}%'),
                _metric('Grade', card.grade),
                _metric('GPA', examFmtMarks(card.gpa)),
                _metric('Class rank', '${card.classRank}'),
                _metric('Result', card.passed ? 'PASS' : 'FAIL',
                    color: card.passed ? const Color(0xFF047857) : Colors.red.shade700),
              ],
            ),
            if (card.remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Class in-charge remarks', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(card.remarks, style: const TextStyle(fontSize: 12.5, color: muted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String k, String v, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(k, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
            Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

Future<void> showReportCardDialog(
  BuildContext context, {
  required ReportCard card,
  required ExamSchedule? exam,
  required ExamStudentInfo? student,
  required ExamMasterData master,
  bool showStatus = false,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => ExamDialogFrame(
      title: 'Report Card',
      subtitle: student?.name,
      icon: Icons.assignment_outlined,
      maxWidth: 680,
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: reportCardText(card: card, exam: exam, student: student, master: master),
            ));
            showExamSnack(ctx, 'Report card copied. You can paste it to print or share.');
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy report card'),
        ),
        ExamPrimaryButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop()),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStatus) ...[
            Row(children: [
              const Text('Status: ', style: TextStyle(fontSize: 12.5)),
              ExamBadge(card.status),
            ]),
            if (card.status == 'SENT_BACK' && card.sendBackReason.isNotEmpty)
              ExamNotice('Sent back: ${card.sendBackReason}', warning: true),
            if (card.stale)
              const ExamNotice('Marks changed after this was calculated. Calculate again.', warning: true),
            const SizedBox(height: 8),
          ],
          ReportCardView(card: card, exam: exam, student: student, master: master),
        ],
      ),
    ),
  );
}

final _readinessProvider =
    FutureProvider.autoDispose.family<ResultReadiness, ExamSectionKey>((ref, key) async {
  ref.watch(examDataVersionProvider);
  final master = await ref.watch(examMasterProvider.future);
  return ref.watch(examResultRepositoryProvider).readiness(
        examId: key.examId,
        sectionId: key.sectionId,
        master: master,
      );
});

/// Screen 7: calculate results, approve report cards and publish them.
class ResultsPanel extends ConsumerStatefulWidget {
  final String? examId;
  const ResultsPanel({super.key, this.examId});

  @override
  ConsumerState<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends ConsumerState<ResultsPanel> {
  String? _sectionId;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      bumpExamData(ref);
      if (mounted) showExamSnack(context, done);
    } catch (e) {
      if (mounted) showExamSnack(context, examErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final examId = resolveExamId(ref, widget.examId);
    final masterAsync = ref.watch(examMasterProvider);
    final papersAsync = ref.watch(examPapersProvider(examId));
    final examsAsync = ref.watch(allExamsProvider);
    final bands = ref.watch(gradeScaleProvider).valueOrNull ?? const <GradeBand>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: 'Results & Report Cards',
          subtitle: perms.canManageResults
              ? 'Calculate total, percentage, grade, GPA and rank. Approve, then publish.'
              : 'Results of your class (read only).',
        ),
        if (widget.examId == null) ...[
          ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
          const SizedBox(height: 12),
        ],
        if (examId == null)
          const ExamEmpty(icon: Icons.assessment_outlined, message: 'Select an exam first.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => papersAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (papers) {
                var sectionIds = papers
                    .where((p) => !p.isCancelled)
                    .map((p) => p.classSectionId)
                    .whereType<String>()
                    .toSet()
                    .toList();
                if (perms.isClassIncharge) {
                  final mine = actorSectionId(actor, master);
                  sectionIds = sectionIds.where((s) => s == mine).toList();
                }
                if (sectionIds.isEmpty) {
                  return const ExamEmpty(
                    icon: Icons.event_busy,
                    message: 'No papers for your class in this exam.',
                  );
                }
                final sectionId = sectionIds.contains(_sectionId) ? _sectionId! : sectionIds.first;
                final exam = examsAsync.valueOrNull
                    ?.where((e) => e.examScheduleId == examId)
                    .firstOrNull;
                final key = (examId: examId, sectionId: sectionId);
                final readiness = ref.watch(_readinessProvider(key)).valueOrNull;
                final cards = ref
                        .watch(reportCardsProvider(
                            (examId: examId, sectionId: sectionId, studentId: null, published: false)))
                        .valueOrNull ??
                    const <ReportCard>[];
                return _body(context, master, exam, examId, sectionId, sectionIds, readiness, cards, bands, perms);
              },
            ),
          ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    ExamMasterData master,
    ExamSchedule? exam,
    String examId,
    String sectionId,
    List<String> sectionIds,
    ResultReadiness? readiness,
    List<ReportCard> cards,
    List<GradeBand> bands,
    ExaminationPermissions perms,
  ) {
    final actor = ref.read(currentExamActorProvider);
    final repo = ref.read(examResultRepositoryProvider);
    final manage = perms.canManageResults;
    final hasCards = cards.isNotEmpty;
    final anyStale = cards.any((c) => c.stale);
    final canApprove = cards.any((c) => c.status == 'PENDING_APPROVAL' || c.status == 'SENT_BACK') && !anyStale;
    final canPublish = cards.any((c) => c.status == 'APPROVED');
    final anyPublished = cards.any((c) => c.status == 'PUBLISHED');
    final passed = cards.where((c) => c.passed).length;
    final avg = hasCards ? cards.fold<double>(0, (a, c) => a + c.percentage) / cards.length : 0.0;
    final top = hasCards ? cards.map((c) => c.percentage).reduce((a, b) => a > b ? a : b) : 0.0;

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
              if (readiness == null)
                const LinearProgressIndicator()
              else if (readiness.ready)
                const ExamNotice('All subjects are reviewed. Results can be calculated.', info: true)
              else ...[
                const Text('Not ready to calculate yet:', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final p in readiness.pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('- $p', style: const TextStyle(fontSize: 12.5)),
                  ),
              ],
              if (anyStale)
                const ExamNotice(
                  'Marks changed after the results were calculated. Calculate the results again.',
                  warning: true,
                ),
              if (manage) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                      onPressed: _busy || readiness == null || !readiness.ready
                          ? null
                          : () async {
                              if (cards.any((c) => c.status == 'APPROVED' || c.status == 'PUBLISHED')) {
                                final ok = await confirmExam(
                                  context,
                                  title: 'Calculate again?',
                                  message:
                                      'Approved or published report cards of this class will go back to "pending approval" and be hidden from students and parents until approved again.',
                                  confirmText: 'Calculate again',
                                );
                                if (!ok) return;
                              }
                              await _run(() async {
                                final r = await repo.calculate(
                                  examId: examId,
                                  sectionId: sectionId,
                                  master: master,
                                  actor: actor,
                                );
                                if (mounted) {
                                  showExamSnack(
                                    context,
                                    '${r.studentsProcessed} report cards: ${r.passed} passed, ${r.failed} failed.',
                                  );
                                }
                              }, 'Results calculated.');
                            },
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: Text(hasCards ? 'Recalculate Results' : 'Calculate Results'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || !canApprove
                          ? null
                          : () => _run(
                                () => repo.approveSection(examId: examId, sectionId: sectionId, actor: actor),
                                'Report cards approved.',
                              ),
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Approve'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || !hasCards
                          ? null
                          : () async {
                              final reason = await askExamText(
                                context,
                                title: 'Send back for correction',
                                label: 'Reason *',
                                hint: 'e.g. Physics marks need a recheck',
                                confirmText: 'Send back',
                                danger: true,
                              );
                              if (reason == null) return;
                              await _run(
                                () => repo.sendBackSection(
                                  examId: examId,
                                  sectionId: sectionId,
                                  reason: reason,
                                  actor: actor,
                                ),
                                'Report cards sent back.',
                              );
                            },
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Send back'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: _busy || !canPublish
                          ? null
                          : () => _run(
                                () => repo.publishSection(examId: examId, sectionId: sectionId, actor: actor),
                                'Report cards published. Students and parents can see them now.',
                              ),
                      icon: const Icon(Icons.public, size: 18),
                      label: const Text('Publish'),
                    ),
                    if (anyPublished)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => repo.unpublishSection(examId: examId, sectionId: sectionId, actor: actor),
                                  'Report cards unpublished.',
                                ),
                        icon: const Icon(Icons.visibility_off_outlined, size: 18),
                        label: const Text('Unpublish'),
                      ),
                    if (hasCards)
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                final ok = await confirmExam(
                                  context,
                                  title: 'Delete report cards?',
                                  message:
                                      'Delete all ${cards.length} report cards of ${master.sectionLabel(sectionId)} for this exam? Marks are not deleted.',
                                  confirmText: 'Delete',
                                  danger: true,
                                );
                                if (!ok) return;
                                await _run(
                                  () => repo.deleteSectionCards(
                                      examId: examId, sectionId: sectionId, actor: actor),
                                  'Report cards deleted.',
                                );
                              },
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                        label: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (hasCards) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ExamBadge('Students: ${cards.length}', color: const Color(0xFF2563EB)),
              ExamBadge('Pass: ${(passed / cards.length * 100).toStringAsFixed(0)}%',
                  color: const Color(0xFF059669)),
              ExamBadge('Average: ${avg.toStringAsFixed(1)}%', color: const Color(0xFFD97706)),
              ExamBadge('Highest: ${top.toStringAsFixed(1)}%', color: const Color(0xFF7C3AED)),
            ],
          ),
          const SizedBox(height: 12),
          ExamTable(
            minWidth: 820,
            columns: const [
              'Rank',
              'Student',
              'Total',
              '%',
              'Grade',
              'GPA',
              'Result',
              'Status',
              'Action',
            ],
            rows: cards.map((c) {
              final st = master.studentById(c.studentId);
              return [
                Text('${c.classRank}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(st?.name ?? c.studentId, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${examFmtMarks(c.totalMarks)} / ${examFmtMarks(c.totalMaxMarks)}'),
                Text('${c.percentage.toStringAsFixed(2)}%'),
                Text(c.grade, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(examFmtMarks(c.gpa)),
                ExamBadge(c.passed ? 'PASS' : 'FAIL'),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  ExamBadge(c.status),
                  if (c.stale) ...[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: 'Marks changed after calculation',
                      child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                    ),
                  ],
                ]),
                ExamIconAction(
                  icon: Icons.visibility_outlined,
                  tooltip: 'View report card',
                  onPressed: () => showReportCardDialog(
                    context,
                    card: c,
                    exam: exam,
                    student: st,
                    master: master,
                    showStatus: true,
                  ),
                ),
              ];
            }).toList(),
          ),
        ] else
          const ExamEmpty(
            icon: Icons.assignment_outlined,
            message: 'No report cards yet. Calculate the results once all marks are reviewed.',
          ),
        const SizedBox(height: 12),
        ExamCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Grade scale', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: bands
                    .map((b) => ExamBadge(
                          '${b.grade}: ${examFmtMarks(b.minPercent)}%+  GPA ${examFmtMarks(b.gpaPoint)}',
                          color: const Color(0xFF475569),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              const Text(
                'Absent counts as 0 marks. A subject is failed when marks are below the passing marks. Equal totals share the same rank.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
