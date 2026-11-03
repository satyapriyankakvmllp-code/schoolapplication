import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import '../../application/classes_controller.dart';
import '../../application/classroom_controller.dart';
import '../../application/sections_controller.dart';
import '../../application/subjects_controller.dart';
import '../../domain/class_model.dart';
import '../../domain/classroom_model.dart';
import '../../domain/section_model.dart';
import '../../domain/subject_model.dart';

import '../../../staff/application/staff_controller.dart';
import '../../../staff/domain/staff_member_model.dart';

class TeacherOption {
  final String id;
  final String name;
  // Full details come straight from the Staff Directory record (never copied).
  final String designation;
  final String department;
  final String specialization;
  final List<String> assignedSubjects;
  final String phone;
  final String email;
  const TeacherOption(
    this.id,
    this.name, {
    this.designation = '',
    this.department = '',
    this.specialization = '',
    this.assignedSubjects = const [],
    this.phone = '',
    this.email = '',
  });
}

/// Evaluates whether a [TeacherOption] is qualified or designated to teach [subjectName].
bool isTeacherQualifiedForSubject(TeacherOption teacher, String? subjectName) {
  if (subjectName == null || subjectName.trim().isEmpty) return false;
  final sName = subjectName.trim().toLowerCase();

  // 1. Direct assigned subject match from staff record
  for (final asub in teacher.assignedSubjects) {
    final a = asub.trim().toLowerCase();
    if (a.isEmpty) continue;
    if (a == sName) return true;
    if (a.length >= 4 && sName.length >= 4) {
      if (sName.startsWith(a) || a.startsWith(sName)) return true;
    }
  }

  final dept = teacher.department.toLowerCase();
  final desig = teacher.designation.toLowerCase();
  final spec = teacher.specialization.toLowerCase();

  // 2. Domain classification based on subject name
  // Mathematics
  if (sName.contains('math') ||
      sName.contains('calculus') ||
      sName.contains('algebra') ||
      sName.contains('trig') ||
      sName.contains('geometry')) {
    return dept == 'mathematics' ||
        desig.contains('mathematics') ||
        spec.contains('algebra') ||
        spec.contains('calculus') ||
        spec.contains('geometry');
  }

  // Physics
  if (sName.contains('physics')) {
    return desig.contains('physics') || spec.contains('physics');
  }

  // Chemistry
  if (sName.contains('chemistry')) {
    return desig.contains('chemistry') || spec.contains('chemistry');
  }

  // Natural / General Science (Science, General Science) - excludes Social and Computer Science
  if (sName.contains('science') &&
      !sName.contains('social') &&
      !sName.contains('computer')) {
    return dept == 'science' &&
        !desig.contains('computer') &&
        !desig.contains('social');
  }

  // English / Literature
  if (sName.contains('english') || sName.contains('literature')) {
    return dept == 'english' ||
        desig.contains('english') ||
        desig.contains('literature') ||
        spec.contains('literature') ||
        spec.contains('language arts');
  }

  // Computer Science / AI / IT
  if (sName.contains('computer') ||
      sName.contains(' ai') ||
      sName.contains('artificial intelligence') ||
      sName.contains('information technology') ||
      sName.contains('robotics')) {
    return dept == 'computer science' ||
        desig.contains('computer') ||
        spec.contains('computer') ||
        desig.contains('ai');
  }

  // Social Science / Social Studies / History / Civics
  if (sName.contains('social') ||
      sName.contains('history') ||
      sName.contains('civics') ||
      sName.contains('geography')) {
    return dept == 'social science' ||
        dept == 'social studies' ||
        desig.contains('social') ||
        desig.contains('history') ||
        spec.contains('history') ||
        spec.contains('social');
  }

  // Physical Education / Sports
  if (sName.contains('physical education') ||
      sName.contains('physical & health') ||
      sName.contains('sports') ||
      sName.contains('athletics')) {
    return dept == 'physical education' ||
        desig.contains('physical education') ||
        desig.contains('athletics') ||
        spec.contains('sports');
  }

  // Hindi
  if (sName.contains('hindi')) {
    return dept.contains('hindi') ||
        desig.contains('hindi') ||
        spec.contains('hindi');
  }

  // Biology
  if (sName.contains('biology') ||
      sName.contains('botany') ||
      sName.contains('zoology')) {
    return dept.contains('biology') ||
        desig.contains('biology') ||
        spec.contains('biology');
  }

  return false;
}

/// Older class data still stores these ids. They resolve to the real Staff
/// Directory record so a teacher is never listed (or counted) twice.
const Map<String, String> kLegacyTeacherAliases = {
  'tch-101': 'STF-2026-0111',
  'tch-102': 'STF-2026-0112',
  'tch-103': 'STF-2026-0113',
  'tch-104': 'STF-2026-0114',
  'tch-105': 'STF-2026-0115',
  'tch-106': 'STF-2026-0116',
  'tch-107': 'STF-2026-0117',
  'tch-108': 'STF-2026-0118',
  'USR-TEACH-01': 'STF-2026-0111',
};

/// Teachers = the teaching staff of the Staff Directory (assets/data/staff/staff.json).
final classesTeachersProvider = Provider<List<TeacherOption>>((ref) {
  final staffList = ref.watch(staffListProvider).value ?? [];
  final teachingStaff = staffList
      .where((s) => s.category == StaffCategory.teaching)
      .toList();

  final Map<String, TeacherOption> map = {};
  for (final staff in teachingStaff) {
    map[staff.id] = TeacherOption(
      staff.id,
      '${staff.fullName} (${staff.designation})',
      designation: staff.designation,
      department: staff.department,
      specialization: staff.specialization ?? '',
      assignedSubjects: staff.assignedClasses.map((a) => a.subject).toList(),
      phone: staff.phone,
      email: staff.email,
    );
  }

  final activeTeacher = RoleDirectory.mockUsers[UserRole.teacher];
  if (activeTeacher != null &&
      !map.containsKey(activeTeacher.id) &&
      !map.containsKey(kLegacyTeacherAliases[activeTeacher.id])) {
    map[activeTeacher.id] = TeacherOption(
      activeTeacher.id,
      '${activeTeacher.firstName} ${activeTeacher.lastName} (Current User)',
    );
  }

  return map.values.toList();
});

