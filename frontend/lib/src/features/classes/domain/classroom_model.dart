class ClassroomModel {
  static const List<String> roomTypes = ['Lecture Hall', 'Theory', 'Practical'];
  static const List<String> roomStatuses = ['Assigned', 'Unassigned'];

  final String id;
  final String name; // RoomNo, e.g. "Room 101"
  final String building;
  final int capacity;

  /// Optional extras (additive; older classes.json rows simply omit them).
  final String floor;
  final String roomType; // Lecture Hall | Theory | Practical
  final String
  status; // Assigned | Unassigned | Unavailable (legacy availability)

  const ClassroomModel({
    required this.id,
    required this.name,
    required this.building,
    required this.capacity,
    this.floor = '',
    this.roomType = 'Theory',
    this.status = 'Unassigned',
  });

  bool get isAvailable =>
      status.toLowerCase() != 'unavailable' &&
      status.toLowerCase() != 'not available';

  /// Comparable room number: "Room 101", "room-101" and "101" all become "101".
  static String normalizeNumber(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'\broom\b|[\s\-_.#]'), '');

  String get normalizedNumber => normalizeNumber(name);

  /// Floor shown in the UI: explicit floor, else parsed from the legacy building text "(1st Floor)".
  String get displayFloor {
    if (floor.trim().isNotEmpty) return floor.trim();
    final m = RegExp(
      r'\(([^)]*floor[^)]*)\)',
      caseSensitive: false,
    ).firstMatch(building);
    return m?.group(1)?.trim() ?? '—';
  }

  factory ClassroomModel.fromJson(Map<String, dynamic> json) => ClassroomModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    building: json['building'] as String? ?? '',
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    floor: json['floor'] as String? ?? '',
    roomType: json['room_type'] as String? ?? 'Theory',
    status: json['status'] as String? ?? 'Available',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'building': building,
    'capacity': capacity,
    'floor': floor,
    'room_type': roomType,
    'status': status,
  };

  ClassroomModel copyWith({
    String? name,
    String? building,
    int? capacity,
    String? floor,
    String? roomType,
    String? status,
  }) => ClassroomModel(
    id: id,
    name: name ?? this.name,
    building: building ?? this.building,
    capacity: capacity ?? this.capacity,
    floor: floor ?? this.floor,
    roomType: roomType ?? this.roomType,
    status: status ?? this.status,
  );
}
