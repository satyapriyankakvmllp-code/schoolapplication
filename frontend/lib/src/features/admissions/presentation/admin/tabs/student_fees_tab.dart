import 'package:flutter/material.dart';
import '../../../domain/student_admission_model.dart';

/// Fee invoice model representing a single fee schedule entry for a student.
class StudentFeeInvoiceItem {
  final String id;
  final String sl;
  final String feesType;
  final String dueDate;
  final String paymentType;
  final double amount;
  final double discountPercent;
  final double fine;
  final double paid;
  final double due;
  final String? paidDate;
  final String status; // 'Paid', 'Partial', 'Unpaid'

  const StudentFeeInvoiceItem({
    required this.id,
    required this.sl,
    required this.feesType,
    required this.dueDate,
    required this.paymentType,
    required this.amount,
    required this.discountPercent,
    required this.fine,
    required this.paid,
    required this.due,
    this.paidDate,
    required this.status,
  });

  StudentFeeInvoiceItem copyWith({
    String? id,
    String? sl,
    String? feesType,
    String? dueDate,
    String? paymentType,
    double? amount,
    double? discountPercent,
    double? fine,
    double? paid,
    double? due,
    String? paidDate,
    String? status,
  }) {
    return StudentFeeInvoiceItem(
      id: id ?? this.id,
      sl: sl ?? this.sl,
      feesType: feesType ?? this.feesType,
      dueDate: dueDate ?? this.dueDate,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      discountPercent: discountPercent ?? this.discountPercent,
      fine: fine ?? this.fine,
      paid: paid ?? this.paid,
      due: due ?? this.due,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
    );
  }
}

/// Fees Tab View for Student 360° Profile.
/// Displays 4 KPI gradient cards and student fee ledger table across all screen sizes.
/// Double-check buttons and Collect Fees modal removed per user instruction.
class StudentFeesTab extends StatefulWidget {
  final StudentAdmissionModel admission;
  final bool isDark;

  const StudentFeesTab({
    super.key,
    required this.admission,
    this.isDark = false,
  });

  @override
  State<StudentFeesTab> createState() => _StudentFeesTabState();
}

