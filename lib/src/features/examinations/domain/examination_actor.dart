import 'exam_schedule_model.dart';
import 'global_setup_model.dart';

enum ExamRole {
  admin,
  principal,
  teacher,
  classIncharge,
  student,
  parent;

  static ExamRole fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'ADMIN':
        return ExamRole.admin;
      case 'PRINCIPAL':
        return ExamRole.principal;
      case 'TEACHER':
        return ExamRole.teacher;
      case 'CLASS_INCHARGE':
        return ExamRole.classIncharge;
      case 'STUDENT':
        return ExamRole.student;
      case 'PARENT':
        return ExamRole.parent;
      default:
        return ExamRole.admin;
    }
  }

  String get code {
    switch (this) {
      case ExamRole.admin:
        return 'ADMIN';
      case ExamRole.principal:
        return 'PRINCIPAL';
      case ExamRole.teacher:
        return 'TEACHER';
      case ExamRole.classIncharge:
        return 'CLASS_INCHARGE';
      case ExamRole.student:
        return 'STUDENT';
      case ExamRole.parent:
        return 'PARENT';
    }
  }

  String get displayName {
    switch (this) {
      case ExamRole.admin:
        return 'Admin';
      case ExamRole.principal:
        return 'Principal';
      case ExamRole.teacher:
        return 'Teacher';
      case ExamRole.classIncharge:
        return 'Class Incharge';
      case ExamRole.student:
        return 'Student';
      case ExamRole.parent:
        return 'Parent';
    }
  }
}

class ExaminationPermissions {
  final ExamRole role;

  const ExaminationPermissions(this.role);

  bool get isAdmin => role == ExamRole.admin;
  bool get isPrincipal => role == ExamRole.principal;
  bool get isTeacher => role == ExamRole.teacher;
  bool get isClassIncharge => role == ExamRole.classIncharge;
  bool get isStudent => role == ExamRole.student;
  bool get isParent => role == ExamRole.parent;

  /// ADMIN / PRINCIPAL: full access
  bool get isAdminOrPrincipal => isAdmin || isPrincipal;

  /// Can create new exams
  bool get canCreateExam => isAdminOrPrincipal;

  /// Can edit existing exams
  bool get canEditExam => isAdminOrPrincipal;

  /// Can cancel exams
  bool get canCancelExam => isAdminOrPrincipal;

  /// Can delete PLANNED exams with 0 papers
  bool get canDeleteExam => isAdminOrPrincipal;

  /// Read-only roles
  bool get isReadOnly => !isAdminOrPrincipal;

  // ---- Permissions for the other examination screens ----

  /// Timetable (exam papers): create / edit / delete / cancel.
  bool get canManagePapers => isAdminOrPrincipal;

  /// Hall tickets: generate, revoke, delete.
  bool get canManageHallTickets => isAdminOrPrincipal;

  /// Exam-day attendance (invigilators are teachers).
  bool get canMarkAttendance => isAdminOrPrincipal || isTeacher;

  /// Marks entry. Admin can edit marks at any time.
  bool get canEnterMarks => isAdminOrPrincipal || isTeacher;

  /// Marks review, correction requests and student remarks.
  bool get canReviewMarks => isAdminOrPrincipal || isClassIncharge;

  /// Calculate results, approve, publish report cards.
  bool get canManageResults => isAdminOrPrincipal;

  /// Syllabus & exam pattern setup.
  bool get canManagePatterns => isAdminOrPrincipal;

  /// Question bank and question paper writing.
  bool get canWriteQuestions => isAdminOrPrincipal || isTeacher;

  /// Question paper review / approval.
  bool get canApproveQuestionPapers => isAdminOrPrincipal;

  /// STUDENT and PARENT: read-only, shown as simple cards, hide PLANNED exams that have no papers.
  bool get isStudentOrParent => isStudent || isParent;

  /// Filter out PLANNED exams that have no papers for students and parents
  bool canViewExam(ExamSchedule exam) {
    if (isStudentOrParent) {
      if (exam.isPlanned && exam.paperCount == 0) {
        return false;
      }
    }
    return true;
  }
}

class ExaminationActor {
  final String userId;
  final String name;
  final ExamRole role;

  /// Linked live-data ids (see GlobalUser).
  final String? teacherId;
  final String? sectionId;
  final String? studentId;

  const ExaminationActor({
    required this.userId,
    required this.name,
    required this.role,
    this.teacherId,
    this.sectionId,
    this.studentId,
  });

  factory ExaminationActor.fromGlobalUser(GlobalUser user) {
    return ExaminationActor(
      userId: user.id,
      name: user.name,
      role: ExamRole.fromString(user.role),
      teacherId: user.teacherId,
      sectionId: user.sectionId,
      studentId: user.studentId,
    );
  }

  ExaminationPermissions get permissions => ExaminationPermissions(role);
}

