import 'dart:convert';
import '../../../utils/asset_loader.dart';
import '../../../utils/dynamic_data_client.dart';
import '../domain/class_model.dart';
import '../domain/class_teacher_assignment_model.dart';
import '../domain/classes_actor.dart';
import '../domain/classroom_model.dart';
import '../domain/curriculum_model.dart';
import '../domain/daily_lesson_model.dart';
import '../domain/section_model.dart';
import '../domain/subject_model.dart';
import '../domain/teacher_work_model.dart';
import '../domain/timetable_entry_model.dart';

part 'repositories/class_repository.dart';
part 'repositories/section_repository.dart';
part 'repositories/subject_repository.dart';
part 'repositories/curriculum_repository.dart';
part 'repositories/daily_lesson_repository.dart';
part 'repositories/timetable_repository.dart';
part 'repositories/classroom_repository.dart';
part 'repositories/teacher_work_repository.dart';
part 'repositories/teacher_assignment_repository.dart';

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
  Future<List<Map<String, dynamic>>> getClassFieldDefinitions(ClassesActor a);
  Future<void> saveClassFieldDefinition(ClassesActor a, String name);
  Future<List<SectionModel>> getSections(ClassesActor a);
  Future<List<SubjectModel>> getSubjects(ClassesActor a);
  Future<List<CurriculumModel>> getCurriculum(ClassesActor a);
  Future<List<DailyLessonModel>> getLessons(ClassesActor a);
  Future<List<TimetableEntryModel>> getTimetable(ClassesActor a);
  Future<List<ClassroomModel>> getClassrooms(ClassesActor a);
  Future<List<TeacherWorkModel>> getTeacherWork(ClassesActor a);
  Future<List<ClassTeacherAssignmentModel>> getTeacherAssignments(
    ClassesActor a,
  );
  Future<ClassTeacherAssignmentModel> saveTeacherAssignment(
    ClassesActor a,
    ClassTeacherAssignmentModel model,
  );
  Future<void> deleteTeacherAssignment(ClassesActor a, String id);
  Future<ClassModel> saveClass(
    ClassesActor a,
    ClassModel model, {
    bool isNew = false,
  });
  Future<void> deleteClass(ClassesActor a, String id);
  Future<ClassModel> assignClassTeacher(
    ClassesActor a,
    String classId,
    String? teacherId,
  );
  Future<SectionModel> saveSection(
    ClassesActor a,
    SectionModel model, {
    bool isNew = false,
  });
  Future<void> deleteSection(ClassesActor a, String id);
  Future<SubjectModel> saveSubject(
    ClassesActor a,
    SubjectModel model, {
    bool isNew = false,
  });
  Future<void> deleteSubject(ClassesActor a, String id);
  Future<SubjectModel> assignSubjectTeacher(
    ClassesActor a,
    String subjectId,
    String? teacherId,
  );
  Future<CurriculumModel> saveCurriculum(
    ClassesActor a,
    CurriculumModel model, {
    bool isNew = false,
  });
  Future<void> deleteCurriculum(ClassesActor a, String id);
  Future<CurriculumModel> updateProgress(
    ClassesActor a,
    String curriculumId,
    int completedTopics,
  );
  Future<DailyLessonModel> saveLesson(
    ClassesActor a,
    DailyLessonModel model, {
    bool isNew = false,
  });
  Future<void> deleteLesson(ClassesActor a, String id);
  Future<TimetableEntryModel> saveTimetableEntry(
    ClassesActor a,
    TimetableEntryModel model, {
    bool isNew = false,
  });
  Future<void> deleteTimetableEntry(ClassesActor a, String id);
  Future<ClassroomModel> saveClassroom(
    ClassesActor a,
    ClassroomModel model, {
    bool isNew = false,
  });
  Future<void> deleteClassroom(ClassesActor a, String id);
  Future<TeacherWorkModel> saveTeacherWork(
    ClassesActor a,
    TeacherWorkModel model, {
    bool isNew = false,
  });
  Future<void> deleteTeacherWork(ClassesActor a, String id);
}

