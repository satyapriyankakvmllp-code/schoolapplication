import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Student Exam Results Screen
/// Displays official published examination results.
/// Unapproved or draft marks are never displayed.
class StudentExamResultsScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const StudentExamResultsScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<StudentExamResultsScreen> createState() => _StudentExamResultsScreenState();
}

class _StudentExamResultsScreenState extends ConsumerState<StudentExamResultsScreen> {
  String? _selectedExamScheduleId;

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

    final cardsAsync = ref.watch(reportCardsProvider(activeExam.examScheduleId));
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(activeExam.examScheduleId)).valueOrNull ?? [];
    final marks = ref.watch(marksProvider(activeExam.examScheduleId)).valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Selector Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assessment_outlined, size: 20, color: kExamGreen),
                const SizedBox(width: 8),
                const Text('Select Exam:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          const SizedBox(height: 20),

          // Published Result Card
          cardsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading results: $e')),
            data: (cards) {
              // Only filter for PUBLISHED cards
              final publishedCards = cards.where((c) => c.status == 'PUBLISHED').toList();

              if (publishedCards.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.pending_actions, size: 40, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Results have not been officially published yet.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'The school examination committee is finalizing reviews. Please check back later.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final card = publishedCards.first;
              final isPass = card.passed;

              return Column(
                children: [
                  // High Level Metrics
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: const Text(
                                'OFFICIALLY PUBLISHED',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              activeExam.academicYear,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statBox('Total Marks', '${card.totalMarks.toStringAsFixed(1)} / ${card.totalMaxMarks.toStringAsFixed(0)}', Colors.blue),
                            _statBox('Percentage', '${card.percentage.toStringAsFixed(1)}%', kExamGreen),
                            _statBox('Overall Grade', card.grade, Colors.purple),
                            _statBox('Result', isPass ? 'PASS' : 'FAIL', isPass ? Colors.green : Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject-wise Breakdown Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        ),
                        columns: const [
                          DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Max Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Pass Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Marks Obtained', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: timetable
                            .where((p) => p.classSectionId == card.classSectionId)
                            .map((p) {
                          final subName = refData.subjectName(p.subjectId);
                          final m = marks
                              .where((x) => x.examPaperId == p.id && x.studentId == card.studentId)
                              .firstOrNull;
                          final got = m?.marksObtained;
                          return DataRow(
                            cells: [
                              DataCell(Text(subName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(p.maxMarks.toStringAsFixed(0))),
                              DataCell(Text(p.passingMarks.toStringAsFixed(0))),
                              DataCell(Text(got != null ? got.toStringAsFixed(1) : '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    got != null
                                        ? (got >= 90 ? 'A+' : got >= 75 ? 'A' : got >= 60 ? 'B' : got >= 35 ? 'C' : 'F')
                                        : '—',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade800),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
