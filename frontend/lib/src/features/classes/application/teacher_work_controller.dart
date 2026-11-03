import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/teacher_work_model.dart';
import 'classes_access.dart';

final teacherWorkControllerProvider =
    AsyncNotifierProvider<TeacherWorkController, List<TeacherWorkModel>>(
  TeacherWorkController.new,
);

class TeacherWorkController extends AsyncNotifier<List<TeacherWorkModel>> {
  @override
  FutureOr<List<TeacherWorkModel>> build() async {
    final ds = ref.watch(classesRepositoryProvider);
    final actor = ref.watch(classesActorProvider);
    return ds.getTeacherWork(actor);
  }

  Future<void> save(TeacherWorkModel model, {bool isNew = false}) async {
    final ds = ref.read(classesRepositoryProvider);
    final actor = ref.read(classesActorProvider);
    await ds.saveTeacherWork(actor, model, isNew: isNew);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final ds = ref.read(classesRepositoryProvider);
    final actor = ref.read(classesActorProvider);
    await ds.deleteTeacherWork(actor, id);
    ref.invalidateSelf();
  }
}
