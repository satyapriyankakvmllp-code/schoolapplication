class SectionModel {
  final String id;
  final String classId;
  final String name;
  final int capacity;
  final String? classroomId;
  final String? classTeacherId;
  final String status; // 'Active' or 'Inactive'

  const SectionModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.capacity,
    this.classroomId,
    this.classTeacherId,
    this.status = 'Active',
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
        id: json['id'] as String? ?? '',
        classId: json['class_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        classroomId: json['classroom_id'] as String?,
        classTeacherId: json['class_teacher_id'] as String?,
        status: json['status'] as String? ?? 'Active',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'name': name,
        'capacity': capacity,
        'classroom_id': classroomId,
        'class_teacher_id': classTeacherId,
        'status': status,
      };

  SectionModel copyWith({
    String? classId,
    String? name,
    int? capacity,
    String? classroomId,
    String? classTeacherId,
    String? status,
    bool clearClassroom = false,
    bool clearClassTeacher = false,
  }) =>
      SectionModel(
        id: id,
        classId: classId ?? this.classId,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
        classTeacherId: clearClassTeacher ? null : (classTeacherId ?? this.classTeacherId),
        status: status ?? this.status,
      );
}
