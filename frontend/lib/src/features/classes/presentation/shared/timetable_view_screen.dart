import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/timetable_controller.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Read-only timetable grouped by weekday. The data source already limits it
/// to the teacher's own periods or the student's own section.
class TimetableViewScreen extends ConsumerWidget {
  const TimetableViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(classesLookupProvider);
    return ClassesPageFrame(
      title: 'Timetable',
      child: AsyncListBody<TimetableEntryModel>(
        value: ref.watch(timetableControllerProvider),
        onRetry: () => ref.invalidate(timetableControllerProvider),
        emptyTitle: 'No timetable entries',
        builder: (items) => TimetableDayList(entries: items, lookup: lookup),
      ),
    );
  }
}

/// Reusable day-grouped list (also used by the admin timetable screen).
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('${e.startTime} – ${e.endTime}  ·  ${lookup.subjectName(e.subjectId)}'),
                subtitle: Text(
                  '${lookup.className(e.classId)} ${lookup.sectionName(e.sectionId)}'
                  ' · ${lookup.teacherName(e.teacherId)}'
                  ' · ${lookup.roomName(e.classroomId)}',
                ),
                trailing: trailingBuilder?.call(e),
              ),
            ),
        ],
      ],
    );
  }
}
