import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tabs/flow_ui.dart';
import 'exam_list_screen.dart';
import 'exam_syllabus_screen.dart';
import 'exam_timetable_screen.dart';
import 'question_papers_screen.dart';
import 'hall_tickets_screen.dart';
import 'exam_management_screen.dart';
import 'marks_review_screen.dart';
import 'results_screen.dart';
import 'report_cards_screen.dart';

/// Admin Examinations Screen
/// Hosts the 9 unified admin tabs directly within the screen frame:
/// Exams | Syllabus | Timetable | Question Papers | Hall Tickets | Exam Management | Marks | Results | Report Cards
class AdminExaminationsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;
  final int initialTabIndex;

  const AdminExaminationsScreen({
    super.key,
    this.isDark = false,
    this.onToggleTheme,
    this.onExitToGateway,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<AdminExaminationsScreen> createState() => _AdminExaminationsScreenState();
}

class _AdminExaminationsScreenState extends ConsumerState<AdminExaminationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Exams'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Syllabus'),
    Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Timetable'),
    Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Question Papers'),
    Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Hall Tickets'),
    Tab(icon: Icon(Icons.manage_accounts_outlined, size: 18), text: 'Exam Management'),
    Tab(icon: Icon(Icons.rate_review_outlined, size: 18), text: 'Marks Review'),
    Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Results'),
    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Report Cards'),
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

        // Active Tab Screen Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const ExamListScreen(),
              const ExamSyllabusScreen(),
              const ExamTimetableScreen(),
              const QuestionPapersScreen(),
              const HallTicketsScreen(),
              const ExamManagementScreen(),
              const MarksReviewScreen(),
              const AdminResultsScreen(),
              const AdminReportCardsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