/// Id -> display name resolver built from already-loaded, role-scoped data.
class ClassesLookup {
  final List<ClassModel> classes;
  final List<SectionModel> sections;
  final List<SubjectModel> subjects;
  final List<ClassroomModel> classrooms;
  final List<TeacherOption> teachers;

  const ClassesLookup({
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.classrooms,
    required this.teachers,
  });

  /// Dynamically returns only teachers qualified or assigned to teach [subjectName].
  List<TeacherOption> qualifiedTeachersForSubject(String? subjectName) {
    if (subjectName == null || subjectName.trim().isEmpty) return const [];
    return teachers
        .where((t) => isTeacherQualifiedForSubject(t, subjectName))
        .toList();
  }

  String className(String? id) =>
      _first(classes.where((c) => c.id == id), (c) => c.name);
  String sectionName(String? id) =>
      _first(sections.where((s) => s.id == id), (s) => s.name);
  String subjectName(String? id) =>
      _first(subjects.where((s) => s.id == id), (s) => s.name);
  String roomName(String? id) =>
      _first(classrooms.where((r) => r.id == id), (r) => r.name);
  String teacherName(String? id) {
    if (id == null || id.isEmpty) return 'Unassigned';
    final match = teachers.where((t) => t.id == canonicalTeacherId(id));
    if (match.isNotEmpty) return match.first.name;
    // Fallback known aliases
    switch (id) {
      case 'tch-101':
      case 'USR-TEACH-01':
        return 'Anita Roy';
      case 'tch-102':
        return 'R. Sharma';
      case 'tch-103':
        return 'S. Verma';
      case 'tch-104':
        return 'A. Singh';
      case 'tch-105':
        return 'P. Mehta';
      case 'tch-106':
        return 'N. Gupta';
      case 'tch-107':
        return 'V. Joshi';
      case 'tch-108':
        return 'M. Khan';
      default:
        return id;
    }
  }

  /// Staff Directory id for [id] (maps legacy ids such as tch-101 to their staff record).
  String canonicalTeacherId(String id) => kLegacyTeacherAliases[id] ?? id;

  TeacherOption? teacherById(String? id) {
    if (id == null || id.isEmpty) return null;
    final cid = canonicalTeacherId(id);
    return teachers.where((t) => t.id == cid).firstOrNull;
  }

  /// Case-insensitive teacher lookup by name ("anita roy" == "ANITA ROY").
  TeacherOption? teacherByName(String name) {
    final q = name.trim().toLowerCase();
    if (q.isEmpty) return null;
    return teachers.where((t) => t.name.toLowerCase().contains(q)).firstOrNull;
  }

  /// "5th Class – A, B" style summary of who uses [roomId] (class room and/or section rooms).
  String? roomAssignmentSummary(String? roomId) {
    if (roomId == null || roomId.isEmpty) return null;
    final parts = <String>[];
    for (final c in classes) {
      final secs = sections
          .where((s) => s.classId == c.id && s.classroomId == roomId)
          .map((s) => s.name)
          .toList();
      if (c.classroomId == roomId || secs.isNotEmpty) {
        parts.add(secs.isEmpty ? c.name : '${c.name} – ${secs.join(', ')}');
      }
    }
    return parts.isEmpty ? null : parts.join(' | ');
  }

  /// The single (class, section) pair that owns [roomId], or null when none / ambiguous.
  ({String classId, String? sectionId})? uniqueRoomHolder(String? roomId) {
    if (roomId == null || roomId.isEmpty) return null;
    final owners = <String>{
      for (final c in classes)
        if (c.classroomId == roomId) c.id,
      for (final s in sections)
        if (s.classroomId == roomId) s.classId,
    };
    if (owners.length != 1) return null;
    final classId = owners.first;
    final secs = sections
        .where((s) => s.classId == classId && s.classroomId == roomId)
        .toList();
    return (
      classId: classId,
      sectionId: secs.length == 1 ? secs.first.id : null,
    );
  }

  bool matchesTeacher(String? teacherId, String? currentUserId) {
    if (teacherId == null || currentUserId == null) return false;
    final canonicalIds = {
      'USR-TEACH-01': 'STF-2026-0111',
      'tch-101': 'STF-2026-0111',
      'tch-102': 'STF-2026-0112',
    };
    return (canonicalIds[teacherId] ?? teacherId) ==
        (canonicalIds[currentUserId] ?? currentUserId);
  }

  static String _first<T>(
    Iterable<T> it,
    String Function(T) f, {
    String empty = '—',
  }) => it.isEmpty ? empty : f(it.first);
}

final classesLookupProvider = Provider<ClassesLookup>((ref) {
  return ClassesLookup(
    classes: ref.watch(classesControllerProvider).valueOrNull ?? const [],
    sections: ref.watch(sectionsControllerProvider).valueOrNull ?? const [],
    subjects: ref.watch(subjectsControllerProvider).valueOrNull ?? const [],
    classrooms: ref.watch(classroomControllerProvider).valueOrNull ?? const [],
    teachers: ref.watch(classesTeachersProvider),
  );
});
