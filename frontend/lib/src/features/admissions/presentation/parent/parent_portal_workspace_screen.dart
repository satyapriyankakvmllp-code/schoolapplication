import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/logout_button.dart';
import '../../application/admissions_controller.dart';
import '../../domain/admission_request_model.dart';
import '../../domain/student_admission_model.dart';
import '../widgets/admission_application_wizard.dart';

enum ParentPortalTab {
  childrenOverview,
  applyNewAdmission,
  myApplications,
}

class ParentPortalWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;
  final ParentPortalTab initialTab;

  const ParentPortalWorkspaceScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onExitToGateway,
    this.initialTab = ParentPortalTab.childrenOverview,
  });

  @override
  ConsumerState<ParentPortalWorkspaceScreen> createState() =>
      _ParentPortalWorkspaceScreenState();
}

class _ParentPortalWorkspaceScreenState
    extends ConsumerState<ParentPortalWorkspaceScreen> {
  late ParentPortalTab _activeTab;
  String _selectedEnrolledChild = 'Aarav Sharma';

  // Base enrolled children mock profiles
  final List<Map<String, dynamic>> _enrolledChildren = [
    {
      'name': 'Aarav Sharma',
      'fullName': 'Aarav Rajesh Sharma',
      'grade': 'Class 10 - Section A',
      'rollNo': '#12',
      'admNo': 'ADM-2026-0042',
      'initials': 'AS',
      'teacher': 'Mrs. Anita Desai',
      'academicYear': '2026-2027',
      'attendance': '95.4% (Present)',
      'phone': '+91 98765 43210 (Father)',
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Kabir Sharma',
      'fullName': 'Kabir Rajesh Sharma',
      'grade': 'Class 6 - Section B',
      'rollNo': '#08',
      'admNo': 'ADM-2026-0095',
      'initials': 'KS',
      'teacher': 'Mr. Ramesh Bhat',
      'academicYear': '2026-2027',
      'attendance': '98.1% (Present)',
      'phone': '+91 98765 43210 (Father)',
      'color': const Color(0xFF0D9488),
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  List<Map<String, dynamic>> _getCombinedChildren(List<StudentAdmissionModel> allAdmissions) {
    final list = List<Map<String, dynamic>>.from(_enrolledChildren);

    for (final adm in allAdmissions) {
      final parentName = adm.father?.fullName ?? adm.guardian?.fullName ?? adm.mother?.fullName ?? '';
      final isSharmaParent = parentName.toLowerCase().contains('sharma') ||
          adm.user.fullName.toLowerCase().contains('sharma') ||
          adm.father?.phoneNumber == '+91 98765 43210' ||
          adm.guardian?.phoneNumber == '+91 98765 43210' ||
          adm.student.emergencyContactPhone == '+91 98765 43210';
      final alreadyExists = list.any((c) =>
          c['admNo'] == adm.student.admissionNumber ||
          c['name'] == adm.user.fullName);

      if (isSharmaParent && !alreadyExists) {
        final initials = adm.user.fullName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

        list.add({
          'name': adm.user.fullName,
          'fullName': adm.user.fullName,
          'grade': '${adm.student.className} - Section ${adm.student.section ?? "A"}',
          'rollNo': adm.student.rollNumber != null ? '#${adm.student.rollNumber}' : '#Pending',
          'admNo': adm.student.admissionNumber,
          'initials': initials.isNotEmpty ? initials : 'ST',
          'teacher': 'Assigned by Administration',
          'academicYear': adm.student.academicYear ?? '2026-2027',
          'attendance': '100% (Newly Enrolled)',
          'phone': adm.student.emergencyContactPhone ?? '+91 98765 43210 (Father)',
          'color': const Color(0xFF3B82F6),
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final requestsAsync = ref.watch(admissionRequestsListProvider);
    final myAppCount = requestsAsync.maybeWhen(
      data: (list) => list
          .where((r) =>
              r.source == AdmissionRequestSource.parentPortal ||
              r.parentFullName.toLowerCase().contains('sharma'))
          .length,
      orElse: () => 0,
    );

    return PopScope(
      canPop: _activeTab == ParentPortalTab.childrenOverview && widget.onExitToGateway == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeTab != ParentPortalTab.childrenOverview) {
          setState(() => _activeTab = ParentPortalTab.childrenOverview);
        } else {
          widget.onExitToGateway?.call();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(isDark: isDark, isMobile: isMobile),
              if (!isMobile)
                _buildNavigationTabBar(
                  isDark: isDark,
                  isMobile: isMobile,
                  myAppCount: myAppCount,
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildActiveTabContent(
                    isDark: isDark,
                    isMobile: isMobile,
                    key: ValueKey(_activeTab),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isMobile
            ? _buildMobileBottomNav(
                isDark: isDark,
                myAppCount: myAppCount,
              )
            : null,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Header: Compact & Clean on Mobile, Full on Desktop
  // --------------------------------------------------------------------------
  Widget _buildTopHeader({required bool isDark, required bool isMobile}) {
    final canGoBackToOverview = _activeTab != ParentPortalTab.childrenOverview;
    final showBackButton = canGoBackToOverview || widget.onExitToGateway != null;

    return Container(
      height: isMobile ? 62 : 70,
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
          // Back Button (Returns to Overview if in sub-tab, or to Gateway if on Overview)
          if (showBackButton) ...[
            Tooltip(
              message: canGoBackToOverview ? 'Back to Overview' : 'Back to Gateway',
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: isMobile ? 32 : 36,
                  minHeight: isMobile ? 32 : 36,
                ),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: isMobile ? 20 : 22,
                ),
                onPressed: () {
                  if (canGoBackToOverview) {
                    setState(() => _activeTab = ParentPortalTab.childrenOverview);
                  } else {
                    widget.onExitToGateway?.call();
                  }
                },
              ),
            ),
            SizedBox(width: isMobile ? 2 : 6),
          ],

          // Brand Lockup
          Container(
            width: isMobile ? 30 : 36,
            height: isMobile ? 30 : 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EduPulse',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'PARENT & GUARDIAN PORTAL',
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 8.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Parent Profile Indicator
          if (isMobile)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              icon: const CircleAvatar(
                radius: 13,
                backgroundColor: Color(0xFF10B981),
                child: Text(
                  'R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () => _showParentProfileBottomSheet(context, isDark),
              tooltip: 'Parent Profile',
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 11,
                    backgroundColor: Color(0xFF10B981),
                    child: Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rajesh Sharma (Father)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 4),
          LogoutButton(onLogout: widget.onExitToGateway),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
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

  void _showParentProfileBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF10B981),
                    child: Text(
                      'RS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rajesh Sharma',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Father • Senior Technical Lead',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildProfileDetailRow(Icons.email_outlined, 'rajesh.sharma@gmail.com', isDark),
              const SizedBox(height: 10),
              _buildProfileDetailRow(Icons.phone_outlined, '+91 98765 43210', isDark),
              const SizedBox(height: 10),
              _buildProfileDetailRow(
                Icons.location_on_outlined,
                '42 Lotus Enclave, MG Road, Bengaluru',
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Mobile Bottom Navigation Bar (Material 3 Thumb Ergonomics)
  // --------------------------------------------------------------------------
  Widget _buildMobileBottomNav({
    required bool isDark,
    required int myAppCount,
  }) {
    int currentIndex = 0;
    if (_activeTab == ParentPortalTab.applyNewAdmission) currentIndex = 1;
    if (_activeTab == ParentPortalTab.myApplications) currentIndex = 2;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.18),
        height: 64,
        onDestinationSelected: (idx) {
          setState(() {
            if (idx == 0) _activeTab = ParentPortalTab.childrenOverview;
            if (idx == 1) _activeTab = ParentPortalTab.applyNewAdmission;
            if (idx == 2) _activeTab = ParentPortalTab.myApplications;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded, color: Color(0xFF10B981)),
            label: 'Enrolled Children',
          ),
          const NavigationDestination(
            icon: Icon(Icons.note_add_outlined),
            selectedIcon: Icon(Icons.note_add_rounded, color: Color(0xFF10B981)),
            label: 'New Child Admission',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: myAppCount > 0,
              label: Text('$myAppCount'),
              child: const Icon(Icons.track_changes_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: myAppCount > 0,
              label: Text('$myAppCount'),
              child: const Icon(Icons.track_changes_rounded, color: Color(0xFF10B981)),
            ),
            label: 'My Applications',
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Desktop Top Navigation Tab Bar
  // --------------------------------------------------------------------------
  Widget _buildNavigationTabBar({
    required bool isDark,
    required bool isMobile,
    required int myAppCount,
  }) {
    final tabs = [
      {
        'tab': ParentPortalTab.childrenOverview,
        'title': 'Enrolled Children',
        'icon': Icons.dashboard_outlined,
        'count': 0,
      },
      {
        'tab': ParentPortalTab.applyNewAdmission,
        'title': 'New Child Admission',
        'icon': Icons.note_add_outlined,
        'count': 0,
      },
      {
        'tab': ParentPortalTab.myApplications,
        'title': 'My Applications & Status',
        'icon': Icons.track_changes_outlined,
        'count': myAppCount,
      },
    ];

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF131D31) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: tabs.map((t) {
          final tabEnum = t['tab'] as ParentPortalTab;
          final isSelected = _activeTab == tabEnum;
          final count = t['count'] as int;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _activeTab = tabEnum),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Active Tab Router
  // --------------------------------------------------------------------------
  Widget _buildActiveTabContent({
    required bool isDark,
    required bool isMobile,
    required Key key,
  }) {
    switch (_activeTab) {
      case ParentPortalTab.applyNewAdmission:
        return _buildApplyNewAdmissionTab(isDark, isMobile);
      case ParentPortalTab.myApplications:
        return _buildMyApplicationsTab(isDark, isMobile);
      case ParentPortalTab.childrenOverview:
        return _buildChildrenOverviewTab(isDark, isMobile);
    }
  }

  // --------------------------------------------------------------------------
  // TAB 1: Enrolled Children Overview
  // --------------------------------------------------------------------------
  Widget _buildChildrenOverviewTab(bool isDark, bool isMobile) {
    final admissionsAsync = ref.watch(admissionsListProvider);
    final childrenList = _getCombinedChildren(admissionsAsync.valueOrNull ?? []);
    final activeChild = childrenList.firstWhere(
      (c) => c['name'] == _selectedEnrolledChild,
      orElse: () => childrenList.first,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 28,
        vertical: isMobile ? 14 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with Responsive Action
              _buildHeroBanner(isDark: isDark, isMobile: isMobile),
              const SizedBox(height: 18),

              // Sibling Selection Bar
              _buildSiblingSelector(
                childrenList: childrenList,
                isDark: isDark,
                isMobile: isMobile,
              ),
              const SizedBox(height: 18),

              // Active Student Snapshot Card
              _buildStudentSnapshotCard(
                childData: activeChild,
                isDark: isDark,
                isMobile: isMobile,
              ),
              const SizedBox(height: 20),

              // Action Launchers (Stacked on mobile, side-by-side on desktop)
              _buildActionLaunchers(isDark: isDark, isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner({required bool isDark, required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Parent & Guardian Portal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back, Rajesh Sharma. Monitor active academic profiles, attendance records, and track incoming admission requests.',
              style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Apply for New Child ➔',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF047857),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Parent & Guardian Portal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Apply for New Child ➔',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF047857),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome back, Rajesh Sharma. Monitor active academic profiles, attendance records, and track incoming admission requests.',
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSiblingSelector({
    required List<Map<String, dynamic>> childrenList,
    required bool isDark,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                'Select Child Profile:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (childrenList.length <= 2)
            Row(
              children: childrenList.map((child) {
                final isSelected = _selectedEnrolledChild == child['name'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: child == childrenList.last ? 0 : 8,
                    ),
                    child: _buildChildSelectorItem(child, isSelected, isDark, isMobile),
                  ),
                );
              }).toList(),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: childrenList.map((child) {
                  final isSelected = _selectedEnrolledChild == child['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: isMobile ? 175 : 210,
                      child: _buildChildSelectorItem(child, isSelected, isDark, isMobile),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildSelectorItem(
    Map<String, dynamic> child,
    bool isSelected,
    bool isDark,
    bool isMobile,
  ) {
    return InkWell(
      onTap: () => setState(() => _selectedEnrolledChild = child['name'] as String),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: isMobile ? 12 : 14,
              backgroundColor: child['color'] as Color,
              child: Text(
                child['initials'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child['name'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    child['grade'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSnapshotCard({
    required Map<String, dynamic> childData,
    required bool isDark,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 22 : 26,
                backgroundColor: childData['color'] as Color,
                child: Text(
                  childData['initials'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childData['fullName'] as String,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${childData['grade']} • Roll No: ${childData['rollNo']} • ${childData['admNo']}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          // Responsive Stats
          if (isMobile)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _buildStatTile(
                  'Class Teacher',
                  childData['teacher'] as String,
                  Icons.school_outlined,
                  isDark,
                ),
                _buildStatTile(
                  'Academic Year',
                  childData['academicYear'] as String,
                  Icons.calendar_today_outlined,
                  isDark,
                ),
                _buildStatTile(
                  'Attendance Rate',
                  childData['attendance'] as String,
                  Icons.check_circle_outline,
                  isDark,
                ),
                _buildStatTile(
                  'Alert Contact',
                  childData['phone'] as String,
                  Icons.phone_outlined,
                  isDark,
                ),
              ],
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                _buildStatPill('Class Teacher', childData['teacher'] as String, Icons.school_outlined, isDark),
                _buildStatPill('Academic Year', childData['academicYear'] as String, Icons.calendar_today_outlined, isDark),
                _buildStatPill('Attendance Rate', childData['attendance'] as String, Icons.check_circle_outline, isDark),
                _buildStatPill('Primary Alert Phone', childData['phone'] as String, Icons.phone_outlined, isDark),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLaunchers({required bool isDark, required bool isMobile}) {
    final card1 = _buildActionLauncherCard(
      title: 'Start Child Intake Application',
      desc: 'Submit new child registration online with digital attachments',
      icon: Icons.note_add_outlined,
      color: const Color(0xFF10B981),
      isDark: isDark,
      onTap: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
    );

    final card2 = _buildActionLauncherCard(
      title: 'Live Application Tracker',
      desc: 'Track review stages from screening to final administrative sign-off',
      icon: Icons.track_changes_outlined,
      color: const Color(0xFF6366F1),
      isDark: isDark,
      onTap: () => setState(() => _activeTab = ParentPortalTab.myApplications),
    );

    if (isMobile) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: 16),
        Expanded(child: card2),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: New Child Admission Application (3-Step Wizard)
  // --------------------------------------------------------------------------
  Widget _buildApplyNewAdmissionTab(bool isDark, bool isMobile) {
    // Pre-populate with logged in parent profile
    final prefilledParentData = AdmissionRequestModel(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch % 100000}',
      applicantFirstName: '',
      applicantLastName: '',
      gender: 'MALE',
      dateOfBirth: DateTime(2018, 5, 12),
      gradeApplied: 'Class 1',
      parentFullName: 'Rajesh Sharma',
      parentRelationship: 'Father',
      parentPhone: '+91 98765 43210',
      parentEmail: 'rajesh.sharma@gmail.com',
      parentOccupation: 'Senior Technical Lead',
      currentAddress: '42 Lotus Enclave, MG Road, Bengaluru, Karnataka - 560001',
      emergencyContactPhone: '+91 98765 43210',
      source: AdmissionRequestSource.parentPortal,
      status: AdmissionRequestStatus.pending,
      appliedAt: DateTime.now(),
    );

    return AdmissionApplicationWizard(
      source: AdmissionRequestSource.parentPortal,
      initialData: prefilledParentData,
      isDark: isDark,
      onCancel: () => setState(() => _activeTab = ParentPortalTab.childrenOverview),
      onSubmitted: (req) async {
        await ref.read(admissionRequestsListProvider.notifier).createRequest(req);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Application ${req.id} for ${req.applicantFullName} successfully submitted to School Administration!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          // Switch to tracker tab
          setState(() => _activeTab = ParentPortalTab.myApplications);
        }
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: My Applications & Status Tracker
  // --------------------------------------------------------------------------
  Widget _buildMyApplicationsTab(bool isDark, bool isMobile) {
    final requestsAsync = ref.watch(admissionRequestsListProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 28,
        vertical: isMobile ? 14 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back to Overview quick link
              InkWell(
                onTap: () => setState(() => _activeTab = ParentPortalTab.childrenOverview),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        'Back to Children Overview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isMobile) ...[
                Text(
                  'Admission Applications & Status Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live tracking of submitted applications from submission to Admin enrollment',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'New Application',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admission Applications & Status Tracker',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Live tracking of submitted applications from submission to Admin enrollment',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'New Application',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              requestsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error loading applications: $err'),
                  ),
                ),
                data: (allRequests) {
                  final myRequests = allRequests.where((r) {
                    return r.source == AdmissionRequestSource.parentPortal ||
                        r.parentFullName.toLowerCase().contains('sharma');
                  }).toList();

                  if (myRequests.isEmpty) {
                    return _buildEmptyApplicationsState(isDark);
                  }

                  return Column(
                    children: myRequests.map((req) {
                      return _buildApplicationTrackingCard(req, isDark, isMobile);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationTrackingCard(
    AdmissionRequestModel req,
    bool isDark,
    bool isMobile,
  ) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (req.status) {
      case AdmissionRequestStatus.approved:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Approved & Enrolled';
        statusIcon = Icons.check_circle_rounded;
        break;
      case AdmissionRequestStatus.rejected:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Application Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      case AdmissionRequestStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending Admin Review';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final isApproved = req.status == AdmissionRequestStatus.approved;
    final isRejected = req.status == AdmissionRequestStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badges - Responsive Wrap for mobile
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.id,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.gradeApplied,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Applicant Name & Details
          Text(
            req.applicantFullName,
            style: TextStyle(
              fontSize: isMobile ? 16 : 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Applied on ${DateFormat('dd MMMM yyyy').format(req.appliedAt)} • DOB: ${DateFormat('dd MMM yyyy').format(req.dateOfBirth)} • Blood: ${req.bloodGroup ?? "O+"}',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 3-Stage Lifecycle Tracker Visual (Responsive)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isMobile
                ? _buildMobileTrackingProgress(
                    isApproved: isApproved,
                    isRejected: isRejected,
                    isDark: isDark,
                  )
                : Row(
                    children: [
                      _buildTrackingNode('1. Submitted', true, isDark),
                      _buildTrackingConnector(true, isDark),
                      _buildTrackingNode(
                        '2. Admin Screening',
                        isApproved || !isRejected,
                        isDark,
                      ),
                      _buildTrackingConnector(isApproved, isDark),
                      _buildTrackingNode(
                        isRejected ? '3. Rejected' : '3. Final Enrollment',
                        isApproved,
                        isDark,
                        isError: isRejected,
                      ),
                    ],
                  ),
          ),

          if (isRejected && req.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Rejection Feedback: ${req.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileTrackingProgress({
    required bool isApproved,
    required bool isRejected,
    required bool isDark,
  }) {
    String currentStageDesc;
    if (isApproved) {
      currentStageDesc = 'Stage 3 of 3: Enrollment complete & verified by Admin';
    } else if (isRejected) {
      currentStageDesc = 'Application rejected during administrative screening';
    } else {
      currentStageDesc = 'Stage 2 of 3: Under review by School Admissions Desk';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildNumberedProgressNode(1, 'Submitted', true, isDark),
            _buildTrackingConnector(true, isDark),
            _buildNumberedProgressNode(
              2,
              'Screening',
              isApproved || !isRejected,
              isDark,
            ),
            _buildTrackingConnector(isApproved, isDark),
            _buildNumberedProgressNode(
              3,
              isRejected ? 'Rejected' : 'Enrolled',
              isApproved,
              isDark,
              isError: isRejected,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          currentStageDesc,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isRejected
                ? const Color(0xFFEF4444)
                : (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedProgressNode(
    int stepNumber,
    String label,
    bool isCompleted,
    bool isDark, {
    bool isError = false,
  }) {
    Color color;
    if (isError) {
      color = const Color(0xFFEF4444);
    } else if (isCompleted) {
      color = const Color(0xFF10B981);
    } else {
      color = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color,
          child: isCompleted
              ? Icon(
                  isError ? Icons.close : Icons.check,
                  size: 11,
                  color: Colors.white,
                )
              : Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingNode(
    String label,
    bool isCompleted,
    bool isDark, {
    bool isError = false,
  }) {
    Color color;
    if (isError) {
      color = const Color(0xFFEF4444);
    } else if (isCompleted) {
      color = const Color(0xFF10B981);
    } else {
      color = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: color,
          child: Icon(
            isError ? Icons.close : (isCompleted ? Icons.check : Icons.circle),
            size: 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingConnector(bool isDone, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildEmptyApplicationsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Applications Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You haven’t submitted any new student applications yet.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Start New Application'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionLauncherCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
