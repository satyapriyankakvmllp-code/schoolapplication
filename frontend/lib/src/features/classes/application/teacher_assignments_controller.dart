import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/class_teacher_assignment_model.dart';
import 'classes_access.dart';
import 'classes_controller.dart';
import 'classroom_controller.dart';
import 'sections_controller.dart';
import 'subjects_controller.dart';

final teacherAssignmentsControllerProvider =
    AsyncNotifierProvider<TeacherAssignmentsController, List<ClassTeacherAssignmentModel>>(
        TeacherAssignmentsController.new);

/// View + add only. There is intentionally no delete: admins may view teacher
/// assignments but must not remove them.
class TeacherAssignmentsController extends AsyncNotifier<List<ClassTeacherAssignmentModel>> {
  @override
  Future<List<ClassTeacherAssignmentModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getTeacherAssignments(actor);
  }

  Future<void> add(ClassTeacherAssignmentModel model) async {
    await ref.read(classesRepositoryProvider).saveTeacherAssignment(ref.read(classesActorProvider), model);
    ref.invalidateSelf();
    ref.invalidate(subjectsControllerProvider);
    ref.invalidate(classesControllerProvider);
    ref.invalidate(sectionsControllerProvider);
    ref.invalidate(classroomControllerProvider);
  }

  Future<void> remove(String id) async {
    await ref.read(classesRepositoryProvider).deleteTeacherAssignment(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
    ref.invalidate(subjectsControllerProvider);
    ref.invalidate(classesControllerProvider);
    ref.invalidate(sectionsControllerProvider);
    ref.invalidate(classroomControllerProvider);
  }
}
