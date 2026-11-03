import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/examinations/data/examination_local_datasource.dart';
import 'package:frontend/src/features/examinations/data/examination_store.dart';
import 'package:frontend/src/features/examinations/data/exam_repository.dart';
import 'package:frontend/src/features/examinations/data/exam_paper_repository.dart';
import 'package:frontend/src/features/examinations/data/exam_conduct_repository.dart';
import 'package:frontend/src/features/examinations/data/exam_result_repository.dart';
import 'package:frontend/src/features/examinations/data/exam_planning_repository.dart';
import 'package:frontend/src/features/examinations/data/question_paper_builder.dart';
import 'package:frontend/src/features/examinations/domain/exam_master_data.dart';
import 'package:frontend/src/features/examinations/domain/exam_paper_model.dart';
import 'package:frontend/src/features/examinations/domain/exam_planning_model.dart';
import 'package:frontend/src/features/examinations/domain/exam_records_model.dart';
import 'package:frontend/src/features/examinations/domain/exam_schedule_model.dart';
import 'package:frontend/src/features/examinations/domain/examination_actor.dart';

int fails = 0;
void ok(bool c, String m) {
  if (!c) fails++;
  expect(c, isTrue, reason: m);
}
Future<void> throws(Future<void> Function() f, String m, [String? contains]) async {
  try { await f(); fails++; fail('$m (no error)'); }
  catch (e) {
    final good = contains == null || e.toString().contains(contains);
    if (!good) fails++;
    expect(good, isTrue, reason: '$m -> $e');
  }
}

class _MemoryDataSource extends ExaminationLocalDataSource {
  String? exam;
  String? global;

  @override
  Future<String> readExaminationJson() async =>
      exam ??= File('assets/data/examination.json').readAsStringSync();

  @override
  Future<void> writeExaminationJson(String jsonString) async {
    exam = jsonString;
  }

  @override
  Future<String> readGlobalJson() async =>
      global ??= File('assets/data/global.json').readAsStringSync();

  @override
  Future<void> writeGlobalJson(String jsonString) async {
    global = jsonString;
  }
}

void main() {
  test('Examination workflow: papers, hall tickets, attendance, marks, results, question papers',
      () async {
    await _workflow();
    expect(fails, 0);
  });
}

