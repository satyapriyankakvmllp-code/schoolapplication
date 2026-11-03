import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/daily_lesson_model.dart';
import 'classes_access.dart';

final dailyLessonsControllerProvider =
    AsyncNotifierProvider<DailyLessonsController, List<DailyLessonModel>>(DailyLessonsController.new);

class DailyLessonsController extends AsyncNotifier<List<DailyLessonModel>> {
  @override
  Future<List<DailyLessonModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getLessons(actor);
  }

  Future<void> save(DailyLessonModel lesson, {bool isNew = false}) async {
    await ref.read(classesRepositoryProvider).saveLesson(ref.read(classesActorProvider), lesson, isNew: isNew);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteLesson(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
  }
}
