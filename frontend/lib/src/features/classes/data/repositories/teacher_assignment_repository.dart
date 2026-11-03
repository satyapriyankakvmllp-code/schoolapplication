part of '../classes_repository.dart';

/// Teacher assignments: reads, writes and rules.
mixin _TeacherAssignmentRepository on _ClassesStore {
  @override
  Future<List<ClassTeacherAssignmentModel>> getTeacherAssignments(
    ClassesActor a,
  ) async {
    await _ensureLoaded();
    _require(a.permissions.canViewTeacherWork, 'view teacher assignments');
    final ids = await _visibleClassIds(a);
    var visible = _teacherAssignments.where((t) => ids.contains(t.classId));
    if (a.permissions.isTeacher) {
      visible = visible.where((t) => _matchesTeacher(a.userId, t.teacherId));
    } else if (a.permissions.isStudent || a.permissions.isParent) {
      if (a.studentSectionId == null || a.studentSectionId!.isEmpty) {
        return const [];
      }
      visible = visible.where((t) => t.sectionId == a.studentSectionId);
    }
    return visible.toList();
  }

  /// Places a Staff Directory teacher on a class / section / subject / room.
  /// Also sets the subject's teacher so existing screens and counts stay consistent.
  @override
  Future<ClassTeacherAssignmentModel> saveTeacherAssignment(
    ClassesActor a,
    ClassTeacherAssignmentModel model,
  ) async {
    await _ensureLoaded();
    _require(a.permissions.canAssignTeachers, 'assign teachers');
    if (!_classes.any((c) => c.id == model.classId)) {
      throw const ClassesDataException('Selected class no longer exists.');
    }
    if (model.teacherId.isEmpty)
      throw const ClassesDataException('Please select a teacher.');
    final exists = _teacherAssignments.any(
      (t) =>
          t.classId == model.classId &&
          t.sectionId == model.sectionId &&
          t.subjectId == model.subjectId &&
          t.teacherId == model.teacherId,
    );
    if (exists)
      throw const ClassesDataException(
        'This teacher is already assigned to that class, section and subject.',
      );
    final created = ClassTeacherAssignmentModel(
      id: _newId('cta'),
      classId: model.classId,
      sectionId: model.sectionId,
      subjectId: model.subjectId,
      teacherId: model.teacherId,
      classroomId: model.classroomId,
    );
    _teacherAssignments = [..._teacherAssignments, created];
    if (model.subjectId != null) {
      _subjects = [
        for (final s in _subjects)
          s.id == model.subjectId ? s.copyWith(teacherId: model.teacherId) : s,
      ];
    }
    await _persist();
    return created;
  }

  @override
  Future<void> deleteTeacherAssignment(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canAssignTeachers, 'delete teacher assignment');
    final removed = _teacherAssignments.where((t) => t.id == id).firstOrNull;
    _teacherAssignments = _teacherAssignments.where((t) => t.id != id).toList();
    if (removed != null && removed.subjectId != null) {
      final other = _teacherAssignments
          .where((t) => t.subjectId == removed.subjectId)
          .firstOrNull;
      if (other == null) {
        _subjects = [
          for (final s in _subjects)
            s.id == removed.subjectId ? s.copyWith(clearTeacher: true) : s,
        ];
      }
    }
    await _persist();
  }
}
