import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../application/staff_auth_controller.dart';
import '../../domain/staff_member_model.dart';
import '../../domain/staff_menu_item.dart';
import 'staff_list_screen.dart';

/// Screen representing the official School Accounts & Salary Disbursement Ledger
/// for a specific staff member.
/// Navigated to from StaffPayrollTab via 'Open in Accounts'.
class StaffAccountsLedgerScreen extends ConsumerStatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onExitToGateway;

  const StaffAccountsLedgerScreen({
    super.key,
    required this.staff,
    required this.isDark,
    this.onNavigate,
    this.onExitToGateway,
  });

  @override
  ConsumerState<StaffAccountsLedgerScreen> createState() => _StaffAccountsLedgerScreenState();
}

class _StaffAccountsLedgerScreenState extends ConsumerState<StaffAccountsLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2026/2027';
  bool _isAccountMasked = true;

  late List<Map<String, dynamic>> _ledgerEntries;

  @override
  void initState() {
    super.initState();
    _ledgerEntries = _buildInitialLedger(widget.staff);
    final currentRole = ref.read(currentLoggedInStaffProvider)?.effectiveRole;
    if (isSuperAdmin(currentRole)) {
      _isAccountMasked = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildInitialLedger([StaffMemberModel? staff]) {
    final staffToUse = staff ?? widget.staff;
    final basic = staffToUse.compensation.basicSalary;
    final gross = (basic * 1.35).roundToDouble();
    final deductions = (basic * 0.15).roundToDouble();
    final net = gross - deductions;

    final cycles = [
      {'vch': 'ACC-VCH-2026-08', 'month': 'August 2026', 'date': '07 Aug 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892110294'},
      {'vch': 'ACC-VCH-2026-07', 'month': 'July 2026', 'date': '08 Jul 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892110188'},
      {'vch': 'ACC-VCH-2026-06', 'month': 'June 2026', 'date': '07 Jun 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892110052'},
      {'vch': 'ACC-VCH-2026-05', 'month': 'May 2026', 'date': '06 May 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892109912'},
      {'vch': 'ACC-VCH-2026-04', 'month': 'April 2026', 'date': '07 Apr 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892109804'},
      {'vch': 'ACC-VCH-2026-03', 'month': 'March 2026', 'date': '08 Mar 2026', 'mode': 'Treasury Transfer (RTGS)', 'status': 'Disbursed', 'ref': 'RTGS4401928371'},
      {'vch': 'ACC-VCH-2026-02', 'month': 'February 2026', 'date': '07 Feb 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892109721'},
      {'vch': 'ACC-VCH-2026-01', 'month': 'January 2026', 'date': '08 Jan 2026', 'mode': 'Direct Bank Transfer (NEFT)', 'status': 'Disbursed', 'ref': 'NEFT8892109605'},
      {'vch': 'ACC-VCH-2026-09', 'month': 'September 2026', 'date': 'Pending Clearance', 'mode': 'Bank Transfer (NEFT)', 'status': 'Pending Clearance', 'ref': 'Awaiting Principal Approval'},
    ];

    return cycles.map((c) {
      return {
        'vch': c['vch'],
        'month': c['month'],
        'date': c['date'],
        'gross': gross,
        'deductions': deductions,
        'net': net,
        'mode': c['mode'],
        'status': c['status'],
        'ref': c['ref'],
      };
    }).toList();
  }

  void _showVoucherModal(Map<String, dynamic> entry, StaffMemberModel currentStaff) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF109F83).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF109F83)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Disbursement Voucher ${entry['vch']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${entry['month']} Salary Clearing', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Beneficiary Faculty', currentStaff.fullName),
                    _buildModalRow('Staff ID', currentStaff.id),
                    _buildModalRow('Bank Name', currentStaff.compensation.bankName),
                    _buildModalRow('Account Number', currentStaff.compensation.accountNumber),
                    _buildModalRow('IFSC Code', currentStaff.compensation.ifscCode),
                    _buildModalRow('PAN Card', currentStaff.compensation.panNumber),
                    _buildModalRow('EPF / UAN Reg', currentStaff.compensation.epfUan ?? 'MH/BAN/0048192/000'),
                    _buildModalRow('Transaction Ref', entry['ref'].toString()),
                    _buildModalRow('Clearing Date', entry['date'].toString()),
                    const Divider(height: 16),
                    _buildModalRow('Gross Compensation', currencyFmt.format(entry['gross'])),
                    _buildModalRow('Statutory Deductions (EPF/TDS)', '- ${currencyFmt.format(entry['deductions'])}', isDeduction: true),
                    const Divider(height: 16),
                    _buildModalRow('Net Disbursed Amount', currencyFmt.format(entry['net']), isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print Voucher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Printing Voucher ${entry['vch']}...'),
                  backgroundColor: const Color(0xFF109F83),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(StaffMemberModel currentStaff) {
    final bankController = TextEditingController(text: currentStaff.compensation.bankName);
    final accountController = TextEditingController(text: currentStaff.compensation.accountNumber);
    final ifscController = TextEditingController(text: currentStaff.compensation.ifscCode);
    final panController = TextEditingController(text: currentStaff.compensation.panNumber);
    final epfController = TextEditingController(
      text: currentStaff.compensation.epfUan ?? 'MH/BAN/0048192/000',
    );
    final basicController = TextEditingController(
      text: currentStaff.compensation.basicSalary.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF109F83).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, size: 20, color: Color(0xFF109F83)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Bank & Salary Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Staff: ${currentStaff.fullName} (${currentStaff.id})',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: bankController,
                    label: 'Bank Name',
                    icon: Icons.account_balance_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bank name required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: accountController,
                    label: 'Account Number',
                    icon: Icons.credit_card_outlined,
                    isNumeric: true,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Account number required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogTextField(
                          controller: ifscController,
                          label: 'IFSC Code',
                          icon: Icons.numbers_outlined,
                          isUppercase: true,
                          validator: (v) => v == null || v.trim().isEmpty ? 'IFSC required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogTextField(
                          controller: panController,
                          label: 'PAN Number',
                          icon: Icons.badge_outlined,
                          isUppercase: true,
                          validator: (v) => v == null || v.trim().isEmpty ? 'PAN required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogTextField(
                          controller: epfController,
                          label: 'EPF / UAN Registration',
                          icon: Icons.assured_workload_outlined,
                          isUppercase: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogTextField(
                          controller: basicController,
                          label: 'Monthly Basic (₹)',
                          icon: Icons.currency_rupee,
                          isNumeric: true,
                          validator: (v) => v == null || double.tryParse(v.trim()) == null
                              ? 'Valid salary required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newBasic = double.tryParse(basicController.text.trim()) ??
                    currentStaff.compensation.basicSalary;
                final updatedCompensation = currentStaff.compensation.copyWith(
                  bankName: bankController.text.trim(),
                  accountNumber: accountController.text.trim(),
                  ifscCode: ifscController.text.trim().toUpperCase(),
                  panNumber: panController.text.trim().toUpperCase(),
                  epfUan: epfController.text.trim().toUpperCase(),
                  basicSalary: newBasic,
                );
                final updatedStaff = currentStaff.copyWith(compensation: updatedCompensation);

                await ref.read(staffListProvider.notifier).saveStaff(updatedStaff);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {
                    _ledgerEntries = _buildInitialLedger(updatedStaff);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bank & account details updated for ${currentStaff.fullName}!'),
                      backgroundColor: const Color(0xFF109F83),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    bool isUppercase = false,
    String? Function(String?)? validator,
  }) {
    final isDark = widget.isDark;
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      textCapitalization: isUppercase ? TextCapitalization.characters : TextCapitalization.none,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFF109F83)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF109F83), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBold = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDeduction ? const Color(0xFFEF4444) : (isBold ? const Color(0xFF109F83) : (widget.isDark ? Colors.white : const Color(0xFF0F172A))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
    final currentStaff = staffList.firstWhere(
      (s) => s.id == widget.staff.id,
      orElse: () => widget.staff,
    );

    final basic = currentStaff.compensation.basicSalary;
    final annualGross = (basic * 1.35) * 12;
    final annualDeduction = (basic * 0.15) * 12;
    final annualNet = (basic * 1.20) * 12;

    final filtered = _ledgerEntries.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchVch = e['vch'].toString().toLowerCase().contains(q);
        final matchMonth = e['month'].toString().toLowerCase().contains(q);
        final matchStatus = e['status'].toString().toLowerCase().contains(q);
        if (!matchVch && !matchMonth && !matchStatus) return false;
      }
      return true;
    }).toList();

    return EdupluseScaffold(
      activePage: EdupluseNavPage.accounts,
      isDark: isDark,
      onExitToGateway: widget.onExitToGateway,
      onNavigate: (page) {
        if (widget.onNavigate != null) {
          Navigator.of(context).pop();
          widget.onNavigate!(page);
        } else {
          Navigator.of(context).pop();
        }
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumb Bar
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => StaffListScreen(isDark: isDark),
                      ),
                    );
                  },
                  child: Text(
                    'Staff Directory',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: subColor),
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: subColor),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    currentStaff.fullName,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: subColor),
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: subColor),
                const Text(
                  'Accounts & Financial Ledger',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF109F83)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Page Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 14,
                children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF109F83).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_rounded, size: 24, color: Color(0xFF109F83)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Accounts & Salary Disbursement Ledger',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF109F83).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Official Registry',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Central Financial Management & Bank Transfer Clearance Registry',
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back to Staff Profile'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: const Text('Print Ledger Statement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF109F83),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Printing complete financial ledger statement for ${currentStaff.fullName}...'),
                                  backgroundColor: const Color(0xFF109F83),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 20),

            // 3. Staff & Official Bank Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Action Header
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Faculty Financial & Bank Clearance Profile',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Update Account Details', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF109F83),
                              side: const BorderSide(color: Color(0xFF109F83)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showEditAccountDialog(currentStaff),
                          ),
                          IconButton(
                            tooltip: _isAccountMasked ? 'Reveal Account Number' : 'Mask Account Number',
                            icon: Icon(
                              _isAccountMasked ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF109F83),
                            ),
                            onPressed: () => setState(() => _isAccountMasked = !_isAccountMasked),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Profile + Bank Details Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 800;

                      final staffSummary = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                              backgroundImage: currentStaff.photoUrl != null ? NetworkImage(currentStaff.photoUrl!) : null,
                              child: currentStaff.photoUrl == null
                                  ? Text(
                                      currentStaff.fullName.isNotEmpty ? currentStaff.fullName[0] : 'S',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentStaff.fullName,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${currentStaff.id} • ${currentStaff.designation}',
                                    style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dept: ${currentStaff.department} • ${currentStaff.employmentType.label}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF109F83), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      final bankDetails = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildBankRow('Bank Name', currentStaff.compensation.bankName, textColor, subColor),
                            _buildBankRow(
                              'A/C Number',
                              _isAccountMasked
                                  ? currentStaff.compensation.maskedAccountNumber
                                  : currentStaff.compensation.accountNumber,
                              textColor,
                              subColor,
                              isMonospace: true,
                            ),
                            _buildBankRow('IFSC Code', currentStaff.compensation.ifscCode, textColor, subColor, isMonospace: true),
                            _buildBankRow('PAN Card', currentStaff.compensation.panNumber, textColor, subColor, isMonospace: true),
                            _buildBankRow(
                              'EPF / PF Reg',
                              (currentStaff.compensation.epfUan != null && currentStaff.compensation.epfUan!.isNotEmpty)
                                  ? currentStaff.compensation.epfUan!
                                  : 'MH/BAN/0048192/000',
                              textColor,
                              subColor,
                              isMonospace: true,
                            ),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            staffSummary,
                            const SizedBox(height: 12),
                            bankDetails,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: staffSummary),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: bankDetails),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Financial KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                if (isNarrow) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildAccountsKpi(currencyFmt.format(basic), 'Monthly Basic Pay', Icons.payments_outlined, const Color(0xFF109F83), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor, width: 220),
                      _buildAccountsKpi(currencyFmt.format(annualGross), 'Annualized Gross Pay', Icons.savings_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor, width: 220),
                      _buildAccountsKpi(currencyFmt.format(annualDeduction), 'Annual Deductions (TDS/PF)', Icons.pie_chart_outline, const Color(0xFFEF4444), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor, width: 220),
                      _buildAccountsKpi(currencyFmt.format(annualNet), 'Total Disbursed to Date', Icons.verified_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor, width: 220),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _buildAccountsKpi(currencyFmt.format(basic), 'Monthly Basic Pay', Icons.payments_outlined, const Color(0xFF109F83), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAccountsKpi(currencyFmt.format(annualGross), 'Annualized Gross Pay', Icons.savings_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAccountsKpi(currencyFmt.format(annualDeduction), 'Annual Deductions (TDS/PF)', Icons.pie_chart_outline, const Color(0xFFEF4444), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAccountsKpi(currencyFmt.format(annualNet), 'Total Disbursed to Date', Icons.verified_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 5. Official Salary Disbursement Registry Table
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Filter Toolbar
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Clearing & Bank Transfer Registry',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Complete chronological transaction audit log of all payroll disbursements',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Search Box
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(fontSize: 12.5, color: textColor),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, size: 16, color: subColor),
                                hintText: 'Search voucher...',
                                hintStyle: TextStyle(fontSize: 12, color: subColor),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          // Year Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedYear,
                                dropdownColor: cardBg,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                items: const [
                                  DropdownMenuItem(value: 'Year 2026/2027', child: Text('Year 2026/2027')),
                                  DropdownMenuItem(value: 'Year 2025/2026', child: Text('Year 2025/2026')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedYear = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data Table
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const double minTableWidth = 980;
                      final double tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: tableWidth),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            ),
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 52,
                            headingRowHeight: 42,
                            horizontalMargin: 16,
                            columnSpacing: 18,
                            columns: [
                              DataColumn(label: Text('Voucher ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Salary Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Clearing Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Gross Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Deductions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Net Disbursed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Payment Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Clearing Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                              DataColumn(label: Text('Audit Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor))),
                            ],
                            rows: filtered.map((entry) {
                              final isPending = entry['status'] == 'Pending Clearance';

                              return DataRow(
                                cells: [
                                  DataCell(Text(entry['vch'].toString(), style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                                  DataCell(Text(entry['month'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor))),
                                  DataCell(Text(entry['date'].toString(), style: TextStyle(fontSize: 11.5, color: subColor))),
                                  DataCell(Text(currencyFmt.format(entry['gross']), style: TextStyle(fontSize: 12, color: textColor))),
                                  DataCell(Text('- ${currencyFmt.format(entry['deductions'])}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)))),
                                  DataCell(Text(currencyFmt.format(entry['net']), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF109F83)))),
                                  DataCell(Text(entry['mode'].toString(), style: TextStyle(fontSize: 11.5, color: subColor))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        entry['status'].toString(),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isPending ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _showVoucherModal(entry, currentStaff),
                                          child: const Text('View Voucher', style: TextStyle(fontSize: 11)),
                                        ),
                                        if (isPending) ...[
                                          const SizedBox(width: 6),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF109F83),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                entry['status'] = 'Disbursed';
                                                entry['date'] = '19 Oct 2026';
                                                entry['ref'] = 'NEFT8892110355';
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Disbursement cleared for ${entry['month']}!'),
                                                  backgroundColor: const Color(0xFF109F83),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            child: const Text('Clear / Pay', style: TextStyle(fontSize: 11)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankRow(String label, String value, Color textColor, Color subColor, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: subColor)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsKpi(
    String value,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
        ],
      ),
    );
  }
}
