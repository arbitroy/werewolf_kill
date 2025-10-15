class Player {
  final String id;
  final String username;
  final String? role;
  final bool isAlive;

  Player({
    required this.id,
    required this.username,
    this.role,
    this.isAlive = true,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? json['playerId'],
      username: json['username'],
      role: json['role'],
      isAlive: json['isAlive'] ?? json['alive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'isAlive': isAlive,
    };
  }

  Player copyWith({
    String? id,
    String? username,
    String? role,
    bool? isAlive,
  }) {
    return Player(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, username: $username, role: $role, isAlive: $isAlive)';
  }
}
