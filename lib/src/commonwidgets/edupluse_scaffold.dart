import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/admissions/domain/admission_request_model.dart';
import '../features/admissions/application/admissions_controller.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/staff/application/staff_controller.dart';
import '../features/authentication/domain/user_model.dart';
import 'logout_button.dart';

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
  classesTimetable,
  classesClassrooms,
  classesTeacherWork,
  examinations,
  fees,
  attendance,
}

class EdupluseScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final EdupluseNavPage activePage;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;
  final bool isDark;

  const EdupluseScaffold({
    super.key,
    required this.body,
    required this.activePage,
    this.onNavigate,
    this.onToggleTheme,
    this.onExitToGateway,
    this.isDark = false,
  });

  @override
  ConsumerState<EdupluseScaffold> createState() => _EdupluseScaffoldState();
}

class _EdupluseScaffoldState extends ConsumerState<EdupluseScaffold> {
  bool _isSidebarCollapsed = false;
  bool _isStudentsExpanded = true;
  bool _isStaffExpanded = true;
  bool _isClassesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;
    final isDark =
        Theme.of(context).brightness == Brightness.dark || widget.isDark;

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
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
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
                _buildTopHeader(
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  isDark: isDark,
                ),
                Expanded(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF1F5F9),
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

  Widget _buildTopHeader({
    required bool isDesktop,
    required bool isMobile,
    required bool isDark,
  }) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isDesktop)
            IconButton(
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                color: isDark ? Colors.white : Colors.grey.shade700,
              ),
              tooltip: _isSidebarCollapsed
                  ? 'Expand Sidebar'
                  : 'Collapse Sidebar',
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            )
          else
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDark ? Colors.white : Colors.grey.shade700,
                ),
                tooltip: 'Open Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          const SizedBox(width: 8),
          // Search Bar (Expanded on Desktop, Icon on Tablet/Mobile)
          if (isDesktop)
            Flexible(
              child: InkWell(
                onTap: () => _openSearchDialog(context, isDark),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search students by name, id...',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Quick Search',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.search,
                color: isDark ? Colors.white : Colors.grey.shade700,
              ),
              onPressed: () => _openSearchDialog(context, isDark),
              tooltip: 'Search Students',
            ),
          const Spacer(),
          // Active User Badge
          () {
            final activeUser = ref.watch(currentUserProfileProvider);
            final activeRole = ref.watch(activeUserRoleProvider);
            final roleMeta = activeRole != null
                ? RoleDirectory.registry[activeRole]
                : null;
            final primaryColor =
                roleMeta?.primaryColor ?? const Color(0xFF6366F1);
            final roleLabel = roleMeta?.shortLabel ?? 'Admin';

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: primaryColor,
                    child: Text(
                      (activeUser?.firstName ?? 'A')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }(),
          const SizedBox(width: 8),
          // Logout Button
          LogoutButton(onLogout: widget.onExitToGateway),
          const SizedBox(width: 8),
          // Action Icons
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : Colors.grey.shade700,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          if (!isMobile) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
          const SizedBox(width: 4),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 22),
                color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
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
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),

        // Active User Profile preview
        if (showLabels) ...[
          () {
            final activeUser = ref.watch(currentUserProfileProvider);
            final activeRole = ref.watch(activeUserRoleProvider);
            final roleMeta = activeRole != null
                ? RoleDirectory.registry[activeRole]
                : null;
            final primaryColor =
                roleMeta?.primaryColor ?? const Color(0xFF6366F1);
            final displayName = activeUser?.fullName ?? 'Dr. Sarah Jenkins';
            final designation = roleMeta?.designation ?? 'School Administrator';

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withValues(alpha: 0.18),
                    child: Icon(
                      roleMeta?.icon ?? Icons.person,
                      color: primaryColor,
                      size: 20,
                    ),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          designation,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey,
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
                onTap: () =>
                    _handleNavigation(EdupluseNavPage.dashboard, isDrawer),
              ),
              // Expandable Students Module
              _buildStudentsGroup(
                showLabels: showLabels,
                isDrawer: isDrawer,
                isDark: isDark,
              ),
              // Expandable Staff Module
              _buildStaffGroup(
                showLabels: showLabels,
                isDrawer: isDrawer,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.family_restroom_outlined,
                title: 'Guardian',
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Guardian', isDrawer),
              ),
              _buildClassesGroup(
                showLabels: showLabels,
                isDrawer: isDrawer,
                isDark: isDark,
              ),
              _buildNavItem(
                icon: Icons.quiz_outlined,
                title: 'Examinations',
                showLabels: showLabels,
                isDark: isDark,
                isActive: widget.activePage == EdupluseNavPage.examinations,
                onTap: () => _handleNavigation(EdupluseNavPage.examinations, isDrawer),
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
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _handleGeneralNavItem('Accounts', isDrawer),
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
            onTap: () {
              if (isDrawer && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ref.read(activeUserRoleProvider.notifier).state = null;
              widget.onExitToGateway?.call();
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

  Widget _buildStudentsGroup({
    required bool showLabels,
    required bool isDrawer,
    required bool isDark,
  }) {
    final counts = ref.watch(admissionRequestCountsProvider);
    final pendingCount = counts[AdmissionRequestStatus.pending] ?? 0;

    final isGroupActive =
        widget.activePage == EdupluseNavPage.addNewStudent ||
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
              color: isGroupActive
                  ? const Color(0xFF109F83)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (pendingCount > 0 && !isGroupActive)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      ),
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
                  _isStudentsExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade500),
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
                  isActive:
                      widget.activePage == EdupluseNavPage.studentList ||
                      widget.activePage == EdupluseNavPage.studentDetails,
                  isDark: isDark,
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.studentList, isDrawer),
                ),
                _buildSubItem(
                  title: 'Student Pipeline',
                  isActive:
                      widget.activePage == EdupluseNavPage.studentPipeline,
                  isDark: isDark,
                  trailingBadge: pendingCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.5),
                            ),
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
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.studentPipeline,
                    isDrawer,
                  ),
                ),
                _buildSubItem(
                  title: 'Add New Student',
                  isActive: widget.activePage == EdupluseNavPage.addNewStudent,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.addNewStudent,
                    isDrawer,
                  ),
                ),
                _buildSubItem(
                  title: 'Edit Student',
                  isActive: widget.activePage == EdupluseNavPage.editStudent,
                  isDark: isDark,
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.editStudent, isDrawer),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStaffGroup({
    required bool showLabels,
    required bool isDrawer,
    required bool isDark,
  }) {
    final staffCounts = ref.watch(staffCountsProvider);
    final isGroupActive =
        widget.activePage == EdupluseNavPage.staffList ||
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
              color: isGroupActive
                  ? const Color(0xFF109F83)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Staff',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (staffCounts.total > 0 && !isGroupActive)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF109F83).withValues(alpha: 0.4),
                      ),
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
                  _isStaffExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade500),
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
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.staffList, isDrawer),
                ),
                _buildSubItem(
                  title: 'Add New Staff',
                  isActive: widget.activePage == EdupluseNavPage.addNewStaff,
                  isDark: isDark,
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.addNewStaff, isDrawer),
                ),
                _buildSubItem(
                  title: 'Edit Staff',
                  isActive: widget.activePage == EdupluseNavPage.editStaff,
                  isDark: isDark,
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.editStaff, isDrawer),
                ),
                _buildSubItem(
                  title: 'Departments & Roles',
                  isActive:
                      widget.activePage == EdupluseNavPage.staffDepartments,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.staffDepartments,
                    isDrawer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClassesGroup({
    required bool showLabels,
    required bool isDrawer,
    required bool isDark,
  }) {
    final activeRole = ref.watch(activeUserRoleProvider);
    final isAdmin = activeRole == UserRole.admin;
    final isTeacher = activeRole == UserRole.teacher;
    final isStudent = activeRole == UserRole.student;
    final isParent = activeRole == UserRole.parent;

    final isGroupActive =
        widget.activePage == EdupluseNavPage.classes ||
        widget.activePage == EdupluseNavPage.classesSubjects ||
        widget.activePage == EdupluseNavPage.classesSections ||
        widget.activePage == EdupluseNavPage.classesCurriculum ||
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
              color: isGroupActive
                  ? const Color(0xFF109F83)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 20,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Classes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isGroupActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isGroupActive
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF334155)),
                    ),
                  ),
                ),
                Icon(
                  _isClassesExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color: isGroupActive
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade500),
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
                  title: isTeacher
                      ? 'My Classes'
                      : (isStudent || isParent
                            ? 'My Class'
                            : 'Academic Classes'),
                  isActive: widget.activePage == EdupluseNavPage.classes,
                  isDark: isDark,
                  onTap: () =>
                      _handleNavigation(EdupluseNavPage.classes, isDrawer),
                ),
                if (isAdmin)
                  _buildSubItem(
                    title: 'Class Rooms',
                    alias: 'Classrooms',
                    isActive:
                        widget.activePage == EdupluseNavPage.classesClassrooms,
                    isDark: isDark,
                    onTap: () => _handleNavigation(
                      EdupluseNavPage.classesClassrooms,
                      isDrawer,
                    ),
                  ),
                if (!isStudent && !isParent)
                  _buildSubItem(
                    title: 'Sections',
                    isActive:
                        widget.activePage == EdupluseNavPage.classesSections,
                    isDark: isDark,
                    onTap: () => _handleNavigation(
                      EdupluseNavPage.classesSections,
                      isDrawer,
                    ),
                  ),
                _buildSubItem(
                  title: 'Subjects',
                  isActive:
                      widget.activePage == EdupluseNavPage.classesSubjects,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.classesSubjects,
                    isDrawer,
                  ),
                ),
                _buildSubItem(
                  title: 'Timetable',
                  isActive:
                      widget.activePage == EdupluseNavPage.classesTimetable,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.classesTimetable,
                    isDrawer,
                  ),
                ),
                _buildSubItem(
                  title: 'Curriculum',
                  isActive:
                      widget.activePage == EdupluseNavPage.classesCurriculum,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.classesCurriculum,
                    isDrawer,
                  ),
                ),
                _buildSubItem(
                  title: 'Assignments',
                  alias: isStudent || isParent ? null : 'Teacher Work',
                  isActive:
                      widget.activePage == EdupluseNavPage.classesTeacherWork,
                  isDark: isDark,
                  onTap: () => _handleNavigation(
                    EdupluseNavPage.classesTeacherWork,
                    isDrawer,
                  ),
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
        padding: EdgeInsets.symmetric(
          horizontal: showLabels ? 12 : 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF109F83) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: showLabels
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
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
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
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
      return Tooltip(message: title, preferBelow: false, child: navContent);
    }
    return navContent;
  }

  Widget _buildSubItem({
    required String title,
    String? alias,
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
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (alias != null)
                    Opacity(
                      opacity: 0.0,
                      child: Text(alias, style: const TextStyle(fontSize: 1)),
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? const Color(0xFF109F83)
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ?trailingBadge,
          ],
        ),
      ),
    );
  }

  void _openSearchDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => _StudentSearchDialog(
        isDark: isDark,
        onSelectStudent: (studentId) {
          ref.read(selectedStudentIdProvider.notifier).state = studentId;
          widget.onNavigate?.call(EdupluseNavPage.studentDetails);
        },
      ),
    );
  }
}

