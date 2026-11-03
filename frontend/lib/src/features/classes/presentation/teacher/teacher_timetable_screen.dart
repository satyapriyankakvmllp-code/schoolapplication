import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/timetable_controller.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';
import '../widgets/timetable_day_list.dart';

/// Read-only timetable for the Teacher role, grouped by weekday. The data source already limits it
/// to the teacher's own periods.
class TeacherTimetableScreen extends ConsumerWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    return ClassesPageFrame(
      title: 'Timetable',
      child: AccessGuard(
        allowed: perms.isTeacher,
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
