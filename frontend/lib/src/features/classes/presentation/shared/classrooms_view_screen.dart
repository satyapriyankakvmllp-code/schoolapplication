import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classroom_controller.dart';
import '../widgets/classes_ui.dart';

/// Read-only classroom list (Teacher: assigned rooms, Student: room info).
class ClassroomsViewScreen extends ConsumerWidget {
  final String title;
  const ClassroomsViewScreen({super.key, this.title = 'Classroom'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClassesPageFrame(
      title: title,
      child: AsyncListBody(
        value: ref.watch(classroomControllerProvider),
        onRetry: () => ref.invalidate(classroomControllerProvider),
        emptyTitle: 'No classroom information',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text(r.name),
                subtitle: Text('${r.building} · capacity ${r.capacity}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
