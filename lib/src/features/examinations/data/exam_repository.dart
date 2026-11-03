import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../domain/exam_paper_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import '../domain/global_setup_model.dart';
import 'examination_local_datasource.dart';

class ExamValidationException implements Exception {
  final String message;
  const ExamValidationException(this.message);
  @override
  String toString() => message;
}

class ExamPermissionException implements Exception {
  final String message;
  const ExamPermissionException(this.message);
  @override
  String toString() => message;
}

abstract class ExamRepository {
  Future<List<ExamSchedule>> getExams({
    String? searchQuery,
    String? academicYear,
    String? examType,
    String? status,
    ExaminationActor? actor,
  });

  Future<ExamSchedule?> getExamById(String id, {ExaminationActor? actor});

  Future<ExamSchedule> createExam(
    ExamSchedule exam, {
    required ExaminationActor actor,
  });

  Future<ExamSchedule> updateExam(
    ExamSchedule exam, {
    required ExaminationActor actor,
  });

  Future<ExamSchedule> cancelExam(
    String id,
    String reason, {
    required ExaminationActor actor,
  });

  Future<void> deleteExam(
    String id, {
    required ExaminationActor actor,
  });

  Future<ExamLinkedDataCounts> getLinkedDataCounts(String id);

  Future<ExamSchedule?> checkDateOverlap({
    required String examType,
    required String academicYear,
    required String startDate,
    required String endDate,
    String? excludeExamId,
  });

  Future<GlobalSetup> getGlobalSetup();
  Future<void> setCurrentUser(String userId);

  Future<void> resetDemoData();
}

class LocalExamRepository implements ExamRepository {
  final ExaminationLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();

  LocalExamRepository({ExaminationLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? ExaminationLocalDataSource();

  // ---------------------------------------------------------------------------
  // JSON RAW LOADERS
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _loadExaminationData() async {
    final raw = await _localDataSource.readExaminationJson();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveExaminationData(Map<String, dynamic> data) async {
    const encoder = JsonEncoder.withIndent('  ');
    await _localDataSource.writeExaminationJson(encoder.convert(data));
  }

  Future<List<ExamPaper>> _loadPapers(Map<String, dynamic> raw) async {
    final list = raw['exam_papers'] as List<dynamic>? ??
        raw['exam_timetables'] as List<dynamic>? ??
        [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamPaper.fromJson(e))
        .toList();
  }

  DateTime _parseDateOnly(String dateStr) {
    final parts = dateStr.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  DateTime _todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ---------------------------------------------------------------------------
  // EXAM SCHEDULES
  // ---------------------------------------------------------------------------
  @override
  Future<List<ExamSchedule>> getExams({
    String? searchQuery,
    String? academicYear,
    String? examType,
    String? status,
    ExaminationActor? actor,
  }) async {
    final raw = await _loadExaminationData();
    final rawList = raw['exam_schedules'] as List<dynamic>? ?? [];
    final papers = await _loadPapers(raw);

    // Map paper counts by schedule ID
    final paperCountMap = <String, int>{};
    for (final p in papers) {
      paperCountMap[p.examScheduleId] = (paperCountMap[p.examScheduleId] ?? 0) + 1;
    }

    final exams = <ExamSchedule>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final id = (item['exam_schedule_id'] ?? item['id'] ?? '').toString();
        final count = paperCountMap[id] ?? 0;
        final schedule = ExamSchedule.fromJson(item, paperCount: count);
        exams.add(schedule);
      }
    }

    // Role-based visibility check:
    // STUDENT and PARENT: hide PLANNED exams that have no papers.
    var filtered = exams.where((e) {
      if (actor != null && !actor.permissions.canViewExam(e)) {
        return false;
      }
      return true;
    }).toList();

    // Query filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((e) => e.examName.toLowerCase().contains(q))
          .toList();
    }

    // Academic Year filter
    if (academicYear != null &&
        academicYear.trim().isNotEmpty &&
        academicYear != 'All' &&
        academicYear != 'All Years') {
      filtered = filtered
          .where((e) => e.academicYear.trim() == academicYear.trim())
          .toList();
    }

    // Exam Type filter
    if (examType != null &&
        examType.trim().isNotEmpty &&
        examType != 'All' &&
        examType != 'All Types') {
      filtered = filtered
          .where((e) => e.examType.toUpperCase() == examType.toUpperCase())
          .toList();
    }

    // Status filter
    if (status != null &&
        status.trim().isNotEmpty &&
        status != 'All' &&
        status != 'All Statuses') {
      filtered = filtered
          .where((e) => e.status.toUpperCase() == status.toUpperCase())
          .toList();
    }

    // Sort by start_date ascending, then by name
    filtered.sort((a, b) {
      final c = a.startDate.compareTo(b.startDate);
      if (c != 0) return c;
      return a.examName.compareTo(b.examName);
    });

    return filtered;
  }

  @override
  Future<ExamSchedule?> getExamById(String id, {ExaminationActor? actor}) async {
    final all = await getExams(actor: actor);
    return all.where((e) => e.examScheduleId == id).firstOrNull;
  }

  // ---------------------------------------------------------------------------
  // CREATE EXAM
  // ---------------------------------------------------------------------------
  @override
  Future<ExamSchedule> createExam(
    ExamSchedule exam, {
    required ExaminationActor actor,
  }) async {
    // 1. Check permissions
    if (!actor.permissions.canCreateExam) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can create exams.',
      );
    }

