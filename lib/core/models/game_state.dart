class GameState {
  final String? roomId;
  final String phase;
  final int dayNumber;
  final bool isActive;
  final Map<String, int>? voteCounts;
  final String? lastAction;

  GameState({
    this.roomId,
    required this.phase,
    this.dayNumber = 0,
    this.isActive = false,
    this.voteCounts,
    this.lastAction,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      roomId: json['roomId'],
      phase: json['phase'] ?? 'WAITING',
      dayNumber: json['dayNumber'] ?? 0,
      isActive: json['isActive'] ?? false,
      voteCounts: json['voteCounts'] != null
          ? Map<String, int>.from(json['voteCounts'])
          : null,
      lastAction: json['lastAction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'phase': phase,
      'dayNumber': dayNumber,
      'isActive': isActive,
      'voteCounts': voteCounts,
      'lastAction': lastAction,
    };
  }

  GameState copyWith({
    String? roomId,
    String? phase,
    int? dayNumber,
    bool? isActive,
    Map<String, int>? voteCounts,
    String? lastAction,
  }) {
    return GameState(
      roomId: roomId ?? this.roomId,
      phase: phase ?? this.phase,
      dayNumber: dayNumber ?? this.dayNumber,
      isActive: isActive ?? this.isActive,
      voteCounts: voteCounts ?? this.voteCounts,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  bool get isNightPhase => phase == 'NIGHT';
  bool get isDayPhase => phase == 'DAY';
  bool get isVotingPhase => phase == 'VOTING';
  bool get isGameOver => phase == 'GAME_OVER';

  @override
  String toString() {
    return 'GameState(roomId: $roomId, phase: $phase, day: $dayNumber, active: $isActive)';
  }
}