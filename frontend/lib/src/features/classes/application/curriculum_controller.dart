import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/curriculum_model.dart';
import 'classes_access.dart';

final curriculumControllerProvider =
    AsyncNotifierProvider<CurriculumController, List<CurriculumModel>>(CurriculumController.new);

class CurriculumController extends AsyncNotifier<List<CurriculumModel>> {
  @override
  Future<List<CurriculumModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getCurriculum(actor);
  }

  Future<void> save(CurriculumModel model, {bool isNew = false}) async {
    await ref.read(classesRepositoryProvider).saveCurriculum(ref.read(classesActorProvider), model, isNew: isNew);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteCurriculum(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
  }

  Future<void> updateProgress(String id, int completedTopics) async {
    await ref.read(classesRepositoryProvider).updateProgress(ref.read(classesActorProvider), id, completedTopics);
    ref.invalidateSelf();
  }
}
