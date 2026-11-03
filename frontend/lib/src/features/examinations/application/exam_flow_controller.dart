import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_flow_repository.dart';
import '../domain/exam_flow_models.dart';
import '../domain/exam_timetable_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import 'exam_controller.dart';
import 'examination_access.dart';

final examFlowRepositoryProvider =
    Provider<ExamFlowRepository>((ref) => ExamFlowRepository());

final studentsProvider = FutureProvider<List<StudentRef>>(
    (ref) => ref.watch(examFlowRepositoryProvider).getStudents());

final hallTicketsProvider = FutureProvider.family<List<HallTicket>, String>(
    (ref, examId) => ref.watch(examFlowRepositoryProvider).getHallTickets(examId));

final attendanceProvider = FutureProvider.family<List<AttendanceRecord>, String>(
    (ref, paperId) => ref.watch(examFlowRepositoryProvider).getAttendance(paperId));

final marksProvider = FutureProvider.family<List<StudentMark>, String>(
    (ref, paperId) => ref.watch(examFlowRepositoryProvider).getMarks(paperId));

final examMarksProvider = FutureProvider.family<List<StudentMark>, String>(
    (ref, examId) => ref.watch(examFlowRepositoryProvider).getMarksForExam(examId));

final reportCardsProvider = FutureProvider.family<List<ReportCard>, String>(
    (ref, examId) => ref.watch(examFlowRepositoryProvider).getReportCards(examId));

final studentReportCardsProvider = FutureProvider.family<List<ReportCard>, bool>(
    (ref, staff) => ref.watch(examFlowRepositoryProvider).getStudentReportCards(
        ExamFlowRepository.demoStudentId,
        publishedOnly: !staff));

final syllabusProvider = FutureProvider<List<SyllabusChapter>>(
    (ref) => ref.watch(examFlowRepositoryProvider).getSyllabus());

final filteredSyllabusProvider = FutureProvider.family<List<SyllabusChapter>, ({String? classId, String? sectionId, String? subjectId})>(
    (ref, filter) => ref.watch(examFlowRepositoryProvider).getSyllabus(
        classId: filter.classId,
        sectionId: filter.sectionId,
        subjectId: filter.subjectId));

final examPatternsProvider = FutureProvider.family<List<ExamPattern>, String>(
    (ref, examId) => ref.watch(examFlowRepositoryProvider).getExamPatterns(examScheduleId: examId));

final questionPapersProvider = FutureProvider.family<List<UploadedQuestionPaper>, String>(
    (ref, examId) => ref.watch(examFlowRepositoryProvider).getQuestionPapers(examScheduleId: examId));

class ExamFlowActions {
  final Ref ref;
  ExamFlowActions(this.ref);
  ExamFlowRepository get _r => ref.read(examFlowRepositoryProvider);
  ExaminationActor get _a => ref.read(currentExamActorProvider);

  void refreshAll(String examId) {
    ref.invalidate(hallTicketsProvider(examId));
    ref.invalidate(examMarksProvider(examId));
    ref.invalidate(reportCardsProvider(examId));
    ref.invalidate(studentReportCardsProvider);
    ref.invalidate(attendanceProvider);
    ref.invalidate(marksProvider);
    ref.invalidate(examPatternsProvider(examId));
    ref.invalidate(questionPapersProvider(examId));
    ref.invalidate(examListControllerProvider);
  }

  Future<Map<String, int>> generateTickets(
    ExamSchedule e, {
    String? sectionId,
    List<String>? selectedStudentIds,
  }) async {
    final res = await _r.generateHallTickets(
      e,
      _a,
      sectionId: sectionId,
      selectedStudentIds: selectedStudentIds,
    );
    refreshAll(e.examScheduleId);
    return res;
  }

  Future<void> ticketStatus(String examId, String id, String status) async {
    await _r.setHallTicketStatus(id, status, _a);
    refreshAll(examId);
  }

  Future<void> saveTicket(HallTicket ticket) async {
    await _r.saveHallTicket(ticket, _a);
    refreshAll(ticket.examScheduleId);
  }

  Future<void> saveAttendance(
      String examId, ExamTimetableEntry p, Map<String, String> s, Map<String, String> rem) async {
    await _r.saveAttendance(p, s, rem, _a);
    refreshAll(examId);
  }

  Future<void> saveMarks(
      String examId, ExamTimetableEntry p, Map<String, double?> v, bool submit) async {
    await _r.saveMarks(p, v, submit, _a);
    refreshAll(examId);
  }

  Future<int> markUnderReview(String examId, String paperId) async {
    final count = await _r.markUnderReview(paperId, _a);
    refreshAll(examId);
    return count;
  }

  Future<void> rejectMark(String examId, String markId, String reason) async {
    await _r.rejectMark(markId, reason, _a);
    refreshAll(examId);
  }

  Future<void> approveMark(String examId, String markId) async {
    await _r.approveMark(markId, _a);
    refreshAll(examId);
  }

  Future<int> bulkApproveMarks(String examId, {String? paperId, String? sectionId}) async {
    final n = await _r.bulkApproveMarks(
      examId: examId,
      paperId: paperId,
      sectionId: sectionId,
      a: _a,
    );
    refreshAll(examId);
    return n;
  }

  Future<int> calculate(ExamSchedule e, {String? sectionId}) async {
    final n = await _r.calculateResults(e, _a, sectionId: sectionId);
    refreshAll(e.examScheduleId);
    return n;
  }

  Future<int> advance(String examId, String action) async {
    final n = await _r.advanceReportCards(examId, action, _a);
    refreshAll(examId);
    return n;
  }

  Future<void> remarks(
    String examId,
    String cardId, {
    String? inchargeRemarks,
    String? principalRemarks,
  }) async {
    await _r.saveRemarks(
      cardId: cardId,
      inchargeRemarks: inchargeRemarks,
      principalRemarks: principalRemarks,
      a: _a,
    );
    refreshAll(examId);
  }

  Future<SyllabusChapter> saveSyllabus(SyllabusChapter chapter) async {
    final res = await _r.saveSyllabusChapter(chapter, _a);
    ref.invalidate(syllabusProvider);
    ref.invalidate(filteredSyllabusProvider);
    return res;
  }

  Future<void> deleteSyllabus(String chapterId) async {
    await _r.deleteSyllabusChapter(chapterId, _a);
    ref.invalidate(syllabusProvider);
    ref.invalidate(filteredSyllabusProvider);
  }

  Future<ExamPattern> savePattern(ExamPattern pattern) async {
    final res = await _r.saveExamPattern(pattern, _a);
    ref.invalidate(examPatternsProvider(pattern.examScheduleId));
    return res;
  }

  Future<void> deletePattern(String examId, String patternId) async {
    await _r.deleteExamPattern(patternId, _a);
    ref.invalidate(examPatternsProvider(examId));
  }

  Future<UploadedQuestionPaper> uploadPaper(UploadedQuestionPaper paper) async {
    final res = await _r.uploadQuestionPaper(paper, _a);
    ref.invalidate(questionPapersProvider(paper.examScheduleId));
    return res;
  }

  Future<void> reviewPaper(String examId, String paperId, String status, [String? remarks]) async {
    await _r.reviewQuestionPaper(paperId, status, remarks, _a);
    ref.invalidate(questionPapersProvider(examId));
  }

  Future<void> deletePaper(String examId, String paperId) async {
    await _r.deleteQuestionPaper(paperId, _a);
    ref.invalidate(questionPapersProvider(examId));
  }
}

final examFlowActionsProvider = Provider<ExamFlowActions>((ref) => ExamFlowActions(ref));
