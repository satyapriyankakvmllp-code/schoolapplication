import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../application/staff_controller.dart';
import '../../../domain/staff_member_model.dart';

/// Model representing an individual day's biometric punch & attendance log
class DayAttendanceLog {
  final int day;
  final String dateStr;
  final String weekday;
  final String status; // 'Present', 'Late', 'Half Day', 'On Duty', 'Leave', 'Holiday', 'Absent'
  final Color statusColor;
  final String statusLabel;
  final String? inTime;
  final String? outTime;
  final String workHours;
  final String shift;
  final String? note;
  final bool canRegularize;

  const DayAttendanceLog({
    required this.day,
    required this.dateStr,
    required this.weekday,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    this.inTime,
    this.outTime,
    required this.workHours,
    required this.shift,
    this.note,
    this.canRegularize = false,
  });
}

/// Model representing a staff member's submitted regularization request
class AttendanceRegularizationRequest {
  final String id;
  final String staffId;
  final String date;
  final String punchType; // 'Missed In-Punch', 'Missed Out-Punch', 'Full Day Attendance', 'On-Duty (OD)'
  final String proposedTime;
  final String reasonCategory; // 'Biometric System Glitch', 'Official Outdoor School Duty', 'Forgot Punch', 'Emergency'
  final String remarks;
  final String status; // 'Pending Approval', 'Approved', 'Rejected'
  final DateTime submittedAt;
  final String? reviewerRemarks;

  const AttendanceRegularizationRequest({
    required this.id,
    required this.staffId,
    required this.date,
    required this.punchType,
    required this.proposedTime,
    required this.reasonCategory,
    required this.remarks,
    required this.status,
    required this.submittedAt,
    this.reviewerRemarks,
  });

  AttendanceRegularizationRequest copyWith({
    String? status,
    String? reviewerRemarks,
  }) {
    return AttendanceRegularizationRequest(
      id: id,
      staffId: staffId,
      date: date,
      punchType: punchType,
      proposedTime: proposedTime,
      reasonCategory: reasonCategory,
      remarks: remarks,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewerRemarks: reviewerRemarks ?? this.reviewerRemarks,
    );
  }
}

/// State provider storing regularization requests across all faculty & staff members
final staffAttendanceRegularizationsProvider =
    StateProvider<List<AttendanceRegularizationRequest>>((ref) {
  // Pre-seeded realistic demo requests across academic months
  return [
    AttendanceRegularizationRequest(
      id: 'REG-2026-081',
      staffId: 'STF-2026-0101',
      date: '14 Oct 2026',
      punchType: 'Missed Out-Punch',
      proposedTime: '04:30 PM',
      reasonCategory: 'Biometric System Glitch',
      remarks: 'Biometric reader at Main Gate was rebooting during afternoon departure.',
      status: 'Approved',
      submittedAt: DateTime(2026, 10, 15, 9, 30),
      reviewerRemarks: 'Verified against manual security desk register. Approved.',
    ),
    AttendanceRegularizationRequest(
      id: 'REG-2026-094',
      staffId: 'STF-2026-0101',
      date: '21 Oct 2026',
      punchType: 'On-Duty (OD)',
      proposedTime: '08:30 AM - 04:00 PM',
      reasonCategory: 'Official Outdoor School Duty',
      remarks: 'Deputed as escort teacher for CBSE District Inter-School Science Fair at DAV School.',
      status: 'Pending Approval',
      submittedAt: DateTime(2026, 10, 21, 17, 10),
    ),
    AttendanceRegularizationRequest(
      id: 'REG-2026-062',
      staffId: 'STF-2026-0101',
      date: '18 Sep 2026',
      punchType: 'On-Duty (OD)',
      proposedTime: '09:00 AM - 03:30 PM',
      reasonCategory: 'Official Outdoor School Duty',
      remarks: 'Attended CBSE State Curriculum Capacity Building Workshop at Capital High School.',
      status: 'Approved',
      submittedAt: DateTime(2026, 9, 18, 16, 45),
      reviewerRemarks: 'Workshop deputation certificate verified. Approved.',
    ),
    AttendanceRegularizationRequest(
      id: 'REG-2026-041',
      staffId: 'STF-2026-0101',
      date: '10 Aug 2026',
      punchType: 'Missed In-Punch',
      proposedTime: '08:30 AM',
      reasonCategory: 'Forgot Punch',
      remarks: 'Forgot biometric punch during morning school assembly gate supervision duties.',
      status: 'Approved',
      submittedAt: DateTime(2026, 8, 10, 11, 0),
      reviewerRemarks: 'Verified against morning gate duty roster.',
    ),
  ];
});

