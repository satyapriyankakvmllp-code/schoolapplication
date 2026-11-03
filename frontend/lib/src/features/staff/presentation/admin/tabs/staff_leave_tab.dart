import 'package:flutter/material.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../domain/staff_member_model.dart';

class StaffLeaveRecord {
  final String id;
  final String sl;
  final String leaveType;
  final String dateRange;
  final int durationDays;
  final String applyDate;
  final String status; // 'Approved', 'Pending', 'Rejected'
  final String? reason;
  final String? adminRemarks;

  const StaffLeaveRecord({
    required this.id,
    required this.sl,
    required this.leaveType,
    required this.dateRange,
    required this.durationDays,
    required this.applyDate,
    required this.status,
    this.reason,
    this.adminRemarks,
  });

  StaffLeaveRecord copyWith({
    String? id,
    String? sl,
    String? leaveType,
    String? dateRange,
    int? durationDays,
    String? applyDate,
    String? status,
    String? reason,
    String? adminRemarks,
  }) {
    return StaffLeaveRecord(
      id: id ?? this.id,
      sl: sl ?? this.sl,
      leaveType: leaveType ?? this.leaveType,
      dateRange: dateRange ?? this.dateRange,
      durationDays: durationDays ?? this.durationDays,
      applyDate: applyDate ?? this.applyDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      adminRemarks: adminRemarks ?? this.adminRemarks,
    );
  }
}

/// Tab 4: Leave (matching Screenshot 4)
/// Displays staff leave applications with inline Approve/Reject action buttons.
/// No "Apply Leave" button (Admin views staff requests).
class StaffLeaveTab extends StatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffLeaveTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  State<StaffLeaveTab> createState() => _StaffLeaveTabState();
}

class _StaffLeaveTabState extends State<StaffLeaveTab> {
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

  late List<StaffLeaveRecord> _leaves;

  @override
  void initState() {
    super.initState();
    _leaves = _buildInitialLeaves();
    _loadLeaves();
  }

