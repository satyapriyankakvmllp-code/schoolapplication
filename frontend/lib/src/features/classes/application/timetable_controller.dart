import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/timetable_entry_model.dart';
import 'classes_access.dart';

final timetableControllerProvider =
    AsyncNotifierProvider<TimetableController, List<TimetableEntryModel>>(TimetableController.new);

class TimetableController extends AsyncNotifier<List<TimetableEntryModel>> {
  @override
  Future<List<TimetableEntryModel>> build() {
    final actor = ref.watch(classesActorProvider);
    return ref.watch(classesRepositoryProvider).getTimetable(actor);
  }

  Future<void> save(TimetableEntryModel entry, {bool isNew = false}) async {
    await ref
        .read(classesRepositoryProvider)
        .saveTimetableEntry(ref.read(classesActorProvider), entry, isNew: isNew);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(classesRepositoryProvider).deleteTimetableEntry(ref.read(classesActorProvider), id);
    ref.invalidateSelf();
  }
}
