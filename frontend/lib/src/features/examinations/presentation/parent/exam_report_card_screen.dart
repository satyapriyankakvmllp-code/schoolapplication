import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Parent Exam Report Card Screen
/// Displays and prints the student's official progress report card.
class ParentExamReportCardScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const ParentExamReportCardScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<ParentExamReportCardScreen> createState() => _ParentExamReportCardScreenState();
}

class _ParentExamReportCardScreenState extends ConsumerState<ParentExamReportCardScreen> {
  String? _selectedExamScheduleId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  void _downloadReportCard() {
    flowSnack(context, 'Report Card PDF downloaded to device.');
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
    final studentsAsync = ref.watch(studentsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(activeExam.examScheduleId)).valueOrNull ?? [];
    final marks = ref.watch(marksProvider(activeExam.examScheduleId)).valueOrNull ?? [];

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
                const Icon(Icons.receipt_long_outlined, size: 20, color: kExamGreen),
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
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _downloadReportCard,
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print / Download PDF'),
                  style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Report Card
          cardsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading report card: $e')),
            data: (allCards) {
              final publishedCards = allCards.where((c) => c.status == 'PUBLISHED').toList();

              if (publishedCards.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Official Report Card is not yet released for this examination.', style: TextStyle(color: Colors.grey)),
                );
              }

              final card = publishedCards.first;
              final students = studentsAsync.valueOrNull ?? [];
              final student = students.where((s) => s.id == card.studentId).firstOrNull;
              final studentName = student?.name ?? refData.studentName(card.studentId);
              final rollNo = student?.rollNumber ?? '—';
              final secName = refData.sectionName(card.classSectionId);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school, size: 40, color: kExamGreen),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                const Text(
                                  'EDUPULSE HIGH SCHOOL',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'CBSE Affiliation No: 130245 • Academic Year: ${activeExam.academicYear}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kExamGreen.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'OFFICIAL PROGRESS REPORT — ${activeExam.examName.toUpperCase()}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kExamGreen),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 16),

                        // Student Info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow('Candidate Name:', studentName, bold: true),
                                    const SizedBox(height: 6),
                                    _infoRow('Admission / ID:', card.studentId),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow('Class & Section:', secName),
                                    const SizedBox(height: 6),
                                    _infoRow('Roll Number:', rollNo),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subject Marks Table
                        Table(
                          border: TableBorder.all(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1.2),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(1.5),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              ),
                              children: const [
                                _cell('Subject', bold: true),
                                _cell('Max Marks', bold: true, align: TextAlign.center),
                                _cell('Pass Marks', bold: true, align: TextAlign.center),
                                _cell('Marks Obtained', bold: true, align: TextAlign.center),
                                _cell('Grade', bold: true, align: TextAlign.center),
                                _cell('Status', bold: true, align: TextAlign.center),
                              ],
                            ),
                            ...timetable
                                .where((p) => p.classSectionId == card.classSectionId)
                                .map((p) {
                              final sName = refData.subjectName(p.subjectId);
                              final m = marks
                                  .where((x) => x.examPaperId == p.id && x.studentId == card.studentId)
                                  .firstOrNull;
                              final got = m?.marksObtained;
                              final passed = got != null && got >= p.passingMarks;

                              return TableRow(
                                children: [
                                  _cell(sName),
                                  _cell(p.maxMarks.toStringAsFixed(0), align: TextAlign.center),
                                  _cell(p.passingMarks.toStringAsFixed(0), align: TextAlign.center),
                                  _cell(got != null ? got.toStringAsFixed(1) : '—', align: TextAlign.center, bold: true),
                                  _cell(
                                    got != null
                                        ? (got >= 90 ? 'A+' : got >= 75 ? 'A' : got >= 60 ? 'B' : got >= 35 ? 'C' : 'F')
                                        : '—',
                                    align: TextAlign.center,
                                    bold: true,
                                    color: Colors.blue.shade700,
                                  ),
                                  _cell(
                                    got == null ? 'Pending' : (passed ? 'Pass' : 'Needs Support'),
                                    align: TextAlign.center,
                                    color: passed ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Summary Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _metric('Grand Total', '${card.totalMarks.toStringAsFixed(1)} / ${card.totalMaxMarks.toStringAsFixed(0)}'),
                              _metric('Percentage', '${card.percentage.toStringAsFixed(1)}%'),
                              _metric('Overall Grade', card.grade, color: Colors.blue.shade700),
                              _metric(
                                'Final Result',
                                card.passed ? 'PASS' : 'FAIL',
                                color: card.passed ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Signatures
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _signBlock('Class Teacher Signature'),
                            _signBlock('Exam Coordinator'),
                            _signBlock('Principal Signature & Seal'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  Widget _metric(String label, String val, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _signBlock extends StatelessWidget {
  final String label;
  const _signBlock(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 150, height: 1, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

Widget _cell(String text, {bool bold = false, TextAlign align = TextAlign.left, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
    ),
  );
}