  @override
  void didUpdateWidget(covariant StaffLeaveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.id != widget.staff.id) {
      _loadLeaves();
    }
  }

  Future<void> _loadLeaves() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_leaves.json',
        storageKey: 'edupulse_staff_leaves_records',
      );
      if (records.isNotEmpty) {
        final staffRecords = records.where((r) => r['staff_id'] == widget.staff.id).toList();
        final effectiveRecords = staffRecords.isNotEmpty ? staffRecords : records;
        if (mounted) {
          setState(() {
            _leaves = effectiveRecords.map((r) => StaffLeaveRecord(
              id: (r['id'] ?? '').toString(),
              sl: (r['sl'] ?? '').toString(),
              leaveType: (r['leave_type'] ?? 'Casual Leave').toString(),
              dateRange: (r['date_range'] ?? '').toString(),
              durationDays: (r['duration_days'] as num?)?.toInt() ?? 1,
              applyDate: (r['apply_date'] ?? '').toString(),
              status: (r['status'] ?? 'Pending').toString(),
              reason: r['reason']?.toString(),
              adminRemarks: r['admin_remarks']?.toString(),
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

  List<StaffLeaveRecord> _buildInitialLeaves() {
    return [
      const StaffLeaveRecord(
        id: 'sl-01',
        sl: '01',
        leaveType: 'Medical Leave',
        dateRange: '19 Oct 2026 - 20 Oct 2026',
        durationDays: 2,
        applyDate: '15 Oct 2026',
        status: 'Approved',
        reason: 'Scheduled dental surgery and recovery',
        adminRemarks: 'Approved with substitute coverage assigned to Amit Chatterjee',
      ),
      const StaffLeaveRecord(
        id: 'sl-02',
        sl: '02',
        leaveType: 'Special Duty Leave',
        dateRange: '04 Nov 2026 - 05 Nov 2026',
        durationDays: 2,
        applyDate: '16 Oct 2026',
        status: 'Pending',
        reason: 'Attending national curriculum development conference as panel speaker',
      ),
      const StaffLeaveRecord(
        id: 'sl-03',
        sl: '03',
        leaveType: 'Casual Leave',
        dateRange: '12 Sep 2026 - 13 Sep 2026',
        durationDays: 2,
        applyDate: '08 Sep 2026',
        status: 'Approved',
        reason: 'Family wedding event in hometown',
        adminRemarks: 'Approved by Principal',
      ),
      const StaffLeaveRecord(
        id: 'sl-04',
        sl: '04',
        leaveType: 'Casual Leave',
        dateRange: '18 Aug 2026 - 19 Aug 2026',
        durationDays: 2,
        applyDate: '14 Aug 2026',
        status: 'Pending',
        reason: 'Personal urgent bank clearance work',
      ),
      const StaffLeaveRecord(
        id: 'sl-05',
        sl: '05',
        leaveType: 'Medical Leave',
        dateRange: '10 Jul 2026 - 11 Jul 2026',
        durationDays: 2,
        applyDate: '09 Jul 2026',
        status: 'Approved',
        reason: 'Seasonal viral fever',
        adminRemarks: 'Medical certificate verified',
      ),
      const StaffLeaveRecord(
        id: 'sl-06',
        sl: '06',
        leaveType: 'Special Leave',
        dateRange: '02 Jun 2026 - 04 Jun 2026',
        durationDays: 3,
        applyDate: '28 May 2026',
        status: 'Rejected',
        reason: 'Personal recreation during examination week',
        adminRemarks: 'Cannot approve during board examination invigilation schedule',
      ),
      const StaffLeaveRecord(
        id: 'sl-07',
        sl: '07',
        leaveType: 'Casual Leave',
        dateRange: '15 May 2026 - 16 May 2026',
        durationDays: 2,
        applyDate: '11 May 2026',
        status: 'Approved',
        reason: 'Attending sibling graduation ceremony',
      ),
      const StaffLeaveRecord(
        id: 'sl-08',
        sl: '08',
        leaveType: 'Special Leave',
        dateRange: '20 Apr 2026 - 22 Apr 2026',
        durationDays: 3,
        applyDate: '15 Apr 2026',
        status: 'Rejected',
        reason: 'Extension of spring holiday without prior intimation',
      ),
      const StaffLeaveRecord(
        id: 'sl-09',
        sl: '09',
        leaveType: 'Medical Leave',
        dateRange: '10 Mar 2026 - 11 Mar 2026',
        durationDays: 2,
        applyDate: '08 Mar 2026',
        status: 'Approved',
        reason: 'Eye consultation and rest',
      ),
      const StaffLeaveRecord(
        id: 'sl-10',
        sl: '10',
        leaveType: 'Special Duty Leave',
        dateRange: '14 Feb 2026 - 15 Feb 2026',
        durationDays: 2,
        applyDate: '10 Feb 2026',
        status: 'Approved',
        reason: 'Inter-school sports meet coordinator duty',
      ),
    ];
  }

  Future<void> _updateLeaveStatus(String id, String newStatus, {String? remarks}) async {
    setState(() {
      _leaves = _leaves.map((l) {
        if (l.id == id) {
          return l.copyWith(status: newStatus, adminRemarks: remarks);
        }
        return l;
      }).toList();
    });

    try {
      final allRaw = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/staff/staff_leaves.json',
        storageKey: 'edupulse_staff_leaves_records',
      );
      final updatedRaw = allRaw.map((item) {
        if (item['id'] == id) {
          item['status'] = newStatus;
          if (remarks != null) item['admin_remarks'] = remarks;
        }
        return item;
      }).toList();
      await DynamicDataClient.instance.syncAll(
        assetPath: 'assets/data/staff/staff_leaves.json',
        storageKey: 'edupulse_staff_leaves_records',
        items: updatedRaw,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave application marked as $newStatus.'),
          backgroundColor: newStatus == 'Approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showApproveRejectDialog(StaffLeaveRecord leave, bool isApprove) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(isApprove ? 'Approve Leave Request?' : 'Reject Leave Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applicant: ${widget.staff.fullName}'),
            const SizedBox(height: 4),
            Text('Leave Type: ${leave.leaveType} (${leave.durationDays} days)'),
            const SizedBox(height: 4),
            Text('Dates: ${leave.dateRange}'),
            if (leave.reason != null) ...[
              const SizedBox(height: 6),
              Text('Reason: ${leave.reason}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Admin Remarks / Substitute Teacher',
                border: OutlineInputBorder(),
                hintText: 'e.g., Substitute teacher assigned',
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
              backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateLeaveStatus(
                leave.id,
                isApprove ? 'Approved' : 'Rejected',
                remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
              );
            },
            child: Text(isApprove ? 'Confirm Approve' : 'Confirm Reject'),
          ),
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

    final filtered = _leaves.where((l) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesType = l.leaveType.toLowerCase().contains(q);
        final matchesStatus = l.status.toLowerCase().contains(q);
        final matchesDate = l.dateRange.toLowerCase().contains(q);
        if (!matchesType && !matchesStatus && !matchesDate) return false;
      }
      return true;
    }).toList();

    final totalEntries = filtered.length;
    final totalPages = (totalEntries / _rowsPerPage).ceil().clamp(1, 999);
    final startIdx = ((_currentPage - 1) * _rowsPerPage).clamp(0, totalEntries);
    final endIdx = (startIdx + _rowsPerPage).clamp(0, totalEntries);
    final pageRecords = filtered.sublist(startIdx, endIdx);

    return Container(
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
          // Header Row
          Text(
            'Leave',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Search, Filter & Rows Per Page Bar
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
                  // Export Button
                  PopupMenuButton<String>(
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                      PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                    ],
                    onSelected: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exporting leaves as ${val.toUpperCase()}...'),
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
                  // Rows Per Page
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

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  searchField,
                  controls,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Leave Table (Covers full screen width with LayoutBuilder)
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
                      // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'S.L',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Leave Type',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Date',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Duration',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Apply Date',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Action',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Table Rows
                  if (pageRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text('No leave applications match your search.', style: TextStyle(color: subColor)),
                    )
                  else
                    ...pageRecords.map((l) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(l.sl, style: TextStyle(fontSize: 12, color: subColor)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                l.leaveType,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(l.dateRange, style: TextStyle(fontSize: 12, color: textColor)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${l.durationDays}', style: TextStyle(fontSize: 12, color: textColor)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(l.applyDate, style: TextStyle(fontSize: 12, color: textColor)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildStatusBadge(l.status),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: l.status == 'Pending'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _showApproveRejectDialog(l, true),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Approve',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _showApproveRejectDialog(l, false),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Reject',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      l.adminRemarks ?? 'Reviewed',
                                      style: TextStyle(fontSize: 11.5, color: subColor, fontStyle: FontStyle.italic),
                                      overflow: TextOverflow.ellipsis,
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

          // Pagination Info & Buttons
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFDCFCE7);
    Color fg = const Color(0xFF16A34A);

    if (status == 'Pending') {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFEA580C);
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    if (widget.isDark) {
      if (status == 'Approved') bg = const Color(0xFF14532D);
      if (status == 'Pending') bg = const Color(0xFF7C2D12);
      if (status == 'Rejected') bg = const Color(0xFF7F1D1D);
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
