import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/subjects_controller.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Admin-only: assign class teachers and subject teachers.
class TeacherAssignmentScreen extends ConsumerWidget {
  const TeacherAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final options = {for (final t in lookup.teachers) t.id: t.name};
    final classes = ref.watch(classesControllerProvider).valueOrNull ?? const [];
    final subjects = ref.watch(subjectsControllerProvider).valueOrNull ?? const [];

    return AccessGuard(
      allowed: perms.canAssignTeachers,
      child: ClassesPageFrame(
        title: 'Teacher / Class Assignment',
        subtitle: 'Choose a teacher for each class and subject.',
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Text('Class teachers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (classes.isEmpty) const Text('No classes.'),
            for (final c in classes)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IdDropdown(
                    label: c.name,
                    value: c.classTeacherId,
                    options: options,
                    onChanged: (v) => runClassesAction(
                      context,
                      () => ref.read(classesControllerProvider.notifier).assignClassTeacher(c.id, v),
                      success: 'Class teacher updated',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Subject teachers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (subjects.isEmpty) const Text('No subjects.'),
            for (final s in subjects)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IdDropdown(
                    label: '${s.name} (${lookup.className(s.classId)})',
                    value: s.teacherId,
                    options: options,
                    onChanged: (v) => runClassesAction(
                      context,
                      () => ref.read(subjectsControllerProvider.notifier).assignTeacher(s.id, v),
                      success: 'Subject teacher updated',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
