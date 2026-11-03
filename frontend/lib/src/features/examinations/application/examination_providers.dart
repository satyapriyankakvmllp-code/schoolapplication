import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_conduct_repository.dart';
import '../data/exam_master_repository.dart';
import '../data/exam_paper_repository.dart';
import '../data/exam_planning_repository.dart';
import '../data/exam_result_repository.dart';
import '../data/examination_local_datasource.dart';
import '../data/examination_store.dart';
import '../domain/exam_master_data.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_planning_model.dart';
import '../domain/exam_records_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import 'examination_access.dart';

// ---------------------------------------------------------------------------
// Repositories (all share ONE data source through the store)
// ---------------------------------------------------------------------------
final examinationDataSourceProvider =
    Provider<ExaminationLocalDataSource>((ref) => ExaminationLocalDataSource());

final examDataVersionProvider = StateProvider<int>((ref) => 0);

final examinationStoreProvider = Provider<ExaminationStore>((ref) {
  return ExaminationStore(ref.watch(examinationDataSourceProvider));
});

final examMasterRepositoryProvider = Provider<ExamMasterRepository>((ref) {
  return ExamMasterRepository();
});

final examPaperRepositoryProvider = Provider<ExamPaperRepository>((ref) {
  return ExamPaperRepository(ref.watch(examinationStoreProvider));
});

final examConductRepositoryProvider = Provider<ExamConductRepository>((ref) {
  return ExamConductRepository(ref.watch(examinationStoreProvider));
});

final examResultRepositoryProvider = Provider<ExamResultRepository>((ref) {
  return ExamResultRepository(
    ref.watch(examinationStoreProvider),
    ref.watch(examConductRepositoryProvider),
  );
});

final examPlanningRepositoryProvider = Provider<ExamPlanningRepository>((ref) {
  return ExamPlanningRepository(ref.watch(examinationStoreProvider));
});

/// Tells every screen that examination data changed.
void bumpExamData(WidgetRef ref) {
  ref.read(examDataVersionProvider.notifier).state++;
}

// ---------------------------------------------------------------------------
// Selected exam (shared by all examination screens)
// ---------------------------------------------------------------------------
final selectedExamIdProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Data providers. All watch the data version so they refresh by themselves.
// ---------------------------------------------------------------------------
final examMasterProvider = FutureProvider.autoDispose<ExamMasterData>((ref) async {
  ref.watch(examDataVersionProvider);
  List<Map<String, dynamic>> extra = const [];
  try {
    final store = ref.watch(examinationStoreProvider);
    extra = store.listOf(await store.load(), 'syllabus_topics');
  } catch (_) {}
  return ref.watch(examMasterRepositoryProvider).load(extraChapters: extra);
});

/// Every exam the current role may see (all years), used by exam selectors.
final allExamsProvider = FutureProvider.autoDispose<List<ExamSchedule>>((ref) async {
  ref.watch(examDataVersionProvider);
  final actor = ref.watch(currentExamActorProvider);
  final list = await ref.watch(examRepositoryProvider).getExams(actor: actor);
  list.sort((a, b) => b.startDate.compareTo(a.startDate));
  return list;
});

final examPapersProvider =
    FutureProvider.autoDispose.family<List<ExamPaper>, String?>((ref, examId) async {
  ref.watch(examDataVersionProvider);
  if (examId == null) return const [];
  return ref.watch(examPaperRepositoryProvider).getPapers(examId: examId);
});

final hallTicketsProvider =
    FutureProvider.autoDispose.family<List<HallTicket>, String?>((ref, examId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examConductRepositoryProvider).getHallTickets(examId: examId);
});

final attendanceForExamProvider =
    FutureProvider.autoDispose.family<List<ExamAttendance>, String?>((ref, examId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examConductRepositoryProvider).getAttendance(examId: examId);
});

final marksForExamProvider =
    FutureProvider.autoDispose.family<List<ExamMark>, String?>((ref, examId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examConductRepositoryProvider).getMarks(examId: examId);
});

typedef ExamSectionKey = ({String examId, String sectionId});

final remarksProvider =
    FutureProvider.autoDispose.family<List<StudentRemarks>, ExamSectionKey>((ref, key) async {
  ref.watch(examDataVersionProvider);
  return ref
      .watch(examConductRepositoryProvider)
      .getRemarks(examId: key.examId, sectionId: key.sectionId);
});

typedef ReportCardQuery = ({String? examId, String? sectionId, String? studentId, bool published});

final reportCardsProvider =
    FutureProvider.autoDispose.family<List<ReportCard>, ReportCardQuery>((ref, q) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examResultRepositoryProvider).getReportCards(
        examId: q.examId,
        sectionId: q.sectionId,
        studentId: q.studentId,
        publishedOnly: q.published,
      );
});

final gradeScaleProvider = FutureProvider.autoDispose<List<GradeBand>>((ref) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examResultRepositoryProvider).getGradeScale();
});

final patternsProvider =
    FutureProvider.autoDispose.family<List<ExamPattern>, String?>((ref, examId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examPlanningRepositoryProvider).getPatterns(examId: examId);
});

final questionsProvider =
    FutureProvider.autoDispose.family<List<Question>, String?>((ref, subjectId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examPlanningRepositoryProvider).getQuestions(subjectId: subjectId);
});

final questionPapersProvider =
    FutureProvider.autoDispose.family<List<QuestionPaper>, String?>((ref, examPaperId) async {
  ref.watch(examDataVersionProvider);
  return ref.watch(examPlanningRepositoryProvider).getQuestionPapers(examPaperId: examPaperId);
});