Future<void> _workflow() async {
  final ds = _MemoryDataSource();
  final store = ExaminationStore(ds);
  final exams = LocalExamRepository(localDataSource: ds);
  final papers = ExamPaperRepository(store);
  final conduct = ExamConductRepository(store);
  final results = ExamResultRepository(store, conduct);
  final plan = ExamPlanningRepository(store);

  const admin = ExaminationActor(userId: 'u1', name: 'Admin', role: ExamRole.admin);
  const principal = ExaminationActor(userId: 'u2', name: 'Principal', role: ExamRole.principal);
  const teacher = ExaminationActor(userId: 'u3', name: 'Teacher', role: ExamRole.teacher, teacherId: 'STF-2026-0113');
  const incharge = ExaminationActor(userId: 'u4', name: 'Incharge', role: ExamRole.classIncharge, teacherId: 'STF-2026-0111', sectionId: 'sec-10a');
  const student = ExaminationActor(userId: 'u5', name: 'Student', role: ExamRole.student, studentId: 'std-1001', sectionId: 'sec-10a');

  final names = {'std-1010':'Diya Patel','std-1011':'Rohan Mehta','std-1012':'Ishaan Kapoor','std-1001':'Aarav Sharma','std-1013':'Meera Nair','std-1014':'Kabir Singh','std-1015':'Sneha Reddy','std-1016':'Arjun Das'};
  final rolls = {'std-1010':'3','std-1011':'5','std-1012':'7','std-1001':'10','std-1013':'12','std-1014':'15','std-1015':'18','std-1016':'21'};
  final master = ExamMasterData(
    classes: const [ExamClassInfo(id: 'cls-10', name: '10th Class')],
    sections: const [ExamSectionInfo(id: 'sec-10a', classId: 'cls-10', name: 'A'), ExamSectionInfo(id: 'sec-10b', classId: 'cls-10', name: 'B')],
    subjects: const [
      ExamSubjectInfo(id: 'sub-102', classId: 'cls-10', name: 'English', teacherId: 'STF-2026-0113'),
      ExamSubjectInfo(id: 'sub-103', classId: 'cls-10', name: 'Physics', teacherId: 'STF-2026-0114'),
      ExamSubjectInfo(id: 'sub-104', classId: 'cls-10', name: 'Chemistry', teacherId: 'STF-2026-0115'),
      ExamSubjectInfo(id: 'sub-105', classId: 'cls-10', name: 'Social', teacherId: 'STF-2026-0117'),
      ExamSubjectInfo(id: 'sub-107', classId: 'cls-10', name: 'Computer Science', teacherId: 'STF-2026-0116'),
    ],
    rooms: const [ExamRoomInfo(id: 'room-205', name: 'Room 205'), ExamRoomInfo(id: 'room-204', name: 'Room 204')],
    teachers: const [ExamTeacherInfo(id: 'STF-2026-0113', name: 'Sanjay Verma')],
    students: [for (final e in names.entries) ExamStudentInfo(id: e.key, name: e.value, rollNumber: rolls[e.key]!, classId: 'cls-10', sectionId: 'sec-10a')],
    chapters: const [],
  );
  var list = await exams.getExams(actor: admin);
  ok(list.length == 5, '5 seed exams');
  final mid = list.firstWhere((e) => e.examScheduleId == 'exam-sch-002');
  ok(mid.paperCount == 6, 'Mid-Term paper count = 6 (got ${mid.paperCount})');
  final created = await exams.createExam(ExamSchedule(examScheduleId: '', examName: 'Quiz X', examType: 'UNIT_TEST', academicYear: '2026-2027', description: '', startDate: '2027-02-01', endDate: '2027-02-03', status: 'PLANNED', createdBy: 'u1', createdAt: '', updatedAt: ''), actor: admin);
  ok(created.status == 'PLANNED' && !created.manualStatus, 'new exam PLANNED, automatic');
  final c2 = await exams.createExam(ExamSchedule(examScheduleId: '', examName: 'Quiz Y', examType: 'UNIT_TEST', academicYear: '2026-2027', description: '', startDate: '2027-02-10', endDate: '2027-02-12', status: 'COMPLETED', manualStatus: true, createdBy: 'u1', createdAt: '', updatedAt: ''), actor: admin);
  ok(c2.status == 'COMPLETED' && c2.manualStatus, 'status picked from dropdown is kept (COMPLETED)');
  list = await exams.getExams(actor: admin);
  ok(list.firstWhere((e) => e.examName == 'Quiz Y').status == 'COMPLETED', 'manual status survives reload');
  await throws(() async { await exams.createExam(ExamSchedule(examScheduleId: '', examName: 'Quiz Z', examType: 'UNIT_TEST', academicYear: '2026-2027', description: '', startDate: '2027-02-10', endDate: '2027-02-12', status: 'CANCELLED', createdBy: 'u1', createdAt: '', updatedAt: ''), actor: admin); }, 'cancelled without reason is rejected', 'reason');
  final upd = await exams.updateExam(created.copyWith(status: 'CANCELLED', cancelReason: 'Holiday'), actor: admin);
  ok(upd.status == 'CANCELLED' && upd.cancelReason == 'Holiday', 'edit status to CANCELLED with reason');
  final back = await exams.updateExam(upd.copyWith(status: 'PLANNED', manualStatus: false), actor: admin);
  ok(back.status == 'PLANNED' && back.cancelReason == null, 'edit CANCELLED -> PLANNED clears reason');
  await exams.deleteExam(c2.examScheduleId, actor: admin);
  ok((await exams.getExams(actor: admin)).every((e) => e.examName != 'Quiz Y'), 'delete exam in any status (COMPLETED)');
  var all = await papers.getPapers(examId: 'exam-sch-002');
  ok(all.length == 6, '6 Mid-Term papers load with new model');
  final draft = ExamPaper(id: '', examScheduleId: 'exam-sch-002', classSectionId: 'sec-10a', subjectId: 'sub-105', examDate: '2026-11-02', startTime: '09:30', endTime: '12:00', maxMarks: 100, passingMarks: 35, roomId: 'room-205');
  var chk = await papers.check(draft, master: master);
  ok(chk.errors.isNotEmpty, 'duplicate subject is blocked: ${chk.errors.isEmpty ? '' : chk.errors.first}');
  final d2 = draft.copyWith(subjectId: 'sub-107', examDate: '2026-11-10');
  chk = await papers.check(d2, master: master);
  ok(chk.errors.isEmpty, 'new subject on a free date is allowed (${chk.errors})');
  ok(chk.warnings.isNotEmpty, 'date outside exam period only warns');
  final clash = draft.copyWith(subjectId: 'sub-107', examDate: '2026-11-04', startTime: '10:00', endTime: '11:00');
  chk = await papers.check(clash, master: master);
  ok(chk.errors.any((e) => e.contains('already has')), 'class time clash blocked');
  final room = draft.copyWith(classSectionId: 'sec-10b', subjectId: 'sub-107', examDate: '2026-11-04', startTime: '10:00', endTime: '11:00');
  chk = await papers.check(room, master: master);
  ok(chk.errors.any((e) => e.contains('Room 205')), 'room clash blocked');
  await throws(() async { await papers.savePaper(d2, actor: teacher); }, 'teacher cannot add papers', 'Permission');
  final saved = await papers.savePaper(d2, actor: admin, master: master);
  ok(saved.id.isNotEmpty, 'paper saved by admin');
  final edited = await papers.savePaper(saved.copyWith(maxMarks: 80, passingMarks: 30), actor: admin, master: master);
  ok(edited.maxMarks == 80, 'paper edited');
  await papers.cancelPaper(saved.id, 'Holiday', actor: admin);
  ok((await papers.getPaper(saved.id))!.status == 'CANCELLED', 'paper cancelled');
  await papers.deletePaper(saved.id, actor: admin);
  ok(await papers.getPaper(saved.id) == null, 'paper deleted in any status');
  final completed = (await papers.getPapers(examId: 'exam-sch-001')).first;
  ok(completed.status == 'COMPLETED', 'Unit Test paper status COMPLETED by date');
  final editDone = await papers.savePaper(completed.copyWith(roomId: 'room-204'), actor: admin, master: master);
  ok(editDone.roomId == 'room-204', 'admin can edit a COMPLETED paper');
  var tk = await conduct.getHallTickets(examId: 'exam-sch-002');
  ok(tk.length == 8, 'seed has 8 tickets');
  await conduct.deleteHallTicket(tk.first.id, actor: admin);
  final gen = await conduct.generateHallTickets(examId: 'exam-sch-002', sectionId: 'sec-10a', master: master, actor: admin);
  ok(gen.created == 1 && gen.alreadyIssued == 7, 'generate is regenerate-safe (created ${gen.created}, existing ${gen.alreadyIssued})');
  tk = await conduct.getHallTickets(examId: 'exam-sch-002');
  ok(tk.map((t) => t.hallTicketNumber).toSet().length == 8, 'ticket numbers unique');
  ok(tk.any((t) => t.hallTicketNumber == 'MID26-10A-010'), 'ticket number format MID26-10A-010');
  await throws(() async { await conduct.generateHallTickets(examId: 'exam-sch-002', sectionId: 'sec-10a', master: master, actor: teacher); }, 'teacher cannot generate', 'Permission');
  final phy = (await papers.getPapers(examId: 'exam-sch-002')).firstWhere((p) => p.id == 'ex-paper-mid-phy');
  await conduct.saveAttendance(paperId: phy.id, statusByStudent: {for (final id in names.keys) id: id == 'std-1014' ? 'ABSENT' : 'PRESENT'}, actor: admin);
  var att = await conduct.getAttendance(paperId: phy.id);
  ok(att.where((a) => a.isAbsent).length == 1, 'one absent saved');
  final teacherPhysics = ExaminationActor(userId: 'u3', name: 'T', role: ExamRole.teacher, teacherId: 'STF-2026-0114');
  await throws(() async { await conduct.saveMarks(paper: phy, inputs: [const MarkInput(studentId: 'std-1001', marks: 60)], submit: false, actor: teacherPhysics, master: master); }, 'marks above max rejected', 'between 0 and 50');
  await throws(() async { await conduct.saveMarks(paper: phy, inputs: [const MarkInput(studentId: 'std-1001', marks: 40)], submit: false, actor: teacher, master: master); }, 'other subject teacher cannot enter marks', 'own subject');
  final inputs = [for (final id in names.keys) if (id != 'std-1014') MarkInput(studentId: id, marks: 20.0 + (rolls[id] == '10' ? 25 : int.parse(rolls[id]!)))];
  await conduct.saveMarks(paper: phy, inputs: [inputs.first], submit: false, actor: teacherPhysics, master: master);
  await throws(() async { await conduct.saveMarks(paper: phy, inputs: inputs.take(3).toList(), submit: true, actor: teacherPhysics, master: master); }, 'submit with missing marks blocked', 'missing');
  await conduct.saveMarks(paper: phy, inputs: inputs, submit: true, actor: teacherPhysics, master: master);
  var marks = await conduct.getMarks(paperId: phy.id);
  ok(marks.length == 7 && marks.every((m) => m.status == 'SUBMITTED'), '7 marks submitted, absent student has none');
  await throws(() async { await conduct.saveMarks(paper: phy, inputs: inputs, submit: false, actor: teacherPhysics, master: master); }, 'teacher cannot edit after submit', 'already submitted');
  await conduct.saveMarks(paper: phy, inputs: [MarkInput(studentId: 'std-1001', marks: 46)], submit: false, actor: admin, master: master);
  ok((await conduct.getMarks(paperId: phy.id)).firstWhere((m) => m.studentId == 'std-1001').marksObtained == 46, 'admin can edit submitted marks any time');
  await conduct.flagCorrection(paperId: phy.id, comment: 'Recheck roll 3', actor: incharge);
  marks = await conduct.getMarks(paperId: phy.id);
  ok(marks.every((m) => m.status == 'CORRECTION_REQUIRED'), 'class in-charge sent marks back');
  await conduct.saveMarks(paper: phy, inputs: inputs, submit: true, actor: teacherPhysics, master: master);
  final students8 = master.studentsForSection('sec-10a');
  // English / Chemistry / Social / Hindi are not done, so results are not ready
  var ready = await results.readiness(examId: 'exam-sch-002', sectionId: 'sec-10a', master: master);
  ok(!ready.ready && ready.pending.isNotEmpty, 'results not ready while subjects are pending (${ready.pending.length} pending)');
  await throws(() async { await results.calculate(examId: 'exam-sch-002', sectionId: 'sec-10a', master: master, actor: admin); }, 'calculate blocked until reviewed', 'Cannot calculate');
  await throws(() async { await results.calculate(examId: 'exam-sch-001', sectionId: 'sec-10a', master: master, actor: teacher); }, 'teacher cannot calculate', 'Permission');

  // Unit Test 1 is fully reviewed in the seed: recalculate it
  ready = await results.readiness(examId: 'exam-sch-001', sectionId: 'sec-10a', master: master);
  ok(ready.ready, 'Unit Test 1 is ready (${ready.pending})');
  final before = await results.getReportCards(examId: 'exam-sch-001');
  final sum = await results.calculate(examId: 'exam-sch-001', sectionId: 'sec-10a', master: master, actor: admin);
  final after = await results.getReportCards(examId: 'exam-sch-001');
  ok(sum.studentsProcessed == 8 && after.length == 8, 'recalculated 8 report cards (no duplicates)');
  ok(after.every((c) => c.status == 'PENDING_APPROVAL' && !c.isPublished), 'recalculation resets to PENDING_APPROVAL');
  final matches = after.every((c) => before.firstWhere((b) => b.studentId == c.studentId).percentage == c.percentage);
  ok(matches, 'recalculated percentages equal the seed values');
  ok(after.first.classRank == 1, 'rank 1 first: ${after.first.studentId} ${after.first.percentage}%');
  final kabir = after.firstWhere((c) => c.studentId == 'std-1014');
  ok(kabir.subjects.any((s) => s.absent && s.failed) && !kabir.passed, 'absent student gets 0 and fails that subject');
  await throws(() async { await results.publishSection(examId: 'exam-sch-001', sectionId: 'sec-10a', actor: admin); }, 'cannot publish before approval', 'Approve');
  await results.approveSection(examId: 'exam-sch-001', sectionId: 'sec-10a', actor: principal);
  await results.publishSection(examId: 'exam-sch-001', sectionId: 'sec-10a', actor: principal);
  final pub = await results.getReportCards(studentId: 'std-1001', publishedOnly: true);
  ok(pub.length == 1 && pub.first.status == 'PUBLISHED', 'student sees the published card');
  await results.unpublishSection(examId: 'exam-sch-001', sectionId: 'sec-10a', actor: admin);
  ok((await results.getReportCards(studentId: 'std-1001', publishedOnly: true)).isEmpty, 'unpublished cards are hidden from students');
  // editing marks after calculation flags the cards as stale
  final ut = (await papers.getPapers(examId: 'exam-sch-001')).first;
  await conduct.saveMarks(paper: ut, inputs: [const MarkInput(studentId: 'std-1001', marks: 10)], submit: false, actor: admin, master: master);
  ok((await results.getReportCards(examId: 'exam-sch-001')).every((c) => c.stale), 'changing marks marks report cards as stale');
  await throws(() async { await results.approveSection(examId: 'exam-sch-001', sectionId: 'sec-10a', actor: admin); }, 'stale cards cannot be approved', 'Calculate');
  await conduct.saveRemarks(StudentRemarks(id: '', examScheduleId: 'exam-sch-001', studentId: 'std-1013', classSectionId: 'sec-10a', academic: 'Good', remarks: 'Steady progress'), actor: incharge);
  ok((await conduct.getRemarks(examId: 'exam-sch-001')).length == 2, 'remarks saved');
  await throws(() async { await conduct.saveRemarks(StudentRemarks(id: '', examScheduleId: 'exam-sch-001', studentId: 'std-1013', classSectionId: 'sec-10b'), actor: incharge); }, 'in-charge limited to own section', 'own class');
  var pats = await plan.getPatterns(examId: 'exam-sch-002');
  ok(pats.length == 1 && pats.first.sections.length == 3 && pats.first.topics.length == 4, 'seed pattern loads with sections + chapters');
  ok(pats.first.activationProblems().isEmpty, 'seed pattern totals 50 marks and 100% weightage');
  await throws(() async { await plan.savePattern(pats.first.copyWithForTest(maxMarks: 60, status: 'ACTIVE'), actor: admin); }, 'cannot activate when sections != max marks', 'Cannot activate');
  final bank = await plan.getQuestions(subjectId: 'sub-103');
  ok(bank.length == 21 && bank.where((q) => q.type == 'MCQ').every((q) => q.options.length == 4), '21 questions, MCQs have 4 options');
  final q1 = await plan.saveQuestion(Question(id: '', subjectId: 'sub-103', topicId: 'syl-103-2', text: 'New short q', type: 'SHORT', marks: 4), const [], actor: teacher);
  ok(q1.status == 'DRAFT', 'teacher question starts as DRAFT');
  await throws(() async { await plan.saveQuestion(Question(id: '', subjectId: 'sub-103', text: 'Bad mcq', type: 'MCQ', marks: 1), [const QuestionOption(id: '', questionId: '', text: 'only one', isCorrect: true)], actor: teacher); }, 'MCQ needs 2 options', '2 options');
  await throws(() async { await plan.setQuestionStatus(q1.id, 'APPROVED', actor: teacher); }, 'teacher cannot approve', 'Admin');
  await plan.setQuestionStatus(q1.id, 'APPROVED', actor: admin);
  final examPaper = (await papers.getPapers(examId: 'exam-sch-002')).firstWhere((p) => p.id == 'ex-paper-mid-phy');
  final pattern = pats.first;
  final qp = await plan.createQuestionPaper(examPaper: examPaper, pattern: pattern, actor: teacher);
  ok(qp.status == 'DRAFT', 'question paper created as DRAFT');
  await throws(() async { await plan.createQuestionPaper(examPaper: examPaper, pattern: pattern, actor: teacher); }, 'only one paper per exam paper', 'already exists');
  var items = QuestionPaperBuilder.autoPick(pattern: pattern, bank: await plan.getQuestions(subjectId: 'sub-103'), existing: const [], questionPaperId: qp.id, newId: () => '');
  final qmap = {for (final q in await plan.getQuestions(subjectId: 'sub-103')) q.id: q};
  var res = QuestionPaperBuilder.evaluate(pattern: pattern, items: items, questions: qmap);
  // ignore: avoid_print
  print('     auto-pick: ${items.length} items, sections ${res.selectedPerSection}, blockers ${res.blockers}');
  ok(res.selectedPerSection['Section A'] == 10 && res.selectedPerSection['Section B'] == 5 && res.selectedPerSection['Section C'] == 3, 'auto-pick fills every section');
  ok(res.ok, 'filled paper satisfies the pattern');
  await plan.saveItems(questionPaperId: qp.id, items: items.take(5).toList(), actor: teacher);
  res = QuestionPaperBuilder.evaluate(pattern: pattern, items: items.take(5).toList(), questions: qmap);
  ok(!res.ok, 'incomplete paper is blocked');
  await throws(() async { await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'SUBMITTED', actor: teacher, check: res); }, 'submit blocked until pattern is satisfied', 'Cannot submit');
  await plan.saveItems(questionPaperId: qp.id, items: items, actor: teacher);
  final fine = QuestionPaperBuilder.evaluate(pattern: pattern, items: (await plan.getQuestionPapers(examPaperId: examPaper.id)).first.items, questions: qmap);
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'SUBMITTED', actor: teacher, check: fine);
  await throws(() async { await plan.saveItems(questionPaperId: qp.id, items: items, actor: teacher); }, 'teacher cannot edit after submit', 'cannot be edited');
  await throws(() async { await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'APPROVED', actor: teacher); }, 'teacher cannot approve paper');
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'UNDER_REVIEW', actor: admin);
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'CORRECTION_REQUIRED', comment: 'Swap Q3', actor: admin);
  await plan.saveItems(questionPaperId: qp.id, items: items, actor: teacher);
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'SUBMITTED', actor: teacher, check: fine);
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'APPROVED', actor: principal);
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'LOCKED', actor: admin);
  await throws(() async { await plan.saveItems(questionPaperId: qp.id, items: items, actor: admin); }, 'locked paper cannot be edited', 'locked');
  await plan.changePaperStatus(questionPaperId: qp.id, newStatus: 'DRAFT', actor: admin);
  ok((await plan.getQuestionPapers()).first.status == 'DRAFT', 'admin can unlock');
  await exams.deleteExam('exam-sch-002', actor: admin);
  final data = await store.load();
  for (final k in ['exam_papers','hall_tickets','exam_attendance','student_exam_marks','question_papers','question_paper_items','exam_syllabus_patterns','pattern_sections','pattern_topics']) {
    final left = (data[k] as List).whereType<Map>().where((m) => (m['exam_schedule_id'] ?? '') == 'exam-sch-002').length;
    ok(left == 0, 'no $k rows left for the deleted exam');
  }
  ok((data['exam_papers'] as List).whereType<Map>().every((m) => m['exam_schedule_id'] != 'exam-sch-002'), 'papers of deleted exam are gone');
}

extension on ExamPattern {
  ExamPattern copyWithForTest({double? maxMarks, String? status}) => ExamPattern(
        id: id, examScheduleId: examScheduleId, classSectionId: classSectionId, subjectId: subjectId,
        patternName: patternName, maxMarks: maxMarks ?? this.maxMarks, examDuration: examDuration,
        syllabusDetails: syllabusDetails, status: status ?? this.status, sections: sections, topics: topics);
}
