import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../domain/staff_member_model.dart';

/// Tab 3: Attendance (matching Screenshot 3)
/// Features 5 KPI summary cards, dynamic academic year filter (2024 to now),
/// export dropdown, color legend, and full-screen 30-day monthly matrix table.
/// Allows Admin to edit attendance marks interactively.
class StaffAttendanceTab extends ConsumerStatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffAttendanceTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  ConsumerState<StaffAttendanceTab> createState() => _StaffAttendanceTabState();
}

class _StaffAttendanceTabState extends ConsumerState<StaffAttendanceTab> {
  String _selectedAcademicYear = '2026/2027';
  String _attendanceChartMode = 'rate'; // 'rate' (Line Chart) or 'breakdown' (Bar Chart)

  final List<String> _academicYears = [
    '2026/2027',
    '2025/2026',
    '2024/2025',
  ];

  int _totalPresent = 227;
  int _totalAbsent = 70;
  int _halfDay = 27;
  int _totalLate = 28;
  int _totalHoliday = 12;
  List<Map<String, dynamic>> _loadedMonths = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(covariant StaffAttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.id != widget.staff.id) {
      _loadAttendanceData();
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/attendance/staff_attendance.json',
        storageKey: 'edupulse_staff_attendance_records',
      );
      final staffRec = records.firstWhere(
        (r) => r['staff_id'] == widget.staff.id && r['academic_year'] == _selectedAcademicYear,
        orElse: () => records.firstWhere(
          (r) => r['academic_year'] == _selectedAcademicYear,
          orElse: () => records.isNotEmpty ? records.first : <String, dynamic>{},
        ),
      );

