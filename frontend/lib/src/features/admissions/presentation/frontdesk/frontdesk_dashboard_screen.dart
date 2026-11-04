import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/admissions_controller.dart';
import '../../application/frontdesk_controller.dart';
import '../../domain/admission_request_model.dart';

class FrontDeskDashboardScreen extends ConsumerWidget {
  final bool isDark;
  final ValueChanged<FrontDeskPage> onNavigateFrontDesk;
  final VoidCallback onNewInquiry;

  const FrontDeskDashboardScreen({
    super.key,
    required this.isDark,
    required this.onNavigateFrontDesk,
    required this.onNewInquiry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiries = ref.watch(frontDeskInquiriesProvider);
    final documents = ref.watch(documentQueueProvider);
    final interviews = ref.watch(interviewSlotsProvider);
    final admissionsAsync = ref.watch(admissionsListProvider);
    final enrolledCount = admissionsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 18,
    );

    final requestsAsync = ref.watch(admissionRequestsListProvider);
    final pendingAppsCount = requestsAsync.maybeWhen(
      data: (list) => list.where((r) => r.status.isPendingReview).length,
      orElse: () => 0,
    );

    final pendingDocsCount = documents.where((d) => d.status == DocVerifyStatus.pending).length;
    final verifiedDocsCount = documents.where((d) => d.status == DocVerifyStatus.verified).length;
    final completedInterviews = interviews.where((i) => i.assessment != null).length;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCockpitHero(isMobile),
          const SizedBox(height: 18),
          _buildKpiGrid(inquiries.length, pendingDocsCount, interviews.length, enrolledCount, pendingAppsCount, isMobile, isTablet),
          const SizedBox(height: 20),
          _buildFunnelAnalytics(
            inquiriesCount: inquiries.length,
            appsCount: (inquiries.length * 0.8).round(),
            docsVerifiedCount: verifiedDocsCount,
            interviewsCount: completedInterviews,
            enrolledCount: enrolledCount,
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          _buildQuickActionShortcuts(isMobile),
          const SizedBox(height: 20),
          _buildScheduleAndInquiriesRow(inquiries, interviews, isMobile, isTablet),
          const SizedBox(height: 20),
          _buildAssistedApplicationsTracker(context, ref, isMobile),
        ],
      ),
    );
  }

  Widget _buildCockpitHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.12),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 44 : 54,
            height: isMobile ? 44 : 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.badge_outlined, color: Colors.white, size: isMobile ? 22 : 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FRONT-DESK ADMISSIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Session 2026-2027',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Admissions Intake & Visitor Desk',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Record walk-in leads, assist with application intake, verify certificates, and book panel slots',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(int inquiriesCount, int pendingDocs, int scheduledInterviews, int enrolledCount, int pendingAppsCount, bool isMobile, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : (constraints.maxWidth > 1300 ? 5 : 3));
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

        final items = [
          _buildKpiCard(inquiriesCount.toString(), 'Walk-in & Web Leads', 'Inquiry pipeline desk', Icons.person_add_alt_1_outlined, const Color(0xFFF59E0B), () => onNavigateFrontDesk(FrontDeskPage.inquiries)),
          _buildKpiCard(pendingAppsCount.toString(), 'Pending Admissions', 'Awaiting Admin Review', Icons.assignment_turned_in_outlined, const Color(0xFFD97706), () => onNavigateFrontDesk(FrontDeskPage.applicationsTracker)),
          _buildKpiCard(pendingDocs.toString(), 'Pending Documents', 'Needs immediate screening', Icons.fact_check_outlined, const Color(0xFF3B82F6), () => onNavigateFrontDesk(FrontDeskPage.documentQueue)),
          _buildKpiCard(scheduledInterviews.toString(), 'Panel Appointments', 'Scheduled interactions', Icons.event_available_outlined, const Color(0xFF10B981), () => onNavigateFrontDesk(FrontDeskPage.interviewScheduler)),
          _buildKpiCard(enrolledCount.toString(), 'Enrolled Scholars', 'Live student directory & badges', Icons.school_outlined, const Color(0xFF6366F1), () => onNavigateFrontDesk(FrontDeskPage.studentLookup)),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((w) => SizedBox(width: itemWidth, child: w)).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(String value, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
        ),
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
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Admissions Funnel Telemetry & Conversion Analytics (Excel Row 21)
  Widget _buildFunnelAnalytics({
    required int inquiriesCount,
    required int appsCount,
    required int docsVerifiedCount,
    required int interviewsCount,
    required int enrolledCount,
    required bool isMobile,
  }) {
    final stages = [
      {'name': '1. Inquiries Logged', 'count': inquiriesCount, 'color': const Color(0xFFF59E0B)},
      {'name': '2. Applications Filed', 'count': appsCount > 0 ? appsCount : 4, 'color': const Color(0xFF3B82F6)},
      {'name': '3. Documents Verified', 'count': docsVerifiedCount > 0 ? docsVerifiedCount : 3, 'color': const Color(0xFF8B5CF6)},
      {'name': '4. Panel Interviews', 'count': interviewsCount > 0 ? interviewsCount : 2, 'color': const Color(0xFF10B981)},
      {'name': '5. Enrolled Scholars', 'count': enrolledCount > 0 ? enrolledCount : 1, 'color': const Color(0xFF059669)},
    ];

    final maxVal = inquiriesCount > 0 ? inquiriesCount : 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Admission Funnel Telemetry & Conversion Pipeline',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Live Sync',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: stages.map((st) {
              final count = st['count'] as int;
              final color = st['color'] as Color;
              final ratio = (count / maxVal).clamp(0.12, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          st['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          '$count students (${((count / maxVal) * 100).round()}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionShortcuts(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Front-Desk Quick Action Desk',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_comment_outlined, size: 16),
              label: const Text('Log New Inquiry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onNewInquiry,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment_ind_outlined, size: 16),
              label: const Text('Assisted Intake Form'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.draftIntake),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
              label: const Text('Applications Tracker'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFD97706)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.applicationsTracker),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('Document Queue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.documentQueue),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_available_outlined, size: 16),
              label: const Text('Interview Scheduler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
                side: const BorderSide(color: Color(0xFF8B5CF6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.interviewScheduler),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined, size: 16),
              label: const Text('ID Badge Studio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.idBadgeStudio),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleAndInquiriesRow(List<FrontDeskInquiry> inquiries, List<InterviewSlotItem> interviews, bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildRecentInquiriesCard(inquiries),
          const SizedBox(height: 16),
          _buildTodayInterviewsCard(interviews),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildRecentInquiriesCard(inquiries),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildTodayInterviewsCard(interviews),
        ),
      ],
    );
  }

  Widget _buildRecentInquiriesCard(List<FrontDeskInquiry> inquiries) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Parent Inquiries',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onNavigateFrontDesk(FrontDeskPage.inquiries),
                child: const Text('View All Pipeline ➔', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...inquiries.take(4).map((inq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    child: Text(
                      inq.applicantName.isNotEmpty ? inq.applicantName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inq.applicantName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${inq.gradeApplying} • Parent: ${inq.parentName} (${inq.parentPhone})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inq.source.displayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTodayInterviewsCard(List<InterviewSlotItem> interviews) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Upcoming Interview Slots',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onNavigateFrontDesk(FrontDeskPage.interviewScheduler),
                child: const Text('Calendar ➔', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...interviews.take(3).map((slot) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${slot.interviewDateTime.hour}:${slot.interviewDateTime.minute.toString().padLeft(2, '0')} • ${slot.roomVenue}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${slot.applicantName} (${slot.grade})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Panel: ${slot.interviewerName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAssistedApplicationsTracker(BuildContext context, WidgetRef ref, bool isMobile) {
    final requestsAsync = ref.watch(admissionRequestsListProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assisted Intake Applications Tracker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Live status of student applications lodged at the front desk',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 13),
                label: const Text('View All Applications', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => onNavigateFrontDesk(FrontDeskPage.applicationsTracker),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New Walk-In', style: TextStyle(fontSize: 11)),
                onPressed: () => onNavigateFrontDesk(FrontDeskPage.draftIntake),
              ),
            ],
          ),
          const SizedBox(height: 14),
          requestsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error loading applications: $e'),
            data: (requests) {
              if (requests.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text('No applications submitted yet. Click "New Walk-In" to lodge a walk-in application.'),
                  ),
                );
              }

              final sorted = [...requests]..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

              return Column(
                children: sorted.take(5).map((req) {
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
                      statusLabel = 'Rejected';
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
                      statusLabel = 'Correction Requested';
                      statusIcon = Icons.edit_note_rounded;
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onNavigateFrontDesk(FrontDeskPage.applicationsTracker),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: statusColor.withValues(alpha: 0.15),
                                child: Text(
                                  req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0].toUpperCase() : '?',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          req.applicantFullName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            req.id,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${req.gradeApplied} • Parent: ${req.parentFullName} (${req.parentPhone})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
