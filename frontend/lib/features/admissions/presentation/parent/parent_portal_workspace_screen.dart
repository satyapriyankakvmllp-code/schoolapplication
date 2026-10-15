import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/logout_button.dart';
import '../../application/admissions_controller.dart';
import '../../domain/admission_request_model.dart';
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

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildTopHeader(isDark: isDark, isMobile: isMobile),
          _buildNavigationTabBar(isDark: isDark, isMobile: isMobile),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildActiveTabContent(isDark: isDark, isMobile: isMobile),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top Header with Logout & Profile
  // --------------------------------------------------------------------------
  Widget _buildTopHeader({required bool isDark, required bool isMobile}) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'EduPulse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Text(
                'PARENT & GUARDIAN PORTAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Parent Profile Chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 11,
                  backgroundColor: Color(0xFF10B981),
                  child: Text('R', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                if (!isMobile) ...[
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
              ],
            ),
          ),
          const SizedBox(width: 10),
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

  // --------------------------------------------------------------------------
  // Tab Bar Navigation
  // --------------------------------------------------------------------------
  Widget _buildNavigationTabBar({required bool isDark, required bool isMobile}) {
    final requestsAsync = ref.watch(admissionRequestsListProvider);
    final myAppCount = requestsAsync.maybeWhen(
      data: (list) => list.where((r) => r.source == AdmissionRequestSource.parentPortal || r.parentFullName.contains('Sharma')).length,
      orElse: () => 0,
    );

    final tabs = [
      {'tab': ParentPortalTab.childrenOverview, 'title': 'Enrolled Children', 'icon': Icons.dashboard_outlined, 'count': 0},
      {'tab': ParentPortalTab.applyNewAdmission, 'title': 'New Child Admission', 'icon': Icons.note_add_outlined, 'count': 0},
      {'tab': ParentPortalTab.myApplications, 'title': 'My Applications & Status', 'icon': Icons.track_changes_outlined, 'count': myAppCount},
    ];

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF131D31) : Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((t) {
            final tabEnum = t['tab'] as ParentPortalTab;
            final isSelected = _activeTab == tabEnum;
            final count = t['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _activeTab = tabEnum),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.grey.shade700),
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
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Active Tab Content Router
  // --------------------------------------------------------------------------
  Widget _buildActiveTabContent({required bool isDark, required bool isMobile}) {
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 18 : 24),
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
                          label: const Text('Apply for New Child ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF047857),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 0,
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
                ),
              ),
              const SizedBox(height: 24),

              // Sibling Selection Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Selected Child:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Aarav Sharma (Grade 10-A)'),
                            selected: _selectedEnrolledChild == 'Aarav Sharma',
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedEnrolledChild == 'Aarav Sharma'
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) => setState(() => _selectedEnrolledChild = 'Aarav Sharma'),
                          ),
                          ChoiceChip(
                            label: const Text('Kabir Sharma (Grade 6-B)'),
                            selected: _selectedEnrolledChild == 'Kabir Sharma',
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedEnrolledChild == 'Kabir Sharma'
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) => setState(() => _selectedEnrolledChild = 'Kabir Sharma'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Card Snapshot
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF10B981),
                          child: Text(
                            _selectedEnrolledChild == 'Aarav Sharma' ? 'AS' : 'KS',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEnrolledChild == 'Aarav Sharma' ? 'Aarav Rajesh Sharma' : 'Kabir Rajesh Sharma',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                _selectedEnrolledChild == 'Aarav Sharma'
                                    ? 'Class 10 - Section A • Roll No: #12 • Admission: ADM-2026-0042'
                                    : 'Class 6 - Section B • Roll No: #08 • Admission: ADM-2026-0095',
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
                    const Divider(height: 30),
                    Wrap(
                      spacing: 24,
                      runSpacing: 14,
                      children: [
                        _buildStatPill('Class Teacher', _selectedEnrolledChild == 'Aarav Sharma' ? 'Mrs. Anita Desai' : 'Mr. Ramesh Bhat', Icons.school_outlined, isDark),
                        _buildStatPill('Academic Year', '2026-2027', Icons.calendar_today_outlined, isDark),
                        _buildStatPill('Attendance Rate', '95.4% (Present)', Icons.check_circle_outline, isDark),
                        _buildStatPill('Primary Alert Phone', '+91 98765 43210 (Father)', Icons.phone_outlined, isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action launchers
              Row(
                children: [
                  Expanded(
                    child: _buildActionLauncherCard(
                      title: 'Start Child Intake Application',
                      desc: 'Submit new child registration online with digital attachments',
                      icon: Icons.note_add_outlined,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      onTap: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionLauncherCard(
                      title: 'Live Application Tracker',
                      desc: 'Track review stages from screening to final administrative sign-off',
                      icon: Icons.track_changes_outlined,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      onTap: () => setState(() => _activeTab = ParentPortalTab.myApplications),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            fontSize: isMobile ? 18 : 22,
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
                    label: const Text('New Application', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              requestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading applications: $err'),
                data: (allRequests) {
                  // Filter requests submitted by parent portal or matching this parent
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

  Widget _buildApplicationTrackingCard(AdmissionRequestModel req, bool isDark, bool isMobile) {
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
          // Header Row
          Row(
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
              const SizedBox(width: 10),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Applied on ${DateFormat('dd MMMM yyyy').format(req.appliedAt)} • DOB: ${DateFormat('dd MMM yyyy').format(req.dateOfBirth)} • Blood: ${req.bloodGroup ?? "O+"}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 3-Stage Lifecycle Tracker Visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTrackingNode('1. Submitted', true, isDark),
                _buildTrackingConnector(true, isDark),
                _buildTrackingNode('2. Admin Screening', isApproved || !isRejected, isDark),
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
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
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

  Widget _buildTrackingNode(String label, bool isCompleted, bool isDark, {bool isError = false}) {
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
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
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
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Start New Application'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
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
            Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
