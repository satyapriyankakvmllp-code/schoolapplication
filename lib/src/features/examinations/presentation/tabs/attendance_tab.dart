import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import 'flow_ui.dart';

/// Screen 4: Exam-Day Attendance (present/absent/malpractice)
class ExamAttendanceTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const ExamAttendanceTab({super.key, required this.exam});

  @override
  ConsumerState<ExamAttendanceTab> createState() => _State();
}

class _State extends ConsumerState<ExamAttendanceTab> {
  String? _paperId;
  bool _todayOnly = false;
  bool _saving = false;
  final Map<String, String> _status = {};
  final Map<String, String> _remarks = {};
  String? _loadedFor;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _save(ExamTimetableEntry p) async {
    setState(() => _saving = true);
    try {
      await ref.read(examFlowActionsProvider).saveAttendance(widget.exam.examScheduleId, p, _status, _remarks);
      if (mounted) flowSnack(context, 'Attendance saved.');
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(examinationPermissionsProvider);
    final r = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetableAsync = ref.watch(examTimetableProvider(widget.exam.examScheduleId));
    final canMark = (perms.isAdminOrPrincipal || perms.isTeacher || perms.isClassIncharge) &&
        !widget.exam.isCancelled;

    return timetableAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        final papers = _todayOnly ? all.where((p) => p.examDate == _today).toList() : all;
        final paper = papers.where((p) => p.id == _paperId).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Exam-Day Attendance',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            FilterChip(
              label: const Text("Today's timetable only"),
              selected: _todayOnly,
              onSelected: (v) => setState(() {
                _todayOnly = v;
                _paperId = null;
              }),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: papers.any((p) => p.id == _paperId) ? _paperId : null,
            isExpanded: true,
            decoration: flowDecoration(context, 'Select Exam Timetable Entry'),
            items: [
              for (final p in {for (final x in papers) x.id: x}.values)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(
                      '${p.examDate}${p.examDate == _today ? " (today)" : ""}  ${p.startTime}  ${r.subjectName(p.subjectId)} - ${r.sectionName(p.classSectionId)}'),
                ),
            ],
            onChanged: (v) => setState(() {
              _paperId = v;
              _loadedFor = null;
            }),
          ),
          const SizedBox(height: 14),
          if (papers.isEmpty)
            FlowEmpty(Icons.event_busy, _todayOnly ? 'No exam timetable scheduled for today.' : 'No timetable entries scheduled yet.')
          else if (paper == null)
            const FlowEmpty(Icons.touch_app_outlined, 'Select a timetable entry to mark attendance.')
          else
            _roster(paper, canMark),
        ]);
      },
    );
  }

  Widget _roster(ExamTimetableEntry paper, bool canMark) {
    final studentsAsync = ref.watch(studentsProvider);
    final attAsync = ref.watch(attendanceProvider(paper.id));
    return studentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Text('$e'),
      data: (all) => attAsync.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        error: (e, _) => Text('$e'),
        data: (records) {
          final students = all.where((s) => s.sectionId == paper.classSectionId).toList();
          if (_loadedFor != paper.id) {
            _loadedFor = paper.id;
            _status
              ..clear()
              ..addEntries(students.map((s) => MapEntry(
                  s.id, records.where((x) => x.studentId == s.id).firstOrNull?.status ?? 'PRESENT')));
            _remarks
              ..clear()
              ..addEntries(records.where((x) => x.remarks != null).map((x) => MapEntry(x.studentId, x.remarks!)));
          }
          final present = _status.values.where((v) => v == 'PRESENT').length;
          final absent = _status.values.where((v) => v == 'ABSENT').length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, children: [
              FlowChip('Total ${students.length}', Colors.blueGrey),
              FlowChip('Present $present', const Color(0xFF059669)),
              FlowChip('Absent $absent', const Color(0xFFDC2626)),
            ]),
            const SizedBox(height: 10),
            if (students.isEmpty)
              const FlowEmpty(Icons.groups_outlined, 'No students found in this class section.')
            else
              for (final s in students)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text('${s.rollNumber.isNotEmpty ? "${s.rollNumber}. " : ""}${s.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(s.admissionNumber),
                    trailing: SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: const ['PRESENT', 'ABSENT', 'MALPRACTICE'].contains(_status[s.id])
                            ? _status[s.id]
                            : 'PRESENT',
                        isExpanded: true,
                        decoration: flowDecoration(context, 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
                          DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                          DropdownMenuItem(value: 'MALPRACTICE', child: Text('Malpractice')),
                        ],
                        onChanged: canMark ? (v) => setState(() => _status[s.id] = v ?? 'PRESENT') : null,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 10),
            if (canMark)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                onPressed: _saving ? null : () => _save(paper),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save Attendance'),
              ),
          ]);
        },
      ),
    );
  }
}