/// Universal, fully-featured, responsive "My Attendance" screen shared across all institutional staff types.
class MyAttendanceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const MyAttendanceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  String _selectedMonth = 'October 2026';
  final List<String> _months = [
    'October 2026',
    'September 2026',
    'August 2026',
    'July 2026',
  ];

  DayAttendanceLog? _selectedDayLog;

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final staffListAsync = ref.watch(staffListProvider);
    final allStaff = staffListAsync.valueOrNull ?? [];
    final effectiveStaff = staff ??
        (allStaff.isNotEmpty
            ? allStaff.firstWhere(
                (s) => s.category == StaffCategory.teaching,
                orElse: () => allStaff.first,
              )
            : null);

    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    final allRegularizations = ref.watch(staffAttendanceRegularizationsProvider);
    final myRegularizations = effectiveStaff != null
        ? allRegularizations.where((r) => r.staffId == effectiveStaff.id).toList()
        : allRegularizations;

    final days = _buildMonthLogs(_selectedMonth);
    final lateCount = days.where((d) => d.status == 'Late Check-In' || d.status == 'Late').length;

    // Filter regularizations by selected month
    final monthPrefix = _selectedMonth.split(' ').first.toLowerCase();
    final monthRegularizations = myRegularizations.where((r) {
      return r.date.toLowerCase().contains(monthPrefix);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 14 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HEADER & ACTION BAR (without fingerprint icon)
          _buildTopHeader(context, effectiveStaff, days, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 16),

          // 2. TODAY'S LIVE ATTENDANCE OR ARCHIVED MONTH SUMMARY
          if (_selectedMonth == 'October 2026')
            _buildTodayLiveStatusCard(context, effectiveStaff, cardBg, borderColor, textColor, subColor, isMobile, dark)
          else
            _buildArchivedMonthStatusCard(context, _selectedMonth, days, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 16),

          // 3. MONTHLY ATTENDANCE KPI STATS (6 CARDS - Computed dynamically from selected month)
          _buildKpiMetricsGrid(days, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 16),

          // 4. ATTENDANCE DISCIPLINE & LATE PENALTY POLICY ALERT BANNER (Dynamic for selected month)
          _buildLatePenaltyBanner(_selectedMonth, lateCount, isMobile, dark),

          const SizedBox(height: 18),

          // 5. 31-DAY INTERACTIVE BIOMETRIC CALENDAR MATRIX (Dynamic start offset and days)
          _buildCalendarMatrix(context, days, _selectedMonth, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 18),

          // 6. REGULARIZATION & MISSED PUNCH REQUESTS TRACKER (Filtered by selected month)
          _buildRegularizationSection(context, monthRegularizations, effectiveStaff, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 18),

          // 7. 6-MONTH ATTENDANCE COMPLIANCE TREND (Highlights selected month)
          _buildTrendChart(_selectedMonth, cardBg, borderColor, textColor, subColor, isMobile, dark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(
    BuildContext context,
    StaffMemberModel? staff,
    List<DayAttendanceLog> days,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Attendance Ledger',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biometric logs, shift tracking & compliance for ${staff?.fullName ?? "Faculty Member"}',
                      style: TextStyle(fontSize: 12, color: subColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Month dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: dark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isDense: true,
                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: subColor),
                    dropdownColor: cardBg,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    items: _months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMonth = val;
                          _selectedDayLog = null;
                        });
                      }
                    },
                  ),
                ),
              ),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showExportSlipModal(context, staff, dark, _selectedMonth, days),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Export Slip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRegularizationModal(context, staff, dark, null),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Request Regularization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TODAY'S LIVE STATUS HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildTodayLiveStatusCard(
    BuildContext context,
    StaffMemberModel? staff,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: dark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'TODAY’S SHIFT STATUS: 22 OCT 2026',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: dark ? AppColors.success : const Color(0xFF166534),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TODAY’S SHIFT STATUS: 22 OCT 2026',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: dark ? AppColors.success : const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'PUNCH-IN VERIFIED',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTimeMetric('Punch In', '08:34 AM', Icons.login_rounded, AppColors.success, textColor, subColor, 'Machine #02 (Gate A)')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTimeMetric('Expected Out', '04:00 PM', Icons.logout_rounded, AppColors.primary, textColor, subColor, 'Standard Shift End')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTimeMetric('Shift Hours', '07h 30m', Icons.schedule_rounded, const Color(0xFF6366F1), textColor, subColor, 'Mandatory Target')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTimeMetric('Punctuality', 'On Time', Icons.verified_user_rounded, AppColors.success, textColor, subColor, 'Grace Period: 15m')),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTimeMetric('Punch In', '08:34 AM', Icons.login_rounded, AppColors.success, textColor, subColor, 'Machine #02 (Gate A)')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Expected Out', '04:00 PM', Icons.logout_rounded, AppColors.primary, textColor, subColor, 'Standard Shift End')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Shift Hours', '07h 30m', Icons.schedule_rounded, const Color(0xFF6366F1), textColor, subColor, 'Mandatory Target')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Punctuality', 'On Time', Icons.verified_user_rounded, AppColors.success, textColor, subColor, 'Grace Period: 15m')),
                  ],
                ),
          const SizedBox(height: 14),
          // Working hours live meter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isMobile ? 'Progress: 6h 15m / 7h 30m' : 'Campus Work Duration Progress: 6h 15m / 7h 30m',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '83% Completed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.83,
                  minHeight: 7,
                  backgroundColor: dark ? Colors.white10 : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedMonthStatusCard(
    BuildContext context,
    String month,
    List<DayAttendanceLog> days,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    final totalDays = days.length;
    final holidays = days.where((d) => d.status == 'Holiday').length;
    final workingDays = totalDays - holidays;
    final present = days.where((d) => d.status == 'Present').length;
    final od = days.where((d) => d.status == 'On Duty').length;
    final totalHours = (present * 7.5 + od * 7.5).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ARCHIVED LEDGER: $month',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'AUDITED & CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTimeMetric('Campus Time Logged', '${totalHours}h', Icons.timelapse_rounded, AppColors.primary, textColor, subColor, 'Biometric Total')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTimeMetric('Shift Compliance', '100% Verified', Icons.verified_user_rounded, AppColors.success, textColor, subColor, 'Standard Shift')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildTimeMetric('Payroll Sync', 'Disbursed', Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6), textColor, subColor, 'HR Ledger Closed')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTimeMetric('Audit Remarks', 'No Discrepancies', Icons.fact_check_rounded, const Color(0xFF6366F1), textColor, subColor, 'Finalized')),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTimeMetric('Campus Time Logged', '${totalHours}h', Icons.timelapse_rounded, AppColors.primary, textColor, subColor, 'Biometric Total')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Shift Compliance', '100% Verified', Icons.verified_user_rounded, AppColors.success, textColor, subColor, 'Standard Shift')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Payroll Sync', 'Disbursed', Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6), textColor, subColor, 'HR Ledger Closed')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeMetric('Audit Remarks', 'No Discrepancies', Icons.fact_check_rounded, const Color(0xFF6366F1), textColor, subColor, 'Finalized')),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(
    String label,
    String time,
    IconData icon,
    Color color,
    Color textColor,
    Color subColor,
    String caption,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(fontSize: 10, color: subColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. MONTHLY ATTENDANCE KPI STATS (6 CARDS)
  // ---------------------------------------------------------------------------
  Widget _buildKpiMetricsGrid(
    List<DayAttendanceLog> days,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    final totalDays = days.length;
    final holidays = days.where((d) => d.status == 'Holiday').length;
    final workingDays = totalDays - holidays;
    final present = days.where((d) => d.status == 'Present').length;
    final leaves = days.where((d) => d.status == 'Leave' || d.status == 'Half Day').length;
    final od = days.where((d) => d.status == 'On Duty').length;
    final lateCount = days.where((d) => d.status == 'Late Check-In' || d.status == 'Late').length;
    final netPayable = (present + od + leaves + lateCount) - ((lateCount ~/ 3) * 0.5);
    final compliancePct = workingDays > 0 ? ((netPayable / workingDays) * 100).toStringAsFixed(1) : '100.0';

    final c1 = _buildKpiBox('Total Working Days', '$workingDays', Icons.calendar_month_outlined, const Color(0xFF64748B), cardBg, borderColor, textColor, subColor, 'Official Academic Days');
    final c2 = _buildKpiBox('Present Days', '$present', Icons.check_circle_outline_rounded, AppColors.success, cardBg, borderColor, textColor, subColor, 'Full Day In-Campus');
    final c3 = _buildKpiBox('Approved Leaves', leaves < 10 ? '0$leaves' : '$leaves', Icons.beach_access_outlined, const Color(0xFF0284C7), cardBg, borderColor, textColor, subColor, leaves == 0 ? 'Zero Leaves Taken' : '$leaves Approved Record(s)');
    final c4 = _buildKpiBox('On-Duty (OD)', od < 10 ? '0$od' : '$od', Icons.assignment_turned_in_outlined, const Color(0xFF8B5CF6), cardBg, borderColor, textColor, subColor, od == 0 ? 'No Outdoor Deputation' : '$od School Deputation(s)');
    final c5 = _buildKpiBox('Late Arrivals', lateCount < 10 ? '0$lateCount' : '$lateCount', Icons.alarm_on_outlined, lateCount > 0 ? AppColors.warning : AppColors.success, cardBg, borderColor, textColor, subColor, lateCount == 0 ? 'Punctual Month' : 'Policy Limit: 3/Month');
    final c6 = _buildKpiBox('Net Payable Days', netPayable % 1 == 0 ? '${netPayable.toInt()} / $workingDays' : '$netPayable / $workingDays', Icons.currency_rupee_rounded, AppColors.primary, cardBg, borderColor, textColor, subColor, '$compliancePct% Salary Compliance');

    if (isMobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: c1), const SizedBox(width: 10), Expanded(child: c2)]),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: c3), const SizedBox(width: 10), Expanded(child: c4)]),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: c5), const SizedBox(width: 10), Expanded(child: c6)]),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(children: [Expanded(child: c1), const SizedBox(width: 10), Expanded(child: c2), const SizedBox(width: 10), Expanded(child: c3)]),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: c4), const SizedBox(width: 10), Expanded(child: c5), const SizedBox(width: 10), Expanded(child: c6)]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: c1),
            const SizedBox(width: 10),
            Expanded(child: c2),
            const SizedBox(width: 10),
            Expanded(child: c3),
            const SizedBox(width: 10),
            Expanded(child: c4),
            const SizedBox(width: 10),
            Expanded(child: c5),
            const SizedBox(width: 10),
            Expanded(child: c6),
          ],
        );
      },
    );
  }

  Widget _buildKpiBox(
    String title,
    String value,
    IconData icon,
    Color accent,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    String caption,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(fontSize: 10, color: subColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LATE PENALTY WARNING BANNER
  // ---------------------------------------------------------------------------
  Widget _buildLatePenaltyBanner(String month, int lateCount, bool isMobile, bool dark) {
    if (lateCount == 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withValues(alpha: dark ? 0.4 : 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perfect Punctuality Record',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Zero late arrivals recorded for $month! You have achieved 100% on-time attendance compliance with zero penalty deductions.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? const Color(0xFFA7F3D0) : const Color(0xFF14532D),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF291A00) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.4 : 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institutional Punctuality Rule Alert',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'As per KVM service regulations, accumulating '),
                      const TextSpan(
                        text: '3 Late check-ins in a month results in a 1/2 day Casual Leave (CL) deduction',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '. You have recorded '),
                      TextSpan(
                        text: '$lateCount late arrival${lateCount > 1 ? "s" : ""} for $month',
                        style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                      TextSpan(
                        text: lateCount >= 3
                            ? '. Penalty threshold reached: 1/2 day CL deduction applied in payroll.'
                            : '. Kindly ensure punch-in before 08:30 AM to maintain full compensation.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 31-DAY BIOMETRIC CALENDAR MATRIX
  // ---------------------------------------------------------------------------
  Widget _buildCalendarMatrix(
    BuildContext context,
    List<DayAttendanceLog> days,
    String month,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$month Daily Log Matrix',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap on any day cell to inspect biometric in/out logs or request regularization',
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Badges Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegend(AppColors.success, 'P', 'Present', subColor),
              _buildLegend(AppColors.warning, 'L', 'Late', subColor),
              _buildLegend(const Color(0xFF8B5CF6), 'OD', 'On-Duty', subColor),
              _buildLegend(const Color(0xFF0284C7), 'LV', 'Leave', subColor),
              _buildLegend(AppColors.error, 'A', 'Absent', subColor),
              _buildLegend(Colors.grey.shade400, 'H', 'Holiday / Sunday', subColor),
            ],
          ),
          const SizedBox(height: 16),

          // Days Grid (7 columns layout: Sun, Mon, Tue, Wed, Thu, Fri, Sat)
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = ((constraints.maxWidth - (6 * 6)) / 7).floorToDouble();
              final startOffset = _getMonthStartOffset(month);

              return Column(
                children: [
                  // Weekday Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
                      final isSun = d == 'Sun';
                      return SizedBox(
                        width: cellWidth,
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSun ? AppColors.error : subColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar day cells
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Blank offset placeholders before Day 1
                      for (int i = 0; i < startOffset; i++)
                        SizedBox(
                          width: cellWidth,
                          height: isMobile ? 52 : 58,
                        ),
                      ...days.map((dayLog) {
                        final isSelected = _selectedDayLog?.day == dayLog.day;

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedDayLog = dayLog);
                          _showDayDetailsBottomSheet(context, dayLog, dark);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: cellWidth,
                          height: isMobile ? 52 : 58,
                          decoration: BoxDecoration(
                            color: dayLog.statusColor.withValues(alpha: dark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : dayLog.statusColor.withValues(alpha: dark ? 0.6 : 0.4),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${dayLog.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: dayLog.statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dayLog.statusLabel,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (!isMobile && dayLog.inTime != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dayLog.inTime!,
                                  style: TextStyle(fontSize: 8, color: subColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                      }).toList(),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String code, String label, Color subColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            code,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: subColor)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. REGULARIZATION SECTION
  // ---------------------------------------------------------------------------
  Widget _buildRegularizationSection(
    BuildContext context,
    List<AttendanceRegularizationRequest> requests,
    StaffMemberModel? staff,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Regularization Requests',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Outdoor school duties & biometric mismatches',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRegularizationModal(context, staff, dark, null),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Missed Punch & Regularization Requests',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track Principal / Admin approvals for official outdoor duties & biometric mismatches',
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showRegularizationModal(context, staff, dark, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),

          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: subColor.withValues(alpha: 0.5), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No pending or past regularization requests.',
                    style: TextStyle(fontSize: 12.5, color: subColor),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = requests[index];
                Color badgeBg;
                Color badgeFg;
                IconData badgeIcon;

                switch (req.status.toLowerCase()) {
                  case 'approved':
                    badgeBg = AppColors.success.withValues(alpha: 0.12);
                    badgeFg = AppColors.success;
                    badgeIcon = Icons.check_circle_rounded;
                    break;
                  case 'rejected':
                    badgeBg = AppColors.error.withValues(alpha: 0.12);
                    badgeFg = AppColors.error;
                    badgeIcon = Icons.cancel_rounded;
                    break;
                  default:
                    badgeBg = AppColors.warning.withValues(alpha: 0.12);
                    badgeFg = AppColors.warning;
                    badgeIcon = Icons.hourglass_top_rounded;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(badgeIcon, color: badgeFg, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${req.punchType} (${req.date})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: badgeFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${req.reasonCategory} • Proposed Time: ${req.proposedTime}',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              req.remarks,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: dark ? Colors.white70 : const Color(0xFF334155),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (req.reviewerRemarks != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Principal Note: ${req.reviewerRemarks}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badgeFg,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. 6-MONTH TREND CHART
  // ---------------------------------------------------------------------------
  Widget _buildTrendChart(
    String month,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
    bool dark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Attendance Trend ($month)',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('Compliance %', style: TextStyle(fontSize: 10.5, color: subColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Punctual check-ins (Past 6 Months)',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Compliance Trend (Past 6 Months)',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Punctual check-ins and presence percentage • Selected: $month',
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Compliance %', style: TextStyle(fontSize: 11, color: subColor)),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: borderColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(fontSize: 9, color: subColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          final isCurrentMonth = month.toLowerCase().startsWith(months[idx].toLowerCase());
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[idx],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentMonth ? AppColors.primary : subColor,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 60,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 92),
                      FlSpot(1, 89),
                      FlSpot(2, 95),
                      FlSpot(3, 94),
                      FlSpot(4, 91),
                      FlSpot(5, 96),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DAY DETAILS BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showDayDetailsBottomSheet(BuildContext context, DayAttendanceLog log, bool dark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.dateStr} (${log.weekday})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shift: ${log.shift}',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: log.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: log.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: log.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: dark ? AppColors.borderDark : AppColors.borderLight),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildModalDetailRow('Check-In Time', log.inTime ?? 'No Record', Icons.login)),
                Expanded(child: _buildModalDetailRow('Check-Out Time', log.outTime ?? 'No Record', Icons.logout)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildModalDetailRow('Total Hours', log.workHours, Icons.schedule)),
                Expanded(child: _buildModalDetailRow('Biometric Gate', 'Gate A (Reader 02)', Icons.qr_code_scanner)),
              ],
            ),
            if (log.note != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log.note!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (log.canRegularize)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showRegularizationModal(context, ref.read(currentLoggedInStaffProvider), dark, log.dateStr);
                  },
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: Text('Apply Regularization for ${log.dateStr}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REGULARIZATION MODAL
  // ---------------------------------------------------------------------------
  void _showRegularizationModal(
    BuildContext context,
    StaffMemberModel? staff,
    bool dark,
    String? initialDate,
  ) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: initialDate ?? '21 Oct 2026');
    final timeController = TextEditingController(text: '04:30 PM');
    final remarksController = TextEditingController();

    String selectedType = 'Missed Out-Punch';
    String selectedReason = 'Biometric System Glitch';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Regularization / Missed Punch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit verification request to Principal / Admin for biometric rectifications.',
                    style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 14),

                  // Date
                  TextFormField(
                    controller: dateController,
                    decoration: InputDecoration(
                      labelText: 'Incident Date',
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter date' : null,
                  ),
                  const SizedBox(height: 12),

                  // Punch Type
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Punch Type to Regularize',
                      prefixIcon: const Icon(Icons.touch_app_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Missed In-Punch', child: Text('Missed In-Punch (Morning)')),
                      DropdownMenuItem(value: 'Missed Out-Punch', child: Text('Missed Out-Punch (Afternoon)')),
                      DropdownMenuItem(value: 'Full Day Attendance', child: Text('Full Day Attendance (Biometric Down)')),
                      DropdownMenuItem(value: 'On-Duty (OD)', child: Text('On-Duty (OD) Official Deputation')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Actual / Proposed Time
                  TextFormField(
                    controller: timeController,
                    decoration: InputDecoration(
                      labelText: 'Proposed Actual Time',
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter time' : null,
                  ),
                  const SizedBox(height: 12),

                  // Reason Category
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Reason Category',
                      prefixIcon: const Icon(Icons.category_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Biometric System Glitch', child: Text('Biometric Machine Error / Power Failure')),
                      DropdownMenuItem(value: 'Official Outdoor School Duty', child: Text('Official Outdoor School Event / Exam Duty')),
                      DropdownMenuItem(value: 'Forgot Punch', child: Text('Forgot to Punch In/Out')),
                      DropdownMenuItem(value: 'Emergency', child: Text('Urgent Institutional Matter / Medical Departure')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Explanation Remarks
                  TextFormField(
                    controller: remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Detailed Explanation / Remarks',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please explain the reason' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final newReq = AttendanceRegularizationRequest(
                    id: 'REG-2026-${100 + DateTime.now().millisecond}',
                    staffId: staff?.id ?? 'STF-2026-0101',
                    date: dateController.text.trim(),
                    punchType: selectedType,
                    proposedTime: timeController.text.trim(),
                    reasonCategory: selectedReason,
                    remarks: remarksController.text.trim(),
                    status: 'Pending Approval',
                    submittedAt: DateTime.now(),
                  );

                  ref.read(staffAttendanceRegularizationsProvider.notifier).update(
                        (state) => [newReq, ...state],
                      );

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Attendance regularization request submitted for Principal/Admin approval!',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT ATTENDANCE SLIP MODAL
  // ---------------------------------------------------------------------------
  void _showExportSlipModal(
    BuildContext context,
    StaffMemberModel? staff,
    bool dark,
    String month,
    List<DayAttendanceLog> days,
  ) {
    final totalDays = days.length;
    final holidays = days.where((d) => d.status == 'Holiday').length;
    final workingDays = totalDays - holidays;
    final present = days.where((d) => d.status == 'Present').length;
    final leaves = days.where((d) => d.status == 'Leave' || d.status == 'Half Day').length;
    final od = days.where((d) => d.status == 'On Duty').length;
    final lateCount = days.where((d) => d.status == 'Late Check-In' || d.status == 'Late').length;
    final netPayable = (present + od + leaves + lateCount) - ((lateCount ~/ 3) * 0.5);
    final compliancePct = workingDays > 0 ? ((netPayable / workingDays) * 100).toStringAsFixed(1) : '100.0';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 16, 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Monthly Attendance Docket',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Institutional verification docket for payroll and leave audit.',
                style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff?.fullName ?? 'Faculty Member',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${staff?.designation ?? "Faculty"} • ID: ${staff?.id ?? "STF-2026-0101"}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 6),
                    _buildSlipItem('Billing Period', month),
                    _buildSlipItem('Total Academic Days', '$workingDays Days'),
                    _buildSlipItem('Total Present Days', '$present Days'),
                    _buildSlipItem('Approved Paid Leaves', '$leaves Days'),
                    _buildSlipItem('On-Duty Deputations', '$od Day(s)'),
                    _buildSlipItem('Late Check-Ins', '$lateCount Occurrences'),
                    _buildSlipItem('Loss of Pay (LWP)', '${days.where((d) => d.status == "Absent").length} Days'),
                    const SizedBox(height: 6),
                    const Divider(),
                    const SizedBox(height: 6),
                    _buildSlipItem(
                      'Net Payable Attendance',
                      '${netPayable % 1 == 0 ? netPayable.toInt() : netPayable} / $workingDays Days ($compliancePct%)',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Dispatching verified attendance docket of ${staff?.fullName ?? "Staff"} ($month) to institutional printer...',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print Docket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipItem(String key, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 11.5, color: isBold ? null : Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAMPLE DATA GENERATOR MATCHING ACADEMIC CALENDAR & DYNAMIC MONTHS
  // ---------------------------------------------------------------------------
  int _getMonthStartOffset(String month) {
    if (month.startsWith('October')) return 4; // Oct 1, 2026 is Thursday (Sun=0, Mon=1, Tue=2, Wed=3, Thu=4)
    if (month.startsWith('September')) return 2; // Sep 1, 2026 is Tuesday (offset 2)
    if (month.startsWith('August')) return 6; // Aug 1, 2026 is Saturday (offset 6)
    if (month.startsWith('July')) return 3; // Jul 1, 2026 is Wednesday (offset 3)
    return 0;
  }

  List<DayAttendanceLog> _buildMonthLogs(String month) {
    const weekdaysList = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final int daysCount = month.startsWith('September') ? 30 : 31;
    final int startOffset = _getMonthStartOffset(month);
    final String monthName = month.split(' ').first;

    return List.generate(daysCount, (index) {
      final day = index + 1;
      final weekdayIndex = (startOffset + index) % 7;
      final weekday = weekdaysList[weekdayIndex];
      final isSunday = weekday == 'Sun';
      final isSecondSaturday = weekday == 'Sat' && (day >= 8 && day <= 14);

      Color statusColor;
      String status;
      String statusLabel;
      String? inTime;
      String? outTime;
      String workHours;
      String? note;
      bool canRegularize = false;

      // 1. Sundays & 2nd Saturdays
      if (isSunday || isSecondSaturday) {
        statusColor = Colors.grey.shade400;
        status = 'Holiday';
        statusLabel = 'H';
        workHours = '0h 00m';
        note = isSunday ? 'Weekly Sunday Off' : 'Institutional 2nd Saturday Holiday';
      }
      // Month-specific dynamic logs
      else if (month.startsWith('October')) {
        if (day == 8) {
          statusColor = AppColors.error;
          status = 'Absent';
          statusLabel = 'A';
          workHours = '0h 00m';
          note = 'Unreported Absence. Tap to Regularize or Convert to Leave.';
          canRegularize = true;
        } else if (day == 14) {
          statusColor = const Color(0xFF0284C7);
          status = 'Leave';
          statusLabel = 'LV';
          workHours = '0h 00m';
          note = 'Approved Casual Leave (CL)';
        } else if (day == 17) {
          statusColor = const Color(0xFF0284C7);
          status = 'Leave';
          statusLabel = 'LV';
          workHours = '0h 00m';
          note = 'Approved Medical Leave (ML)';
        } else if (day == 21) {
          statusColor = const Color(0xFF8B5CF6);
          status = 'On Duty';
          statusLabel = 'OD';
          inTime = '08:30 AM';
          outTime = '04:00 PM';
          workHours = '07h 30m';
          note = 'District Inter-School Science Fair (Official Deputation)';
        } else if (day == 6 || day == 19) {
          statusColor = AppColors.warning;
          status = 'Late Check-In';
          statusLabel = 'L';
          inTime = day == 6 ? '08:48 AM' : '08:44 AM';
          outTime = '04:10 PM';
          workHours = '07h 22m';
          note = 'Late by ${day == 6 ? "18 mins" : "14 mins"}. Subject to Late Mark.';
          canRegularize = true;
        } else {
          statusColor = AppColors.success;
          status = 'Present';
          statusLabel = 'P';
          inTime = '08:28 AM';
          outTime = '04:05 PM';
          workHours = '07h 37m';
          note = 'On Time Check-in. Biometric Reader Gate A.';
        }
      } else if (month.startsWith('September')) {
        if (day == 11) {
          statusColor = const Color(0xFF0284C7);
          status = 'Leave';
          statusLabel = 'LV';
          workHours = '0h 00m';
          note = 'Approved Casual Leave (CL) - Personal Affairs';
        } else if (day == 18) {
          statusColor = const Color(0xFF8B5CF6);
          status = 'On Duty';
          statusLabel = 'OD';
          inTime = '09:00 AM';
          outTime = '03:30 PM';
          workHours = '06h 30m';
          note = 'CBSE State Curriculum Capacity Building Workshop at Capital High School';
        } else {
          statusColor = AppColors.success;
          status = 'Present';
          statusLabel = 'P';
          inTime = day == 5 ? '08:15 AM' : '08:25 AM';
          outTime = '04:05 PM';
          workHours = '07h 40m';
          note = day == 5 ? 'Teachers\' Day Special Assembly. On Time.' : 'On Time Check-in. Biometric Gate A.';
        }
      } else if (month.startsWith('August')) {
        if (day == 15) {
          statusColor = Colors.grey.shade400;
          status = 'Holiday';
          statusLabel = 'H';
          workHours = '0h 00m';
          note = 'Independence Day (National Holiday)';
        } else if (day == 24) {
          statusColor = Colors.grey.shade400;
          status = 'Holiday';
          statusLabel = 'H';
          workHours = '0h 00m';
          note = 'Janmashtami (Institutional Holiday)';
        } else if (day == 5) {
          statusColor = const Color(0xFF0284C7);
          status = 'Leave';
          statusLabel = 'LV';
          workHours = '0h 00m';
          note = 'Approved Casual Leave (CL)';
        } else if (day == 10) {
          statusColor = AppColors.warning;
          status = 'Late Check-In';
          statusLabel = 'L';
          inTime = '08:42 AM';
          outTime = '04:05 PM';
          workHours = '07h 23m';
          note = 'Late by 12 mins. Morning assembly gate duty.';
          canRegularize = true;
        } else {
          statusColor = AppColors.success;
          status = 'Present';
          statusLabel = 'P';
          inTime = '08:26 AM';
          outTime = '04:00 PM';
          workHours = '07h 34m';
          note = 'On Time Check-in. Biometric Gate A.';
        }
      } else {
        // July
        if (day == 8 || day == 9) {
          statusColor = const Color(0xFF0284C7);
          status = 'Leave';
          statusLabel = 'LV';
          workHours = '0h 00m';
          note = 'Approved Casual Leave (CL) - Annual Family Leave';
        } else if (day == 22) {
          statusColor = const Color(0xFF8B5CF6);
          status = 'On Duty';
          statusLabel = 'OD';
          inTime = '08:30 AM';
          outTime = '04:00 PM';
          workHours = '07h 30m';
          note = 'CBSE Regional Pedagogy Seminar';
        } else if (day == 3 || day == 14 || day == 27) {
          statusColor = AppColors.warning;
          status = 'Late Check-In';
          statusLabel = 'L';
          inTime = day == 27 ? '08:51 AM' : '08:45 AM';
          outTime = '04:15 PM';
          workHours = '07h 24m';
          note = 'Late check-in recorded. Policy threshold applied.';
          canRegularize = true;
        } else {
          statusColor = AppColors.success;
          status = 'Present';
          statusLabel = 'P';
          inTime = '08:27 AM';
          outTime = '04:02 PM';
          workHours = '07h 35m';
          note = 'On Time Check-in. Biometric Reader Gate A.';
        }
      }

      final shortMonth = monthName.length > 3 ? monthName.substring(0, 3) : monthName;
      final dateStr = '$day $shortMonth 2026';

      return DayAttendanceLog(
        day: day,
        dateStr: dateStr,
        weekday: weekday,
        status: status,
        statusColor: statusColor,
        statusLabel: statusLabel,
        inTime: inTime,
        outTime: outTime,
        workHours: workHours,
        shift: 'Morning Shift (08:30 - 04:00)',
        note: note,
        canRegularize: canRegularize,
      );
    });
  }
}
