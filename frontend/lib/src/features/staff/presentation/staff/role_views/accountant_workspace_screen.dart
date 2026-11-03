import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../application/staff_controller.dart';

class AccountantWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const AccountantWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<AccountantWorkspaceScreen> createState() => _AccountantWorkspaceScreenState();
}

class _AccountantWorkspaceScreenState extends ConsumerState<AccountantWorkspaceScreen> {
  final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final List<Map<String, dynamic>> _feeTransactions = [
    {'rcpt': 'RCP-2026-881', 'student': 'Aarav Sharma (10-A)', 'head': 'Term 2 Tuition Fee', 'amount': 24500, 'mode': 'UPI / NetBanking', 'status': 'Paid'},
    {'rcpt': 'RCP-2026-882', 'student': 'Diya Patel (10-A)', 'head': 'Term 2 Tuition Fee', 'amount': 24500, 'mode': 'Debit Card (POS)', 'status': 'Paid'},
    {'rcpt': 'RCP-2026-883', 'student': 'Rohan Verma (10-A)', 'head': 'Annual Lab & Library Fee', 'amount': 8200, 'mode': 'Cheque Clearance', 'status': 'Paid'},
    {'rcpt': 'RCP-2026-884', 'student': 'Sneha Iyer (10-A)', 'head': 'Bus Transport Q3', 'amount': 6500, 'mode': 'Online Gateway', 'status': 'Paid'},
    {'rcpt': 'RCP-2026-885', 'student': 'Kabir Mehta (10-A)', 'head': 'Term 2 Tuition Fee', 'amount': 24500, 'mode': 'Cash Counter', 'status': 'Pending'},
  ];

  final Map<String, bool> _disbursedStaff = {};

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final staffList = ref.watch(staffListProvider).valueOrNull ?? [];

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
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899).withValues(alpha: dark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundColor: const Color(0xFFEC4899),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
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
                              'Treasury & Accounts Bursar Desk',
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
                              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACCOUNTANT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comptroller: ${staff?.fullName ?? 'Sunita Verma'} • Fee counter collections & payroll execution',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Financial KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final kpiToday = _buildKpiCard('Today\'s Collections', '₹63,700', AppColors.success, Icons.payments, cardBg, borderColor, dark);
              final kpiMonthly = _buildKpiCard('Month-to-Date Fees', '₹18,45,000', AppColors.primary, Icons.savings_outlined, cardBg, borderColor, dark);
              final kpiPending = _buildKpiCard('Unpaid Dues Alert', '₹2,84,000', AppColors.error, Icons.warning_amber_rounded, cardBg, borderColor, dark);
              final kpiPayroll = _buildKpiCard('Payroll Budget', '₹12,40,000', const Color(0xFFEC4899), Icons.receipt_long, cardBg, borderColor, dark);

              if (isNarrow) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: kpiToday), const SizedBox(width: 10), Expanded(child: kpiMonthly)]),
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: kpiPending), const SizedBox(width: 10), Expanded(child: kpiPayroll)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: kpiToday),
                  const SizedBox(width: 12),
                  Expanded(child: kpiMonthly),
                  const SizedBox(width: 12),
                  Expanded(child: kpiPending),
                  const SizedBox(width: 12),
                  Expanded(child: kpiPayroll),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Fee Collection Table
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
                    Text('Today\'s Fee Collection Counter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Instant receipt receipt generator opened.'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Fee Receipt'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _feeTransactions.length,
                  separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.5)),
                  itemBuilder: (context, index) {
                    final tx = _feeTransactions[index];
                    final isPaid = tx['status'] == 'Paid';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(isPaid ? Icons.check_circle : Icons.hourglass_top, color: isPaid ? AppColors.success : AppColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx['student'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                Text('${tx['head']} • Mode: ${tx['mode']} • Ref: ${tx['rcpt']}', style: TextStyle(fontSize: 11, color: subColor)),
                              ],
                            ),
                          ),
                          Text(
                            currencyFmt.format(tx['amount']),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPaid ? AppColors.success : AppColors.warning),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Salary Disbursement Desk
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
                    Text('Staff Salary Disbursement Ledger (October 2026)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    const Text('NEFT Direct Transfer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: staffList.take(6).length,
                  separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.5)),
                  itemBuilder: (context, index) {
                    final s = staffList[index];
                    final basic = s.compensation.basicSalary;
                    final net = (basic * 1.18).roundToDouble();
                    final isPaid = _disbursedStaff[s.id] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(s.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                Text('${s.designation} • ${s.compensation.bankName} (${s.compensation.maskedAccountNumber})', style: TextStyle(fontSize: 11, color: subColor)),
                              ],
                            ),
                          ),
                          Text(currencyFmt.format(net), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 12),
                          isPaid
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Disbursed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _disbursedStaff[s.id] = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Salary of ${currencyFmt.format(net)} disbursed to ${s.fullName}!'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEC4899),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  child: const Text('Pay / Disburse'),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color accent, IconData icon, Color cardBg, Color borderColor, bool dark) {
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
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(fontSize: 11, color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
