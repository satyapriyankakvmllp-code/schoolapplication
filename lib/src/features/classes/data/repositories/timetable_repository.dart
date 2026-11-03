part of '../classes_repository.dart';

/// Timetable: reads, writes and rules.
mixin _TimetableRepository on _ClassesStore {
  @override
  Future<List<TimetableEntryModel>> getTimetable(ClassesActor a) async {
    await _ensureLoaded();
    final ids = await _visibleClassIds(a);
    final sectionIds = (await getSections(a)).map((s) => s.id).toSet();
    var list = _timetable.where((t) => ids.contains(t.classId));
    if (a.permissions.isTeacher) {
      list = list.where((t) => _matchesTeacher(a.userId, t.teacherId));
    }
    if (a.permissions.isStudent || a.permissions.isParent) {
      list = list.where((t) => sectionIds.contains(t.sectionId));
    }
    return list.toList()..sort((x, y) {
      final d = x.dayOfWeek.compareTo(y.dayOfWeek);
      return d != 0 ? d : x.startTime.compareTo(y.startTime);
    });
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
    if (model.classroomId != null && model.classroomId!.isNotEmpty) {
      final room = _classrooms
          .where((r) => r.id == model.classroomId)
          .firstOrNull;
      if (room != null && !room.isAvailable) {
        throw ClassesDataException('${room.name} is marked Unavailable.');
      }
    }

    final sanitizedModel = model.isBreak
        ? TimetableEntryModel(
            id: model.id,
            classId: model.classId,
            sectionId: model.sectionId,
            subjectId: '',
            teacherId: '',
            classroomId: null,
            isBreak: true,
            title: model.title?.trim().isNotEmpty == true
                ? model.title!.trim()
                : (model.startTime == '12:00' ? 'Lunch' : 'Break'),
            dayOfWeek: model.dayOfWeek,
            startTime: model.startTime,
            endTime: model.endTime,
            month: model.month,
            subjectType: null,
          )
        : (model.subjectType?.toLowerCase() == 'theory'
              ? model.copyWith(clearClassroom: true)
              : model);

    if (!sanitizedModel.isBreak &&
        sanitizedModel.subjectType?.toLowerCase() == 'practical') {
      if (sanitizedModel.classroomId == null ||
          sanitizedModel.classroomId!.trim().isEmpty) {
        throw const ClassesDataException(
          'Please select an available room or lab for Practical period.',
        );
      }
    }

    bool monthsOverlap(String? m1, String? m2) {
      if (m1 == null || m1.isEmpty || m1 == 'All Months') return true;
      if (m2 == null || m2.isEmpty || m2 == 'All Months') return true;
      return m1.toLowerCase() == m2.toLowerCase();
    }

    bool overlaps(TimetableEntryModel t) =>
        t.id != sanitizedModel.id &&
        t.dayOfWeek == sanitizedModel.dayOfWeek &&
        monthsOverlap(t.month, sanitizedModel.month) &&
        t.startTime.compareTo(sanitizedModel.endTime) < 0 &&
        sanitizedModel.startTime.compareTo(t.endTime) < 0;

    // Break & lunch overlap validation
    if (!sanitizedModel.isBreak) {
      // 1. Cannot overlap standard Break (10:15 - 10:30)
      if (sanitizedModel.startTime.compareTo('10:30') < 0 &&
          '10:15'.compareTo(sanitizedModel.endTime) < 0) {
        throw const ClassesDataException(
          'Cannot schedule class during Break (10:15 AM - 10:30 AM).',
        );
      }
      // 2. Cannot overlap standard Lunch (12:00 - 12:40)
      if (sanitizedModel.startTime.compareTo('12:40') < 0 &&
          '12:00'.compareTo(sanitizedModel.endTime) < 0) {
        throw const ClassesDataException(
          'Cannot schedule class during Lunch (12:00 PM - 12:40 PM).',
        );
      }
      // 3. Cannot overlap custom break scheduled for that day
      for (final t in _timetable.where(
        (e) =>
            e.isBreak && e.dayOfWeek == sanitizedModel.dayOfWeek && overlaps(e),
      )) {
        final bTitle = t.title?.isNotEmpty == true ? t.title! : 'Break';
        throw ClassesDataException(
          'Cannot schedule class during $bTitle (${t.startTime} - ${t.endTime}).',
        );
      }
    } else {
      // Break cannot overlap any scheduled teaching period
      for (final t in _timetable.where(
        (e) =>
            !e.isBreak &&
            e.dayOfWeek == sanitizedModel.dayOfWeek &&
            overlaps(e),
      )) {
        throw ClassesDataException(
          'Break time overlaps with an existing class period (${t.startTime} - ${t.endTime}).',
        );
      }
    }

    for (final t in _timetable.where(overlaps)) {
      if (t.isBreak) continue;
      if (t.sectionId.isNotEmpty && t.sectionId == sanitizedModel.sectionId) {
        throw const ClassesDataException(
          'This section already has a period in that time slot.',
        );
      }
      if (sanitizedModel.teacherId.isNotEmpty &&
          t.teacherId == sanitizedModel.teacherId) {
        throw const ClassesDataException(
          'That teacher is already teaching in that time slot.',
        );
      }
      if (sanitizedModel.classroomId != null &&
          sanitizedModel.classroomId!.isNotEmpty &&
          t.classroomId != null &&
          t.classroomId == sanitizedModel.classroomId) {
        throw const ClassesDataException(
          'That classroom or lab is already booked for that time slot.',
        );
      }
    }

    if (isNew) {
      final created = TimetableEntryModel(
        id: _newId('tt'),
        classId: sanitizedModel.classId,
        sectionId: sanitizedModel.sectionId,
        subjectId: sanitizedModel.subjectId,
        teacherId: sanitizedModel.teacherId,
        classroomId: sanitizedModel.classroomId,
        isBreak: sanitizedModel.isBreak,
        title: sanitizedModel.title,
        dayOfWeek: sanitizedModel.dayOfWeek,
        startTime: sanitizedModel.startTime,
        endTime: sanitizedModel.endTime,
        month: sanitizedModel.month,
        subjectType: sanitizedModel.subjectType,
      );
      _timetable = [..._timetable, created];
      await _persist();
      return created;
    }
    _timetable = [
      for (final t in _timetable)
        t.id == sanitizedModel.id ? sanitizedModel : t,
    ];
    await _persist();
    return sanitizedModel;
  }

  @override
  Future<void> deleteTimetableEntry(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageTimetable, 'delete timetable entries');
    _timetable = _timetable.where((t) => t.id != id).toList();
    await _persist();
  }
}
