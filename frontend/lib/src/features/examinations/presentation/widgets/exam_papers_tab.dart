import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';
import 'exam_paper_form_dialog.dart';

/// Screen 2A: Exam Timetable tab (formerly Exam Papers tab) inside Exam Details.
class ExamTimetableTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const ExamTimetableTab({super.key, required this.exam});

  @override
  ConsumerState<ExamTimetableTab> createState() => _ExamTimetableTabState();
}

class _ExamTimetableTabState extends ConsumerState<ExamTimetableTab> {
  String _classFilter = 'ALL';

  String _fmtDate(String d) {
    try {
      return DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  Future<void> _openForm(ExamReferenceData refData, {ExamTimetableEntry? entry}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ExamTimetableFormDialog(
        exam: widget.exam,
        entry: entry,
        refData: refData,
      ),
    );
    if (ok == true && mounted) {
      flowSnack(
        context,
        entry == null
            ? 'Exam timetable entry added.'
            : 'Exam timetable entry updated.',
      );
    }
  }

  Future<void> _delete(ExamTimetableEntry entry, ExamReferenceData r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove timetable entry?'),
        content: Text(
          'Remove ${r.subjectName(entry.subjectId)} (${r.sectionName(entry.classSectionId)}) from this exam?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(examTimetableActionsProvider).delete(entry.id, widget.exam);
      if (mounted) flowSnack(context, 'Timetable entry removed.');
    } catch (e) {
      if (mounted) {
        flowSnack(context, flowError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(examinationPermissionsProvider);
    final timetableAsync = ref.watch(examTimetableProvider(widget.exam.examScheduleId));
    final refAsync = ref.watch(examReferenceProvider);
    final locked = widget.exam.isCancelled || widget.exam.isCompleted;
    final canManage = (perms.isAdminOrPrincipal || perms.isTeacher || perms.isClassIncharge) && !locked;

    return timetableAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 8),
              Text('Could not load timetable: $e'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(examTimetableProvider(widget.exam.examScheduleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (all) {
        final r = refAsync.valueOrNull ?? const ExamReferenceData();
        final sectionIds = all.map((p) => p.classSectionId).whereType<String>().toSet();

        // Role filtering: Student and Parent see only their own class and hide cancelled exams
        List<ExamTimetableEntry> visibleList = all;
        if (perms.isStudentOrParent) {
          if (widget.exam.isCancelled) {
            visibleList = [];
          } else {
            // Filter by student's class (default to cls-sec-10a in seed data)
            visibleList = all.where((p) => p.classSectionId == 'cls-sec-10a').toList();
          }
        }

        final filtered = _classFilter == 'ALL'
            ? visibleList
            : visibleList.where((p) => p.classSectionId == _classFilter).toList();

        final byDate = <String, List<ExamTimetableEntry>>{};
        for (final p in filtered) {
          byDate.putIfAbsent(p.examDate ?? '-', () => []).add(p);
        }
        final dates = byDate.keys.toList()..sort();

        final countText = '${visibleList.length} ${visibleList.length == 1 ? 'entry' : 'entries'}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: kExamGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Exam Timetable ($countText)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _classFilter == 'ALL' || sectionIds.contains(_classFilter)
                        ? _classFilter
                        : 'ALL',
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Class / Section'),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All classes')),
                      for (final id in sectionIds)
                        DropdownMenuItem(value: id, child: Text(r.sectionName(id))),
                    ],
                    onChanged: (v) => setState(() => _classFilter = v ?? 'ALL'),
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kExamGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: refAsync.hasValue ? () => _openForm(r) : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Exam Timetable Entry'),
                  ),
              ],
            ),
            if (locked)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.orange.shade900, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.exam.isCompleted
                              ? 'This exam is completed, so the timetable is read-only.'
                              : 'This exam is cancelled, so the timetable is read-only.',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              FlowEmpty(
                Icons.calendar_today_outlined,
                canManage
                    ? 'No exam timetable entries scheduled yet. Add the first entry.'
                    : 'No exam timetable entries scheduled yet.',
              )
            else
              for (final d in dates) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kExamGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _fmtDate(d),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: kExamGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                    ],
                  ),
                ),
                for (final p in byDate[d]!)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: kExamGreen.withValues(alpha: 0.12),
                            child: const Icon(Icons.menu_book, color: kExamGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      r.subjectName(p.subjectId),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        r.sectionName(p.classSectionId),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    statusChip(p.status ?? 'SCHEDULED'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '🕒 ${p.startTime} – ${p.endTime} (${p.formattedDuration})',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    Text(
                                      '🎯 Max: ${p.maxMarks.toStringAsFixed(0)} (Pass: ${p.passingMarks.toStringAsFixed(0)})',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    Text(
                                      '🏛️ Room: ${p.roomId == null ? "—" : r.roomName(p.roomId)}',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                    Text(
                                      '👤 Invigilator: ${p.invigilatorId == null ? "—" : r.teacherName(p.invigilatorId)}',
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 15),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _openForm(r, entry: p),
                                ),
                                const SizedBox(width: 4),
                                if (perms.isAdminOrPrincipal)
                                  IconButton(
                                    tooltip: 'Remove entry',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 18),
                                    onPressed: () => _delete(p, r),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }
}

/// Backwards compatibility alias
typedef ExamPapersTab = ExamTimetableTab;
