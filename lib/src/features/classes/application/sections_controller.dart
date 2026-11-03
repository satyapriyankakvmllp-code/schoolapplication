import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/section_model.dart';
import 'classes_access.dart';
import 'timetable_controller.dart';

final sectionsControllerProvider =
    AsyncNotifierProvider<SectionsController, List<SectionModel>>(SectionsController.new);

class SectionsController extends AsyncNotifier<List<SectionModel>> {
  @override
  Future<List<SectionModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getSections(actor);
  }

  Future<void> save(SectionModel section, {bool isNew = false}) async {
    await ref.read(classesRepositoryProvider).saveSection(ref.read(classesActorProvider), section, isNew: isNew);
    ref.invalidateSelf();
    ref.invalidate(timetableControllerProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteSection(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
    ref.invalidate(timetableControllerProvider);
  }
}
