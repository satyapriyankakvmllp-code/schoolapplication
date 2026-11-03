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
}

class GlobalUser {
  final String id;
  final String name;
  final String role; // ADMIN | PRINCIPAL | TEACHER | CLASS_INCHARGE | STUDENT | PARENT

  /// Links to the live school data (staff id, class section id, student id).
  /// Used to scope what each role is allowed to see.
  final String? teacherId;
  final String? sectionId;
  final String? studentId;

  const GlobalUser({
    required this.id,
    required this.name,
    required this.role,
    this.teacherId,
    this.sectionId,
    this.studentId,
  });

  /// Defaults used when an older saved global.json has no link fields yet.
  static const Map<String, Map<String, String>> _defaultLinks = {
    'u3': {'teacher_id': 'STF-2026-0113'},
    'u4': {'teacher_id': 'STF-2026-0111', 'section_id': 'sec-10a'},
    'u5': {'student_id': 'std-1001', 'section_id': 'sec-10a'},
    'u6': {'student_id': 'std-1001', 'section_id': 'sec-10a'},
  };

  factory GlobalUser.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final defaults = _defaultLinks[id] ?? const <String, String>{};
    String? pick(String key) {
      final v = json[key]?.toString();
      if (v != null && v.isNotEmpty && v != 'null') return v;
      return defaults[key];
    }

    return GlobalUser(
      id: id,
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'ADMIN').toString().toUpperCase(),
      teacherId: pick('teacher_id'),
      sectionId: pick('section_id'),
      studentId: pick('student_id'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      if (teacherId != null) 'teacher_id': teacherId,
      if (sectionId != null) 'section_id': sectionId,
      if (studentId != null) 'student_id': studentId,
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
      examTypes: (json['exam_types'] as List<dynamic>?)
              ?.map((e) => ExamType.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
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

