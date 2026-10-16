import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/curriculum_controller.dart';
import '../../domain/curriculum_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Curriculum list for Teacher and Student. Teachers can tick off topics only
/// for subjects assigned to them (re-checked in the data source).
class CurriculumListScreen extends ConsumerWidget {
  const CurriculumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(classesLookupProvider);
    final actor = ref.watch(classesActorProvider);
    final perms = actor.permissions;

    bool canUpdate(CurriculumModel c) {
      if (!perms.canUpdateCurriculumProgress) return false;
      if (perms.isAdmin) return true;
      return lookup.subjects.any((s) => s.id == c.subjectId && s.teacherId == actor.userId);
    }

    return ClassesPageFrame(
      title: 'Curriculum',
      child: AsyncListBody(
        value: ref.watch(curriculumControllerProvider),
        onRetry: () => ref.invalidate(curriculumControllerProvider),
        emptyTitle: 'No curriculum available',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final c = items[i];
            return Card(
              child: ExpansionTile(
                title: Text(c.title),
                subtitle: Text('${lookup.subjectName(c.subjectId)} · ${lookup.className(c.classId)}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.description.isNotEmpty) Text(c.description),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: c.progress),
                  const SizedBox(height: 4),
                  Text('${c.completedTopics} of ${c.topics.length} topics covered'),
                  const SizedBox(height: 8),
                  for (var t = 0; t < c.topics.length; t++)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(c.topics[t]),
                      value: t < c.completedTopics,
                      // Topics are completed in order; the checkbox moves the progress marker.
                      onChanged: canUpdate(c)
                          ? (checked) => runClassesAction(
                                context,
                                () => ref
                                    .read(curriculumControllerProvider.notifier)
                                    .updateProgress(c.id, checked == true ? t + 1 : t),
                              )
                          : null,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
