import 'package:flutter/material.dart';
import '../../../domain/staff_member_model.dart';

/// Tab 2: Class Routine / Duty Schedule (matching Screenshot 2)
/// Renders weekly timetable columns Monday through Sunday with pastel period cards.
/// Dynamically adapts into 'Duty Schedule & Shift Roster' for non-teaching staff.
class StaffClassRoutineTab extends StatelessWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffClassRoutineTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final isTeaching = staff.category == StaffCategory.teaching;

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
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                isTeaching ? 'Class Routine' : 'Duty Schedule & Shift Roster',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTeaching ? 'Academic Year 2026/2027' : 'Standard Shift Pattern',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF109F83),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal scrollable schedule grid for 7 days (Covers full screen width with LayoutBuilder)
          LayoutBuilder(
            builder: (context, constraints) {
              final double minGridWidth = 1120;
              final double gridWidth = constraints.maxWidth > minGridWidth
                  ? constraints.maxWidth
                  : minGridWidth;
              final double dayColWidth = (gridWidth - (6 * 10)) / 7;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: gridWidth,
                  child: isTeaching
                      ? _buildTeachingRoutine(cardBg, borderColor, textColor, subColor, dayColWidth)
                      : _buildNonTeachingDutyRoster(cardBg, borderColor, textColor, subColor, dayColWidth),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingRoutine(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    double dayColWidth,
  ) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // Distinct periods corresponding to Screenshot 2
    final colors = [
      (
        headerBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
        headerText: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
      ),
      (
        headerBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
        headerText: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
      ),
      (
        headerBg: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
        headerText: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      ),
      (
        headerBg: isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6),
        headerText: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
      ),
      (
        headerBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
        headerText: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
      ),
    ];

    final timeSlots = [
      '09:00 AM - 09:45 AM',
      '09:50 AM - 10:35 AM',
      '10:40 AM - 11:25 AM',
      '11:30 AM - 12:15 PM',
      '12:20 PM - 01:05 PM',
    ];

    final roomNumbers = ['16', '10', '22', '08', '25'];

    List<_RoutinePeriod> periods = [];
    if (staff.assignedClasses.isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        final assign = staff.assignedClasses[i % staff.assignedClasses.length];
        final clr = colors[i % colors.length];
        periods.add(
          _RoutinePeriod(
            className: '${assign.grade} (${assign.section})',
            subject: assign.subject,
            roomNo: roomNumbers[i % roomNumbers.length],
            time: timeSlots[i % timeSlots.length],
            headerBg: clr.headerBg,
            headerText: clr.headerText,
          ),
        );
      }
    } else {
      periods = [
        _RoutinePeriod(
          className: 'Class: 1 (A)',
          subject: 'Math',
          roomNo: '16',
          time: '09:00 AM - 09:45 AM',
          headerBg: colors[0].headerBg,
          headerText: colors[0].headerText,
        ),
        _RoutinePeriod(
          className: 'Class: 2 (B)',
          subject: 'English',
          roomNo: '10',
          time: '09:50 AM - 10:35 AM',
          headerBg: colors[1].headerBg,
          headerText: colors[1].headerText,
        ),
        _RoutinePeriod(
          className: 'Class: 3 (A)',
          subject: 'Science',
          roomNo: '22',
          time: '10:40 AM - 11:25 AM',
          headerBg: colors[2].headerBg,
          headerText: colors[2].headerText,
        ),
        _RoutinePeriod(
          className: 'Class: 4 (C)',
          subject: 'History',
          roomNo: '8',
          time: '11:30 AM - 12:15 PM',
          headerBg: colors[3].headerBg,
          headerText: colors[3].headerText,
        ),
        _RoutinePeriod(
          className: 'Class: 5 (B)',
          subject: 'CSE',
          roomNo: '25',
          time: '12:20 PM - 01:05 PM',
          headerBg: colors[4].headerBg,
          headerText: colors[4].headerText,
        ),
      ];
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.map((day) {
        final isSunday = day == 'Sunday';

        return Container(
          width: dayColWidth,
          margin: EdgeInsets.only(right: day == days.last ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Day Title Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              if (isSunday)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFDBA74),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Holiday',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                    ),
                  ),
                )
              else
                ...periods.map((period) => _buildPeriodCard(period, borderColor, textColor, subColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNonTeachingDutyRoster(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    double dayColWidth,
  ) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final dutySlots = [
      _RoutinePeriod(
        className: 'Shift: Morning',
        subject: 'Facility Prep',
        roomNo: 'Desk 1',
        time: '08:00 AM - 10:30 AM',
        headerBg: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE),
        headerText: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
      ),
      _RoutinePeriod(
        className: 'Shift: Operations',
        subject: staff.department,
        roomNo: 'Station 4',
        time: '10:45 AM - 01:15 PM',
        headerBg: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
        headerText: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      ),
      _RoutinePeriod(
        className: 'Shift: Afternoon',
        subject: 'Inquiries & Admin',
        roomNo: 'Main Bay',
        time: '02:00 PM - 04:30 PM',
        headerBg: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
        headerText: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.map((day) {
        final isSunday = day == 'Sunday';

        return Container(
          width: dayColWidth,
          margin: EdgeInsets.only(right: day == days.last ? 0 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              if (isSunday)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFDBA74),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Weekly Off',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                    ),
                  ),
                )
              else
                ...dutySlots.map((slot) => _buildPeriodCard(slot, borderColor, textColor, subColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodCard(
    _RoutinePeriod period,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pastel Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: period.headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              period.className,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: period.headerText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 13, color: subColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Subject : ${period.subject}',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 13, color: subColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Room No : ${period.roomNo}',
                        style: TextStyle(fontSize: 10.5, color: subColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined, size: 13, color: subColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        period.time,
                        style: TextStyle(fontSize: 9.5, color: subColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutinePeriod {
  final String className;
  final String subject;
  final String roomNo;
  final String time;
  final Color headerBg;
  final Color headerText;

  const _RoutinePeriod({
    required this.className,
    required this.subject,
    required this.roomNo,
    required this.time,
    required this.headerBg,
    required this.headerText,
  });
}
