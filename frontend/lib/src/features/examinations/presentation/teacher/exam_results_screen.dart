import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Teacher Exam Results Screen
/// Allows teachers to view published results and performance analytics for their classes.
class TeacherExamResultsScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const TeacherExamResultsScreen({super.key, this.initialExamScheduleId});

  @override
  ConsumerState<TeacherExamResultsScreen> createState() =>
      _TeacherExamResultsScreenState();
}

class _TeacherExamResultsScreenState
    extends ConsumerState<TeacherExamResultsScreen> {
  String? _selectedExamScheduleId;
  String? _selectedClassId;
  String? _selectedSectionId;

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

    final refData =
        ref.watch(examReferenceProvider).valueOrNull ??
        const ExamReferenceData();
    final cardsAsync = ref.watch(
      reportCardsProvider(activeExam.examScheduleId),
    );
    final studentsAsync = ref.watch(studentsProvider);

    final availableSections = _selectedClassId == null
        ? refData.sections
        : refData.sections.where((s) => s.classId == _selectedClassId).toList();

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
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                // Exam Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: activeExam.examScheduleId,
                    decoration: flowDecoration(context, 'Examination'),
                    items: exams
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.examScheduleId,
                            child: Text(e.examName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        setState(() => _selectedExamScheduleId = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Class Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: flowDecoration(context, 'Class'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      for (final c in {
                        for (final x in refData.classes) x.id: x,
                      }.values)
                        DropdownMenuItem(value: c.id, child: Text(c.label)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedClassId = v;
                        _selectedSectionId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Section Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        availableSections.any((s) => s.id == _selectedSectionId)
                        ? _selectedSectionId
                        : null,
                    decoration: flowDecoration(context, 'Section'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Sections'),
                      ),
                      for (final s in {
                        for (final x in availableSections) x.id: x,
                      }.values)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _selectedSectionId = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results Ledger
          cardsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('Error loading results: $e')),
            data: (allCards) {
              final students = studentsAsync.valueOrNull ?? [];
              final studentMap = {for (final s in students) s.id: s};

              // Teacher only sees published results (or approved)
              final publishedCards = allCards.where((c) {
                if (c.status != 'PUBLISHED' && c.status != 'APPROVED')
                  return false;
                if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
                  final sec = refData.sections
                      .where((s) => s.id == c.classSectionId)
                      .firstOrNull;
                  if (sec?.classId != _selectedClassId) return false;
                }
                if (_selectedSectionId != null &&
                    _selectedSectionId!.isNotEmpty) {
                  if (c.classSectionId != _selectedSectionId) return false;
                }
                return true;
              }).toList();

              if (publishedCards.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.assessment_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No published results found for the selected criteria.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final totalStudents = publishedCards.length;
              final passedStudents = publishedCards
                  .where(
                    (c) =>
                        c.finalResult.toUpperCase() == 'PASS' ||
                        c.finalResult.toUpperCase() == 'DISTINCTION',
                  )
                  .length;
              final passRate = totalStudents > 0
                  ? (passedStudents / totalStudents * 100)
                  : 0.0;

              return Column(
                children: [
                  // Analytics Summary
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Graded',
                          '$totalStudents Students',
                          Colors.blue,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Passed',
                          '$passedStudents',
                          Colors.green,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Class Pass Rate',
                          '${passRate.toStringAsFixed(1)}%',
                          kExamGreen,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF8FAFC),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Roll No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Student',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Class & Section',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Total Marks',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Percentage',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Grade',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Result',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: publishedCards.map((card) {
                        final s = studentMap[card.studentId];
                        final name =
                            s?.name ?? refData.studentName(card.studentId);
                        final roll = s?.rollNumber ?? '—';
                        final secName = refData.sectionName(
                          card.classSectionId,
                        );
                        final isPass =
                            card.finalResult.toUpperCase() == 'PASS' ||
                            card.finalResult.toUpperCase() == 'DISTINCTION';

                        return DataRow(
                          cells: [
                            DataCell(Text(roll)),
                            DataCell(
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(secName)),
                            DataCell(
                              Text(
                                '${card.totalMarks.toStringAsFixed(1)} / ${card.maxMarks.toStringAsFixed(0)}',
                              ),
                            ),
                            DataCell(
                              Text('${card.percentage.toStringAsFixed(1)}%'),
                            ),
                            DataCell(
                              Text(
                                card.overallGrade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isPass
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  card.finalResult,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPass
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String val, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