/// Shared state, loading/saving and helper rules used by every entity file in
/// `repositories/`. The per-entity logic lives in those files as mixins.
abstract class _ClassesStore implements ClassesRepository {
  static const String assetPath = 'assets/data/global_school_database.json';
  static const String legacyAssetPath = 'assets/data/classes/classes.json';
  static const String prefsKey = 'edupulse_saved_global_school_database';
  static const String legacyPrefsKey = 'edupulse_saved_classes_records';

  final AssetLoader _loader;
  final DynamicDataClient _dataClient;
  Future<void>? _loading;

  List<ClassModel> _classes = [];
  List<SectionModel> _sections = [];
  List<SubjectModel> _subjects = [];
  List<CurriculumModel> _curriculum = [];
  List<DailyLessonModel> _lessons = [];
  List<TimetableEntryModel> _timetable = [];
  List<ClassroomModel> _classrooms = [];
  List<TeacherWorkModel> _teacherWork = [];
  List<ClassTeacherAssignmentModel> _teacherAssignments = [];
  Map<String, dynamic> _globalJson = {};
  List<Map<String, dynamic>> _classFieldDefinitions = [];
  int _seq = 0;

  _ClassesStore({AssetLoader? loader, DynamicDataClient? dataClient})
    : _loader = loader ?? const AssetLoader(),
      _dataClient = dataClient ?? DynamicDataClient.instance;

  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    _globalJson =
        await _dataClient.getJsonObject(
          assetPath: assetPath,
          storageKey: prefsKey,
        ) ??
        await _loader.loadJsonObject(assetPath, delayMs: 0);

    var needsMigration = false;
    if (_globalJson['academic_classes'] is! List) {
      final legacyJson =
          await _dataClient.getJsonObject(
            assetPath: legacyAssetPath,
            storageKey: legacyPrefsKey,
          ) ??
          await _loader.loadJsonObject(legacyAssetPath, delayMs: 0);
      _globalJson.addAll({
        'academic_classes': legacyJson['classes'] ?? const [],
        'academic_sections': legacyJson['sections'] ?? const [],
        'academic_subjects': legacyJson['subjects'] ?? const [],
        'academic_curriculum': const [],
        'academic_daily_lessons': const [],
        'academic_timetable': legacyJson['timetable'] ?? const [],
        'academic_classrooms': legacyJson['classrooms'] ?? const [],
        'academic_teacher_work': legacyJson['teacher_work'] ?? const [],
        'academic_teacher_assignments':
            legacyJson['class_teachers'] ?? const [],
        'academic_class_field_definitions': const [],
      });
      needsMigration = true;
    }
    _globalJson.putIfAbsent('academic_sections', () => const []);
    _globalJson.putIfAbsent('academic_subjects', () => const []);
    _globalJson.putIfAbsent('academic_curriculum', () => const []);
    _globalJson.putIfAbsent('academic_daily_lessons', () => const []);
    _globalJson.putIfAbsent('academic_timetable', () => const []);
    _globalJson.putIfAbsent('academic_classrooms', () => const []);
    _globalJson.putIfAbsent('academic_teacher_work', () => const []);
    _globalJson.putIfAbsent('academic_teacher_assignments', () => const []);
    _globalJson.putIfAbsent('academic_class_field_definitions', () => const []);

    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        (_globalJson[key] as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    _classes = parse('academic_classes', ClassModel.fromJson);
    _sections = parse('academic_sections', SectionModel.fromJson);
    _subjects = parse('academic_subjects', SubjectModel.fromJson);
    _curriculum = parse('academic_curriculum', CurriculumModel.fromJson);
    _lessons = parse('academic_daily_lessons', DailyLessonModel.fromJson);
    _timetable = parse('academic_timetable', TimetableEntryModel.fromJson);
    _classrooms = parse('academic_classrooms', ClassroomModel.fromJson);
    _teacherWork = parse('academic_teacher_work', TeacherWorkModel.fromJson);
    _teacherAssignments = parse(
      'academic_teacher_assignments',
      ClassTeacherAssignmentModel.fromJson,
    );
    _classFieldDefinitions =
        (_globalJson['academic_class_field_definitions'] as List<dynamic>? ??
                const [])
            .whereType<Map<String, dynamic>>()
            .map(Map<String, dynamic>.from)
            .toList();
    if (needsMigration) await _persist();
  }