    final trimmedName = exam.examName.trim();
    if (trimmedName.isEmpty) {
      throw const ExamValidationException('Exam Name is required.');
    }
    if (exam.startDate.isEmpty || exam.endDate.isEmpty) {
      throw const ExamValidationException('Start and End dates are required.');
    }

    final startDate = _parseDateOnly(exam.startDate);
    final endDate = _parseDateOnly(exam.endDate);
    final today = _todayDateOnly();

    // Business Rule 5: start_date cannot be in the past when creating
    if (startDate.isBefore(today)) {
      throw const ExamValidationException(
        'Start date cannot be in the past when creating a new exam.',
      );
    }

    // Business Rule 5: end_date must be on or after start_date
    if (endDate.isBefore(startDate)) {
      throw const ExamValidationException(
        'End date must be on or after the start date.',
      );
    }

    final raw = await _loadExaminationData();
    final rawList = (raw['exam_schedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    // Business Rule 6: Duplicate exam_name in the same academic_year is rejected
    final hasDuplicate = rawList.any((e) {
      final name = (e['exam_name'] ?? '').toString().trim();
      final year = (e['academic_year'] ?? '').toString().trim();
      return year == exam.academicYear.trim() &&
          name.toLowerCase() == trimmedName.toLowerCase();
    });

    if (hasDuplicate) {
      throw ExamValidationException(
        'An exam with this name already exists for ${exam.academicYear}.',
      );
    }

    // Business Rule 1: New exams are always PLANNED
    final id = exam.examScheduleId.isNotEmpty
        ? exam.examScheduleId
        : 'exam-sch-${_uuid.v4().substring(0, 8)}';
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final newExam = exam.copyWith(
      examScheduleId: id,
      examName: trimmedName,
      status: 'PLANNED',
      cancelReason: null,
      createdBy: actor.userId,
      createdAt: nowIso,
      updatedAt: nowIso,
      paperCount: 0,
    );

    rawList.add(newExam.toJson());
    raw['exam_schedules'] = rawList;
    await _saveExaminationData(raw);

    return newExam;
  }

  // ---------------------------------------------------------------------------
  // UPDATE EXAM
  // ---------------------------------------------------------------------------
  @override
  Future<ExamSchedule> updateExam(
    ExamSchedule exam, {
    required ExaminationActor actor,
  }) async {
    // 1. Check permissions
    if (!actor.permissions.canEditExam) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can edit exams.',
      );
    }

