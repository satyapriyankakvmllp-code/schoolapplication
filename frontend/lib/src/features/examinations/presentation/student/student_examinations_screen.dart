import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/flow_ui.dart';
import 'exam_student_screen.dart';
import 'exam_syllabus_screen.dart';
import 'exam_timetable_screen.dart';
import 'exam_hall_ticket_screen.dart';
import 'exam_results_screen.dart';
import 'exam_report_card_screen.dart';

/// Student Examinations Screen
/// Hosts the 6 student tabs directly within the screen frame:
/// Overview | Syllabus | Timetable | Hall Ticket | Results | Report Card
class StudentExaminationsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;
  final int initialTabIndex;

  const StudentExaminationsScreen({
    super.key,
    this.isDark = false,
    this.onToggleTheme,
    this.onExitToGateway,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<StudentExaminationsScreen> createState() => _StudentExaminationsScreenState();
}

class _StudentExaminationsScreenState extends ConsumerState<StudentExaminationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Syllabus'),
    Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Timetable'),
    Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Hall Ticket'),
    Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Results'),
    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Report Card'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark || Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab Navigation Bar
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: kExamGreen,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            indicatorColor: kExamGreen,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: _tabs,
          ),
        ),

        // Active Tab View Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ExamStudentScreen(),
              StudentExamSyllabusScreen(),
              StudentExamTimetableScreen(),
              StudentExamHallTicketScreen(),
              StudentExamResultsScreen(),
              StudentExamReportCardScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

