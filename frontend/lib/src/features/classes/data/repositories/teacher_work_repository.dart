part of '../classes_repository.dart';

/// Teacher work: reads, writes and rules.
mixin _TeacherWorkRepository on _ClassesStore {
  @override
  Future<List<TeacherWorkModel>> getTeacherWork(ClassesActor a) async {
    await _ensureLoaded();
    _require(a.permissions.canViewTeacherWork, 'view teacher work');
    if (a.permissions.isAdmin) return List.of(_teacherWork);
    List<TeacherWorkModel> visible;
    if (a.permissions.isTeacher) {
      final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
      visible = _teacherWork
          .where(
            (work) =>
                subjectIds.contains(work.subjectId) &&
                _matchesTeacher(a.userId, work.teacherId),
          )
          .toList();
    } else if (a.permissions.isStudent || a.permissions.isParent) {
      if (!_hasVerifiedStudentScope(a) ||
          a.studentId == null ||
          a.studentId!.isEmpty ||
          a.studentClassId == null ||
          a.studentClassId!.isEmpty) {
        return const [];
      }
      visible = _teacherWork.where((work) {
        if (work.classId != a.studentClassId) return false;
        return work.sectionId == null ||
            work.sectionId!.isEmpty ||
            work.sectionId == a.studentSectionId;
      }).toList();
    } else {
      return const [];
    }
    return visible..sort((x, y) => x.dueDate.compareTo(y.dueDate));
  }

  // ----------------------------------------------------------- teacher work
  @override
  Future<TeacherWorkModel> saveTeacherWork(
    ClassesActor a,
    TeacherWorkModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTeacherWork, 'manage teacher work');
    final subject = _subjects.where((s) => s.id == model.subjectId).firstOrNull;
    if (subject == null) {
      throw const ClassesDataException('Selected subject no longer exists.');
    }
    _require(
      subject.classId == model.classId,
      'assign work outside the subject class',
    );
    if (a.permissions.isTeacher) {
      final matchesTeacher = _matchesTeacher(a.userId, subject.teacherId);
      _require(
        matchesTeacher,
        'manage teacher work for a subject not assigned to you',
      );
      if (!isNew) {
        final existing = _teacherWork.firstWhere((w) => w.id == model.id);
        final matchesExisting = _matchesTeacher(a.userId, existing.teacherId);
        _require(matchesExisting, 'edit another teacher\'s work');
      }
    }
    if (model.sectionId != null &&
        model.sectionId!.isNotEmpty &&
        !_sections.any(
          (section) =>
              section.id == model.sectionId && section.classId == model.classId,
        )) {
      throw const ClassesDataException(
        'Selected section is not in this class.',
      );
    }

    if (isNew) {
      final created = TeacherWorkModel(
        id: _newId('tw'),
        title: model.title,
        classId: model.classId,
        sectionId: model.sectionId,
        subjectId: model.subjectId,
        teacherId: a.permissions.isTeacher
            ? (subject.teacherId ?? a.userId)
            : model.teacherId,
        workType: model.workType,
        dueDate: model.dueDate,
        status: model.status,
        instructions: model.instructions,
        submissionGuidelines: model.submissionGuidelines,
        academicYear: model.academicYear,
      );
      _teacherWork = [..._teacherWork, created];
      await _persist();
      return created;
    }
    final existing = _teacherWork.where((w) => w.id == model.id).firstOrNull;
    if (existing == null) {
      throw const ClassesDataException('Assignment no longer exists.');
    }
    final updated = TeacherWorkModel(
      id: existing.id,
      title: model.title,
      classId: model.classId,
      sectionId: model.sectionId,
      subjectId: model.subjectId,
      teacherId: a.permissions.isTeacher
          ? (subject.teacherId ?? a.userId)
          : model.teacherId,
      workType: model.workType,
      dueDate: model.dueDate,
      status: model.status,
      instructions: model.instructions,
      submissionGuidelines: model.submissionGuidelines,
      academicYear: model.academicYear,
    );
    _teacherWork = [
      for (final w in _teacherWork) w.id == model.id ? updated : w,
    ];
    await _persist();
    return updated;
  }

  @override
  Future<void> deleteTeacherWork(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canDeleteTeacherWork, 'delete teacher work');
    final existing = _teacherWork.firstWhere((w) => w.id == id);
    if (a.permissions.isTeacher) {
      final matchesExisting = _matchesTeacher(a.userId, existing.teacherId);
      _require(matchesExisting, 'delete another teacher\'s work');
    }
    _teacherWork = _teacherWork.where((w) => w.id != id).toList();
    await _persist();
  }
}
