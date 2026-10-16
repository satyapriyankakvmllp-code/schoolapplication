class SubjectModel {
  final String id;
  final String classId;
  final String name;
  final String code;
  final String? teacherId;

  const SubjectModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.code,
    this.teacherId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
        id: json['id'] as String,
        classId: json['class_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        teacherId: json['teacher_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'name': name,
        'code': code,
        'teacher_id': teacherId,
      };

  SubjectModel copyWith({
    String? name,
    String? code,
    String? teacherId,
    bool clearTeacher = false,
  }) =>
      SubjectModel(
        id: id,
        classId: classId,
        name: name ?? this.name,
        code: code ?? this.code,
        teacherId: clearTeacher ? null : (teacherId ?? this.teacherId),
      );
}
