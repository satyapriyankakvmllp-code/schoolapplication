import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../domain/staff_member_model.dart';
import '../../../domain/staff_menu_item.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../../authentication/application/auth_controller.dart';
import '../../../../authentication/domain/user_model.dart';
import '../staff_accounts_ledger_screen.dart';

class StaffPayrollInvoice {
  final String sl;
  final String invoiceId;
  final String salaryFor;
  final String date;
  final double netSalary;
  final String paymentMethod;
  final String status; // 'Paid', 'Pending', 'Failed'

  const StaffPayrollInvoice({
    required this.sl,
    required this.invoiceId,
    required this.salaryFor,
    required this.date,
    required this.netSalary,
    required this.paymentMethod,
    required this.status,
  });
}

/// Tab 5: Payroll (matching Screenshot 5)
/// Features 3 KPI cards (Total Net Salary, Gross Salary, Total Deduction),
/// interactive invoice table with Indian Rupee (₹) format, and "View Payslip" voucher modal.
/// Super Admin can view unmasked bank details and directly disburse salary.
class StaffPayrollTab extends ConsumerStatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffPayrollTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  ConsumerState<StaffPayrollTab> createState() => _StaffPayrollTabState();
}

class _StaffPayrollTabState extends ConsumerState<StaffPayrollTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2026/2027';
  int _rowsPerPage = 10;
  int _currentPage = 1;

  final List<String> _academicYears = [
    'Year 2026/2027',
    'Year 2025/2026',
    'Year 2024/2025',
  ];

  late List<StaffPayrollInvoice> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = _buildInvoices();
    _loadPayroll();
  }

  @override
  void didUpdateWidget(covariant StaffPayrollTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.id != widget.staff.id) {
      _loadPayroll();
    }
  }

  Future<void> _loadPayroll() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/finance/staff_payroll.json',
        storageKey: 'edupulse_staff_payroll_records',
      );
      if (records.isNotEmpty) {
        final staffRecords = records.where((r) => r['staff_id'] == widget.staff.id).toList();
        final effectiveRecords = staffRecords.isNotEmpty ? staffRecords : records;
        if (mounted) {
          setState(() {
            _invoices = effectiveRecords.map((r) => StaffPayrollInvoice(
              sl: (r['sl'] ?? '').toString(),
              invoiceId: (r['invoice_id'] ?? '').toString(),
              salaryFor: (r['salary_for'] ?? '').toString(),
              date: (r['date'] ?? '').toString(),
              netSalary: (r['net_salary'] as num?)?.toDouble() ?? widget.staff.compensation.basicSalary,
              paymentMethod: (r['payment_method'] ?? 'Bank Transfer').toString(),
              status: (r['status'] ?? 'Paid').toString(),
            )).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDisburseSalaryDialog() {
    final basic = widget.staff.compensation.basicSalary;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Disburse Monthly Salary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${widget.staff.fullName} (${widget.staff.id})'),
            const SizedBox(height: 4),
            Text('Designation: ${widget.staff.designation} • ${widget.staff.department}'),
            const SizedBox(height: 4),
            Text('Net Payable: ${currencyFmt.format(basic)}'),
            const SizedBox(height: 4),
            Text('Transfer Destination: ${widget.staff.compensation.bankName} - ${widget.staff.compensation.accountNumber}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct NEFT bank transfer gateway authorization.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _disburseSalary();
            },
            child: const Text('Confirm Disbursement'),
          ),
        ],
      ),
    );
  }

  Future<void> _disburseSalary() async {
    final now = DateTime.now();
    final newInv = StaffPayrollInvoice(
      sl: '01',
      invoiceId: 'INV-2026-OCT-${now.millisecondsSinceEpoch.toString().substring(8)}',
      salaryFor: 'October 2026',
      date: '${now.day} Oct ${now.year}',
      netSalary: widget.staff.compensation.basicSalary,
      paymentMethod: 'Bank Transfer (NEFT)',
      status: 'Paid',
    );

    setState(() {
      _invoices.insert(0, newInv);
    });

    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/finance/staff_payroll.json',
        storageKey: 'edupulse_staff_payroll_records',
      );
      final rawInv = {
        'sl': newInv.sl,
        'invoice_id': newInv.invoiceId,
        'salary_for': newInv.salaryFor,
        'date': newInv.date,
        'net_salary': newInv.netSalary,
        'payment_method': newInv.paymentMethod,
        'status': newInv.status,
        'staff_id': widget.staff.id,
      };
      records.insert(0, rawInv);
      await DynamicDataClient.instance.syncAll(
        assetPath: 'assets/data/finance/staff_payroll.json',
        storageKey: 'edupulse_staff_payroll_records',
        items: records,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salary for October 2026 disbursed successfully to ${widget.staff.fullName}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  List<StaffPayrollInvoice> _buildInvoices() {
    final basic = widget.staff.compensation.basicSalary;
    final months = [
      {'m': 'Jan 2026', 'd': '07 Jan 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52365'},
      {'m': 'Feb 2026', 'd': '08 Feb 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52366'},
      {'m': 'Mar 2026', 'd': '07 Mar 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52367'},
      {'m': 'Apr 2026', 'd': '06 Apr 2026', 'st': 'Paid', 'pm': 'Online / NEFT', 'id': 'AD52368'},
      {'m': 'May 2026', 'd': '07 May 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52369'},
      {'m': 'Jun 2026', 'd': '06 Jun 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52370'},
      {'m': 'Jul 2026', 'd': '08 Jul 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52371'},
      {'m': 'Aug 2026', 'd': '07 Aug 2026', 'st': 'Paid', 'pm': 'Online / NEFT', 'id': 'AD52372'},
      {'m': 'Sep 2026', 'd': '06 Sep 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52373'},
      {'m': 'Oct 2026', 'd': '07 Oct 2026', 'st': 'Paid', 'pm': 'Bank Transfer', 'id': 'AD52374'},
      {'m': 'Nov 2026', 'd': '07 Nov 2026', 'st': 'Pending', 'pm': 'Bank Transfer', 'id': 'AD52375'},
      {'m': 'Dec 2026', 'd': '07 Dec 2026', 'st': 'Pending', 'pm': 'Bank Transfer', 'id': 'AD52376'},
    ];

    return List.generate(months.length, (i) {
      final item = months[i];
      final sl = (i + 1).toString().padLeft(2, '0');
      return StaffPayrollInvoice(
        sl: sl,
        invoiceId: item['id']!,
        salaryFor: item['m']!,
        date: item['d']!,
        netSalary: basic,
        paymentMethod: item['pm']!,
        status: item['st']!,
      );
    });
  }

  void _showPayslipDialog(StaffPayrollInvoice invoice) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final basic = invoice.netSalary;
    final hra = (basic * 0.20).roundToDouble();
    final da = (basic * 0.10).roundToDouble();
    final specialAllowance = (basic * 0.05).roundToDouble();
    final gross = basic + hra + da + specialAllowance;

    final epf = (basic * 0.12).roundToDouble();
    const pt = 200.0;
    final tds = (basic * 0.05).roundToDouble();
    final totalDeductions = epf + pt + tds;
    final netPay = gross - totalDeductions;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF109F83).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school, color: Color(0xFF109F83), size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'EDUPULSE GLOBAL ACADEMY',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            Text(
                              'Faculty Monthly Salary Slip / Voucher',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Invoice & Employee Details Grid
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _buildSlipMeta('Invoice ID', invoice.invoiceId),
                    _buildSlipMeta('Salary For', invoice.salaryFor),
                    _buildSlipMeta('Disbursed Date', invoice.date),
                    _buildSlipMeta('Employee ID', widget.staff.id),
                    _buildSlipMeta('Employee Name', widget.staff.fullName),
                    _buildSlipMeta('Designation', widget.staff.designation),
                    _buildSlipMeta('Department', widget.staff.department),
                    _buildSlipMeta('Bank Name', widget.staff.compensation.bankName),
                    _buildSlipMeta(
                      'Account No',
                      isSuperAdmin(ref.watch(currentLoggedInStaffProvider)?.effectiveRole)
                          ? widget.staff.compensation.accountNumber
                          : widget.staff.compensation.maskedAccountNumber,
                    ),
                    _buildSlipMeta(
                      'PAN Number',
                      isSuperAdmin(ref.watch(currentLoggedInStaffProvider)?.effectiveRole)
                          ? widget.staff.compensation.panNumber
                          : widget.staff.compensation.maskedPanNumber,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Earnings & Deductions Breakdown
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('EARNINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            const SizedBox(height: 8),
                            _buildBreakdownRow('Basic Pay', currencyFmt.format(basic)),
                            _buildBreakdownRow('HRA (20%)', currencyFmt.format(hra)),
                            _buildBreakdownRow('DA (10%)', currencyFmt.format(da)),
                            _buildBreakdownRow('Special Allowance', currencyFmt.format(specialAllowance)),
                            const Divider(height: 16),
                            _buildBreakdownRow('Gross Earnings', currencyFmt.format(gross), isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Deductions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DEDUCTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                            const SizedBox(height: 8),
                            _buildBreakdownRow('EPF Contribution', currencyFmt.format(epf)),
                            _buildBreakdownRow('Professional Tax', currencyFmt.format(pt)),
                            _buildBreakdownRow('TDS Deduction', currencyFmt.format(tds)),
                            const SizedBox(height: 14),
                            const Divider(height: 16),
                            _buildBreakdownRow('Total Deductions', currencyFmt.format(totalDeductions), isBold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Net Payable Highlight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF109F83).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF109F83)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NET SALARY PAYABLE:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF109F83)),
                      ),
                      Text(
                        currencyFmt.format(netPay),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF109F83)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Print Payslip'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Printing salary slip for ${invoice.salaryFor}...'),
                            backgroundColor: const Color(0xFF109F83),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF109F83),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloaded PDF voucher for ${invoice.invoiceId}.'),
                            backgroundColor: const Color(0xFF109F83),
                          ),
                        );
                      },
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

  Widget _buildSlipMeta(String label, String val) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final basic = widget.staff.compensation.basicSalary;
    final annualNet = basic * 10;
    final annualGross = (basic * 1.35) * 10;
    final annualDeduction = (basic * 0.15) * 10;

    final filtered = _invoices.where((inv) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = inv.invoiceId.toLowerCase().contains(q);
        final matchesMonth = inv.salaryFor.toLowerCase().contains(q);
        final matchesStatus = inv.status.toLowerCase().contains(q);
        if (!matchesId && !matchesMonth && !matchesStatus) return false;
      }
      return true;
    }).toList();

    final totalEntries = filtered.length;
    final totalPages = (totalEntries / _rowsPerPage).ceil().clamp(1, 999);
    final startIdx = ((_currentPage - 1) * _rowsPerPage).clamp(0, totalEntries);
    final endIdx = (startIdx + _rowsPerPage).clamp(0, totalEntries);
    final pageRecords = filtered.sublist(startIdx, endIdx);

    // Permission check: Masked for Principal, Parent, Student to preserve faculty salary confidentiality
    final currentStaff = ref.watch(currentLoggedInStaffProvider);
    final activeRole = ref.watch(activeUserRoleProvider);
    final currentRole = currentStaff?.effectiveRole.toLowerCase() ?? '';
    final isRestrictedRole = currentRole == 'principal' ||
        activeRole == UserRole.parent ||
        activeRole == UserRole.student;
    final canViewFinancials = !isRestrictedRole;

    if (!canViewFinancials) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: widget.isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            Text(
              'Confidential Compensation & Payroll Record',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                'Faculty basic salary, bank account, and tax details are restricted to School Management (Admin) and Accounts personnel under institutional privacy guidelines.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 KPI Cards: Total Net Salary, Gross Salary, Total Deduction
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            if (isNarrow) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPayrollKpi(currencyFmt.format(annualNet), 'Total Net Salary', Icons.account_balance_wallet_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor, width: 220),
                  _buildPayrollKpi(currencyFmt.format(annualGross), 'Total Gross Salary', Icons.savings_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor, width: 220),
                  _buildPayrollKpi(currencyFmt.format(annualDeduction), 'Total Deduction', Icons.pie_chart_outline, const Color(0xFFDC2626), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor, width: 220),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: _buildPayrollKpi(currencyFmt.format(annualNet), 'Total Net Salary', Icons.account_balance_wallet_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 14),
                Expanded(child: _buildPayrollKpi(currencyFmt.format(annualGross), 'Total Gross Salary', Icons.savings_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 14),
                Expanded(child: _buildPayrollKpi(currencyFmt.format(annualDeduction), 'Total Deduction', Icons.pie_chart_outline, const Color(0xFFDC2626), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor)),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Payroll Invoices Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),

              // Search, Filters & Rows per page
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 750;

                  final searchField = SizedBox(
                    width: isNarrow ? double.infinity : 240,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      }),
                      style: TextStyle(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, size: 18, color: subColor),
                        hintText: 'Search...',
                        hintStyle: TextStyle(fontSize: 13, color: subColor),
                        filled: true,
                        fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF109F83)),
                        ),
                      ),
                    ),
                  );

                  final controls = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Year Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedYear,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            dropdownColor: cardBg,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                            items: _academicYears.map((y) {
                              return DropdownMenuItem(value: y, child: Text(y));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedYear = v);
                            },
                          ),
                        ),
                      ),
                      // Disburse Salary Button for Super Admin
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payments_outlined, size: 15),
                        label: const Text('Disburse Salary'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: _showDisburseSalaryDialog,
                      ),
                      // Open in Accounts Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.account_balance_outlined, size: 15),
                        label: const Text('Open in Accounts'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF109F83),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StaffAccountsLedgerScreen(
                                staff: widget.staff,
                                isDark: widget.isDark,
                              ),
                            ),
                          );
                        },
                      ),
                      // Export Button
                      PopupMenuButton<String>(
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                          PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                        ],
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exporting payroll data as ${val.toUpperCase()}...'),
                              backgroundColor: const Color(0xFF109F83),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_outlined, size: 16, color: subColor),
                              const SizedBox(width: 4),
                              Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 16, color: subColor),
                            ],
                          ),
                        ),
                      ),
                      // Rows per page
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Rows per page: ', style: TextStyle(fontSize: 12, color: subColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _rowsPerPage,
                                isDense: true,
                                dropdownColor: cardBg,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                items: [5, 10, 20].map((count) {
                                  return DropdownMenuItem(value: count, child: Text('$count'));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _rowsPerPage = v;
                                      _currentPage = 1;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      searchField,
                      controls,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Payroll Table (Covers full screen width with LayoutBuilder)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double tableWidth = constraints.maxWidth > 980 ? constraints.maxWidth : 980;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 45, child: Text('S.L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Invoice ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Salary For', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Net Salary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            Expanded(flex: 2, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Invoices Rows
                      ...pageRecords.map((inv) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 45, child: Text(inv.sl, style: TextStyle(fontSize: 12, color: subColor))),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  inv.invoiceId,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(inv.salaryFor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(inv.date, style: TextStyle(fontSize: 12, color: textColor)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFmt.format(inv.netSalary),
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(inv.paymentMethod, style: TextStyle(fontSize: 12, color: textColor)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildStatusBadge(inv.status),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      side: BorderSide(color: borderColor),
                                    ),
                                    onPressed: () => _showPayslipDialog(inv),
                                    child: Text(
                                      'View Payslip',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
            const SizedBox(height: 16),

              // Pagination Info & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${totalEntries == 0 ? 0 : startIdx + 1} to $endIdx of $totalEntries entries',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_currentPage',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollKpi(
    String amount,
    String label,
    IconData icon,
    Color iconColor,
    Color iconBg,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor, {
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFDCFCE7);
    Color fg = const Color(0xFF16A34A);

    if (status == 'Pending') {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFEA580C);
    } else if (status == 'Failed') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    if (widget.isDark) {
      if (status == 'Paid') bg = const Color(0xFF14532D);
      if (status == 'Pending') bg = const Color(0xFF7C2D12);
      if (status == 'Failed') bg = const Color(0xFF7F1D1D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
