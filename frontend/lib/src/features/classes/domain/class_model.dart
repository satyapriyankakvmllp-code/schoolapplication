class ClassModel {
  final String id;
  final String name;
  final int gradeLevel;
  final String academicYear;
  final String? classTeacherId;
  final String? classroomId;

  const ClassModel({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.academicYear,
    this.classTeacherId,
    this.classroomId,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        gradeLevel: (json['grade_level'] as num?)?.toInt() ?? 0,
        academicYear: json['academic_year'] as String? ?? '',
        classTeacherId: json['class_teacher_id'] as String?,
        classroomId: json['classroom_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade_level': gradeLevel,
        'academic_year': academicYear,
        'class_teacher_id': classTeacherId,
        'classroom_id': classroomId,
      };

  ClassModel copyWith({
    String? name,
    int? gradeLevel,
    String? academicYear,
    String? classTeacherId,
    String? classroomId,
    bool clearClassTeacher = false,
    bool clearClassroom = false,
  }) =>
      ClassModel(
        id: id,
        name: name ?? this.name,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        academicYear: academicYear ?? this.academicYear,
        classTeacherId: clearClassTeacher ? null : (classTeacherId ?? this.classTeacherId),
        classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
      );
}
