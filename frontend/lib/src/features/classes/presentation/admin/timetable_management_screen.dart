import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/timetable_controller.dart';
import '../../application/subjects_controller.dart';
import '../../domain/class_model.dart';
import '../../domain/classes_actor.dart';
import '../../domain/subject_model.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

const List<String> kWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

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
  TimetablePeriodSlot(
    periodNumber: 1,
    startTime: '08:00',
    endTime: '08:45',
    label: '1\n08:00 - 08:45 AM',
  ),
  TimetablePeriodSlot(
    periodNumber: 2,
    startTime: '08:45',
    endTime: '09:30',
    label: '2\n08:45 - 09:30 AM',
  ),
  TimetablePeriodSlot(
    periodNumber: 3,
    startTime: '09:30',
    endTime: '10:15',
    label: '3\n09:30 - 10:15 AM',
  ),
  TimetablePeriodSlot(
    periodNumber: 0,
    startTime: '10:15',
    endTime: '10:30',
    isBreak: true,
    label: 'Break\n10:15 - 10:30 AM',
  ),
  TimetablePeriodSlot(
    periodNumber: 4,
    startTime: '10:30',
    endTime: '11:15',
    label: '4\n10:30 - 11:15 AM',
  ),
  TimetablePeriodSlot(
    periodNumber: 5,
    startTime: '11:15',
    endTime: '12:00',
    label: '5\n11:15 AM - 12:00 PM',
  ),
  TimetablePeriodSlot(
    periodNumber: 0,
    startTime: '12:00',
    endTime: '12:40',
    isBreak: true,
    label: 'Lunch\n12:00 - 12:40 PM',
  ),
  TimetablePeriodSlot(
    periodNumber: 6,
    startTime: '12:40',
    endTime: '13:25',
    label: '6\n12:40 - 01:25 PM',
  ),
  TimetablePeriodSlot(
    periodNumber: 7,
    startTime: '13:25',
    endTime: '14:10',
    label: '7\n01:25 - 02:10 PM',
  ),
];

/// Timetable Management Screen:
/// Responsive layout using available screen width, Table / Timetable toggle,
/// Add Period with Day, Month, AM/PM time selection (up to midnight),
/// Class Subjects dropdown, Teachers dropdown, Classrooms dropdown,
/// and duplicate/overlap validation.
class TimetableManagementScreen extends ConsumerStatefulWidget {
  /// When [embedded] (e.g. inside Class Details) the screen is locked to [initialClassId],
  /// hides its own class picker / metric cards and lets the parent handle scrolling.
  final String? initialClassId;
  final String? initialSectionId;
  final bool lockSection;
  final bool embedded;
  const TimetableManagementScreen({
    super.key,
    this.initialClassId,
    this.initialSectionId,
    this.lockSection = false,
    this.embedded = false,
  });

