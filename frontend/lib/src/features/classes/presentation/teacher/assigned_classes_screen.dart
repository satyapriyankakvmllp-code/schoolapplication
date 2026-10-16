import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../shared/class_details_screen.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Teacher: classes where the teacher is class teacher or teaches a subject/period.
/// Read-only; no create/edit/assign actions are offered.
class AssignedClassesScreen extends ConsumerWidget {
  const AssignedClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    return AccessGuard(
      allowed: perms.isTeacher || perms.isAdmin,
      child: ClassesPageFrame(
        title: 'Assigned Classes',
        child: AsyncListBody(
          value: ref.watch(classesControllerProvider),
          onRetry: () => ref.invalidate(classesControllerProvider),
          emptyTitle: 'No classes assigned',
          emptySubtitle: 'Ask an administrator to assign you to a class.',
          builder: (items) => ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: Text(c.name),
                  subtitle: Text('${c.academicYear} · ${lookup.roomName(c.classroomId)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ClassDetailsScreen(classId: c.id)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
