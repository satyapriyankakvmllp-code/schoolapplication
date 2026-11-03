import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/subject_model.dart';
import 'classes_access.dart';
import 'curriculum_controller.dart';
import 'daily_lessons_controller.dart';
import 'timetable_controller.dart';

final subjectsControllerProvider =
    AsyncNotifierProvider<SubjectsController, List<SubjectModel>>(SubjectsController.new);

class SubjectsController extends AsyncNotifier<List<SubjectModel>> {
  @override
  Future<List<SubjectModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getSubjects(actor);
  }

  void _refreshDependents() {
    ref.invalidateSelf();
    ref.invalidate(curriculumControllerProvider);
    ref.invalidate(dailyLessonsControllerProvider);
    ref.invalidate(timetableControllerProvider);
  }

  Future<SubjectModel> save(SubjectModel subject, {bool isNew = false}) async {
    final saved = await ref.read(classesRepositoryProvider).saveSubject(
          ref.read(classesActorProvider),
          subject,
          isNew: isNew,
        );
    _refreshDependents();
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteSubject(ref.read(classesActorProvider), id);
    _refreshDependents();
  }

  Future<void> assignTeacher(String subjectId, String? teacherId) async {
    await ref
        .read(classesRepositoryProvider)
        .assignSubjectTeacher(ref.read(classesActorProvider), subjectId, teacherId);
    _refreshDependents();
  }
}