  Future<void> _persist() async {
    _globalJson.addAll({
      'classes': _classes.map((c) => c.toJson()).toList(),
      'sections': _sections.map((s) => s.toJson()).toList(),
      'academic_classes': _classes.map((c) => c.toJson()).toList(),
      'academic_sections': _sections.map((s) => s.toJson()).toList(),
      'academic_subjects': _subjects.map((s) => s.toJson()).toList(),
      'academic_curriculum': _curriculum.map((c) => c.toJson()).toList(),
      'academic_daily_lessons': _lessons.map((l) => l.toJson()).toList(),
      'academic_timetable': _timetable.map((t) => t.toJson()).toList(),
      'academic_classrooms': _classrooms.map((r) => r.toJson()).toList(),
      'academic_teacher_work': _teacherWork.map((w) => w.toJson()).toList(),
      'academic_teacher_assignments': _teacherAssignments
          .map((t) => t.toJson())
          .toList(),
      'academic_class_field_definitions': _classFieldDefinitions,
    });
    await _dataClient.syncJsonObject(
      assetPath: assetPath,
      storageKey: prefsKey,
      data: _globalJson,
    );
  }

  /// Export current JSON data as a formatted string
  @override
  String exportJsonString() {
    final payload = Map<String, dynamic>.from(_globalJson);
    payload.addAll({
      'classes': _classes.map((c) => c.toJson()).toList(),
      'sections': _sections.map((s) => s.toJson()).toList(),
      'academic_classes': _classes.map((c) => c.toJson()).toList(),
      'academic_sections': _sections.map((s) => s.toJson()).toList(),
      'academic_subjects': _subjects.map((s) => s.toJson()).toList(),
      'academic_curriculum': _curriculum.map((c) => c.toJson()).toList(),
      'academic_daily_lessons': _lessons.map((l) => l.toJson()).toList(),
      'academic_timetable': _timetable.map((t) => t.toJson()).toList(),
      'academic_classrooms': _classrooms.map((r) => r.toJson()).toList(),
      'academic_teacher_work': _teacherWork.map((w) => w.toJson()).toList(),
      'academic_teacher_assignments': _teacherAssignments
          .map((t) => t.toJson())
          .toList(),
      'academic_class_field_definitions': _classFieldDefinitions,
    });
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  void _require(bool allowed, String what) {
    if (!allowed) throw ClassesPermissionException('Not permitted: $what');
  }

  bool _matchesTeacher(String teacherId, String? id) {
    if (id == null || id.isEmpty) return false;
    const aliases = {
      'USR-TEACH-01': {'USR-TEACH-01', 'tch-101', 'STF-2026-0111'},
      'tch-101': {'USR-TEACH-01', 'tch-101', 'STF-2026-0111'},
      'STF-2026-0111': {'USR-TEACH-01', 'tch-101', 'STF-2026-0111'},
      'tch-102': {'tch-102', 'STF-2026-0112'},
      'STF-2026-0112': {'tch-102', 'STF-2026-0112'},
    };
    return aliases[teacherId]?.contains(id) ?? teacherId == id;
  }

  Set<String> _teacherClassIds(String teacherId) {
    return {
      for (final c in _classes)
        if (_matchesTeacher(teacherId, c.classTeacherId)) c.id,
      for (final s in _sections)
        if (_matchesTeacher(teacherId, s.classTeacherId)) s.classId,
      for (final s in _subjects)
        if (_matchesTeacher(teacherId, s.teacherId)) s.classId,
      for (final t in _timetable)
        if (_matchesTeacher(teacherId, t.teacherId)) t.classId,
      for (final t in _teacherAssignments)
        if (_matchesTeacher(teacherId, t.teacherId)) t.classId,
    };
  }

  bool _studentClassMatches(ClassModel c, ClassesActor a) {
    return _hasVerifiedStudentScope(a) &&
        (a.permissions.isStudent || a.permissions.isParent) &&
        a.studentId != null &&
        a.studentId!.isNotEmpty &&
        a.studentClassId != null &&
        a.studentClassId!.isNotEmpty &&
        c.id == a.studentClassId;
  }

  bool _hasVerifiedStudentScope(ClassesActor a) {
    if (a.permissions.isStudent) {
      return a.studentUserId != null && a.studentUserId == a.userId;
    }
    if (a.permissions.isParent) {
      return a.linkedParentUserId != null && a.linkedParentUserId == a.userId;
    }
    return false;
  }

  Future<Set<String>> _visibleClassIds(ClassesActor a) async =>
      (await getClasses(a)).map((c) => c.id).toSet();

  // ------------------------------------------------- classroom assignment rules
  /// Class ids that currently "hold" [roomId]: a class that has it as its classroom,
  /// or the class of any section using it. Sections of the SAME class may share a room.
  Set<String> _classesHoldingRoom(String roomId, {String? ignoreClassId}) {
    final holders = <String>{
      for (final c in _classes)
        if (c.classroomId == roomId) c.id,
      for (final s in _sections)
        if (s.classroomId == roomId) s.classId,
    };
    if (ignoreClassId != null) holders.remove(ignoreClassId);
    return holders;
  }

  void _syncClassroomAssignmentStatuses() {
    _classrooms = [
      for (final room in _classrooms)
        if (room.status.toLowerCase() == 'unavailable' ||
            room.status.toLowerCase() == 'not available')
          room
        else
          room.copyWith(
            status: _classesHoldingRoom(room.id).isEmpty
                ? 'Unassigned'
                : 'Assigned',
          ),
    ];
  }

  /// Throws a clear message when [roomId] cannot be assigned to [classId].
  /// Only called when the assignment actually changes, so legacy data stays editable.
  void _checkRoomAssignable(String? roomId, String classId) {
    if (roomId == null || roomId.isEmpty) return;
    final room = _classrooms.where((r) => r.id == roomId).firstOrNull;
    if (room == null)
      throw const ClassesDataException('Selected classroom no longer exists.');
    if (!room.isAvailable) {
      throw ClassesDataException(
        '${room.name} is marked Unavailable and cannot be assigned.',
      );
    }
    final others = _classesHoldingRoom(roomId, ignoreClassId: classId);
    if (others.isNotEmpty) {
      final names = [
        for (final id in others)
          _classes.where((c) => c.id == id).firstOrNull?.name ?? id,
      ].join(', ');
      throw ClassesDataException(
        '${room.name} is already assigned to $names. Choose another room (e.g. 201 or 202).',
      );
    }
  }
}

/// JSON-backed repository with in-memory caching. Academic module data is stored
/// in namespaced keys in the global school database JSON.
///
/// Every mutation re-checks the actor's permissions here, ensuring robust
/// role-based authorization at the data boundary.
class MockClassesRepository extends _ClassesStore
    with
        _ClassRepository,
        _SectionRepository,
        _SubjectRepository,
        _CurriculumRepository,
        _DailyLessonRepository,
        _TimetableRepository,
        _ClassroomRepository,
        _TeacherWorkRepository,
        _TeacherAssignmentRepository {
  static const String assetPath = _ClassesStore.assetPath;
  static const String legacyAssetPath = _ClassesStore.legacyAssetPath;
  static const String prefsKey = _ClassesStore.prefsKey;
  static const String legacyPrefsKey = _ClassesStore.legacyPrefsKey;

  MockClassesRepository({super.loader, super.dataClient});
}
