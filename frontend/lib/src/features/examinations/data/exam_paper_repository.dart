import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../domain/exam_timetable_model.dart';
import '../domain/exam_reference_model.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import '../domain/room_model.dart';
import 'exam_repository.dart';
import 'examination_local_datasource.dart';

/// Repository for Exam Timetable (formerly Exam Papers).
/// Persists entries to examination.json (under `exam_papers` / `exam_timetables`)
/// so Screen 1 exam schedule paper counts remain synchronized and backwards compatible.
class ExamTimetableRepository {
  final ExaminationLocalDataSource _ds;
  final Uuid _uuid = const Uuid();
  ExamReferenceData? _refCache;

  ExamTimetableRepository({ExaminationLocalDataSource? dataSource})
      : _ds = dataSource ?? ExaminationLocalDataSource();

  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await _ds.readExaminationJson()) as Map<String, dynamic>;

  Future<void> _save(Map<String, dynamic> data) async =>
      _ds.writeExaminationJson(const JsonEncoder.withIndent('  ').convert(data));

  List<Map<String, dynamic>> _rawPapers(Map<String, dynamic> raw) =>
      (raw['exam_papers'] as List<dynamic>? ?? raw['exam_timetables'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  Future<ExamReferenceData> getReferenceData() async {
    if (_refCache != null) return _refCache!;

    Future<dynamic> asset(String p) async {
      try {
        final content = await rootBundle.loadString(p);
        return jsonDecode(content);
      } catch (_) {
        return null;
      }
    }

    // 1. Load shared master data from global_school_database.json (with modular fallbacks)
    final globalDb = (await asset('assets/data/global_school_database.json') as Map<String, dynamic>?) ?? {};
    final setup = (await asset('assets/data/academics/academic_setup.json') as Map<String, dynamic>?) ?? {};
    final classesJson = (await asset('assets/data/classes/classes.json') as Map<String, dynamic>?) ?? {};
    final staff = (await asset('assets/data/staff/staff_global.json') as Map<String, dynamic>?) ?? {};
    final users = await asset('assets/data/auth/users.json');

    final userList = [
      ...((globalDb['users'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((users is List ? users : (users as Map<String, dynamic>?)?['users'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];

    final userNames = <String, String>{};
    for (final u in userList) {
      final uid = u['id'].toString();
      if (!userNames.containsKey(uid)) {
        userNames[uid] = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
      }
    }

    // 1. Teachers
    final teachers = <TeacherRef>[];
    final teacherProfiles = [
      ...((globalDb['teacher_profiles'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((staff['teacher_profiles'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];
    for (final t in teacherProfiles) {
      final tid = t['id'].toString();
      if (!teachers.any((x) => x.id == tid)) {
        final name = userNames[t['user_id']?.toString()] ?? '';
        teachers.add(TeacherRef(
          tid,
          name.isEmpty ? (t['employee_id']?.toString() ?? tid) : name,
          employeeId: t['employee_id']?.toString() ?? '',
          department: t['department']?.toString() ?? '',
        ));
      }
    }

    // Also load staff from staff.json (for staff IDs like STF-2026-0115)
    final staffJson = await asset('assets/data/staff/staff.json');
    if (staffJson is List) {
      for (final s in staffJson.whereType<Map<String, dynamic>>()) {
        final sid = s['id']?.toString() ?? '';
        if (sid.isNotEmpty && !teachers.any((x) => x.id == sid)) {
          final fullName = s['fullName']?.toString() ?? '';
          teachers.add(TeacherRef(
            sid,
            fullName.isNotEmpty ? fullName : sid,
            employeeId: s['employeeId']?.toString() ?? sid,
            department: s['department']?.toString() ?? '',
          ));
        }
      }
    }

    // 2. Classrooms / Rooms
    final rooms = <RoomRef>[];
    final globalSections = (globalDb['class_sections'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    for (final s in globalSections) {
      final roomNum = s['room_number']?.toString();
      if (roomNum != null && roomNum.isNotEmpty && !rooms.any((r) => r.label.contains(roomNum))) {
        rooms.add(RoomRef('room-${roomNum.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}', roomNum, capacity: 40));
      }
    }
    final classrooms = (classesJson['classrooms'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    for (final r in classrooms) {
      final cap = (r['capacity'] as num?)?.toInt() ?? 40;
      final rid = r['id'].toString();
      if (!rooms.any((x) => x.id == rid)) {
        rooms.add(RoomRef(
          rid,
          '${r['name']} (cap $cap)',
          capacity: cap,
          building: r['building']?.toString() ?? '',
        ));
      }
    }

    // 3. Classes
    final classesList = <ClassRef>[];
    final rawClasses = (classesJson['classes'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    for (final c in rawClasses) {
      classesList.add(ClassRef(
        c['id'].toString(),
        c['name'].toString(),
        code: c['code']?.toString() ?? '',
      ));
    }

    bool isSameClassName(String a, String b) {
      if (a.toLowerCase().trim() == b.toLowerCase().trim()) return true;
      final d1 = RegExp(r'\d+').firstMatch(a)?.group(0);
      final d2 = RegExp(r'\d+').firstMatch(b)?.group(0);
      return d1 != null && d1 == d2;
    }

    final allRawSections = [
      ...globalSections,
      ...((setup['class_sections'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];
    for (final s in allRawSections) {
      final className = s['class_name']?.toString() ?? '';
      if (className.isNotEmpty) {
        final existing = classesList.where((c) => isSameClassName(c.label, className)).firstOrNull;
        if (existing == null) {
          final syntheticId = 'cls-${className.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
          classesList.add(ClassRef(syntheticId, className));
        }
      }
    }

    // 4. Sections
    final sectionsList = <SectionRef>[];
    for (final s in allRawSections) {
      final secId = s['id'].toString();
      if (!sectionsList.any((x) => x.id == secId)) {
        final className = s['class_name']?.toString() ?? '';
        final secName = s['section_name']?.toString() ?? '';
        final matchingClass = classesList.where((c) => isSameClassName(c.label, className)).firstOrNull;
        final classId = matchingClass?.id ?? 'cls-${className.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';

        sectionsList.add(SectionRef(
          secId,
          '$className - $secName',
          classId: classId,
          sectionName: secName,
          teacherId: s['class_incharge_id']?.toString(),
          classroomId: s['room_number']?.toString(),
        ));
      }
    }

    for (final s in (classesJson['sections'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()) {
      final secId = s['id'].toString();
      if (!sectionsList.any((x) => x.id == secId)) {
        final clsId = s['class_id']?.toString() ?? '';
        final cls = classesList.where((c) => c.id == clsId).firstOrNull;
        final clsName = cls?.label ?? clsId;
        final secName = s['name']?.toString() ?? '';
        sectionsList.add(SectionRef(
          secId,
          '$clsName - $secName',
          classId: clsId,
          sectionName: secName,
          capacity: (s['capacity'] as num?)?.toInt() ?? 35,
          classroomId: s['classroom_id']?.toString(),
          teacherId: s['class_teacher_id']?.toString(),
        ));
      }
    }

    // 5. Subject Allocations
    final allocations = <SubjectAllocationRef>[];
    final allAllocations = [
      ...((globalDb['class_subject_allocations'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((setup['class_subject_allocations'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];
    for (final a in allAllocations) {
      allocations.add(SubjectAllocationRef(
        a['class_section_id'].toString(),
        a['subject_id'].toString(),
        a['teacher_id']?.toString(),
      ));
    }

    // 6. Subjects
    final subjectsList = <SubjectRef>[];
    final allSubjects = [
      ...((globalDb['subjects'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
      ...((setup['subjects'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()),
    ];
    for (final s in allSubjects) {
      final subId = s['id'].toString();
      if (!subjectsList.any((x) => x.id == subId)) {
        final name = (s['subject_name'] ?? s['name'])?.toString() ?? '';
        final linkedSec = allocations.where((a) => a.subjectId == subId).firstOrNull;
        final sec = sectionsList.where((x) => x.id == linkedSec?.classSectionId).firstOrNull;
        final clsId = sec?.classId ?? s['class_id']?.toString() ?? '';

        subjectsList.add(SubjectRef(
          subId,
          name,
          classId: clsId,
          code: (s['subject_code'] ?? s['code'])?.toString() ?? '',
          defaultTeacherId: linkedSec?.teacherId,
        ));
      }
    }

    for (final s in (classesJson['subjects'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>()) {
      final subId = s['id'].toString();
      if (!subjectsList.any((x) => x.id == subId)) {
        subjectsList.add(SubjectRef(
          subId,
          s['name']?.toString() ?? '',
          classId: s['class_id']?.toString() ?? '',
          code: s['code']?.toString() ?? '',
          defaultTeacherId: s['teacher_id']?.toString(),
          maxMarks: (s['max_marks'] as num?)?.toDouble() ?? 100.0,
          passMarks: (s['pass_marks'] as num?)?.toDouble() ?? 35.0,
        ));
      }
    }

    // Ensure any teacher referenced by subjects or allocations is present in teachers
    for (final s in subjectsList) {
      final tid = s.defaultTeacherId;
      if (tid != null && tid.isNotEmpty && !teachers.any((x) => x.id == tid)) {
        teachers.add(TeacherRef(tid, tid));
      }
    }
    for (final a in allocations) {
      final tid = a.teacherId;
      if (tid != null && tid.isNotEmpty && !teachers.any((x) => x.id == tid)) {
        teachers.add(TeacherRef(tid, tid));
      }
    }

    return _refCache = ExamReferenceData(
      classes: classesList,
      sections: sectionsList,
      subjects: subjectsList,
      rooms: rooms,
      teachers: teachers,
      allocations: allocations,
    );
  }

  Future<List<Room>> getRooms() async {
    final raw = await _load();
    final rawRooms = (raw['rooms'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    if (rawRooms.isNotEmpty) {
      return rawRooms.map(Room.fromJson).toList();
    }
    final ref = await getReferenceData();
    return ref.rooms
        .map((r) => Room(roomId: r.id, roomNumber: r.label, capacity: r.capacity))
        .toList();
  }

  Future<List<ExamTimetableEntry>> getPapers(String examScheduleId) async {
    final raw = await _load();
    final list = _rawPapers(raw)
        .where((p) => p['exam_schedule_id']?.toString() == examScheduleId)
        .map(ExamTimetableEntry.fromJson)
        .toList()
      ..sort((a, b) {
        final c = (a.examDate ?? '').compareTo(b.examDate ?? '');
        return c != 0 ? c : a.startTime.compareTo(b.startTime);
      });
    return list;
  }

  /// Rule 10: changing an exam's dates is blocked if any timetable entry would fall outside the new range
  Future<List<ExamTimetableEntry>> papersOutsideRange(
      String examScheduleId, String start, String end) async {
    final papers = await getPapers(examScheduleId);
    return papers
        .where((p) =>
            p.examDate != null &&
            (p.examDate!.compareTo(start) < 0 || p.examDate!.compareTo(end) > 0))
        .toList();
  }

  int _mins(String hhmm) {
    try {
      final p = hhmm.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _validate(
    ExamTimetableEntry paper,
    ExamSchedule exam,
    List<ExamTimetableEntry> existing,
  ) async {
    // Rule 8: read-only if exam is COMPLETED or CANCELLED
    if (exam.isCancelled || exam.isCompleted) {
      throw ExamValidationException(
          'Timetable entries cannot be changed for a ${exam.status.toLowerCase()} exam.');
    }
    if (paper.classSectionId == null || paper.classSectionId!.isEmpty) {
      throw const ExamValidationException('Class / Section: This field is required.');
    }
    if (paper.subjectId == null || paper.subjectId!.isEmpty) {
      throw const ExamValidationException('Subject: This field is required.');
    }
    if (paper.examDate == null || paper.examDate!.isEmpty) {
      throw const ExamValidationException('Exam Date: This field is required.');
    }
    // Rule 1: exam_date must fall between exam start_date and end_date
    if (paper.examDate!.compareTo(exam.startDate) < 0 ||
        paper.examDate!.compareTo(exam.endDate) > 0) {
      throw ExamValidationException(
          'Exam date must be between ${exam.startDate} and ${exam.endDate}.');
    }
    // Rule 2: end_time must be after start_time
    if (_mins(paper.endTime) <= _mins(paper.startTime)) {
      throw const ExamValidationException('End time must be after the start time.');
    }
    // Rule 3: max_marks > 0 and passing_marks between 0 and max_marks
    if (paper.maxMarks <= 0) {
      throw const ExamValidationException('Max marks must be greater than 0.');
    }
    if (paper.passingMarks < 0 || paper.passingMarks > paper.maxMarks) {
      throw const ExamValidationException('Passing marks cannot exceed max marks.');
    }

    final others = existing.where((p) => p.id != paper.id && !p.isCancelled);

    // Rule 7 & Unique rule: one paper per (exam_schedule_id, class_section_id, subject_id)
    if (others.any((p) =>
        p.classSectionId == paper.classSectionId &&
        p.subjectId == paper.subjectId)) {
      throw const ExamValidationException(
          'This subject already has a paper for the selected class in this exam.');
    }

    bool overlaps(ExamTimetableEntry p) =>
        p.examDate == paper.examDate &&
        _mins(p.startTime) < _mins(paper.endTime) &&
        _mins(paper.startTime) < _mins(p.endTime);

    // Rule 4: A class section cannot have two papers that overlap in time on the same date
    if (others.any((p) => p.classSectionId == paper.classSectionId && overlaps(p))) {
      throw const ExamValidationException(
          'This class section cannot have two papers that overlap in time on the same date.');
    }

    // Rules 5 & 6: Invigilator and Room clash across ALL exams, not just this one
    final raw = await _load();
    final all = _rawPapers(raw)
        .map(ExamTimetableEntry.fromJson)
        .where((p) => p.id != paper.id && !p.isCancelled && overlaps(p));

    // Rule 5: An invigilator cannot be assigned to two papers that overlap in time
    if (paper.invigilatorId != null &&
        paper.invigilatorId!.isNotEmpty &&
        all.any((p) => p.invigilatorId == paper.invigilatorId)) {
      throw const ExamValidationException(
          'This invigilator is already assigned to another paper at that time.');
    }

    // Rule 6: A room cannot be used by two different classes at overlapping times
    if (paper.roomId != null &&
        paper.roomId!.isNotEmpty &&
        all.any((p) => p.roomId == paper.roomId &&
            p.classSectionId != paper.classSectionId)) {
      throw const ExamValidationException(
          'This room is already used by another paper at that time.');
    }
  }

  void _requireWrite(ExaminationActor actor) {
    if (!actor.permissions.isAdminOrPrincipal) {
      throw const ExamPermissionException(
          'Permission denied: Only Admin or Principal can manage exam timetable.');
    }
  }

  Future<ExamTimetableEntry> addPaper(ExamTimetableEntry paper, ExamSchedule exam,
      {required ExaminationActor actor}) async {
    _requireWrite(actor);
    final existing = await getPapers(exam.examScheduleId);
    final now = DateTime.now().toIso8601String();
    final p = ExamTimetableEntry(
      id: 'paper-${_uuid.v4().substring(0, 8)}',
      examScheduleId: exam.examScheduleId,
      classId: paper.classId,
      classSectionId: paper.classSectionId,
      subjectId: paper.subjectId,
      examDate: paper.examDate,
      startTime: paper.startTime,
      endTime: paper.endTime,
      maxMarks: paper.maxMarks,
      passingMarks: paper.passingMarks,
      invigilatorId: paper.invigilatorId,
      roomId: paper.roomId,
      status: 'SCHEDULED',
      createdAt: now,
      updatedAt: now,
    );
    await _validate(p, exam, existing);

    final raw = await _load();
    final list = _rawPapers(raw)..add(p.toJson());
    raw['exam_papers'] = list;
    await _save(raw);
    return p;
  }

  Future<ExamTimetableEntry> updatePaper(ExamTimetableEntry paper, ExamSchedule exam,
      {required ExaminationActor actor}) async {
    _requireWrite(actor);
    final existing = await getPapers(exam.examScheduleId);
    await _validate(paper, exam, existing);

    final raw = await _load();
    final list = _rawPapers(raw);
    final i = list.indexWhere((e) => e['id']?.toString() == paper.id);
    if (i < 0) throw const ExamValidationException('Timetable entry not found.');

    final json = paper.toJson()..['updated_at'] = DateTime.now().toIso8601String();
    list[i] = json;
    raw['exam_papers'] = list;
    await _save(raw);
    return ExamTimetableEntry.fromJson(json);
  }

  Future<void> deletePaper(String paperId, ExamSchedule exam,
      {required ExaminationActor actor}) async {
    _requireWrite(actor);
    if (exam.isCancelled || exam.isCompleted) {
      throw ExamValidationException(
          'Timetable entries cannot be removed from a ${exam.status.toLowerCase()} exam.');
    }
    final raw = await _load();
    final list = _rawPapers(raw)
      ..removeWhere((e) => e['id']?.toString() == paperId);
    raw['exam_papers'] = list;
    await _save(raw);
  }
}

/// Compatibility alias
typedef ExamPaperRepository = ExamTimetableRepository;
