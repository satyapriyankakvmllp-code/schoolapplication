import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_scope.dart';
import '../../application/examination_access.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_records_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../widgets/exam_selectors.dart';
import '../widgets/exam_ui.dart';
import 'hall_tickets_panel.dart';
import 'results_panel.dart';

/// Screen 8: what a student or parent sees. Read only.
class MyExamsPanel extends ConsumerStatefulWidget {
  const MyExamsPanel({super.key});

  @override
  ConsumerState<MyExamsPanel> createState() => _MyExamsPanelState();
}

class _MyExamsPanelState extends ConsumerState<MyExamsPanel> {
  String _tab = 'Timetable';
  static const _tabs = ['Timetable', 'Hall Ticket', 'Report Cards', 'Performance'];

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final masterAsync = ref.watch(examMasterProvider);
    final isParent = actor.permissions.isParent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamPanelHeader(
          title: isParent ? 'My Child\'s Exams' : 'My Exams',
          subtitle: 'Timetable, hall ticket, report cards and progress.',
        ),
        masterAsync.when(
          loading: () => const ExamLoading(),
          error: (e, _) => ExamErrorView(e),
          data: (master) {
            final student = master.studentById(actor.studentId);
            if (student == null) {
              return const ExamEmpty(
                icon: Icons.person_off_outlined,
                message: 'No student is linked to this login yet.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExamCard(
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, color: kExamTeal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text('${master.sectionLabel(student.sectionId)} | Roll ${student.rollNumber}',
                                style: const TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tabs
                      .map((t) => ChoiceChip(
                            label: Text(t),
                            selected: _tab == t,
                            selectedColor: kExamTeal.withValues(alpha: 0.2),
                            onSelected: (_) => setState(() => _tab = t),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (_tab == 'Timetable') _Timetable(student: student, master: master),
                if (_tab == 'Hall Ticket') _MyHallTicket(student: student, master: master),
                if (_tab == 'Report Cards') _MyReportCards(student: student, master: master),
                if (_tab == 'Performance') _Performance(student: student, master: master),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Timetable extends ConsumerWidget {
  final ExamStudentInfo student;
  final ExamMasterData master;
  const _Timetable({required this.student, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examId = ref.watch(selectedExamIdProvider);
    final papers = (ref.watch(examPapersProvider(examId)).valueOrNull ?? const [])
        .where((p) => p.classSectionId == student.sectionId && !p.isCancelled)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
        const SizedBox(height: 12),
        if (examId == null)
          const ExamEmpty(icon: Icons.event_note, message: 'Select an exam.')
        else if (papers.isEmpty)
          const ExamEmpty(icon: Icons.event_busy, message: 'The timetable for this exam is not ready yet.')
        else
          ExamTable(
            minWidth: 560,
            columns: const ['Date', 'Day', 'Subject', 'Time', 'Room'],
            rows: papers
                .map((p) => [
                      Text(examFmtDate(p.examDate)),
                      Text(examFmtDay(p.examDate)),
                      Text(master.subjectName(p.subjectId),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${examFmtTime(p.startTime)} to ${examFmtTime(p.endTime)}'),
                      Text(master.roomName(p.roomId)),
                    ])
                .toList(),
          ),
      ],
    );
  }
}

class _MyHallTicket extends ConsumerWidget {
  final ExamStudentInfo student;
  final ExamMasterData master;
  const _MyHallTicket({required this.student, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examId = ref.watch(selectedExamIdProvider);
    final exam = ref
        .watch(allExamsProvider)
        .valueOrNull
        ?.where((e) => e.examScheduleId == examId)
        .firstOrNull;
    final ticket = (ref.watch(hallTicketsProvider(examId)).valueOrNull ?? const <HallTicket>[])
        .where((t) => t.studentId == student.id && t.isIssued)
        .firstOrNull;
    final papers = (ref.watch(examPapersProvider(examId)).valueOrNull ?? const [])
        .where((p) => p.classSectionId == student.sectionId)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamCard(child: ExamSelector(where: (e) => !e.isCancelled)),
        const SizedBox(height: 12),
        if (exam == null)
          const ExamEmpty(icon: Icons.badge_outlined, message: 'Select an exam.')
        else if (ticket == null)
          const ExamEmpty(
            icon: Icons.badge_outlined,
            message: 'Your hall ticket has not been issued yet. Please check again later.',
          )
        else ...[
          HallTicketView(
            exam: exam,
            ticket: ticket,
            student: student,
            master: master,
            papers: papers,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showHallTicketDialog(
              context,
              exam: exam,
              ticket: ticket,
              student: student,
              master: master,
              papers: papers,
            ),
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print / copy'),
          ),
        ],
      ],
    );
  }
}

class _MyReportCards extends ConsumerWidget {
  final ExamStudentInfo student;
  final ExamMasterData master;
  const _MyReportCards({required this.student, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref
            .watch(reportCardsProvider(
                (examId: null, sectionId: null, studentId: student.id, published: true)))
            .valueOrNull ??
        const <ReportCard>[];
    final exams = ref.watch(allExamsProvider).valueOrNull ?? const <ExamSchedule>[];
    if (cards.isEmpty) {
      return const ExamEmpty(
        icon: Icons.assignment_outlined,
        message: 'No report cards have been published yet.',
      );
    }
    return Column(
      children: cards.map((c) {
        final exam = exams.where((e) => e.examScheduleId == c.examScheduleId).firstOrNull;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ExamCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam?.examName ?? c.examScheduleId,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        ExamBadge('${c.percentage.toStringAsFixed(1)}%', color: const Color(0xFF2563EB)),
                        ExamBadge('Grade ${c.grade}', color: const Color(0xFF059669)),
                        ExamBadge('Rank ${c.classRank}', color: const Color(0xFF7C3AED)),
                        ExamBadge(c.passed ? 'PASS' : 'FAIL'),
                      ]),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kExamTeal),
                  onPressed: () => showReportCardDialog(
                    context,
                    card: c,
                    exam: exam,
                    student: student,
                    master: master,
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Performance extends ConsumerWidget {
  final ExamStudentInfo student;
  final ExamMasterData master;
  const _Performance({required this.student, required this.master});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = [
      ...(ref
              .watch(reportCardsProvider(
                  (examId: null, sectionId: null, studentId: student.id, published: true)))
              .valueOrNull ??
          const <ReportCard>[]),
    ];
    final exams = ref.watch(allExamsProvider).valueOrNull ?? const <ExamSchedule>[];
    ExamSchedule? examOf(ReportCard c) =>
        exams.where((e) => e.examScheduleId == c.examScheduleId).firstOrNull;
    cards.sort((a, b) => (examOf(a)?.startDate ?? '').compareTo(examOf(b)?.startDate ?? ''));
    if (cards.isEmpty) {
      return const ExamEmpty(
        icon: Icons.show_chart,
        message: 'Progress appears here after report cards are published.',
      );
    }
    final subjectNames = <String>{for (final c in cards) for (final s in c.subjects) s.subjectName};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExamCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall percentage', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              for (final c in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${examOf(c)?.examName ?? c.examScheduleId}  -  ${c.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12.5)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (c.percentage / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          color: kExamTeal,
                          backgroundColor: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExamTable(
          minWidth: 480,
          columns: ['Subject', ...cards.map((c) => examOf(c)?.examName ?? 'Exam')],
          rows: subjectNames.map((name) {
            return [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ...cards.map((c) {
                final s = c.subjects.where((x) => x.subjectName == name).firstOrNull;
                if (s == null) return const Text('-');
                return Text(
                  s.absent ? 'AB' : '${examFmtMarks(s.marks)} / ${examFmtMarks(s.maxMarks)}',
                  style: TextStyle(color: s.failed ? Colors.red.shade600 : null),
                );
              }),
            ];
          }).toList(),
        ),
      ],
    );
  }
}
