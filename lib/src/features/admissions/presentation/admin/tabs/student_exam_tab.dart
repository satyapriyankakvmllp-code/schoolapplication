import 'package:flutter/material.dart';
import '../../../domain/student_admission_model.dart';

/// Subject scorecard item for an examination cycle.
class SubjectMarkItem {
  final String subject;
  final double maxMarks;
  final double minMarks;
  final double marksObtained;
  final String grade;
  final String result; // 'Pass', 'Fail'

  const SubjectMarkItem({
    required this.subject,
    required this.maxMarks,
    required this.minMarks,
    required this.marksObtained,
    required this.grade,
    required this.result,
  });
}

/// Examination section holding multiple subject scorecards.
class ExamSectionItem {
  final String id;
  final String title;
  final List<SubjectMarkItem> marks;
  final int rank;
  final double totalMax;
  final double totalObtained;
  final String overallGrade;
  final String overallResult;

  const ExamSectionItem({
    required this.id,
    required this.title,
    required this.marks,
    required this.rank,
    required this.totalMax,
    required this.totalObtained,
    required this.overallGrade,
    required this.overallResult,
  });
}

/// Exam Tab View for Student 360° Profile.
/// Displays exam records categorized by semester, month, and week.
/// Single-accordion behavior: tapping an exam expands it and automatically closes all others.
/// Full-width mark sheet tables with summary strips.
class StudentExamTab extends StatefulWidget {
  final StudentAdmissionModel admission;
  final bool isDark;

  const StudentExamTab({
    super.key,
    required this.admission,
    this.isDark = false,
  });

  @override
  State<StudentExamTab> createState() => _StudentExamTabState();
}

class _StudentExamTabState extends State<StudentExamTab> {
  // Only one expanded exam at a time. Default to First Semester.
  String? _expandedExamId = 'first-semester';

  late List<ExamSectionItem> _examSections;

  @override
  void initState() {
    super.initState();
    _examSections = _buildExamSections();
  }

