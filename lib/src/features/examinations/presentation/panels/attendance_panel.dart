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

/// Screen 4: exam-day attendance (the only place where absence is stored).
class AttendancePanel extends ConsumerStatefulWidget {
  final String? examId;
  const AttendancePanel({super.key, this.examId});

  @override
  ConsumerState<AttendancePanel> createState() => _AttendancePanelState();
}

class _AttendancePanelState extends ConsumerState<AttendancePanel> {
  String? _dateFilter; // null = all dates

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final examId = resolveExamId(ref, widget.examId);
    final masterAsync = ref.watch(examMasterProvider);
    final papersAsync = ref.watch(examPapersProvider(examId));
    final attAsync = ref.watch(attendanceForExamProvider(examId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExamPanelHeader(
          title: 'Exam-Day Attendance',
          subtitle: 'Mark who is present or absent for each paper. Absent students get no marks.',
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
                final att = attAsync.valueOrNull ?? const <ExamAttendance>[];
                var papers = scopePapers(all, actor, master).where((p) => !p.isCancelled).toList();
                final dates = papers.map((p) => p.examDate).whereType<String>().toSet().toList()
                  ..sort();
                if (_dateFilter != null) {
                  papers = papers.where((p) => p.examDate == _dateFilter).toList();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExamCard(
                      child: ExamDropdown<String?>(
                        label: 'Date',
                        value: _dateFilter,
                        options: [
                          const ExamOption<String?>(null, 'All dates'),
                          ...dates.map((d) => ExamOption<String?>(
                                d,
                                '${examFmtDate(d)} ${examFmtDay(d)}${d == _today() ? '  (Today)' : ''}',
                              )),
                        ],
                        onChanged: (v) => setState(() => _dateFilter = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (papers.isEmpty)
                      const ExamEmpty(
                        icon: Icons.event_busy,
                        message: 'No papers to mark attendance for.',
                      )
                    else
                      ExamTable(
                        minWidth: 860,
                        columns: const [
                          'Date',
                          'Class - Section',
                          'Subject',
                          'Time',
                          'Room',
                          'Students',
                          'Present',
                          'Absent',
                          'Action',
                        ],
                        rows: papers.map((p) {
                          final students = master.studentsForSection(p.classSectionId);
                          final mine = att.where((a) => a.examPaperId == p.id).toList();
                          final present = mine.where((a) => !a.isAbsent).length;
                          final absent = mine.where((a) => a.isAbsent).length;
                          final canMark = actor.permissions.canMarkAttendance &&
                              (!actor.permissions.isTeacher ||
                                  p.invigilatorId == null ||
                                  p.invigilatorId == actor.teacherId);
                          return [
                            Text('${examFmtDate(p.examDate)}\n${examFmtDay(p.examDate)}',
                                style: const TextStyle(fontSize: 12.5)),
                            Text(master.sectionLabel(p.classSectionId),
                                style: const TextStyle(fontSize: 12.5)),
                            Text(master.subjectName(p.subjectId),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text('${examFmtTime(p.startTime)} to\n${examFmtTime(p.endTime)}',
                                style: const TextStyle(fontSize: 12.5)),
                            Text(master.roomName(p.roomId), style: const TextStyle(fontSize: 12.5)),
                            Text('${students.length}', style: const TextStyle(fontSize: 12.5)),
                            Text(mine.isEmpty ? '-' : '$present',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF059669))),
                            Text(mine.isEmpty ? '-' : '$absent',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: absent > 0 ? Colors.red.shade600 : null,
                                )),
                            FilledButton.tonal(
                              onPressed: () => showAttendanceDialog(
                                context,
                                paper: p,
                                master: master,
                                canMark: canMark,
                              ),
                              child: Text(canMark ? (mine.isEmpty ? 'Take attendance' : 'Edit') : 'View'),
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

Future<void> showAttendanceDialog(
  BuildContext context, {
  required ExamPaper paper,
  required ExamMasterData master,
  required bool canMark,
}) {
  return showExamDialog<void>(
    context,
    (ctx) => _AttendanceDialog(paper: paper, master: master, canMark: canMark),
  );
}

class _AttendanceDialog extends ConsumerStatefulWidget {
  final ExamPaper paper;
  final ExamMasterData master;
  final bool canMark;
  const _AttendanceDialog({required this.paper, required this.master, required this.canMark});

  @override
  ConsumerState<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends ConsumerState<_AttendanceDialog> {
  final Map<String, String> _status = {};
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final existing = await ref.read(examConductRepositoryProvider).getAttendance(paperId: widget.paper.id);
    for (final s in widget.master.studentsForSection(widget.paper.classSectionId)) {
      final rec = existing.where((a) => a.studentId == s.id).firstOrNull;
      _status[s.id] = rec?.status ?? 'PRESENT';
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(examConductRepositoryProvider).saveAttendance(
            paperId: widget.paper.id,
            statusByStudent: Map<String, String>.from(_status),
            actor: ref.read(currentExamActorProvider),
          );
      bumpExamData(ref);
      if (mounted) {
        Navigator.of(context).pop();
        showExamSnack(context, 'Attendance saved.');
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
    final master = widget.master;
    final students = master.studentsForSection(widget.paper.classSectionId);
    final tickets = ref.watch(hallTicketsProvider(widget.paper.examScheduleId)).valueOrNull ?? const [];
    final present = _status.values.where((s) => s == 'PRESENT').length;
    final absent = _status.values.where((s) => s == 'ABSENT').length;

    return ExamDialogFrame(
      title: '${master.subjectName(widget.paper.subjectId)} attendance',
      subtitle:
          '${master.sectionLabel(widget.paper.classSectionId)} | ${examFmtDate(widget.paper.examDate)} | ${master.roomName(widget.paper.roomId)}',
      icon: Icons.fact_check_outlined,
      maxWidth: 640,
      actions: [
        ExamCancelButton(label: widget.canMark ? 'Cancel' : 'Close'),
        if (widget.canMark) ExamPrimaryButton(label: 'Save Attendance', busy: _busy, onPressed: _save),
      ],
      child: !_loaded
          ? const ExamLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ExamNotice(_error!),
                if (!widget.canMark)
                  const ExamNotice('You can view attendance but not change it.', info: true),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExamBadge('Present: $present', status: 'PRESENT'),
                    ExamBadge('Absent: $absent', status: 'ABSENT'),
                    if (widget.canMark)
                      TextButton(
                        onPressed: () => setState(() {
                          for (final k in _status.keys.toList()) {
                            _status[k] = 'PRESENT';
                          }
                        }),
                        child: const Text('Mark all present'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (students.isEmpty)
                  const ExamEmpty(icon: Icons.group_off, message: 'No enrolled students in this class-section.')
                else
                  ...students.map((s) {
                    final ticket = tickets.where((t) => t.studentId == s.id).firstOrNull;
                    final isAbsent = _status[s.id] == 'ABSENT';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: examIsDark(context) ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAbsent ? Colors.red.shade300 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(s.rollNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (ticket != null)
                                  Text(ticket.hallTicketNumber,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            segments: const [
                              ButtonSegment(value: 'PRESENT', label: Text('Present')),
                              ButtonSegment(value: 'ABSENT', label: Text('Absent')),
                            ],
                            selected: {_status[s.id] ?? 'PRESENT'},
                            onSelectionChanged: widget.canMark
                                ? (v) => setState(() => _status[s.id] = v.first)
                                : null,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
