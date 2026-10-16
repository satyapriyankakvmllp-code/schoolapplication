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

class TeacherOption {
  final String id;
  final String name;
  const TeacherOption(this.id, this.name);
}

/// Teachers known to the app. Combines active mock users and school faculty directory.
final classesTeachersProvider = Provider<List<TeacherOption>>((ref) {
  final activeTeacher = RoleDirectory.mockUsers[UserRole.teacher];
  return [
    if (activeTeacher != null)
      TeacherOption(activeTeacher.id, '${activeTeacher.firstName} ${activeTeacher.lastName} (Current User)'),
    const TeacherOption('tch-101', 'Anita Roy (Class In-Charge 10A)'),
    const TeacherOption('tch-102', 'R. Sharma (Mathematics HOD)'),
    const TeacherOption('tch-103', 'S. Verma (English Literature)'),
    const TeacherOption('tch-104', 'A. Singh (Physics & Science)'),
    const TeacherOption('tch-105', 'P. Mehta (Chemistry)'),
    const TeacherOption('tch-106', 'N. Gupta (Computer Science & AI)'),
    const TeacherOption('tch-107', 'V. Joshi (Social Science)'),
    const TeacherOption('tch-108', 'M. Khan (Physical Education)'),
    const TeacherOption('tch-109', 'K. Gupta (Hindi Core)'),
    const TeacherOption('tch-110', 'P. Rao (Art & Design)'),
    const TeacherOption('tch-111', 'R. Iyer (Music & Performing Arts)'),
    const TeacherOption('tch-112', 'D. Patel (Biology & Environmental Studies)'),
    const TeacherOption('tch-113', 'T. Das (History & Geography)'),
    const TeacherOption('tch-114', 'S. Nair (Value Education & Ethics)'),
  ];
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

  String className(String? id) => _first(classes.where((c) => c.id == id), (c) => c.name);
  String sectionName(String? id) => _first(sections.where((s) => s.id == id), (s) => s.name);
  String subjectName(String? id) => _first(subjects.where((s) => s.id == id), (s) => s.name);
  String roomName(String? id) => _first(classrooms.where((r) => r.id == id), (r) => r.name);
  String teacherName(String? id) {
    if (id == null || id.isEmpty) return 'Unassigned';
    final match = teachers.where((t) => t.id == id);
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

  static String _first<T>(Iterable<T> it, String Function(T) f, {String empty = '—'}) =>
      it.isEmpty ? empty : f(it.first);
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
