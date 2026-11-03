import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/curriculum_controller.dart';
import '../../application/sections_controller.dart';
import '../../application/subjects_controller.dart';
import '../../application/teacher_work_controller.dart';
import '../../application/timetable_controller.dart';
import '../../domain/teacher_work_model.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Read-only academic portal for the signed-in student's own enrollment.
class StudentClassScreen extends ConsumerWidget {
  const StudentClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(classesActorProvider);
    final perms = actor.permissions;
    final classes = ref.watch(classesControllerProvider);
    final sections = ref.watch(sectionsControllerProvider);
    final subjects = ref.watch(subjectsControllerProvider);
    final curriculum = ref.watch(curriculumControllerProvider);
    final timetable = ref.watch(timetableControllerProvider);
    final assignments = ref.watch(teacherWorkControllerProvider);
    final lookup = ref.watch(classesLookupProvider);
    final admissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];

    return AccessGuard(
      allowed: perms.isStudent,
      child: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Unable to load your class: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (classList) {
          final classId = actor.studentClassId;
          final classModel = classId == null
              ? null
              : classList.where((item) => item.id == classId).firstOrNull;
          if (classModel == null ||
              actor.studentId == null ||
              actor.studentSectionId == null) {
            return const ClassesPageFrame(
              title: 'My Class',
              child: Center(
                child: Text(
                  'No active class and section are linked to your student account.',
                ),
              ),
            );
          }

          final section = sections.valueOrNull
              ?.where((item) => item.id == actor.studentSectionId)
              .firstOrNull;
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
                'Unable to load your academic information: $error',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final mySubjects = subjects.valueOrNull ?? const [];
          final myCurriculum = curriculum.valueOrNull ?? const [];
          final myTimetable = (timetable.valueOrNull ?? const [])
              .where((entry) => entry.sectionId == actor.studentSectionId)
              .toList();
          final myAssignments = assignments.valueOrNull ?? const [];
          final myAdmission = admissions
              .where((item) => item.student.id == actor.studentId)
              .firstOrNull;

          return ClassesPageFrame(
            title: 'My Class',
            subtitle: 'Your class, section, and academic information',
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _portalCard(
                  context,
                  title: myAdmission?.user.fullName ?? 'Student',
                  children: [
                    _detailLine('Class', classModel.name),
                    _detailLine(
                      'Section',
                      section?.name ?? actor.studentSection ?? '—',
                    ),
                    _detailLine('Academic Year', classModel.academicYear),
                    if (myAdmission?.student.rollNumber != null)
                      _detailLine(
                        'Roll Number',
                        myAdmission!.student.rollNumber!,
                      ),
                  ],
                ),
                _portalCard(
                  context,
                  title: 'My Subjects',
                  children: mySubjects.isEmpty
                      ? const [Text('No subjects assigned.')]
                      : mySubjects
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
                _portalCard(
                  context,
                  title: 'Curriculum & Progress',
                  children: myCurriculum.isEmpty
                      ? const [Text('No curriculum available.')]
                      : myCurriculum
                            .map(
                              (unit) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(unit.title),
                                subtitle: Text(
                                  '${unit.completedTopics} of ${unit.topics.length} topics complete · ${(unit.progress * 100).round()}%',
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
                _portalCard(
                  context,
                  title: 'My Timetable',
                  children: myTimetable.isEmpty
                      ? const [Text('No timetable periods available.')]
                      : myTimetable
                            .map((entry) => _timetableLine(entry, lookup))
                            .toList(),
                ),
                _portalCard(
                  context,
                  title: 'My Assignments',
                  children: myAssignments.isEmpty
                      ? const [Text('No assignments available.')]
                      : myAssignments
                            .map((work) => _assignmentLine(work, lookup))
                            .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _portalCard(
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

Widget _detailLine(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    children: [
      SizedBox(width: 130, child: Text(label)),
      Expanded(child: Text(value)),
    ],
  ),
);

Widget _timetableLine(
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

Widget _assignmentLine(TeacherWorkModel work, ClassesLookup lookup) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.assignment_outlined),
  title: Text(work.title),
  subtitle: Text(
    '${lookup.subjectName(work.subjectId)} · ${work.dueDate.toIso8601String().split('T').first} · ${work.status}',
  ),
);
