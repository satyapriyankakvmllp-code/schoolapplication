class SubjectModel {
  final String id;
  final String classId;
  final String name;
  final String code;
  final String type; // 'Theory' or 'Practical'
  final String? syllabus;
  final String? teacherId;
  final int maxMarks;
  final int passMarks;

  const SubjectModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.code,
    this.type = 'Theory',
    this.syllabus,
    this.teacherId,
    this.maxMarks = 100,
    this.passMarks = 35,
  });

  bool get isPractical => type.toLowerCase() == 'practical';

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
        id: json['id'] as String? ?? '',
        classId: json['class_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        type: json['type'] as String? ?? 'Theory',
        syllabus: json['syllabus'] as String?,
        teacherId: json['teacher_id'] as String?,
        maxMarks: (json['max_marks'] as num?)?.toInt() ?? 100,
        passMarks: (json['pass_marks'] as num?)?.toInt() ?? 35,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'name': name,
        'code': code,
        'type': type,
        if (syllabus != null) 'syllabus': syllabus,
        'teacher_id': teacherId,
        'max_marks': maxMarks,
        'pass_marks': passMarks,
      };

  SubjectModel copyWith({
    String? classId,
    String? name,
    String? code,
    String? type,
    String? syllabus,
    String? teacherId,
    int? maxMarks,
    int? passMarks,
    bool clearTeacher = false,
    bool clearSyllabus = false,
  }) =>
      SubjectModel(
        id: id,
        classId: classId ?? this.classId,
        name: name ?? this.name,
        code: code ?? this.code,
        type: type ?? this.type,
        syllabus: clearSyllabus ? null : (syllabus ?? this.syllabus),
        teacherId: clearTeacher ? null : (teacherId ?? this.teacherId),
        maxMarks: maxMarks ?? this.maxMarks,
        passMarks: passMarks ?? this.passMarks,
      );
}