      if (staffRec.isNotEmpty && mounted) {
        setState(() {
          _totalPresent = (staffRec['total_present'] as num?)?.toInt() ?? _totalPresent;
          _totalAbsent = (staffRec['total_absent'] as num?)?.toInt() ?? _totalAbsent;
          _halfDay = (staffRec['half_day'] as num?)?.toInt() ?? _halfDay;
          _totalLate = (staffRec['total_late'] as num?)?.toInt() ?? _totalLate;
          _totalHoliday = (staffRec['total_holiday'] as num?)?.toInt() ?? _totalHoliday;
          if (staffRec['months'] != null) {
            _loadedMonths = List<Map<String, dynamic>>.from(staffRec['months'] as List);
          }
        });
      }
    } catch (_) {}
  }

  void _toggleDayAttendance(String monthName, int dayIndex) {
    const cycle = {
      'P': 'L',
      'L': 'F',
      'F': 'A',
      'A': 'H',
      'H': 'P',
    };

    final effectiveList = _loadedMonths.isNotEmpty ? _loadedMonths : _masterMonths;
    final monthIdx = effectiveList.indexWhere((m) => m['month'] == monthName);
    if (monthIdx < 0) return;

    final currentDays = List<String>.from(effectiveList[monthIdx]['days'] as List);
    if (dayIndex < 0 || dayIndex >= currentDays.length) return;

    final currentVal = currentDays[dayIndex];
    final nextVal = cycle[currentVal] ?? 'P';
    currentDays[dayIndex] = nextVal;

    setState(() {
      effectiveList[monthIdx]['days'] = currentDays;
      _loadedMonths = effectiveList;

      int p = 0, a = 0, f = 0, l = 0, h = 0;
      for (final m in effectiveList) {
        final dList = (m['days'] as List).map((d) => d.toString()).toList();
        p += dList.where((d) => d == 'P').length;
        a += dList.where((d) => d == 'A').length;
        f += dList.where((d) => d == 'F').length;
        l += dList.where((d) => d == 'L').length;
        h += dList.where((d) => d == 'H').length;
      }
      _totalPresent = p;
      _totalAbsent = a;
      _halfDay = f;
      _totalLate = l;
      _totalHoliday = h;
    });

    _persistAttendance();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$monthName Day ${dayIndex + 1} updated to "$nextVal".'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _persistAttendance() async {
    try {
      final records = await DynamicDataClient.instance.getAll(
        assetPath: 'assets/data/attendance/staff_attendance.json',
        storageKey: 'edupulse_staff_attendance_records',
      );
      final staffRecord = {
        'staff_id': widget.staff.id,
        'academic_year': _selectedAcademicYear,
        'total_present': _totalPresent,
        'total_absent': _totalAbsent,
        'half_day': _halfDay,
        'total_late': _totalLate,
        'total_holiday': _totalHoliday,
        'months': _loadedMonths.isNotEmpty ? _loadedMonths : _masterMonths,
      };

      final idx = records.indexWhere((r) => r['staff_id'] == widget.staff.id && r['academic_year'] == _selectedAcademicYear);
      if (idx >= 0) {
        records[idx] = staffRecord;
      } else {
        records.add(staffRecord);
      }

      await DynamicDataClient.instance.syncAll(
        assetPath: 'assets/data/attendance/staff_attendance.json',
        storageKey: 'edupulse_staff_attendance_records',
        items: records,
      );
    } catch (_) {}
  }

  // Base calendar seed with status codes:
  // P = Present (Green), A = Absent (Red), H = Holiday (Orange), L = Late (Blue), F = Half Day (Purple)
  final List<Map<String, dynamic>> _masterMonths = [
    {
      'month': 'Jan',
      'days': [
        'P', 'H', 'A', 'P', 'P', 'P', 'F', 'L', 'H', 'P',
        'A', 'P', 'P', 'L', 'H', 'P', 'P', 'P', 'P', 'F',
        'H', 'P', 'P', 'P', 'P', 'P', 'A', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Feb',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'F', 'P', 'L', 'A', 'H',
        'P', 'F', 'P', 'L', 'H', 'A', 'P', 'P', 'H', 'P',
        'F', 'P', 'L', 'A', 'H', 'P', 'F', 'P', 'L', 'A'
      ]
    },
    {
      'month': 'Mar',
      'days': [
        'P', 'A', 'P', 'P', 'F', 'H', 'P', 'L', 'P', 'A',
        'P', 'H', 'P', 'L', 'F', 'A', 'P', 'H', 'P', 'P',
        'A', 'P', 'L', 'P', 'H', 'P', 'A', 'F', 'H', 'P'
      ]
    },
    {
      'month': 'Apr',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'F', 'L', 'P', 'H', 'A',
        'P', 'P', 'L', 'P', 'F', 'H', 'P', 'A', 'P', 'P',
        'H', 'P', 'F', 'L', 'P', 'A', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'May',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'F', 'L', 'P', 'H', 'A',
        'P', 'P', 'L', 'P', 'F', 'H', 'P', 'A', 'P', 'P',
        'H', 'P', 'F', 'L', 'P', 'A', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Jun',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'F', 'L', 'P', 'H', 'A',
        'P', 'P', 'L', 'P', 'F', 'H', 'P', 'A', 'P', 'P',
        'H', 'P', 'F', 'L', 'P', 'A', 'P', 'H', 'P', 'A'
      ]
    },
    {
      'month': 'Jul',
      'days': [
        'P', 'P', 'P', 'H', 'P', 'P', 'L', 'P', 'H', 'P',
        'A', 'P', 'P', 'F', 'H', 'P', 'P', 'P', 'P', 'L',
        'H', 'P', 'P', 'P', 'P', 'A', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Aug',
      'days': [
        'P', 'P', 'H', 'P', 'P', 'P', 'F', 'P', 'H', 'P',
        'P', 'L', 'P', 'A', 'H', 'P', 'P', 'P', 'P', 'P',
        'H', 'F', 'P', 'P', 'P', 'P', 'A', 'H', 'P', 'L'
      ]
    },
    {
      'month': 'Sep',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'P', 'L', 'P', 'H', 'P',
        'P', 'P', 'P', 'L', 'H', 'P', 'P', 'F', 'P', 'P',
        'H', 'P', 'A', 'P', 'P', 'P', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Oct',
      'days': [
        'P', 'P', 'P', 'H', 'P', 'F', 'P', 'L', 'H', 'P',
        'P', 'A', 'P', 'P', 'H', 'P', 'P', 'P', 'P', 'L',
        'H', 'P', 'P', 'F', 'P', 'P', 'A', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Nov',
      'days': [
        'P', 'P', 'P', 'H', 'P', 'P', 'L', 'P', 'H', 'P',
        'A', 'P', 'P', 'P', 'H', 'P', 'P', 'F', 'P', 'P',
        'H', 'P', 'P', 'P', 'P', 'A', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Dec',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'P', 'F', 'L', 'H', 'P',
        'P', 'P', 'P', 'L', 'H', 'P', 'P', 'P', 'P', 'F',
        'H', 'P', 'P', 'P', 'P', 'P', 'A', 'H', 'P', 'P'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final monthsSource = _loadedMonths.isNotEmpty ? _loadedMonths : _masterMonths;
    final displayedMonths = _selectedAcademicYear == '2026/2027'
        ? (monthsSource.length >= 10 ? monthsSource.sublist(0, 10) : monthsSource)
        : monthsSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5 KPI Summary Cards (Present, Absent, Half Day, Late, Holiday)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            if (isNarrow) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard('$_totalPresent', 'Total Present', Icons.check_circle_outline, const Color(0xFF16A34A), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_totalAbsent', 'Total Absent', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_halfDay', 'Half Day', Icons.event_note_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_totalLate', 'Total Late', Icons.schedule_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_totalHoliday', 'Total Holiday', Icons.beach_access_outlined, const Color(0xFFF59E0B), const Color(0xFFFEF3C7), cardBg, borderColor, textColor, subColor, width: 160),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: _buildKpiCard('$_totalPresent', 'Total Present', Icons.check_circle_outline, const Color(0xFF16A34A), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalAbsent', 'Total Absent', Icons.cancel_outlined, const Color(0xFFEF4444), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_halfDay', 'Half Day', Icons.event_note_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalLate', 'Total Late', Icons.schedule_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalHoliday', 'Total Holiday', Icons.beach_access_outlined, const Color(0xFFF59E0B), const Color(0xFFFEF3C7), cardBg, borderColor, textColor, subColor)),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Attendance Performance Matrix Heatmap Graph
        _buildAttendanceMatrixGraph(displayedMonths, cardBg, borderColor, textColor, subColor, widget.isDark),
        const SizedBox(height: 20),

        // Filter Bar & Color Legend
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
              // Top Row: Title, Year Dropdown, Export Button, Legend
              LayoutBuilder(
                builder: (context, constraints) {
                  final leftControls = Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Year selector dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAcademicYear,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            dropdownColor: cardBg,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            items: _academicYears.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text('Academic Year $year'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedAcademicYear = val);
                                _loadAttendanceData();
                              }
                            },
                          ),
                        ),
                      ),
                      // Export button
                      PopupMenuButton<String>(
                        tooltip: 'Export Attendance Report',
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'pdf', child: Text('Export to PDF')),
                          PopupMenuItem(value: 'csv', child: Text('Export to CSV')),
                          PopupMenuItem(value: 'excel', child: Text('Export to Excel')),
                        ],
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exporting attendance report as ${val.toUpperCase()}...'),
                              backgroundColor: const Color(0xFF109F83),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_outlined, size: 16, color: subColor),
                              const SizedBox(width: 6),
                              Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 16, color: subColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );

                  final legend = Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildLegendItem('Present: P', const Color(0xFF16A34A)),
                      _buildLegendItem('Absent: A', const Color(0xFFEF4444)),
                      _buildLegendItem('Holiday: H', const Color(0xFFF59E0B)),
                      _buildLegendItem('Late: L', const Color(0xFF0284C7)),
                      _buildLegendItem('Half Day: F', const Color(0xFF9333EA)),
                    ],
                  );

                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 14,
                    children: [
                      leftControls,
                      legend,
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Full Screen Width Monthly Matrix Table (Covers full screen width with LayoutBuilder)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double tableWidth = constraints.maxWidth > 1060
                      ? constraints.maxWidth
                      : 1060;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                      // Header: Month, 1, 2, 3 ... 30
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            ...List.generate(30, (index) {
                              return Expanded(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: subColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Month Rows
                      ...displayedMonths.map((m) {
                        final String monthName = m['month'] as String;
                        final List<String> days = List<String>.from(m['days'] as List);

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  monthName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              ...days.asMap().entries.map((entry) {
                                final dayIdx = entry.key;
                                final status = entry.value;
                                return Expanded(
                                  child: Tooltip(
                                    message: 'Tap to toggle status (P/L/F/A/H)',
                                    child: InkWell(
                                      onTap: () => _toggleDayAttendance(monthName, dayIdx),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        alignment: Alignment.center,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(status),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
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
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String code) {
    switch (code) {
      case 'P':
        return const Color(0xFF16A34A);
      case 'A':
        return const Color(0xFFEF4444); // Vivid Crimson Red
      case 'H':
        return const Color(0xFFF59E0B); // Warm Amber / Golden Yellow
      case 'L':
        return const Color(0xFF0284C7);
      case 'F':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Attendance Performance Matrix Graph (Dual-View Interactive Chart)
  Widget _buildAttendanceMatrixGraph(
    List<Map<String, dynamic>> months,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    // Compute monthly metrics
    final List<Map<String, dynamic>> computed = months.map((m) {
      final days = (m['days'] as List).map((d) => d.toString()).toList();
      final p = days.where((d) => d == 'P').length;
      final a = days.where((d) => d == 'A').length;
      final l = days.where((d) => d == 'L').length;
      final f = days.where((d) => d == 'F').length;
      final h = days.where((d) => d == 'H').length;
      final workDays = 30 - h;
      final rate = workDays > 0 ? ((p + (f * 0.5)) / workDays) * 100 : 100.0;

      return {
        'month': m['month'],
        'P': p,
        'A': a,
        'L': l,
        'F': f,
        'H': h,
        'rate': rate,
      };
    }).toList();

    // Overall annual average rate
    final double overallRate = computed.isNotEmpty
        ? computed.map((c) => c['rate'] as double).reduce((x, y) => x + y) / computed.length
        : 90.0;

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Toggle Controls
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF109F83)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Staff Attendance Performance Matrix',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      Text(
                        'Visual monthly progression, consistency benchmark & duty breakdown',
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ],
              ),
              // Segmented Toggle Switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChartModePill('rate', 'Rate Trend (Line)', Icons.show_chart, textColor, subColor, isDark),
                    _buildChartModePill('breakdown', 'Days Breakdown (Bar)', Icons.bar_chart, textColor, subColor, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Display Area
          SizedBox(
            height: 260,
            child: _attendanceChartMode == 'rate'
                ? _buildAttendanceLineChart(computed, textColor, subColor, borderColor, isDark, overallRate)
                : _buildAttendanceBarChart(computed, textColor, subColor, borderColor, isDark),
          ),
          const SizedBox(height: 16),

          // Metric Badges & Legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMatrixLegendBadge('Present Days', const Color(0xFF16A34A), isDark),
                  _buildMatrixLegendBadge('Absent Days', const Color(0xFFEF4444), isDark),
                  _buildMatrixLegendBadge('Late Arrivals', const Color(0xFF0284C7), isDark),
                  _buildMatrixLegendBadge('Half Days', const Color(0xFF9333EA), isDark),
                  _buildMatrixLegendBadge('Holidays', const Color(0xFFF59E0B), isDark),
                  _buildMatrixLegendBadge('Attendance Rate', const Color(0xFF109F83), isDark),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Annual Consistency: ${overallRate.toStringAsFixed(1)}% Avg',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF109F83)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartModePill(
    String mode,
    String label,
    IconData icon,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    final isSelected = _attendanceChartMode == mode;
    return InkWell(
      onTap: () => setState(() => _attendanceChartMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF109F83) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : subColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceLineChart(
    List<Map<String, dynamic>> computed,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
    double overallRate,
  ) {
    if (computed.isEmpty) {
      return Center(child: Text('No attendance data available', style: TextStyle(color: subColor)));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < computed.length; i++) {
      spots.add(FlSpot(i.toDouble(), (computed[i]['rate'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (val) => FlLine(
            color: borderColor.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= computed.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    computed[idx]['month'].toString(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 10,
              getTitlesWidget: (val, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${val.toInt()}%',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subColor),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 85,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                labelResolver: (_) => '85% Target',
              ),
            ),
          ],
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF109F83),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF109F83),
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF109F83).withValues(alpha: 0.35),
                  const Color(0xFF109F83).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF0F172A) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final monthName = computed[idx]['month'];
                final rate = spot.y.toStringAsFixed(1);
                return LineTooltipItem(
                  '$monthName: $rate%\n',
                  TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                  children: [
                    TextSpan(
                      text: spot.y >= 90
                          ? 'Status: High Performance'
                          : (spot.y >= 80 ? 'Status: Consistent' : 'Status: Needs Focus'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: spot.y >= 90
                            ? const Color(0xFF10B981)
                            : (spot.y >= 80 ? const Color(0xFF06B6D4) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceBarChart(
    List<Map<String, dynamic>> computed,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    if (computed.isEmpty) {
      return Center(child: Text('No attendance data available', style: TextStyle(color: subColor)));
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < computed.length; i++) {
      final m = computed[i];
      final double p = (m['P'] as num).toDouble();
      final double hd = (m['F'] as num).toDouble();
      final double l = (m['L'] as num).toDouble();
      final double a = (m['A'] as num).toDouble();
      final double h = (m['H'] as num).toDouble();
      final double total = (p + hd + l + a + h).clamp(1.0, 31.0);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              rodStackItems: [
                BarChartRodStackItem(0, p, const Color(0xFF16A34A)),
                BarChartRodStackItem(p, p + hd, const Color(0xFF9333EA)),
                BarChartRodStackItem(p + hd, p + hd + l, const Color(0xFF0284C7)),
                BarChartRodStackItem(p + hd + l, p + hd + l + a, const Color(0xFFEF4444)),
                BarChartRodStackItem(p + hd + l + a, total, const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: 32,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (val) => FlLine(
            color: borderColor.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= computed.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    computed[idx]['month'].toString(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 10,
              getTitlesWidget: (val, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${val.toInt()}d',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subColor),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF0F172A) : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final m = computed[group.x.toInt()];
              return BarTooltipItem(
                '${m['month']} (Total: 30d)\n',
                TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                children: [
                  TextSpan(text: '• Present: ${m['P']}d\n', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10.5)),
                  TextSpan(text: '• Half Day: ${m['F']}d\n', style: const TextStyle(color: Color(0xFF9333EA), fontSize: 10.5)),
                  TextSpan(text: '• Late: ${m['L']}d\n', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10.5)),
                  TextSpan(text: '• Absent: ${m['A']}d\n', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10.5)),
                  TextSpan(text: '• Holiday: ${m['H']}d', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixLegendBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}
