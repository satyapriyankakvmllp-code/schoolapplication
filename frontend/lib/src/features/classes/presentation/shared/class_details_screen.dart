import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_controller.dart';
import '../../application/sections_controller.dart';
import '../../application/subjects_controller.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Read-only class overview shared by Admin, Teacher and Student.
/// The data layer already scopes classes/sections/subjects to the actor.
class ClassDetailsScreen extends StatelessWidget {
  final String classId;
  const ClassDetailsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: ClassDetailsBody(classId: classId),
    );
  }
}

/// The details content without a Scaffold, so it can be embedded in a hub tab.
class ClassDetailsBody extends ConsumerWidget {
  final String classId;
  const ClassDetailsBody({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classes = ref.watch(classesControllerProvider);
    final lookup = ref.watch(classesLookupProvider);
    final sections = (ref.watch(sectionsControllerProvider).valueOrNull ?? const [])
        .where((s) => s.classId == classId)
        .toList();
    final subjects = (ref.watch(subjectsControllerProvider).valueOrNull ?? const [])
        .where((s) => s.classId == classId)
        .toList();

    return classes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (list) {
        final matches = list.where((c) => c.id == classId);
        if (matches.isEmpty) {
          return const AccessGuard(allowed: false, child: SizedBox.shrink());
        }
        final c = matches.first;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(c.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Academic year ${c.academicYear}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Class teacher'),
                        subtitle: Text(lookup.teacherName(c.classTeacherId)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.meeting_room_outlined),
                        title: const Text('Classroom'),
                        subtitle: Text(lookup.roomName(c.classroomId)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Sections', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (sections.isEmpty)
                  const Text('No sections to show.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in sections) Chip(label: Text('Section ${s.name} · capacity ${s.capacity}')),
                    ],
                  ),
                const SizedBox(height: 16),
                Text('Subjects', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (subjects.isEmpty)
                  const Text('No subjects to show.')
                else
                  Card(
                    child: Column(
                      children: [
                        for (final s in subjects)
                          ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(s.name),
                            subtitle: Text('${s.code} · ${lookup.teacherName(s.teacherId)}'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
