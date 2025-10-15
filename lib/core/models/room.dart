class Room {
  final String id;
  final String name;
  final String hostId;
  final int maxPlayers;
  final int currentPlayers;
  final String status;

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    this.maxPlayers = 8,
    this.currentPlayers = 0,
    this.status = 'WAITING',
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      hostId: json['hostId'],
      maxPlayers: json['maxPlayers'] ?? 8,
      currentPlayers: json['currentPlayers'] ?? 0,
      status: json['status'] ?? 'WAITING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'status': status,
    };
  }

  bool get isFull => currentPlayers >= maxPlayers;
  bool get canStart => currentPlayers >= 3;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, players: $currentPlayers/$maxPlayers, status: $status)';
  }
}