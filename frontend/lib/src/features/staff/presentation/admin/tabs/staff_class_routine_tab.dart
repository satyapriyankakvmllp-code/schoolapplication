import 'package:flutter/material.dart';
import '../../../domain/staff_member_model.dart';

/// Item representing a scheduled class or duty roster block.
class RoutinePeriodItem {
  final String id;
  final String day; // 'Monday', 'Tuesday', etc.
  final String className;
  String subject; // Mutable duty/instructional subject
  String purpose; // Mutable duty purpose / syllabus objective
  final String roomNo;
  final String time;
  String status; // 'Scheduled', 'In Progress', 'Completed', 'Staff on Leave', 'Substituted'
  String? substitutedBy; // Substitute staff member assigned when original staff is on leave
  String? substituteNotes;

  RoutinePeriodItem({
    required this.id,
    required this.day,
    required this.className,
    required this.subject,
    required this.purpose,
    required this.roomNo,
    required this.time,
    this.status = 'Scheduled',
    this.substitutedBy,
    this.substituteNotes,
  });

  RoutinePeriodItem copyWith({
    String? id,
    String? day,
    String? className,
    String? subject,
    String? purpose,
    String? roomNo,
    String? time,
    String? status,
    String? substitutedBy,
    String? substituteNotes,
  }) {
    return RoutinePeriodItem(
      id: id ?? this.id,
      day: day ?? this.day,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      purpose: purpose ?? this.purpose,
      roomNo: roomNo ?? this.roomNo,
      time: time ?? this.time,
      status: status ?? this.status,
      substitutedBy: substitutedBy ?? this.substitutedBy,
      substituteNotes: substituteNotes ?? this.substituteNotes,
    );
  }
}

/// Tab 2: Class Routine / Duty Schedule
/// Features:
/// 1. Dynamic Month & Week Filter Toolbar (select month, then week).
/// 2. Column-wise coloring per day (Monday to Sunday) reflecting a unified daily shift.
/// 3. Mutable 'Subject / Purpose' fields enabling admin and staff to assign/update work objectives.
/// 4. Interactive status update dialog ('Scheduled', 'In Progress', 'Completed', 'Staff on Leave').
/// 5. Distinct alert coloring when a staff member is on leave or absent with a Reassign Substitute Staff action.
class StaffClassRoutineTab extends StatefulWidget {
  final StaffMemberModel staff;
  final bool isDark;

  const StaffClassRoutineTab({
    super.key,
    required this.staff,
    required this.isDark,
  });

  @override
  State<StaffClassRoutineTab> createState() => _StaffClassRoutineTabState();
}

class _StaffClassRoutineTabState extends State<StaffClassRoutineTab> {
  String _selectedMonth = 'August 2026';
  int _selectedWeek = 1;

  final List<String> _months = [
    'August 2026',
    'July 2026',
    'June 2026',
    'May 2026',
    'April 2026',
  ];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Available substitute faculty members
  final List<String> _availableSubstitutes = [
    'Amit Chatterjee (Senior Science Faculty)',
    'Rajesh Verma (Mathematics Specialist)',
    'Priya Sharma (English & Humanities)',
    'Sunita Rao (Computer Applications & ICT)',
    'Vikram Malhotra (Physics Lab Supervisor)',
    'Ananya Sen (Administration & Accounts)',
  ];

  late Map<String, List<RoutinePeriodItem>> _scheduleMap;

  @override
  void initState() {
    super.initState();
    _rebuildSchedule();
  }

