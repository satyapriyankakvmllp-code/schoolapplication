import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/features/staff/data/leave_repository.dart';
import 'package:frontend/src/features/staff/domain/staff_leave_model.dart';

class PrincipalFacultyLeavesScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const PrincipalFacultyLeavesScreen({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<PrincipalFacultyLeavesScreen> createState() => _PrincipalFacultyLeavesScreenState();
}

class _PrincipalFacultyLeavesScreenState extends ConsumerState<PrincipalFacultyLeavesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _showApprovalDialog(StaffLeaveModel leave, bool isApprove) {
    _remarksController.text = isApprove ? 'Approved by Principal' : 'Declined due to institutional academic coverage';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApprove ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 10),
            Text(
              isApprove ? 'Confirm Approval' : 'Decline Application',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicant: ${leave.staffName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Leave: ${leave.leaveType} (${leave.dateRange}, ${leave.durationDays} days)',
              style: TextStyle(fontSize: 12, color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Executive Remarks',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final remarks = _remarksController.text.trim();
              if (isApprove) {
                await ref.read(leaveListProvider.notifier).approveLeave(leave.id, remarks: remarks);
              } else {
                await ref.read(leaveListProvider.notifier).rejectLeave(leave.id, remarks: remarks);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isApprove
                          ? 'Leave for ${leave.staffName} APPROVED successfully.'
                          : 'Leave for ${leave.staffName} DECLINED.',
                    ),
                    backgroundColor: isApprove ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isApprove ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingLeaves = ref.watch(pendingLeavesForPrincipalProvider);
    final allLeavesAsync = ref.watch(leaveListProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final cardBg = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;
    final subColor = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: widget.isDark ? 0.25 : 0.12),
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
                  radius: isMobile ? 22 : 28,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.approval, color: Colors.white, size: 26),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Leave Approvals Board',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review, sanction, and dispatch teacher leave applications with syllabus substitute tracking.',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: subColor,
            indicatorColor: const Color(0xFF6366F1),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending Review', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: pendingLeaves.isNotEmpty ? AppColors.warning : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingLeaves.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Tab(text: 'Leave History & Logs'),
            ],
          ),

          const SizedBox(height: 16),

          // Active Tab View Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                // Pending Leaves Tab
                if (pendingLeaves.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                        const SizedBox(height: 12),
                        Text(
                          'All Faculty Leave Applications Reviewed!',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No faculty leave requests currently awaiting your sign-off.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: pendingLeaves.map((leave) => _buildLeaveCard(leave, cardBg, borderColor, textColor, subColor, isMobile)).toList(),
                );
              } else {
                // History Tab
                final allLeaves = allLeavesAsync.valueOrNull ?? [];
                final historyLeaves = allLeaves.where((l) => l.status != 'Pending').toList();

                if (historyLeaves.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Text('No historical leave records found.', style: TextStyle(color: subColor)),
                  );
                }

                return Column(
                  children: historyLeaves.map((leave) {
                    final isApproved = leave.status == 'Approved';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApproved ? Icons.check_circle : Icons.cancel,
                            color: isApproved ? AppColors.success : AppColors.error,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${leave.staffName} • ${leave.leaveType}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Dates: ${leave.dateRange} (${leave.durationDays} days) • Remarks: ${leave.adminRemarks ?? 'No remarks'}',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              leave.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isApproved ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(
    StaffLeaveModel leave,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    leave.staffName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      leave.leaveType,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dates: ${leave.dateRange} (${leave.durationDays} days) • Applied: ${leave.applyDate}',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Reason: ${leave.reason}',
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showApprovalDialog(leave, true),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showApprovalDialog(leave, false),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}
