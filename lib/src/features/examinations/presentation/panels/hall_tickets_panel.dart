import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_paper_model.dart';
import '../../domain/exam_records_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';

const String kSchoolName = 'EduPulse Public School & Senior College';

/// Plain-text version of a hall ticket (used by the Copy button).
String hallTicketText({
  required ExamSchedule exam,
  required HallTicket ticket,
  required ExamStudentInfo? student,
  required ExamMasterData master,
  required List<ExamPaper> papers,
}) {
  final b = StringBuffer()
    ..writeln(kSchoolName)
    ..writeln('HALL TICKET - ${exam.examName} (${exam.academicYear})')
    ..writeln('Hall Ticket No: ${ticket.hallTicketNumber}')
    ..writeln('Student: ${student?.name ?? ticket.studentId}   Roll: ${student?.rollNumber ?? '-'}')
    ..writeln('Class: ${master.sectionLabel(student?.sectionId)}')
    ..writeln('');
  for (final p in papers) {
    b.writeln(
      '${examFmtDate(p.examDate)} (${examFmtDay(p.examDate)})  ${master.subjectName(p.subjectId)}  '
      '${examFmtTime(p.startTime)}-${examFmtTime(p.endTime)}  ${master.roomName(p.roomId)}',
    );
  }
  return b.toString();
}

/// Printable hall ticket. Used by Screen 3 (admin) and Screen 8 (student).
class HallTicketView extends StatelessWidget {
  final ExamSchedule exam;
  final HallTicket ticket;
  final ExamStudentInfo? student;
  final ExamMasterData master;
  final List<ExamPaper> papers;

  const HallTicketView({
    super.key,
    required this.exam,
    required this.ticket,
    required this.student,
    required this.master,
    required this.papers,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111827);
    const muted = Color(0xFF6B7280);
    final rows = papers.where((p) => !p.isCancelled).toList();
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
              child: Text(
                kSchoolName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                'HALL TICKET - ${exam.examName.toUpperCase()} (${exam.academicYear})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kExamTeal),
              ),
            ),
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Student', student?.name ?? ticket.studentId),
                      _line('Class', master.sectionLabel(student?.sectionId)),
                      _line('Roll No', student?.rollNumber ?? '-'),
                      _line('Hall Ticket No', ticket.hallTicketNumber, bold: true),
                      _line('Issued on', examFmtDate(ticket.issueDate)),
                      if (!ticket.isIssued)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: ExamBadge('REVOKED', status: 'REVOKED'),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ExamQrPlaceholder(data: ticket.qrToken, size: 84),
                    const SizedBox(height: 2),
                    Text(ticket.qrToken, style: const TextStyle(fontSize: 8.5, color: muted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Exam timetable', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (rows.isEmpty)
              const Text('No papers scheduled yet.', style: TextStyle(color: muted))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(color: const Color(0xFFD1D5DB)),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                      children: ['Date', 'Day', 'Subject', 'Time', 'Room']
                          .map((h) => _cell(h, bold: true))
                          .toList(),
                    ),
                    for (final p in rows)
                      TableRow(children: [
                        _cell(examFmtDate(p.examDate)),
                        _cell(examFmtDay(p.examDate)),
                        _cell(master.subjectName(p.subjectId)),
                        _cell('${examFmtTime(p.startTime)} - ${examFmtTime(p.endTime)}'),
                        _cell(master.roomName(p.roomId)),
                      ]),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text('Instructions', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final t in const [
              'Bring this hall ticket to every paper.',
              'Reach the exam room 15 minutes before the start time.',
              'Mobile phones and notes are not allowed in the exam room.',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('- $t', style: const TextStyle(fontSize: 12, color: muted)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$k: ', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5)),
          TextSpan(
            text: v,
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13),
          ),
        ])),
      );

  Widget _cell(String t, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      );
}

