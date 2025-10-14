import 'player.dart';

enum GamePhase { WAITING, NIGHT, DAY, VOTING, GAME_OVER }

class GameState {
  final String roomId;
  final GamePhase phase;
  final List<Player> players;
  final int timeRemaining; // seconds
  final String? lastEvent;
  final Map<String, int> votes; // playerId -> targetPlayerId
  final String? winner; // WEREWOLVES or VILLAGERS

  GameState({
    required this.roomId,
    required this.phase,
    required this.players,
    this.timeRemaining = 0,
    this.lastEvent,
    this.votes = const {},
    this.winner,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      roomId: json['roomId'],
      phase: GamePhase.values.byName(json['phase']),
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      timeRemaining: json['timeRemaining'] ?? 0,
      lastEvent: json['lastEvent'],
      votes: Map<String, int>.from(json['votes'] ?? {}),
      winner: json['winner'],
    );
  }

  bool get isDay => phase == GamePhase.DAY || phase == GamePhase.VOTING;
  bool get isNight => phase == GamePhase.NIGHT;
  bool get isGameOver => phase == GamePhase.GAME_OVER;
}