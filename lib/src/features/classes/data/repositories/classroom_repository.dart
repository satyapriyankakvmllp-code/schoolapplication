part of '../classes_repository.dart';

/// Classrooms: reads, writes and rules.
mixin _ClassroomRepository on _ClassesStore {
  @override
  Future<List<ClassroomModel>> getClassrooms(ClassesActor a) async {
    await _ensureLoaded();
    _require(a.permissions.canAccessClasses, 'view classrooms');
    if (a.permissions.isAdmin) return List.of(_classrooms);
    final classIds = await _visibleClassIds(a);
    final used = <String>{
      for (final c in _classes)
        if (classIds.contains(c.id) && c.classroomId != null) c.classroomId!,
      for (final s in await getSections(a))
        if (s.classroomId != null) s.classroomId!,
      for (final t in await getTimetable(a))
        if (t.classroomId != null) t.classroomId!,
    };
    return _classrooms.where((r) => used.contains(r.id)).toList();
  }

  // ------------------------------------------------------------ classrooms
  @override
  Future<ClassroomModel> saveClassroom(
    ClassesActor a,
    ClassroomModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClassrooms, 'manage classrooms');

    // Duplicate classroom prevention
    final isDuplicate = _classrooms.any(
      (r) =>
          (isNew || r.id != model.id) &&
          r.normalizedNumber == model.normalizedNumber,
    );
    if (isDuplicate) {
      throw ClassesDataException(
        'Room number "${model.name}" already exists. Use a different room number.',
      );
    }
    if (!isNew &&
        !model.isAvailable &&
        _classesHoldingRoom(model.id).isNotEmpty) {
      throw ClassesDataException(
        '${model.name} is assigned to a class/section. Unassign it before marking Unavailable.',
      );
    }

    if (isNew) {
      final created = ClassroomModel(
        id: _newId('room'),
        name: model.name,
        building: model.building,
        capacity: model.capacity,
        floor: model.floor,
        roomType: model.roomType,
        status: model.status,
      );
      _classrooms = [..._classrooms, created];
      _syncClassroomAssignmentStatuses();
      await _persist();
      return _classrooms.firstWhere((room) => room.id == created.id);
    }
    _classrooms = [
      for (final room in _classrooms)
        room.id == model.id
            ? model.copyWith(
                status: !model.isAvailable
                    ? 'Unavailable'
                    : (_classesHoldingRoom(model.id).isEmpty
                          ? 'Unassigned'
                          : 'Assigned'),
              )
            : room,
    ];
    _syncClassroomAssignmentStatuses();
    await _persist();
    return _classrooms.firstWhere((room) => room.id == model.id);
  }

  @override
  Future<void> deleteClassroom(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClassrooms, 'delete classrooms');
    _classrooms = _classrooms.where((r) => r.id != id).toList();
    _classes = [
      for (final c in _classes)
        c.classroomId == id ? c.copyWith(clearClassroom: true) : c,
    ];
    _sections = [
      for (final s in _sections)
        s.classroomId == id ? s.copyWith(clearClassroom: true) : s,
    ];
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
            isBreak: t.isBreak,
            title: t.title,
            dayOfWeek: t.dayOfWeek,
            startTime: t.startTime,
            endTime: t.endTime,
            month: t.month,
          )
        else
          t,
    ];
    await _persist();
  }
}