Future<void> showHallTicketDialog(
  BuildContext context, {
  required ExamSchedule exam,
  required HallTicket ticket,
  required ExamStudentInfo? student,
  required ExamMasterData master,
  required List<ExamPaper> papers,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => ExamDialogFrame(
      title: 'Hall Ticket',
      subtitle: ticket.hallTicketNumber,
      icon: Icons.badge_outlined,
      maxWidth: 640,
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: hallTicketText(
                exam: exam,
                ticket: ticket,
                student: student,
                master: master,
                papers: papers,
              ),
            ));
            showExamSnack(ctx, 'Hall ticket copied. You can paste it to print or share.');
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy ticket'),
        ),
        ExamPrimaryButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop()),
      ],
      child: HallTicketView(
        exam: exam,
        ticket: ticket,
        student: student,
        master: master,
        papers: papers,
      ),
    ),
  );
}

/// Screen 3: hall tickets (admin generates, others view).
class HallTicketsPanel extends ConsumerStatefulWidget {
  final String? examId;
  const HallTicketsPanel({super.key, this.examId});

  @override
  ConsumerState<HallTicketsPanel> createState() => _HallTicketsPanelState();
}

class _HallTicketsPanelState extends ConsumerState<HallTicketsPanel> {
  String? _sectionFilter;

