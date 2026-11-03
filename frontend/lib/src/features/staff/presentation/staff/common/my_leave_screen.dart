import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/src/commonwidgets/empty_state_view.dart';
import 'package:frontend/src/commonwidgets/loading_indicator.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../application/staff_controller.dart';
import '../../../data/leave_repository.dart';
import '../../../domain/staff_leave_model.dart';

/// Single common MyLeaveScreen shared by all staff roles (Teaching, Admin, Support).
/// Fully responsive across mobile (390x844), tablet, and desktop viewports.
class MyLeaveScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const MyLeaveScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<MyLeaveScreen> createState() => _MyLeaveScreenState();
}

class _MyLeaveScreenState extends ConsumerState<MyLeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _selectedLeaveType = 'Casual Leave';
  bool _isHalfDay = false;
  String _halfDaySession = 'Morning Shift (FN: 08:30 AM - 12:00 PM)';
  DateTime _fromDate = DateTime.now().add(const Duration(days: 2));
  DateTime _toDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedSubstituteTeacher;
  String? _attachedDocumentName;
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;

  // History Filter
  String _historyFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected', 'Cancelled'
  bool _showPolicyNotice = true;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Medical Leave',
    'Special Duty Leave',
    'Earned Vacation Leave',
    'Maternity / Paternity Leave',
    'Compensatory Off',
    'Loss of Pay (LWP)',
  ];

  final List<String> _halfDaySessions = [
    'Morning Shift (FN: 08:30 AM - 12:00 PM)',
    'Afternoon Shift (AN: 12:30 PM - 04:00 PM)',
  ];

  final List<Map<String, String>> _mockHolidays = [
    {
      'name': 'Diwali & Kali Puja',
      'date': '29 Oct 2026',
      'daysLeft': '7 days',
      'type': 'Gazetted Holiday',
      'icon': 'celebration',
    },
    {
      'name': 'Kartik Purnima',
      'date': '15 Nov 2026',
      'daysLeft': '24 days',
      'type': 'State Holiday',
      'icon': 'water',
    },
    {
      'name': 'Christmas Day',
      'date': '25 Dec 2026',
      'daysLeft': '64 days',
      'type': 'National Holiday',
      'icon': 'park',
    },
    {
      'name': 'New Year\'s Day',
      'date': '01 Jan 2027',
      'daysLeft': '71 days',
      'type': 'Institutional Observance',
      'icon': 'star',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// Calculates working days between [_fromDate] and [_toDate], excluding Sundays.
  double _calculateWorkingDays() {
    if (_isHalfDay) return 0.5;
    if (_toDate.isBefore(_fromDate)) return 0;

    int totalDays = 0;
    DateTime cur = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day);

    while (!cur.isAfter(end)) {
      if (cur.weekday != DateTime.sunday) {
        totalDays++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return totalDays == 0 ? 1.0 : totalDays.toDouble();
  }

  Future<void> _submitLeaveApplication() async {
    if (!_formKey.currentState!.validate()) return;

    final staff = ref.read(currentLoggedInStaffProvider);
    if (staff == null) return;

    final isTeaching = staff.category == StaffCategory.teaching;
    if (isTeaching && _selectedSubstituteTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please nominate a substitute faculty colleague to cover your scheduled periods.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final workingDays = _calculateWorkingDays();
    final dateRangeStr = _isHalfDay
        ? '${DateFormat('dd MMM yyyy').format(_fromDate)} ($_halfDaySession)'
        : '${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}';
    final applyDateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    final newLeave = StaffLeaveModel(
      id: 'sl-${const Uuid().v4().substring(0, 8)}',
      staffId: staff.id,
      staffName: staff.fullName,
      leaveType: _selectedLeaveType,
      dateRange: dateRangeStr,
      fromDate: _fromDate,
      toDate: _isHalfDay ? _fromDate : _toDate,
      durationDays: workingDays.ceil(),
      applyDate: applyDateStr,
      status: 'Pending',
      reason: _reasonCtrl.text.trim(),
      substituteTeacher: _selectedSubstituteTeacher,
      isHalfDay: _isHalfDay,
      halfDaySession: _isHalfDay ? _halfDaySession : null,
      attachmentName: _attachedDocumentName,
    );

    try {
      await ref.read(leaveListProvider.notifier).applyLeave(newLeave);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _reasonCtrl.clear();
          _attachedDocumentName = null;
        });

        final isPrincipal = staff.effectiveRole.toLowerCase() == 'principal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPrincipal
                ? 'Leave application for $workingDays day(s) submitted for Management approval!'
                : 'Leave application for $workingDays day(s) submitted for Principal review!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Switch to history tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit leave: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showWithdrawConfirmation(StaffLeaveModel leave) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Withdraw Leave Request?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to withdraw your pending application for ${leave.leaveType} (${leave.dateRange})? This will immediately cancel the application from the approval pipeline.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Application'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref.read(leaveListProvider.notifier).cancelLeave(leave.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Leave application withdrawn successfully.'
                          : 'Failed to cancel application.'),
                      backgroundColor: success ? AppColors.info : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Yes, Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveStatementDocket(StaffMemberModel? staff, List<StaffLeaveModel> myLeaves) {
    final approvedLeaves = myLeaves.where((l) => l.isApproved).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
        final bg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
        final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Faculty Leave Statement',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'KVM Public School • Academic Year 2026-2027',
                            style: TextStyle(fontSize: 12, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: borderColor),
                const SizedBox(height: 10),

                // Staff Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          (staff?.fullName.isNotEmpty ?? false)
                              ? staff!.fullName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff?.fullName ?? 'Faculty Member',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${staff?.id ?? "N/A"} • ${staff?.designation ?? "Faculty"} • ${staff?.department ?? "Academics"}',
                              style: TextStyle(fontSize: 11, color: subColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Approved Leaves Ledger (${approvedLeaves.length} Records)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),

                // Approved List
                Expanded(
                  child: approvedLeaves.isEmpty
                      ? Center(
                          child: Text(
                            'No approved leaves logged in the current academic year.',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                        )
                      : ListView.separated(
                          itemCount: approvedLeaves.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final item = approvedLeaves[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.leaveType,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${item.dateRange} • ${item.durationDays} day(s)',
                                          style: TextStyle(fontSize: 11, color: subColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    'Approved',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),
                Divider(color: borderColor),
                const SizedBox(height: 8),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Leave Ledger Docket dispatched to your registered email!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export PDF Statement'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    final staffLeavesAsync = ref.watch(leaveListProvider);
    final allLeaves = staffLeavesAsync.valueOrNull ?? [];
    final myLeaves = staff != null
        ? allLeaves.where((l) => l.staffId == staff.id).toList()
        : allLeaves;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Banner with Action Buttons
          _buildTopHeaderBanner(staff, myLeaves, cardBg, borderColor, textColor, subColor, isMobile),

          // 2. 5 Real-Time Leave Quota Cards
          _buildQuotaCardsSection(myLeaves, cardBg, borderColor, textColor, subColor, isMobile),

          // 3. Institutional Policy Alert Banner
          if (_showPolicyNotice)
            _buildPolicyAlertBanner(borderColor, isMobile),

          // 4. Upcoming Holidays Widget
          _buildUpcomingHolidaysWidget(cardBg, borderColor, textColor, subColor, isMobile),

          const SizedBox(height: 12),

          // 5. Dual-Mode Tab Section (Apply vs History)
          _buildDualTabContainer(staff, staffLeavesAsync, myLeaves, cardBg, borderColor, textColor, subColor, isMobile),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Top Header Banner
  Widget _buildTopHeaderBanner(
    StaffMemberModel? staff,
    List<StaffLeaveModel> myLeaves,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: isMobile ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.beach_access_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Leave Management',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Track quota, submit leaves & verify pipeline',
                            style: TextStyle(fontSize: 11, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => _showLeaveStatementDocket(staff, myLeaves),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Statement', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _tabController.animateTo(0),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('+ Apply for Leave', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.beach_access_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Leave Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Real-time quota tracking, academic substitute coordination & multi-stage approval',
                              style: TextStyle(fontSize: 12, color: subColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => _showLeaveStatementDocket(staff, myLeaves),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Statement'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _tabController.animateTo(0),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Apply for Leave'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// 5 Real-Time Leave Quota Cards
  Widget _buildQuotaCardsSection(
    List<StaffLeaveModel> myLeaves,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    // Calculate availed leaves dynamically from approved leaves
    int clAvailed = 0;
    int mlAvailed = 0;
    int elAvailed = 0;
    int odAvailed = 0;
    int lwpAvailed = 0;

    for (final l in myLeaves) {
      if (l.isApproved) {
        final t = l.leaveType.toLowerCase();
        if (t.contains('casual')) {
          clAvailed += l.durationDays;
        } else if (t.contains('medical')) {
          mlAvailed += l.durationDays;
        } else if (t.contains('vacation') || t.contains('earned')) {
          elAvailed += l.durationDays;
        } else if (t.contains('duty') || t.contains('special') || t.contains('compensatory')) {
          odAvailed += l.durationDays;
        } else if (t.contains('loss of pay') || t.contains('lwp')) {
          lwpAvailed += l.durationDays;
        }
      }
    }

    // Default institutional seeds if staff has 0 approved
    if (clAvailed == 0) clAvailed = 4;
    if (mlAvailed == 0) mlAvailed = 2;
    if (odAvailed == 0) odAvailed = 1;

    final quotaData = [
      {
        'title': 'Casual Leave',
        'code': 'CL',
        'total': 12,
        'availed': clAvailed,
        'remaining': (12 - clAvailed).clamp(0, 12),
        'color': AppColors.primary,
        'icon': Icons.weekend_outlined,
      },
      {
        'title': 'Medical Leave',
        'code': 'ML',
        'total': 10,
        'availed': mlAvailed,
        'remaining': (10 - mlAvailed).clamp(0, 10),
        'color': AppColors.secondary,
        'icon': Icons.medical_services_outlined,
      },
      {
        'title': 'Earned Leave',
        'code': 'EL',
        'total': 15,
        'availed': elAvailed,
        'remaining': (15 - elAvailed).clamp(0, 15),
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.school_outlined,
      },
      {
        'title': 'On-Duty / Comp',
        'code': 'OD',
        'total': 3,
        'availed': odAvailed,
        'remaining': (3 - odAvailed).clamp(0, 3),
        'color': const Color(0xFFF59E0B),
        'icon': Icons.work_outline,
      },
      {
        'title': 'Loss of Pay',
        'code': 'LWP',
        'total': 0,
        'availed': lwpAvailed,
        'remaining': 0,
        'color': const Color(0xFFEF4444),
        'icon': Icons.money_off_outlined,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 960) {
            // Desktop: 5 in a Row
            return Row(
              children: quotaData.map((data) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildQuotaCard(data, cardBg, borderColor, textColor, subColor),
                  ),
                );
              }).toList(),
            );
          } else if (width >= 600) {
            // Tablet: 3 on top, 2 on bottom
            return Column(
              children: [
                Row(
                  children: quotaData.take(3).map((data) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildQuotaCard(data, cardBg, borderColor, textColor, subColor),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: quotaData.skip(3).map((data) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildQuotaCard(data, cardBg, borderColor, textColor, subColor),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          } else {
            // Mobile (390px): 2-column Wrap with clean calculated widths
            final itemWidth = (width - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: quotaData.map((data) {
                return SizedBox(
                  width: itemWidth,
                  child: _buildQuotaCard(data, cardBg, borderColor, textColor, subColor, isCompact: true),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuotaCard(
    Map<String, dynamic> data,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor, {
    bool isCompact = false,
  }) {
    final title = data['title'] as String;
    final code = data['code'] as String;
    final total = data['total'] as int;
    final availed = data['availed'] as int;
    final remaining = data['remaining'] as int;
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;

    final ratio = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isCompact ? 16 : 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                code == 'LWP' ? '$availed Days' : '$remaining',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (code != 'LWP') ...[
                const SizedBox(width: 4),
                Text(
                  '/ $total Bal',
                  style: TextStyle(fontSize: isCompact ? 10 : 11, color: subColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: code == 'LWP' ? 1.0 : ratio,
              minHeight: 4,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            code == 'LWP'
                ? 'Deductions Applied'
                : '$availed days availed this year',
            style: TextStyle(fontSize: 10, color: subColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Policy Alert Banner
  Widget _buildPolicyAlertBanner(Color borderColor, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Institutional Leave Rules: (1) Max 3 consecutive Casual Leaves. (2) Medical certificate mandatory for Medical Leave > 2 days. (3) Teaching staff must arrange substitute coverage before submitting.',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: const Color(0xFFB45309),
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFB45309)),
            onPressed: () => setState(() => _showPolicyNotice = false),
          ),
        ],
      ),
    );
  }

  /// Upcoming Holidays Widget
  Widget _buildUpcomingHolidaysWidget(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 6),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upcoming Gazetted Holidays (Term II)',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Plan Ahead',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _mockHolidays.map((holiday) {
                return Container(
                  width: isMobile ? 180 : 210,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: darkTheme(context)
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              holiday['daysLeft']!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              holiday['date']!,
                              style: TextStyle(fontSize: 10, color: subColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        holiday['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        holiday['type']!,
                        style: TextStyle(fontSize: 10, color: subColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool darkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark || widget.isDark;
  }

  /// Dual Tab Container (Tab 1: Apply, Tab 2: History)
  Widget _buildDualTabContainer(
    StaffMemberModel? staff,
    AsyncValue<List<StaffLeaveModel>> staffLeavesAsync,
    List<StaffLeaveModel> myLeaves,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Tab bar header
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: subColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.note_add_outlined, size: 18),
                text: 'Apply for Leave',
              ),
              Tab(
                icon: Icon(Icons.history_outlined, size: 18),
                text: 'My Leave History',
              ),
            ],
          ),
          Divider(height: 1, color: borderColor),

          // Tab content rendered dynamically based on active tab
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildApplyLeaveForm(staff, cardBg, borderColor, textColor, subColor, isMobile);
              } else {
                return _buildLeaveHistorySection(staff, staffLeavesAsync, myLeaves, cardBg, borderColor, textColor, subColor, isMobile);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Tab 1: Apply Leave Form
  Widget _buildApplyLeaveForm(
    StaffMemberModel? staff,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    final workingDays = _calculateWorkingDays();
    final isTeaching = staff?.category == StaffCategory.teaching;
    final staffListAsync = ref.watch(staffListProvider);
    final allStaff = staffListAsync.valueOrNull ?? [];
    final colleagueCandidates = allStaff.where((s) => s.id != staff?.id).toList();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_calendar_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application Parameters & Institutional Coverage',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leave Category Dropdown
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedLeaveType,
              decoration: const InputDecoration(
                labelText: 'Leave Category *',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _leaveTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLeaveType = val);
              },
            ),
            const SizedBox(height: 16),

            // Half-Day Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_bottom_rounded,
                                size: 18,
                                color: _isHalfDay ? AppColors.primary : subColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Half-Day Application',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isHalfDay,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isHalfDay = val;
                            if (_isHalfDay) {
                              _toDate = _fromDate;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isHalfDay) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _halfDaySession,
                      decoration: const InputDecoration(
                        labelText: 'Select Shift Session',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _halfDaySessions.map((session) {
                        return DropdownMenuItem(value: session, child: Text(session, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _halfDaySession = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Responsive Date Range Pickers (Vertical on small phone, horizontal on tablet/desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 480;

                final fromPicker = InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fromDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) {
                      setState(() {
                        _fromDate = picked;
                        if (_toDate.isBefore(_fromDate)) {
                          _toDate = _fromDate;
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'From Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_fromDate)),
                  ),
                );

                final toPicker = InkWell(
                  onTap: _isHalfDay
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _toDate,
                            firstDate: _fromDate,
                            lastDate: DateTime.now().add(const Duration(days: 180)),
                          );
                          if (picked != null) {
                            setState(() => _toDate = picked);
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _isHalfDay ? 'To Date (Single Half Day)' : 'To Date *',
                      prefixIcon: const Icon(Icons.event_outlined),
                      border: const OutlineInputBorder(),
                      enabled: !_isHalfDay,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_isHalfDay ? _fromDate : _toDate)),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      fromPicker,
                      const SizedBox(height: 12),
                      toPicker,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: fromPicker),
                      const SizedBox(width: 12),
                      Expanded(child: toPicker),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Smart Working Days Calculation Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isHalfDay
                          ? 'Requested: 0.5 Day (Shift: $_halfDaySession)'
                          : 'Calculated: $workingDays working day(s) (Sundays automatically excluded)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Substitute Teacher Colleague Dropdown (For Teaching Staff)
            if (isTeaching) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedSubstituteTeacher,
                decoration: const InputDecoration(
                  labelText: 'Substitute Teacher / Proxy *',
                  hintText: 'Select faculty colleague',
                  prefixIcon: Icon(Icons.people_outline),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: colleagueCandidates.map((c) {
                  return DropdownMenuItem(
                    value: c.fullName,
                    child: Text(
                      '${c.fullName} (${c.department})',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedSubstituteTeacher = val);
                },
              ),
              const SizedBox(height: 6),
              Text(
                '• Nominated colleague will be notified to accept class handover during your absence.',
                style: TextStyle(fontSize: 11, color: subColor),
              ),
              const SizedBox(height: 16),
            ],

            // Document Attachment Simulator (Especially for Medical Leave or Deputation)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supporting Document Attachment (Optional / Required if ML > 2 days)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_attachedDocumentName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachedDocumentName!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _attachedDocumentName = null),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _attachedDocumentName = 'Doctor_Medical_Fitness_Cert.pdf (240 KB)');
                          },
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text('Attach Medical Cert', style: TextStyle(fontSize: 11)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _attachedDocumentName = 'Olympiad_Duty_Deputation_Order.pdf (180 KB)');
                          },
                          icon: const Icon(Icons.file_present_rounded, size: 14),
                          label: const Text('Attach Official Order', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason Text Field
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detailed Reason for Leave *',
                hintText: 'Specify medical circumstances, family event, or official academic deputation...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please state your reason for requesting leave';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitLeaveApplication,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting Application...' : 'Submit Application for Approval',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 2: My Leave History & Pipeline Section
  Widget _buildLeaveHistorySection(
    StaffMemberModel? staff,
    AsyncValue<List<StaffLeaveModel>> staffLeavesAsync,
    List<StaffLeaveModel> myLeaves,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return staffLeavesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: LoadingIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('Error loading leave history: $err')),
      ),
      data: (_) {
        // Apply filter
        final filtered = myLeaves.where((l) {
          if (_historyFilter == 'All') return true;
          if (_historyFilter == 'Pending') return l.isPending;
          if (_historyFilter == 'Approved') return l.isApproved;
          if (_historyFilter == 'Rejected') return l.isRejected;
          if (_historyFilter == 'Cancelled') return l.isCancelled;
          return true;
        }).toList();

        return Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'].map((f) {
                    final isSel = _historyFilter == f;
                    final count = f == 'All'
                        ? myLeaves.length
                        : myLeaves.where((l) {
                            if (f == 'Pending') return l.isPending;
                            if (f == 'Approved') return l.isApproved;
                            if (f == 'Rejected') return l.isRejected;
                            if (f == 'Cancelled') return l.isCancelled;
                            return false;
                          }).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$f ($count)'),
                        selected: isSel,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? AppColors.primary : textColor,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _historyFilter = f);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              if (filtered.isEmpty) ...[
                EmptyStateView(
                  title: 'No $_historyFilter Applications Found',
                  subtitle: 'You have no leave applications under this status filter.',
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final leave = filtered[idx];
                    return _buildLeaveHistoryCard(
                      leave,
                      cardBg,
                      borderColor,
                      textColor,
                      subColor,
                      isMobile,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Individual Leave History Card with Multi-Stage Pipeline and Cancellation
  Widget _buildLeaveHistoryCard(
    StaffLeaveModel leave,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    final statusColor = leave.isApproved
        ? AppColors.success
        : leave.isPending
            ? AppColors.warning
            : leave.isCancelled
                ? const Color(0xFF64748B)
                : AppColors.error;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Date, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  leave.isApproved
                      ? Icons.check_circle_outline
                      : leave.isPending
                          ? Icons.pending_outlined
                          : leave.isCancelled
                              ? Icons.cancel_outlined
                              : Icons.highlight_off_rounded,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.leaveType,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Applied on ${leave.applyDate} • ${leave.durationDays} day(s)',
                      style: TextStyle(fontSize: 11, color: subColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  leave.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date Range & Half-Day indicator
          Row(
            children: [
              const Icon(Icons.date_range_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  leave.dateRange,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reason
          Text(
            'Reason: ${leave.reason}',
            style: TextStyle(fontSize: 12, color: subColor),
          ),

          // Substitute Teacher & Document Badges
          if (leave.substituteTeacher != null || leave.attachmentName != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (leave.substituteTeacher != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_outlined, size: 13, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Proxy: ${leave.substituteTeacher}',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (leave.attachmentName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attachment_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            leave.attachmentName!,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          // Admin / Principal Remarks Container
          if (leave.adminRemarks != null && leave.adminRemarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reviewer Note: ${leave.adminRemarks}',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: statusColor),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),

          // Multi-Stage Pipeline Visual Indicator
          _buildPipelineIndicator(leave, isMobile),

          // Action row (Withdraw button for pending applications)
          if (leave.isPending) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _showWithdrawConfirmation(leave),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Withdraw Application', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 3-Stage Approval Pipeline Stepper
  Widget _buildPipelineIndicator(StaffLeaveModel leave, bool isMobile) {
    final s2Done = leave.isApproved || leave.isRejected;
    final s2Active = leave.isPending;
    final s3Done = leave.isApproved;
    final s3Rejected = leave.isRejected;
    final s3Cancelled = leave.isCancelled;

    return Row(
      children: [
        _buildPipelineStep('Submitted', AppColors.success, Icons.check_circle, true),
        _buildPipelineLine(s2Done || s2Active, isMobile),
        _buildPipelineStep(
          'HOD Review',
          s2Done
              ? AppColors.success
              : s2Active
                  ? AppColors.warning
                  : Colors.grey,
          s2Done
              ? Icons.check_circle
              : s2Active
                  ? Icons.schedule
                  : Icons.radio_button_unchecked,
          false,
        ),
        _buildPipelineLine(s3Done || s3Rejected || s3Cancelled, isMobile),
        _buildPipelineStep(
          'Principal',
          s3Done
              ? AppColors.success
              : s3Rejected
                  ? AppColors.error
                  : s3Cancelled
                      ? const Color(0xFF64748B)
                      : Colors.grey,
          s3Done
              ? Icons.check_circle
              : s3Rejected
                  ? Icons.cancel
                  : s3Cancelled
                      ? Icons.block
                      : Icons.radio_button_unchecked,
          false,
        ),
      ],
    );
  }

  Widget _buildPipelineStep(String label, Color color, IconData icon, bool isFirst) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineLine(bool active, bool isMobile) {
    return Container(
      width: isMobile ? 8 : 16,
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
      color: active ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
    );
  }
}
