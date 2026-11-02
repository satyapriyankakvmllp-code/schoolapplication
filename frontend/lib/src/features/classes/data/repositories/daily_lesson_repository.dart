part of '../classes_repository.dart';

/// Daily lessons: reads, writes and rules.
mixin _DailyLessonRepository on _ClassesStore {
  @override
  Future<List<DailyLessonModel>> getLessons(ClassesActor a) async {
    await _ensureLoaded();
    final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
    var visible = _lessons.where((l) => subjectIds.contains(l.subjectId));
    if (a.permissions.isStudent || a.permissions.isParent) {
      if (a.studentSectionId == null || a.studentSectionId!.isEmpty) {
        return const [];
      }
      visible = visible.where(
        (lesson) =>
            lesson.sectionId.isEmpty || lesson.sectionId == a.studentSectionId,
      );
    }
    return visible.toList()..sort((x, y) => y.date.compareTo(x.date));
  }

  // --------------------------------------------------------- daily lessons
  @override
  Future<DailyLessonModel> saveLesson(
    ClassesActor a,
    DailyLessonModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canWriteLessons, 'write daily lessons');
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == model.subjectId);
      final matchesTeacher = _matchesTeacher(a.userId, subject.teacherId);
      _require(
        matchesTeacher,
        'write lessons for a subject not assigned to you',
      );
      _require(
        subject.classId == model.classId,
        'write lessons outside the assigned subject class',
      );
      if (!isNew) {
        final existing = _lessons.firstWhere((l) => l.id == model.id);
        final matchesExisting = _matchesTeacher(a.userId, existing.teacherId);
        _require(matchesExisting, 'edit another teacher\'s lesson');
      }
    }
    if (isNew) {
      final created = DailyLessonModel(
        id: _newId('les'),
        classId: model.classId,
        sectionId: model.sectionId,
        subjectId: model.subjectId,
        teacherId: a.permissions.isTeacher
            ? (_subjects
                      .where((s) => s.id == model.subjectId)
                      .first
                      .teacherId ??
                  a.userId)
            : model.teacherId,
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
      final matchesExisting = _matchesTeacher(a.userId, existing.teacherId);
      _require(matchesExisting, 'delete another teacher\'s lesson');
    }
    _lessons = _lessons.where((l) => l.id != id).toList();
    await _persist();
  }
}