  List<ExamSectionItem> _buildExamSections() {
    return const [
      // 1. First Semester
      ExamSectionItem(
        id: 'first-semester',
        title: 'First Semester',
        rank: 30,
        totalMax: 600,
        totalObtained: 398,
        overallGrade: 'A',
        overallResult: 'Pass',
        marks: [
          SubjectMarkItem(subject: 'Bangla', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Chemistry', maxMarks: 100.0, minMarks: 35.0, marksObtained: 48.0, grade: 'B', result: 'Pass'),
          SubjectMarkItem(subject: 'English', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B+', result: 'Pass'),
          SubjectMarkItem(subject: 'ICT', maxMarks: 100.0, minMarks: 35.0, marksObtained: 70.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Mathematics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Physics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B', result: 'Pass'),
        ],
      ),

      // 2. Monthly Test (Jun-2025)
      ExamSectionItem(
        id: 'monthly-jun-2025',
        title: 'Monthly Test (Jun-2025)',
        rank: 30,
        totalMax: 600,
        totalObtained: 398,
        overallGrade: 'A',
        overallResult: 'Pass',
        marks: [
          SubjectMarkItem(subject: 'Bangla', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Chemistry', maxMarks: 100.0, minMarks: 35.0, marksObtained: 48.0, grade: 'B', result: 'Pass'),
          SubjectMarkItem(subject: 'English', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B+', result: 'Pass'),
          SubjectMarkItem(subject: 'ICT', maxMarks: 100.0, minMarks: 35.0, marksObtained: 70.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Mathematics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Physics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B', result: 'Pass'),
        ],
      ),

      // 3. Weekly Test(Jun-2025)
      ExamSectionItem(
        id: 'weekly-jun-2025',
        title: 'Weekly Test(Jun-2025)',
        rank: 30,
        totalMax: 600,
        totalObtained: 398,
        overallGrade: 'A',
        overallResult: 'Pass',
        marks: [
          SubjectMarkItem(subject: 'Bangla', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Chemistry', maxMarks: 100.0, minMarks: 35.0, marksObtained: 48.0, grade: 'B', result: 'Pass'),
          SubjectMarkItem(subject: 'English', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B+', result: 'Pass'),
          SubjectMarkItem(subject: 'ICT', maxMarks: 100.0, minMarks: 35.0, marksObtained: 70.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Mathematics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Physics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B', result: 'Pass'),
        ],
      ),

      // 4. Weekly Test(May-2025)
      ExamSectionItem(
        id: 'weekly-may-2025',
        title: 'Weekly Test(May-2025)',
        rank: 30,
        totalMax: 600,
        totalObtained: 398,
        overallGrade: 'A',
        overallResult: 'Pass',
        marks: [
          SubjectMarkItem(subject: 'Bangla', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Chemistry', maxMarks: 100.0, minMarks: 35.0, marksObtained: 48.0, grade: 'B', result: 'Pass'),
          SubjectMarkItem(subject: 'English', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B+', result: 'Pass'),
          SubjectMarkItem(subject: 'ICT', maxMarks: 100.0, minMarks: 35.0, marksObtained: 70.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Mathematics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Physics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B', result: 'Pass'),
        ],
      ),

      // 5. weeklyTestMay
      ExamSectionItem(
        id: 'weekly-test-may',
        title: 'weeklyTestMay',
        rank: 30,
        totalMax: 600,
        totalObtained: 398,
        overallGrade: 'A',
        overallResult: 'Pass',
        marks: [
          SubjectMarkItem(subject: 'Bangla', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Chemistry', maxMarks: 100.0, minMarks: 35.0, marksObtained: 48.0, grade: 'B', result: 'Pass'),
          SubjectMarkItem(subject: 'English', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B+', result: 'Pass'),
          SubjectMarkItem(subject: 'ICT', maxMarks: 100.0, minMarks: 35.0, marksObtained: 70.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Mathematics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 80.0, grade: 'A+', result: 'Pass'),
          SubjectMarkItem(subject: 'Physics', maxMarks: 100.0, minMarks: 35.0, marksObtained: 60.0, grade: 'B', result: 'Pass'),
        ],
      ),
    ];
  }

  void _toggleExam(String examId) {
    setState(() {
      // Single accordion logic: if currently open, close it; otherwise open this one and close others.
      _expandedExamId = (_expandedExamId == examId) ? null : examId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Exam',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),

          // Collapsible Exam Section Cards (Single expanded accordion)
          for (int i = 0; i < _examSections.length; i++) ...[
            _buildExamAccordionCard(_examSections[i], isDark),
            if (i != _examSections.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildExamAccordionCard(ExamSectionItem item, bool isDark) {
    final isExpanded = _expandedExamId == item.id;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accordion Header
          InkWell(
            onTap: () => _toggleExam(item.id),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Accordion Content (Scorecard Table + Summary Bar)
          if (isExpanded) ...[
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            LayoutBuilder(
              builder: (context, tableConstraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      ),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 52,
                      headingRowHeight: 44,
                      horizontalMargin: 20,
                      columnSpacing: 28,
                      columns: [
                        DataColumn(label: _buildSortHeader('Subject', isDark)),
                        DataColumn(label: _buildSortHeader('Max Marks', isDark)),
                        DataColumn(label: _buildSortHeader('Min Marks', isDark)),
                        DataColumn(label: _buildSortHeader('Marks Obtained', isDark)),
                        DataColumn(label: _buildSortHeader('Grade', isDark)),
                        DataColumn(label: _buildSortHeader('Result', isDark)),
                      ],
                      rows: item.marks.map((mark) {
                        final isPass = mark.result.toLowerCase() == 'pass';

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                mark.subject,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                mark.maxMarks.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                mark.minMarks.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                mark.marksObtained % 1 == 0
                                    ? mark.marksObtained.toInt().toString()
                                    : mark.marksObtained.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                mark.grade,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPass ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  mark.result,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isPass ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            // Summary Footer Bar matching exact format from Screenshots
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                border: Border(
                  top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSummaryItem('Rank:', '${item.rank}', isDark),
                    const SizedBox(width: 32),
                    _buildSummaryItem('Total:', '${item.totalMax.toInt()}', isDark),
                    const SizedBox(width: 32),
                    _buildSummaryItem('Total Obtain Marks:', '${item.totalObtained.toInt()}', isDark),
                    const SizedBox(width: 32),
                    _buildSummaryItem('Grade:', item.overallGrade, isDark),
                    const SizedBox(width: 32),
                    _buildSummaryItem('Results:', item.overallResult, isDark, valueColor: const Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _buildSortHeader(String title, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.unfold_more, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      ],
    );
  }
}
