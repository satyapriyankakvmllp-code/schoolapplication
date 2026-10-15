import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/frontdesk_controller.dart';
import '../../../data/models/admission_request_model.dart';
import 'frontdesk_new_application_screen.dart';
import 'frontdesk_dashboard_screen.dart';
import 'inquiry_desk_screen.dart';
import 'document_verification_queue_screen.dart';
import 'interview_scheduler_screen.dart';
import 'id_badge_studio_screen.dart';
import 'frontdesk_student_lookup_screen.dart';
import '../../../../auth/presentation/widgets/logout_button.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';

class FrontDeskWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;

  const FrontDeskWorkspaceScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onExitToGateway,
  });

  @override
  ConsumerState<FrontDeskWorkspaceScreen> createState() => _FrontDeskWorkspaceScreenState();
}

class _FrontDeskWorkspaceScreenState extends ConsumerState<FrontDeskWorkspaceScreen> {
  bool _isSidebarCollapsed = false;

  void _navigateTo(FrontDeskPage page, {bool isDrawer = false}) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(frontDeskActivePageProvider.notifier).state = page;
  }

  @override
  Widget build(BuildContext context) {
    final activePage = ref.watch(frontDeskActivePageProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;
    final isDark = widget.isDark;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: SafeArea(
          child: _buildSidebarContent(activePage, isDrawer: true, isDark: isDark),
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
                width: _isSidebarCollapsed ? 80 : 255,
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
                  minWidth: _isSidebarCollapsed ? 80 : 255,
                  maxWidth: _isSidebarCollapsed ? 80 : 255,
                  alignment: Alignment.topLeft,
                  child: _buildSidebarContent(activePage, isDrawer: false, isDark: isDark),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(isDesktop: isDesktop, isMobile: isMobile, isDark: isDark),
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                    child: _buildActivePageContent(activePage, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader({required bool isDesktop, required bool isMobile, required bool isDark}) {
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
              tooltip: _isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            )
          else
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.grey.shade700),
                tooltip: 'Open Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FRONT-DESK DESK',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF59E0B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          // Officer Identity Chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: Color(0xFFF59E0B),
                  child: Text('P', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Priya Verma',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Logout Button
          LogoutButton(onLogout: widget.onExitToGateway),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : Colors.grey.shade700,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(FrontDeskPage activePage, {required bool isDrawer, required bool isDark}) {
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
                    colors: [Color(0xFFF59E0B), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
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

        // Officer Profile Card
        if (showLabels)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Text('PV', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priya Verma',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admissions Officer',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
              ],
            ),
          ),

        // Navigation Items (Option A: Full Admissions Lifecycle)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                isActive: activePage == FrontDeskPage.dashboard,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.dashboard, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.question_answer_outlined,
                title: 'Inquiries & Leads',
                isActive: activePage == FrontDeskPage.inquiries,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.inquiries, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.note_add_outlined,
                title: 'New Application',
                isActive: activePage == FrontDeskPage.draftIntake,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.draftIntake, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.fact_check_outlined,
                title: 'Document Verification',
                isActive: activePage == FrontDeskPage.documentQueue,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.documentQueue, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.event_available_outlined,
                title: 'Interview Scheduler',
                isActive: activePage == FrontDeskPage.interviewScheduler,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.interviewScheduler, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.badge_outlined,
                title: 'Student ID Cards',
                isActive: activePage == FrontDeskPage.idBadgeStudio,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.idBadgeStudio, isDrawer: isDrawer),
              ),
              _buildNavItem(
                icon: Icons.manage_search_outlined,
                title: 'Student Directory Lookup',
                isActive: activePage == FrontDeskPage.studentLookup,
                showLabels: showLabels,
                isDark: isDark,
                onTap: () => _navigateTo(FrontDeskPage.studentLookup, isDrawer: isDrawer),
              ),
            ],
          ),
        ),

        // Logout Link at bottom of sidebar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
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

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required bool showLabels,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: activeColor.withValues(alpha: isDark ? 0.15 : 0.08),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: showLabels ? 14 : 0, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? activeColor.withValues(alpha: isDark ? 0.4 : 0.25) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? activeColor : (isDark ? Colors.white : const Color(0xFF334155)),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePageContent(FrontDeskPage page, bool isDark) {
    switch (page) {
      case FrontDeskPage.inquiries:
        return InquiryDeskScreen(
          isDark: isDark,
          onConvertToApplication: () => ref.read(frontDeskActivePageProvider.notifier).state = FrontDeskPage.draftIntake,
        );
      case FrontDeskPage.draftIntake:
        final draftInq = ref.watch(frontDeskDraftInquiryProvider);
        AdmissionRequestModel? initialModel;
        if (draftInq != null) {
          final names = draftInq.applicantName.split(' ');
          final fName = names.isNotEmpty ? names.first : '';
          final lName = names.length > 1 ? names.sublist(1).join(' ') : '';
          initialModel = AdmissionRequestModel(
            id: 'REQ-${draftInq.id.replaceAll(RegExp(r'[^0-9]'), '')}',
            applicantFirstName: fName,
            applicantLastName: lName,
            gender: 'MALE',
            dateOfBirth: DateTime(2018, 5, 12),
            gradeApplied: draftInq.gradeApplying.isNotEmpty ? draftInq.gradeApplying : 'Class 1',
            parentFullName: draftInq.parentName,
            parentPhone: draftInq.parentPhone,
            parentEmail: draftInq.parentEmail,
            currentAddress: '',
            emergencyContactPhone: draftInq.parentPhone,
            source: AdmissionRequestSource.frontDesk,
            status: AdmissionRequestStatus.pending,
            appliedAt: DateTime.now(),
            notes: 'Converted from Front-Desk Inquiry ${draftInq.id}. ${draftInq.notes}',
          );
        }
        return FrontDeskNewApplicationScreen(
          isDark: isDark,
          prefilledData: initialModel,
          onCancel: () {
            ref.read(frontDeskDraftInquiryProvider.notifier).state = null;
            ref.read(frontDeskActivePageProvider.notifier).state = FrontDeskPage.dashboard;
          },
          onSubmittedSuccess: () {
            ref.read(frontDeskDraftInquiryProvider.notifier).state = null;
            ref.read(frontDeskActivePageProvider.notifier).state = FrontDeskPage.dashboard;
          },
        );
      case FrontDeskPage.documentQueue:
        return DocumentVerificationQueueScreen(isDark: isDark);
      case FrontDeskPage.interviewScheduler:
        return InterviewSchedulerScreen(isDark: isDark);
      case FrontDeskPage.idBadgeStudio:
        return IdBadgeStudioScreen(isDark: isDark);
      case FrontDeskPage.studentLookup:
        return FrontDeskStudentLookupScreen(
          isDark: isDark,
          onNavigateFrontDesk: (p) => ref.read(frontDeskActivePageProvider.notifier).state = p,
        );
      case FrontDeskPage.dashboard:
        return FrontDeskDashboardScreen(
          isDark: isDark,
          onNavigateFrontDesk: (p) => ref.read(frontDeskActivePageProvider.notifier).state = p,
          onNewInquiry: () => ref.read(frontDeskActivePageProvider.notifier).state = FrontDeskPage.inquiries,
        );
    }
  }
}
