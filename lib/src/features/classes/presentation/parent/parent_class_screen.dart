import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../../admissions/domain/student_admission_model.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/curriculum_controller.dart';
import '../../application/sections_controller.dart';
import '../../application/subjects_controller.dart';
import '../../application/teacher_work_controller.dart';
import '../../application/timetable_controller.dart';
import '../../domain/classes_actor.dart';
import '../../domain/class_model.dart';
import '../../domain/curriculum_model.dart';
import '../../domain/section_model.dart';
import '../../domain/subject_model.dart';
import '../../domain/teacher_work_model.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Read-only academic portal scoped to a child linked to the signed-in parent.
class ParentClassScreen extends ConsumerWidget {
  const ParentClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final admissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];
    final linkedChildren = admissions.where((item) {
      if (user == null) return false;
      return item.father?.userId == user.id ||
          item.mother?.userId == user.id ||
          item.guardian?.userId == user.id;
    }).toList();
    final selectedChildId = ref.watch(parentActiveChildIdProvider);
    final selectedChild = linkedChildren
        .where(
          (item) =>
              item.student.id == selectedChildId ||
              item.student.userId == selectedChildId ||
              item.user.id == selectedChildId,
        )
        .firstOrNull;

    if (selectedChild == null && linkedChildren.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(parentActiveChildIdProvider.notifier).state =
            linkedChildren.first.student.id;
      });
    }

    final actor = ref.watch(classesActorProvider);
    final perms = actor.permissions;
    final classes = ref.watch(classesControllerProvider);
    final sections = ref.watch(sectionsControllerProvider);
    final subjects = ref.watch(subjectsControllerProvider);
    final curriculum = ref.watch(curriculumControllerProvider);
    final timetable = ref.watch(timetableControllerProvider);
    final assignments = ref.watch(teacherWorkControllerProvider);
    final lookup = ref.watch(classesLookupProvider);

    return AccessGuard(
      allowed: perms.isParent,
      child: ClassesPageFrame(
        title: 'My Child’s Class',
        subtitle: 'Academic information for a linked child',
        child: linkedChildren.isEmpty
            ? const Center(
                child: Text(
                  'No student admission is linked to this parent account.',
                ),
              )
            : _buildSelectedChild(
                context: context,
                ref: ref,
                linkedChildren: linkedChildren,
                selectedChild: selectedChild,
                actor: actor,
                classes: classes,
                sections: sections,
                subjects: subjects,
                curriculum: curriculum,
                timetable: timetable,
                assignments: assignments,
                lookup: lookup,
              ),
      ),
    );
  }

  Widget _buildSelectedChild({
    required BuildContext context,
    required WidgetRef ref,
    required List<StudentAdmissionModel> linkedChildren,
    required StudentAdmissionModel? selectedChild,
    required ClassesActor actor,
    required AsyncValue<List<ClassModel>> classes,
    required AsyncValue<List<SectionModel>> sections,
    required AsyncValue<List<SubjectModel>> subjects,
    required AsyncValue<List<CurriculumModel>> curriculum,
    required AsyncValue<List<TimetableEntryModel>> timetable,
    required AsyncValue<List<TeacherWorkModel>> assignments,
    required ClassesLookup lookup,
  }) {
    return classes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Unable to load your child’s class: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (classList) {
        final child = selectedChild;
        if (child == null ||
            actor.studentId != child.student.id ||
            actor.studentClassId == null ||
            actor.studentSectionId == null) {
          return const Center(
            child: Text(
              'Select a linked child with an active class enrollment.',
            ),
          );
        }
        final classModel = classList
            .where((item) => item.id == actor.studentClassId)
            .firstOrNull;
        if (classModel == null) {
          return const Center(
            child: Text('No active class is linked to this child.'),
          );
        }
        if (sections.isLoading ||
            subjects.isLoading ||
            curriculum.isLoading ||
            timetable.isLoading ||
            assignments.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (sections.hasError ||
            subjects.hasError ||
            curriculum.hasError ||
            timetable.hasError ||
            assignments.hasError) {
          final error =
              sections.error ??
              subjects.error ??
              curriculum.error ??
              timetable.error ??
              assignments.error;
          return Center(
            child: Text(
              'Unable to load your child’s academic information: $error',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final section = sections.valueOrNull
            ?.where((item) => item.id == actor.studentSectionId)
            .firstOrNull;
        final classSubjects = subjects.valueOrNull ?? const [];
        final classCurriculum = curriculum.valueOrNull ?? const [];
        final classTimetable = (timetable.valueOrNull ?? const [])
            .where((entry) => entry.sectionId == actor.studentSectionId)
            .toList();
        final classAssignments = assignments.valueOrNull ?? const [];

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (linkedChildren.length > 1)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    value: child.student.id,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: linkedChildren
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.student.id,
                            child: Text(item.user.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) {
                        ref.read(parentActiveChildIdProvider.notifier).state =
                            id;
                      }
                    },
                  ),
                ),
              ),
            _parentCard(
              context,
              title: child.user.fullName,
              children: [
                _parentDetail('Class', classModel.name),
                _parentDetail(
                  'Section',
                  section?.name ?? child.student.section,
                ),
                _parentDetail('Academic Year', classModel.academicYear),
                if (child.student.rollNumber != null)
                  _parentDetail('Roll Number', child.student.rollNumber!),
              ],
            ),
            _parentCard(
              context,
              title: 'Subjects',
              children: classSubjects.isEmpty
                  ? const [Text('No subjects assigned.')]
                  : classSubjects
                        .map(
                          (subject) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(subject.name),
                            subtitle: Text(subject.code),
                          ),
                        )
                        .toList(),
            ),
            _parentCard(
              context,
              title: 'Curriculum & Progress',
              children: classCurriculum.isEmpty
                  ? const [Text('No curriculum available.')]
                  : classCurriculum
                        .map(
                          (unit) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(unit.title),
                            subtitle: Text(
                              '${unit.completedTopics} of ${unit.topics.length} topics complete',
                            ),
                            trailing: SizedBox(
                              width: 76,
                              child: LinearProgressIndicator(
                                value: unit.progress,
                              ),
                            ),
                          ),
                        )
                        .toList(),
            ),
            _parentCard(
              context,
              title: 'Timetable',
              children: classTimetable.isEmpty
                  ? const [Text('No timetable periods available.')]
                  : classTimetable
                        .map((entry) => _parentTimetable(entry, lookup))
                        .toList(),
            ),
            _parentCard(
              context,
              title: 'Assignments',
              children: classAssignments.isEmpty
                  ? const [Text('No assignments available.')]
                  : classAssignments
                        .map((work) => _parentAssignment(work, lookup))
                        .toList(),
            ),
          ],
        );
      },
    );
  }
}

Widget _parentCard(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

Widget _parentDetail(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    children: [
      SizedBox(width: 130, child: Text(label)),
      Expanded(child: Text(value)),
    ],
  ),
);

Widget _parentTimetable(
  TimetableEntryModel entry,
  ClassesLookup lookup,
) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.schedule_outlined),
  title: Text('Day ${entry.dayOfWeek} · ${entry.startTime}–${entry.endTime}'),
  subtitle: Text(
    entry.isBreak
        ? (entry.title ?? 'Break')
        : '${lookup.subjectName(entry.subjectId)} · ${lookup.teacherName(entry.teacherId)}',
  ),
);

Widget _parentAssignment(
  TeacherWorkModel work,
  ClassesLookup lookup,
) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.assignment_outlined),
  title: Text(work.title),
  subtitle: Text(
    '${lookup.subjectName(work.subjectId)} · ${work.dueDate.toIso8601String().split('T').first} · ${work.status}',
  ),
);
