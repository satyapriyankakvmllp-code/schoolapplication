import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../application/staff_controller.dart';
import '../../../data/leave_repository.dart';

class PrincipalWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const PrincipalWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<PrincipalWorkspaceScreen> createState() => _PrincipalWorkspaceScreenState();
}

class _PrincipalWorkspaceScreenState extends ConsumerState<PrincipalWorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final counts = ref.watch(staffCountsProvider);
    final pendingLeaves = ref.watch(pendingLeavesForPrincipalProvider);

    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Principal Hero Card
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: dark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Executive Superintendent Console',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRINCIPAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Logged in as ${staff?.fullName ?? 'Dr. Anand Roy'} • Comprehensive institutional governance & approvals',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Institutional KPI Cards (Reusing staffCountsProvider)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final kpiTotal = _buildKpiCard('Total Personnel', '${counts.total}', const Color(0xFF6366F1), Icons.people_outline, cardBg, borderColor, dark);
              final kpiTeaching = _buildKpiCard('Teaching Faculty', '${counts.teaching}', AppColors.secondary, Icons.school_outlined, cardBg, borderColor, dark);
              final kpiOnLeave = _buildKpiCard('On Leave Today', '${counts.onLeave}', AppColors.warning, Icons.beach_access_outlined, cardBg, borderColor, dark);
              final kpiPending = _buildKpiCard('Pending Approvals', '${pendingLeaves.length}', AppColors.error, Icons.pending_actions, cardBg, borderColor, dark);

              if (isNarrow) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: kpiTotal), const SizedBox(width: 10), Expanded(child: kpiTeaching)]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: kpiOnLeave), const SizedBox(width: 10), Expanded(child: kpiPending)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: kpiTotal),
                  const SizedBox(width: 12),
                  Expanded(child: kpiTeaching),
                  const SizedBox(width: 12),
                  Expanded(child: kpiOnLeave),
                  const SizedBox(width: 12),
                  Expanded(child: kpiPending),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // CRITICAL: PENDING LEAVE APPROVALS BOARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.approval, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Faculty Leave Applications Awaiting Executive Sign-Off',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pendingLeaves.length} Pending',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (pendingLeaves.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 36, color: AppColors.success.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text('All faculty leave requests have been reviewed.', style: TextStyle(fontSize: 13, color: subColor)),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingLeaves.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final leave = pendingLeaves[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 600;

                            final infoBlock = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      leave.staffName,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        leave.leaveType,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dates: ${leave.dateRange} (${leave.durationDays} days) • Applied: ${leave.applyDate}',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${leave.reason}',
                                  style: TextStyle(fontSize: 12, color: textColor),
                                ),
                              ],
                            );

                            final actionButtons = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    await ref.read(leaveListProvider.notifier).approveLeave(leave.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Leave for ${leave.staffName} has been APPROVED!'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    await ref.read(leaveListProvider.notifier).rejectLeave(leave.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Leave for ${leave.staffName} has been declined.'),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  infoBlock,
                                  const SizedBox(height: 12),
                                  actionButtons,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: infoBlock),
                                const SizedBox(width: 16),
                                actionButtons,
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Institutional Fee Collection Graph
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Institutional Fee Collection Trends (Q1-Q4)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const Text('FY 2026-2027', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (v, m) => Text('₹${v.toInt()}L', style: TextStyle(fontSize: 9, color: subColor)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, m) {
                              const quarters = ['Apr-Jun', 'Jul-Sep', 'Oct-Dec', 'Jan-Mar'];
                              final i = v.toInt();
                              if (i >= 0 && i < quarters.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(quarters[i], style: TextStyle(fontSize: 10, color: subColor)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 48, color: AppColors.primary, width: 22, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 62, color: AppColors.secondary, width: 22, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 75, color: const Color(0xFF6366F1), width: 22, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 34, color: AppColors.warning, width: 22, borderRadius: BorderRadius.circular(4))]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    Color accent,
    IconData icon,
    Color cardBg,
    Color borderColor,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
