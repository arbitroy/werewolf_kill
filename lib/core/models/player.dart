class Player {
  final String id;
  final String username;
  final String? role;
  final bool isAlive;
  final bool isHost;
  final String? avatarUrl;

  Player({
    required this.id,
    required this.username,
    this.role,
    this.isAlive = true,
    this.isHost = false,
    this.avatarUrl,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? json['playerId'] ?? '',
      username: json['username'] ?? 'Unknown',
      role: json['role'],
      isAlive: json['isAlive'] ?? json['status'] != 'DEAD',
      isHost: json['isHost'] ?? false,
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'isAlive': isAlive,
      'isHost': isHost,
      'avatarUrl': avatarUrl,
    };
  }

  Player copyWith({
    String? id,
    String? username,
    String? role,
    bool? isAlive,
    bool? isHost,
    String? avatarUrl,
  }) {
    return Player(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      isHost: isHost ?? this.isHost,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, username: $username, role: $role, isAlive: $isAlive, isHost: $isHost)';
  }
}