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

      final playerId = data['playerId'] as String;
      final username = data['username'] as String;
      final isHost = data['isHost'] == true;

      // Check if player exists and UPDATE them
      final existingIndex = _players.indexWhere((p) => p.id == playerId);

      if (existingIndex != -1) {
        // Player exists - UPDATE their data
        print('🔄 Player exists, updating: $username, isHost: $isHost');
        _players[existingIndex] = _players[existingIndex].copyWith(
          username: username,
          isHost: isHost,
        );
      } else {
        // New player - ADD them
        print('🆕 New player added: $username, isHost: $isHost');
        _players.add(Player(
          id: playerId,
          username: username,
          isHost: isHost,
        ));
      }

      // Update myPlayer if this is me
      if (_myPlayer?.id == playerId) {
        print('🔄 Updating myPlayer isHost status: $isHost');
        _myPlayer = _myPlayer?.copyWith(isHost: isHost);
      }

      print('🔍 Current players after processing: ${_players.length}');
      notifyListeners();
    };

    // Player left room
    _wsService.onPlayerLeft = (data) {
      print('👋 Player left: ${data['playerId']}');
      _players.removeWhere((p) => p.id == data['playerId']);
      notifyListeners();
    };

    // Game started
    _wsService.onGameStarted = (data) {
      print('🎮 Game started!');
      _gameState = GameState(
        roomId: data['roomId'],
        phase: 'STARTING',
        isActive: true,
      );
      notifyListeners();
    };

    // Game update
    _wsService.onGameUpdate = (data) {
      print('🔄 Game update received');
      _updateGameState(data);
      notifyListeners();
    };

    // Role assigned
    _wsService.onRoleAssigned = (data) {
      print('🎭 Role assigned: ${data['role']}');
      if (_myPlayer != null && data['playerId'] == _myPlayer!.id) {
        _myPlayer = _myPlayer!.copyWith(role: data['role']);
      }
      notifyListeners();
    };

    // Phase change
    _wsService.onPhaseChange = (data) {
      print('🌓 Phase changed to: ${data['phase']}');
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
      print('🗳️ Vote cast: ${data['voterId']} -> ${data['targetId']}');
      notifyListeners();
    };

    // Player died
    _wsService.onPlayerDied = (data) {
      print('☠️ Player died: ${data['playerId']}');
      final playerId = data['playerId'];
      final playerIndex = _players.indexWhere((p) => p.id == playerId);
      if (playerIndex != -1) {
        _players[playerIndex] = _players[playerIndex].copyWith(isAlive: false);
      }
      notifyListeners();
    };

    // Errors
    _wsService.onError = (errorMsg) {
      print('❌ WebSocket error: $errorMsg');
      _error = errorMsg;
      notifyListeners();
    };
  }

  void _handleHostChanged(Map<String, dynamic> data) {
    print('👑 HOST CHANGED EVENT');
    final newHostId = data['newHostId'] as String;
    final newHostUsername = data['newHostUsername'] as String;

    print('New host: $newHostUsername ($newHostId)');

    // Update isHost flag for all players
    _players = _players.map((player) {
      return player.copyWith(isHost: player.id == newHostId);
    }).toList();

    // Update myPlayer if I'm the new host
    if (_myPlayer?.id == newHostId) {
      _myPlayer = _myPlayer?.copyWith(isHost: true);
    }

    notifyListeners();
  }

  void _handlePlayersList(Map<String, dynamic> data) {
    print('📋 RECEIVED FULL PLAYERS LIST');
    final playersList = data['players'] as List?;

    if (playersList == null) {
      print('❌ Players list is null');
      return;
    }

    _players = playersList.map((p) {
      final player = Player.fromJson(p);
      print('👤 Player from list: ${player.username}, isHost: ${player.isHost}');
      return player;
    }).toList();

    // Update myPlayer if found in list
    final myPlayerInList = _players.firstWhere(
      (p) => p.id == _myPlayer?.id,
      orElse: () => _myPlayer!,
    );

    if (myPlayerInList.id == _myPlayer?.id) {
      print('🔄 Updating myPlayer from list, isHost: ${myPlayerInList.isHost}');
      _myPlayer = myPlayerInList;
    }

    print('✅ Players loaded: ${_players.length}');
    notifyListeners();
  }

  void _updateGameState(Map<String, dynamic> data) {
    _gameState = GameState(
      roomId: data['roomId'] ?? _currentRoomId,
      phase: data['phase'] ?? _gameState?.phase ?? 'WAITING',
      dayNumber: data['dayNumber'] ?? _gameState?.dayNumber ?? 0,
      isActive: data['isActive'] ?? true,
    );

    final type = data['type'] as String?;

    if (type == 'HOST_CHANGED') {
      _handleHostChanged(data);
    } else if (type == 'PLAYERS_LIST') {
      _handlePlayersList(data);
    }

    // Update players if provided
    if (data['players'] != null) {
      _players = (data['players'] as List)
          .map((p) => Player(
                id: p['id'],
                username: p['username'],
                role: p['role'],
                isAlive: p['isAlive'] ?? true,
              ))
          .toList();
    }
  }

  // ✅ Connect to game room via WebSocket
  Future<void> connectToRoom(String roomId, Player myPlayer) async {
    print('🔵 GameProvider: Connecting to room $roomId');
    _currentRoomId = roomId;
    _myPlayer = myPlayer;

    // Clear players - wait for PLAYERS_LIST from backend
    _players.clear();

    // Use serverUrl (without /api) for WebSocket
    final connectionUrl = _apiService.serverUrl;
    print('🔍 WebSocket server URL: $connectionUrl');

    // Connect to WebSocket with player information
    _wsService.connect(roomId, myPlayer.id, myPlayer.username, connectionUrl);

    notifyListeners();
  }

  // ✅ Disconnect from WebSocket
  void disconnectFromRoom() {
    print('🔌 Disconnecting from room');
    _wsService.disconnect();
    _currentRoomId = null;
    _players.clear();
    _gameState = null;
    _myPlayer = null;
    notifyListeners();
  }

  // Start game (REST API call, server will broadcast via WebSocket)
  Future<bool> startGame(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Starting game: $roomId');
      await _apiService.startGame(roomId);
      print('✅ Game start request sent');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Start game error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Vote (can use WebSocket or REST API)
  Future<bool> vote(String roomId, String voterId, String targetId) async {
    try {
      print('🔵 Casting vote: $voterId -> $targetId');
      // Option 1: Send via WebSocket for real-time feedback
      _wsService.sendVote(roomId, voterId, targetId);

      // Option 2: Also call REST API for persistence
      // await _apiService.vote(roomId, voterId, targetId);

      return true;
    } catch (e) {
      print('❌ Vote error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Night action (Werewolf or Seer)
  Future<bool> nightAction(
    String roomId,
    String actorId,
    String targetId,
    String action,
  ) async {
    try {
      print('🔵 Night action: $action on $targetId');
      _wsService.sendNightAction(roomId, actorId, targetId, action);
      return true;
    } catch (e) {
      print('❌ Night action error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Set token
  void setToken(String token) {
    _apiService.setToken(token);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _gameState = null;
    _players.clear();
    _currentRoomId = null;
    _myPlayer = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}