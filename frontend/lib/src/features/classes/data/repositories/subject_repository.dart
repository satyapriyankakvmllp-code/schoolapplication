part of '../classes_repository.dart';

/// Subjects: reads, writes and rules.
mixin _SubjectRepository on _ClassesStore {
  @override
  Future<List<SubjectModel>> getSubjects(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    final classSubjects = [
      ..._subjects.where((s) => ids.contains(s.classId)),
      ..._getAllocatedGlobalSubjects(ids),
    ];
    final seenSubjectNames = <String>{};
    var list = classSubjects.where((subject) {
      final key = '${subject.classId}:${subject.name.trim().toLowerCase()}';
      return seenSubjectNames.add(key);
    });
    if (a.permissions.isTeacher) {
      final assignedSubjectIds = {
        for (final assignment in _teacherAssignments)
          if (_matchesTeacher(a.userId, assignment.teacherId) &&
              assignment.subjectId != null)
            assignment.subjectId!,
      };
      list = list.where(
        (s) =>
            _matchesTeacher(a.userId, s.teacherId) ||
            assignedSubjectIds.contains(s.id),
      );
    }
    return list.toList();
  }

  List<SubjectModel> _getAllocatedGlobalSubjects(Set<String> visibleClassIds) {
    final masterSubjects = {
      for (final value
          in (_globalJson['subjects'] as List<dynamic>? ?? const []))
        if (value is Map<String, dynamic> &&
            value['id'] is String &&
            value['is_active'] != false)
          value['id'] as String: value,
    };
    final classSections = {
      for (final value
          in (_globalJson['class_sections'] as List<dynamic>? ?? const []))
        if (value is Map<String, dynamic> && value['id'] is String)
          value['id'] as String: value,
    };
    final subjectsByClass = <String, SubjectModel>{};

    int? gradeFrom(String? name) {
      final match = RegExp(r'\d+').firstMatch(name ?? '');
      return match == null ? null : int.tryParse(match.group(0)!);
    }

    for (final value
        in (_globalJson['class_subject_allocations'] as List<dynamic>? ??
            const [])) {
      if (value is! Map<String, dynamic> || value['is_active'] == false) {
        continue;
      }
      final section = classSections[value['class_section_id']];
      final globalSubject = masterSubjects[value['subject_id']];
      if (section == null || globalSubject == null) continue;

      final globalGrade = gradeFrom(section['class_name'] as String?);
      if (globalGrade == null) continue;
      final matchedClasses = _classes.where(
        (classModel) =>
            visibleClassIds.contains(classModel.id) &&
            (classModel.gradeLevel == globalGrade ||
                gradeFrom(classModel.name) == globalGrade),
      );
      for (final classModel in matchedClasses) {
        final subjectId = globalSubject['id'] as String;
        final subjectName = (globalSubject['subject_name'] as String? ?? '')
            .trim();
        if (subjectName.isEmpty) continue;
        final key = '${classModel.id}:$subjectId';
        subjectsByClass.putIfAbsent(
          key,
          () => SubjectModel(
            id: 'global-${classModel.id}-$subjectId',
            classId: classModel.id,
            name: subjectName,
            code: globalSubject['subject_code'] as String? ?? '',
            type: globalSubject['is_practical'] == true
                ? 'Practical'
                : 'Theory',
          ),
        );
      }
    }
    return subjectsByClass.values.toList();
  }

  // -------------------------------------------------------------- subjects
  @override
  Future<SubjectModel> saveSubject(
    ClassesActor a,
    SubjectModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSubjects, 'manage subjects');
    if (isNew) {
      final created = SubjectModel(
        id: _newId('sub'),
        classId: model.classId,
        name: model.name,
        code: model.code,
        type: model.type,
        syllabus: model.syllabus,
        teacherId: model.teacherId,
        maxMarks: model.maxMarks,
        passMarks: model.passMarks,
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
  Future<SubjectModel> assignSubjectTeacher(
    ClassesActor a,
    String subjectId,
    String? teacherId,
  ) async {
    await _ensureLoaded();
    _require(a.permissions.canAssignTeachers, 'assign subject teachers');
    final current = _subjects.firstWhere((s) => s.id == subjectId);
    final next = current.copyWith(
      teacherId: teacherId,
      clearTeacher: teacherId == null,
    );
    _subjects = [for (final s in _subjects) s.id == subjectId ? next : s];
    await _persist();
    return next;
  }
}
