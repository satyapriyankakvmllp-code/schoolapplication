part of '../classes_repository.dart';

/// Sections: reads, writes and rules.
mixin _SectionRepository on _ClassesStore {
  @override
  Future<List<SectionModel>> getSections(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    var list = _sections.where((s) => ids.contains(s.classId));
    if (a.permissions.isStudent || a.permissions.isParent) {
      if (a.studentSectionId != null && a.studentSectionId!.isNotEmpty) {
        list = list.where((s) => s.id == a.studentSectionId);
      } else if (a.permissions.isStudent && a.studentSection != null) {
        list = list.where(
          (s) => s.name.toUpperCase() == a.studentSection!.toUpperCase(),
        );
      } else {
        return const [];
      }
    }
    return list.toList();
  }

  // -------------------------------------------------------------- sections
  @override
  Future<SectionModel> saveSection(
    ClassesActor a,
    SectionModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageSections, 'manage sections');

    // Duplicate section prevention for the same class
    final isDuplicate = _sections.any(
      (s) =>
          (isNew || s.id != model.id) &&
          s.classId == model.classId &&
          s.name.trim().toLowerCase() == model.name.trim().toLowerCase(),
    );
    if (isDuplicate) {
      throw ClassesDataException(
        'Section "${model.name}" already exists for this class.',
      );
    }
    final prevSection = isNew
        ? null
        : _sections.where((x) => x.id == model.id).firstOrNull;
    if (model.classroomId != prevSection?.classroomId) {
      _checkRoomAssignable(model.classroomId, model.classId);
      // Each section of a class needs its own room.
      final rid = model.classroomId;
      if (rid != null && rid.isNotEmpty) {
        final clash = _sections
            .where(
              (s) =>
                  s.id != model.id &&
                  s.classId == model.classId &&
                  s.classroomId == rid,
            )
            .firstOrNull;
        if (clash != null) {
          throw ClassesDataException(
            'Room is already used by Section ${clash.name} of this class. Choose a different room.',
          );
        }
      }
    }

    // Section names are stored upper-case so "a" and "A" behave identically.
    model = model.copyWith(name: model.name.trim().toUpperCase());

    if (isNew) {
      final created = SectionModel(
        id: _newId('sec'),
        classId: model.classId,
        name: model.name,
        capacity: model.capacity,
        classroomId: model.classroomId,
        classTeacherId: model.classTeacherId,
        status: model.status.isNotEmpty ? model.status : 'Active',
      );
      _sections = [..._sections, created];
      _syncClassroomAssignmentStatuses();
      await _persist();
      return created;
    }
    _sections = [for (final s in _sections) s.id == model.id ? model : s];
    _syncClassroomAssignmentStatuses();
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
    _teacherAssignments = _teacherAssignments
        .where((t) => t.sectionId != id)
        .toList();
    _syncClassroomAssignmentStatuses();
    await _persist();
  }
}
