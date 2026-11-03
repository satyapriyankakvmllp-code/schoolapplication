import 'package:flutter/material.dart';
import '../../domain/timetable_entry_model.dart';
import 'classes_lookup.dart';
import 'classes_ui.dart';

/// Reusable day-grouped list (shared by the role timetable screens).
class TimetableDayList extends StatelessWidget {
  final List<TimetableEntryModel> entries;
  final ClassesLookup lookup;
  final Widget Function(TimetableEntryModel entry)? trailingBuilder;

  const TimetableDayList({
    super.key,
    required this.entries,
    required this.lookup,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = <int>{for (final e in entries) e.dayOfWeek}.toList()..sort();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              weekdayNames[(d - 1).clamp(0, 6)],
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final e in entries.where((e) => e.dayOfWeek == d))
            Builder(
              builder: (context) {
                final isLunch = e.startTime == '12:00' || (e.title?.toLowerCase().contains('lunch') ?? false);
                final breakTitle = (e.title?.isNotEmpty == true) ? e.title! : (isLunch ? 'Lunch' : 'Break');
                final icon = isLunch ? Icons.restaurant_outlined : Icons.free_breakfast_outlined;

                if (e.isBreak) {
                  return Card(
                    color: isLunch
                        ? const Color(0xFFEA580C).withValues(alpha: 0.08)
                        : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    child: ListTile(
                      leading: Icon(
                        icon,
                        color: isLunch ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                      ),
                      title: Text(
                        '${e.startTime} – ${e.endTime}  ·  $breakTitle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLunch ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                        ),
                      ),
                      subtitle: const Text('Break Time · Reserved (No classes or teachers assigned)'),
                      trailing: trailingBuilder?.call(e),
                    ),
                  );
                }

                final isPractical = e.isPractical ||
                    (e.subjectType?.toLowerCase() == 'practical') ||
                    (lookup.subjects.where((s) => s.id == e.subjectId).firstOrNull?.isPractical ?? false);
                final subjectTypeLabel = isPractical ? 'Practical' : 'Theory';

                final roomPart = (isPractical && e.classroomId != null && e.classroomId!.isNotEmpty)
                    ? ' · ${lookup.roomName(e.classroomId)}'
                    : '';
                final monthPart = (e.month != null && e.month!.isNotEmpty && e.month != 'All Months')
                    ? ' · ${e.month}'
                    : '';

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('${e.startTime} – ${e.endTime}  ·  ${lookup.subjectName(e.subjectId)}'),
                    subtitle: Text(
                      '${lookup.className(e.classId)} ${lookup.sectionName(e.sectionId)}'
                      ' · $subjectTypeLabel'
                      ' · ${lookup.teacherName(e.teacherId)}'
                      '$roomPart'
                      '$monthPart',
                    ),
                    trailing: trailingBuilder?.call(e),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
