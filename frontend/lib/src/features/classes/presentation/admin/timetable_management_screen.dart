import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/timetable_controller.dart';
import '../../domain/classes_actor.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

const List<String> kWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

const List<String> kMonths = [
  'All Months',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String format24hTimeWithAmPm(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }
  return hhmm;
}

TimeOfDay parse24hTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String timeOfDayTo24h(TimeOfDay tod) {
  return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
}

class TimetablePeriodSlot {
  final int periodNumber;
  final String startTime;
  final String endTime;
  final bool isBreak;
  final String label;

  const TimetablePeriodSlot({
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    required this.label,
  });
}

const List<TimetablePeriodSlot> kStandardSlots = [
  TimetablePeriodSlot(periodNumber: 1, startTime: '08:00', endTime: '08:45', label: '1\n08:00 - 08:45 AM'),
  TimetablePeriodSlot(periodNumber: 2, startTime: '08:45', endTime: '09:30', label: '2\n08:45 - 09:30 AM'),
  TimetablePeriodSlot(periodNumber: 3, startTime: '09:30', endTime: '10:15', label: '3\n09:30 - 10:15 AM'),
  TimetablePeriodSlot(periodNumber: 0, startTime: '10:15', endTime: '10:30', isBreak: true, label: 'Break\n10:15 - 10:30 AM'),
  TimetablePeriodSlot(periodNumber: 4, startTime: '10:30', endTime: '11:15', label: '4\n10:30 - 11:15 AM'),
  TimetablePeriodSlot(periodNumber: 5, startTime: '11:15', endTime: '12:00', label: '5\n11:15 AM - 12:00 PM'),
  TimetablePeriodSlot(periodNumber: 0, startTime: '12:00', endTime: '12:40', isBreak: true, label: 'Lunch Break\n12:00 - 12:40 PM'),
  TimetablePeriodSlot(periodNumber: 6, startTime: '12:40', endTime: '13:25', label: '6\n12:40 - 01:25 PM'),
  TimetablePeriodSlot(periodNumber: 7, startTime: '13:25', endTime: '14:10', label: '7\n01:25 - 02:10 PM'),
];

