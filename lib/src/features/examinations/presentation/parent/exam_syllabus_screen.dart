import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Parent Exam Syllabus Screen
/// Displays syllabus chapters, topics, and weightage for the student's subjects.
class ParentExamSyllabusScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const ParentExamSyllabusScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<ParentExamSyllabusScreen> createState() => _ParentExamSyllabusScreenState();
}

class _ParentExamSyllabusScreenState extends ConsumerState<ParentExamSyllabusScreen> {
  String? _selectedExamScheduleId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
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

    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final syllabusAsync = ref.watch(syllabusProvider(activeExam.examScheduleId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: activeExam.examScheduleId,
                    decoration: flowDecoration(context, 'Examination'),
                    items: exams.map((e) => DropdownMenuItem(value: e.examScheduleId, child: Text(e.examName))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedExamScheduleId = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: flowDecoration(context, 'Subject Filter'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      for (final sub in {for (final x in refData.subjects) x.id: x}.values)
                        DropdownMenuItem(value: sub.id, child: Text(sub.label)),
                    ],
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Syllabus Cards
          syllabusAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading syllabus: $e')),
            data: (allSyllabus) {
              final filtered = allSyllabus.where((s) {
                if (_selectedSubjectId != null && s.subjectId != _selectedSubjectId) return false;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('No syllabus details found for this examination.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = filtered[idx];
                  final subName = refData.subjectName(item.subjectId);

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(subName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${item.chapters.length} chapter(s) covered', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      children: [
                        const Divider(height: 1),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.chapters.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (c, cIdx) {
                            final ch = item.chapters[cIdx];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: kExamGreen.withOpacity(0.12),
                                child: Text(
                                  '${ch.chapterNumber}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kExamGreen),
                                ),
                              ),
                              title: Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: ch.topics.isNotEmpty ? Text(ch.topics, style: const TextStyle(fontSize: 12)) : null,
                              trailing: ch.weightageMarks != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.teal.shade200),
                                      ),
                                      child: Text(
                                        '${ch.weightageMarks} marks',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
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

