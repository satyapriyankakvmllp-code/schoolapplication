import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_repository.dart';
import '../data/examination_local_datasource.dart';
import '../domain/examination_actor.dart';
import '../domain/global_setup_model.dart';

/// ONE shared data source, so every repository sees the same cached JSON.
final examinationDataSourceProvider = Provider<ExaminationLocalDataSource>((ref) {
  return ExaminationLocalDataSource();
});

/// Bumped after any change to examination data. Screens that watch it
/// refresh immediately (for example the Papers count on the Exam list).
final examDataVersionProvider = StateProvider<int>((ref) => 0);

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return LocalExamRepository(
    localDataSource: ref.watch(examinationDataSourceProvider),
  );
});

/// Global setup provider (reads global.json)
final globalSetupProvider = AsyncNotifierProvider<GlobalSetupNotifier, GlobalSetup>(() {
  return GlobalSetupNotifier();
});

class GlobalSetupNotifier extends AsyncNotifier<GlobalSetup> {
  @override
  Future<GlobalSetup> build() async {
    final repo = ref.watch(examRepositoryProvider);
    return repo.getGlobalSetup();
  }

  Future<void> switchUser(String userId) async {
    final repo = ref.read(examRepositoryProvider);
    await repo.setCurrentUser(userId);
    ref.invalidateSelf();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
  }
}

/// Active user / role for the examination module
final currentExamActorProvider = Provider<ExaminationActor>((ref) {
  final setupAsync = ref.watch(globalSetupProvider);
  final setup = setupAsync.valueOrNull;

  if (setup != null && setup.currentUser != null) {
    return ExaminationActor.fromGlobalUser(setup.currentUser!);
  }

  // Fallback default admin
  return const ExaminationActor(
    userId: 'u1',
    name: 'Admin',
    role: ExamRole.admin,
  );
});

final examinationPermissionsProvider = Provider<ExaminationPermissions>((ref) {
  return ref.watch(currentExamActorProvider).permissions;
});

