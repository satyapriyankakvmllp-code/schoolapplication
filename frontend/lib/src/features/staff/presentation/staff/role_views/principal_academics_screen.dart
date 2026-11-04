import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/features/classes/presentation/admin/classes_list_screen.dart';
import 'package:frontend/src/features/classes/presentation/shared/teacher_work_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/curriculum_management_screen.dart';
import 'package:frontend/src/features/classes/presentation/admin/timetable_management_screen.dart';

enum PrincipalAcademicsTab {
  classes,
  teacherWorkload,
  curriculum,
  timetable,
}

class PrincipalAcademicsScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final PrincipalAcademicsTab initialTab;

  const PrincipalAcademicsScreen({
    super.key,
    required this.isDark,
    this.initialTab = PrincipalAcademicsTab.classes,
  });

  @override
  ConsumerState<PrincipalAcademicsScreen> createState() => _PrincipalAcademicsScreenState();
}

class _PrincipalAcademicsScreenState extends ConsumerState<PrincipalAcademicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.index);
  }

  @override
  void didUpdateWidget(covariant PrincipalAcademicsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.animateTo(widget.initialTab.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final cardBg = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;
    final subColor = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Academics Banner
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: widget.isDark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 22 : 28,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: const Icon(Icons.school, color: Colors.white, size: 26),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Governance & Curriculum Operations',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Classroom configuration, class teacher assignments, curriculum syllabus audits, and master timetable orchestration.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: subColor,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: const [
              Tab(
                child: Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Classes & Sections', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Teacher Workload', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Curriculum & Lessons', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Master Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return const AdminClassesListScreen();
                case 1:
                  return const TeacherWorkManagementScreen();
                case 2:
                  return const CurriculumManagementScreen();
                case 3:
                default:
                  return const TimetableManagementScreen();
              }
            },
          ),
        ],
      ),
    );
  }
}
