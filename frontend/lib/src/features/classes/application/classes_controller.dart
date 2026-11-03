import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/class_model.dart';
import 'classes_access.dart';
import 'classroom_controller.dart';
import 'curriculum_controller.dart';
import 'daily_lessons_controller.dart';
import 'sections_controller.dart';
import 'subjects_controller.dart';
import 'timetable_controller.dart';

final classesControllerProvider =
    AsyncNotifierProvider<ClassesController, List<ClassModel>>(ClassesController.new);

final classFieldDefinitionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(classesRepositoryProvider).getClassFieldDefinitions(
        ref.watch(classesActorProvider),
      );
});

class ClassesController extends AsyncNotifier<List<ClassModel>> {
  @override
  Future<List<ClassModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getClasses(actor);
  }

  void _refreshDependents() {
    ref.invalidateSelf();
    ref.invalidate(sectionsControllerProvider);
    ref.invalidate(classroomControllerProvider);
    ref.invalidate(subjectsControllerProvider);
    ref.invalidate(curriculumControllerProvider);
    ref.invalidate(dailyLessonsControllerProvider);
    ref.invalidate(timetableControllerProvider);
  }

  Future<void> save(ClassModel model, {bool isNew = false}) async {
    await ref.read(classesRepositoryProvider).saveClass(ref.read(classesActorProvider), model, isNew: isNew);
    _refreshDependents();
  }

  Future<void> saveFieldDefinition(String name) async {
    await ref.read(classesRepositoryProvider).saveClassFieldDefinition(
          ref.read(classesActorProvider),
          name,
        );
    ref.invalidate(classFieldDefinitionsProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteClass(ref.read(classesActorProvider), id);
    _refreshDependents();
  }

  Future<void> assignClassTeacher(String classId, String? teacherId) async {
    await ref
        .read(classesRepositoryProvider)
        .assignClassTeacher(ref.read(classesActorProvider), classId, teacherId);
    _refreshDependents();
  }
}
