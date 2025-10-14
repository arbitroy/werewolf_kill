enum Role { WEREWOLF, VILLAGER, SEER }
enum PlayerStatus { ALIVE, DEAD }

class Player {
  final String id;
  final String username;
  final Role? role; // null until revealed
  final PlayerStatus status;
  final bool isHost;

  Player({
    required this.id,
    required this.username,
    this.role,
    required this.status,
    this.isHost = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      username: json['username'],
      role: json['role'] != null ? Role.values.byName(json['role']) : null,
      status: PlayerStatus.values.byName(json['status']),
      isHost: json['isHost'] ?? false,
    );
  }

  bool get isAlive => status == PlayerStatus.ALIVE;
}
