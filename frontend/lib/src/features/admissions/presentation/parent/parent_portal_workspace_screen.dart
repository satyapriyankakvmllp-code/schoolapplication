import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/common_app_header.dart';
import '../../../../utils/dynamic_data_client.dart';
import '../../application/admissions_controller.dart';
import '../../domain/admission_request_model.dart';
import '../../domain/student_admission_model.dart';
import '../widgets/admission_application_wizard.dart';

final parentApplicationDraftProvider =
    StateNotifierProvider<ParentApplicationDraftNotifier, AdmissionRequestModel?>((ref) {
  return ParentApplicationDraftNotifier();
});

class ParentApplicationDraftNotifier extends StateNotifier<AdmissionRequestModel?> {
  static const String _draftStorageKey = 'edupulse_saved_parent_application_draft';
  final DynamicDataClient _client;

  ParentApplicationDraftNotifier({DynamicDataClient? client})
      : _client = client ?? DynamicDataClient.instance,
        super(null) {
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final raw = await _client.getAll(
        assetPath: '',
        storageKey: _draftStorageKey,
      );
      if (raw.isNotEmpty) {
        state = AdmissionRequestModel.fromJson(raw.first);
      }
    } catch (_) {}
  }

  Future<void> saveDraft(AdmissionRequestModel draft) async {
    state = draft;
    try {
      await _client.syncAll(
        assetPath: '',
        storageKey: _draftStorageKey,
        items: [draft.toJson()],
      );
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    state = null;
    try {
      await _client.syncAll(
        assetPath: '',
        storageKey: _draftStorageKey,
        items: [],
      );
    } catch (_) {}
  }
}

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
      'className': 'Class 10',
      'section': 'Section A',
      'rollNo': '#12',
      'admNo': 'ADM-2026-0042',
      'initials': 'AS',
      'gender': 'Male',
      'dob': '14 May 2010 (16 years)',
      'bloodGroup': 'B+',
      'houseGroup': 'Shivaji House (Green)',
      'secondLanguage': 'Sanskrit',
      'medium': 'English Medium',
      'admissionDate': '12 June 2020',
      'teacher': 'Mrs. Anita Desai',
      'academicYear': '2026-2027',
      'attendance': '95.4% (Present)',
      'phone': '+91 98765 43210 (Father)',
      'email': 'aarav.sharma@student.edu',
      'fatherName': 'Mr. Rajesh Sharma',
      'fatherOccupation': 'Software Architect',
      'motherName': 'Mrs. Sunita Sharma',
      'motherOccupation': 'Senior Lecturer',
      'address': 'Flat 402, Green Valley Heights, Sector 14, Navi Mumbai',
      'emergencyPhone': '+91 98765 43210',
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Kabir Sharma',
      'fullName': 'Kabir Rajesh Sharma',
      'grade': 'Class 6 - Section B',
      'className': 'Class 6',
      'section': 'Section B',
      'rollNo': '#08',
      'admNo': 'ADM-2026-0095',
      'initials': 'KS',
      'gender': 'Male',
      'dob': '22 August 2014 (12 years)',
      'bloodGroup': 'O+',
      'houseGroup': 'Tagore House (Blue)',
      'secondLanguage': 'Hindi',
      'medium': 'English Medium',
      'admissionDate': '10 April 2022',
      'teacher': 'Mr. Ramesh Bhat',
      'academicYear': '2026-2027',
      'attendance': '98.1% (Present)',
      'phone': '+91 98765 43210 (Father)',
      'email': 'kabir.sharma@student.edu',
      'fatherName': 'Mr. Rajesh Sharma',
      'fatherOccupation': 'Software Architect',
      'motherName': 'Mrs. Sunita Sharma',
      'motherOccupation': 'Senior Lecturer',
      'address': 'Flat 402, Green Valley Heights, Sector 14, Navi Mumbai',
      'emergencyPhone': '+91 98765 43210',
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
          'grade': '${adm.student.className} - Section ${adm.student.section.isNotEmpty ? adm.student.section : "A"}',
          'className': adm.student.className,
          'section': adm.student.section.isNotEmpty ? 'Section ${adm.student.section}' : 'Section A',
          'rollNo': adm.student.rollNumber != null ? '#${adm.student.rollNumber}' : '#Pending',
          'admNo': adm.student.admissionNumber,
          'initials': initials.isNotEmpty ? initials : 'ST',
          'gender': adm.user.gender?.displayName ?? 'Male',
          'dob': adm.user.dateOfBirth != null
              ? DateFormat('dd MMM yyyy').format(adm.user.dateOfBirth!)
              : 'Not Specified',
          'bloodGroup': adm.student.bloodGroup ?? 'O+',
          'houseGroup': adm.student.houseGroup ?? 'General',
          'secondLanguage': adm.student.secondLanguage ?? 'Hindi',
          'medium': adm.student.mediumOfInstruction ?? 'English Medium',
          'admissionDate': DateFormat('dd MMM yyyy').format(adm.student.admissionDate),
          'teacher': 'Assigned by Administration',
          'academicYear': adm.student.academicYear.isNotEmpty ? adm.student.academicYear : '2026-2027',
          'attendance': '100% (Newly Enrolled)',
          'phone': adm.student.emergencyContactPhone.isNotEmpty ? adm.student.emergencyContactPhone : '+91 98765 43210 (Father)',
          'email': adm.user.email,
          'fatherName': adm.father?.fullName ?? 'Mr. Rajesh Sharma',
          'fatherOccupation': adm.father?.occupation ?? 'Parent',
          'motherName': adm.mother?.fullName ?? 'Mrs. Sunita Sharma',
          'motherOccupation': adm.mother?.occupation ?? 'Parent',
          'address': adm.student.currentAddress.isNotEmpty ? adm.student.currentAddress : 'Navi Mumbai',
          'emergencyPhone': adm.student.emergencyContactPhone.isNotEmpty ? adm.student.emergencyContactPhone : '+91 98765 43210',
          'photoUrl': adm.user.profilePhotoUrl,
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
              CommonAppHeader(
                isDark: isDark,
                leading: _activeTab != ParentPortalTab.childrenOverview
                    ? Tooltip(
                        message: 'Back to Overview',
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _activeTab = ParentPortalTab.childrenOverview);
                          },
                        ),
                      )
                    : null,
                onToggleTheme: widget.onToggleTheme,
                onLogout: widget.onExitToGateway,
                roleOverride: 'Parent',
                roleColorOverride: const Color(0xFF10B981),
              ),
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

              if (ref.watch(parentApplicationDraftProvider) != null) ...[
                _buildDraftNotificationCard(
                  ref.watch(parentApplicationDraftProvider)!,
                  isDark,
                  isMobile,
                ),
                const SizedBox(height: 20),
              ],

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
      onTap: () {
        setState(() => _selectedEnrolledChild = child['name'] as String);
        _showEnrolledStudentDetailsModal(child);
      },
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
            IconButton(
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.info_outline,
                color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white38 : Colors.grey.shade400),
                size: 16,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Inspect Student Record',
              onPressed: () {
                setState(() => _selectedEnrolledChild = child['name'] as String);
                _showEnrolledStudentDetailsModal(child);
              },
            ),
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
    return InkWell(
      onTap: () => _showEnrolledStudentDetailsModal(childData),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              childData['fullName'] as String,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Enrolled',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${childData['grade']} • Roll No: ${childData['rollNo']} • ${childData['admNo']}',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
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

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action Footer
            if (isMobile)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEnrolledStudentDetailsModal(childData),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Full 360° Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Click card for full 360° record',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showEnrolledStudentDetailsModal(childData),
                    icon: const Icon(Icons.visibility_outlined, size: 13),
                    label: const Text('View Full Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
          ],
        ),
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

  Widget _buildDraftNotificationCard(
    AdmissionRequestModel draft,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Unfinished Application Draft',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        draft.gradeApplied,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  draft.applicantFirstName.isNotEmpty
                      ? 'Draft for ${draft.applicantFullName} was saved. Resume where you left off.'
                      : 'You have a saved admission application in progress. Tap to continue.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _activeTab = ParentPortalTab.applyNewAdmission),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: New Child Admission Application (3-Step Wizard)
  // --------------------------------------------------------------------------
  Widget _buildApplyNewAdmissionTab(bool isDark, bool isMobile) {
    final savedDraft = ref.watch(parentApplicationDraftProvider);

    // Pre-populate with saved draft or logged in parent profile
    final prefilledParentData = savedDraft ?? AdmissionRequestModel(
      id: 'DRAFT-${DateTime.now().millisecondsSinceEpoch % 100000}',
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
      status: AdmissionRequestStatus.pendingReview,
      appliedAt: DateTime.now(),
    );

    return Column(
      children: [
        if (savedDraft != null) ...[
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resuming saved draft${savedDraft.applicantFirstName.isNotEmpty ? ' for ${savedDraft.applicantFullName}' : ''} (${savedDraft.gradeApplied}).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(parentApplicationDraftProvider.notifier).clearDraft();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Discard Draft', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: AdmissionApplicationWizard(
            source: AdmissionRequestSource.parentPortal,
            initialData: prefilledParentData,
            isDark: isDark,
            onCancel: () => setState(() => _activeTab = ParentPortalTab.childrenOverview),
            onSaveDraft: (draft) async {
              await ref.read(parentApplicationDraftProvider.notifier).saveDraft(draft);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.bookmark_added, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Application draft for ${draft.applicantFirstName.isNotEmpty ? draft.applicantFullName : "child"} saved successfully!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFF59E0B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            onSubmitted: (req) async {
              final created = await ref.read(admissionRequestsListProvider.notifier).createRequest(req);
              await ref.read(parentApplicationDraftProvider.notifier).clearDraft();
              if (mounted) {
                _showSubmissionConfirmationDialog(created);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showSubmissionConfirmationDialog(AdmissionRequestModel req) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF131D31) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'Admission Application Submitted!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Official Ticket Reference Number',
              style: TextStyle(fontSize: 12, color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0D9488)),
              ),
              child: Text(
                req.id,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Candidate Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(req.applicantFullName, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grade Applied:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(req.gradeApplied, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Initial Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PENDING_REVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Workflow Routing:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Text('Principal & Admin Queue', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _activeTab = ParentPortalTab.myApplications);
              },
              child: const Text('View Ticket in Live Tracker ➔', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
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
      case AdmissionRequestStatus.pendingReview:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case AdmissionRequestStatus.correctionRequested:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Correction Requested (Action Required)';
        statusIcon = Icons.edit_note_rounded;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApplicationDetailsModal(req),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
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

                // Applicant Avatar & Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 20 : 24,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      backgroundImage: (req.studentPhotoUrl != null && req.studentPhotoUrl!.isNotEmpty)
                          ? (req.studentPhotoUrl!.startsWith('http')
                              ? NetworkImage(req.studentPhotoUrl!)
                              : (req.studentPhotoUrl!.startsWith('data:')
                                  ? MemoryImage(base64Decode(req.studentPhotoUrl!.split(',').last))
                                  : AssetImage(req.studentPhotoUrl!) as ImageProvider))
                          : null,
                      child: (req.studentPhotoUrl == null || req.studentPhotoUrl!.isEmpty)
                          ? Text(
                              req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0] : 'S',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.applicantFullName,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Applied on ${DateFormat('dd MMMM yyyy').format(req.appliedAt)} • DOB: ${DateFormat('dd MMM yyyy').format(req.dateOfBirth)} • Blood: ${req.bloodGroup ?? "O+"}',
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

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Interactive Action Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Click card for complete application dossier',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showApplicationDetailsModal(req),
                      icon: const Icon(Icons.description_outlined, size: 13),
                      label: const Text('View Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  // --------------------------------------------------------------------------
  // Detail Modals & 360° Profile Inspectors
  // --------------------------------------------------------------------------

  ImageProvider? _resolveImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    if (photoUrl.startsWith('data:')) {
      try {
        final base64Str = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return AssetImage(photoUrl);
  }

  void _showEnrolledStudentDetailsModal(Map<String, dynamic> child) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final color = child['color'] as Color? ?? const Color(0xFF10B981);
    final photoUrl = child['photoUrl'] as String?;
    final imageProvider = _resolveImageProvider(photoUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
              maxWidth: 780,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.school_rounded, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enrolled Student Record',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Official 360° Academic & Personal Dossier',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          tooltip: 'Close Record',
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Hero Profile Box
                          Container(
                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFF0FDF4), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 28 : 34,
                                  backgroundColor: color,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Text(
                                          child['initials'] as String? ?? 'ST',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 18 : 22,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              child['fullName'] as String? ?? child['name'] as String? ?? '',
                                              style: TextStyle(
                                                fontSize: isMobile ? 17 : 20,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified, size: 12, color: Color(0xFF10B981)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Enrolled Active',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              child['grade'] as String? ?? '',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF3B82F6),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Roll ${child['rollNo'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              child['admNo'] as String? ?? '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 4 Quick Metrics
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth < 500 ? 2 : 4;
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: constraints.maxWidth < 500 ? 2.2 : 2.0,
                                children: [
                                  _buildModalKpiTile(
                                    'Attendance',
                                    child['attendance'] as String? ?? 'N/A',
                                    Icons.insights_rounded,
                                    const Color(0xFF10B981),
                                    isDark,
                                  ),
                                  _buildModalKpiTile(
                                    'Class Teacher',
                                    child['teacher'] as String? ?? 'Assigned',
                                    Icons.school_rounded,
                                    const Color(0xFF3B82F6),
                                    isDark,
                                  ),
                                  _buildModalKpiTile(
                                    'Session',
                                    child['academicYear'] as String? ?? '2026-2027',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF8B5CF6),
                                    isDark,
                                  ),
                                  _buildModalKpiTile(
                                    'Medium / Lang',
                                    '${child['medium'] ?? "English"}',
                                    Icons.translate_rounded,
                                    const Color(0xFFF59E0B),
                                    isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),

                          // Section 1: Academic & Institutional Placement
                          _buildModalSectionCard(
                            'Academic Placement & Institutional Details',
                            Icons.account_balance_rounded,
                            [
                              _buildModalDetailRow('Class & Grade', child['className'] as String? ?? child['grade'] as String? ?? 'Class 10', isDark),
                              _buildModalDetailRow('Section', child['section'] as String? ?? 'Section A', isDark),
                              _buildModalDetailRow('Roll Number', child['rollNo'] as String? ?? '#12', isDark),
                              _buildModalDetailRow('Permanent Admission Number', child['admNo'] as String? ?? 'ADM-2026-0042', isDark, isHighlighted: true),
                              _buildModalDetailRow('Admission Enrolled Date', child['admissionDate'] as String? ?? '12 June 2020', isDark),
                              _buildModalDetailRow('House Division', child['houseGroup'] as String? ?? 'Shivaji House (Green)', isDark),
                              _buildModalDetailRow('Medium of Instruction', child['medium'] as String? ?? 'English Medium', isDark),
                              _buildModalDetailRow('Second Language', child['secondLanguage'] as String? ?? 'Sanskrit', isDark),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 14),

                          // Section 2: Personal Demographics & Identity
                          _buildModalSectionCard(
                            'Personal Demographics & Identity',
                            Icons.person_rounded,
                            [
                              _buildModalDetailRow('Full Legal Name', child['fullName'] as String? ?? child['name'] as String? ?? '', isDark),
                              _buildModalDetailRow('Gender', child['gender'] as String? ?? 'Male', isDark),
                              _buildModalDetailRow('Date of Birth & Age', child['dob'] as String? ?? '14 May 2010', isDark),
                              _buildModalDetailRow('Blood Group', child['bloodGroup'] as String? ?? 'B+', isDark, isHighlighted: true),
                              _buildModalDetailRow('Student Institutional Email', child['email'] as String? ?? 'student@kvm.edu', isDark),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 14),

                          // Section 3: Parent & Emergency Contacts
                          _buildModalSectionCard(
                            'Parent & Emergency Contacts',
                            Icons.family_restroom_rounded,
                            [
                              _buildModalDetailRow('Father’s Name', child['fatherName'] as String? ?? 'Mr. Rajesh Sharma', isDark),
                              _buildModalDetailRow('Father’s Occupation', child['fatherOccupation'] as String? ?? 'Software Architect', isDark),
                              _buildModalDetailRow('Mother’s Name', child['motherName'] as String? ?? 'Mrs. Sunita Sharma', isDark),
                              _buildModalDetailRow('Mother’s Occupation', child['motherOccupation'] as String? ?? 'Senior Lecturer', isDark),
                              _buildModalDetailRow('Primary Emergency Phone', child['emergencyPhone'] as String? ?? '+91 98765 43210', isDark, isHighlighted: true),
                              _buildModalDetailRow('SMS & Alert Contact', child['phone'] as String? ?? '+91 98765 43210', isDark),
                              _buildModalDetailRow('Residential Address', child['address'] as String? ?? 'Navi Mumbai', isDark),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 16),

                          // Institutional Guarantee Footer
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Institutional Student Record • Verified by KVM Public School Registry Office for Session 2026-2027.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D31) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close Student Record', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApplicationDetailsModal(AdmissionRequestModel req) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    String statusDescription;

    switch (req.status) {
      case AdmissionRequestStatus.approved:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Approved & Enrolled';
        statusIcon = Icons.check_circle_rounded;
        statusDescription = 'This application was thoroughly reviewed and officially approved. The student profile is now enrolled in the school academic system.';
        break;
      case AdmissionRequestStatus.rejected:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Application Rejected';
        statusIcon = Icons.cancel_rounded;
        statusDescription = 'This application was not approved during administrative screening. Review the remarks below for further guidance.';
        break;
      case AdmissionRequestStatus.pending:
      case AdmissionRequestStatus.pendingReview:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_top_rounded;
        statusDescription = 'This application has been successfully submitted and is currently in the Admissions Screening Queue awaiting Principal/Admin decision.';
        break;
      case AdmissionRequestStatus.correctionRequested:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Correction Requested';
        statusIcon = Icons.edit_note_rounded;
        statusDescription = 'Additional documents or corrections are requested by the Admissions Desk before final approval.';
        break;
    }

    final isRejected = req.status == AdmissionRequestStatus.rejected;
    final imageProvider = _resolveImageProvider(req.studentPhotoUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
              maxWidth: 780,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admission Application Dossier',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Application ID: ${req.id} • Session ${req.academicYear}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          tooltip: 'Close Dossier',
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        req.source.displayName,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  statusDescription,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                                if (req.reviewedAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reviewed on ${DateFormat('dd MMMM yyyy, hh:mm a').format(req.reviewedAt!)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (isRejected && req.rejectionReason != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Official Administrative Rejection Reason',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          req.rejectionReason!,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (req.status == AdmissionRequestStatus.correctionRequested &&
                              req.correctionNotes != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.edit_note, color: Color(0xFFD97706), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Required Corrections / Resubmission Notes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          req.correctionNotes!,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Applicant Identity Box
                          Container(
                            padding: EdgeInsets.all(isMobile ? 14 : 18),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 26 : 32,
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Text(
                                          req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0] : 'S',
                                          style: TextStyle(
                                            color: const Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 18 : 22,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.applicantFullName,
                                        style: TextStyle(
                                          fontSize: isMobile ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Grade Applied: ${req.gradeApplied} • Academic Year: ${req.academicYear}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Submitted on ${DateFormat('dd MMMM yyyy, hh:mm a').format(req.appliedAt)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Section 1: Child Demographics
                          _buildModalSectionCard(
                            'Child Demographics & Application Details',
                            Icons.child_care_rounded,
                            [
                              _buildModalDetailRow('First Name', req.applicantFirstName, isDark),
                              _buildModalDetailRow('Last Name', req.applicantLastName, isDark),
                              _buildModalDetailRow('Grade / Class Applied', req.gradeApplied, isDark, isHighlighted: true),
                              _buildModalDetailRow('Date of Birth', DateFormat('dd MMMM yyyy').format(req.dateOfBirth), isDark),
                              _buildModalDetailRow('Gender', req.gender, isDark),
                              _buildModalDetailRow('Blood Group', req.bloodGroup ?? 'Not Specified', isDark),
                              _buildModalDetailRow('Academic Session', req.academicYear, isDark),
                              _buildModalDetailRow('Application Source', req.source.displayName, isDark),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 14),

                          // Section 2: Guardian & Contacts
                          _buildModalSectionCard(
                            'Parent & Guardian Information',
                            Icons.family_restroom_rounded,
                            [
                              _buildModalDetailRow('Parent / Guardian Name', req.parentFullName, isDark),
                              _buildModalDetailRow('Relationship to Student', req.parentRelationship, isDark),
                              _buildModalDetailRow('Primary Phone Number', req.parentPhone, isDark, isHighlighted: true),
                              _buildModalDetailRow('Email Address', req.parentEmail, isDark),
                              _buildModalDetailRow('Parent Occupation', req.parentOccupation ?? 'Not Specified', isDark),
                              _buildModalDetailRow('Current Residential Address', req.currentAddress, isDark),
                              _buildModalDetailRow('Permanent Address', req.permanentAddress ?? req.currentAddress, isDark),
                              _buildModalDetailRow('Emergency Contact Phone', req.emergencyContactPhone, isDark),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 14),

                          // Section 3: Prior Schooling History
                          _buildModalSectionCard(
                            'Prior Schooling & Academic Background',
                            Icons.history_edu_rounded,
                            [
                              _buildModalDetailRow(
                                'Previous School Attended',
                                (req.previousSchoolName != null && req.previousSchoolName!.isNotEmpty)
                                    ? req.previousSchoolName!
                                    : 'Direct Admission (First Schooling)',
                                isDark,
                              ),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 14),

                          // Section 4: Attached Verification Documents
                          _buildModalSectionCard(
                            'Attached Verification Documents',
                            Icons.attach_file_rounded,
                            [
                              if (req.documents.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: req.documents.map((doc) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.file_present_rounded, size: 16, color: Color(0xFF10B981)),
                                          const SizedBox(width: 6),
                                          Text(
                                            doc,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.check_circle, size: 13, color: Color(0xFF10B981)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Birth Certificate & Address Verification verified during online form submission.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            isDark,
                          ),

                          if (req.notes != null && req.notes!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildModalSectionCard(
                              'Special Parent Remarks / Notes',
                              Icons.notes_rounded,
                              [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    req.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                              isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D31) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close Application Dossier', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF10B981)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModalDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalKpiTile(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
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
                    fontSize: 11,
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
}
