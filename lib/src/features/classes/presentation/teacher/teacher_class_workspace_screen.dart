import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/curriculum_controller.dart';
import '../../application/subjects_controller.dart';
import '../../application/teacher_work_controller.dart';
import '../../application/timetable_controller.dart';
import '../../domain/teacher_work_model.dart';
import '../../domain/timetable_entry_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Teacher-only view of the subjects, timetable, curriculum, and work they teach.
class TeacherClassWorkspaceScreen extends ConsumerWidget {
  final String classId;

  const TeacherClassWorkspaceScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final classes = ref.watch(classesControllerProvider);
    final subjects = ref.watch(subjectsControllerProvider);
    final curriculum = ref.watch(curriculumControllerProvider);
    final timetable = ref.watch(timetableControllerProvider);
    final assignments = ref.watch(teacherWorkControllerProvider);
    final lookup = ref.watch(classesLookupProvider);

    return AccessGuard(
      allowed: perms.isTeacher,
      child: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Unable to load your class: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (classList) {
          final classModel = classList
              .where((item) => item.id == classId)
              .firstOrNull;
          if (classModel == null) {
            return const ClassesPageFrame(
              title: 'Class',
              child: Center(
                child: Text('This class is not assigned to your account.'),
              ),
            );
          }
          if (subjects.isLoading ||
              curriculum.isLoading ||
              timetable.isLoading ||
              assignments.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (subjects.hasError ||
              curriculum.hasError ||
              timetable.hasError ||
              assignments.hasError) {
            final error =
                subjects.error ??
                curriculum.error ??
                timetable.error ??
                assignments.error;
            return Center(
              child: Text(
                'Unable to load class information: $error',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final classSubjects = (subjects.valueOrNull ?? const [])
              .where((item) => item.classId == classId)
              .toList();
          final classCurriculum = (curriculum.valueOrNull ?? const [])
              .where((item) => item.classId == classId)
              .toList();
          final classTimetable = (timetable.valueOrNull ?? const [])
              .where((item) => item.classId == classId)
              .toList();
          final classAssignments = (assignments.valueOrNull ?? const [])
              .where((item) => item.classId == classId)
              .toList();

          return ClassesPageFrame(
            title: classModel.name,
            subtitle: 'Your assigned subjects and weekly teaching work',
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _teacherCard(
                  context,
                  'My Subjects',
                  classSubjects.isEmpty
                      ? const [
                          Text('No subjects assigned to you in this class.'),
                        ]
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
                _teacherCard(
                  context,
                  'My Curriculum',
                  classCurriculum.isEmpty
                      ? const [
                          Text('No curriculum available for your subjects.'),
                        ]
                      : classCurriculum
                            .map(
                              (unit) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(unit.title),
                                subtitle: Text(
                                  '${lookup.subjectName(unit.subjectId)} · ${unit.completedTopics}/${unit.topics.length} topics covered',
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
                _teacherCard(
                  context,
                  'My Weekly Periods',
                  classTimetable.isEmpty
                      ? const [Text('No periods assigned to you.')]
                      : classTimetable
                            .map((period) => _teacherPeriod(period, lookup))
                            .toList(),
                ),
                _teacherCard(
                  context,
                  'My Assignments',
                  classAssignments.isEmpty
                      ? const [
                          Text('No assignments created by you for this class.'),
                        ]
                      : classAssignments
                            .map((work) => _teacherWork(work, lookup))
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

Widget _teacherCard(
  BuildContext context,
  String title,
  List<Widget> children,
) => Card(
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

Widget _teacherPeriod(
  TimetableEntryModel period,
  ClassesLookup lookup,
) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.schedule_outlined),
  title: Text(
    'Day ${period.dayOfWeek} · ${period.startTime}–${period.endTime}',
  ),
  subtitle: Text(
    period.isBreak
        ? (period.title ?? 'Break')
        : '${lookup.subjectName(period.subjectId)} · ${lookup.teacherName(period.teacherId)}',
  ),
);

Widget _teacherWork(TeacherWorkModel work, ClassesLookup lookup) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.assignment_outlined),
  title: Text(work.title),
  subtitle: Text(
    '${lookup.subjectName(work.subjectId)} · ${work.dueDate.toIso8601String().split('T').first} · ${work.status}',
  ),
);