class _StudentFeesTabState extends State<StudentFeesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2025/2026';
  int _rowsPerPage = 10;

  final List<String> _academicYears = [
    'Year 2025/2026',
    'Year 2024/2025',
    'Year 2026/2027',
  ];

  late List<StudentFeeInvoiceItem> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = _buildInitialInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentFeeInvoiceItem> _buildInitialInvoices() {
    return [
      const StudentFeeInvoiceItem(
        id: 'inv-01',
        sl: '01',
        feesType: 'May Month Fees',
        dueDate: '05 May 2025',
        paymentType: 'Bank',
        amount: 700.50,
        discountPercent: 10,
        fine: 50.0,
        paid: 700.50,
        due: 0.0,
        paidDate: '12 May 2025',
        status: 'Paid',
      ),
      const StudentFeeInvoiceItem(
        id: 'inv-02',
        sl: '02',
        feesType: 'June Month Fees',
        dueDate: '05 Jun 2025',
        paymentType: 'Cash',
        amount: 680.00,
        discountPercent: 5,
        fine: 30.0,
        paid: 350.00,
        due: 330.00,
        paidDate: '09 Jun 2025',
        status: 'Partial',
      ),
      const StudentFeeInvoiceItem(
        id: 'inv-03',
        sl: '03',
        feesType: 'July Month Fees',
        dueDate: '05 Jul 2025',
        paymentType: 'Bank',
        amount: 700.00,
        discountPercent: 10,
        fine: 0.0,
        paid: 0.0,
        due: 700.00,
        paidDate: null,
        status: 'Unpaid',
      ),
      const StudentFeeInvoiceItem(
        id: 'inv-04',
        sl: '04',
        feesType: 'Term 1 Lab & Computer Fee',
        dueDate: '15 Aug 2025',
        paymentType: 'UPI',
        amount: 3500.00,
        discountPercent: 0,
        fine: 0.0,
        paid: 3500.00,
        due: 0.0,
        paidDate: '10 Aug 2025',
        status: 'Paid',
      ),
      const StudentFeeInvoiceItem(
        id: 'inv-05',
        sl: '05',
        feesType: 'Annual Library & Athletic Levy',
        dueDate: '01 Sep 2025',
        paymentType: 'Bank',
        amount: 2500.00,
        discountPercent: 0,
        fine: 120.0,
        paid: 2620.00,
        due: 0.0,
        paidDate: '05 Sep 2025',
        status: 'Paid',
      ),
      const StudentFeeInvoiceItem(
        id: 'inv-06',
        sl: '06',
        feesType: 'Term 2 Tuition Installment',
        dueDate: '15 Oct 2025',
        paymentType: 'Bank',
        amount: 2420.00,
        discountPercent: 5,
        fine: 0.0,
        paid: 450.00,
        due: 1970.00,
        paidDate: '12 Oct 2025',
        status: 'Partial',
      ),
    ];
  }

  double get _totalAmount => _invoices.fold(0, (sum, i) => sum + i.amount);
  double get _totalFine => _invoices.fold(0, (sum, i) => sum + i.fine);
  double get _totalPaid => _invoices.fold(0, (sum, i) => sum + i.paid);
  double get _totalDue => _invoices.fold(0, (sum, i) => sum + i.due);

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      final whole = amount.floor();
      final decimal = (amount - whole);
      final s = whole.toString();
      String formatted;
      if (s.length > 3) {
        final lastThree = s.substring(s.length - 3);
        final otherNumbers = s.substring(0, s.length - 3);
        final otherFormatted = otherNumbers.replaceAllMapped(
          RegExp(r'(\d)(?=(\d\d)+$)'),
          (Match m) => '${m[1]},',
        );
        formatted = '$otherFormatted,$lastThree';
      } else {
        formatted = s;
      }
      return decimal > 0 ? '₹$formatted.${(decimal * 100).round().toString().padLeft(2, '0')}' : '₹$formatted';
    }
    return amount % 1 == 0 ? '₹${amount.toInt()}' : '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final filtered = _invoices.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return item.feesType.toLowerCase().contains(q) ||
          item.paymentType.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                'Fees',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF109F83)),
                    const SizedBox(width: 5),
                    Text(
                      'Account Ledger',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4 KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;
              final isMobile = constraints.maxWidth < 600;

              final kpiCards = [
                _buildFeeKpiCard(
                  amount: _formatCurrency(_totalAmount),
                  label: 'Total Amount',
                  icon: Icons.account_balance_wallet_rounded,
                  iconBgColor: const Color(0xFF0284C7),
                  gradientColors: isDark
                      ? [const Color(0xFF0C4A6E).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFF0F9FF), Colors.white],
                  borderColor: isDark ? const Color(0xFF075985) : const Color(0xFFBAE6FD),
                ),
                _buildFeeKpiCard(
                  amount: _formatCurrency(_totalFine),
                  label: 'Total Fine',
                  icon: Icons.do_disturb_on_rounded,
                  iconBgColor: const Color(0xFFDC2626),
                  gradientColors: isDark
                      ? [const Color(0xFF7F1D1D).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFFEF2F2), Colors.white],
                  borderColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
                ),
                _buildFeeKpiCard(
                  amount: _formatCurrency(_totalPaid),
                  label: 'Total Paid',
                  icon: Icons.check_circle_rounded,
                  iconBgColor: const Color(0xFF16A34A),
                  gradientColors: isDark
                      ? [const Color(0xFF064E3B).withValues(alpha: 0.4), const Color(0xFF1E293B)]
                      : [const Color(0xFFF0FDF4), Colors.white],
                  borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
                ),
                _buildFeeKpiCard(
                  amount: _formatCurrency(_totalDue),
                  label: 'Total Due',
                  icon: Icons.pending_actions_rounded,
                  iconBgColor: const Color(0xFFEA580C),
                  gradientColors: isDark
                      ? [const Color(0xFF7C2D12).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFFFF7ED), Colors.white],
                  borderColor: isDark ? const Color(0xFF9A3412) : const Color(0xFFFED7AA),
                ),
              ];

              if (isMobile) {
                return Column(
                  children: kpiCards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(width: double.infinity, child: card),
                          ))
                      .toList(),
                );
              }

              if (isNarrow) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kpiCards
                      .map((card) => SizedBox(
                            width: (constraints.maxWidth - 24) / 2,
                            child: card,
                          ))
                      .toList(),
                );
              }

              return Row(
                children: kpiCards
                    .map((card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: card,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Control Bar: Search, Year dropdown, Export, Rows per page
          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 980;

              final searchBox = SizedBox(
                width: isWrap ? double.infinity : 260,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                    ),
                  ),
                ),
              );

              final rightControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year Dropdown
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Export Button
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exporting invoices as $val...'),
                          backgroundColor: const Color(0xFF109F83),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                      PopupMenuItem(value: 'Excel', child: Text('Export Excel / CSV')),
                    ],
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_upload_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Rows per page
                  Text(
                    'Rows per page:',
                    style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _rowsPerPage,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _rowsPerPage = val);
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isWrap) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchBox,
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: rightControls,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  searchBox,
                  rightControls,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Fees Data Table - Covers full screen width with LayoutBuilder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(
                builder: (context, tableConstraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        headingRowHeight: 46,
                        horizontalMargin: 16,
                        columnSpacing: 22,
                        columns: [
                          DataColumn(label: _buildSortHeader('S.L', isDark)),
                          DataColumn(label: _buildSortHeader('Fees Type', isDark)),
                          DataColumn(label: _buildSortHeader('Due Date', isDark)),
                          DataColumn(label: _buildSortHeader('Payment Type', isDark)),
                          DataColumn(label: _buildSortHeader('Amount', isDark)),
                          DataColumn(label: _buildSortHeader('Discount', isDark)),
                          DataColumn(label: _buildSortHeader('Fine', isDark)),
                          DataColumn(label: _buildSortHeader('Paid', isDark)),
                          DataColumn(label: _buildSortHeader('Due', isDark)),
                          DataColumn(label: _buildSortHeader('Paid Date', isDark)),
                          DataColumn(label: _buildSortHeader('Status', isDark)),
                        ],
                        rows: filtered.take(_rowsPerPage).map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.sl,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.feesType,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.dueDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.paymentType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatCurrency(item.amount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.discountPercent > 0 ? '${item.discountPercent.toInt()}%' : '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.fine > 0 ? _formatCurrency(item.fine) : '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: item.fine > 0 ? FontWeight.w600 : FontWeight.normal,
                                    color: item.fine > 0 ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatCurrency(item.paid),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatCurrency(item.due),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: item.due > 0 ? const Color(0xFFEA580C) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.paidDate ?? '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              DataCell(
                                _buildStatusPill(item.status),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeKpiCard({
    required String amount,
    required String label,
    required IconData icon,
    required Color iconBgColor,
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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

  Widget _buildSortHeader(String title, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.unfold_more, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color text;

    switch (status) {
      case 'Paid':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case 'Partial':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
      case 'Unpaid':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
