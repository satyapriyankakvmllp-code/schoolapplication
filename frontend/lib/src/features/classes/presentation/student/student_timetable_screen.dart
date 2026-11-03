import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/timetable_controller.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';
import '../widgets/timetable_day_list.dart';

/// Read-only timetable for the Student role, grouped by weekday. The data source already limits it
/// to the student's own section.
class StudentTimetableScreen extends ConsumerWidget {
  const StudentTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    return ClassesPageFrame(
      title: 'Timetable',
      child: AccessGuard(
        allowed: perms.isStudent,
        child: AsyncListBody<TimetableEntryModel>(
          value: ref.watch(timetableControllerProvider),
          onRetry: () => ref.invalidate(timetableControllerProvider),
          emptyTitle: 'No timetable entries',
          builder: (items) => TimetableDayList(entries: items, lookup: lookup),
        ),
      ),
    );
  }
}
