import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/admissions_controller.dart';
import '../../application/frontdesk_controller.dart';

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

    final pendingDocsCount = documents.where((d) => d.status == DocVerifyStatus.pending).length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCockpitHero(isMobile),
          const SizedBox(height: 20),
          _buildKpiGrid(inquiries.length, pendingDocsCount, interviews.length, enrolledCount, isMobile, isTablet),
          const SizedBox(height: 24),
          _buildQuickActionShortcuts(isMobile),
          const SizedBox(height: 24),
          _buildScheduleAndInquiriesRow(inquiries, interviews, isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildCockpitHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
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
            width: isMobile ? 48 : 56,
            height: isMobile ? 48 : 56,
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
            child: Icon(Icons.badge_outlined, color: Colors.white, size: isMobile ? 24 : 30),
          ),
          const SizedBox(width: 16),
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
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMISSIONS DESK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      'Session 2025-2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Admissions & Intake Cockpit',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Officer Priya Verma • Fast-Track Walk-in Intake, Verification & Scheduling',
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

  Widget _buildKpiGrid(int totalInquiries, int pendingDocs, int scheduledInterviews, int enrolledCount, bool isMobile, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

        final items = [
          _buildKpiCard('12', 'Walk-in Leads Today', '+4 vs yesterday', Icons.person_add_alt_1_outlined, const Color(0xFFF59E0B), () => onNavigateFrontDesk(FrontDeskPage.inquiries)),
          _buildKpiCard(pendingDocs.toString(), 'Pending Documents', 'Needs immediate screening', Icons.fact_check_outlined, const Color(0xFF3B82F6), () => onNavigateFrontDesk(FrontDeskPage.documentQueue)),
          _buildKpiCard(scheduledInterviews.toString(), 'Interviews Scheduled', '3 panel slots today', Icons.event_available_outlined, const Color(0xFF10B981), () => onNavigateFrontDesk(FrontDeskPage.interviewScheduler)),
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
            OutlinedButton.icon(
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('Screen Documents'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.documentQueue),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Interview Slots'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.interviewScheduler),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined, size: 16),
              label: const Text('ID Badge Studio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
                side: const BorderSide(color: Color(0xFF8B5CF6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.idBadgeStudio),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Student Directory Lookup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06B6D4),
                side: const BorderSide(color: Color(0xFF06B6D4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onNavigateFrontDesk(FrontDeskPage.studentLookup),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleAndInquiriesRow(
    List<FrontDeskInquiry> inquiries,
    List<InterviewSlotItem> interviews,
    bool isMobile,
    bool isTablet,
  ) {
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
        Expanded(flex: 5, child: _buildRecentInquiriesCard(inquiries)),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: _buildTodayInterviewsCard(interviews)),
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
                  'Recent Walk-In & Phone Leads',
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
                child: const Text('View All Inquiries ➔', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...inquiries.take(3).map((inq) {
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
                    radius: 16,
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    child: Text(
                      inq.applicantName[0],
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
}
