import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/examinations/data/exam_repository.dart';
import 'package:frontend/src/features/examinations/data/examination_local_datasource.dart';
import 'package:frontend/src/features/examinations/domain/exam_schedule_model.dart';
import 'package:frontend/src/features/examinations/domain/examination_actor.dart';
import 'package:frontend/src/features/examinations/domain/global_setup_model.dart';

/// Test Local DataSource using in-memory string storage to avoid filesystem dependencies during unit tests
class MockInMemoryDataSource extends ExaminationLocalDataSource {
  String examJson;
  String globalJson;

  MockInMemoryDataSource({
    required this.examJson,
    required this.globalJson,
  });

  @override
  Future<String> readExaminationJson() async => examJson;

  @override
  Future<void> writeExaminationJson(String jsonString) async {
    examJson = jsonString;
  }

  @override
  Future<String> readGlobalJson() async => globalJson;

  @override
  Future<void> writeGlobalJson(String jsonString) async {
    globalJson = jsonString;
  }

  @override
  Future<void> resetDemoData() async {
    // Reset back to initial test data
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockInMemoryDataSource mockDataSource;
  late ExamRepository repo;

  final adminActor = const ExaminationActor(
    userId: 'u1',
    name: 'Admin User',
    role: ExamRole.admin,
  );

  final principalActor = const ExaminationActor(
    userId: 'u2',
    name: 'Principal User',
    role: ExamRole.principal,
  );

  final teacherActor = const ExaminationActor(
    userId: 'u3',
    name: 'Teacher User',
    role: ExamRole.teacher,
  );

  final studentActor = const ExaminationActor(
    userId: 'u5',
    name: 'Student User',
    role: ExamRole.student,
  );

  final initialExamData = {
    'exam_schedules': [
      {
        'exam_schedule_id': 'exam-1',
        'exam_name': 'Mid-Term Exam',
        'exam_type': 'MID_TERM',
        'academic_year': '2026-2027',
        'start_date': '2026-10-25',
        'end_date': '2026-11-05',
        'description': 'Midterm evaluation',
        'status': 'ONGOING',
        'cancel_reason': null,
        'created_by': 'u1',
        'created_at': '2026-09-01T00:00:00.000Z',
        'updated_at': '2026-10-25T00:00:00.000Z',
      },
      {
        'exam_schedule_id': 'exam-2',
        'exam_name': 'Unit Test 2',
        'exam_type': 'UNIT_TEST',
        'academic_year': '2026-2027',
        'start_date': '2026-12-01',
        'end_date': '2026-12-10',
        'description': 'Upcoming test without papers',
        'status': 'PLANNED',
        'cancel_reason': null,
        'created_by': 'u1',
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-01T00:00:00.000Z',
      },
      {
        'exam_schedule_id': 'exam-3',
        'exam_name': 'Unit Test 1',
        'exam_type': 'UNIT_TEST',
        'academic_year': '2026-2027',
        'start_date': '2026-07-01',
        'end_date': '2026-07-10',
        'description': 'Completed test',
        'status': 'COMPLETED',
        'cancel_reason': null,
        'created_by': 'u1',
        'created_at': '2026-06-01T00:00:00.000Z',
        'updated_at': '2026-07-10T00:00:00.000Z',
      },
    ],
    'exam_papers': [
      {
        'id': 'paper-1',
        'exam_schedule_id': 'exam-1',
        'exam_date': '2026-10-28',
      },
    ],
  };

  final initialGlobalData = {
    'academic_years': ['2025-2026', '2026-2027'],
    'current_academic_year': '2026-2027',
    'exam_types': [
      {'code': 'UNIT_TEST', 'label': 'Unit Test'},
      {'code': 'MID_TERM', 'label': 'Mid-Term'},
    ],
    'users': [
      {'id': 'u1', 'name': 'Admin', 'role': 'ADMIN'},
      {'id': 'u2', 'name': 'Principal', 'role': 'PRINCIPAL'},
      {'id': 'u3', 'name': 'Teacher', 'role': 'TEACHER'},
      {'id': 'u5', 'name': 'Student', 'role': 'STUDENT'},
    ],
    'current_user_id': 'u1',
  };

  setUp(() {
    mockDataSource = MockInMemoryDataSource(
      examJson: jsonEncode(initialExamData),
      globalJson: jsonEncode(initialGlobalData),
    );
    repo = LocalExamRepository(localDataSource: mockDataSource);
  });

  group('Business Rule 2: Dynamic Computed Status', () {
    test('PLANNED becomes ONGOING when today reaches start_date', () {
      final status = ExamSchedule.computeStatus(
        rawStatus: 'PLANNED',
        startDate: '2026-10-20',
        endDate: '2026-11-05',
        referenceDate: DateTime(2026, 10, 25),
      );
      expect(status, 'ONGOING');
    });

    test('ONGOING becomes COMPLETED when today passes end_date', () {
      final status = ExamSchedule.computeStatus(
        rawStatus: 'ONGOING',
        startDate: '2026-10-01',
        endDate: '2026-10-15',
        referenceDate: DateTime(2026, 10, 20),
      );
      expect(status, 'COMPLETED');
    });

    test('CANCELLED never changes even if dates are passed or future', () {
      final statusPast = ExamSchedule.computeStatus(
        rawStatus: 'CANCELLED',
        startDate: '2026-05-01',
        endDate: '2026-05-10',
        referenceDate: DateTime(2026, 10, 31),
      );
      expect(statusPast, 'CANCELLED');

      final statusFuture = ExamSchedule.computeStatus(
        rawStatus: 'CANCELLED',
        startDate: '2027-01-01',
        endDate: '2027-01-10',
        referenceDate: DateTime(2026, 10, 31),
      );
      expect(statusFuture, 'CANCELLED');
    });
  });

  group('ExamRepository Create Exam Rules', () {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    ExamSchedule draftExam(String name, String status, {String? reason}) {
      final now = DateTime.now();
      return ExamSchedule(
        examScheduleId: '',
        examName: name,
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: fmt(DateTime(now.year, now.month, now.day + 10)),
        endDate: fmt(DateTime(now.year, now.month, now.day + 20)),
        description: 'New test',
        status: status,
        cancelReason: reason,
        createdBy: 'u1',
        createdAt: '',
        updatedAt: '',
      );
    }

    test('Rule 1 (revised): status follows the dates unless picked from the dropdown', () async {
      final auto = await repo.createExam(draftExam('Annual Test', 'PLANNED'), actor: adminActor);
      expect(auto.status, 'PLANNED');
      expect(auto.manualStatus, isFalse);
      expect(auto.examScheduleId, isNotEmpty);
      expect(auto.createdAt, isNotEmpty);
      expect(auto.updatedAt, isNotEmpty);
    });

    test('Status dropdown: a picked status that differs from the dates is kept', () async {
      final picked = await repo.createExam(draftExam('Picked Status Test', 'ONGOING'), actor: adminActor);
      expect(picked.status, 'ONGOING');
      expect(picked.manualStatus, isTrue);
      final reloaded = (await repo.getExamById(picked.examScheduleId))!;
      expect(reloaded.status, 'ONGOING');
    });

    test('Status dropdown: CANCELLED needs a reason and editing back clears it', () async {
      expect(
        () => repo.createExam(draftExam('No Reason', 'CANCELLED'), actor: adminActor),
        throwsA(isA<ExamValidationException>()),
      );
      final cancelled = await repo.createExam(
        draftExam('With Reason', 'CANCELLED', reason: 'Holiday'),
        actor: adminActor,
      );
      expect(cancelled.status, 'CANCELLED');
      expect(cancelled.cancelReason, 'Holiday');
      final restored = await repo.updateExam(
        cancelled.copyWith(status: 'PLANNED', manualStatus: false),
        actor: adminActor,
      );
      expect(restored.status, 'PLANNED');
      expect(restored.cancelReason, isNull);
    });

    test('Rule 5: start_date cannot be in the past when creating', () async {
      final pastExam = ExamSchedule(
        examScheduleId: '',
        examName: 'Past Test',
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '2020-01-01',
        endDate: '2020-01-10',
        description: 'Test in past',
        status: 'PLANNED',
        createdBy: 'u1',
        createdAt: '',
        updatedAt: '',
      );

      expect(
        () => repo.createExam(pastExam, actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('Start date cannot be in the past'),
        )),
      );
    });

    test('Rule 5: end_date must be on or after start_date', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day + 15);
      final end = DateTime(now.year, now.month, now.day + 5);

      final invalidDates = ExamSchedule(
        examScheduleId: '',
        examName: 'Invalid Dates Test',
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        endDate: '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
        description: 'Invalid',
        status: 'PLANNED',
        createdBy: 'u1',
        createdAt: '',
        updatedAt: '',
      );

      expect(
        () => repo.createExam(invalidDates, actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('End date must be on or after the start date'),
        )),
      );
    });

    test('Rule 6: Duplicate exam_name in the same academic_year is rejected', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day + 10);
      final end = DateTime(now.year, now.month, now.day + 20);

      final duplicate = ExamSchedule(
        examScheduleId: '',
        examName: 'Mid-Term Exam', // Already exists in 2026-2027
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        endDate: '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
        description: 'Duplicate name',
        status: 'PLANNED',
        createdBy: 'u1',
        createdAt: '',
        updatedAt: '',
      );

      expect(
        () => repo.createExam(duplicate, actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('An exam with this name already exists for 2026-2027'),
        )),
      );
    });

    test('Role check: Non-admin/principal cannot create exam', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day + 10);
      final end = DateTime(now.year, now.month, now.day + 20);

      final newExam = ExamSchedule(
        examScheduleId: '',
        examName: 'Teacher Created Test',
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        endDate: '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
        description: 'Test',
        status: 'PLANNED',
        createdBy: 'u3',
        createdAt: '',
        updatedAt: '',
      );

      expect(
        () => repo.createExam(newExam, actor: teacherActor),
        throwsA(isA<ExamPermissionException>()),
      );
    });
  });

  group('ExamRepository Update Exam Rules (Revised)', () {
    test('Rule 4: ADMIN/PRINCIPAL can edit all fields in ONGOING status', () async {
      final exam1 = (await repo.getExamById('exam-1'))!;
      expect(exam1.isOngoing, isTrue);

      // In revised rules, all fields including examName are editable regardless of status
      final validUpdate = exam1.copyWith(
        examName: 'Mid-Term Examination (Revised)',
        description: 'Updated midterm notes',
        endDate: '2026-11-12',
      );
      final result = await repo.updateExam(validUpdate, actor: adminActor);
      expect(result.examName, 'Mid-Term Examination (Revised)');
      expect(result.description, 'Updated midterm notes');
      expect(result.endDate, '2026-11-12');
    });

    test('Rule 4: ADMIN/PRINCIPAL can edit an exam in COMPLETED status', () async {
      final exam3 = (await repo.getExamById('exam-3'))!;
      expect(exam3.isCompleted, isTrue);

      final updated = exam3.copyWith(
        description: 'New retrospective note added by admin',
      );
      final result = await repo.updateExam(updated, actor: principalActor);
      expect(result.description, 'New retrospective note added by admin');
    });

    test('Rule 4: Non-admin/principal role cannot edit exam', () async {
      final exam1 = (await repo.getExamById('exam-1'))!;
      expect(
        () => repo.updateExam(exam1.copyWith(description: 'Teacher edit'), actor: teacherActor),
        throwsA(isA<ExamPermissionException>()),
      );
    });

    test('Rule 9: Block date change if papers exist outside new date range', () async {
      // exam-1 has paper-1 on 2026-10-28
      final exam1 = (await repo.getExamById('exam-1'))!;
      // Move endDate before paper-1 date (2026-10-26 is before 2026-10-28)
      final invalidEndDate = exam1.copyWith(endDate: '2026-10-26');

      expect(
        () => repo.updateExam(invalidEndDate, actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('one or more exam papers fall outside the new date range'),
        )),
      );
    });
  });

  group('ExamRepository Cancel and Delete Rules (Revised)', () {
    test('Rule 3: Cancel requires reason and sets CANCELLED (allowed from PLANNED or ONGOING)', () async {
      // Missing reason is rejected
      expect(
        () => repo.cancelExam('exam-1', '   ', actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('A cancellation reason is required'),
        )),
      );

      final cancelled = await repo.cancelExam(
        'exam-1',
        'Weather emergency',
        actor: principalActor,
      );
      expect(cancelled.status, 'CANCELLED');
      expect(cancelled.cancelReason, 'Weather emergency');
    });

    test('Rule 3: Cancel is rejected on COMPLETED exam', () async {
      expect(
        () => repo.cancelExam('exam-3', 'Too late', actor: adminActor),
        throwsA(isA<ExamValidationException>().having(
          (e) => e.message,
          'message',
          contains('Only PLANNED or ONGOING exams can be cancelled'),
        )),
      );
    });

    test('Rule 8: Delete allowed in ANY status and cascades linked data', () async {
      // exam-1 is ONGOING and has paper-1
      final countsBefore = await repo.getLinkedDataCounts('exam-1');
      expect(countsBefore.papers, 1);
      expect(countsBefore.hasLinkedData, isTrue);
      expect(
        countsBefore.formatSummary(),
        'This exam has 1 paper. Deleting will remove all of them. This cannot be undone.',
      );

      // In revised rules, deleting ONGOING exam with linked papers is allowed and cascades
      await repo.deleteExam('exam-1', actor: adminActor);
      final remaining = await repo.getExamById('exam-1');
      expect(remaining, isNull);

      // Verify linked papers were also removed
      final raw = jsonDecode(await mockDataSource.readExaminationJson()) as Map<String, dynamic>;
      final papers = (raw['exam_papers'] as List<dynamic>? ?? []);
      expect(papers.any((p) => p['exam_schedule_id'] == 'exam-1'), isFalse);
    });

    test('Rule 8: Delete on COMPLETED or PLANNED exam succeeds', () async {
      // Delete exam-2 (PLANNED)
      await repo.deleteExam('exam-2', actor: principalActor);
      expect(await repo.getExamById('exam-2'), isNull);

      // Delete exam-3 (COMPLETED)
      await repo.deleteExam('exam-3', actor: adminActor);
      expect(await repo.getExamById('exam-3'), isNull);
    });

    test('Rule 8: Non-admin/principal role cannot delete exam', () async {
      expect(
        () => repo.deleteExam('exam-2', actor: teacherActor),
        throwsA(isA<ExamPermissionException>()),
      );
    });
  });

  group('Student & Parent Visibility Filter', () {
    test('Hides PLANNED exams that have 0 papers for student', () async {
      final studentExams = await repo.getExams(actor: studentActor);
      // exam-2 is PLANNED with 0 papers, so it should be hidden
      final ids = studentExams.map((e) => e.examScheduleId).toList();
      expect(ids.contains('exam-2'), isFalse);
      expect(ids.contains('exam-1'), isTrue);
      expect(ids.contains('exam-3'), isTrue);
    });

    test('Shows all exams for admin', () async {
      final adminExams = await repo.getExams(actor: adminActor);
      final ids = adminExams.map((e) => e.examScheduleId).toList();
      expect(ids.contains('exam-2'), isTrue);
      expect(ids.contains('exam-1'), isTrue);
      expect(ids.contains('exam-3'), isTrue);
    });
  });

  group('Overlap Check (Non-blocking warning)', () {
    test('Detects overlapping exam of same exam_type', () async {
      // exam-2 is UNIT_TEST (2026-12-01 to 2026-12-10)
      final overlap = await repo.checkDateOverlap(
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '2026-12-05',
        endDate: '2026-12-15',
      );
      expect(overlap, isNotNull);
      expect(overlap!.examScheduleId, 'exam-2');
    });

    test('Returns null when dates do not overlap', () async {
      final overlap = await repo.checkDateOverlap(
        examType: 'UNIT_TEST',
        academicYear: '2026-2027',
        startDate: '2027-04-01',
        endDate: '2027-04-10',
      );
      expect(overlap, isNull);
    });
  });
}

