class Room {
  final String id;
  final String name;
  final String createdBy;  // ✅ Changed from hostId
  final int maxPlayers;
  final int currentPlayers;  // Optional - from session data
  final String status;       // Optional - from session data
  final String? gameMode;
  final bool? isPublic;
  final String? createdAt;

  Room({
    required this.id,
    required this.name,
    required this.createdBy,  // ✅ Changed from hostId
    this.maxPlayers = 8,
    this.currentPlayers = 0,
    this.status = 'WAITING',
    this.gameMode,
    this.isPublic,
    this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String,  // ✅ Changed from hostId
      maxPlayers: json['maxPlayers'] as int? ?? 8,
      // Optional fields - only present if session exists
      currentPlayers: json['currentPlayers'] as int? ?? 0,
      status: json['status'] as String? ?? 'WAITING',
      gameMode: json['gameMode'] as String?,
      isPublic: json['isPublic'] as bool?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,  // ✅ Changed from hostId
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'status': status,
      'gameMode': gameMode,
      'isPublic': isPublic,
      'createdAt': createdAt,
    };
  }

  bool get isFull => currentPlayers >= maxPlayers;
  bool get canStart => currentPlayers >= 3;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, createdBy: $createdBy, players: $currentPlayers/$maxPlayers, status: $status)';
  }
  
  // Helper method to check if current user is creator
  bool isCreator(String userId) {
    return createdBy == userId;
  }
}