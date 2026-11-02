import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Teacher Exam Timetable Screen
/// Displays schedule with invigilation duties highlighted.
class TeacherExamTimetableScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const TeacherExamTimetableScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<TeacherExamTimetableScreen> createState() => _TeacherExamTimetableScreenState();
}

class _TeacherExamTimetableScreenState extends ConsumerState<TeacherExamTimetableScreen> {
  String? _selectedExamScheduleId;
  String _filter = 'ALL'; // ALL | MY_DUTIES

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No examinations scheduled.')));
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final timetableAsync = ref.watch(examTimetableProvider(activeExam.examScheduleId));
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Selection & Filter Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20, color: kExamGreen),
                const SizedBox(width: 8),
                const Text('Examination:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeExam.examScheduleId,
                      isExpanded: true,
                      items: exams.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.examScheduleId,
                          child: Text('${e.examName} (${e.academicYear})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExamScheduleId = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timetable List
          timetableAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading timetable: $e')),
            data: (entries) {
              if (entries.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('No timetable entries published for this examination yet.', style: TextStyle(color: Colors.grey)),
                );
              }

              // Group entries by date
              final byDate = <String, List<ExamTimetableEntry>>{};
              for (final e in entries) {
                byDate.putIfAbsent(e.examDate, () => []).add(e);
              }
              final sortedDates = byDate.keys.toList()..sort();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, dIdx) {
                  final date = sortedDates[dIdx];
                  final dayEntries = byDate[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          _fmtDate(date),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kExamGreen),
                        ),
                      ),
                      ...dayEntries.map((entry) {
                        final subName = refData.subjectName(entry.subjectId);
                        final secName = refData.sectionName(entry.classSectionId);
                        final invigName = refData.teacherName(entry.invigilatorId);
                        final roomName = refData.roomName(entry.roomId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: kExamGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          subName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(secName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 16,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${entry.startTime} - ${entry.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(roomName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('Invigilator: $invigName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

