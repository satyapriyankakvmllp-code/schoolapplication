// Read-only snapshot of the school data the examination module depends on.
// It is read from the SAME live stores used by the Classes, Staff and
// Admissions modules, so classes, subjects, teachers and students created
// there show up here automatically.

class ExamClassInfo {
  final String id;
  final String name;
  const ExamClassInfo({required this.id, required this.name});
}

class ExamSectionInfo {
  final String id;
  final String classId;
  final String name;
  final String? classroomId;
  final String? classTeacherId;
  const ExamSectionInfo({
    required this.id,
    required this.classId,
    required this.name,
    this.classroomId,
    this.classTeacherId,
  });
}

class ExamSubjectInfo {
  final String id;
  final String classId;
  final String name;
  final String code;
  final String? teacherId;
  final double maxMarks;
  final double passMarks;
  const ExamSubjectInfo({
    required this.id,
    required this.classId,
    required this.name,
    this.code = '',
    this.teacherId,
    this.maxMarks = 100,
    this.passMarks = 35,
  });
}

class ExamRoomInfo {
  final String id;
  final String name;
  final int capacity;
  const ExamRoomInfo({required this.id, required this.name, this.capacity = 0});
}

class ExamTeacherInfo {
  final String id;
  final String name;
  final String department;
  const ExamTeacherInfo({required this.id, required this.name, this.department = ''});
}

class ExamStudentInfo {
  final String id;
  final String name;
  final String rollNumber;
  final String classId;
  final String sectionId;
  final bool enrolled;
  const ExamStudentInfo({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.classId,
    required this.sectionId,
    this.enrolled = true,
  });

  int get rollSort => int.tryParse(rollNumber) ?? 100000;
}

class ExamChapterInfo {
  final String id;
  final String classId;
  final String subjectId;
  final String title;
  const ExamChapterInfo({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.title,
  });
}

class ExamMasterData {
  final List<ExamClassInfo> classes;
  final List<ExamSectionInfo> sections;
  final List<ExamSubjectInfo> subjects;
  final List<ExamRoomInfo> rooms;
  final List<ExamTeacherInfo> teachers;
  final List<ExamStudentInfo> students;
  final List<ExamChapterInfo> chapters;

  const ExamMasterData({
    this.classes = const [],
    this.sections = const [],
    this.subjects = const [],
    this.rooms = const [],
    this.teachers = const [],
    this.students = const [],
    this.chapters = const [],
  });

  static const ExamMasterData empty = ExamMasterData();

  ExamClassInfo? classById(String? id) =>
      classes.where((c) => c.id == id).firstOrNull;
  ExamSectionInfo? sectionById(String? id) =>
      sections.where((s) => s.id == id).firstOrNull;
  ExamSubjectInfo? subjectById(String? id) =>
      subjects.where((s) => s.id == id).firstOrNull;
  ExamRoomInfo? roomById(String? id) => rooms.where((r) => r.id == id).firstOrNull;
  ExamTeacherInfo? teacherById(String? id) =>
      teachers.where((t) => t.id == id).firstOrNull;
  ExamStudentInfo? studentById(String? id) =>
      students.where((s) => s.id == id).firstOrNull;
  ExamChapterInfo? chapterById(String? id) =>
      chapters.where((c) => c.id == id).firstOrNull;

  String sectionLabel(String? sectionId) {
    final s = sectionById(sectionId);
    if (s == null) return sectionId ?? '-';
    final c = classById(s.classId);
    return '${c?.name ?? s.classId} - ${s.name}';
  }

  /// Short code like 10A used in hall ticket numbers.
  String sectionCode(String? sectionId) {
    final s = sectionById(sectionId);
    if (s == null) return 'X';
    final c = classById(s.classId);
    final digits = RegExp(r'\d+').firstMatch(c?.name ?? '')?.group(0);
    final base = digits ?? (c?.name ?? 'C').replaceAll(RegExp(r'[^A-Za-z]'), '');
    return '$base${s.name}'.toUpperCase();
  }

  String subjectName(String? id) => subjectById(id)?.name ?? (id ?? '-');
  String teacherName(String? id) => (id == null || id.isEmpty)
      ? '-'
      : (teacherById(id)?.name ?? id);
  String roomName(String? id) =>
      (id == null || id.isEmpty) ? '-' : (roomById(id)?.name ?? id);
  String studentName(String? id) => studentById(id)?.name ?? (id ?? '-');

  List<ExamSubjectInfo> subjectsForSection(String? sectionId) {
    final s = sectionById(sectionId);
    if (s == null) return const [];
    return subjects.where((x) => x.classId == s.classId).toList();
  }

  /// Enrolled students of one section, ordered by roll number.
  List<ExamStudentInfo> studentsForSection(String? sectionId) {
    final list =
        students.where((s) => s.sectionId == sectionId && s.enrolled).toList();
    list.sort((a, b) {
      final c = a.rollSort.compareTo(b.rollSort);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return list;
  }

  List<ExamChapterInfo> chaptersFor(String? subjectId) =>
      chapters.where((c) => c.subjectId == subjectId).toList();
}
