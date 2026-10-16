import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/subjects_controller.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Read-only subjects list (Teacher: assigned subjects, Student: enrolled subjects).
class SubjectsListScreen extends ConsumerWidget {
  final String title;
  const SubjectsListScreen({super.key, this.title = 'Subjects'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(classesLookupProvider);
    return ClassesPageFrame(
      title: title,
      child: AsyncListBody(
        value: ref.watch(subjectsControllerProvider),
        onRetry: () => ref.invalidate(subjectsControllerProvider),
        emptyTitle: 'No subjects',
        emptySubtitle: 'Nothing has been assigned to you yet.',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(s.name),
                subtitle: Text('${s.code} · ${lookup.className(s.classId)} · ${lookup.teacherName(s.teacherId)}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
