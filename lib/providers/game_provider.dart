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

    // ✅ PRIORITY 1: Handle ROOM_STATE_UPDATE (most authoritative)
    _wsService.onRoomStateUpdate = (data) {
      print('📊 ROOM_STATE_UPDATE received');
      _handleRoomStateUpdate(data);
    };

    // ✅ Handle individual events (for backward compatibility)
    _wsService.onPlayerJoined = (data) {
      print('👋 Player joined event');
      // Individual events are now secondary to ROOM_STATE_UPDATE
      // Only process if we don't have full state
      if (_players.isEmpty) {
        _handlePlayerJoined(data);
      }
    };

    _wsService.onPlayerLeft = (data) {
      print('👋 Player left event');
      _handlePlayerLeft(data);
    };

    // ✅ CRITICAL: Handle HOST_CHANGED event
    _wsService.onHostChanged = (data) {
      print('👑 HOST_CHANGED event received');
      _handleHostChanged(data);
    };

    // Game events
    _wsService.onGameStarted = (data) {
      print('🎮 Game started!');
      _gameState = GameState(
        roomId: data['roomId'],
        phase: 'STARTING',
        isActive: true,
      );
      notifyListeners();
    };

    _wsService.onGameUpdate = (data) {
      print('🔄 Game update received');
      _updateGameState(data);
      notifyListeners();
    };

    _wsService.onRoleAssigned = (data) {
      print('🎭 Role assigned: ${data['role']}');
      if (_myPlayer != null && data['playerId'] == _myPlayer!.id) {
        _myPlayer = _myPlayer!.copyWith(role: data['role']);
      }
      notifyListeners();
    };

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

    _wsService.onVoteCast = (data) {
      print('🗳️ Vote cast: ${data['voterId']} -> ${data['targetId']}');
      notifyListeners();
    };

    _wsService.onPlayerDied = (data) {
      print('☠️ Player died: ${data['playerId']}');
      final playerId = data['playerId'];
      final playerIndex = _players.indexWhere((p) => p.id == playerId);
      if (playerIndex != -1) {
        _players[playerIndex] = _players[playerIndex].copyWith(isAlive: false);
      }
      notifyListeners();
    };

    _wsService.onError = (errorMsg) {
      print('❌ WebSocket error: $errorMsg');
      _error = errorMsg;
      notifyListeners();
    };
  }

  // ✅ NEW: Handle unified room state updates (most authoritative)
  void _handleRoomStateUpdate(Map<String, dynamic> data) {
    print('📊 Processing ROOM_STATE_UPDATE');

    try {
      final playersList = data['players'] as List?;

      if (playersList != null && playersList.isNotEmpty) {
        // Create new player list from the authoritative state
        _players = playersList.map((p) {
          return Player(
            id: p['playerId'] as String,
            username: p['username'] as String,
            isHost: p['isHost'] as bool? ?? false,
            isAlive: (p['status'] as String?) == 'ALIVE',
            role: p['role'] as String?,
          );
        }).toList();

        print('✅ Updated ${_players.length} players from ROOM_STATE_UPDATE');

        // Update myPlayer with current state
        if (_myPlayer != null) {
          final updatedMe = _players.firstWhere(
            (p) => p.id == _myPlayer!.id,
            orElse: () => _myPlayer!,
          );

          if (updatedMe.id == _myPlayer!.id) {
            final wasHost = _myPlayer!.isHost;
            final nowHost = updatedMe.isHost;

            _myPlayer = updatedMe;

            // Log host status changes for debugging
            if (wasHost != nowHost) {
              print('🔄 My host status changed: $wasHost -> $nowHost');
            }
          }
        }

        // Sort players - host first for display
        _players.sort((a, b) {
          if (a.isHost && !b.isHost) return -1;
          if (!a.isHost && b.isHost) return 1;
          return 0;
        });
      }

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error handling ROOM_STATE_UPDATE: $e');
      print('Stack trace: $stackTrace');
      _error = 'Failed to update room state';
      notifyListeners();
    }
  }

  // ✅ Handle HOST_CHANGED event specifically
  void _handleHostChanged(Map<String, dynamic> data) {
    print('👑 Processing HOST_CHANGED event');

    try {
      final newHostId = data['newHostId'] as String;
      final newHostUsername = data['newHostUsername'] as String;

      print('👑 New host: $newHostUsername ($newHostId)');

      // Update isHost flag for all players
      _players = _players.map((player) {
        final isNewHost = player.id == newHostId;
        if (player.isHost != isNewHost) {
          print(
            '🔄 Updating ${player.username} isHost: ${player.isHost} -> $isNewHost',
          );
        }
        return player.copyWith(isHost: isNewHost);
      }).toList();

      // Update myPlayer if I'm the new host or was the old host
      if (_myPlayer != null) {
        final wasHost = _myPlayer!.isHost;
        final nowHost = _myPlayer!.id == newHostId;

        if (wasHost != nowHost) {
          _myPlayer = _myPlayer!.copyWith(isHost: nowHost);

          if (nowHost) {
            print('🎉 YOU are now the host!');
          } else {
            print('ℹ️ You are no longer the host');
          }
        }
      }

      // Sort players - host first
      _players.sort((a, b) {
        if (a.isHost && !b.isHost) return -1;
        if (!a.isHost && b.isHost) return 1;
        return 0;
      });

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error handling HOST_CHANGED: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Handle individual player joined event (fallback)
  void _handlePlayerJoined(Map<String, dynamic> data) {
    print('👋 Processing PLAYER_JOINED event');

    final playerId = data['playerId'] as String;
    final username = data['username'] as String;
    final isHost = data['isHost'] as bool? ?? false;

    final existingIndex = _players.indexWhere((p) => p.id == playerId);

    if (existingIndex != -1) {
      _players[existingIndex] = _players[existingIndex].copyWith(
        username: username,
        isHost: isHost,
      );
      print('🔄 Updated existing player: $username');
    } else {
      _players.add(
        Player(id: playerId, username: username, isHost: isHost, isAlive: true),
      );
      print('🆕 Added new player: $username');
    }

    // Update myPlayer if this is me
    if (_myPlayer?.id == playerId) {
      _myPlayer = _myPlayer?.copyWith(isHost: isHost);
    }

    notifyListeners();
  }

  void _handlePlayerLeft(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String;
    _players.removeWhere((p) => p.id == playerId);
    print('👋 Player $playerId removed');
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
    } else if (type == 'ROOM_STATE_UPDATE') {
      _handleRoomStateUpdate(data);
    }

    // Update players if provided
    if (data['players'] != null) {
      _players = (data['players'] as List)
          .map(
            (p) => Player(
              id: p['playerId'] ?? p['id'],
              username: p['username'],
              role: p['role'],
              isAlive: p['isAlive'] ?? p['status'] == 'ALIVE',
              isHost: p['isHost'] ?? false,
            ),
          )
          .toList();
    }

    notifyListeners();
  }

  // ✅ Connect to game room via WebSocket
  Future<void> connectToRoom(String roomId, Player myPlayer) async {
    print('🔵 GameProvider: Connecting to room $roomId');
    _currentRoomId = roomId;
    _myPlayer = myPlayer;

    // Clear players - wait for ROOM_STATE_UPDATE from backend
    _players.clear();

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
  Future<bool> startGame() async {
    if (_currentRoomId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.startGame(_currentRoomId!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Failed to start game: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