class _StudentSearchDialog extends ConsumerStatefulWidget {
  final bool isDark;
  final ValueChanged<String> onSelectStudent;
  const _StudentSearchDialog({
    required this.isDark,
    required this.onSelectStudent,
  });

  @override
  ConsumerState<_StudentSearchDialog> createState() =>
      _StudentSearchDialogState();
}

class _StudentSearchDialogState extends ConsumerState<_StudentSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admissionsAsync = ref.watch(admissionsListProvider);
    final query = _controller.text.toLowerCase().trim();
    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF109F83), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Quick Search Students',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type student name, admission no, roll no...',
                prefixIcon: const Icon(Icons.school_outlined, size: 18),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _controller.clear()),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: admissionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF109F83)),
                ),
                error: (err, _) => Center(child: Text('Error loading: $err')),
                data: (students) {
                  final filtered = students.where((s) {
                    if (query.isEmpty) return true;
                    return s.user.fullName.toLowerCase().contains(query) ||
                        s.student.admissionNumber.toLowerCase().contains(
                          query,
                        ) ||
                        (s.student.rollNumber ?? '').toLowerCase().contains(
                          query,
                        ) ||
                        s.student.className.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No students match "$query"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFDCFCE7),
                          child: Text(
                            s.user.firstName.isNotEmpty
                                ? s.user.firstName[0]
                                : 'S',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF109F83),
                            ),
                          ),
                        ),
                        title: Text(
                          s.user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          '${s.student.admissionNumber} • Roll: ${s.student.rollNumber ?? 'N/A'} • ${s.student.className}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF109F83),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelectStudent(s.student.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicMaxWidth extends BoxConstraints {
  const DynamicMaxWidth(double max) : super(maxWidth: max);
}
