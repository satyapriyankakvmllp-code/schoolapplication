import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../tabs/attendance_tab.dart';
import '../tabs/flow_ui.dart';
import '../tabs/syllabus_pattern_tab.dart';

/// Admin Exam Management Screen
/// Consolidates operational examination management tasks:
/// 1. Attendance Marking & Malpractice Records (ExamAttendanceTab)
/// 2. Configurable 100-Mark Exam Patterns & Internal Assessment Setup (ExamPatternTab)
class ExamManagementScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const ExamManagementScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen> with SingleTickerProviderStateMixin {
  String? _selectedExamScheduleId;
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No examinations scheduled yet.'),
        ),
      );
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Selection Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_outlined, size: 20, color: kExamGreen),
                const SizedBox(width: 10),
                const Text(
                  'Select Examination:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeExam.examScheduleId,
                      isExpanded: true,
                      items: exams.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.examScheduleId,
                          child: Text(
                            '${e.examName} (${e.academicYear})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExamScheduleId = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sub-Tab Switcher
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _subTabController,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: kExamGreen,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Exam Attendance'),
                Tab(icon: Icon(Icons.dashboard_customize_outlined, size: 18), text: 'Exam Patterns & Blueprint'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sub-Tab Views
          AnimatedBuilder(
            animation: _subTabController,
            builder: (context, _) {
              if (_subTabController.index == 0) {
                return ExamAttendanceTab(exam: activeExam);
              } else {
                return ExamPatternTab(exam: activeExam);
              }
            },
          ),
        ],
      ),
    );
  }
}

