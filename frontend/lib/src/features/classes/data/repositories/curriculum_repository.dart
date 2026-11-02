part of '../classes_repository.dart';

/// Curriculum and topic progress: reads, writes and rules.
mixin _CurriculumRepository on _ClassesStore {
  @override
  Future<List<CurriculumModel>> getCurriculum(ClassesActor a) async {
    await _ensureLoaded();
    final subjectIds = (await getSubjects(a)).map((s) => s.id).toSet();
    return _curriculum.where((c) => subjectIds.contains(c.subjectId)).toList();
  }

  // ------------------------------------------------------------ curriculum
  @override
  Future<CurriculumModel> saveCurriculum(
    ClassesActor a,
    CurriculumModel model, {
    bool isNew = false,
  }) async {
    await _ensureLoaded();
    _require(a.permissions.canManageCurriculum, 'manage curriculum');
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == model.subjectId);
      final matchesTeacher = _matchesTeacher(a.userId, subject.teacherId);
      _require(
        matchesTeacher,
        'manage curriculum for a subject not assigned to you',
      );
      _require(
        subject.classId == model.classId,
        'manage curriculum outside the assigned subject class',
      );
    }
    if (isNew) {
      final created = CurriculumModel(
        id: _newId('cur'),
        classId: model.classId,
        subjectId: model.subjectId,
        title: model.title,
        description: model.description,
        topics: model.topics,
        completedTopics: model.completedTopics,
      );
      _curriculum = [..._curriculum, created];
      await _persist();
      return created;
    }
    _curriculum = [for (final c in _curriculum) c.id == model.id ? model : c];
    await _persist();
    return model;
  }

  @override
  Future<void> deleteCurriculum(ClassesActor a, String id) async {
    await _ensureLoaded();
    _require(a.permissions.canManageCurriculum, 'delete curriculum');
    final existing = _curriculum.firstWhere((c) => c.id == id);
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == existing.subjectId);
      final matchesTeacher = _matchesTeacher(a.userId, subject.teacherId);
      _require(
        matchesTeacher,
        'delete curriculum for a subject not assigned to you',
      );
    }
    _curriculum = _curriculum.where((c) => c.id != id).toList();
    await _persist();
  }

  /// Teachers may update progress only for subjects they are assigned to.
  @override
  Future<CurriculumModel> updateProgress(
    ClassesActor a,
    String curriculumId,
    int completedTopics,
  ) async {
    await _ensureLoaded();
    _require(
      a.permissions.canUpdateCurriculumProgress,
      'update curriculum progress',
    );
    final current = _curriculum.firstWhere((c) => c.id == curriculumId);
    if (a.permissions.isTeacher) {
      final subject = _subjects.firstWhere((s) => s.id == current.subjectId);
      final matchesTeacher = _matchesTeacher(a.userId, subject.teacherId);
      _require(
        matchesTeacher,
        'update progress for a subject not assigned to you',
      );
    }
    final next = current.copyWith(completedTopics: completedTopics);
    _curriculum = [
      for (final c in _curriculum) c.id == curriculumId ? next : c,
    ];
    await _persist();
    return next;
  }
}
