import 'package:flutter/material.dart';
import '../../../domain/student_admission_model.dart';

/// Attendance Tab View for Student 360° Profile.
/// Matches the exact layout, KPI cards, and 30-day monthly matrix table from reference design.
class StudentAttendanceTab extends StatefulWidget {
  final StudentAdmissionModel admission;
  final bool isDark;

  const StudentAttendanceTab({
    super.key,
    required this.admission,
    this.isDark = false,
  });

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  String _selectedAcademicYear = '2026/2027';
  final List<String> _academicYears = [
    '2026/2027',
    '2025/2026',
    '2024/2025',
  ];

  // Month rows and day attendance status codes:
  // P = Present (Green), A = Absent (Red), H = Holiday (Orange), L = Late (Blue), F = Half Day (Purple)
  final List<Map<String, dynamic>> _allMonthsData = [
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
        'H', 'P', 'F', 'L', 'P', 'A', 'P', 'H', 'P', 'H'
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
        'P', 'P', 'P', 'H', 'P', 'F', 'L', 'P', 'H', 'P',
        'P', 'P', 'P', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Nov',
      'days': [
        'P', 'P', 'P', 'H', 'P', 'F', 'L', 'P', 'H', 'A',
        'P', 'P', 'L', 'P', 'F', 'H', 'P', 'A', 'P', 'P',
        'H', 'P', 'F', 'L', 'P', 'A', 'P', 'H', 'P', 'P'
      ]
    },
    {
      'month': 'Dec',
      'days': [
        'P', 'A', 'P', 'H', 'P', 'P', 'L', 'P', 'H', 'P',
        'P', 'P', 'F', 'L', 'H', 'P', 'P', 'P', 'P', 'P',
        'H', 'P', 'P', 'A', 'H', 'H', 'H', 'H', 'H', 'H'
      ]
    },
  ];

  List<Map<String, dynamic>> get _currentMonthsData {
    if (_selectedAcademicYear == '2026/2027') {
      // Current year up to current month (October 2026: 10 months)
      return _allMonthsData.take(10).toList();
    }
    // Completed past years: Full 12-month calendar range
    return _allMonthsData;
  }

  int _countStatus(String code) {
    int count = 0;
    for (final m in _currentMonthsData) {
      for (final d in (m['days'] as List<String>)) {
        if (d == code) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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
          // Section Title
          Text(
            'Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),

          // 5 KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;
              final isMobile = constraints.maxWidth < 600;

              final kpiCards = [
                _buildKpiCard(
                  count: '${_countStatus('P')}',
                  label: 'Total Present',
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF16A34A),
                  iconBgColor: const Color(0xFF16A34A),
                  gradientColors: isDark
                      ? [const Color(0xFF064E3B).withValues(alpha: 0.4), const Color(0xFF1E293B)]
                      : [const Color(0xFFECFDF5), Colors.white],
                  borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
                ),
                _buildKpiCard(
                  count: '${_countStatus('A')}',
                  label: 'Total Absent',
                  icon: Icons.person_off_rounded,
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFDC2626),
                  gradientColors: isDark
                      ? [const Color(0xFF7F1D1D).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFFEF2F2), Colors.white],
                  borderColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
                ),
                _buildKpiCard(
                  count: '${_countStatus('F')}',
                  label: 'Half Day',
                  icon: Icons.event_note_rounded,
                  iconColor: const Color(0xFF9333EA),
                  iconBgColor: const Color(0xFF9333EA),
                  gradientColors: isDark
                      ? [const Color(0xFF581C87).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFFAF5FF), Colors.white],
                  borderColor: isDark ? const Color(0xFF6B21A8) : const Color(0xFFE9D5FF),
                ),
                _buildKpiCard(
                  count: '${_countStatus('L')}',
                  label: 'Total Late',
                  icon: Icons.access_time_filled_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFF0284C7),
                  gradientColors: isDark
                      ? [const Color(0xFF0C4A6E).withValues(alpha: 0.35), const Color(0xFF1E293B)]
                      : [const Color(0xFFF0F9FF), Colors.white],
                  borderColor: isDark ? const Color(0xFF075985) : const Color(0xFFBAE6FD),
                ),
                _buildKpiCard(
                  count: '${_countStatus('H')}',
                  label: 'Total Holiday',
                  icon: Icons.beach_access_rounded,
                  iconColor: const Color(0xFFEA580C),
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
                children: [
                  for (int i = 0; i < kpiCards.length; i++) ...[
                    Expanded(child: kpiCards[i]),
                    if (i != kpiCards.length - 1) const SizedBox(width: 14),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Controls & Legend Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isWrap = constraints.maxWidth < 980;
              final controls = Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Academic Year Dropdown
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
                        value: _selectedAcademicYear,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _academicYears
                            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAcademicYear = val);
                        },
                      ),
                    ),
                  ),

                  // Export Button
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exporting attendance as $val...'),
                          backgroundColor: const Color(0xFF109F83),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                      const PopupMenuItem(value: 'Excel', child: Text('Export Excel / CSV')),
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
                ],
              );

              final legend = Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildLegendItem('Present:', 'P', const Color(0xFF16A34A)),
                  _buildLegendItem('Absent:', 'A', const Color(0xFFDC2626)),
                  _buildLegendItem('Holiday:', 'H', const Color(0xFFEA580C)),
                  _buildLegendItem('Late:', 'L', const Color(0xFF0284C7)),
                  _buildLegendItem('Half Day:', 'F', const Color(0xFF9333EA)),
                ],
              );

              if (isWrap) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    controls,
                    const SizedBox(height: 12),
                    legend,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  controls,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: legend,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // 30-Day Attendance Matrix Table with smooth horizontal scroll spanning full width
          LayoutBuilder(
            builder: (context, tableConstraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 42,
                        headingRowHeight: 42,
                        horizontalMargin: 16,
                        columnSpacing: 14,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Month',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          for (int d = 1; d <= 30; d++)
                            DataColumn(
                              label: Center(
                                child: Text(
                                  '$d',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        rows: _currentMonthsData.map((row) {
                    final monthName = row['month'] as String;
                    final days = row['days'] as List<String>;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        for (int i = 0; i < 30; i++)
                          DataCell(
                            Center(
                              child: Text(
                                i < days.length ? days[i] : 'P',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(i < days.length ? days[i] : 'P'),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
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
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.3 : 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconBgColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String code, Color color) {
    final isDark = widget.isDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          code,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
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
}