  Future<void> _generate(String examId, ExamMasterData master, List<ExamPaper> papers) async {
    final sections = papers.map((p) => p.classSectionId).whereType<String>().toSet().toList();
    if (sections.isEmpty) {
      showExamSnack(context, 'Add exam papers first. Hall tickets show the timetable.', error: true);
      return;
    }
    String? chosen = _sectionFilter != null && sections.contains(_sectionFilter)
        ? _sectionFilter
        : sections.first;
    final go = await showExamDialog<String>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final students = master.studentsForSection(chosen).length;
          return ExamDialogFrame(
            title: 'Generate Hall Tickets',
            icon: Icons.badge_outlined,
            maxWidth: 480,
            actions: [
              ExamCancelButton(onPressed: () => Navigator.of(ctx).pop()),
              ExamPrimaryButton(
                label: 'Generate',
                onPressed: chosen == null ? null : () => Navigator.of(ctx).pop(chosen),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExamDropdown<String>(
                  label: 'Class - Section',
                  value: chosen,
                  options: sections.map((s) => ExamOption(s, master.sectionLabel(s))).toList(),
                  onChanged: (v) => setLocal(() => chosen = v),
                ),
                const SizedBox(height: 10),
                Text(
                  '$students enrolled student${students == 1 ? '' : 's'} will get a ticket. '
                  'Students who already have one are skipped.',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (go == null) return;
    try {
      final r = await ref.read(examConductRepositoryProvider).generateHallTickets(
            examId: examId,
            sectionId: go,
            master: master,
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) {
        setState(() => _sectionFilter = go);
        showExamSnack(
          context,
          '${r.created} ticket${r.created == 1 ? '' : 's'} created'
          '${r.alreadyIssued > 0 ? ', ${r.alreadyIssued} already issued' : ''}.',
        );
      }
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
    final examsAsync = ref.watch(allExamsProvider);
    final ticketsAsync = ref.watch(hallTicketsProvider(examId));
    final papersAsync = ref.watch(examPapersProvider(examId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: 'Hall Tickets',
          subtitle: 'One ticket per student with the exam timetable.',
          actions: [
            if (perms.canManageHallTickets && examId != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                onPressed: () {
                  final m = masterAsync.valueOrNull;
                  final p = papersAsync.valueOrNull;
                  if (m != null && p != null) {
                    _generate(examId, m, p.where((x) => !x.isCancelled).toList());
                  }
                },
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Generate Hall Tickets'),
              ),
          ],
        ),
        if (widget.examId == null) ...[
          ExamCard(child: ExamSelector(where: (e) => true)),
          const SizedBox(height: 12),
        ],
        if (examId == null)
          const ExamEmpty(icon: Icons.badge_outlined, message: 'Select an exam to see its hall tickets.')
        else
          masterAsync.when(
            loading: () => const ExamLoading(),
            error: (e, _) => ExamErrorView(e),
            data: (master) => ticketsAsync.when(
              loading: () => const ExamLoading(),
              error: (e, _) => ExamErrorView(e),
              data: (all) {
                final exam = examsAsync.valueOrNull
                    ?.where((e) => e.examScheduleId == examId)
                    .firstOrNull;
                final papers = papersAsync.valueOrNull ?? const <ExamPaper>[];
                final mySection = actorSectionId(actor, master);
                var tickets = all.where((t) {
                  final st = master.studentById(t.studentId);
                  if (perms.isClassIncharge && st?.sectionId != mySection) return false;
                  if (_sectionFilter != null && st?.sectionId != _sectionFilter) return false;
                  return true;
                }).toList();
                final sectionIds = all
                    .map((t) => master.studentById(t.studentId)?.sectionId)
                    .whereType<String>()
                    .toSet();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionIds.length > 1 || _sectionFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExamCard(
                          child: ExamDropdown<String?>(
                            label: 'Class - Section',
                            value: _sectionFilter,
                            options: [
                              const ExamOption<String?>(null, 'All'),
                              ...sectionIds.map((s) => ExamOption<String?>(s, master.sectionLabel(s))),
                            ],
                            onChanged: (v) => setState(() => _sectionFilter = v),
                          ),
                        ),
                      ),
                    if (tickets.isEmpty)
                      ExamEmpty(
                        icon: Icons.badge_outlined,
                        message: perms.canManageHallTickets
                            ? 'No hall tickets yet. Click Generate Hall Tickets.'
                            : 'No hall tickets have been issued yet.',
                      )
                    else
                      ExamTable(
                        minWidth: 820,
                        columns: const [
                          'Hall Ticket No',
                          'Student',
                          'Roll',
                          'Class - Section',
                          'Issued',
                          'Status',
                          'Actions',
                        ],
                        rows: tickets.map((t) {
                          final st = master.studentById(t.studentId);
                          final studentPapers = papers
                              .where((p) => p.classSectionId == st?.sectionId)
                              .toList();
                          return [
                            Text(t.hallTicketNumber,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            Text(st?.name ?? t.studentId, style: const TextStyle(fontSize: 12.5)),
                            Text(st?.rollNumber ?? '-', style: const TextStyle(fontSize: 12.5)),
                            Text(master.sectionLabel(st?.sectionId),
                                style: const TextStyle(fontSize: 12.5)),
                            Text(examFmtDate(t.issueDate), style: const TextStyle(fontSize: 12.5)),
                            ExamBadge(t.status),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExamIconAction(
                                  icon: Icons.visibility_outlined,
                                  tooltip: 'Preview',
                                  onPressed: exam == null
                                      ? null
                                      : () => showHallTicketDialog(
                                            context,
                                            exam: exam,
                                            ticket: t,
                                            student: st,
                                            master: master,
                                            papers: studentPapers,
                                          ),
                                ),
                                if (perms.canManageHallTickets) ...[
                                  ExamIconAction(
                                    icon: t.isIssued ? Icons.block : Icons.restore,
                                    tooltip: t.isIssued ? 'Revoke' : 'Restore',
                                    color: Colors.orange.shade700,
                                    onPressed: () async {
                                      try {
                                        await ref.read(examConductRepositoryProvider).setHallTicketStatus(
                                              t.id,
                                              t.isIssued ? 'REVOKED' : 'ISSUED',
                                              actor: actor,
                                            );
                                        bumpExamData(ref);
                                      } catch (e) {
                                        if (context.mounted) {
                                          showExamSnack(context, examErrorText(e), error: true);
                                        }
                                      }
                                    },
                                  ),
                                  ExamIconAction(
                                    icon: Icons.delete_outline,
                                    tooltip: 'Delete',
                                    color: Colors.red.shade600,
                                    onPressed: () async {
                                      final ok = await confirmExam(
                                        context,
                                        title: 'Delete hall ticket?',
                                        message:
                                            'Delete ${t.hallTicketNumber} for ${st?.name ?? t.studentId}? You can generate it again later.',
                                        confirmText: 'Delete',
                                        danger: true,
                                      );
                                      if (!ok) return;
                                      try {
                                        await ref
                                            .read(examConductRepositoryProvider)
                                            .deleteHallTicket(t.id, actor: actor);
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
