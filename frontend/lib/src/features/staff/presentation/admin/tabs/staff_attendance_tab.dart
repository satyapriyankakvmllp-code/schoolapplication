import 'package:flutter/material.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import '../../../domain/staff_member_model.dart';

/// Tab 3: Attendance (matching Screenshot 3)
/// Features 5 KPI summary cards, dynamic academic year filter (2024 to now),
/// export dropdown, color legend, and full-screen 30-day monthly matrix table.
class StaffAttendanceTab extends StatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffAttendanceTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  State<StaffAttendanceTab> createState() => _StaffAttendanceTabState();
}

class _StaffAttendanceTabState extends State<StaffAttendanceTab> {
  String _selectedAcademicYear = '2026/2027';

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
                  _buildKpiCard('$_totalAbsent', 'Total Absent', Icons.cancel_outlined, const Color(0xFFDC2626), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_halfDay', 'Half Day', Icons.event_note_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_totalLate', 'Total Late', Icons.schedule_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor, width: 160),
                  _buildKpiCard('$_totalHoliday', 'Total Holiday', Icons.beach_access_outlined, const Color(0xFFEA580C), const Color(0xFFFFEDD5), cardBg, borderColor, textColor, subColor, width: 160),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: _buildKpiCard('$_totalPresent', 'Total Present', Icons.check_circle_outline, const Color(0xFF16A34A), const Color(0xFFDCFCE7), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalAbsent', 'Total Absent', Icons.cancel_outlined, const Color(0xFFDC2626), const Color(0xFFFEE2E2), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_halfDay', 'Half Day', Icons.event_note_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalLate', 'Total Late', Icons.schedule_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE), cardBg, borderColor, textColor, subColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('$_totalHoliday', 'Total Holiday', Icons.beach_access_outlined, const Color(0xFFEA580C), const Color(0xFFFFEDD5), cardBg, borderColor, textColor, subColor)),
              ],
            );
          },
        ),
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
                      _buildLegendItem('Absent: A', const Color(0xFFDC2626)),
                      _buildLegendItem('Holiday: H', const Color(0xFFEA580C)),
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
                              ...days.map((status) {
                                return Expanded(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                    textAlign: TextAlign.center,
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
        return const Color(0xFFDC2626);
      case 'H':
        return const Color(0xFFEA580C);
      case 'L':
        return const Color(0xFF0284C7);
      case 'F':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF64748B);
    }
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
