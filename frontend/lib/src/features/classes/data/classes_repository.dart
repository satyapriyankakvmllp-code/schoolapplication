import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import '../../../utils/asset_loader.dart';
import '../domain/class_model.dart';
import '../domain/classes_actor.dart';
import '../domain/classroom_model.dart';
import '../domain/curriculum_model.dart';
import '../domain/daily_lesson_model.dart';
import '../domain/section_model.dart';
import '../domain/subject_model.dart';
import '../domain/teacher_work_model.dart';
import '../domain/timetable_entry_model.dart';

class ClassesPermissionException implements Exception {
  final String message;
  const ClassesPermissionException(this.message);
  @override
  String toString() => message;
}

class ClassesDataException implements Exception {
  final String message;
  const ClassesDataException(this.message);
  @override
  String toString() => message;
}

/// Contract for the Classes data layer.
/// Today it is backed by [MockClassesRepository] (JSON file). Later, add an
/// `ApiClassesRepository implements ClassesRepository` and swap it in
/// `classesRepositoryProvider` - screens and controllers stay unchanged.
abstract class ClassesRepository {
  /// Current data as a formatted JSON string.
  String exportJsonString();

  Future<List<ClassModel>> getClasses(ClassesActor a);
  Future<List<SectionModel>> getSections(ClassesActor a);
  Future<List<SubjectModel>> getSubjects(ClassesActor a);
  Future<List<CurriculumModel>> getCurriculum(ClassesActor a);
  Future<List<DailyLessonModel>> getLessons(ClassesActor a);
  Future<List<TimetableEntryModel>> getTimetable(ClassesActor a);
  Future<List<ClassroomModel>> getClassrooms(ClassesActor a);
  Future<List<TeacherWorkModel>> getTeacherWork(ClassesActor a);
  Future<ClassModel> saveClass(ClassesActor a, ClassModel model, {bool isNew = false});
  Future<void> deleteClass(ClassesActor a, String id);
  Future<ClassModel> assignClassTeacher(ClassesActor a, String classId, String? teacherId);
  Future<SectionModel> saveSection(ClassesActor a, SectionModel model, {bool isNew = false});
  Future<void> deleteSection(ClassesActor a, String id);
  Future<SubjectModel> saveSubject(ClassesActor a, SubjectModel model, {bool isNew = false});
  Future<void> deleteSubject(ClassesActor a, String id);
  Future<SubjectModel> assignSubjectTeacher(ClassesActor a, String subjectId, String? teacherId);
  Future<CurriculumModel> saveCurriculum(ClassesActor a, CurriculumModel model, {bool isNew = false});
  Future<void> deleteCurriculum(ClassesActor a, String id);
  Future<CurriculumModel> updateProgress(ClassesActor a, String curriculumId, int completedTopics);
  Future<DailyLessonModel> saveLesson(ClassesActor a, DailyLessonModel model, {bool isNew = false});
  Future<void> deleteLesson(ClassesActor a, String id);
  Future<TimetableEntryModel> saveTimetableEntry(ClassesActor a, TimetableEntryModel model, {bool isNew = false});
  Future<void> deleteTimetableEntry(ClassesActor a, String id);
  Future<ClassroomModel> saveClassroom(ClassesActor a, ClassroomModel model, {bool isNew = false});
  Future<void> deleteClassroom(ClassesActor a, String id);
  Future<TeacherWorkModel> saveTeacherWork(ClassesActor a, TeacherWorkModel model, {bool isNew = false});
  Future<void> deleteTeacherWork(ClassesActor a, String id);
}

/// JSON-backed mock repository (assets/data/classes/classes.json and individual files)
/// with in-memory caching. Every change is written back to classes.json on disk
/// (desktop), and the data is read from that same file on start.
///
/// Every mutation re-checks the actor's permissions here, ensuring robust
/// role-based authorization at the data boundary.
class MockClassesRepository implements ClassesRepository {
  static const String assetPath = 'assets/data/classes/classes.json';
  static const String fallbackAssetPath = 'assets/data/classes.json';

  final AssetLoader _loader;
  Future<void>? _loading;

  List<ClassModel> _classes = [];
  List<SectionModel> _sections = [];
  List<SubjectModel> _subjects = [];
  List<CurriculumModel> _curriculum = [];
  List<DailyLessonModel> _lessons = [];
  List<TimetableEntryModel> _timetable = [];
  List<ClassroomModel> _classrooms = [];
  List<TeacherWorkModel> _teacherWork = [];
  int _seq = 0;

