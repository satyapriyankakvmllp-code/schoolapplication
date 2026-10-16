class ClassroomModel {
  final String id;
  final String name;
  final String building;
  final int capacity;

  const ClassroomModel({
    required this.id,
    required this.name,
    required this.building,
    required this.capacity,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) => ClassroomModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        building: json['building'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'building': building,
        'capacity': capacity,
      };

  ClassroomModel copyWith({String? name, String? building, int? capacity}) => ClassroomModel(
        id: id,
        name: name ?? this.name,
        building: building ?? this.building,
        capacity: capacity ?? this.capacity,
      );
}
