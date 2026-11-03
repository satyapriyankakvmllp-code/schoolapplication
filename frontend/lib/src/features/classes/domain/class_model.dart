class ClassModel {
  final String id;
  final String name;
  final String code;
  final int gradeLevel;
  final String academicYear;
  final String status; // 'Active' or 'Inactive'
  final String? classTeacherId;
  final String? classroomId;

  /// Optional counts typed in the Create Class form. The Class List prefers
  /// counts calculated from live data and only falls back to these.
  final int? subjectCount;
  final int? studentCount;
  final int? teacherCount;
  final String subject;
  final int capacity;
  final Map<String, String> customFields;

  const ClassModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.gradeLevel,
    required this.academicYear,
    this.status = 'Active',
    this.classTeacherId,
    this.classroomId,
    this.subjectCount,
    this.studentCount,
    this.teacherCount,
    this.subject = '',
    this.capacity = 0,
    this.customFields = const {},
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final grade = (json['grade_level'] as num?)?.toInt() ?? 0;
    final fallbackCode = json['id'] != null && (json['id'] as String).isNotEmpty
        ? (json['id'] as String).toUpperCase().replaceAll('CLS-', 'CLS-')
        : 'CLS-${grade > 0 ? grade : 1}';

    return ClassModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? fallbackCode,
      gradeLevel: grade,
      academicYear: json['academic_year'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      classTeacherId: json['class_teacher_id'] as String?,
      classroomId: json['classroom_id'] as String?,
      subjectCount: (json['subject_count'] as num?)?.toInt(),
      studentCount: (json['student_count'] as num?)?.toInt(),
      teacherCount: (json['teacher_count'] as num?)?.toInt(),
      subject: json['subject'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      customFields: (json['custom_fields'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code.isNotEmpty ? code : 'CLS-$gradeLevel',
        'grade_level': gradeLevel,
        'academic_year': academicYear,
        'status': status,
        'class_teacher_id': classTeacherId,
        'classroom_id': classroomId,
        'subject_count': subjectCount,
        'student_count': studentCount,
        'teacher_count': teacherCount,
        'subject': subject,
        'capacity': capacity,
        'custom_fields': customFields,
      };

  ClassModel copyWith({
    String? name,
    String? code,
    int? gradeLevel,
    String? academicYear,
    String? status,
    String? classTeacherId,
    String? classroomId,
    int? subjectCount,
    int? studentCount,
    int? teacherCount,
    String? subject,
    int? capacity,
    Map<String, String>? customFields,
    bool clearClassTeacher = false,
    bool clearClassroom = false,
  }) =>
      ClassModel(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        academicYear: academicYear ?? this.academicYear,
        status: status ?? this.status,
        classTeacherId: clearClassTeacher ? null : (classTeacherId ?? this.classTeacherId),
        classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
        subjectCount: subjectCount ?? this.subjectCount,
        studentCount: studentCount ?? this.studentCount,
        teacherCount: teacherCount ?? this.teacherCount,
        subject: subject ?? this.subject,
        capacity: capacity ?? this.capacity,
        customFields: customFields ?? this.customFields,
      );
}