  @override
  ConsumerState<TimetableManagementScreen> createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState
    extends ConsumerState<TimetableManagementScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedYear; // Academic year; always follows the selected class
  String _selectedMonthFilter = 'All Months';
  bool _isTimetableView = true; // true = Timetable Grid, false = Table View
  final TextEditingController _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _selectedSectionId = widget.initialSectionId;
    _tableSearchController.addListener(() {
      setState(() {
        _tableSearchQuery = _tableSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant TimetableManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialClassId != null && widget.initialClassId != _selectedClassId) {
      setState(() => _selectedClassId = widget.initialClassId);
    }
    if (widget.initialSectionId != null && widget.initialSectionId != _selectedSectionId) {
      setState(() => _selectedSectionId = widget.initialSectionId);
    }
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

    // Default class/section (limited to the selected academic year)
    if (_selectedClassId == null && lookup.classes.isNotEmpty) {
      final inYear = _classesForYear(lookup, _selectedYear);
      final pool = inYear.isNotEmpty ? inYear : lookup.classes;
      final cls10 = pool.where(
        (c) => c.name.toLowerCase().contains('tenth') || c.name.contains('10'),
      );
      _selectedClassId = cls10.isNotEmpty ? cls10.first.id : pool.first.id;
    }
    // The academic year always follows the selected class.
    final currentClass = lookup.classes
        .where((c) => c.id == _selectedClassId)
        .firstOrNull;
    if (currentClass != null && currentClass.academicYear.trim().isNotEmpty) {
      _selectedYear = currentClass.academicYear.trim();
    }
    _selectedYear ??= _academicYearOptions(lookup).first;
    if (widget.lockSection && widget.initialSectionId != null) {
      _selectedSectionId = widget.initialSectionId;
    } else {
      final sectionsForClass = lookup.sections
          .where((s) => s.classId == _selectedClassId)
          .toList();
      if (_selectedSectionId == null && sectionsForClass.isNotEmpty) {
        _selectedSectionId = sectionsForClass.first.id;
      } else if (sectionsForClass.isNotEmpty &&
          !sectionsForClass.any((s) => s.id == _selectedSectionId)) {
        _selectedSectionId = sectionsForClass.first.id;
      }
    }

    final selectedClassName = lookup.className(_selectedClassId);
    final selectedSectionName = lookup.sectionName(_selectedSectionId);

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          final body = Column(
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
              if (!widget.embedded) ...[
                _buildMetricCardsRow(
                  lookup,
                  timetableAsync.valueOrNull ?? const [],
                  isDark,
                  isMobile,
                  screenWidth,
                ),
                const SizedBox(height: 16),
              ],

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
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          );
          if (widget.embedded) return body;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: body,
          );
        },
      ),
    );
  }

  /// Academic years that exist on the created classes (fallback: 2026-2027).
  List<String> _academicYearOptions(ClassesLookup lookup) {
    final years = <String>{
      for (final c in lookup.classes)
        if (c.academicYear.trim().isNotEmpty) c.academicYear.trim(),
    }.toList()
      ..sort();
    if (_selectedYear != null && !years.contains(_selectedYear)) {
      years.add(_selectedYear!);
    }
    return years.isEmpty ? ['2026-2027'] : years;
  }

  List<ClassModel> _classesForYear(ClassesLookup lookup, String? year) =>
      lookup.classes
          .where(
            (c) =>
                year == null ||
                c.academicYear.trim().isEmpty ||
                c.academicYear.trim() == year,
          )
          .toList();

  Widget _buildDropdownBox({
    required bool isDark,
    required Widget child,
  }) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: DropdownButtonHideUnderline(child: child),
  );

  /// "Class Teacher" chip for the selected class + section. The section's own
  /// class teacher wins; otherwise the class-level teacher is shown.
  Widget _buildClassTeacherChip(
    ClassesLookup lookup,
    bool isDark,
    bool isMobile,
  ) {
    final cls = lookup.classes
        .where((c) => c.id == _selectedClassId)
        .firstOrNull;
    final sec = lookup.sections
        .where((s) => s.id == _selectedSectionId)
        .firstOrNull;
    final sectionTeacher = sec?.classTeacherId;
    final tid = (sectionTeacher != null && sectionTeacher.isNotEmpty)
        ? sectionTeacher
        : cls?.classTeacherId;
    final assigned = tid != null && tid.isNotEmpty;
    final teacher = lookup.teacherById(tid);
    final details = [
      if (teacher != null && teacher.phone.isNotEmpty) teacher.phone,
      if (teacher != null && teacher.email.isNotEmpty) teacher.email,
    ].join('  |  ');
    final accent = assigned ? const Color(0xFF109F83) : const Color(0xFF94A3B8);

    final chip = Container(
      height: 34,
      constraints: BoxConstraints(maxWidth: isMobile ? 300 : 360),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 15, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              assigned
                  ? 'Class Teacher: ${lookup.teacherName(tid)}'
                  : 'Class Teacher: Not assigned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
    return details.isEmpty ? chip : Tooltip(message: details, child: chip);
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
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Academic Year (the class list below follows the selected year)
            if (!widget.embedded)
              _buildDropdownBox(
                isDark: isDark,
                child: DropdownButton<String>(
                  value: _selectedYear,
                  isDense: true,
                  hint: const Text('Academic Year', style: TextStyle(fontSize: 12)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: _academicYearOptions(lookup)
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedYear = v;
                      final inYear = _classesForYear(lookup, v);
                      _selectedClassId = inYear.isNotEmpty
                          ? inYear.first.id
                          : null;
                      final secs = lookup.sections
                          .where((s) => s.classId == _selectedClassId)
                          .toList();
                      _selectedSectionId = secs.isNotEmpty
                          ? secs.first.id
                          : null;
                    });
                  },
                ),
              ),

            // Class Dropdown (classes of the selected academic year)
            if (!widget.embedded)
              _buildDropdownBox(
                isDark: isDark,
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  isDense: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: _classesForYear(lookup, _selectedYear).map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedClassId = v;
                        final secs = lookup.sections
                            .where((s) => s.classId == v)
                            .toList();
                        _selectedSectionId = secs.isNotEmpty
                            ? secs.first.id
                            : null;
                      });
                    }
                  },
                ),
              ),

            // Section Dropdown (A / B / C ... of the selected class)
            if (!widget.lockSection)
              Builder(
                builder: (_) {
                  final secs = lookup.sections
                      .where((s) => s.classId == _selectedClassId)
                      .toList();
                  if (secs.isEmpty) {
                    return Text(
                      'No sections',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    );
                  }
                  return _buildDropdownBox(
                    isDark: isDark,
                    child: DropdownButton<String>(
                      value: secs.any((s) => s.id == _selectedSectionId)
                          ? _selectedSectionId
                          : secs.first.id,
                      isDense: true,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      items: secs
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('Section ${s.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSectionId = v);
                      },
                    ),
                  );
                },
              ),

            // Class Teacher of the selected class / section
            _buildClassTeacherChip(lookup, isDark, isMobile),

            // Month Filter
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
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

            // Add Period Button
            if (perms.canManageTimetable)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add Period',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openPeriodModal(
                  context,
                  ref,
                  lookup,
                  presetClassId: _selectedClassId,
                  presetSectionId: _selectedSectionId,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCardsRow(
    ClassesLookup lookup,
    List<TimetableEntryModel> entries,
    bool isDark,
    bool isMobile,
    double screenWidth,
  ) {
    final cardWidth =
        (screenWidth - (isMobile ? 24 : 64) - (isMobile ? 16 : 32)) /
        (isMobile ? 2 : 5);
    final periods = entries.where((entry) => !entry.isBreak).toList();
    final operatingHours = periods.isEmpty
        ? 'No periods scheduled'
        : '${format24hTimeWithAmPm(periods.map((entry) => entry.startTime).reduce((a, b) => a.compareTo(b) < 0 ? a : b))} - '
              '${format24hTimeWithAmPm(periods.map((entry) => entry.endTime).reduce((a, b) => a.compareTo(b) > 0 ? a : b))}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatCard(
          title: 'Total Periods',
          value: '${periods.length}',
          subtitle: 'Scheduled',
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
          subtitle: 'Configured',
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
          value: operatingHours,
          subtitle: 'Scheduled Hours',
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
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
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
      if (_selectedClassId != null && e.classId != _selectedClassId) {
        return false;
      }
      if (_selectedSectionId != null &&
          _selectedSectionId!.isNotEmpty &&
          e.sectionId.isNotEmpty &&
          e.sectionId != _selectedSectionId) {
        return false;
      }
      if (_selectedMonthFilter != 'All Months' &&
          e.month != null &&
          e.month != _selectedMonthFilter) {
        return false;
      }
      return true;
    }).toList();

    // Dynamically incorporate custom time slots (e.g. evening or night periods up to midnight)
    final allSlots = <TimetablePeriodSlot>[...kStandardSlots];
    for (final entry in filtered.where((entry) => entry.isBreak)) {
      if (allSlots.any(
        (slot) => slot.isBreak && slot.startTime == entry.startTime,
      )) {
        continue;
      }
      allSlots.add(
        TimetablePeriodSlot(
          periodNumber: 0,
          startTime: entry.startTime,
          endTime: entry.endTime,
          isBreak: true,
          label:
              '${entry.title ?? 'Break'}\n${format24hTimeWithAmPm(entry.startTime)} - ${format24hTimeWithAmPm(entry.endTime)}',
        ),
      );
    }
    for (final e in filtered.where((entry) => !entry.isBreak)) {
      if (!allSlots.any((s) => s.startTime == e.startTime)) {
        allSlots.add(
          TimetablePeriodSlot(
            periodNumber: allSlots.length + 1,
            startTime: e.startTime,
            endTime: e.endTime,
            label:
                '${format24hTimeWithAmPm(e.startTime)}\n-\n${format24hTimeWithAmPm(e.endTime)}',
          ),
        );
      }
    }
    allSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    final tableMinWidth = (screenWidth - (isMobile ? 48 : 80)).clamp(
      950.0,
      2400.0,
    );

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
              1: FlexColumnWidth(1), // Monday
              2: FlexColumnWidth(1), // Tuesday
              3: FlexColumnWidth(1), // Wednesday
              4: FlexColumnWidth(1), // Thursday
              5: FlexColumnWidth(1), // Friday
              6: FlexColumnWidth(1), // Saturday
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              verticalInside: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                ),
                children: [
                  _buildHeaderCell('Time / Day', isDark),
                  for (final d in kWeekdays) _buildHeaderCell(d, isDark),
                ],
              ),
              // Slot Rows
              for (final slot in allSlots)
                if (slot.isBreak)
                  _buildBreakRow(slot, filtered, lookup, perms, isDark)
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

  TableRow _buildBreakRow(
    TimetablePeriodSlot slot,
    List<TimetableEntryModel> entries,
    ClassesLookup lookup,
    ClassesPermissions perms,
    bool isDark,
  ) {
    final isLunch = slot.startTime == '12:00' || slot.label.toLowerCase().contains('lunch');
    final defaultTitle = isLunch ? 'Lunch' : 'Break';
    final badgeColor = isLunch ? const Color(0xFFEA580C) : const Color(0xFF0284C7);
    final bgColor = isDark
        ? (isLunch ? const Color(0xFF261E14) : const Color(0xFF1E2230))
        : (isLunch ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF));
    final icon = isLunch ? Icons.restaurant_outlined : Icons.free_breakfast_outlined;

    return TableRow(
      decoration: BoxDecoration(
        color: bgColor,
      ),
      children: [
        // Time / Day column
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  defaultTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${format24hTimeWithAmPm(slot.startTime)} - ${format24hTimeWithAmPm(slot.endTime)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Days 1 through 6
        for (int day = 1; day <= 6; day++)
          Builder(
            builder: (context) {
              final entry = entries
                  .where(
                    (e) =>
                        e.isBreak &&
                        e.dayOfWeek == day &&
                        (e.startTime == slot.startTime ||
                            (e.startTime.compareTo(slot.endTime) < 0 &&
                                slot.startTime.compareTo(e.endTime) < 0)),
                  )
                  .firstOrNull;
              final title = (entry?.title?.isNotEmpty == true)
                  ? entry!.title!
                  : defaultTitle;

              return InkWell(
                onTap: perms.canManageTimetable
                    ? () => _openPeriodModal(
                        context,
                        ref,
                        lookup,
                        existing: entry,
                        defaultDay: day,
                        defaultStart: entry?.startTime ?? slot.startTime,
                        defaultEnd: entry?.endTime ?? slot.endTime,
                        defaultIsBreak: true,
                      )
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 13, color: badgeColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
      if (e.isBreak != slot.isBreak) return false;
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
                presetClassId: _selectedClassId,
                presetSectionId: _selectedSectionId,
              )
            : null,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
          ),
          alignment: Alignment.center,
          child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
        ),
      );
    }

    final entry = matches.first;
    final subjectName = lookup.subjectName(entry.subjectId);
    final teacherName = lookup.teacherName(entry.teacherId);
    final roomName = lookup.roomName(entry.classroomId);

    final isPractical = entry.isPractical ||
        (entry.subjectType?.toLowerCase() == 'practical') ||
        (lookup.subjects.where((s) => s.id == entry.subjectId).firstOrNull?.isPractical ?? false);

    Color cellBg;
    Color borderColor;
    Color textColor;

    final subLower = subjectName.toLowerCase();
    if (subLower.contains('physics') ||
        subLower.contains('chemistry') ||
        subLower.contains('biology') ||
        subLower.contains('computer')) {
      // Lab
      cellBg = isDark ? const Color(0xFF0C243B) : const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF93C5FD);
      textColor = const Color(0xFF2563EB);
    } else if (subLower.contains('physical') ||
        subLower.contains('art') ||
        subLower.contains('music')) {
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    subjectName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPractical
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isPractical ? 'Practical' : 'Theory',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isPractical
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              teacherName,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (isPractical &&
                entry.classroomId != null &&
                entry.classroomId!.isNotEmpty)
              Text(
                roomName,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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

    final classEntries = entries.where((e) {
      if (_selectedClassId != null && e.classId != _selectedClassId) {
        return false;
      }
      if (_selectedSectionId != null &&
          _selectedSectionId!.isNotEmpty &&
          e.sectionId.isNotEmpty &&
          e.sectionId != _selectedSectionId) {
        return false;
      }
      if (_selectedMonthFilter != 'All Months' &&
          e.month != null &&
          e.month != _selectedMonthFilter) {
        return false;
      }
      return true;
    }).toList();

    // Include default Break (10:15 - 10:30) and Lunch (12:00 - 12:40) for Monday through Saturday if not already present
    final combinedEntries = <TimetableEntryModel>[...classEntries];
    for (int day = 1; day <= 6; day++) {
      final hasBreak = classEntries.any(
        (e) =>
            e.isBreak &&
            e.dayOfWeek == day &&
            (e.startTime == '10:15' ||
                (e.title?.toLowerCase().contains('break') ?? false) ||
                (e.startTime.compareTo('10:30') < 0 && '10:15'.compareTo(e.endTime) < 0)),
      );
      if (!hasBreak) {
        combinedEntries.add(
          TimetableEntryModel(
            id: 'default-break-$day',
            classId: _selectedClassId ?? '',
            sectionId: _selectedSectionId ?? '',
            subjectId: '',
            teacherId: '',
            isBreak: true,
            title: 'Break',
            dayOfWeek: day,
            startTime: '10:15',
            endTime: '10:30',
            month: _selectedMonthFilter != 'All Months' ? _selectedMonthFilter : null,
          ),
        );
      }

      final hasLunch = classEntries.any(
        (e) =>
            e.isBreak &&
            e.dayOfWeek == day &&
            (e.startTime == '12:00' ||
                (e.title?.toLowerCase().contains('lunch') ?? false) ||
                (e.startTime.compareTo('12:40') < 0 && '12:00'.compareTo(e.endTime) < 0)),
      );
      if (!hasLunch) {
        combinedEntries.add(
          TimetableEntryModel(
            id: 'default-lunch-$day',
            classId: _selectedClassId ?? '',
            sectionId: _selectedSectionId ?? '',
            subjectId: '',
            teacherId: '',
            isBreak: true,
            title: 'Lunch',
            dayOfWeek: day,
            startTime: '12:00',
            endTime: '12:40',
            month: _selectedMonthFilter != 'All Months' ? _selectedMonthFilter : null,
          ),
        );
      }
    }

    // Sort by dayOfWeek (Monday..Saturday), then startTime
    combinedEntries.sort((a, b) {
      final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCmp != 0) return dayCmp;
      return a.startTime.compareTo(b.startTime);
    });

    final filtered = combinedEntries.where((e) {
      if (_tableSearchQuery.isEmpty) return true;
      final q = _tableSearchQuery;
      final isLunch = e.startTime == '12:00' || (e.title?.toLowerCase().contains('lunch') ?? false);
      final breakTitle = (e.title?.isNotEmpty == true) ? e.title! : (isLunch ? 'Lunch' : 'Break');
      final isPrac = e.isPractical ||
          (e.subjectType?.toLowerCase() == 'practical') ||
          (lookup.subjects.where((s) => s.id == e.subjectId).firstOrNull?.isPractical ?? false);
      final subTypeStr = e.isBreak ? 'break' : (isPrac ? 'practical' : 'theory');
      final sub = e.isBreak ? breakTitle.toLowerCase() : lookup.subjectName(e.subjectId).toLowerCase();
      final cls = lookup.className(e.classId).toLowerCase();
      final sec = lookup.sectionName(e.sectionId).toLowerCase();
      final tch = e.isBreak ? '' : lookup.teacherName(e.teacherId).toLowerCase();
      final room = (e.isBreak || !isPrac) ? '' : lookup.roomName(e.classroomId).toLowerCase();
      final day = (e.dayOfWeek >= 1 && e.dayOfWeek <= 6)
          ? kWeekdays[e.dayOfWeek - 1].toLowerCase()
          : '';
      final timeStr = '${format24hTimeWithAmPm(e.startTime)} ${format24hTimeWithAmPm(e.endTime)}'.toLowerCase();
      return sub.contains(q) ||
          cls.contains(q) ||
          sec.contains(q) ||
          subTypeStr.contains(q) ||
          tch.contains(q) ||
          room.contains(q) ||
          day.contains(q) ||
          timeStr.contains(q) ||
          (e.isBreak && ('break'.contains(q) || 'lunch'.contains(q)));
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
            fillColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );

    final tableMinWidth = (screenWidth - (isMobile ? 48 : 80)).clamp(
      850.0,
      2400.0,
    );

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
              const Text(
                'Timetable Periods',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Expanded(child: Center(child: searchBox)),
            ],
          ),
          const Divider(height: 24),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'No periods found for the selected filters.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
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
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Class',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Section',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Subject Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Subject',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Month',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Time Slot (AM/PM)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Teacher',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Classroom / Lab',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      rows: filtered.map((e) {
                        final dayName = (e.dayOfWeek >= 1 && e.dayOfWeek <= 6)
                            ? kWeekdays[e.dayOfWeek - 1]
                            : 'Monday';
                        final timeDisplay =
                            '${format24hTimeWithAmPm(e.startTime)} - ${format24hTimeWithAmPm(e.endTime)}';

                        final isLunch = e.startTime == '12:00' || (e.title?.toLowerCase().contains('lunch') ?? false);
                        final badgeColor = isLunch ? const Color(0xFFEA580C) : const Color(0xFF0284C7);
                        final icon = isLunch ? Icons.restaurant_outlined : Icons.free_breakfast_outlined;
                        final breakTitle = (e.title?.isNotEmpty == true) ? e.title! : (isLunch ? 'Lunch' : 'Break');
                        final isPractical = e.isPractical ||
                            (e.subjectType?.toLowerCase() == 'practical') ||
                            (lookup.subjects.where((s) => s.id == e.subjectId).firstOrNull?.isPractical ?? false);

                        return DataRow(
                          cells: [
                            // Class
                            DataCell(
                              Text(
                                e.isBreak ? '—' : lookup.className(e.classId),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: e.isBreak ? Colors.grey : null,
                                ),
                              ),
                            ),
                            // Section
                            DataCell(
                              Text(
                                e.isBreak ? '—' : lookup.sectionName(e.sectionId),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: e.isBreak ? Colors.grey : null,
                                ),
                              ),
                            ),
                            // Subject Type
                            DataCell(
                              e.isBreak
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Break', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPractical
                                            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                                            : const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isPractical ? 'Practical' : 'Theory',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPractical ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                            ),
                            // Subject
                            DataCell(
                              e.isBreak
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: badgeColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, size: 13, color: badgeColor),
                                          const SizedBox(width: 5),
                                          Text(
                                            breakTitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      lookup.subjectName(e.subjectId),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            // Day
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF109F83,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF109F83),
                                  ),
                                ),
                              ),
                            ),
                            // Month
                            DataCell(
                              Text(
                                e.month ?? 'All Months',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            // Time Slot
                            DataCell(
                              Text(
                                timeDisplay,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Teacher
                            DataCell(
                              Text(
                                e.isBreak ? '—' : lookup.teacherName(e.teacherId),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: e.isBreak ? Colors.grey : null,
                                  fontWeight: e.isBreak ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            // Classroom / Lab: Theory periods do NOT display room number!
                            DataCell(
                              Text(
                                (e.isBreak || !isPractical) ? '—' : lookup.roomName(e.classroomId),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (e.isBreak || !isPractical) ? Colors.grey : const Color(0xFF2563EB),
                                  fontWeight: isPractical ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            DataCell(
                              perms.canManageTimetable
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                          ),
                                          tooltip: e.isBreak ? 'Edit Break' : 'Edit Period',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openPeriodModal(
                                            context,
                                            ref,
                                            lookup,
                                            existing: e.id.startsWith('default-') ? null : e,
                                            defaultDay: e.dayOfWeek,
                                            defaultStart: e.startTime,
                                            defaultEnd: e.endTime,
                                            defaultIsBreak: e.isBreak,
                                          ),
                                        ),
                                        if (!e.id.startsWith('default-'))
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Delete Period',
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () async {
                                              if (await confirmDelete(
                                                context,
                                                'this period',
                                              )) {
                                                if (!mounted) return;
                                                await runClassesAction(
                                                  context,
                                                  () => ref
                                                      .read(
                                                        timetableControllerProvider
                                                            .notifier,
                                                      )
                                                      .delete(e.id),
                                                  success:
                                                      'Period deleted successfully',
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    )
                                  : const Text(
                                      '—',
                                      style: TextStyle(color: Colors.grey),
                                    ),
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
    bool defaultIsBreak = false,
    String? presetClassId,
    String? presetSectionId,
  }) => openPeriodModal(
    context,
    ref,
    lookup,
    existing: existing,
    defaultDay: defaultDay,
    defaultStart: defaultStart,
    defaultEnd: defaultEnd,
    defaultIsBreak: defaultIsBreak,
    presetClassId: presetClassId ?? _selectedClassId,
    presetSectionId: presetSectionId ?? _selectedSectionId,
    presetMonth: _selectedMonthFilter != 'All Months'
        ? _selectedMonthFilter
        : null,
  );
}

Future<void> openPeriodModal(
  BuildContext context,
  WidgetRef ref,
  ClassesLookup lookup, {
  TimetableEntryModel? existing,
  int? defaultDay,
  String? defaultStart,
  String? defaultEnd,
  bool defaultIsBreak = false,
  String? presetClassId,
  String? presetSectionId,
  String? presetMonth,
}) async {
  var classId =
      existing?.classId ??
      presetClassId ??
      (lookup.classes.isNotEmpty ? lookup.classes.first.id : '');
  final sectionsForClass = lookup.sections
      .where((s) => s.classId == classId)
      .toList();
  var sectionId =
      existing?.sectionId ??
      (sectionsForClass.any((s) => s.id == presetSectionId)
          ? presetSectionId!
          : (sectionsForClass.isNotEmpty ? sectionsForClass.first.id : ''));

  // 3. Subject Type (Theory or Practical)
  var subjectType = existing?.subjectType ??
      (existing != null
          ? (lookup.subjects.where((s) => s.id == existing.subjectId).firstOrNull?.type ?? 'Theory')
          : 'Theory');
  if (subjectType.toLowerCase() != 'practical' && subjectType.toLowerCase() != 'theory') {
    subjectType = 'Theory';
  }

  // New period: the user picks the subject; day / time / teacher appear after that.
  var subjectId = existing?.subjectId ?? '';

  // 5. Room Number: Practical only. Cleared/hidden for Theory.
  String? roomId;
  if (subjectType.toLowerCase() == 'practical') {
    roomId = existing?.classroomId;
    if (roomId == null || roomId.isEmpty) {
      final practicalRooms = lookup.classrooms.where((r) =>
        r.isAvailable &&
        (r.roomType.toLowerCase() == 'practical' ||
         r.name.toLowerCase().contains('lab') ||
         r.name.toLowerCase().contains('studio'))
      ).toList();
      final allAvailable = lookup.classrooms.where((r) => r.isAvailable).toList();
      roomId = practicalRooms.isNotEmpty
          ? practicalRooms.first.id
          : (allAvailable.isNotEmpty ? allAvailable.first.id : null);
    }
  } else {
    roomId = null;
  }

  int dayOfWeek = existing?.dayOfWeek ?? (defaultDay ?? 1);
  String selectedMonth = existing?.month ?? (presetMonth ?? 'All Months');

  String? teacherId = existing?.teacherId;

  final createdSubjects = <SubjectModel>[];
  var isBreak = existing?.isBreak ?? defaultIsBreak;
  final breakTitleController = TextEditingController(
    text: existing?.title ?? '',
  );

  TimeOfDay startTimeOfDay = parse24hTime(
    existing?.startTime ?? (defaultStart ?? '08:00'),
  );
  TimeOfDay endTimeOfDay = parse24hTime(
    existing?.endTime ?? (defaultEnd ?? '08:45'),
  );
  String? formError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final currentSubjects = [
          ...lookup.subjects.where((s) => s.classId == classId),
          ...createdSubjects.where((s) => s.classId == classId),
        ];
        final typeFilteredSubs = currentSubjects
            .where((s) => s.type.toLowerCase() == subjectType.toLowerCase())
            .toList();
        final availableSubjects = typeFilteredSubs.isNotEmpty ? typeFilteredSubs : currentSubjects;

        // Never silently pick a subject. If the chosen one no longer belongs to
        // this class / type, clear it so the user selects again.
        if (subjectId.isNotEmpty && !availableSubjects.any((s) => s.id == subjectId)) {
          subjectId = '';
        }
        final subjectChosen = subjectId.isNotEmpty;

        // Available practical labs and suitable rooms from Classroom module
        final practicalLabRooms = lookup.classrooms.where((r) =>
          r.isAvailable &&
          (r.roomType.toLowerCase() == 'practical' ||
           r.name.toLowerCase().contains('lab') ||
           r.name.toLowerCase().contains('studio'))
        ).toList();
        final otherAvailableRooms = lookup.classrooms.where((r) =>
          r.isAvailable && !practicalLabRooms.contains(r)
        ).toList();
        final displayRooms = [...practicalLabRooms, ...otherAvailableRooms];

        // Teacher options filtered for selected subject
        final currentSubject = availableSubjects.where((s) => s.id == subjectId).firstOrNull;
        final subjectName = currentSubject?.name ?? lookup.subjectName(subjectId);
        final qualifiedTeachers = lookup.qualifiedTeachersForSubject(subjectName);
        final baseTeacherOptions = qualifiedTeachers.isNotEmpty ? qualifiedTeachers : lookup.teachers;
        final teacherDropdownOptions = <TeacherOption>[
          ...baseTeacherOptions,
          if (teacherId != null && teacherId!.isNotEmpty && !baseTeacherOptions.any((t) => t.id == teacherId))
            ...lookup.teachers.where((t) => t.id == teacherId),
        ];

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                existing == null
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                color: const Color(0xFF109F83),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                existing == null ? 'Add Timetable Period' : 'Edit Period',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

                  DropdownButtonFormField<bool>(
                    initialValue: isBreak,
                    decoration: const InputDecoration(
                      labelText: 'Entry Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('Subject period'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Break / lunch'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => isBreak = value ?? false),
                  ),
                  const SizedBox(height: 10),

                  if (isBreak) ...[
                    // Quick Preset Buttons for Break and Lunch
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            Icons.free_breakfast_outlined,
                            size: 14,
                            color: Color(0xFF0284C7),
                          ),
                          label: const Text(
                            'Break (10:15 - 10:30 AM)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          side: BorderSide(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              breakTitleController.text = 'Break';
                              startTimeOfDay = const TimeOfDay(hour: 10, minute: 15);
                              endTimeOfDay = const TimeOfDay(hour: 10, minute: 30);
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.restaurant_outlined,
                            size: 14,
                            color: Color(0xFFEA580C),
                          ),
                          label: const Text(
                            'Lunch (12:00 - 12:40 PM)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.1),
                          side: BorderSide(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              breakTitleController.text = 'Lunch';
                              startTimeOfDay = const TimeOfDay(hour: 12, minute: 0);
                              endTimeOfDay = const TimeOfDay(hour: 12, minute: 40);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: breakTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Break / Lunch Name',
                        hintText: 'e.g. Break, Lunch, or Recess',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Reserved for break/lunch. Not assigned to any class, subject, or teacher.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // 1. Class – Select the class
                    const Text(
                      'Class',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Class',
                      inlineLabel: false,
                      allowNone: false,
                      value: classId,
                      options: {
                        for (final c in lookup.classes) c.id: c.name,
                      },
                      onChanged: (v) {
                        if (v != null && v != classId) {
                          setDialogState(() {
                            classId = v;
                            final secs = lookup.sections
                                .where((s) => s.classId == v)
                                .toList();
                            sectionId = secs.isNotEmpty ? secs.first.id : '';
                            // Subject belongs to the class: start again.
                            subjectId = '';
                            teacherId = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Section – Display sections belonging to the selected class
                    const Text(
                      'Section',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Section',
                      inlineLabel: false,
                      allowNone: false,
                      value: sectionId,
                      options: {
                        for (final s in lookup.sections.where(
                          (s) => s.classId == classId,
                        ))
                          s.id: s.name,
                      },
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => sectionId = v);
                        }
                      },
                    ),
                    Builder(
                      builder: (_) {
                        final sec = lookup.sections
                            .where((s) => s.id == sectionId)
                            .firstOrNull;
                        final cls = lookup.classes
                            .where((c) => c.id == classId)
                            .firstOrNull;
                        if (sec == null) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'This class has no sections yet. Create one in Sections first.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                            ),
                          );
                        }
                        final tid = (sec.classTeacherId ?? '').isNotEmpty
                            ? sec.classTeacherId
                            : cls?.classTeacherId;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Class Teacher: ${lookup.teacherName(tid)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. Subject Type – Select Theory or Practical
                    const Text(
                      'Subject Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: subjectType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Theory',
                          child: Text('Theory'),
                        ),
                        DropdownMenuItem(
                          value: 'Practical',
                          child: Text('Practical'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null && v != subjectType) {
                          setDialogState(() {
                            subjectType = v;
                            if (v == 'Theory') {
                              // If Subject Type changes from Practical to Theory, clear previously selected room number and hide field
                              roomId = null;
                            } else {
                              // Practical: Show and enable Room Number field with available practical labs / rooms
                              if (roomId == null || roomId!.isEmpty) {
                                final pRooms = lookup.classrooms.where((r) =>
                                  r.isAvailable &&
                                  (r.roomType.toLowerCase() == 'practical' ||
                                   r.name.toLowerCase().contains('lab') ||
                                   r.name.toLowerCase().contains('studio'))
                                ).toList();
                                final aRooms = lookup.classrooms.where((r) => r.isAvailable).toList();
                                roomId = pRooms.isNotEmpty
                                    ? pRooms.first.id
                                    : (aRooms.isNotEmpty ? aRooms.first.id : null);
                              }
                            }

                            // Subject list is filtered by type: pick again.
                            subjectId = '';
                            teacherId = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4. Subject – Select the subject assigned to selected class and section
                    const Text(
                      'Subject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Subject',
                      inlineLabel: false,
                      allowNone: false,
                      value: subjectId,
                      hint: 'Select a subject',
                      options: {
                        for (final s in availableSubjects)
                          s.id: '${s.name} (${s.type})',
                      },
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            subjectId = v;
                            final s = availableSubjects.where(
                              (sub) => sub.id == v,
                            ).firstOrNull;
                            if (s != null && s.teacherId != null && s.teacherId!.isNotEmpty) {
                              teacherId = s.teacherId;
                            } else if (s != null) {
                              final qualified = lookup.qualifiedTeachersForSubject(s.name);
                              if (qualified.isNotEmpty) teacherId = qualified.first.id;
                            }
                          });
                        }
                      },
                    ),
                    TextButton.icon(
                      onPressed: classId.isEmpty
                          ? null
                          : () async {
                              final name = await showDialog<String>(
                                context: ctx,
                                builder: (dialogContext) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: Text('Add New $subjectType Subject'),
                                    content: TextField(
                                      controller: controller,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Subject name',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(
                                          dialogContext,
                                          controller.text.trim(),
                                        ),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (name == null || name.trim().isEmpty) return;
                              try {
                                final created = await ref
                                    .read(subjectsControllerProvider.notifier)
                                    .save(
                                      SubjectModel(
                                        id: '',
                                        classId: classId,
                                        name: name.trim(),
                                        code: name
                                            .trim()
                                            .substring(
                                              0,
                                              name.trim().length > 3
                                                  ? 3
                                                  : name.trim().length,
                                            )
                                            .toUpperCase(),
                                        type: subjectType,
                                      ),
                                      isNew: true,
                                    );
                                setDialogState(() {
                                  createdSubjects.add(created);
                                  subjectId = created.id;
                                  if (created.teacherId != null && created.teacherId!.isNotEmpty) {
                                    teacherId = created.teacherId;
                                  }
                                });
                              } catch (e) {
                                setDialogState(() => formError = e.toString());
                              }
                            },
                      icon: const Icon(Icons.add, size: 15),
                      label: Text('Add New $subjectType Subject'),
                    ),
                    const SizedBox(height: 12),

                    if (!subjectChosen)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Select a subject (or add a new one) to set the day, time and teacher.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                    // 5. Room Number – Display this field only when Subject Type is Practical
                    if (subjectType == 'Practical') ...[
                      const Text(
                        'Room Number / Lab',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SearchableIdDropdown(
                        label: 'Room Number / Lab',
                        inlineLabel: false,
                        allowNone: false,
                        value: roomId,
                        options: {
                          for (final room in displayRooms)
                            room.id: '${room.name}${room.roomType.isNotEmpty ? ' (${room.roomType})' : ''}',
                        },
                        disabled: {
                          for (final room in lookup.classrooms)
                            if (!room.isAvailable) room.id: 'Unavailable',
                        },
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => roomId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 6. Day of the Week – Select the day
                    const Text(
                      'Day of the Week',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: dayOfWeek,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        if (existing == null)
                          const DropdownMenuItem(
                            value: 0,
                            child: Text(
                              'This Week (Mon-Sat)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ...[1, 2, 3, 4, 5, 6].map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(
                              kWeekdays[d - 1],
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => dayOfWeek = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 7. Month – Select the month
                    const Text(
                      'Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: kMonths.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedMonth = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 8. Period / Time – Select period number or start/end times
                    const Text(
                      'Period / Time (AM/PM)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Start Time Selector
                        Expanded(
                          child: buildTimePickerTile(
                            context: ctx,
                            label: 'Start Time',
                            time: startTimeOfDay,
                            onChanged: (newTod) =>
                                setDialogState(() => startTimeOfDay = newTod),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // End Time Selector
                        Expanded(
                          child: buildTimePickerTile(
                            context: ctx,
                            label: 'End Time',
                            time: endTimeOfDay,
                            onChanged: (newTod) =>
                                setDialogState(() => endTimeOfDay = newTod),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 9. Teacher – Select teacher assigned to subject & class/section
                    const Text(
                      'Teacher',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Teacher',
                      inlineLabel: false,
                      value: teacherId,
                      options: {
                        for (final t in teacherDropdownOptions) t.id: t.name,
                      },
                      onChanged: (v) => setDialogState(() => teacherId = v),
                    ),
                    const SizedBox(height: 12),
                    ],
                  ],
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF109F83),
              ),
              onPressed: () async {
                final start24 = timeOfDayTo24h(startTimeOfDay);
                final end24 = timeOfDayTo24h(endTimeOfDay);

                if (start24.compareTo(end24) >= 0) {
                  setDialogState(
                    () => formError = 'End time must be after start time.',
                  );
                  return;
                }

                if (!isBreak) {
                  if (start24.compareTo('10:30') < 0 && '10:15'.compareTo(end24) < 0) {
                    setDialogState(
                      () => formError = 'Cannot schedule class during Break (10:15 AM - 10:30 AM).',
                    );
                    return;
                  }
                  if (start24.compareTo('12:40') < 0 && '12:00'.compareTo(end24) < 0) {
                    setDialogState(
                      () => formError = 'Cannot schedule class during Lunch (12:00 PM - 12:40 PM).',
                    );
                    return;
                  }
                  if (classId.isEmpty) {
                    setDialogState(() => formError = 'Please select a class.');
                    return;
                  }
                  if (sectionId.isEmpty) {
                    setDialogState(() => formError = 'Please select a section.');
                    return;
                  }
                  if (subjectId.isEmpty) {
                    setDialogState(() => formError = 'Please select a subject.');
                    return;
                  }
                  if (subjectType == 'Practical') {
                    if (roomId == null || roomId!.trim().isEmpty) {
                      setDialogState(
                        () => formError = 'Please select an available room or lab for Practical period.',
                      );
                      return;
                    }
                    final room = lookup.classrooms.where((r) => r.id == roomId).firstOrNull;
                    if (room != null && !room.isAvailable) {
                      setDialogState(
                        () => formError = '${room.name} is marked Unavailable.',
                      );
                      return;
                    }
                  }
                  if (teacherId == null || teacherId!.trim().isEmpty) {
                    setDialogState(() => formError = 'Please select a teacher.');
                    return;
                  }
                }

                try {
                  final days = existing == null && dayOfWeek == 0
                      ? [1, 2, 3, 4, 5, 6]
                      : [dayOfWeek];
                  final savedDays = <int>[];
                  final conflicts = <String>[];
                  for (final day in days) {
                    final model = TimetableEntryModel(
                      id: existing?.id ?? '',
                      classId: isBreak ? '' : classId,
                      sectionId: isBreak ? '' : sectionId,
                      subjectId: isBreak ? '' : subjectId,
                      teacherId: isBreak ? '' : (teacherId ?? ''),
                      classroomId: (isBreak || subjectType == 'Theory') ? null : roomId,
                      isBreak: isBreak,
                      title: isBreak
                          ? breakTitleController.text.trim().isEmpty
                                ? (start24 == '12:00' ? 'Lunch' : 'Break')
                                : breakTitleController.text.trim()
                          : null,
                      dayOfWeek: day,
                      startTime: start24,
                      endTime: end24,
                      month: selectedMonth != 'All Months'
                          ? selectedMonth
                          : null,
                      subjectType: isBreak ? null : subjectType,
                    );
                    try {
                      await ref
                          .read(timetableControllerProvider.notifier)
                          .save(model, isNew: existing == null);
                      savedDays.add(day);
                    } catch (e) {
                      final message = e
                          .toString()
                          .replaceAll('Exception:', '')
                          .replaceAll('ClassesDataException:', '')
                          .trim();
                      conflicts.add('${kWeekdays[day - 1]}: $message');
                    }
                  }
                  if (savedDays.isEmpty && conflicts.isNotEmpty) {
                    setDialogState(() => formError = conflicts.join('\n'));
                    return;
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    showCompactSnackBar(
                      context,
                      conflicts.isEmpty
                          ? (existing == null
                                ? (days.length > 1
                                      ? 'Period added Monday through Saturday'
                                      : 'Period scheduled successfully')
                                : 'Period updated successfully')
                          : 'Added ${savedDays.length} day(s). Skipped conflicts: ${conflicts.join('; ')}',
                      backgroundColor: conflicts.isEmpty
                          ? null
                          : const Color(0xFFB91C1C),
                      icon: conflicts.isEmpty
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      duration: conflicts.isEmpty
                          ? const Duration(seconds: 2)
                          : const Duration(seconds: 5),
                    );
                    breakTitleController.dispose();
                  }
                } catch (e) {
                  setDialogState(() {
                    formError = e
                        .toString()
                        .replaceAll('Exception:', '')
                        .replaceAll('ClassesDataException:', '')
                        .trim();
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

Widget buildTimePickerTile({
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // AM / PM toggle chip
            InkWell(
              onTap: () {
                final newHour = isPm
                    ? (time.hour - 12).clamp(0, 23)
                    : (time.hour + 12).clamp(0, 23);
                onChanged(TimeOfDay(hour: newHour, minute: time.minute));
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPm
                      ? const Color(0xFFF97316).withValues(alpha: 0.15)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPm ? 'PM' : 'AM',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isPm
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF1D4ED8),
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
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF109F83),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
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
