import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/exam_schedule_model.dart';
import 'examination_access.dart';

class ExamFilterState {
  final String searchQuery;
  final String? academicYear;
  final String? examType;
  final String? status;

  const ExamFilterState({
    this.searchQuery = '',
    this.academicYear = '2026-2027',
    this.examType,
    this.status,
  });

  ExamFilterState copyWith({
    String? searchQuery,
    String? academicYear,
    String? examType,
    String? status,
  }) {
    return ExamFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      academicYear: academicYear ?? this.academicYear,
      examType: examType ?? this.examType,
      status: status ?? this.status,
    );
  }
}

final examFilterProvider = StateProvider<ExamFilterState>((ref) {
  final setup = ref.watch(globalSetupProvider).valueOrNull;
  final defaultYear = setup?.currentAcademicYear ?? '2026-2027';
  return ExamFilterState(academicYear: defaultYear);
});

class ExamSummaryStats {
  final int total;
  final int upcoming; // PLANNED
  final int ongoing; // ONGOING
  final int completed; // COMPLETED

  const ExamSummaryStats({
    required this.total,
    required this.upcoming,
    required this.ongoing,
    required this.completed,
  });

  factory ExamSummaryStats.fromExams(List<ExamSchedule> exams) {
    int upcoming = 0;
    int ongoing = 0;
    int completed = 0;

    for (final e in exams) {
      if (e.isPlanned) {
        upcoming++;
      } else if (e.isOngoing) {
        ongoing++;
      } else if (e.isCompleted) {
        completed++;
      }
    }

    return ExamSummaryStats(
      total: exams.length,
      upcoming: upcoming,
      ongoing: ongoing,
      completed: completed,
    );
  }
}

final examListControllerProvider =
    AsyncNotifierProvider<ExamListController, List<ExamSchedule>>(() {
  return ExamListController();
});

class ExamListController extends AsyncNotifier<List<ExamSchedule>> {
  @override
  Future<List<ExamSchedule>> build() async {
    final repo = ref.watch(examRepositoryProvider);
    final actor = ref.watch(currentExamActorProvider);
    final filter = ref.watch(examFilterProvider);

    return repo.getExams(
      searchQuery: filter.searchQuery,
      academicYear: filter.academicYear,
      examType: filter.examType,
      status: filter.status,
      actor: actor,
    );
  }

  Future<void> refreshExams() async {
    ref.invalidateSelf();
    await future;
  }

  Future<ExamSchedule> createExam(ExamSchedule exam) async {
    final repo = ref.read(examRepositoryProvider);
    final actor = ref.read(currentExamActorProvider);

    final created = await repo.createExam(exam, actor: actor);
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<ExamSchedule> updateExam(ExamSchedule exam) async {
    final repo = ref.read(examRepositoryProvider);
    final actor = ref.read(currentExamActorProvider);

    final updated = await repo.updateExam(exam, actor: actor);
    ref.invalidateSelf();
    await future;
    return updated;
  }

  Future<ExamSchedule> cancelExam(String id, String reason) async {
    final repo = ref.read(examRepositoryProvider);
    final actor = ref.read(currentExamActorProvider);

    final cancelled = await repo.cancelExam(id, reason, actor: actor);
    ref.invalidateSelf();
    await future;
    return cancelled;
  }

  Future<void> deleteExam(String id) async {
    final repo = ref.read(examRepositoryProvider);
    final actor = ref.read(currentExamActorProvider);

    await repo.deleteExam(id, actor: actor);
    ref.invalidateSelf();
    await future;
  }

  Future<ExamLinkedDataCounts> getLinkedDataCounts(String id) async {
    final repo = ref.read(examRepositoryProvider);
    return repo.getLinkedDataCounts(id);
  }

  Future<void> resetDemoData() async {
    final repo = ref.read(examRepositoryProvider);
    await repo.resetDemoData();
    ref.read(globalSetupProvider.notifier).reload();
    ref.invalidateSelf();
    await future;
  }
}

/// Dynamic summary cards derived from the active exam list.
/// Updates immediately whenever any exam is created, edited, cancelled, or deleted!
final examSummaryStatsProvider = Provider<ExamSummaryStats>((ref) {
  final examsAsync = ref.watch(examListControllerProvider);
  final list = examsAsync.valueOrNull ?? const [];
  return ExamSummaryStats.fromExams(list);
});

/// Individual exam details provider
final examDetailsProvider =
    FutureProvider.family<ExamSchedule?, String>((ref, id) async {
  // Re-fetch when list controller updates
  ref.watch(examListControllerProvider);
  final repo = ref.watch(examRepositoryProvider);
  final actor = ref.watch(currentExamActorProvider);
  return repo.getExamById(id, actor: actor);
});
