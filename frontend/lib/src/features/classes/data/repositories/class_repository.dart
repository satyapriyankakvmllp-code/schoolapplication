part of '../classes_repository.dart';

/// Classes (class list, custom fields, class teacher): reads, writes and rules.
mixin _ClassRepository on _ClassesStore {
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

  @override
  Future<List<Map<String, dynamic>>> getClassFieldDefinitions(
    ClassesActor a,
  ) async {
    await _ensureLoaded();
    _require(a.permissions.canAccessClasses, 'view class fields');
    return _classFieldDefinitions.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<void> saveClassFieldDefinition(ClassesActor a, String name) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClasses, 'manage class fields');
    final label = name.trim();
    if (label.isEmpty)
      throw const ClassesDataException('Field name is required.');
    if (_classFieldDefinitions.any(
      (field) =>
          (field['name'] as String? ?? '').trim().toLowerCase() ==
          label.toLowerCase(),
    )) {
      throw ClassesDataException('A field named "$label" already exists.');
    }
    final id = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    _classFieldDefinitions = [
      ..._classFieldDefinitions,
      {'id': id, 'name': label},
    ];
    await _persist();
  }

  // --------------------------------------------------------------- classes
  @override
  Future<ClassModel> saveClass(
    ClassesActor a,
    ClassModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClasses, 'manage classes');

    // Duplicate class prevention (Name and Code)
    final isDuplicate = _classes.any(
      (c) =>
          (isNew || c.id != model.id) &&
          c.name.trim().toLowerCase() == model.name.trim().toLowerCase(),
    );
    if (isDuplicate) {
      throw ClassesDataException(
        'A class named "${model.name}" already exists.',
      );
    }
    if (model.code.trim().isNotEmpty) {
      final isDuplicateCode = _classes.any(
        (c) =>
            (isNew || c.id != model.id) &&
            c.code.trim().toLowerCase() == model.code.trim().toLowerCase(),
      );
      if (isDuplicateCode) {
        throw ClassesDataException(
          'A class with code "${model.code}" already exists.',
        );
      }
    }

    // Class strength validation
    if (model.capacity < 0) {
      throw const ClassesDataException(
        'Class strength cannot be a negative number.',
      );
    }
    if (model.capacity > 0 &&
        model.classroomId != null &&
        model.classroomId!.isNotEmpty) {
      final room = _classrooms
          .where((r) => r.id == model.classroomId)
          .firstOrNull;
      if (room != null && room.capacity > 0 && model.capacity > room.capacity) {
        throw ClassesDataException(
          'Class strength (${model.capacity}) cannot exceed selected classroom capacity (${room.capacity}).',
        );
      }
    }

    final prevClass = isNew
        ? null
        : _classes.where((c) => c.id == model.id).firstOrNull;
    if (model.classroomId != prevClass?.classroomId) {
      _checkRoomAssignable(model.classroomId, model.id);
    }

    if (isNew) {
      final code = model.code.isNotEmpty
          ? model.code
          : 'CLS-${model.gradeLevel > 0 ? model.gradeLevel : (model.name.replaceAll(RegExp(r'\D'), '').isNotEmpty ? model.name.replaceAll(RegExp(r'\D'), '') : '1')}';
      final created = ClassModel(
        id: _newId('cls'),
        name: model.name,
        code: code,
        gradeLevel: model.gradeLevel,
        academicYear: model.academicYear,
        status: model.status.isNotEmpty ? model.status : 'Active',
        classTeacherId: model.classTeacherId,
        classroomId: model.classroomId,
        subjectCount: model.subjectCount,
        studentCount: model.studentCount,
        teacherCount: model.teacherCount,
        subject: model.subject,
        capacity: model.capacity,
        customFields: model.customFields,
      );
      _classes = [..._classes, created];
      _syncClassroomAssignmentStatuses();
      await _persist();
      return created;
    }
    _classes = [for (final c in _classes) c.id == model.id ? model : c];
    if (model.capacity > 0) {
      final classSecs = _sections.where((s) => s.classId == model.id).toList();
      _sections = [
        for (final s in _sections)
          if (s.classId == model.id)
            () {
              final idx = classSecs.indexWhere((cs) => cs.id == s.id);
              if (idx == 0) {
                return s.copyWith(capacity: model.capacity);
              } else {
                // Section B and subsequent sections maintain a different strength, never the same
                final diff = (idx % 2 == 1) ? -2 : 2;
                final altCap = (model.capacity + diff > 0)
                    ? model.capacity + diff
                    : model.capacity + 2;
                final secCap = (s.capacity > 0 && s.capacity != model.capacity)
                    ? s.capacity
                    : altCap;
                return s.copyWith(capacity: secCap);
              }
            }()
          else
            s,
      ];
    }
    _syncClassroomAssignmentStatuses();
    await _persist();
    return model;
  }

  @override
  Future<void> deleteClass(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageClasses, 'delete classes');
    _classes = _classes.where((c) => c.id != id).toList();
    _sections = _sections.where((s) => s.classId != id).toList();
    final removedSubjects = _subjects
        .where((s) => s.classId == id)
        .map((s) => s.id)
        .toSet();
    _subjects = _subjects.where((s) => s.classId != id).toList();
    _curriculum = _curriculum.where((c) => c.classId != id).toList();
    _lessons = _lessons
        .where((l) => l.classId != id && !removedSubjects.contains(l.subjectId))
        .toList();
    _timetable = _timetable.where((t) => t.classId != id).toList();
    _teacherWork = _teacherWork.where((w) => w.classId != id).toList();
    _teacherAssignments = _teacherAssignments
        .where((t) => t.classId != id)
        .toList();
    _syncClassroomAssignmentStatuses();
    await _persist();
  }

  @override
  Future<ClassModel> assignClassTeacher(
    ClassesActor a,
    String classId,
    String? teacherId,
  ) async {
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
}