  MockClassesRepository({AssetLoader? loader}) : _loader = loader ?? const AssetLoader();

  Future<void> _ensureLoaded() => _loading ??= _load();

  /// Candidate locations of classes.json on disk (desktop only).
  /// The SAME list is used for reading and writing, so what you save is
  /// exactly what is loaded next time.
  static const List<String> _jsonFilePaths = [
    'assets/data/classes/classes.json',
    'frontend/assets/data/classes/classes.json',
    'assets/data/classes.json',
    'frontend/assets/data/classes.json',
  ];

  /// First classes.json that exists on disk, or null (web / not found).
  io.File? _findJsonFile() {
    if (kIsWeb) return null;
    for (final p in _jsonFilePaths) {
      try {
        final f = io.File(p);
        if (f.existsSync()) return f;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _load() async {
    Map<String, dynamic>? rawJson;

    // 1. Read classes.json straight from disk (desktop). This is the single source of truth.
    final jsonFile = _findJsonFile();
    if (jsonFile != null) {
      try {
        final decoded = jsonDecode(await jsonFile.readAsString());
        if (decoded is Map<String, dynamic>) rawJson = decoded;
      } catch (_) {}
    }

    // 2. Load via asset bundle (Web or packaged app)
    if (rawJson == null) {
      try {
        rawJson = await _loader.loadJsonObject(assetPath, delayMs: 0);
      } catch (_) {
        try {
          rawJson = await _loader.loadJsonObject(fallbackAssetPath, delayMs: 0);
        } catch (_) {}
      }
    }

    // Fallback to defaults only if JSON file is completely missing
    rawJson ??= _buildInitialDefaultData();

    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        (rawJson?[key] as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    _classes = parse('classes', ClassModel.fromJson);
    _sections = parse('sections', SectionModel.fromJson);
    _subjects = parse('subjects', SubjectModel.fromJson);
    _curriculum = parse('curriculum', CurriculumModel.fromJson);
    if (_curriculum.isEmpty) {
      _curriculum = parse('syllabus', CurriculumModel.fromJson);
    }
    if (_curriculum.isEmpty) {
      _curriculum = [
        const CurriculumModel(
          id: 'cur-1',
          classId: 'cls-5',
          subjectId: 'sub-101',
          title: 'Primary Mathematics',
          description: 'Foundations of number operations and shapes',
          topics: ['Chapter 1', 'Chapter 2'],
          completedTopics: 1,
        ),
        const CurriculumModel(
          id: 'cur-2',
          classId: 'cls-10',
          subjectId: 'sub-101',
          title: 'Secondary Mathematics',
          description: 'Advanced algebra, geometry, and trigonometry',
          topics: ['Chapter 1', 'Chapter 2', 'Chapter 3'],
          completedTopics: 2,
        ),
      ];
    }
    _lessons = parse('daily_lessons', DailyLessonModel.fromJson);
    _timetable = parse('timetable', TimetableEntryModel.fromJson);
    _classrooms = parse('classrooms', ClassroomModel.fromJson);
    _teacherWork = parse('teacher_work', TeacherWorkModel.fromJson);
    if (_teacherWork.isEmpty) {
      _teacherWork = parse('teacher_assignments', TeacherWorkModel.fromJson);
    }
  }

  /// Writes all data back into classes.json (the only storage).
  Future<void> _persist() async {
    final jsonStr = exportJsonString();
    final isRunningTest = !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
    if (kIsWeb || isRunningTest) return; // browsers cannot write project files

    final file = _findJsonFile();
    if (file == null) {
      throw const ClassesDataException(
        'classes.json not found. Run the app from the "frontend" folder.',
      );
    }
    await file.writeAsString(jsonStr);
  }

  /// Export current JSON data as a formatted string
  @override
  String exportJsonString() {
    final payload = {
      'classes': _classes.map((c) => c.toJson()).toList(),
      'sections': _sections.map((s) => s.toJson()).toList(),
      'subjects': _subjects.map((s) => s.toJson()).toList(),
      'curriculum': _curriculum.map((c) => c.toJson()).toList(),
      'syllabus': _curriculum.map((c) => c.toJson()).toList(),
      'daily_lessons': _lessons.map((l) => l.toJson()).toList(),
      'timetable': _timetable.map((t) => t.toJson()).toList(),
      'classrooms': _classrooms.map((r) => r.toJson()).toList(),
      'teacher_work': _teacherWork.map((w) => w.toJson()).toList(),
      'teacher_assignments': _teacherWork.map((w) => w.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  void _require(bool allowed, String what) {
    if (!allowed) throw ClassesPermissionException('Not permitted: $what');
  }

  // ---------------------------------------------------------------- reads
  // Reads are scoped to the actor: students only see their own class.
  @override
  Future<List<ClassModel>> getClasses(ClassesActor a) async {
    await _ensureLoaded();
    _require(a.permissions.canAccessClasses, 'view classes');
    if (a.permissions.isAdmin) return List.of(_classes);
    if (a.permissions.isTeacher) {
      final ids = _teacherClassIds(a.userId);
      return _classes.where((c) => ids.contains(c.id)).toList();
    }
    return _classes.where((c) => _studentClassMatches(c, a)).toList();
  }

  bool _matchesTeacher(String teacherId, String? id) =>
      id == teacherId || (teacherId == 'USR-TEACH-01' && (id == 'tch-101' || id == 'tch-102'));

  Set<String> _teacherClassIds(String teacherId) {
    return {
      for (final c in _classes) if (_matchesTeacher(teacherId, c.classTeacherId)) c.id,
      for (final s in _subjects) if (_matchesTeacher(teacherId, s.teacherId)) s.classId,
      for (final t in _timetable) if (_matchesTeacher(teacherId, t.teacherId)) t.classId,
    };
  }

  bool _studentClassMatches(ClassModel c, ClassesActor a) =>
      a.studentClassName != null && c.name.toLowerCase() == a.studentClassName!.toLowerCase();

  Future<Set<String>> _visibleClassIds(ClassesActor a) async =>
      (await getClasses(a)).map((c) => c.id).toSet();

  @override
  Future<List<SectionModel>> getSections(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    var list = _sections.where((s) => ids.contains(s.classId));
    if (a.permissions.isStudent && a.studentSection != null) {
      list = list.where((s) => s.name.toUpperCase() == a.studentSection!.toUpperCase());
    }
    return list.toList();
  }

  @override
  Future<List<SubjectModel>> getSubjects(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    var list = _subjects.where((s) => ids.contains(s.classId));
    if (a.permissions.isTeacher) {
      final classTeacherOf = {
        for (final c in _classes)
          if (_matchesTeacher(a.userId, c.classTeacherId)) c.id
      };
      list = list.where((s) => _matchesTeacher(a.userId, s.teacherId) || classTeacherOf.contains(s.classId));
    }
    return list.toList();
  }

  @override
  Future<List<CurriculumModel>> getCurriculum(ClassesActor a) async {
    await _ensureLoaded();
    final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
    return _curriculum.where((c) => subjectIds.contains(c.subjectId)).toList();
  }

  @override
  Future<List<DailyLessonModel>> getLessons(ClassesActor a) async {
    await _ensureLoaded();
    final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
    return _lessons.where((l) => subjectIds.contains(l.subjectId)).toList()
      ..sort((x, y) => y.date.compareTo(x.date));
  }

  @override
  Future<List<TimetableEntryModel>> getTimetable(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    final sectionIds = (await getSections(a)).map((s) => s.id).toSet();
    var list = _timetable.where((t) => ids.contains(t.classId));
    if (a.permissions.isTeacher) {
      list = list.where((t) => _matchesTeacher(a.userId, t.teacherId));
    }
    if (a.permissions.isStudent) list = list.where((t) => sectionIds.contains(t.sectionId));
    return list.toList()
      ..sort((x, y) {
        final d = x.dayOfWeek.compareTo(y.dayOfWeek);
        return d != 0 ? d : x.startTime.compareTo(y.startTime);
      });
  }

  @override
  Future<List<ClassroomModel>> getClassrooms(ClassesActor a) async {
    await _ensureLoaded();
    _require(a.permissions.canAccessClasses, 'view classrooms');
    if (a.permissions.isAdmin) return List.of(_classrooms);
    final classIds = await _visibleClassIds(a);
    final used = <String>{
      for (final c in _classes) if (classIds.contains(c.id) && c.classroomId != null) c.classroomId!,
      for (final s in await getSections(a)) if (s.classroomId != null) s.classroomId!,
      for (final t in await getTimetable(a)) if (t.classroomId != null) t.classroomId!,
    };
    return _classrooms.where((r) => used.contains(r.id)).toList();
  }

  @override
  Future<List<TeacherWorkModel>> getTeacherWork(ClassesActor a) async {
    await _ensureLoaded();
    _require(a.permissions.canViewTeacherWork, 'view teacher work');
    if (a.permissions.isAdmin) return List.of(_teacherWork);
    final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
    final classIds = await _visibleClassIds(a);
    return _teacherWork
        .where((w) => subjectIds.contains(w.subjectId) || classIds.contains(w.classId))
        .toList()
      ..sort((x, y) => x.dueDate.compareTo(y.dueDate));
  }

  // --------------------------------------------------------------- classes
  @override
  Future<ClassModel> saveClass(ClassesActor a, ClassModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClasses, 'manage classes');

    // Duplicate class prevention
    final isDuplicate = _classes.any((c) =>
        (isNew || c.id != model.id) &&
        c.name.trim().toLowerCase() == model.name.trim().toLowerCase());
    if (isDuplicate) {
      throw ClassesDataException('A class named "${model.name}" already exists.');
    }

    if (isNew) {
      final created = ClassModel(
        id: _newId('cls'),
        name: model.name,
        gradeLevel: model.gradeLevel,
        academicYear: model.academicYear,
        classTeacherId: model.classTeacherId,
        classroomId: model.classroomId,
      );
      _classes = [..._classes, created];
      await _persist();
      return created;
    }
    _classes = [for (final c in _classes) c.id == model.id ? model : c];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteClass(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClasses, 'delete classes');
    _classes = _classes.where((c) => c.id != id).toList();
    _sections = _sections.where((s) => s.classId != id).toList();
    final removedSubjects = _subjects.where((s) => s.classId == id).map((s) => s.id).toSet();
    _subjects = _subjects.where((s) => s.classId != id).toList();
    _curriculum = _curriculum.where((c) => c.classId != id).toList();
    _lessons = _lessons.where((l) => l.classId != id && !removedSubjects.contains(l.subjectId)).toList();
    _timetable = _timetable.where((t) => t.classId != id).toList();
    _teacherWork = _teacherWork.where((w) => w.classId != id).toList();
    await _persist();
  }

  @override
  Future<ClassModel> assignClassTeacher(ClassesActor a, String classId, String? teacherId) async {
    await _ensureLoaded();
    _require(a.permissions.canAssignTeachers, 'assign class teachers');
    final current = _classes.firstWhere((c) => c.id == classId);
    final next = teacherId == null
        ? current.copyWith(clearClassTeacher: true)
        : current.copyWith(classTeacherId: teacherId);
    _classes = [for (final c in _classes) c.id == classId ? next : c];
    await _persist();
    return next;
  }

  // -------------------------------------------------------------- sections
  @override
  Future<SectionModel> saveSection(ClassesActor a, SectionModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSections, 'manage sections');

    // Duplicate section prevention for the same class
    final isDuplicate = _sections.any((s) =>
        (isNew || s.id != model.id) &&
        s.classId == model.classId &&
        s.name.trim().toLowerCase() == model.name.trim().toLowerCase());
    if (isDuplicate) {
      throw ClassesDataException('Section "${model.name}" already exists for this class.');
    }

    if (isNew) {
      final created = SectionModel(
        id: _newId('sec'),
        classId: model.classId,
        name: model.name,
        capacity: model.capacity,
        classroomId: model.classroomId,
      );
      _sections = [..._sections, created];
      await _persist();
      return created;
    }
    _sections = [for (final s in _sections) s.id == model.id ? model : s];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteSection(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSections, 'delete sections');
    _sections = _sections.where((s) => s.id != id).toList();
    _timetable = _timetable.where((t) => t.sectionId != id).toList();
    _teacherWork = _teacherWork.where((w) => w.sectionId != id).toList();
    await _persist();
  }

  // -------------------------------------------------------------- subjects
  @override
  Future<SubjectModel> saveSubject(ClassesActor a, SubjectModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSubjects, 'manage subjects');
    if (isNew) {
      final created = SubjectModel(
        id: _newId('sub'),
        classId: model.classId,
        name: model.name,
        code: model.code,
        teacherId: model.teacherId,
      );
      _subjects = [..._subjects, created];
      await _persist();
      return created;
    }
    _subjects = [for (final s in _subjects) s.id == model.id ? model : s];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteSubject(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSubjects, 'delete subjects');
    _subjects = _subjects.where((s) => s.id != id).toList();
    _curriculum = _curriculum.where((c) => c.subjectId != id).toList();
    _lessons = _lessons.where((l) => l.subjectId != id).toList();
    _timetable = _timetable.where((t) => t.subjectId != id).toList();
    _teacherWork = _teacherWork.where((w) => w.subjectId != id).toList();
    await _persist();
  }

  @override
  Future<SubjectModel> assignSubjectTeacher(ClassesActor a, String subjectId, String? teacherId) async {
    await _ensureLoaded();
    _require(a.permissions.canAssignTeachers, 'assign subject teachers');
    final current = _subjects.firstWhere((s) => s.id == subjectId);
    final next = current.copyWith(teacherId: teacherId, clearTeacher: teacherId == null);
    _subjects = [for (final s in _subjects) s.id == subjectId ? next : s];
    await _persist();
    return next;
  }

  // ------------------------------------------------------------ curriculum
  @override
  Future<CurriculumModel> saveCurriculum(ClassesActor a, CurriculumModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageCurriculum, 'manage curriculum');
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == model.subjectId);
      final matchesTeacher = subject.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (subject.teacherId == 'tch-101' || subject.teacherId == 'tch-102'));
      _require(matchesTeacher, 'manage curriculum for a subject not assigned to you');
    }
    if (isNew) {
      final created = CurriculumModel(
        id: _newId('cur'),
        classId: model.classId,
        subjectId: model.subjectId,
        title: model.title,
        description: model.description,
        topics: model.topics,
        completedTopics: model.completedTopics,
      );
      _curriculum = [..._curriculum, created];
      await _persist();
      return created;
    }
    _curriculum = [for (final c in _curriculum) c.id == model.id ? model : c];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteCurriculum(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageCurriculum, 'delete curriculum');
    final existing = _curriculum.firstWhere((c) => c.id == id);
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == existing.subjectId);
      final matchesTeacher = subject.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (subject.teacherId == 'tch-101' || subject.teacherId == 'tch-102'));
      _require(matchesTeacher, 'delete curriculum for a subject not assigned to you');
    }
    _curriculum = _curriculum.where((c) => c.id != id).toList();
    await _persist();
  }

  /// Teachers may update progress only for subjects they are assigned to.
  @override
  Future<CurriculumModel> updateProgress(ClassesActor a, String curriculumId, int completedTopics) async {
    await _ensureLoaded();
    _require(a.permissions.canUpdateCurriculumProgress, 'update curriculum progress');
    final current = _curriculum.firstWhere((c) => c.id == curriculumId);
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == current.subjectId);
      final matchesTeacher = subject.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (subject.teacherId == 'tch-101' || subject.teacherId == 'tch-102'));
      _require(matchesTeacher, 'update progress for a subject not assigned to you');
    }
    final next = current.copyWith(completedTopics: completedTopics);
    _curriculum = [for (final c in _curriculum) c.id == curriculumId ? next : c];
    await _persist();
    return next;
  }

  // --------------------------------------------------------- daily lessons
  @override
  Future<DailyLessonModel> saveLesson(ClassesActor a, DailyLessonModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canWriteLessons, 'write daily lessons');
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == model.subjectId);
      final matchesTeacher = subject.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (subject.teacherId == 'tch-101' || subject.teacherId == 'tch-102'));
      _require(matchesTeacher, 'write lessons for a subject not assigned to you');
      if (!isNew) {
        final existing = _lessons.firstWhere((l) => l.id == model.id);
        final matchesExisting = existing.teacherId == a.userId ||
            (a.userId == 'USR-TEACH-01' && (existing.teacherId == 'tch-101' || existing.teacherId == 'tch-102'));
        _require(matchesExisting, 'edit another teacher\'s lesson');
      }
    }
    if (isNew) {
      final created = DailyLessonModel(
        id: _newId('les'),
        classId: model.classId,
        sectionId: model.sectionId,
        subjectId: model.subjectId,
        teacherId: a.permissions.isTeacher ? a.userId : model.teacherId,
        periodLabel: model.periodLabel,
        date: model.date,
        title: model.title,
        notes: model.notes,
        homework: model.homework,
        status: model.status,
      );
      _lessons = [..._lessons, created];
      await _persist();
      return created;
    }
    _lessons = [for (final l in _lessons) l.id == model.id ? model : l];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteLesson(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canWriteLessons, 'delete daily lessons');
    final existing = _lessons.firstWhere((l) => l.id == id);
    if (a.permissions.isTeacher) {
      final matchesExisting = existing.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (existing.teacherId == 'tch-101' || existing.teacherId == 'tch-102'));
      _require(matchesExisting, 'delete another teacher\'s lesson');
    }
    _lessons = _lessons.where((l) => l.id != id).toList();
    await _persist();
  }

  // ------------------------------------------------------------- timetable
  @override
  Future<TimetableEntryModel> saveTimetableEntry(
    ClassesActor a,
    TimetableEntryModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTimetable, 'manage timetable');
    if (model.startTime.compareTo(model.endTime) >= 0) {
      throw const ClassesDataException('End time must be after start time.');
    }
    bool overlaps(TimetableEntryModel t) =>
        t.id != model.id &&
        t.dayOfWeek == model.dayOfWeek &&
        t.startTime.compareTo(model.endTime) < 0 &&
        model.startTime.compareTo(t.endTime) < 0;
    for (final t in _timetable.where(overlaps)) {
      if (t.sectionId == model.sectionId) {
        throw const ClassesDataException('This section already has a period in that time slot.');
      }
      if (model.teacherId.isNotEmpty && t.teacherId == model.teacherId) {
        throw const ClassesDataException('That teacher is already teaching in that time slot.');
      }
      if (model.classroomId != null && t.classroomId == model.classroomId) {
        throw const ClassesDataException('That classroom is already in use in that time slot.');
      }
    }
    if (isNew) {
      final created = TimetableEntryModel(
        id: _newId('tt'),
        classId: model.classId,
        sectionId: model.sectionId,
        subjectId: model.subjectId,
        teacherId: model.teacherId,
        classroomId: model.classroomId,
        dayOfWeek: model.dayOfWeek,
        startTime: model.startTime,
        endTime: model.endTime,
        month: model.month,
      );
      _timetable = [..._timetable, created];
      await _persist();
      return created;
    }
    _timetable = [for (final t in _timetable) t.id == model.id ? model : t];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteTimetableEntry(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTimetable, 'delete timetable entries');
    _timetable = _timetable.where((t) => t.id != id).toList();
    await _persist();
  }

  // ------------------------------------------------------------ classrooms
  @override
  Future<ClassroomModel> saveClassroom(ClassesActor a, ClassroomModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClassrooms, 'manage classrooms');

    // Duplicate classroom prevention
    final isDuplicate = _classrooms.any((r) =>
        (isNew || r.id != model.id) &&
        r.name.trim().toLowerCase() == model.name.trim().toLowerCase());
    if (isDuplicate) {
      throw ClassesDataException('Classroom "${model.name}" already exists.');
    }

    if (isNew) {
      final created = ClassroomModel(
        id: _newId('room'),
        name: model.name,
        building: model.building,
        capacity: model.capacity,
      );
      _classrooms = [..._classrooms, created];
      await _persist();
      return created;
    }
    _classrooms = [for (final r in _classrooms) r.id == model.id ? model : r];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteClassroom(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClassrooms, 'delete classrooms');
    _classrooms = _classrooms.where((r) => r.id != id).toList();
    _classes = [for (final c in _classes) c.classroomId == id ? c.copyWith(clearClassroom: true) : c];
    _sections = [for (final s in _sections) s.classroomId == id ? s.copyWith(clearClassroom: true) : s];
    _timetable = [
      for (final t in _timetable)
        if (t.classroomId == id)
          TimetableEntryModel(
            id: t.id,
            classId: t.classId,
            sectionId: t.sectionId,
            subjectId: t.subjectId,
            teacherId: t.teacherId,
            classroomId: null,
            dayOfWeek: t.dayOfWeek,
            startTime: t.startTime,
            endTime: t.endTime,
          )
        else
          t,
    ];
    await _persist();
  }

  // ----------------------------------------------------------- teacher work
  @override
  Future<TeacherWorkModel> saveTeacherWork(ClassesActor a, TeacherWorkModel model, {bool isNew = false}) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTeacherWork, 'manage teacher work');
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == model.subjectId);
      final matchesTeacher = subject.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (subject.teacherId == 'tch-101' || subject.teacherId == 'tch-102'));
      _require(matchesTeacher, 'manage teacher work for a subject not assigned to you');
      if (!isNew) {
        final existing = _teacherWork.firstWhere((w) => w.id == model.id);
        final matchesExisting = existing.teacherId == a.userId ||
            (a.userId == 'USR-TEACH-01' && (existing.teacherId == 'tch-101' || existing.teacherId == 'tch-102'));
        _require(matchesExisting, 'edit another teacher\'s work');
      }
    }

    if (isNew) {
      final created = TeacherWorkModel(
        id: _newId('tw'),
        title: model.title,
        classId: model.classId,
        sectionId: model.sectionId,
        subjectId: model.subjectId,
        teacherId: a.permissions.isTeacher ? a.userId : model.teacherId,
        workType: model.workType,
        dueDate: model.dueDate,
        status: model.status,
        instructions: model.instructions,
        academicYear: model.academicYear,
      );
      _teacherWork = [..._teacherWork, created];
      await _persist();
      return created;
    }
    _teacherWork = [for (final w in _teacherWork) w.id == model.id ? model : w];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteTeacherWork(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTeacherWork, 'delete teacher work');
    final existing = _teacherWork.firstWhere((w) => w.id == id);
    if (a.permissions.isTeacher) {
      final matchesExisting = existing.teacherId == a.userId ||
          (a.userId == 'USR-TEACH-01' && (existing.teacherId == 'tch-101' || existing.teacherId == 'tch-102'));
      _require(matchesExisting, 'delete another teacher\'s work');
    }
    _teacherWork = _teacherWork.where((w) => w.id != id).toList();
    await _persist();
  }

  Map<String, dynamic> _buildInitialDefaultData() {
    return {
      "classes": [
        {"id": "cls-1", "name": "1st Class", "grade_level": 1, "academic_year": "2026-2027", "class_teacher_id": "tch-107", "classroom_id": "room-101"},
        {"id": "cls-2", "name": "2nd Class", "grade_level": 2, "academic_year": "2026-2027", "class_teacher_id": "tch-103", "classroom_id": "room-102"},
        {"id": "cls-3", "name": "3rd Class", "grade_level": 3, "academic_year": "2026-2027", "class_teacher_id": "tch-105", "classroom_id": "room-103"},
        {"id": "cls-4", "name": "4th Class", "grade_level": 4, "academic_year": "2026-2027", "class_teacher_id": "tch-108", "classroom_id": "room-104"},
        {"id": "cls-5", "name": "5th Class", "grade_level": 5, "academic_year": "2026-2027", "class_teacher_id": "tch-106", "classroom_id": "room-105"},
        {"id": "cls-6", "name": "6th Class", "grade_level": 6, "academic_year": "2026-2027", "class_teacher_id": "tch-104", "classroom_id": "room-201"},
        {"id": "cls-7", "name": "7th Class", "grade_level": 7, "academic_year": "2026-2027", "class_teacher_id": "tch-107", "classroom_id": "room-202"},
        {"id": "cls-8", "name": "8th Class", "grade_level": 8, "academic_year": "2026-2027", "class_teacher_id": "tch-103", "classroom_id": "room-203"},
        {"id": "cls-9", "name": "9th Class", "grade_level": 9, "academic_year": "2026-2027", "class_teacher_id": "tch-102", "classroom_id": "room-204"},
        {"id": "cls-10", "name": "10th Class", "grade_level": 10, "academic_year": "2026-2027", "class_teacher_id": "tch-101", "classroom_id": "room-205"}
      ],
      "sections": [
        {"id": "sec-10a", "class_id": "cls-10", "name": "A", "capacity": 40, "classroom_id": "room-205"},
        {"id": "sec-10b", "class_id": "cls-10", "name": "B", "capacity": 40, "classroom_id": "room-205"},
        {"id": "sec-9a", "class_id": "cls-9", "name": "A", "capacity": 40, "classroom_id": "room-204"}
      ],
      "subjects": [
        {"id": "sub-101", "class_id": "cls-10", "name": "Mathematics", "code": "MTH-101", "teacher_id": "tch-102"},
        {"id": "sub-102", "class_id": "cls-10", "name": "English", "code": "ENG-102", "teacher_id": "tch-103"}
      ],
      "curriculum": [],
      "daily_lessons": [],
      "timetable": [],
      "classrooms": [
        {"id": "room-101", "name": "Room 101", "building": "Primary Academic Wing", "capacity": 40},
        {"id": "room-205", "name": "Room 205", "building": "Secondary Academic Wing", "capacity": 42}
      ],
      "teacher_work": []
    };
  }
}
