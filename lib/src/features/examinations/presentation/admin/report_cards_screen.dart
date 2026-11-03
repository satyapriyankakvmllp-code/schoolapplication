import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Admin Report Cards Screen
/// Displays and prints the comprehensive, official student report card.
class AdminReportCardsScreen extends ConsumerStatefulWidget {
  final ExamSchedule? exam;
  final String? initialStudentId;

  const AdminReportCardsScreen({
    super.key,
    this.exam,
    this.initialStudentId,
  });

  @override
  ConsumerState<AdminReportCardsScreen> createState() => _AdminReportCardsScreenState();
}

class _AdminReportCardsScreenState extends ConsumerState<AdminReportCardsScreen> {
  String? _selectedExamScheduleId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.exam?.examScheduleId;
    _selectedStudentId = widget.initialStudentId;
  }

  void _printOrDownload() {
    flowSnack(context, 'Report Card PDF generation triggered.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];

    if (exams.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No examinations scheduled yet.'),
        ),
      );
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => widget.exam ?? exams.first,
    );

    final cardsAsync = ref.watch(reportCardsProvider(activeExam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(activeExam.examScheduleId)).valueOrNull ?? [];
    final marks = ref.watch(marksProvider(activeExam.examScheduleId)).valueOrNull ?? [];
    final att = ref.watch(attendanceProvider(activeExam.examScheduleId)).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${activeExam.examName} - Report Cards'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        elevation: 1,
        actions: [
          FilledButton.icon(
            onPressed: _printOrDownload,
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print / Download PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: kExamGreen,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading report cards: $e')),
        data: (allCards) {
          final students = studentsAsync.valueOrNull ?? [];
          final studentMap = {for (final s in students) s.id: s};

          if (allCards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No report cards found for this examination.'),
                    const SizedBox(height: 8),
                    const Text(
                      'Please compute results in the Results tab first.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final effectiveStudentId = (allCards.any((c) => c.studentId == _selectedStudentId))
              ? _selectedStudentId
              : allCards.first.studentId;

          final card = allCards.firstWhere(
            (c) => c.studentId == effectiveStudentId,
            orElse: () => allCards.first,
          );

          final student = studentMap[card.studentId];
          final studentName = student?.name ?? refData.studentName(card.studentId);
          final rollNo = student?.rollNumber ?? '—';
          final secName = refData.sectionName(card.classSectionId);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Student Selector List
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Students (${allCards.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: allCards.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = allCards[index];
                          final s = studentMap[c.studentId];
                          final name = s?.name ?? refData.studentName(c.studentId);
                          final isSelected = c.studentId == effectiveStudentId;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: kExamGreen.withOpacity(0.1),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: isSelected ? kExamGreen : Colors.grey.shade300,
                              child: Text(
                                name.isNotEmpty ? name[0] : 'S',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${c.studentId} • Grade: ${c.grade}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${c.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? kExamGreen : Colors.grey.shade700,
                              ),
                            ),
                            onTap: () {
                              setState(() => _selectedStudentId = c.studentId);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Right Column: Official Printable Report Card View
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
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
                            // School Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.school, size: 40, color: kExamGreen),
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    const Text(
                                      'EDUPULSE HIGH SCHOOL',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
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
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: kExamGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(thickness: 1.5),
                            const SizedBox(height: 16),

                            // Student Info Grid
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
                                        _infoRow('Student Name:', studentName, bold: true),
                                        const SizedBox(height: 6),
                                        _infoRow('Admission / Student ID:', card.studentId),
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
                                    _HeaderCell('Subject'),
                                    _HeaderCell('Max Marks', align: TextAlign.center),
                                    _HeaderCell('Pass Marks', align: TextAlign.center),
                                    _HeaderCell('Marks Obtained', align: TextAlign.center),
                                    _HeaderCell('Grade', align: TextAlign.center),
                                    _HeaderCell('Status', align: TextAlign.center),
                                  ],
                                ),
                                ...timetable
                                    .where((p) => p.classSectionId == card.classSectionId)
                                    .map((p) {
                                  final sName = refData.subjectName(p.subjectId);
                                  final m = marks
                                      .where((x) => x.examPaperId == p.id && x.studentId == card.studentId)
                                      .firstOrNull;
                                  final a = att
                                      .where((x) => x.examPaperId == p.id && x.studentId == card.studentId)
                                      .firstOrNull;
                                  final isAbsent = a?.status == 'ABSENT';
                                  final got = m?.marksObtained;
                                  final passed = got != null && got >= p.passingMarks;

                                  return TableRow(
                                    children: [
                                      _BodyCell(sName),
                                      _BodyCell(p.maxMarks.toStringAsFixed(0), align: TextAlign.center),
                                      _BodyCell(p.passingMarks.toStringAsFixed(0), align: TextAlign.center),
                                      _BodyCell(
                                        got != null
                                            ? got.toStringAsFixed(1)
                                            : (isAbsent ? 'AB' : '—'),
                                        align: TextAlign.center,
                                        bold: true,
                                      ),
                                      _BodyCell(
                                        got != null
                                            ? (got >= 90 ? 'A+' : got >= 75 ? 'A' : got >= 60 ? 'B' : got >= 35 ? 'C' : 'F')
                                            : '—',
                                        align: TextAlign.center,
                                        color: Colors.blue.shade700,
                                        bold: true,
                                      ),
                                      _BodyCell(
                                        isAbsent
                                            ? 'Absent'
                                            : (got == null ? 'Pending' : (passed ? 'Pass' : 'Needs Support')),
                                        align: TextAlign.center,
                                        color: passed ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Total & Final Summary
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
                                  _metricCol('Grand Total', '${card.totalMarks.toStringAsFixed(1)} / ${card.totalMaxMarks.toStringAsFixed(0)}'),
                                  _metricCol('Percentage', '${card.percentage.toStringAsFixed(1)}%'),
                                  _metricCol('Overall Grade', card.grade, color: Colors.blue.shade700),
                                  _metricCol(
                                    'Final Result',
                                    card.passed ? 'PASS' : 'FAIL',
                                    color: card.passed ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Signatures Block
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                _SignatureLine('Class Teacher Signature'),
                                _SignatureLine('Exam Coordinator'),
                                _SignatureLine('Principal Signature & Seal'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _metricCol(String title, String val, {Color? color}) {
    return Column(
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
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderCell(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool bold;
  final Color? color;
  const _BodyCell(this.text, {this.align = TextAlign.left, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  final String label;
  const _SignatureLine(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 1,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
