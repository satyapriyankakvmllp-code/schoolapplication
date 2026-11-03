import '../../authentication/domain/user_model.dart';

/// Role-based permission matrix for the Classes feature.
/// Admin: Full access across Classes, Subjects, Sections, Curriculum, Lessons, Timetable, Classrooms, Teacher Work.
/// Teacher: View assigned classes/subjects/sections/timetable/classrooms; Add, view, edit Curriculum, Daily Lessons, and Teacher Work.
/// Student / Parent: Read-only access to enrolled class, subjects, curriculum, daily lessons, timetable, and teacher work.
class ClassesPermissions {
  final UserRole? role;
  const ClassesPermissions(this.role);

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;
  bool get isParent => role == UserRole.parent;

  bool get canAccessClasses => isAdmin || isTeacher || isStudent || isParent;
  bool get canManageClasses => isAdmin;
  bool get canManageSubjects => isAdmin;
  bool get canManageSections => isAdmin;
  bool get canManageCurriculum => isAdmin || isTeacher;
  bool get canUpdateCurriculumProgress => isAdmin || isTeacher;
  bool get canManageTimetable => isAdmin;
  bool get canManageClassrooms => isAdmin;
  bool get canAssignTeachers => isAdmin;
  bool get canWriteLessons => isAdmin || isTeacher;
  bool get canManageTeacherWork => isAdmin || isTeacher;

  /// Admin can view teacher assignments but never delete them; teachers manage their own.
  bool get canDeleteTeacherWork => isTeacher;
  bool get canViewTeacherWork => isAdmin || isTeacher || isStudent || isParent;
}

/// Identity + scope of the signed-in user, handed to the data-access layer,
/// which re-checks permissions on every write.
class ClassesActor {
  final UserRole? role;
  final String userId;

  /// Student only: the class name / section from the admission record.
  final String? studentClassName;
  final String? studentSection;
  final String? studentId;
  final String? studentUserId;
  final String? studentClassId;
  final String? studentSectionId;
  final String? linkedParentUserId;

  const ClassesActor({
    required this.role,
    required this.userId,
    this.studentClassName,
    this.studentSection,
    this.studentId,
    this.studentUserId,
    this.studentClassId,
    this.studentSectionId,
    this.linkedParentUserId,
  });

  ClassesPermissions get permissions => ClassesPermissions(role);
}
