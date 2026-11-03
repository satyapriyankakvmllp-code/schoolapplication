/// Room lookup model for examination timetables.
class Room {
  final String roomId;
  final String roomNumber;
  final int capacity;

  const Room({
    required this.roomId,
    required this.roomNumber,
    required this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: (json['room_id'] ?? json['id'] ?? '').toString(),
      roomNumber: (json['room_number'] ?? json['name'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'room_number': roomNumber,
        'capacity': capacity,
      };
}

