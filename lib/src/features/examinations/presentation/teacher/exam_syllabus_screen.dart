import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Teacher Exam Syllabus Screen
/// Allows teachers to manage and update syllabus for their assigned classes.
class TeacherExamSyllabusScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const TeacherExamSyllabusScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<TeacherExamSyllabusScreen> createState() => _TeacherExamSyllabusScreenState();
}

class _TeacherExamSyllabusScreenState extends ConsumerState<TeacherExamSyllabusScreen> {
  String? _selectedExamScheduleId;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  void _openAddChapterDialog(String examId, ExamReferenceData refData) {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      flowSnack(context, 'Please select Class and Subject first.', error: true);
      return;
    }

    final titleCtrl = TextEditingController();
    final topicsCtrl = TextEditingController();
    final weightageCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Syllabus Chapter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: flowDecoration(ctx, 'Chapter Title *', hint: 'e.g. Real Numbers'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: topicsCtrl,
                maxLines: 3,
                decoration: flowDecoration(ctx, 'Topics Covered', hint: 'Sub-topics, key theorems...'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightageCtrl,
                keyboardType: TextInputType.number,
                decoration: flowDecoration(ctx, 'Weightage (Marks)', hint: 'e.g. 15'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kExamGreen),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final actions = ref.read(examFlowActionsProvider);
              final chapter = SyllabusChapter(
                chapterNumber: 1,
                title: titleCtrl.text.trim(),
                topics: topicsCtrl.text.trim(),
                weightageMarks: int.tryParse(weightageCtrl.text) ?? 10,
              );
              final item = SyllabusItem(
                id: 'syl-${DateTime.now().millisecondsSinceEpoch}',
                examScheduleId: examId,
                subjectId: _selectedSubjectId!,
                classSectionId: _selectedSectionId,
                chapters: [chapter],
              );
              await actions.saveSyllabus(item);
              if (mounted) {
                Navigator.pop(ctx);
                flowSnack(context, 'Chapter added to syllabus.');
              }
            },
            child: const Text('Save Chapter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No examinations scheduled.'),
        ),
      );
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final syllabusAsync = ref.watch(syllabusProvider(activeExam.examScheduleId));

    final availableSections = _selectedClassId == null
        ? refData.sections
        : refData.sections.where((s) => s.classId == _selectedClassId).toList();

    final availableSubjects = _selectedClassId == null
        ? refData.subjects
        : refData.subjects.where((s) => s.classId == _selectedClassId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 20, color: kExamGreen),
                    const SizedBox(width: 8),
                    const Text('Syllabus Explorer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openAddChapterDialog(activeExam.examScheduleId, refData),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Syllabus Chapter'),
                      style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Exam Dropdown
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

                    // Class Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: flowDecoration(context, 'Class *'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select Class')),
                          for (final c in {for (final x in refData.classes) x.id: x}.values)
                            DropdownMenuItem(value: c.id, child: Text(c.label)),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedClassId = v;
                            _selectedSectionId = null;
                            _selectedSubjectId = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Section Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: availableSections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                        decoration: flowDecoration(context, 'Section'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Sections')),
                          for (final s in {for (final x in availableSections) x.id: x}.values)
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                        ],
                        onChanged: (v) => setState(() => _selectedSectionId = v),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Subject Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: availableSubjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null,
                        decoration: flowDecoration(context, 'Subject *'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select Subject')),
                          for (final sub in {for (final x in availableSubjects) x.id: x}.values)
                            DropdownMenuItem(value: sub.id, child: Text(sub.label)),
                        ],
                        onChanged: (v) => setState(() => _selectedSubjectId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Syllabus Content
          syllabusAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading syllabus: $e')),
            data: (allSyllabus) {
              final filtered = allSyllabus.where((s) {
                if (_selectedSubjectId != null && s.subjectId != _selectedSubjectId) return false;
                if (_selectedSectionId != null && s.classSectionId != null && s.classSectionId != _selectedSectionId) {
                  return false;
                }
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
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book, size: 40, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        _selectedClassId == null
                            ? 'Please select Class and Subject above to view or add syllabus.'
                            : 'No syllabus chapters defined for the selected criteria.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
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
                      title: Text(
                        subName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${item.chapters.length} chapter(s) covered',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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