  @override
  void didUpdateWidget(covariant StaffClassRoutineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff.id != widget.staff.id) {
      _rebuildSchedule();
    }
  }

  void _rebuildSchedule() {
    final isTeaching = widget.staff.category == StaffCategory.teaching;
    final Map<String, List<RoutinePeriodItem>> map = {};

    if (isTeaching) {
      final timeSlots = [
        '09:00 AM - 09:45 AM',
        '09:50 AM - 10:35 AM',
        '10:40 AM - 11:25 AM',
        '11:30 AM - 12:15 PM',
        '12:20 PM - 01:05 PM',
      ];
      final rooms = ['Room 16', 'Room 10', 'Room 22', 'Science Lab 08', 'Computer Lab 25'];

      final defaultClasses = [
        ('Class: 1 (A)', 'Mathematics', 'Fundamental Algebra & Number Sense exercises'),
        ('Class: 2 (B)', 'English', 'Prose Comprehension & Applied Vocabulary lab'),
        ('Class: 3 (A)', 'Science', 'Experimental demonstration on Thermodynamics & Heat'),
        ('Class: 4 (C)', 'History', 'Modern Indian History & Architectural heritage debate'),
        ('Class: 5 (B)', 'Computer Science', 'Data structures algorithms & Python coding clinic'),
      ];

      for (int d = 0; d < _days.length; d++) {
        final day = _days[d];
        if (day == 'Sunday') {
          map[day] = [];
          continue;
        }

        final List<RoutinePeriodItem> periods = [];
        for (int p = 0; p < 5; p++) {
          final def = defaultClasses[(p + d) % defaultClasses.length];
          // Sample simulation: Wednesday 3rd period staff marked on leave to showcase alert and substitute flow
          final isDemoOnLeave = (day == 'Wednesday' && p == 2 && _selectedWeek == 1);
          periods.add(
            RoutinePeriodItem(
              id: 'per-$d-$p-$_selectedMonth-w$_selectedWeek',
              day: day,
              className: def.$1,
              subject: def.$2,
              purpose: def.$3,
              roomNo: rooms[p % rooms.length],
              time: timeSlots[p],
              status: isDemoOnLeave ? 'Staff on Leave' : 'Scheduled',
              substitutedBy: isDemoOnLeave ? 'Amit Chatterjee' : null,
              substituteNotes: isDemoOnLeave ? 'Assigned due to scheduled dental leave' : null,
            ),
          );
        }
        map[day] = periods;
      }
    } else {
      // Non-teaching duty schedule
      final dutySlots = [
        ('Shift: Morning', 'Facility Prep', 'Verification of equipment, safety roster & lab calibration', 'Desk 1', '08:00 AM - 10:30 AM'),
        ('Shift: Operations', widget.staff.department, 'Routine administrative operations, student queries & data entry', 'Station 4', '10:45 AM - 01:15 PM'),
        ('Shift: Afternoon', 'Inquiries & Admin', 'Counter clearance, fee registry audits & parent interaction hours', 'Main Bay', '02:00 PM - 04:30 PM'),
      ];

      for (int d = 0; d < _days.length; d++) {
        final day = _days[d];
        if (day == 'Sunday') {
          map[day] = [];
          continue;
        }

        final List<RoutinePeriodItem> periods = [];
        for (int p = 0; p < dutySlots.length; p++) {
          final slot = dutySlots[p];
          final isDemoOnLeave = (day == 'Thursday' && p == 1 && _selectedWeek == 2);
          periods.add(
            RoutinePeriodItem(
              id: 'duty-$d-$p-$_selectedMonth-w$_selectedWeek',
              day: day,
              className: slot.$1,
              subject: slot.$2,
              purpose: slot.$3,
              roomNo: slot.$4,
              time: slot.$5,
              status: isDemoOnLeave ? 'Staff on Leave' : 'Scheduled',
              substitutedBy: isDemoOnLeave ? 'Ananya Sen' : null,
            ),
          );
        }
        map[day] = periods;
      }
    }

    setState(() {
      _scheduleMap = map;
    });
  }

  // Column-wise palettes for each day of the week
  ({Color headerBg, Color headerText, Color cardBg, Color border}) _getDayPalette(String day, bool isDark) {
    if (isDark) {
      switch (day) {
        case 'Monday':
          return (headerBg: const Color(0xFF1E1B4B), headerText: const Color(0xFFA5B4FC), cardBg: const Color(0xFF0F172A), border: const Color(0xFF312E81));
        case 'Tuesday':
          return (headerBg: const Color(0xFF064E3B), headerText: const Color(0xFF6EE7B7), cardBg: const Color(0xFF0F172A), border: const Color(0xFF065F46));
        case 'Wednesday':
          return (headerBg: const Color(0xFF0C4A6E), headerText: const Color(0xFF7DD3FC), cardBg: const Color(0xFF0F172A), border: const Color(0xFF075985));
        case 'Thursday':
          return (headerBg: const Color(0xFF3B0764), headerText: const Color(0xFFD8B4FE), cardBg: const Color(0xFF0F172A), border: const Color(0xFF581C87));
        case 'Friday':
          return (headerBg: const Color(0xFF78350F), headerText: const Color(0xFFFDE68A), cardBg: const Color(0xFF0F172A), border: const Color(0xFF92400E));
        case 'Saturday':
          return (headerBg: const Color(0xFF881337), headerText: const Color(0xFFFECDD3), cardBg: const Color(0xFF0F172A), border: const Color(0xFF9F1239));
        case 'Sunday':
        default:
          return (headerBg: const Color(0xFF1E293B), headerText: const Color(0xFF94A3B8), cardBg: const Color(0xFF0F172A), border: const Color(0xFF334155));
      }
    } else {
      switch (day) {
        case 'Monday':
          return (headerBg: const Color(0xFFE0E7FF), headerText: const Color(0xFF3730A3), cardBg: const Color(0xFFEEF2FF), border: const Color(0xFFC7D2FE));
        case 'Tuesday':
          return (headerBg: const Color(0xFFCCFBF1), headerText: const Color(0xFF0F766E), cardBg: const Color(0xFFF0FDFA), border: const Color(0xFF99F6E4));
        case 'Wednesday':
          return (headerBg: const Color(0xFFE0F2FE), headerText: const Color(0xFF0369A1), cardBg: const Color(0xFFF0F9FF), border: const Color(0xFFBAE6FD));
        case 'Thursday':
          return (headerBg: const Color(0xFFF3E8FF), headerText: const Color(0xFF6B21A8), cardBg: const Color(0xFFFAF5FF), border: const Color(0xFFDDD6FE));
        case 'Friday':
          return (headerBg: const Color(0xFFFEF3C7), headerText: const Color(0xFFB45309), cardBg: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A));
        case 'Saturday':
          return (headerBg: const Color(0xFFFFE4E6), headerText: const Color(0xFFBE123C), cardBg: const Color(0xFFFFF1F2), border: const Color(0xFFFECDD3));
        case 'Sunday':
        default:
          return (headerBg: const Color(0xFFF1F5F9), headerText: const Color(0xFF475569), cardBg: const Color(0xFFF8FAFC), border: const Color(0xFFCBD5E1));
      }
    }
  }

  void _showStatusAndReassignDialog(RoutinePeriodItem period) {
    String currentStatus = period.status;
    String? selectedSub = period.substitutedBy;
    final subjectController = TextEditingController(text: period.subject);
    final purposeController = TextEditingController(text: period.purpose);
    final notesController = TextEditingController(text: period.substituteNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isOnLeave = currentStatus == 'Staff on Leave' || currentStatus == 'Staff Absent';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF109F83).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF109F83)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Work Schedule & Duty Purpose',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slot Context Banner (Fixed Time and Room Slot)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF109F83)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${period.day} • ${period.time} • ${period.className} • ${period.roomNo}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned Faculty: ${widget.staff.fullName} (${widget.staff.id})',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mutable Subject / Work Title
                    Row(
                      children: const [
                        Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF109F83)),
                        SizedBox(width: 6),
                        Text(
                          'Subject / Work Title',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('edit_routine_subject_input'),
                      controller: subjectController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Physics - Mechanics / Lab Supervision / Audit',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mutable Duty Purpose / Objective
                    Row(
                      children: const [
                        Icon(Icons.description_outlined, size: 14, color: Color(0xFF109F83)),
                        SizedBox(width: 6),
                        Text(
                          'Duty Purpose / Objective',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('edit_routine_purpose_input'),
                      controller: purposeController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe purpose of this work time (topic, duty notes, objective)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Update Status Section
                    const Text(
                      'Session Execution Status:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('edit_routine_status_dropdown'),
                      initialValue: currentStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled (Normal)')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'Staff on Leave', child: Text('Staff on Leave / Absent (Alert)')),
                        DropdownMenuItem(value: 'Substituted', child: Text('Substituted by Other Staff')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            currentStatus = val;
                          });
                        }
                      },
                    ),

                    if (isOnLeave || currentStatus == 'Substituted') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                SizedBox(width: 6),
                                Text(
                                  'Substitute Staff Reassignment Required',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Select an available faculty member from the department roster to take over this period:',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSub,
                              isExpanded: true,
                              hint: const Text('Select substitute teacher / staff...'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              items: _availableSubstitutes.map((s) {
                                return DropdownMenuItem(value: s.split(' (').first, child: Text(s, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedSub = val;
                                  if (val != null && currentStatus != 'Substituted') {
                                    currentStatus = 'Substituted';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: notesController,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Reassignment Notes / Instructions',
                                hintText: 'e.g., Substitute to cover Chapter 4 lab worksheet',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const ValueKey('edit_routine_save_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    final newSubject = subjectController.text.trim();
                    final newPurpose = purposeController.text.trim();
                    if (newSubject.isNotEmpty) {
                      period.subject = newSubject;
                    }
                    if (newPurpose.isNotEmpty) {
                      period.purpose = newPurpose;
                    }
                    period.status = currentStatus;
                    period.substitutedBy = selectedSub;
                    period.substituteNotes = notesController.text.trim().isNotEmpty ? notesController.text.trim() : null;
                  });
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Updated ${period.day} ${period.time} duty: "${period.subject}".'),
                      backgroundColor: const Color(0xFF109F83),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final isTeaching = widget.staff.category == StaffCategory.teaching;

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
          // Header Row with Title & Academic Year
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTeaching ? 'Staff Class Routine & Timetable' : 'Duty Schedule & Shift Roster',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Interactive weekly duty roster with column-wise day schedules, mutable work purpose, and substitute reassignment.',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
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
          const SizedBox(height: 16),

          // Two-Tier Filter Toolbar: Select Month, then Select Week
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                // Month Selector
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Select Month:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          dropdownColor: cardBg,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF109F83)),
                          items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMonth = val);
                              _rebuildSchedule();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Week Pills Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Week:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      for (int w = 1; w <= 4; w++) ...[
                        _buildWeekPill(w, _selectedWeek == w, widget.isDark),
                        if (w != 4) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Horizontal scrollable schedule grid for 7 days
          LayoutBuilder(
            builder: (context, constraints) {
              const double minGridWidth = 1120;
              final double gridWidth = constraints.maxWidth > minGridWidth ? constraints.maxWidth : minGridWidth;
              final double dayColWidth = (gridWidth - (6 * 10)) / 7;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: gridWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _days.map((day) {
                      final isSunday = day == 'Sunday';
                      final dayPeriods = _scheduleMap[day] ?? [];
                      final palette = _getDayPalette(day, widget.isDark);

                      return Container(
                        width: dayColWidth,
                        margin: EdgeInsets.only(right: day == _days.last ? 0 : 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Day Title Header with Day Color Badge
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              decoration: BoxDecoration(
                                color: palette.headerBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.border),
                              ),
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.headerText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (isSunday)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(Icons.weekend_outlined, size: 22, color: subColor),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Weekly Off',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...dayPeriods.map((period) => _buildPeriodCard(period, palette, borderColor, textColor, subColor)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekPill(int weekNum, bool isSelected, bool isDark) {
    const activeColor = Color(0xFF109F83);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return InkWell(
      onTap: () {
        setState(() => _selectedWeek = weekNum);
        _rebuildSchedule();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : borderColor),
        ),
        child: Text(
          'Week $weekNum',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard(
    RoutinePeriodItem period,
    ({Color headerBg, Color headerText, Color cardBg, Color border}) palette,
    Color defaultBorder,
    Color textColor,
    Color subColor,
  ) {
    final isOnLeave = period.status == 'Staff on Leave' || period.status == 'Staff Absent';
    final isSubstituted = period.status == 'Substituted' || period.substitutedBy != null;

    // Custom alert styling if staff is on leave
    final cardBg = isOnLeave
        ? (widget.isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
        : (isSubstituted
            ? (widget.isDark ? const Color(0xFF3B1D0B) : const Color(0xFFFFFBEB))
            : palette.cardBg);

    final cardBorder = isOnLeave
        ? const Color(0xFFEF4444)
        : (isSubstituted ? const Color(0xFFF59E0B) : palette.border);

    final bannerBg = isOnLeave
        ? const Color(0xFFFEE2E2)
        : (isSubstituted ? const Color(0xFFFEF3C7) : palette.headerBg);

    final bannerText = isOnLeave
        ? const Color(0xFFDC2626)
        : (isSubstituted ? const Color(0xFFB45309) : palette.headerText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder, width: isOnLeave ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusAndReassignDialog(period),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column-wise Day Header Banner with Class & Status Tag
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: bannerBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        period.className,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: bannerText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOnLeave)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ON LEAVE',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      )
                    else if (isSubstituted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SUBSTITUTED',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Field
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 13, color: palette.headerText),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            period.subject,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Dedicated Purpose Field (Mutable assigned duty purpose)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cardBorder.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 11, color: subColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Subject / Purpose',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: subColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              Icon(Icons.mode_edit_outline, size: 9, color: subColor.withValues(alpha: 0.6)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            period.purpose,
                            style: TextStyle(fontSize: 9.5, color: textColor.withValues(alpha: 0.9), fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Room & Time
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 12, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            period.roomNo,
                            style: TextStyle(fontSize: 10, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 12, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            period.time,
                            style: TextStyle(fontSize: 9.5, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Substitute Info or Action Button
                    if (isSubstituted && period.substitutedBy != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_outlined, size: 11, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Sub: ${period.substitutedBy}',
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isOnLeave) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1_outlined, size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Reassign Staff',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

