import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../domain/staff_member_model.dart';

class MyPayrollScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const MyPayrollScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<MyPayrollScreen> createState() => _MyPayrollScreenState();
}

class _MyPayrollScreenState extends ConsumerState<MyPayrollScreen> {
  final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _showPayslipModal(BuildContext context, StaffMemberModel staff, Map<String, dynamic> slip) {
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final cardBg = dark ? AppColors.surfaceDark : Colors.white;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;

    final basic = staff.compensation.basicSalary;
    final hra = (basic * 0.20).roundToDouble();
    final da = (basic * 0.15).roundToDouble();
    final gross = basic + hra + da;
    final pf = (basic * 0.12).roundToDouble();
    final tax = (basic * 0.05).roundToDouble();
    final totalDeductions = pf + tax;
    final net = gross - totalDeductions;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salary Slip — ${slip['month']}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    'Voucher Ref: ${slip['vch']}',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institutional Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'EduPulse Global Academy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        'Faculty Payroll Statement & Tax Slip',
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Divider(color: borderColor),

                // Employee Coordinates
                _buildModalRow('Employee Name', staff.fullName, textColor, subColor),
                _buildModalRow('Staff ID', staff.id, textColor, subColor),
                _buildModalRow('Designation', staff.designation, textColor, subColor),
                _buildModalRow('Bank Name', staff.compensation.bankName, textColor, subColor),
                _buildModalRow('Account No', staff.compensation.maskedAccountNumber, textColor, subColor),
                _buildModalRow('PAN Card', staff.compensation.maskedPanNumber, textColor, subColor),
                Divider(color: borderColor),

                // Earnings vs Deductions Table
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EARNINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.success)),
                          const SizedBox(height: 6),
                          _buildModalRow('Basic Pay', currencyFmt.format(basic), textColor, subColor),
                          _buildModalRow('HRA (20%)', currencyFmt.format(hra), textColor, subColor),
                          _buildModalRow('DA (15%)', currencyFmt.format(da), textColor, subColor),
                          const Divider(),
                          _buildModalRow('Gross Pay', currencyFmt.format(gross), textColor, subColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Deductions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DEDUCTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.error)),
                          const SizedBox(height: 6),
                          _buildModalRow('Provident Fund', currencyFmt.format(pf), textColor, subColor),
                          _buildModalRow('Income Tax', currencyFmt.format(tax), textColor, subColor),
                          const Divider(),
                          _buildModalRow('Total Deductions', currencyFmt.format(totalDeductions), textColor, subColor),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: borderColor),

                // Net Salary Highlight
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NET SALARY TRANSFERRED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        currencyFmt.format(net),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Salary slip PDF dispatch sent to print spooler.'),
                  backgroundColor: AppColors.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Download / Print PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: subColor)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
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

    final basic = staff?.compensation.basicSalary ?? 65000.0;
    final gross = (basic * 1.35).roundToDouble();
    final deductions = (basic * 0.17).roundToDouble();
    final net = gross - deductions;

    final vouchers = [
      {'month': 'October 2026', 'vch': 'ACC-VCH-2026-10', 'date': '07 Oct 2026', 'net': net, 'status': 'Disbursed'},
      {'month': 'September 2026', 'vch': 'ACC-VCH-2026-09', 'date': '07 Sep 2026', 'net': net, 'status': 'Disbursed'},
      {'month': 'August 2026', 'vch': 'ACC-VCH-2026-08', 'date': '07 Aug 2026', 'net': net, 'status': 'Disbursed'},
      {'month': 'July 2026', 'vch': 'ACC-VCH-2026-07', 'date': '07 Jul 2026', 'net': net, 'status': 'Disbursed'},
      {'month': 'June 2026', 'vch': 'ACC-VCH-2026-06', 'date': '07 Jun 2026', 'net': net, 'status': 'Disbursed'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Compensation & Payslips',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly compensation statements, bank credit records, and tax deductions',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          const SizedBox(height: 20),

          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final kpiNet = _buildKpiCard('Net Take-Home', currencyFmt.format(net), AppColors.success, Icons.wallet, cardBg, borderColor, dark);
              final kpiGross = _buildKpiCard('Gross Monthly Pay', currencyFmt.format(gross), AppColors.primary, Icons.payments_outlined, cardBg, borderColor, dark);
              final kpiDed = _buildKpiCard('Total Deductions', currencyFmt.format(deductions), AppColors.error, Icons.money_off_outlined, cardBg, borderColor, dark);

              if (isNarrow) {
                return Column(
                  children: [
                    kpiNet,
                    const SizedBox(height: 10),
                    Row(children: [Expanded(child: kpiGross), const SizedBox(width: 10), Expanded(child: kpiDed)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: kpiNet),
                  const SizedBox(width: 14),
                  Expanded(child: kpiGross),
                  const SizedBox(width: 14),
                  Expanded(child: kpiDed),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Bank Details Banner
          if (staff != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Deposit: ${staff.compensation.bankName}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account: ${staff.compensation.maskedAccountNumber} • IFSC: ${staff.compensation.ifscCode} • PAN: ${staff.compensation.maskedPanNumber}',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Vouchers Table
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
                Text(
                  'Historical Disbursement Vouchers',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vouchers.length,
                  separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.6)),
                  itemBuilder: (context, index) {
                    final v = vouchers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['month'] as String,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                Text(
                                  'Paid on ${v['date']} • Ref: ${v['vch']}',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFmt.format(v['net']),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                            tooltip: 'View Payslip',
                            onPressed: () {
                              if (staff != null) {
                                _showPayslipModal(context, staff, v);
                              }
                            },
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
