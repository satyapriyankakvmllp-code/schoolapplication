import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/student_admission_model.dart';

/// Subject scorecard item for an examination cycle.
class SubjectMarkItem {
  final String subject;
  final String date;
  final String time;
  final double maxMarks;
  final double minMarks;
  final double marksObtained;
  final String grade;
  final String result; // 'Pass', 'Fail'

  const SubjectMarkItem({
    required this.subject,
    required this.date,
    required this.time,
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
  final String testType; // 'MONTHLY' or 'WEEKLY'
  final String month; // e.g., 'June 2025'
  final String monthKey; // e.g., '2025-06'
  final int? weekNumber; // 1, 2, 3, 4
  final String? weekLabel; // 'Week 1', 'Week 2'
  final String? dateRange;
  final List<SubjectMarkItem> marks;
  final int rank;
  final double totalMax;
  final double totalObtained;
  final String overallGrade;
  final String overallResult;

  const ExamSectionItem({
    required this.id,
    required this.title,
    this.testType = 'MONTHLY',
    this.month = 'June 2025',
    this.monthKey = '2025-06',
    this.weekNumber,
    this.weekLabel,
    this.dateRange,
    required this.marks,
    required this.rank,
    required this.totalMax,
    required this.totalObtained,
    required this.overallGrade,
    required this.overallResult,
  });

  double get averagePercentage =>
      totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
}

/// Exam Tab View for Student 360° Profile.
/// Features:
/// 1. Subject-vs-Exam Performance Matrix Heatmap with toggle between Monthly and Weekly test trends.
/// 2. Dedicated 'Monthly Tests' section with dynamic Month filter selector.
/// 3. Dedicated 'Weekly Tests' section with dynamic Month + Week selector pills.
/// 4. Full-width responsive DataTable with dedicated 'Exam Date' and 'Exam Time' fields.
/// 5. Graceful empty state when an untested cycle is selected.
/// 6. Dynamic JSON loading from assets/data/examinations/examinations.json with zero-lag fallback.
class StudentExamTab extends StatefulWidget {
  final StudentAdmissionModel? admission;
  final bool isDark;

  const StudentExamTab({
    super.key,
    this.admission,
    this.isDark = false,
  });

  @override
  State<StudentExamTab> createState() => _StudentExamTabState();
}

class _StudentExamTabState extends State<StudentExamTab> {
  // Matrix display mode: 'MONTHLY' or 'WEEKLY'
  String _matrixMode = 'MONTHLY';

  // Filter state for Monthly Tests
  String _selectedMonthlyMonth = 'August 2025';

  // Filter state for Weekly Tests
  String _selectedWeeklyMonth = 'August 2025';
  int _selectedWeeklyWeek = 1; // Default to Week 1

  // Collapsible section states
  bool _isMonthlyExpanded = true;
  bool _isWeeklyExpanded = true;

  late List<ExamSectionItem> _allExamSections;

  @override
  void initState() {
    super.initState();
    _allExamSections = _buildDefaultExamSections();
    _loadExamsFromJson();
  }

  Future<void> _loadExamsFromJson() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/examinations/examinations.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data.containsKey('exam_schedules') && data.containsKey('exam_papers')) {
        final schedules = data['exam_schedules'] as List;
        final papers = data['exam_papers'] as List;

        final List<ExamSectionItem> loaded = [];

        for (final sch in schedules) {
          final schId = sch['id'] as String;
          final schTitle = sch['title'] as String;
          final schType = (sch['test_type'] as String? ?? 'MONTHLY').toUpperCase();
          final schMonth = sch['month'] as String? ?? 'August 2025';
          final schMonthKey = sch['month_key'] as String? ?? '2025-08';
          final schWeekNum = (sch['week'] as num?)?.toInt();
          final schWeekLabel = sch['week_label'] as String?;
          final schStart = sch['start_date'] as String? ?? '';
          final schEnd = sch['end_date'] as String? ?? '';
          final dateRange = schStart.isNotEmpty && schEnd.isNotEmpty ? '$schStart - $schEnd' : null;

          final schRank = (sch['rank'] as num?)?.toInt() ?? 30;
          final schTotalMax = (sch['total_max'] as num?)?.toDouble() ?? 600.0;
          final schTotalObtained = (sch['total_obtained'] as num?)?.toDouble() ?? 398.0;
          final schGrade = sch['overall_grade'] as String? ?? 'A';
          final schResult = sch['overall_result'] as String? ?? 'Pass';

          final matchingPapers = papers.where((p) => p['exam_schedule_id'] == schId);

          final List<SubjectMarkItem> subjectMarks = matchingPapers.map((p) {
            return SubjectMarkItem(
              subject: p['subject'] as String? ?? 'Subject',
              date: p['exam_date'] as String? ?? 'TBD',
              time: p['time_slot'] as String? ?? (p['start_time'] != null ? '${p['start_time']} - ${p['end_time']}' : '09:00 AM - 12:00 PM'),
              maxMarks: (p['max_marks'] as num?)?.toDouble() ?? 100.0,
              minMarks: (p['min_marks'] as num?)?.toDouble() ?? 35.0,
              marksObtained: (p['marks_obtained'] as num?)?.toDouble() ?? 75.0,
              grade: p['grade'] as String? ?? 'A',
              result: p['result'] as String? ?? 'Pass',
            );
          }).toList();

          if (subjectMarks.isNotEmpty) {
            loaded.add(
              ExamSectionItem(
                id: schId,
                title: schTitle,
                testType: schType,
                month: schMonth,
                monthKey: schMonthKey,
                weekNumber: schWeekNum,
                weekLabel: schWeekLabel,
                dateRange: dateRange,
                marks: subjectMarks,
                rank: schRank,
                totalMax: schTotalMax,
                totalObtained: schTotalObtained,
                overallGrade: schGrade,
                overallResult: schResult,
              ),
            );
          }
        }

        if (loaded.isNotEmpty && mounted) {
          setState(() {
            final Map<String, ExamSectionItem> merged = {};
            for (final def in _buildDefaultExamSections()) {
              merged[def.id] = def;
            }
            for (final item in loaded) {
              merged[item.id] = item;
            }
            _allExamSections = merged.values.toList();
            final monthlyMonths = _allExamSections.where((e) => e.testType == 'MONTHLY').map((e) => e.month).toSet().toList();
            if (monthlyMonths.isNotEmpty && !monthlyMonths.contains(_selectedMonthlyMonth)) {
              _selectedMonthlyMonth = monthlyMonths.first;
            }
            final weeklyMonths = _allExamSections.where((e) => e.testType == 'WEEKLY').map((e) => e.month).toSet().toList();
            if (weeklyMonths.isNotEmpty && !weeklyMonths.contains(_selectedWeeklyMonth)) {
              _selectedWeeklyMonth = weeklyMonths.first;
            }
          });
        }
      }
    } catch (_) {
      // Retain fallback safely
    }
  }

  static List<SubjectMarkItem> _createDefaultSubjectMarks(String mShort, int startDay) {
    const subs = [
      ('Bangla', 85.0, 'A+', '09:30 AM - 11:30 AM'),
      ('Chemistry', 60.0, 'B+', '09:30 AM - 11:30 AM'),
      ('English', 70.0, 'A', '09:30 AM - 11:30 AM'),
      ('ICT', 78.0, 'A', '10:00 AM - 12:00 PM'),
      ('Mathematics', 82.0, 'A+', '09:30 AM - 11:30 AM'),
      ('Physics', 70.0, 'A', '09:30 AM - 11:30 AM'),
    ];

    final List<SubjectMarkItem> list = [];
    for (int i = 0; i < subs.length; i++) {
      final s = subs[i];
      final day = (startDay + i).toString().padLeft(2, '0');
      list.add(
        SubjectMarkItem(
          subject: s.$1,
          date: '$day $mShort 2025',
          time: s.$4,
          maxMarks: 100.0,
          minMarks: 35.0,
          marksObtained: s.$2,
          grade: s.$3,
          result: 'Pass',
        ),
      );
    }
    return list;
  }

  List<ExamSectionItem> _buildDefaultExamSections() {
    final List<ExamSectionItem> sections = [];

    const monthDefs = [
      ('August 2025', '2025-08', 'aug', 22, 459.0),
      ('July 2025', '2025-07', 'jul', 25, 437.0),
      ('June 2025', '2025-06', 'jun', 28, 412.0),
      ('May 2025', '2025-05', 'may', 31, 395.0),
      ('April 2025', '2025-04', 'apr', 35, 370.0),
    ];

    // 1. Monthly Tests for all 5 months
    for (final m in monthDefs) {
      final mShort = m.$1.split(' ').first.substring(0, 3);
      sections.add(
        ExamSectionItem(
          id: 'monthly-${m.$3}-2025',
          title: 'Monthly Test ($mShort-2025)',
          testType: 'MONTHLY',
          month: m.$1,
          monthKey: m.$2,
          dateRange: '20 $mShort 2025 - 26 $mShort 2025',
          rank: m.$4,
          totalMax: 600.0,
          totalObtained: m.$5,
          overallGrade: m.$5 >= 420 ? 'A+' : (m.$5 >= 390 ? 'A' : 'B+'),
          overallResult: 'Pass',
          marks: _createDefaultSubjectMarks(mShort, 20),
        ),
      );
    }

    // 2. Weekly Tests for all 4 weeks across all 5 months
    const weekConfigs = [
      (1, 2, 8, 'Week 1', 6, 0.95),
      (2, 9, 15, 'Week 2', 4, 0.97),
      (3, 16, 22, 'Week 3', 2, 0.99),
      (4, 23, 29, 'Week 4', 0, 1.02),
    ];

    for (final m in monthDefs) {
      final mShort = m.$1.split(' ').first.substring(0, 3);
      for (final wc in weekConfigs) {
        final totalObt = (m.$5 * wc.$6).roundToDouble().clamp(330.0, 580.0);
        sections.add(
          ExamSectionItem(
            id: 'weekly-${m.$3}-2025-w${wc.$1}',
            title: 'Weekly Test ($mShort-2025 W${wc.$1})',
            testType: 'WEEKLY',
            month: m.$1,
            monthKey: m.$2,
            weekNumber: wc.$1,
            weekLabel: wc.$4,
            dateRange: '${wc.$2.toString().padLeft(2, '0')} $mShort 2025 - ${wc.$3.toString().padLeft(2, '0')} $mShort 2025',
            rank: m.$4 + wc.$5,
            totalMax: 600.0,
            totalObtained: totalObt,
            overallGrade: totalObt >= 420 ? 'A+' : (totalObt >= 380 ? 'A' : 'B+'),
            overallResult: 'Pass',
            marks: _createDefaultSubjectMarks(mShort, wc.$2),
          ),
        );
      }
    }

    return sections;
  }

  // Helper getters for Monthly Tests
  List<ExamSectionItem> get _monthlyExams =>
      _allExamSections.where((e) => e.testType == 'MONTHLY').toList();

  List<String> get _availableMonthlyMonths {
    const canonical = ['August 2025', 'July 2025', 'June 2025', 'May 2025', 'April 2025'];
    final months = _monthlyExams.map((e) => e.month).toSet().toList();
    if (months.isEmpty) return canonical;
    final ordered = <String>[];
    for (final m in canonical) {
      if (months.contains(m)) ordered.add(m);
    }
    for (final m in months) {
      if (!ordered.contains(m)) ordered.add(m);
    }
    return ordered;
  }

  ExamSectionItem? get _currentMonthlyExam {
    final matches = _monthlyExams.where((e) => e.month == _selectedMonthlyMonth);
    return matches.isNotEmpty ? matches.first : (_monthlyExams.isNotEmpty ? _monthlyExams.first : null);
  }

  // Helper getters for Weekly Tests
  List<ExamSectionItem> get _weeklyExams =>
      _allExamSections.where((e) => e.testType == 'WEEKLY').toList();

  List<String> get _availableWeeklyMonths {
    const canonical = ['August 2025', 'July 2025', 'June 2025', 'May 2025', 'April 2025'];
    final months = _weeklyExams.map((e) => e.month).toSet().toList();
    if (months.isEmpty) return canonical;
    final ordered = <String>[];
    for (final m in canonical) {
      if (months.contains(m)) ordered.add(m);
    }
    for (final m in months) {
      if (!ordered.contains(m)) ordered.add(m);
    }
    return ordered;
  }

  List<int> get _activeWeeksForSelectedMonth {
    final active = _weeklyExams
        .where((e) => e.month == _selectedWeeklyMonth && e.weekNumber != null)
        .map((e) => e.weekNumber!)
        .toSet()
        .toList()
      ..sort();
    if (active.isEmpty) return [1, 2, 3, 4];
    return active;
  }

  ExamSectionItem? get _currentWeeklyExam {
    final matches = _weeklyExams.where(
      (e) => e.month == _selectedWeeklyMonth && e.weekNumber == _selectedWeeklyWeek,
    );
    if (matches.isNotEmpty) return matches.first;

    final monthMatches = _weeklyExams.where((e) => e.month == _selectedWeeklyMonth);
    if (monthMatches.isNotEmpty) return monthMatches.first;

    return _weeklyExams.isNotEmpty ? _weeklyExams.first : null;
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
            'Exam & Academic Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Continuous evaluation scorecards for Monthly & Weekly test series with dynamic filters.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Performance Matrix Graph Heatmap (Top of screen)
          _buildPerformanceMatrixGraph(isDark),
          const SizedBox(height: 24),

          // 2. Monthly Tests Collapsible Card with Month Filter
          _buildMonthlyTestsCard(isDark),
          const SizedBox(height: 20),

          // 3. Weekly Tests Collapsible Card with Month & Week Filters
          _buildWeeklyTestsCard(isDark),
        ],
      ),
    );
  }

  /// Builds the Performance Matrix Heatmap with a toggle between Monthly and Weekly trends.
  Widget _buildPerformanceMatrixGraph(bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final List<ExamSectionItem> matrixSections = _matrixMode == 'MONTHLY'
        ? _monthlyExams
        : _weeklyExams;

    // Extract unique subject names
    final Set<String> subjectSet = {};
    for (final sec in _allExamSections) {
      for (final m in sec.marks) {
        subjectSet.add(m.subject);
      }
    }
    final List<String> subjects = subjectSet.toList()..sort();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Mode Toggle, and Legend
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF109F83)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Student Performance Matrix',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                          ),
                          Text(
                            _matrixMode == 'MONTHLY'
                                ? 'Multi-month continuous evaluation'
                                : 'Week-by-week subject progression',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Mode Toggle Segment: Monthly vs Weekly Matrix
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeToggleBtn('MONTHLY', 'Monthly Tests', isDark),
                          _buildModeToggleBtn('WEEKLY', 'Weekly Tests', isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Color Scale Legend Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildLegendChip('≥80% High', const Color(0xFF10B981), isDark),
                  _buildLegendChip('70-79% Good', const Color(0xFF06B6D4), isDark),
                  _buildLegendChip('50-69% Avg', const Color(0xFFF59E0B), isDark),
                  _buildLegendChip('<50% Focus', const Color(0xFFEF4444), isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Responsive Full-Width Heatmap Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double minRequiredWidth = 150.0 + 120.0 + (matrixSections.length * 90.0);
              final double gridWidth = constraints.maxWidth > minRequiredWidth ? constraints.maxWidth : minRequiredWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: gridWidth,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                'Subject / Cycle',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                            ...matrixSections.map((sec) {
                              final label = _matrixMode == 'MONTHLY'
                                  ? sec.month
                                  : '${sec.month.split(' ').first} ${sec.weekLabel ?? ''}';
                              return Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Overall Trend',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subject Matrix Rows
                      ...subjects.map((subj) {
                        final List<double?> percentages = [];
                        final List<SubjectMarkItem?> marksList = [];

                        for (final sec in matrixSections) {
                          final match = sec.marks.where((m) => m.subject == subj).firstOrNull;
                          marksList.add(match);
                          if (match != null && match.maxMarks > 0) {
                            percentages.add((match.marksObtained / match.maxMarks) * 100);
                          } else {
                            percentages.add(null);
                          }
                        }

                        final validPcts = percentages.whereType<double>().toList();
                        final double subjectAvg = validPcts.isNotEmpty
                            ? validPcts.reduce((a, b) => a + b) / validPcts.length
                            : 0.0;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Subject Title
                              SizedBox(
                                width: 150,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(subjectAvg),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subj,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Exam Cells
                              for (int i = 0; i < matrixSections.length; i++) ...[
                                Expanded(
                                  child: _buildHeatCell(
                                    sec: matrixSections[i],
                                    mark: marksList[i],
                                    pct: percentages[i],
                                    prevPct: i > 0 ? percentages[i - 1] : null,
                                    isDark: isDark,
                                  ),
                                ),
                              ],

                              // Overall Trend Badge
                              SizedBox(
                                width: 120,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(subjectAvg).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getScoreColor(subjectAvg).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '${subjectAvg.toStringAsFixed(1)}% ${_getSubjectTierLabel(subjectAvg)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _getScoreColor(subjectAvg),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 6),
                      // Matrix Footer Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                'Cycle Avg %',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            ...matrixSections.map((sec) {
                              final avg = sec.averagePercentage;
                              return Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${avg.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getScoreColor(avg),
                                      ),
                                    ),
                                    Text(
                                      'Rank ${sec.rank}',
                                      style: TextStyle(fontSize: 10, color: subColor),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: subColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleBtn(String mode, String label, bool isDark) {
    final isSelected = _matrixMode == mode;
    return InkWell(
      onTap: () => setState(() => _matrixMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF109F83)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  /// 2. Dedicated Monthly Tests Card with Month Filter Dropdown
  Widget _buildMonthlyTestsCard(bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final currentExam = _currentMonthlyExam;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expand Toggle
          InkWell(
            onTap: () => setState(() => _isMonthlyExpanded = !_isMonthlyExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF109F83)),
                        Text(
                          'Monthly Tests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF109F83).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedMonthlyMonth,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF109F83),
                            ),
                          ),
                        ),
                        if (currentExam != null)
                          Text(
                            '• Rank ${currentExam.rank} (${currentExam.averagePercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isMonthlyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: subColor,
                  ),
                ],
              ),
            ),
          ),

          if (_isMonthlyExpanded) ...[
            Divider(height: 1, color: borderColor),

            // Filter Toolbar: Month Selection Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 10,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Select Month:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _availableMonthlyMonths.contains(_selectedMonthlyMonth)
                                ? _selectedMonthlyMonth
                                : _availableMonthlyMonths.first,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF109F83)),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            items: _availableMonthlyMonths.map((m) {
                              return DropdownMenuItem<String>(
                                value: m,
                                child: Text(m),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMonthlyMonth = val;
                                  _selectedWeeklyMonth = val;
                                  final weeks = _weeklyExams
                                      .where((e) => e.month == val && e.weekNumber != null)
                                      .map((e) => e.weekNumber!)
                                      .toList();
                                  if (weeks.isNotEmpty && !weeks.contains(_selectedWeeklyWeek)) {
                                    _selectedWeeklyWeek = weeks.first;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (currentExam?.dateRange != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Icon(Icons.date_range_outlined, size: 14, color: subColor),
                        Text(
                          'Schedule: ${currentExam!.dateRange!}',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Content Table or Empty State
            if (currentExam != null)
              _buildExamDataTable(currentExam, isDark)
            else
              _buildEmptyStateCard('No Monthly Test record found for $_selectedMonthlyMonth.', isDark),
          ],
        ],
      ),
    );
  }

  /// 3. Dedicated Weekly Tests Card with Month + Week Filter Pills
  Widget _buildWeeklyTestsCard(bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final currentExam = _currentWeeklyExam;
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeWeeks = _activeWeeksForSelectedMonth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expand Toggle
          InkWell(
            onTap: () => setState(() => _isWeeklyExpanded = !_isWeeklyExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.view_week_rounded, size: 20, color: Color(0xFF06B6D4)),
                        Text(
                          'Weekly Tests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_selectedWeeklyMonth • Week $_selectedWeeklyWeek',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0891B2),
                            ),
                          ),
                        ),
                        if (currentExam != null)
                          Text(
                            '• Rank ${currentExam.rank} (${currentExam.averagePercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isWeeklyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: subColor,
                  ),
                ],
              ),
            ),
          ),

          if (_isWeeklyExpanded) ...[
            Divider(height: 1, color: borderColor),

            // Two-Tier Filter: Select Month, then Select Week
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      // Month Selector
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Month:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _availableWeeklyMonths.contains(_selectedWeeklyMonth)
                                    ? _selectedWeeklyMonth
                                    : _availableWeeklyMonths.first,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF06B6D4)),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                items: _availableWeeklyMonths.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedWeeklyMonth = val;
                                      _selectedMonthlyMonth = val;
                                      // If current week not in new month, default to first available
                                      final weeks = _weeklyExams
                                          .where((e) => e.month == val && e.weekNumber != null)
                                          .map((e) => e.weekNumber!)
                                          .toList();
                                      if (weeks.isNotEmpty && !weeks.contains(_selectedWeeklyWeek)) {
                                        _selectedWeeklyWeek = weeks.first;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Week Pill Tabs: Week 1, 2, 3, 4 wrapped in horizontal scroll
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select Week:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            for (int w = 1; w <= 4; w++) ...[
                              _buildWeekPill(
                                weekNum: w,
                                isSelected: _selectedWeeklyWeek == w,
                                hasData: activeWeeks.contains(w),
                                isDark: isDark,
                              ),
                              if (w != 4) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (currentExam?.dateRange != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Icon(Icons.date_range_outlined, size: 13, color: subColor),
                        Text(
                          'Evaluated Schedule: ${currentExam!.dateRange!}',
                          style: TextStyle(fontSize: 11.5, color: subColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Content Table or Empty State
            if (currentExam != null)
              _buildExamDataTable(currentExam, isDark)
            else
              _buildEmptyStateCard(
                'No Weekly Test record found for Week $_selectedWeeklyWeek of $_selectedWeeklyMonth.\nPlease select an active evaluation week above.',
                isDark,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekPill({
    required int weekNum,
    required bool isSelected,
    required bool hasData,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFF0891B2);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return InkWell(
      onTap: () => setState(() => _selectedWeeklyWeek = weekNum),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (hasData
                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasData && !isSelected) ...[
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF0891B2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              'Week $weekNum',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (hasData
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-width scorecard DataTable with 'Exam Date' and 'Exam Time'
  Widget _buildExamDataTable(ExamSectionItem item, bool isDark) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, tableConstraints) {
            final double tableWidth = tableConstraints.maxWidth > 920 ? tableConstraints.maxWidth : 920;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  ),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 52,
                  headingRowHeight: 44,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(label: _buildSortHeader('Subject', isDark)),
                    DataColumn(label: _buildSortHeader('Exam Date', isDark)),
                    DataColumn(label: _buildSortHeader('Exam Time', isDark)),
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
                        // 1. Subject
                        DataCell(
                          Text(
                            mark.subject,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        // 2. Exam Date
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12.5, color: subColor),
                              const SizedBox(width: 6),
                              Text(
                                mark.date,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 3. Exam Time
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: subColor),
                              const SizedBox(width: 6),
                              Text(
                                mark.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 4. Max Marks
                        DataCell(
                          Text(
                            mark.maxMarks.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 13,
                              color: subColor,
                            ),
                          ),
                        ),
                        // 5. Min Marks
                        DataCell(
                          Text(
                            mark.minMarks.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 13,
                              color: subColor,
                            ),
                          ),
                        ),
                        // 6. Marks Obtained
                        DataCell(
                          Text(
                            mark.marksObtained % 1 == 0
                                ? mark.marksObtained.toInt().toString()
                                : mark.marksObtained.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        // 7. Grade
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
                        // 8. Result
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

        // Summary Footer Bar
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
            physics: const BouncingScrollPhysics(),
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
    );
  }

  Widget _buildEmptyStateCard(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 40,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
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

  Widget _buildHeatCell({
    required ExamSectionItem sec,
    required SubjectMarkItem? mark,
    required double? pct,
    required double? prevPct,
    required bool isDark,
  }) {
    if (mark == null || pct == null) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black26),
        ),
      );
    }

    final scoreColor = _getScoreColor(pct);

    String trendText = '★';
    Color trendColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    if (prevPct != null) {
      final diff = pct - prevPct;
      if (diff > 0.5) {
        trendText = '▲ +${diff.toStringAsFixed(0)}%';
        trendColor = const Color(0xFF10B981);
      } else if (diff < -0.5) {
        trendText = '▼ ${diff.toStringAsFixed(0)}%';
        trendColor = const Color(0xFFEF4444);
      } else {
        trendText = '▬ 0%';
        trendColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      }
    }

    final tooltipMsg =
        '${mark.subject} (${sec.title})\n'
        'Score: ${mark.marksObtained.toStringAsFixed(1)} / ${mark.maxMarks.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)\n'
        'Grade: ${mark.grade} • Result: ${mark.result}\n'
        'Exam Date: ${mark.date}\n'
        'Exam Time: ${mark.time}';

    return Tooltip(
      message: tooltipMsg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              trendText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double pct) {
    if (pct >= 80) return const Color(0xFF10B981);
    if (pct >= 70) return const Color(0xFF06B6D4);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getSubjectTierLabel(double pct) {
    if (pct >= 80) return 'High';
    if (pct >= 70) return 'Good';
    if (pct >= 50) return 'Avg';
    return 'Low';
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
