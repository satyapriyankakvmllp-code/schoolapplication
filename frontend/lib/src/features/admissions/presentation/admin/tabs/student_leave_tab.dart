import 'package:flutter/material.dart';
import '../../../domain/student_admission_model.dart';

/// Leave Record model for student leave applications.
class StudentLeaveItem {
  final String id;
  final String sl;
  final String leaveType;
  final String dateRange;
  final int durationDays;
  final String applyDate;
  final String status; // 'Approved', 'Pending', 'Rejected'
  final String? reason;

  const StudentLeaveItem({
    required this.id,
    required this.sl,
    required this.leaveType,
    required this.dateRange,
    required this.durationDays,
    required this.applyDate,
    required this.status,
    this.reason,
  });

  StudentLeaveItem copyWith({
    String? id,
    String? sl,
    String? leaveType,
    String? dateRange,
    int? durationDays,
    String? applyDate,
    String? status,
    String? reason,
  }) {
    return StudentLeaveItem(
      id: id ?? this.id,
      sl: sl ?? this.sl,
      leaveType: leaveType ?? this.leaveType,
      dateRange: dateRange ?? this.dateRange,
      durationDays: durationDays ?? this.durationDays,
      applyDate: applyDate ?? this.applyDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }
}

/// Leave Tab View for Student 360° Profile.
/// Allows administrators to view student leave requests, with inline Approve & Reject actions.
/// Does not allow admin to apply leave directly (students apply on their own portal).
class StudentLeaveTab extends StatefulWidget {
  final StudentAdmissionModel admission;
  final bool isDark;

  const StudentLeaveTab({
    super.key,
    required this.admission,
    this.isDark = false,
  });

  @override
  State<StudentLeaveTab> createState() => _StudentLeaveTabState();
}

class _StudentLeaveTabState extends State<StudentLeaveTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedYear = 'Year 2026/2027';
  int _rowsPerPage = 10;

  final List<String> _academicYears = [
    'Year 2026/2027',
    'Year 2025/2026',
    'Year 2024/2025',
  ];

  late List<StudentLeaveItem> _leaves;

  @override
  void initState() {
    super.initState();
    _leaves = _buildInitialLeaves();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentLeaveItem> _buildInitialLeaves() {
    return [
      const StudentLeaveItem(
        id: 'lv-01',
        sl: '01',
        leaveType: 'Medical Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 1,
        applyDate: '07 May 2025',
        status: 'Approved',
        reason: 'Viral fever rest recommended by family physician.',
      ),
      const StudentLeaveItem(
        id: 'lv-02',
        sl: '02',
        leaveType: 'Special Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 3,
        applyDate: '07 May 2025',
        status: 'Pending',
        reason: 'National inter-school science championship representation.',
      ),
      const StudentLeaveItem(
        id: 'lv-03',
        sl: '03',
        leaveType: 'Medical Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 5,
        applyDate: '07 May 2025',
        status: 'Approved',
        reason: 'Orthopedic recovery and physio rest.',
      ),
      const StudentLeaveItem(
        id: 'lv-04',
        sl: '04',
        leaveType: 'Casual Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 6,
        applyDate: '07 May 2025',
        status: 'Pending',
        reason: 'Attending elder sibling wedding in native town.',
      ),
      const StudentLeaveItem(
        id: 'lv-05',
        sl: '05',
        leaveType: 'Medical Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 1,
        applyDate: '07 May 2025',
        status: 'Approved',
        reason: 'Dental extraction procedure.',
      ),
      const StudentLeaveItem(
        id: 'lv-06',
        sl: '06',
        leaveType: 'Special Leave',
        dateRange: '07 May 2025 - 08 May 2025',
        durationDays: 2,
        applyDate: '07 May 2025',
        status: 'Rejected',
        reason: 'Request submitted without prior class teacher endorsement.',
      ),
    ];
  }

  void _updateLeaveStatus(String id, String newStatus) {
    setState(() {
      final index = _leaves.indexWhere((item) => item.id == id);
      if (index != -1) {
        _leaves[index] = _leaves[index].copyWith(status: newStatus);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request marked as $newStatus'),
        backgroundColor: newStatus == 'Approved'
            ? const Color(0xFF109F83)
            : const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final filtered = _leaves.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return item.leaveType.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q) ||
          item.dateRange.toLowerCase().contains(q);
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
          // Header with Title (Apply Leave removed as students submit leave)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                'Leave Requests',
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 5),
                    Text(
                      'Submitted by Student',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                          content: Text('Exporting leave records as $val...'),
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

          // Leave Data Table - Covers full screen width with LayoutBuilder
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
                        columnSpacing: 24,
                        columns: [
                          DataColumn(label: _buildSortHeader('S.L', isDark)),
                          DataColumn(label: _buildSortHeader('Leave Type', isDark)),
                          DataColumn(label: _buildSortHeader('Date', isDark)),
                          DataColumn(label: _buildSortHeader('Duration', isDark)),
                          DataColumn(label: _buildSortHeader('Apply Date', isDark)),
                          DataColumn(label: _buildSortHeader('Status', isDark)),
                          DataColumn(label: _buildSortHeader('Action', isDark)),
                        ],
                        rows: filtered.take(_rowsPerPage).map((item) {
                          final isPending = item.status == 'Pending';

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
                                  item.leaveType,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.dateRange,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${item.durationDays} day${item.durationDays > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.applyDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                _buildStatusPill(item.status),
                              ),
                              DataCell(
                                isPending
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _updateLeaveStatus(item.id, 'Approved'),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF16A34A),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Approve',
                                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _updateLeaveStatus(item.id, 'Rejected'),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDC2626),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Reject',
                                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item.status == 'Approved' ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                                            size: 15,
                                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Reviewed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                            ),
                                          ),
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
      case 'Approved':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case 'Pending':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
      case 'Rejected':
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
