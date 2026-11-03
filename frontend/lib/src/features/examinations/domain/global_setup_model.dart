class ExamType {
  final String code;
  final String label;

  const ExamType({
    required this.code,
    required this.label,
  });

  factory ExamType.fromJson(Map<String, dynamic> json) {
    return ExamType(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? json['code'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
    };
  }

  static const List<ExamType> defaultExamTypes = [
    ExamType(code: 'UNIT_TEST', label: 'Unit Test'),
    ExamType(code: 'PERIODIC_TEST', label: 'Periodic Test'),
    ExamType(code: 'MID_TERM', label: 'Mid-Term'),
    ExamType(code: 'HALF_YEARLY', label: 'Half-Yearly'),
    ExamType(code: 'PRE_FINAL', label: 'Pre-Final'),
    ExamType(code: 'ANNUAL', label: 'Annual / Final Exam'),
    ExamType(code: 'PRACTICAL', label: 'Practical Exam'),
    ExamType(code: 'INTERNAL_ASSESSMENT', label: 'Internal Assessment'),
  ];
}

class GlobalUser {
  final String id;
  final String name;
  final String role; // ADMIN | PRINCIPAL | TEACHER | CLASS_INCHARGE | STUDENT | PARENT
  final String? teacherId;
  final String? studentId;
  final String? sectionId;

  const GlobalUser({
    required this.id,
    required this.name,
    required this.role,
    this.teacherId,
    this.studentId,
    this.sectionId,
  });

  factory GlobalUser.fromJson(Map<String, dynamic> json) {
    return GlobalUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'ADMIN').toString().toUpperCase(),
      teacherId: json['teacher_id']?.toString(),
      studentId: json['student_id']?.toString(),
      sectionId: json['section_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      if (teacherId != null) 'teacher_id': teacherId,
      if (studentId != null) 'student_id': studentId,
      if (sectionId != null) 'section_id': sectionId,
    };
  }
}

class GlobalSetup {
  final List<String> academicYears;
  final String currentAcademicYear;
  final List<ExamType> examTypes;
  final List<GlobalUser> users;
  final String currentUserId;

  const GlobalSetup({
    required this.academicYears,
    required this.currentAcademicYear,
    required this.examTypes,
    required this.users,
    required this.currentUserId,
  });

  GlobalUser? get currentUser {
    return users.where((u) => u.id == currentUserId).firstOrNull ??
        (users.isNotEmpty ? users.first : null);
  }

  String resolveUserName(String userId) {
    final user = users.where((u) => u.id == userId).firstOrNull;
    if (user != null) {
      return '${user.name} (${user.role})';
    }
    return userId;
  }

  String resolveExamTypeLabel(String code) {
    final t = examTypes.where((e) => e.code.toUpperCase() == code.toUpperCase()).firstOrNull;
    if (t != null) {
      return t.label;
    }
    return code;
  }

  GlobalSetup copyWith({
    List<String>? academicYears,
    String? currentAcademicYear,
    List<ExamType>? examTypes,
    List<GlobalUser>? users,
    String? currentUserId,
  }) {
    return GlobalSetup(
      academicYears: academicYears ?? this.academicYears,
      currentAcademicYear: currentAcademicYear ?? this.currentAcademicYear,
      examTypes: examTypes ?? this.examTypes,
      users: users ?? this.users,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  factory GlobalSetup.fromJson(Map<String, dynamic> json) {
    return GlobalSetup(
      academicYears: (json['academic_years'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['2025-2026', '2026-2027'],
      currentAcademicYear: (json['current_academic_year'] ?? '2026-2027').toString(),
      examTypes: () {
        final list = (json['exam_types'] as List<dynamic>?)
            ?.map((e) => ExamType.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return (list != null && list.isNotEmpty) ? list : ExamType.defaultExamTypes;
      }(),
      users: (json['users'] as List<dynamic>?)
              ?.map((e) => GlobalUser.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      currentUserId: (json['current_user_id'] ?? 'u1').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academic_years': academicYears,
      'current_academic_year': currentAcademicYear,
      'exam_types': examTypes.map((e) => e.toJson()).toList(),
      'users': users.map((u) => u.toJson()).toList(),
      'current_user_id': currentUserId,
    };
  }
}
