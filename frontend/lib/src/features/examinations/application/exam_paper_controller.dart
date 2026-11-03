import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_paper_repository.dart';
import '../domain/exam_timetable_model.dart';
import '../domain/exam_reference_model.dart';
import '../domain/exam_schedule_model.dart';
import 'exam_controller.dart';
import 'examination_access.dart';

final examPaperRepositoryProvider =
    Provider<ExamTimetableRepository>((ref) => ExamTimetableRepository());

final examReferenceProvider = FutureProvider<ExamReferenceData>(
    (ref) => ref.watch(examPaperRepositoryProvider).getReferenceData());

/// Exam Timetable Provider (aliased to examPapersProvider for backwards-compatibility)
final examTimetableProvider =
    FutureProvider.family<List<ExamTimetableEntry>, String>((ref, examId) {
  return ref.watch(examPaperRepositoryProvider).getPapers(examId);
});

final examPapersProvider = examTimetableProvider;

/// Timetable Mutations. Each mutation refreshes the timetable list AND the
/// Screen 1 exam list so the paper/timetable counts stay strictly synchronized.
class ExamTimetableActions {
  final Ref ref;
  ExamTimetableActions(this.ref);

  void _refresh(String examId) {
    ref.invalidate(examTimetableProvider(examId));
    ref.invalidate(examListControllerProvider);
    ref.invalidate(examDetailsProvider(examId));
  }

  Future<void> add(ExamTimetableEntry p, ExamSchedule exam) async {
    await ref.read(examPaperRepositoryProvider).addPaper(p, exam,
        actor: ref.read(currentExamActorProvider));
    _refresh(exam.examScheduleId);
  }

  Future<void> update(ExamTimetableEntry p, ExamSchedule exam) async {
    await ref.read(examPaperRepositoryProvider).updatePaper(p, exam,
        actor: ref.read(currentExamActorProvider));
    _refresh(exam.examScheduleId);
  }

  Future<void> delete(String id, ExamSchedule exam) async {
    await ref.read(examPaperRepositoryProvider).deletePaper(id, exam,
        actor: ref.read(currentExamActorProvider));
    _refresh(exam.examScheduleId);
  }
}

final examTimetableActionsProvider =
    Provider<ExamTimetableActions>((ref) => ExamTimetableActions(ref));

final examPaperActionsProvider = examTimetableActionsProvider;
