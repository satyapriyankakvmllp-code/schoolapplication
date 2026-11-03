import 'package:flutter/foundation.dart';
import '../../../utils/dynamic_data_client.dart';
import '../domain/exam_master_data.dart';

/// Reads classes, sections, subjects, rooms, teachers, students and syllabus
/// chapters from the live stores of the Classes, Staff and Admissions modules.
class ExamMasterRepository {
  static const String _globalAsset = 'assets/data/global_school_database.json';
  static const String _globalKey = 'edupulse_saved_global_school_database';
  static const String _legacyAsset = 'assets/data/classes/classes.json';
  static const String _legacyKey = 'edupulse_saved_classes_records';
  static const String _admissionsAsset = 'assets/data/admissions/admissions.json';
  static const String _admissionsKey = 'edupulse_saved_enrolled_admissions';
  static const String _staffAsset = 'assets/data/staff/staff.json';
  static const String _staffKey = 'edupulse_saved_staff_records';

  final DynamicDataClient _client;

  ExamMasterRepository({DynamicDataClient? client})
      : _client = client ?? DynamicDataClient.instance;

  List<Map<String, dynamic>> _maps(dynamic v) {
    if (v is! List) return <Map<String, dynamic>>[];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _s(dynamic v, [String f = '']) {
    final s = v?.toString();
    return (s == null || s == 'null') ? f : s;
  }

  double _d(dynamic v, double f) =>
      (v is num) ? v.toDouble() : (double.tryParse(_s(v)) ?? f);

  /// [extraChapters] are syllabus chapters kept in examination.json
  /// (`syllabus_topics`). They are added to the Classes curriculum chapters.
  Future<ExamMasterData> load({List<Map<String, dynamic>> extraChapters = const []}) async {
    Map<String, dynamic> academic = {};
    try {
      final g = await _client.getJsonObject(
        assetPath: _globalAsset,
        storageKey: _globalKey,
      );
      if (g != null && g['academic_classes'] is List) {
        academic = {
          'classes': g['academic_classes'],
          'sections': g['academic_sections'],
          'subjects': g['academic_subjects'],
          'classrooms': g['academic_classrooms'],
          'curriculum': g['academic_curriculum'],
        };
      }
    } catch (e) {
      debugPrint('[ExamMasterRepository] global db read note: $e');
    }
    if (academic.isEmpty) {
      try {
        final legacy = await _client.getJsonObject(
          assetPath: _legacyAsset,
          storageKey: _legacyKey,
        );
        if (legacy != null) {
          academic = {
            'classes': legacy['classes'],
            'sections': legacy['sections'],
            'subjects': legacy['subjects'],
            'classrooms': legacy['classrooms'],
            'curriculum': legacy['curriculum'],
          };
        }
      } catch (e) {
        debugPrint('[ExamMasterRepository] classes read note: $e');
      }
    }

    final classes = _maps(academic['classes'])
        .map((m) => ExamClassInfo(id: _s(m['id']), name: _s(m['name'], _s(m['id']))))
        .toList();

    final sections = _maps(academic['sections'])
        .map((m) => ExamSectionInfo(
              id: _s(m['id']),
              classId: _s(m['class_id']),
              name: _s(m['name']),
              classroomId: m['classroom_id']?.toString(),
              classTeacherId: m['class_teacher_id']?.toString(),
            ))
        .toList();

    final subjects = _maps(academic['subjects'])
        .map((m) => ExamSubjectInfo(
              id: _s(m['id']),
              classId: _s(m['class_id']),
              name: _s(m['name'], _s(m['id'])),
              code: _s(m['code']),
              teacherId: m['teacher_id']?.toString(),
              maxMarks: _d(m['max_marks'], 100),
              passMarks: _d(m['pass_marks'], 35),
            ))
        .toList();

    final rooms = _maps(academic['classrooms'])
        .map((m) => ExamRoomInfo(
              id: _s(m['id']),
              name: _s(m['name'], _s(m['id'])),
              capacity: (m['capacity'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    final chapters = _maps(academic['curriculum'])
        .map((m) => ExamChapterInfo(
              id: _s(m['id']),
              classId: _s(m['class_id']),
              subjectId: _s(m['subject_id']),
              title: _s(m['title'], _s(m['id'])),
            ))
        .toList();

    final knownChapterIds = chapters.map((c) => c.id).toSet();
    for (final m in extraChapters) {
      final id = _s(m['topic_id']);
      if (id.isEmpty || knownChapterIds.contains(id)) continue;
      chapters.add(ExamChapterInfo(
        id: id,
        classId: _s(m['class_id']),
        subjectId: _s(m['subject_id']),
        title: _s(m['chapter_name'], id),
      ));
    }

    var teachers = <ExamTeacherInfo>[];
    try {
      final staff = await _client.getAll(
        assetPath: _staffAsset,
        storageKey: _staffKey,
      );
      teachers = staff
          .where((m) => _s(m['category']).toLowerCase() == 'teaching')
          .map((m) => ExamTeacherInfo(
                id: _s(m['id']),
                name: _s(m['fullName'], _s(m['id'])),
                department: _s(m['department']),
              ))
          .toList();
    } catch (e) {
      debugPrint('[ExamMasterRepository] staff read note: $e');
    }

    var students = <ExamStudentInfo>[];
    try {
      final admissions = await _client.getAll(
        assetPath: _admissionsAsset,
        storageKey: _admissionsKey,
      );
      students = admissions.map((m) {
        final user = m['user'] is Map
            ? Map<String, dynamic>.from(m['user'] as Map)
            : <String, dynamic>{};
        final st = m['student'] is Map
            ? Map<String, dynamic>.from(m['student'] as Map)
            : <String, dynamic>{};
        final first = _s(user['first_name']);
        final last = _s(user['last_name']);
        return ExamStudentInfo(
          id: _s(st['id']),
          name: ('$first $last').trim().isEmpty ? _s(st['id']) : '$first $last'.trim(),
          rollNumber: _s(st['roll_number']),
          classId: _s(st['current_class_id']),
          sectionId: _s(st['section_id']),
          enrolled: _s(st['enrollment_status'], 'ENROLLED').toUpperCase() == 'ENROLLED',
        );
      }).where((s) => s.id.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[ExamMasterRepository] admissions read note: $e');
    }

    return ExamMasterData(
      classes: classes,
      sections: sections,
      subjects: subjects,
      rooms: rooms,
      teachers: teachers,
      students: students,
      chapters: chapters,
    );
  }
}