    final raw = await _loadExaminationData();
    final rawList = (raw['exam_schedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final index = rawList.indexWhere(
      (e) => (e['exam_schedule_id'] ?? e['id']) == exam.examScheduleId,
    );

    if (index < 0) {
      throw const ExamValidationException('Exam not found.');
    }

    final existingJson = rawList[index];
    final existingExam = ExamSchedule.fromJson(existingJson);

    // Business Rule 4 (Revised): ADMIN/PRINCIPAL can Edit an exam in ANY status at any time.
    // All fields are editable regardless of status. Status stays automatic by date, except Cancel, which is manual.

    final startDate = _parseDateOnly(exam.startDate);
    final endDate = _parseDateOnly(exam.endDate);

    // Business Rule 5: end_date must be on or after start_date
    if (endDate.isBefore(startDate)) {
      throw const ExamValidationException(
        'End date must be on or after the start date.',
      );
    }

    // Business Rule 6: Duplicate exam_name check if name was edited
    final trimmedName = exam.examName.trim();
    if (trimmedName.isEmpty) {
      throw const ExamValidationException('Exam Name cannot be empty.');
    }

    final hasDuplicate = rawList.any((e) {
      final otherId = (e['exam_schedule_id'] ?? e['id']).toString();
      if (otherId == exam.examScheduleId) return false;
      final name = (e['exam_name'] ?? '').toString().trim();
      final year = (e['academic_year'] ?? '').toString().trim();
      return year == exam.academicYear.trim() &&
          name.toLowerCase() == trimmedName.toLowerCase();
    });

    if (hasDuplicate) {
      throw ExamValidationException(
        'An exam with this name already exists for ${exam.academicYear}.',
      );
    }

    // Business Rule 9: If papers exist outside a new date range, block the date change
    final papers = await _loadPapers(raw);
    final examPapers = papers.where((p) => p.examScheduleId == exam.examScheduleId);
    for (final p in examPapers) {
      if (p.examDate != null && p.examDate!.isNotEmpty) {
        final paperDate = _parseDateOnly(p.examDate!);
        if (paperDate.isBefore(startDate) || paperDate.isAfter(endDate)) {
          throw const ExamValidationException(
            'Cannot change exam dates: one or more exam papers fall outside the new date range.',
          );
        }
      }
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final finalStatus = existingExam.isCancelled
        ? 'CANCELLED'
        : ExamSchedule.computeStatus(
            rawStatus: exam.status,
            startDate: exam.startDate,
            endDate: exam.endDate,
          );

    final updatedExam = exam.copyWith(
      examName: trimmedName,
      status: finalStatus,
      updatedAt: nowIso,
      paperCount: examPapers.length,
    );

    rawList[index] = updatedExam.toJson();
    raw['exam_schedules'] = rawList;
    await _saveExaminationData(raw);

    return updatedExam;
  }

  // ---------------------------------------------------------------------------
  // CANCEL EXAM
  // ---------------------------------------------------------------------------
  @override
  Future<ExamSchedule> cancelExam(
    String id,
    String reason, {
    required ExaminationActor actor,
  }) async {
    // 1. Check permissions
    if (!actor.permissions.canCancelExam) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can cancel exams.',
      );
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const ExamValidationException('A cancellation reason is required.');
    }

