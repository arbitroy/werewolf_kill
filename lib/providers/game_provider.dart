import 'package:flutter/foundation.dart';
import '../core/models/game_state.dart';
import '../core/models/player.dart';
import '../core/services/api_service.dart';
import '../core/services/websocket_service.dart';

class GameProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  GameState? _gameState;
  List<Player> _players = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRoomId;
  Player? _myPlayer;
  ConnectionState _wsConnectionState = ConnectionState.disconnected;

  // Getters
  GameState? get gameState => _gameState;
  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRoomId => _currentRoomId;
  Player? get myPlayer => _myPlayer;
  ConnectionState get wsConnectionState => _wsConnectionState;
  bool get isConnected => _wsConnectionState == ConnectionState.connected;

  GameProvider() {
    _setupWebSocketCallbacks();
  }

  void _setupWebSocketCallbacks() {
    // Connection state changes
    _wsService.onConnectionStateChanged = (state) {
      print('🔍 Connection state changed to: $state');
      _wsConnectionState = state;
      notifyListeners();
    };

    // Player joined room
    _wsService.onPlayerJoined = (data) {
      print('🔍 GameProvider: onPlayerJoined called with data: $data');
      print('🔍 Current players before add: ${_players.length}');
      print(
        '🔍 isHost value: ${data['isHost']} (type: ${data['isHost'].runtimeType})',
      );

      final playerId = data['playerId'] as String;

      // Don't add if player already exists
      if (_players.any((p) => p.id == playerId)) {
        print('🔍 Player already in list, skipping');
        return;
      }

      final newPlayer = Player(
        id: playerId,
        username: data['username'] as String,
        isHost: data['isHost'] == true, // Explicit boolean check
      );

      print(
        '🔍 Created player: ${newPlayer.username}, isHost: ${newPlayer.isHost}',
      );
      _players.add(newPlayer);
      print('🔍 Current players after add: ${_players.length}');
      notifyListeners();
    };

    // Player left room
    _wsService.onPlayerLeft = (data) {
      print('Player left: ${data['playerId']}');
      _players.removeWhere((p) => p.id == data['playerId']);
      notifyListeners();
    };

    // Game started
    _wsService.onGameStarted = (data) {
      print('Game started!');
      _gameState = GameState(
        roomId: data['roomId'],
        phase: 'STARTING',
        isActive: true,
      );
      notifyListeners();
    };

    // Game update
    _wsService.onGameUpdate = (data) {
      print('Game update received');
      _updateGameState(data);
      notifyListeners();
    };

    // Role assigned
    _wsService.onRoleAssigned = (data) {
      print('Role assigned: ${data['role']}');
      if (_myPlayer != null && data['playerId'] == _myPlayer!.id) {
        _myPlayer = Player(
          id: _myPlayer!.id,
          username: _myPlayer!.username,
          role: data['role'],
          isAlive: true,
          isHost: _myPlayer!.isHost,
        );
      }
      notifyListeners();
    };

    // Phase change
    _wsService.onPhaseChange = (data) {
      print('Phase changed to: ${data['phase']}');
      if (_gameState != null) {
        _gameState = GameState(
          roomId: _gameState!.roomId,
          phase: data['phase'],
          dayNumber: data['dayNumber'] ?? _gameState!.dayNumber,
          isActive: true,
        );
      }
      notifyListeners();
    };

    // Vote cast
    _wsService.onVoteCast = (data) {
      print('Vote cast: ${data['voterId']} -> ${data['targetId']}');
      notifyListeners();
    };

    // Player died
    _wsService.onPlayerDied = (data) {
      print('Player died: ${data['playerId']}');
      final playerId = data['playerId'];
      final playerIndex = _players.indexWhere((p) => p.id == playerId);
      if (playerIndex != -1) {
        _players[playerIndex] = Player(
          id: _players[playerIndex].id,
          username: _players[playerIndex].username,
          role: _players[playerIndex].role,
          isAlive: false,
          isHost: _players[playerIndex].isHost,
        );
      }
      notifyListeners();
    };

    // Errors
    _wsService.onError = (errorMsg) {
      print('WebSocket error: $errorMsg');
      _error = errorMsg;
      notifyListeners();
    };
  }

  void _updateGameState(Map<String, dynamic> data) {
    _gameState = GameState(
      roomId: data['roomId'] ?? _currentRoomId,
      phase: data['phase'] ?? _gameState?.phase ?? 'WAITING',
      dayNumber: data['dayNumber'] ?? _gameState?.dayNumber ?? 0,
      isActive: data['isActive'] ?? true,
    );

    // Update players if provided
    if (data['players'] != null) {
      _players = (data['players'] as List)
          .map(
            (p) => Player(
              id: p['id'],
              username: p['username'],
              role: p['role'],
              isAlive: p['isAlive'] ?? true,
            ),
          )
          .toList();
    }
  }

  // Connect to game room via WebSocket
Future<void> connectToRoom(String roomId, Player myPlayer) async {
  print('🔵 GameProvider: Connecting to room $roomId');
  _currentRoomId = roomId;
  _myPlayer = myPlayer;
  
  // Clear existing players and add self
  _players.clear();
  _players.add(myPlayer);
  
  // Use serverUrl (without /api) for WebSocket
  final connectionUrl = _apiService.serverUrl;
  print('🔍 WebSocket server URL: $connectionUrl');
  
  // Connect to WebSocket with player information
  _wsService.connect(roomId, myPlayer.id, myPlayer.username, connectionUrl);
  
  notifyListeners();
}
  // Disconnect from WebSocket
  void disconnectFromRoom() {
    _wsService.disconnect();
    _currentRoomId = null;
    _players.clear();
    _gameState = null;
  }

  // Start game (REST API call, server will broadcast via WebSocket)
  Future<bool> startGame(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.startGame(roomId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Vote (can use WebSocket or REST API)
  Future<bool> vote(String roomId, String voterId, String targetId) async {
    try {
      // Option 1: Send via WebSocket for real-time feedback
      _wsService.sendVote(roomId, voterId, targetId);

      // Option 2: Also call REST API for persistence
      // await _apiService.vote(roomId, voterId, targetId);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Night action (WebWolf or Seer)
  Future<bool> nightAction(
    String roomId,
    String actorId,
    String targetId,
    String action,
  ) async {
    try {
      _wsService.sendNightAction(roomId, actorId, targetId, action);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}
