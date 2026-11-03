import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/classroom_model.dart';
import 'classes_access.dart';
import 'classes_controller.dart';
import 'sections_controller.dart';
import 'timetable_controller.dart';

final classroomControllerProvider =
    AsyncNotifierProvider<ClassroomController, List<ClassroomModel>>(ClassroomController.new);

class ClassroomController extends AsyncNotifier<List<ClassroomModel>> {
  @override
  Future<List<ClassroomModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getClassrooms(actor);
  }

  Future<ClassroomModel> save(ClassroomModel room, {bool isNew = false}) async {
    final saved = await ref.read(classesRepositoryProvider).saveClassroom(ref.read(classesActorProvider), room, isNew: isNew);
    ref.invalidateSelf();
    ref.invalidate(classesControllerProvider);
    ref.invalidate(sectionsControllerProvider);
    ref.invalidate(timetableControllerProvider);
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteClassroom(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
    ref.invalidate(classesControllerProvider);
    ref.invalidate(sectionsControllerProvider);
    ref.invalidate(timetableControllerProvider);
  }
}
