class Room {
  final String id;
  final String name;
  final String hostId;
  final int maxPlayers;
  final int currentPlayers;
  final String status; // WAITING, IN_PROGRESS, FINISHED

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      hostId: json['hostId'],
      maxPlayers: json['maxPlayers'],
      currentPlayers: json['currentPlayers'],
      status: json['status'],
    );
  }
}
