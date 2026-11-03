// Unified reference models used by the Examination module to read
// Classes, Sections, Subjects, Classrooms, and Teachers without duplicate copies.

class RefOption {
  final String id;
  final String label;
  const RefOption(this.id, this.label);
}

class ClassRef extends RefOption {
  final String code;
  const ClassRef(super.id, super.label, {this.code = ''});
}

class SectionRef extends RefOption {
  final String classId;
  final String sectionName;
  final int capacity;
  final String? classroomId;
  final String? teacherId;

  const SectionRef(
    super.id,
    super.label, {
    required this.classId,
    required this.sectionName,
    this.capacity = 40,
    this.classroomId,
    this.teacherId,
  });
}

class SubjectRef extends RefOption {
  final String classId;
  final String code;
  final String? defaultTeacherId;
  final double maxMarks;
  final double passMarks;

  const SubjectRef(
    super.id,
    super.label, {
    required this.classId,
    this.code = '',
    this.defaultTeacherId,
    this.maxMarks = 100.0,
    this.passMarks = 35.0,
  });
}

class RoomRef extends RefOption {
  final int capacity;
  final String building;
  const RoomRef(super.id, super.label, {this.capacity = 40, this.building = ''});
}

class TeacherRef extends RefOption {
  final String employeeId;
  final String department;
  const TeacherRef(super.id, super.label, {this.employeeId = '', this.department = ''});
}

class SubjectAllocationRef {
  final String classSectionId;
  final String subjectId;
  final String? teacherId;
  const SubjectAllocationRef(this.classSectionId, this.subjectId, this.teacherId);
}

/// Backwards compatibility typedef
typedef ClassSectionRef = SectionRef;

class ExamReferenceData {
  final List<ClassRef> classes;
  final List<SectionRef> sections;
  final List<SubjectRef> subjects;
  final List<RoomRef> rooms;
  final List<TeacherRef> teachers;
  final List<SubjectAllocationRef> allocations;

  const ExamReferenceData({
    this.classes = const [],
    this.sections = const [],
    this.subjects = const [],
    this.rooms = const [],
    this.teachers = const [],
    this.allocations = const [],
  });

  String className(String? id) =>
      classes.where((e) => e.id == id).firstOrNull?.label ?? (id ?? '—');

  String sectionName(String? id) {
    if (id == null || id.isEmpty) return '—';
    final sec = sections.where((e) => e.id == id).firstOrNull;
    if (sec != null) return sec.label;
    return id;
  }

  String subjectName(String? id) =>
      subjects.where((e) => e.id == id).firstOrNull?.label ?? (id ?? '—');

  String roomName(String? id) =>
      rooms.where((e) => e.id == id).firstOrNull?.label ?? (id ?? '—');

  String teacherName(String? id) =>
      teachers.where((e) => e.id == id).firstOrNull?.label ?? (id ?? '—');

  String studentName(String? id) {
    if (id == null || id.isEmpty) return '—';
    if (id == 'std-prof-501') return 'Aarav Sharma';
    if (id == 'std-prof-502') return 'Diya Patel';
    if (id == 'std-prof-503') return 'Rohan Verma';
    if (id == 'std-prof-504') return 'Ananya Iyer';
    if (id == 'std-prof-505') return 'Kabir Singh';
    return id;
  }

  String? classIdForSection(String? sectionId) {
    if (sectionId == null) return null;
    return sections.where((s) => s.id == sectionId).firstOrNull?.classId;
  }

  Set<String> _resolveClassIds(String? classId) {
    if (classId == null || classId.isEmpty) return const {};
    final ids = {classId};
    if (classId == 'cls-10' || classId == 'cls-class-10') {
      ids.addAll({'cls-10', 'cls-class-10'});
    }
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls != null) {
      final digits = RegExp(r'\d+').firstMatch(cls.label)?.group(0);
      if (digits != null) {
        for (final other in classes) {
          if (RegExp(r'\d+').firstMatch(other.label)?.group(0) == digits) {
            ids.add(other.id);
          }
        }
      }
    }
    return ids;
  }

  /// Sections that belong to the chosen class
  List<SectionRef> sectionsForClass(String? classId) {
    if (classId == null || classId.isEmpty) return sections;
    final targetClassIds = _resolveClassIds(classId);
    return sections.where((s) => targetClassIds.contains(s.classId)).toList();
  }

  /// Subjects that belong to the chosen class
  List<SubjectRef> subjectsForClass(String? classId) {
    if (classId == null || classId.isEmpty) return subjects;
    final targetClassIds = _resolveClassIds(classId);

    // Collect section IDs belonging to this class
    final secIds = sections
        .where((s) => targetClassIds.contains(s.classId))
        .map((s) => s.id)
        .toSet();

    // Collect subject IDs allocated to any section of this class
    final allocatedSubjectIds = allocations
        .where((a) => secIds.contains(a.classSectionId))
        .map((a) => a.subjectId)
        .toSet();

    final result = subjects
        .where((s) => targetClassIds.contains(s.classId) || allocatedSubjectIds.contains(s.id))
        .toList();

    if (result.isEmpty && subjects.isNotEmpty) {
      return subjects;
    }

    return result;
  }

  /// Subjects for a section (checking allocations first, then class)
  List<SubjectRef> subjectsForSection(String? sectionId) {
    if (sectionId == null || sectionId.isEmpty) return subjects;
    final sec = sections.where((s) => s.id == sectionId).firstOrNull;

    final allocatedSubjectIds = allocations
        .where((a) => a.classSectionId == sectionId)
        .map((a) => a.subjectId)
        .toSet();

    if (allocatedSubjectIds.isNotEmpty) {
      return subjects.where((s) => allocatedSubjectIds.contains(s.id)).toList();
    }

    if (sec?.classId != null) {
      return subjectsForClass(sec!.classId);
    }
    return subjects;
  }

  /// Default teacher for a class/section and subject
  String? defaultTeacherFor(String? sectionId, String? subjectId) {
    final allocTeacher = allocations
        .where((a) => a.classSectionId == sectionId && a.subjectId == subjectId)
        .firstOrNull
        ?.teacherId;
    if (allocTeacher != null && allocTeacher.isNotEmpty) {
      return allocTeacher;
    }
    final subj = subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subj?.defaultTeacherId != null && subj!.defaultTeacherId!.isNotEmpty) {
      return subj.defaultTeacherId;
    }
    return null;
  }
}