    final raw = await _loadExaminationData();
    final rawList = (raw['exam_schedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final index = rawList.indexWhere(
      (e) => (e['exam_schedule_id'] ?? e['id']) == id,
    );

    if (index < 0) {
      throw const ExamValidationException('Exam not found.');
    }

    final existing = ExamSchedule.fromJson(rawList[index]);

    // Business Rule 3: Cancel is manual, needs a reason, and is allowed only from PLANNED or ONGOING.
    if (!existing.canBeCancelled) {
      throw ExamValidationException(
        'Only PLANNED or ONGOING exams can be cancelled (current status: ${existing.status}).',
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final cancelledExam = existing.copyWith(
      status: 'CANCELLED',
      cancelReason: trimmedReason,
      updatedAt: nowIso,
    );

    rawList[index] = cancelledExam.toJson();
    raw['exam_schedules'] = rawList;
    await _saveExaminationData(raw);

    return cancelledExam;
  }

  // ---------------------------------------------------------------------------
  // DELETE EXAM
  // ---------------------------------------------------------------------------
  @override
  Future<void> deleteExam(
    String id, {
    required ExaminationActor actor,
  }) async {
    // 1. Check permissions
    if (!actor.permissions.canDeleteExam) {
      throw const ExamPermissionException(
        'Permission denied: Only Admin or Principal can delete exams.',
      );
    }

    final raw = await _loadExaminationData();
    final rawList = (raw['exam_schedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final index = rawList.indexWhere(
      (e) => (e['exam_schedule_id'] ?? e['id']) == id,
    );

    if (index < 0) {
      throw const ExamValidationException('Exam not found.');
    }

    // Rule 8 (Revised): Delete is allowed in ANY status (PLANNED, ONGOING, COMPLETED, CANCELLED).
    // Delete the exam and all linked records together.

    // 1. Identify and delete all linked papers
    final papersList = (raw['exam_papers'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final linkedPaperIds = <String>{};
    papersList.removeWhere((p) {
      if ((p['exam_schedule_id'] ?? '') == id) {
        linkedPaperIds.add((p['id'] ?? '').toString());
        return true;
      }
      return false;
    });
    raw['exam_papers'] = papersList;

    // 2. Cascade delete linked records across all tables if present
    for (final key in [
      'hall_tickets',
      'exam_attendance',
      'attendance',
      'student_exam_marks',
      'marks',
      'report_cards',
    ]) {
      if (raw.containsKey(key) && raw[key] is List) {
        final list = (raw[key] as List).whereType<Map<String, dynamic>>().toList();
        list.removeWhere((item) {
          final schId = item['exam_schedule_id']?.toString();
          final pId = (item['paper_id'] ?? item['exam_paper_id'])?.toString();
          return schId == id || (pId != null && linkedPaperIds.contains(pId));
        });
        raw[key] = list;
      }
    }

    // 3. Remove the exam schedule itself
    rawList.removeAt(index);
    raw['exam_schedules'] = rawList;
    await _saveExaminationData(raw);
  }

  // ---------------------------------------------------------------------------
  // GET LINKED DATA COUNTS
  // ---------------------------------------------------------------------------
  @override
  Future<ExamLinkedDataCounts> getLinkedDataCounts(String id) async {
    final raw = await _loadExaminationData();

    final rawPapers = (raw['exam_papers'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final linkedPapers =
        rawPapers.where((p) => (p['exam_schedule_id'] ?? '') == id).toList();
    final linkedPaperIds =
        linkedPapers.map((p) => (p['id'] ?? '').toString()).toSet();

    int countIn(String key, {bool checkPaperId = false}) {
      if (!raw.containsKey(key) || raw[key] is! List) return 0;
      final list = (raw[key] as List).whereType<Map<String, dynamic>>().toList();
      return list.where((item) {
        final schId = item['exam_schedule_id']?.toString();
        final pId = (item['paper_id'] ?? item['exam_paper_id'])?.toString();
        return schId == id || (checkPaperId && pId != null && linkedPaperIds.contains(pId));
      }).length;
    }

    final hallTickets = countIn('hall_tickets', checkPaperId: true);
    final attendance = countIn('exam_attendance', checkPaperId: true) +
        countIn('attendance', checkPaperId: true);
    final marks = countIn('student_exam_marks', checkPaperId: true) +
        countIn('marks', checkPaperId: true);
    final reportCards = countIn('report_cards');

    return ExamLinkedDataCounts(
      papers: linkedPapers.length,
      hallTickets: hallTickets,
      attendance: attendance,
      marks: marks,
      reportCards: reportCards,
    );
  }

  // ---------------------------------------------------------------------------
  // DATE OVERLAP CHECK (Warning Only, Non-Blocking)
  // ---------------------------------------------------------------------------
  @override
  Future<ExamSchedule?> checkDateOverlap({
    required String examType,
    required String academicYear,
    required String startDate,
    required String endDate,
    String? excludeExamId,
  }) async {
    final all = await getExams(academicYear: academicYear, examType: examType);
    final newStart = _parseDateOnly(startDate);
    final newEnd = _parseDateOnly(endDate);

    for (final other in all) {
      if (other.examScheduleId == excludeExamId) continue;
      if (other.isCancelled) continue;

      final otherStart = _parseDateOnly(other.startDate);
      final otherEnd = _parseDateOnly(other.endDate);

      // Overlap condition:
      final overlaps = !(newEnd.isBefore(otherStart) || newStart.isAfter(otherEnd));
      if (overlaps) {
        return other;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // GLOBAL SETUP & CURRENT USER
  // ---------------------------------------------------------------------------
  @override
  Future<GlobalSetup> getGlobalSetup() async {
    final raw = await _localDataSource.readGlobalJson();
    return GlobalSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> setCurrentUser(String userId) async {
    final setup = await getGlobalSetup();
    final updated = setup.copyWith(currentUserId: userId);
    const encoder = JsonEncoder.withIndent('  ');
    await _localDataSource.writeGlobalJson(encoder.convert(updated.toJson()));
  }

  // ---------------------------------------------------------------------------
  // RESET DEMO DATA
  // ---------------------------------------------------------------------------
  @override
  Future<void> resetDemoData() async {
    await _localDataSource.resetDemoData();
  }
}
