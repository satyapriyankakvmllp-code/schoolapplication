import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import '../application/auth_controller.dart';
import '../../../commonwidgets/edupluse_scaffold.dart';

class RoleWorkspaceHubScreen extends ConsumerWidget {
  final UserRole role;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onExitToGateway;

  const RoleWorkspaceHubScreen({
    super.key,
    required this.role,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigate,
    this.onExitToGateway,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = RoleDirectory.registry[role]!;
    final user = RoleDirectory.mockUsers[role]!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return EdupluseScaffold(
      activePage: EdupluseNavPage.dashboard,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      onNavigate: onNavigate,
      onExitToGateway: onExitToGateway,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleHero(context, ref, meta, user, isMobile),
                const SizedBox(height: 24),
                if (role == UserRole.parent)
                  _buildParentWorkspaceContent(context, ref, isDark, isMobile)
                else if (role == UserRole.admissions)
                  _buildAdmissionsWorkspaceContent(context, ref, isDark, isMobile)
                else if (role == UserRole.teacher)
                  _buildTeacherWorkspaceContent(context, ref, isDark, isMobile)
                else if (role == UserRole.student)
                  _buildStudentWorkspaceContent(context, ref, isDark, isMobile)
                else if (role == UserRole.finance)
                  _buildFinanceWorkspaceContent(context, ref, isDark, isMobile)
                else
                  _buildGenericRoleContent(context, ref, meta, isDark, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHero(
    BuildContext context,
    WidgetRef ref,
    RoleMetadata meta,
    UserModel user,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            meta.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: meta.primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.2,
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  color: meta.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: meta.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(meta.icon, color: Colors.white, size: isMobile ? 26 : 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: meta.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            meta.role.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: meta.primaryColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authenticated Session',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Signed in as ${user.fullName} (${user.email}) • ${meta.designation}',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meta.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Parent & Guardian Hub Preview (Phase 3 Foundation)
  // --------------------------------------------------------------------------
  Widget _buildParentWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sibling context bar
        Container(
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
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Aarav Sharma (Grade 10-A)'),
                      selected: true,
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                      onSelected: (_) {},
                    ),
                    ChoiceChip(
                      label: const Text('Kabir Sharma (Grade 6-B)'),
                      selected: false,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                      ),
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Child Snapshot Card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
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
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF10B981),
                          child: Text('AS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aarav Rajesh Sharma',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Class 10 - Section A • Roll No: #12 • Admission: ADM-2026-089',
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
                    const Divider(height: 28),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildStatPill('Class Teacher', 'Mrs. Anita Desai', Icons.school_outlined, isDark),
                        _buildStatPill('Academic Year', '2025-2026', Icons.calendar_today_outlined, isDark),
                        _buildStatPill('Attendance Rate', '94.8% (Present)', Icons.check_circle_outline, isDark),
                        _buildStatPill('Primary Alert Phone', '+91 98765 43210 (Father)', Icons.phone_outlined, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Phase 3 Quick Launch Actions
        Text(
          'Parent Portal Self-Service Actions (Phase 3 Foundation)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Start Child Intake Application',
              subtitle: 'Submit new child registration online with digital attachments',
              icon: Icons.note_add_outlined,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Emergency Contact Controls',
              subtitle: 'Designate primary emergency phone & fee notification recipient',
              icon: Icons.contact_emergency_outlined,
              color: const Color(0xFF06B6D4),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Live Application Tracker',
              subtitle: 'Track review stages from screening to final administrative sign-off',
              icon: Icons.track_changes_outlined,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Admissions Desk Hub (Phase 2 Foundation)
  // --------------------------------------------------------------------------
  Widget _buildAdmissionsWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard('12', 'New Inquiries Today', Icons.person_add_alt_1_outlined, const Color(0xFFF59E0B), isDark),
            _buildKpiCard('7', 'Pending Documents', Icons.file_present_outlined, const Color(0xFF3B82F6), isDark),
            _buildKpiCard('4', 'Interviews Scheduled', Icons.event_available_outlined, const Color(0xFF10B981), isDark),
            _buildKpiCard('9', 'Ready for Admin Sign-Off', Icons.verified_outlined, const Color(0xFF6366F1), isDark),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Front-Desk Intake & Screening Studio (Phase 2 Foundation)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Inquiry Desk & Walk-In Intake',
              subtitle: 'Record walk-in inquiries and generate INQ-2026 tracking numbers',
              icon: Icons.edit_note_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Document Verification Queue',
              subtitle: 'Screen uploaded certificates, verify authenticity or request re-upload',
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'ID Card Studio & Printing',
              subtitle: 'Generate student photo identity cards with instant barcodes',
              icon: Icons.badge_outlined,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Teacher Roster Hub (Phase 5 Foundation)
  // --------------------------------------------------------------------------
  Widget _buildTeacherWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard('38', 'Class 10-A Students', Icons.groups_outlined, const Color(0xFF3B82F6), isDark),
            _buildKpiCard('36', 'Present Today (94.7%)', Icons.how_to_reg_outlined, const Color(0xFF10B981), isDark),
            _buildKpiCard('4', 'Medical / Blood Alerts', Icons.medical_services_outlined, const Color(0xFFEF4444), isDark),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Class In-Charge Safety & Roster Tools (Phase 5 Foundation)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Class Section Roster',
              subtitle: 'View alphabetical student register with roll numbers and status',
              icon: Icons.list_alt_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Student Safety & Emergency Card',
              subtitle: 'Instant blood group identification and 1-tap parent dialer',
              icon: Icons.health_and_safety_outlined,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Classroom Behavioral Notes',
              subtitle: 'Confidential observational tags and internal guidance notes',
              icon: Icons.psychology_outlined,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Student Hub (Phase 6 Foundation)
  // --------------------------------------------------------------------------
  Widget _buildStudentWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard('Class 10-A', 'Enrolled Grade', Icons.school_outlined, const Color(0xFF06B6D4), isDark),
            _buildKpiCard('#12', 'Class Roll Number', Icons.format_list_numbered, const Color(0xFF3B82F6), isDark),
            _buildKpiCard('Active', 'Enrollment Status', Icons.check_circle_outlined, const Color(0xFF10B981), isDark),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Student Academic Self-Service (Phase 6 Foundation)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Digital Student Identity Card',
              subtitle: 'View institutional barcode ID badge with enrolled credentials',
              icon: Icons.badge_outlined,
              color: const Color(0xFF06B6D4),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Profile Correction Ticket',
              subtitle: 'Submit requests to correct misspelled name or outdated info',
              icon: Icons.report_problem_outlined,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Finance Hub (Phase 7 Foundation)
  // --------------------------------------------------------------------------
  Widget _buildFinanceWorkspaceContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard('₹ 4,85,000', 'Intake Collections', Icons.currency_rupee, const Color(0xFFEC4899), isDark),
            _buildKpiCard('18', 'Fee Receipts Issued', Icons.receipt_long_outlined, const Color(0xFF10B981), isDark),
            _buildKpiCard('3', 'Pending Clearance', Icons.pending_actions_outlined, const Color(0xFFF59E0B), isDark),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Finance & Accounts Clearance (Phase 7 Foundation)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Admission Fee Clearance Bridge',
              subtitle: 'Review paid admissions fees and release finance approval tokens',
              icon: Icons.verified_user_outlined,
              color: const Color(0xFFEC4899),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              title: 'Fee Structure Management',
              subtitle: 'Configure class-wise fee breakdowns, term due dates, and active structures',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF109F83),
              isDark: isDark,
              onTap: () => onNavigate?.call(EdupluseNavPage.fees),
            ),
            _buildActionCard(
              title: 'Receipts & Installment Schedules',
              subtitle: 'Issue formal tuition receipts and configure term payment dates',
              icon: Icons.receipt_outlined,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericRoleContent(
    BuildContext context,
    WidgetRef ref,
    RoleMetadata meta,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Text(
            '${meta.title} Workspace Loaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the top role switcher pill to transition across roles at any point.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
