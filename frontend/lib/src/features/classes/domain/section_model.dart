class SectionModel {
  final String id;
  final String classId;
  final String name;
  final int capacity;
  final String? classroomId;

  const SectionModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.capacity,
    this.classroomId,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
        id: json['id'] as String,
        classId: json['class_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        classroomId: json['classroom_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'name': name,
        'capacity': capacity,
        'classroom_id': classroomId,
      };

  SectionModel copyWith({
    String? name,
    int? capacity,
    String? classroomId,
    bool clearClassroom = false,
  }) =>
      SectionModel(
        id: id,
        classId: classId,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
      );
}
