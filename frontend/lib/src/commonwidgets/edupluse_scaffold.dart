import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admissions/domain/admission_request_model.dart';
import '../features/admissions/application/admissions_controller.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/application/student_auth_controller.dart';
import '../features/authentication/application/parent_auth_controller.dart';
import '../features/staff/application/staff_auth_controller.dart';
import '../features/staff/application/staff_controller.dart';
import '../features/authentication/domain/user_model.dart';
import '../routing/route_names.dart';
import 'common_app_header.dart';

enum EdupluseNavPage {
  dashboard,
  addNewStudent,
  editStudent,
  studentList,
  studentDetails,
  studentPipeline,
  staffList,
  addNewStaff,
  editStaff,
  staffDetails,
  staffDepartments,
  teachers,
  guardian,
  classes,
  classesSubjects,
  classesSections,
  classesCurriculum,
  classesDailyLessons,
  classesTimetable,
  classesClassrooms,
  classesTeacherWork,
  examinations,
  fees,
  attendance,
  accounts,
}

class EdupluseScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final EdupluseNavPage activePage;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;
  final bool isDark;
  final bool isEmbedded;

  const EdupluseScaffold({
    super.key,
    required this.body,
    required this.activePage,
    this.onNavigate,
    this.onToggleTheme,
    this.onExitToGateway,
    this.isDark = false,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<EdupluseScaffold> createState() => _EdupluseScaffoldState();
}

class _EdupluseScaffoldState extends ConsumerState<EdupluseScaffold> {
  bool _isSidebarCollapsed = false;
  bool _isStudentsExpanded = true;
  bool _isStaffExpanded = true;
  bool _isClassesExpanded = false;

  Future<void> _handleLogout() async {
    ref.read(activeUserRoleProvider.notifier).state = null;
    ref.read(selectedStudentIdProvider.notifier).state = null;
    ref.read(selectedStaffIdProvider.notifier).state = null;
    await ref.read(staffAuthControllerProvider).logout();
    ref.read(selectedStudentUserIdProvider.notifier).state = null;
    ref.read(studentAuthControllerProvider).logout();
    ref.read(selectedParentUserIdProvider.notifier).state = null;
    ref.read(parentAuthControllerProvider).logout();

    widget.onExitToGateway?.call();

    if (mounted) {
      try {
        GoRouter.of(context).go(RouteNames.signInGateway);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return widget.body;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: SafeArea(
          child: _buildSidebarContent(isDrawer: true, isDark: isDark),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _isSidebarCollapsed ? 80 : 250,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: OverflowBox(
                  minWidth: _isSidebarCollapsed ? 80 : 250,
                  maxWidth: _isSidebarCollapsed ? 80 : 250,
                  alignment: Alignment.topLeft,
                  child: _buildSidebarContent(isDrawer: false, isDark: isDark),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                CommonAppHeader(
                  isDark: isDark,
                  isSidebarCollapsed: _isSidebarCollapsed,
                  onToggleSidebar: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  onToggleTheme: widget.onToggleTheme,
                  onLogout: _handleLogout,
                ),
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _handleNavigation(EdupluseNavPage page, bool isDrawer) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onNavigate?.call(page);
  }

  Widget _buildSidebarContent({required bool isDrawer, required bool isDark}) {
    final showLabels = isDrawer || !_isSidebarCollapsed;

    return Column(
      children: [
        // Brand Header
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              if (showLabels) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'EduPulse',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

        // Active User Profile preview
        if (showLabels) ...[
          () {
            final activeUser = ref.watch(currentUserProfileProvider);
            final activeRole = ref.watch(activeUserRoleProvider);
            final roleMeta = activeRole != null ? RoleDirectory.registry[activeRole] : null;
            final primaryColor = roleMeta?.primaryColor ?? const Color(0xFF6366F1);
            final displayName = activeUser?.fullName ?? 'Dr. Sarah Jenkins';
            final designation = roleMeta?.designation ?? 'School Administrator';

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withValues(alpha: 0.18),
                    child: Icon(roleMeta?.icon ?? Icons.person, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          designation,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                isActive: widget.activePage == EdupluseNavPage.dashboard,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleNavigation(EdupluseNavPage.dashboard, isDrawer),
              ),
              // Expandable Students Module
              _buildStudentsGroup(showLabels: showLabels, isDrawer: isDrawer, isDark: isDark),
              // Expandable Staff Module
              _buildStaffGroup(showLabels: showLabels, isDrawer: isDrawer, isDark: isDark),
              _buildNavItem(
                icon: Icons.family_restroom_outlined,
                title: 'Guardian',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Guardian', isDrawer),
              ),
              _buildClassesGroup(showLabels: showLabels, isDrawer: isDrawer, isDark: isDark),
              _buildNavItem(
                icon: Icons.quiz_outlined,
                title: 'Examinations',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Examinations', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.payments_outlined,
                title: 'Fees Collection',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Fees Collection', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                title: 'Attendance',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Attendance', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.time_to_leave_outlined,
                title: 'Leaves',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Leaves', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.card_membership_outlined,
                title: 'Certificate',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Certificate', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.menu_book_outlined,
                title: 'Library',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Library', isDrawer),
              ),
              _buildNavItem(
                icon: Icons.account_balance_outlined,
                title: 'Accounts',
                isActive: widget.activePage == EdupluseNavPage.accounts,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () {
                  if (widget.onNavigate != null) {
                    _handleNavigation(EdupluseNavPage.accounts, isDrawer);
                  } else {
                    _handleGeneralNavItem('Accounts', isDrawer);
                  }
                },
              ),
            ],
          ),
        ),
        // Logout Link at bottom of sidebar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              ),
            ),
          ),
          child: _buildNavItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            showLabels: showLabels,
            isDark: isDark,
            onTap: () async {
              if (isDrawer && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              await _handleLogout();
            },
          ),
        ),
      ],
    );
  }

  void _handleGeneralNavItem(String title, bool isDrawer) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title module is coming soon!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStudentsGroup({required bool showLabels, required bool isDrawer, required bool isDark}) {
    final counts = ref.watch(admissionRequestCountsProvider);
    final pendingCount = counts[AdmissionRequestStatus.pending] ?? 0;

    final isGroupActive = widget.activePage == EdupluseNavPage.addNewStudent ||
        widget.activePage == EdupluseNavPage.editStudent ||
        widget.activePage == EdupluseNavPage.studentDetails ||
        widget.activePage == EdupluseNavPage.studentList ||
        widget.activePage == EdupluseNavPage.studentPipeline;

    if (!showLabels) {
      return _buildNavItem(
        icon: Icons.school_outlined,
        title: 'Students',
        isActive: isGroupActive,
        showLabels: false,
        isDark: isDark,
        onTap: () {
          setState(() {
            _isSidebarCollapsed = false;
            _isStudentsExpanded = true;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isStudentsExpanded = !_isStudentsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isGroupActive ? const Color(0xFF109F83) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (pendingCount > 0 && !isGroupActive)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                Icon(
                  _isStudentsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        if (_isStudentsExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            child: Column(
              children: [
                _buildSubItem(
                  title: 'Student List',
                  isActive: widget.activePage == EdupluseNavPage.studentList ||
                      widget.activePage == EdupluseNavPage.studentDetails,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.studentList, isDrawer),
                ),
                _buildSubItem(
                  title: 'Student Pipeline',
                  isActive: widget.activePage == EdupluseNavPage.studentPipeline,
                  isDark: isDark,
                  trailingBadge: pendingCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '$pendingCount Pending',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        )
                      : null,
                  onTap: () => _handleNavigation(EdupluseNavPage.studentPipeline, isDrawer),
                ),
                _buildSubItem(
                  title: 'Add New Student',
                  isActive: widget.activePage == EdupluseNavPage.addNewStudent,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.addNewStudent, isDrawer),
                ),
                _buildSubItem(
                  title: 'Edit Student',
                  isActive: widget.activePage == EdupluseNavPage.editStudent,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.editStudent, isDrawer),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStaffGroup({required bool showLabels, required bool isDrawer, required bool isDark}) {
    final staffCounts = ref.watch(staffCountsProvider);
    final isGroupActive = widget.activePage == EdupluseNavPage.staffList ||
        widget.activePage == EdupluseNavPage.addNewStaff ||
        widget.activePage == EdupluseNavPage.editStaff ||
        widget.activePage == EdupluseNavPage.staffDetails ||
        widget.activePage == EdupluseNavPage.staffDepartments;

    if (!showLabels) {
      return _buildNavItem(
        icon: Icons.badge_outlined,
        title: 'Staff',
        isActive: isGroupActive,
        showLabels: false,
        isDark: isDark,
        onTap: () {
          setState(() {
            _isSidebarCollapsed = false;
            _isStaffExpanded = true;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isStaffExpanded = !_isStaffExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isGroupActive ? const Color(0xFF109F83) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Staff',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (staffCounts.total > 0 && !isGroupActive)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${staffCounts.total}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF109F83),
                      ),
                    ),
                  ),
                Icon(
                  _isStaffExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        if (_isStaffExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            child: Column(
              children: [
                _buildSubItem(
                  title: 'Staff Directory',
                  isActive: widget.activePage == EdupluseNavPage.staffList,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.staffList, isDrawer),
                ),
                _buildSubItem(
                  title: 'Add New Staff',
                  isActive: widget.activePage == EdupluseNavPage.addNewStaff,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.addNewStaff, isDrawer),
                ),
                _buildSubItem(
                  title: 'Edit Staff',
                  isActive: widget.activePage == EdupluseNavPage.editStaff,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.editStaff, isDrawer),
                ),
                _buildSubItem(
                  title: 'Departments & Roles',
                  isActive: widget.activePage == EdupluseNavPage.staffDepartments,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.staffDepartments, isDrawer),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClassesGroup({required bool showLabels, required bool isDrawer, required bool isDark}) {
    final activeRole = ref.watch(activeUserRoleProvider);
    final isTeacher = activeRole == UserRole.teacher;
    final isStudent = activeRole == UserRole.student;
    final isParent = activeRole == UserRole.parent;

    final isGroupActive = widget.activePage == EdupluseNavPage.classes ||
        widget.activePage == EdupluseNavPage.classesSubjects ||
        widget.activePage == EdupluseNavPage.classesSections ||
        widget.activePage == EdupluseNavPage.classesCurriculum ||
        widget.activePage == EdupluseNavPage.classesDailyLessons ||
        widget.activePage == EdupluseNavPage.classesTimetable ||
        widget.activePage == EdupluseNavPage.classesClassrooms ||
        widget.activePage == EdupluseNavPage.classesTeacherWork;

    if (!showLabels) {
      return _buildNavItem(
        icon: Icons.class_outlined,
        title: 'Classes',
        isActive: isGroupActive,
        showLabels: false,
        isDark: isDark,
        onTap: () {
          setState(() {
            _isSidebarCollapsed = false;
            _isClassesExpanded = true;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isClassesExpanded = !_isClassesExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isGroupActive ? const Color(0xFF109F83) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Classes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive ? FontWeight.w600 : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                    ),
                  ),
                ),
                Icon(
                  _isClassesExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        if (_isClassesExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            child: Column(
              children: [
                _buildSubItem(
                  title: isTeacher ? 'My Classes' : (isStudent || isParent ? 'My Class' : 'Class List'),
                  isActive: widget.activePage == EdupluseNavPage.classes,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.classes, isDrawer),
                ),
                _buildSubItem(
                  title: 'Subjects',
                  isActive: widget.activePage == EdupluseNavPage.classesSubjects,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.classesSubjects, isDrawer),
                ),
                if (!isStudent && !isParent)
                  _buildSubItem(
                    title: 'Sections',
                    isActive: widget.activePage == EdupluseNavPage.classesSections,
                    isDark: isDark,
                    onTap: () => _handleNavigation(EdupluseNavPage.classesSections, isDrawer),
                  ),
                _buildSubItem(
                  title: 'Curriculum',
                  isActive: widget.activePage == EdupluseNavPage.classesCurriculum,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.classesCurriculum, isDrawer),
                ),
                _buildSubItem(
                  title: 'Daily Lessons',
                  isActive: widget.activePage == EdupluseNavPage.classesDailyLessons,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.classesDailyLessons, isDrawer),
                ),
                _buildSubItem(
                  title: 'Timetable',
                  isActive: widget.activePage == EdupluseNavPage.classesTimetable,
                  isDark: isDark,
                  onTap: () => _handleNavigation(EdupluseNavPage.classesTimetable, isDrawer),
                ),
                if (!isStudent && !isParent)
                  _buildSubItem(
                    title: 'Classrooms',
                    isActive: widget.activePage == EdupluseNavPage.classesClassrooms,
                    isDark: isDark,
                    onTap: () => _handleNavigation(EdupluseNavPage.classesClassrooms, isDrawer),
                  ),
                if (!isStudent && !isParent)
                  _buildSubItem(
                    title: 'Teacher Work',
                    isActive: widget.activePage == EdupluseNavPage.classesTeacherWork,
                    isDark: isDark,
                    onTap: () => _handleNavigation(EdupluseNavPage.classesTeacherWork, isDrawer),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required bool showLabels,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final navContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: EdgeInsets.symmetric(horizontal: showLabels ? 12 : 8, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF109F83) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            if (showLabels) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );

    if (!showLabels) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: navContent,
      );
    }
    return navContent;
  }

  Widget _buildSubItem({
    required String title,
    bool isActive = false,
    required bool isDark,
    Widget? trailingBadge,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF109F83)
                    : (isDark ? const Color(0xFF475569) : Colors.grey.shade400),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF109F83)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailingBadge,
          ],
        ),
      ),
    );
  }
}

class DynamicMaxWidth extends BoxConstraints {
  const DynamicMaxWidth(double max) : super(maxWidth: max);
}
