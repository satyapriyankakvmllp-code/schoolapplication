import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../tabs/flow_ui.dart';
import '../tabs/marks_review_tab.dart';

/// Admin Marks Review Screen
/// Allows Admin / Principal to review and approve marks entered by teachers:
/// 1. Exam selector dropdown
/// 2. Class, Section, and Subject filters
/// 3. Student marks roster with status (Draft, Submitted, Approved, Rejected)
/// 4. Approve All, Single Approve, and Reject with Reason workflow
class MarksReviewScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const MarksReviewScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<MarksReviewScreen> createState() => _MarksReviewScreenState();
}

class _MarksReviewScreenState extends ConsumerState<MarksReviewScreen> {
  String? _selectedExamScheduleId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
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
                const Icon(Icons.rate_review_outlined, size: 20, color: kExamGreen),
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

          // Main Marks Review Tab
          MarksReviewTab(exam: activeExam),
        ],
      ),
    );
  }
}