/// Timetable Management Screen:
/// Responsive layout using available screen width, Table / Timetable toggle,
/// Add Period with Day, Month, AM/PM time selection (up to midnight),
/// Class Subjects dropdown, Teachers dropdown, Classrooms dropdown,
/// and duplicate/overlap validation.
class TimetableManagementScreen extends ConsumerStatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  ConsumerState<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends ConsumerState<TimetableManagementScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String _selectedTerm = 'Term 1 (2026-27)';
  String _selectedMonthFilter = 'All Months';
  bool _isTimetableView = true; // true = Timetable Grid, false = Table View
  final TextEditingController _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tableSearchController.addListener(() {
      setState(() {
        _tableSearchQuery = _tableSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tableSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final timetableAsync = ref.watch(timetableControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default class/section
    if (_selectedClassId == null && lookup.classes.isNotEmpty) {
      final cls10 = lookup.classes.where((c) => c.name.toLowerCase().contains('tenth') || c.name.contains('10'));
      _selectedClassId = cls10.isNotEmpty ? cls10.first.id : lookup.classes.first.id;
    }
    final sectionsForClass = lookup.sections.where((s) => s.classId == _selectedClassId).toList();
    if (_selectedSectionId == null && sectionsForClass.isNotEmpty) {
      _selectedSectionId = sectionsForClass.first.id;
    } else if (sectionsForClass.isNotEmpty && !sectionsForClass.any((s) => s.id == _selectedSectionId)) {
      _selectedSectionId = sectionsForClass.first.id;
    }

    final selectedClassName = lookup.className(_selectedClassId);
    final selectedSectionName = lookup.sectionName(_selectedSectionId);

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar: Title + Subtitle + Controls
                _buildTopBar(
                  lookup: lookup,
                  selectedClassName: selectedClassName,
                  selectedSectionName: selectedSectionName,
                  isDark: isDark,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),

                // 5 Metric Cards
                _buildMetricCardsRow(lookup, isDark, isMobile, screenWidth),
                const SizedBox(height: 16),

                // View Toggle + Color Legend
                _buildLegendAndToggleRow(isDark, isMobile),
                const SizedBox(height: 14),

                // Main Timetable Content (Grid or Table)
                timetableAsync.when(
                  data: (entries) {
                    if (_isTimetableView) {
                      return _buildTimetableGrid(
                        entries: entries,
                        lookup: lookup,
                        isDark: isDark,
                        isMobile: isMobile,
                        screenWidth: screenWidth,
                      );
                    } else {
                      return _buildTimetableTableView(
                        entries: entries,
                        lookup: lookup,
                        isDark: isDark,
                        isMobile: isMobile,
                        screenWidth: screenWidth,
                      );
                    }
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar({
    required ClassesLookup lookup,
    required String selectedClassName,
    required String selectedSectionName,
    required bool isDark,
    required bool isMobile,
  }) {
    final perms = ref.watch(classesPermissionsProvider);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      spacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Timetable',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Visual schedule & period allocation for $selectedClassName - $selectedSectionName',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Class Dropdown
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isDense: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: lookup.classes.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedClassId = v;
                        final secs = lookup.sections.where((s) => s.classId == v).toList();
                        _selectedSectionId = secs.isNotEmpty ? secs.first.id : null;
                      });
                    }
                  },
                ),
              ),
            ),

            // Month Filter
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonthFilter,
                  isDense: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: kMonths.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMonthFilter = v);
                  },
                ),
              ),
            ),

            // Term Selector
            if (!isMobile)
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTerm,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Term 1 (2026-27)', child: Text('Term 1 (2026-27)')),
                      DropdownMenuItem(value: 'Term 2 (2026-27)', child: Text('Term 2 (2026-27)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTerm = v);
                    },
                  ),
                ),
              ),

            // Add Period Button
            if (perms.canManageTimetable)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _openPeriodModal(context, ref, lookup),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCardsRow(ClassesLookup lookup, bool isDark, bool isMobile, double screenWidth) {
    final cardWidth = (screenWidth - (isMobile ? 24 : 64) - (isMobile ? 16 : 32)) / (isMobile ? 2 : 5);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatCard(
          title: 'Total Periods',
          value: '42',
          subtitle: 'Per Week',
          icon: Icons.menu_book_outlined,
          iconColor: const Color(0xFF10B981),
          width: cardWidth,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Total Teachers',
          value: '${lookup.teachers.length}',
          subtitle: 'Available',
          icon: Icons.person_outline,
          iconColor: const Color(0xFF8B5CF6),
          width: cardWidth,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Total Rooms',
          value: '${lookup.classrooms.length}',
          subtitle: 'In Use',
          icon: Icons.door_front_door_outlined,
          iconColor: const Color(0xFF3B82F6),
          width: cardWidth,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Subjects Configured',
          value: '${lookup.subjects.length}',
          subtitle: 'From Subjects',
          icon: Icons.subject_rounded,
          iconColor: const Color(0xFFF97316),
          width: cardWidth,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Operating Hours',
          value: '08:00 AM - 11:59 PM',
          subtitle: 'Full Day Coverage',
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF10B981),
          width: cardWidth,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendAndToggleRow(bool isDark, bool isMobile) {
    return Row(
      children: [
        // View: Table | Timetable
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewToggleButton(
                label: 'Timetable Grid',
                isSelected: _isTimetableView,
                onTap: () => setState(() => _isTimetableView = true),
                isDark: isDark,
              ),
              _buildViewToggleButton(
                label: 'Table View',
                isSelected: !_isTimetableView,
                onTap: () => setState(() => _isTimetableView = false),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Legend on right
        if (!isMobile)
          Wrap(
            spacing: 12,
            children: [
              _buildLegendDot(const Color(0xFF10B981), 'Lecture'),
              _buildLegendDot(const Color(0xFF3B82F6), 'Lab'),
              _buildLegendDot(const Color(0xFFA855F7), 'Activity'),
              _buildLegendDot(Colors.grey.shade400, 'Break'),
              _buildLegendDot(const Color(0xFFF97316), 'Evening / Special'),
            ],
          ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF109F83) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
      ],
    );
  }

  /// Timetable Visual Grid
  Widget _buildTimetableGrid({
    required List<TimetableEntryModel> entries,
    required ClassesLookup lookup,
    required bool isDark,
    required bool isMobile,
    required double screenWidth,
  }) {
    final perms = ref.watch(classesPermissionsProvider);

    // Filter entries by current class and optional month
    final filtered = entries.where((e) {
      if (_selectedClassId != null && e.classId != _selectedClassId) return false;
      if (_selectedMonthFilter != 'All Months' && e.month != null && e.month != _selectedMonthFilter) {
        return false;
      }
      return true;
    }).toList();

    // Dynamically incorporate custom time slots (e.g. evening or night periods up to midnight)
    final allSlots = <TimetablePeriodSlot>[...kStandardSlots];
    for (final e in filtered) {
      if (!allSlots.any((s) => s.startTime == e.startTime)) {
        allSlots.add(TimetablePeriodSlot(
          periodNumber: allSlots.length + 1,
          startTime: e.startTime,
          endTime: e.endTime,
          label: '${format24hTimeWithAmPm(e.startTime)}\n-\n${format24hTimeWithAmPm(e.endTime)}',
        ));
      }
    }
    allSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    final tableMinWidth = (screenWidth - (isMobile ? 48 : 80)).clamp(950.0, 2400.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableMinWidth),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(130), // Time / Day column with AM/PM
              1: FlexColumnWidth(1),    // Monday
              2: FlexColumnWidth(1),    // Tuesday
              3: FlexColumnWidth(1),    // Wednesday
              4: FlexColumnWidth(1),    // Thursday
              5: FlexColumnWidth(1),    // Friday
              6: FlexColumnWidth(1),    // Saturday
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              verticalInside: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                ),
                children: [
                  _buildHeaderCell('Time / Day', isDark),
                  for (final d in kWeekdays) _buildHeaderCell(d, isDark),
                ],
              ),
              // Slot Rows
              for (final slot in allSlots)
                if (slot.isBreak)
                  _buildBreakRow(slot, isDark)
                else
                  _buildPeriodRow(
                    slot: slot,
                    entries: filtered,
                    lookup: lookup,
                    perms: perms,
                    isDark: isDark,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  TableRow _buildBreakRow(TimetablePeriodSlot slot, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            slot.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
        for (int i = 0; i < 6; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: Text(
              slot.periodNumber == 0 ? (slot.startTime == '12:00' ? 'Lunch Break' : 'Break') : 'Break',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  TableRow _buildPeriodRow({
    required TimetablePeriodSlot slot,
    required List<TimetableEntryModel> entries,
    required ClassesLookup lookup,
    required ClassesPermissions perms,
    required bool isDark,
  }) {
    return TableRow(
      children: [
        // Time Slot Column
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            slot.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        // Days 1 through 6
        for (int day = 1; day <= 6; day++)
          _buildDayCell(
            day: day,
            slot: slot,
            entries: entries,
            lookup: lookup,
            perms: perms,
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildDayCell({
    required int day,
    required TimetablePeriodSlot slot,
    required List<TimetableEntryModel> entries,
    required ClassesLookup lookup,
    required ClassesPermissions perms,
    required bool isDark,
  }) {
    final matches = entries.where((e) {
      if (e.dayOfWeek != day) return false;
      return e.startTime == slot.startTime;
    }).toList();

    if (matches.isEmpty) {
      return InkWell(
        onTap: perms.canManageTimetable
            ? () => _openPeriodModal(
                  context,
                  ref,
                  lookup,
                  defaultDay: day,
                  defaultStart: slot.startTime,
                  defaultEnd: slot.endTime,
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
        ),
      );
    }

    final entry = matches.first;
    final subjectName = lookup.subjectName(entry.subjectId);
    final teacherName = lookup.teacherName(entry.teacherId);
    final roomName = lookup.roomName(entry.classroomId);

    Color cellBg;
    Color borderColor;
    Color textColor;

    final subLower = subjectName.toLowerCase();
    if (subLower.contains('physics') || subLower.contains('chemistry') || subLower.contains('biology') || subLower.contains('computer')) {
      // Lab
      cellBg = isDark ? const Color(0xFF0C243B) : const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF93C5FD);
      textColor = const Color(0xFF2563EB);
    } else if (subLower.contains('physical') || subLower.contains('art') || subLower.contains('music')) {
      // Activity
      cellBg = isDark ? const Color(0xFF2E1065) : const Color(0xFFFAF5FF);
      borderColor = const Color(0xFFD8B4FE);
      textColor = const Color(0xFF9333EA);
    } else {
      // Lecture (green)
      cellBg = isDark ? const Color(0xFF0F2922) : const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF16A34A);
    }

    return InkWell(
      onTap: perms.canManageTimetable
          ? () => _openPeriodModal(context, ref, lookup, existing: entry)
          : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subjectName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              teacherName,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              roomName,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Table View for Timetable: Clean, centered smaller search bar, responsive DataTable
  Widget _buildTimetableTableView({
    required List<TimetableEntryModel> entries,
    required ClassesLookup lookup,
    required bool isDark,
    required bool isMobile,
    required double screenWidth,
  }) {
    final perms = ref.watch(classesPermissionsProvider);

    final filtered = entries.where((e) {
      if (_selectedClassId != null && e.classId != _selectedClassId) return false;
      if (_selectedMonthFilter != 'All Months' && e.month != null && e.month != _selectedMonthFilter) {
        return false;
      }
      if (_tableSearchQuery.isEmpty) return true;
      final q = _tableSearchQuery;
      final sub = lookup.subjectName(e.subjectId).toLowerCase();
      final tch = lookup.teacherName(e.teacherId).toLowerCase();
      final room = lookup.roomName(e.classroomId).toLowerCase();
      final day = (e.dayOfWeek >= 1 && e.dayOfWeek <= 6) ? kWeekdays[e.dayOfWeek - 1].toLowerCase() : '';
      return sub.contains(q) || tch.contains(q) || room.contains(q) || day.contains(q);
    }).toList();

    final searchBox = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _tableSearchController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search periods...',
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
            suffixIcon: _tableSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
                    onPressed: () => _tableSearchController.clear(),
                  )
                : null,
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );

    final tableMinWidth = (screenWidth - (isMobile ? 48 : 80)).clamp(850.0, 2400.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table search row centered
          Row(
            children: [
              const Text('Timetable Periods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Expanded(
                child: Center(child: searchBox),
              ),
            ],
          ),
          const Divider(height: 24),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No periods found for the selected filters.', style: TextStyle(color: Colors.grey)),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: tableMinWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                      horizontalMargin: 14,
                      columnSpacing: 18,
                      headingRowHeight: 40,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 64,
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                      columns: const [
                        DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Time Slot (AM/PM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Classroom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                      rows: filtered.map((e) {
                        final dayName = (e.dayOfWeek >= 1 && e.dayOfWeek <= 6) ? kWeekdays[e.dayOfWeek - 1] : 'Monday';
                        final timeDisplay = '${format24hTimeWithAmPm(e.startTime)} - ${format24hTimeWithAmPm(e.endTime)}';

                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF109F83).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dayName,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                timeDisplay,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              Text(
                                lookup.subjectName(e.subjectId),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                lookup.teacherName(e.teacherId),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                lookup.roomName(e.classroomId),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            DataCell(
                              Text(
                                e.month ?? 'All Months',
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ),
                            DataCell(
                              perms.canManageTimetable
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          tooltip: 'Edit Period',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openPeriodModal(context, ref, lookup, existing: e),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                          tooltip: 'Delete Period',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () async {
                                            if (await confirmDelete(context, 'this period')) {
                                              if (!mounted) return;
                                              await runClassesAction(
                                                context,
                                                () => ref.read(timetableControllerProvider.notifier).delete(e.id),
                                                success: 'Period deleted successfully',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : const Text('—', style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Inline modal form to add or edit timetable period with clear AM/PM indicators
  Future<void> _openPeriodModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    TimetableEntryModel? existing,
    int? defaultDay,
    String? defaultStart,
    String? defaultEnd,
  }) async {
    var classId = existing?.classId ?? _selectedClassId ?? (lookup.classes.isNotEmpty ? lookup.classes.first.id : '');
    final sectionsForClass = lookup.sections.where((s) => s.classId == classId).toList();
    var sectionId = existing?.sectionId ?? (sectionsForClass.isNotEmpty ? sectionsForClass.first.id : (lookup.sections.isNotEmpty ? lookup.sections.first.id : ''));

    final subjectsForClass = lookup.subjects.where((s) => s.classId == classId).toList();
    var subjectId = existing?.subjectId ?? (subjectsForClass.isNotEmpty ? subjectsForClass.first.id : (lookup.subjects.isNotEmpty ? lookup.subjects.first.id : ''));

    String? teacherId = existing?.teacherId ?? (lookup.teachers.isNotEmpty ? lookup.teachers.first.id : null);
    String? roomId = existing?.classroomId ?? (lookup.classrooms.isNotEmpty ? lookup.classrooms.first.id : null);
    int dayOfWeek = existing?.dayOfWeek ?? (defaultDay ?? 1);
    String selectedMonth = existing?.month ?? (_selectedMonthFilter != 'All Months' ? _selectedMonthFilter : 'All Months');

    TimeOfDay startTimeOfDay = parse24hTime(existing?.startTime ?? (defaultStart ?? '08:00'));
    TimeOfDay endTimeOfDay = parse24hTime(existing?.endTime ?? (defaultEnd ?? '08:45'));
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentSubjects = lookup.subjects.where((s) => s.classId == classId).toList();
          final availableSubjects = currentSubjects.isNotEmpty ? currentSubjects : lookup.subjects;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add_circle_outline : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'Add Timetable Period' : 'Edit Period',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          formError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Class and Section Selection
                    Row(
                      children: [
                        // Class
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: lookup.classes.any((c) => c.id == classId) ? classId : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: lookup.classes.map((c) {
                                  return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() {
                                      classId = v;
                                      final secs = lookup.sections.where((s) => s.classId == v).toList();
                                      if (secs.isNotEmpty) sectionId = secs.first.id;
                                      final subs = lookup.subjects.where((s) => s.classId == v).toList();
                                      if (subs.isNotEmpty) {
                                        subjectId = subs.first.id;
                                        if (subs.first.teacherId != null) teacherId = subs.first.teacherId;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: lookup.sections.any((s) => s.id == sectionId) ? sectionId : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: (sectionsForClass.isNotEmpty ? sectionsForClass : lookup.sections).map((s) {
                                  return DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => sectionId = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Day of Week and Month
                    Row(
                      children: [
                        // Day of Week
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Day of Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                initialValue: dayOfWeek,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: [1, 2, 3, 4, 5, 6].map((d) {
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text(kWeekdays[d - 1], style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => dayOfWeek = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Month (if required)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Month (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: selectedMonth,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: kMonths.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(m, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => selectedMonth = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time Selection with AM/PM Indicators (supporting slots up to midnight)
                    const Text(
                      'Period Operating Hours (AM/PM)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Start Time Selector
                        Expanded(
                          child: _buildTimePickerTile(
                            context: ctx,
                            label: 'Start Time',
                            time: startTimeOfDay,
                            onChanged: (newTod) => setDialogState(() => startTimeOfDay = newTod),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // End Time Selector
                        Expanded(
                          child: _buildTimePickerTile(
                            context: ctx,
                            label: 'End Time',
                            time: endTimeOfDay,
                            onChanged: (newTod) => setDialogState(() => endTimeOfDay = newTod),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Subject Dropdown: Displays subjects created in Class Subjects module
                    const Text('Subject (from Class Subjects)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: availableSubjects.any((s) => s.id == subjectId)
                          ? subjectId
                          : (availableSubjects.isNotEmpty ? availableSubjects.first.id : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: availableSubjects.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (${lookup.className(s.classId)})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            subjectId = v;
                            final s = availableSubjects.firstWhere((sub) => sub.id == v);
                            classId = s.classId;
                            if (s.teacherId != null && s.teacherId!.isNotEmpty) {
                              teacherId = s.teacherId;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Teacher Dropdown: Displays available teachers
                    const Text('Assigned Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: lookup.teachers.any((t) => t.id == teacherId) ? teacherId : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: lookup.teachers.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => teacherId = v),
                    ),
                    const SizedBox(height: 12),

                    // Classroom Dropdown: Displays available classrooms
                    const Text('Classroom / Room Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: lookup.classrooms.any((r) => r.id == roomId) ? roomId : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: lookup.classrooms.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text('${r.name} (${r.building})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => roomId = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
                onPressed: () async {
                  final start24 = timeOfDayTo24h(startTimeOfDay);
                  final end24 = timeOfDayTo24h(endTimeOfDay);

                  if (start24.compareTo(end24) >= 0) {
                    setDialogState(() => formError = 'End time must be after start time.');
                    return;
                  }

                  try {
                    final model = TimetableEntryModel(
                      id: existing?.id ?? '',
                      classId: classId,
                      sectionId: sectionId,
                      subjectId: subjectId,
                      teacherId: teacherId ?? '',
                      classroomId: roomId,
                      dayOfWeek: dayOfWeek,
                      startTime: start24,
                      endTime: end24,
                      month: selectedMonth != 'All Months' ? selectedMonth : null,
                    );
                    await ref.read(timetableControllerProvider.notifier).save(
                          model,
                          isNew: existing == null,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Period scheduled successfully' : 'Period updated successfully'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e.toString().replaceAll('Exception:', '').replaceAll('ClassesDataException:', '').trim();
                    });
                  }
                },
                child: Text(existing == null ? 'Schedule' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Interactive Time Selector Tile with explicit AM/PM indicator and native clock picker
  Widget _buildTimePickerTile({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    final formatted = format24hTimeWithAmPm(timeOfDayTo24h(time));
    final isPm = time.period == DayPeriod.pm;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              const Spacer(),
              // AM / PM toggle chip
              InkWell(
                onTap: () {
                  final newHour = isPm ? (time.hour - 12).clamp(0, 23) : (time.hour + 12).clamp(0, 23);
                  onChanged(TimeOfDay(hour: newHour, minute: time.minute));
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPm ? const Color(0xFFF97316).withValues(alpha: 0.15) : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPm ? 'PM' : 'AM',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isPm ? const Color(0xFFC2410C) : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF109F83)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatted,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
