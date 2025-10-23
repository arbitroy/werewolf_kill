import 'dart:async';

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
  String? _selectedTargetId;
  bool _hasActedTonight = false;
  bool _hasVoted = false;
  final Map<String, int> _voteCount = {};
  String? _lastActionResult;
  String? _seerResult;
  bool _isHunterRevengeActive = false;
  bool _amITheHunter = false;
  List<Map<String, dynamic>> _hunterTargets = [];
  int _hunterRevengeSecondsRemaining = 0;
  Timer? _hunterRevengeTimer;
  String? _gameOverWinner;
  dynamic _gameOverResults;

  // Getters
  GameState? get gameState => _gameState;
  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRoomId => _currentRoomId;
  Player? get myPlayer => _myPlayer;
  ConnectionState get wsConnectionState => _wsConnectionState;
  bool get isConnected => _wsConnectionState == ConnectionState.connected;
  String? get selectedTargetId => _selectedTargetId;
  bool get hasActedTonight => _hasActedTonight;
  bool get hasVoted => _hasVoted;
  Map<String, int> get voteCount => _voteCount;
  String? get lastActionResult => _lastActionResult;
  String? get seerResult => _seerResult;
  bool get isHunterRevengeActive => _isHunterRevengeActive;
  bool get amITheHunter => _amITheHunter;
  List<Map<String, dynamic>> get hunterTargets => _hunterTargets;
  int get hunterRevengeSecondsRemaining => _hunterRevengeSecondsRemaining;
  String? get gameOverWinner => _gameOverWinner;
  dynamic get gameOverResults => _gameOverResults;

  Function(String role, String description)? onShowRoleReveal;

  GameProvider() {
    _setupWebSocketCallbacks();
  }

  void setToken(String token) {
    _apiService.setToken(token);
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
      final playerId = data['playerId'] as String?;

      if (_myPlayer != null && playerId == _myPlayer!.id) {
        final role = data['role'] as String;
        _myPlayer = _myPlayer!.copyWith(role: role);
        print('✅ My role updated to: ${_myPlayer!.role}');
      }
      notifyListeners();
    };

    _wsService.onPhaseChange = (data) {
      print('🌓 Phase changed to: ${data['phase']}');
      print('   Duration: ${data['duration']}s');
      print('   End time: ${data['phaseEndTime']}');

      // Reset action flags
      if (data['phase'] == 'NIGHT') {
        _hasActedTonight = false;
        _hasVoted = false;
      } else if (data['phase'] == 'VOTING') {
        _hasVoted = false;
      }

      // ✅ Update game state with timer info
      _gameState = GameState(
        roomId: _gameState?.roomId ?? _currentRoomId,
        phase: data['phase'],
        dayNumber: data['dayNumber'] ?? _gameState?.dayNumber ?? 0,
        isActive: true,
        phaseDuration: data['duration'] as int?, // ✅ NEW
        phaseEndTime: data['phaseEndTime'] as int?, // ✅ NEW
      );

      _wsService.onHunterRevengeTriggered = (data) {
        print('🎯 Hunter revenge triggered');
        _isHunterRevengeActive = true;

        final deadline = data['deadline'] as int?;
        if (deadline != null) {
          _startHunterRevengeCountdown(deadline);
        }

        notifyListeners();
      };

      // ✅ Hunter revenge prompt (private to hunter)
      _wsService.onHunterRevengePrompt = (data) {
        print('🎯 I am the hunter! Choosing revenge target...');
        _amITheHunter = true;
        _hunterTargets = List<Map<String, dynamic>>.from(
          data['availableTargets'] ?? [],
        );

        final deadline = data['deadline'] as int?;
        if (deadline != null) {
          _startHunterRevengeCountdown(deadline);
        }

        notifyListeners();
      };

      // ✅ Hunter revenge executed
      _wsService.onHunterRevengeExecuted = (data) {
        print('🎯 Hunter revenge executed on ${data['targetName']}');
        _clearHunterRevengeState();
        notifyListeners();
      };

      // ✅ Hunter revenge timeout
      _wsService.onHunterRevengeTimeout = (data) {
        print('⏰ Hunter revenge timed out');
        _clearHunterRevengeState();
        notifyListeners();
      };

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

    // ✅ NEW: Action confirmation callback
    _wsService.onActionConfirmed = (data) {
      print('✅ Action confirmed: ${data['action']}');
      _hasActedTonight = true; // ✅ Now set it
      _lastActionResult = 'Action confirmed!';
      notifyListeners();

      // Clear message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        _lastActionResult = null;
        notifyListeners();
      });
    };

    // ✅ NEW: Seer result callback
    _wsService.onSeerResult = (data) {
      print('🔮 Seer result received');
      final targetName = data['targetName'] as String?;
      final isWerewolf = data['isWerewolf'] as bool?;

      if (targetName != null && isWerewolf != null) {
        _seerResult = isWerewolf
            ? '🐺 $targetName is a WEREWOLF!'
            : '✅ $targetName is NOT a werewolf';
        _hasActedTonight = true;
        notifyListeners();

        // Clear after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          _seerResult = null;
          notifyListeners();
        });
      }
    };

    // ✅ NEW: Werewolf vote callback (for werewolves to see each other's votes)
    _wsService.onWerewolfVote = (data) {
      print('🐺 Werewolf vote: ${data['voterName']} → ${data['targetId']}');
      notifyListeners();
    };

    // ✅ NEW: Vote count update callback
    _wsService.onVoteCountUpdate = (data) {
      print('🗳️ Vote count updated');
      final votesReceived = data['votesReceived'] as int?;
      final totalPlayers = data['totalPlayers'] as int?;

      if (votesReceived != null && totalPlayers != null) {
        print('   $votesReceived/$totalPlayers players have voted');
      }
      notifyListeners();
    };

    // ✅ NEW: Night result callback
    _wsService.onNightResult = (data) {
      print('🌙 Night result: ${data['message']}');
      _lastActionResult = data['message'] as String?;
      notifyListeners();

      // Clear after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        _lastActionResult = null;
        notifyListeners();
      });
    };

    // ✅ NEW: Vote result callback
    _wsService.onVoteResult = (data) {
      print('🗳️ Vote result: ${data['message']}');
      _lastActionResult = data['message'] as String?;
      notifyListeners();

      // Clear after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        _lastActionResult = null;
        notifyListeners();
      });
    };

    // ✅ UPDATE: Enhanced phase change handler
    _wsService.onPhaseChange = (data) {
      print('🌓 Phase changed to: ${data['phase']}');

      // Extract timer data from backend
      int? duration = data['duration'] as int?;
      int? phaseEndTime = data['phaseEndTime'] as int?;

      // ✅ DEFENSIVE PROGRAMMING: Calculate fallback timer if missing
      if (duration == null || phaseEndTime == null) {
        print('⚠️ WARNING: Backend did not send timer data');
        print('   Calculating fallback timer based on phase type');

        // Use standard phase durations as fallback
        switch (data['phase'].toString().toUpperCase()) {
          case 'STARTING':
            duration = 5;
            print('   → Using fallback: 5 seconds for STARTING');
            break;
          case 'NIGHT':
            duration = 60;
            print('   → Using fallback: 60 seconds for NIGHT');
            break;
          case 'DAY':
            duration = 120;
            print('   → Using fallback: 120 seconds for DAY');
            break;
          case 'VOTING':
            duration = 60;
            print('   → Using fallback: 60 seconds for VOTING');
            break;
          default:
            duration = 30; // Generic fallback
            print('   → Using generic fallback: 30 seconds');
        }

        // Calculate end time from now + duration
        phaseEndTime =
            DateTime.now().millisecondsSinceEpoch + (duration * 1000);
        print('   → Calculated phaseEndTime: $phaseEndTime');
      } else {
        print('   ✅ Timer data received from backend');
        print('   Duration: ${duration}s');
        print('   End time: $phaseEndTime');
      }

      // Reset action flags on phase change
      if (data['phase'] == 'NIGHT') {
        _hasActedTonight = false;
        _hasVoted = false;
        print('   Reset night action flags');
      } else if (data['phase'] == 'VOTING') {
        _hasVoted = false;
        print('   Reset voting flag');
      }

      // ✅ Update game state with guaranteed timer data
      _gameState = GameState(
        roomId: _gameState?.roomId ?? _currentRoomId,
        phase: data['phase'],
        dayNumber: data['dayNumber'] ?? _gameState?.dayNumber ?? 0,
        isActive: true,
        phaseDuration: duration, // ✅ Will never be null now
        phaseEndTime: phaseEndTime, // ✅ Will never be null now
      );

      _selectedTargetId = null;
      notifyListeners();

      print('✅ Phase change complete: ${data['phase']} (${duration}s)');
    };

    _wsService.onRoleAssigned = (data) {
      print('🎭 Role assigned: ${data['role']}');
      if (_myPlayer != null && data['playerId'] == _myPlayer!.id) {
        final role = data['role'] as String;
        final roleDescription = data['roleDescription'] as String? ?? '';

        _myPlayer = _myPlayer!.copyWith(role: role);

        // ✅ Trigger role reveal UI
        onShowRoleReveal?.call(role, roleDescription);
      }
      notifyListeners();
    };

    // ✅ ADD THIS:
    _wsService.onGameOver = (data) {
      print('🎮 GAME OVER! Winner: ${data['winner']}');

      if (_gameState != null) {
        _gameState = GameState(
          roomId: _gameState!.roomId,
          phase: 'GAME_OVER',
          dayNumber: data['totalDays'] ?? _gameState!.dayNumber,
          isActive: false,
        );
      }

      // Show dialog or navigate to game over screen
      _showGameOverAlert(data['winner'], data['finalResults']);

      notifyListeners();
    };

    // ✅ ADD THIS:
    _wsService.onNightResult = (data) {
      print('🌙 Night result: ${data['message']}');
      _lastActionResult = data['message'] as String?;
      notifyListeners();
    };
  }

  void _showGameOverAlert(String? winner, dynamic results) {
    // This triggers UI update
    _gameOverWinner = winner;
    _gameOverResults = results;
    notifyListeners();
  }

  void _startHunterRevengeCountdown(int deadlineMs) {
    _hunterRevengeTimer?.cancel();

    void updateCountdown() {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((deadlineMs - now) / 1000).round();
      _hunterRevengeSecondsRemaining = remaining > 0 ? remaining : 0;

      if (_hunterRevengeSecondsRemaining <= 0) {
        _hunterRevengeTimer?.cancel();
      }

      notifyListeners();
    }

    updateCountdown();
    _hunterRevengeTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) => updateCountdown(),
    );
  }

  void _clearHunterRevengeState() {
    _isHunterRevengeActive = false;
    _amITheHunter = false;
    _hunterTargets.clear();
    _hunterRevengeSecondsRemaining = 0;
    _hunterRevengeTimer?.cancel();
  }

  // ✅ NEW: Submit hunter revenge
  Future<void> submitHunterRevenge(String targetId) async {
    if (_currentRoomId == null || _myPlayer == null) {
      _error = 'Not in a game';
      notifyListeners();
      return;
    }

    try {
      print('🎯 Submitting hunter revenge on $targetId');

      await _apiService.hunterRevenge(_currentRoomId!, _myPlayer!.id, targetId);

      print('✅ Hunter revenge submitted');
    } catch (e) {
      print('❌ Failed to submit hunter revenge: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ✅ NEW: Handle unified room state updates (most authoritative)
  void _handleRoomStateUpdate(Map<String, dynamic> data) {
    print('📊 Processing ROOM_STATE_UPDATE');

    try {
      final currentPhase = data['currentPhase'] as String?;
      if (currentPhase != null && _gameState != null) {
        _gameState = GameState(
          roomId: _gameState!.roomId,
          phase: currentPhase,
          dayNumber: data['dayNumber'] ?? _gameState!.dayNumber,
          isActive: true,
        );
      }

      final playersList = data['players'] as List<dynamic>?;

      if (playersList != null && playersList.isNotEmpty) {
        // Create new player list from the authoritative state
        _players = playersList.map((p) {
          return Player(
            id: p['playerId'] as String,
            username: p['username'] as String,
            isHost: p['isHost'] as bool? ?? false,
            isAlive: (p['status'] as String?) == 'ALIVE',
            role:
                p['role'] as String?, // This will be null in public broadcasts
          );
        }).toList();

        print('✅ Updated ${_players.length} players from ROOM_STATE_UPDATE');

        // ✅ FIX: Update myPlayer while PRESERVING the role
        if (_myPlayer != null) {
          final updatedMe = _players.firstWhere(
            (p) => p.id == _myPlayer!.id,
            orElse: () => _myPlayer!,
          );

          if (updatedMe.id == _myPlayer!.id) {
            final wasHost = _myPlayer!.isHost;
            final nowHost = updatedMe.isHost;

            // ✅ CRITICAL: Preserve the existing role if the update doesn't have one
            final preservedRole = updatedMe.role ?? _myPlayer!.role;

            _myPlayer = updatedMe.copyWith(
              role: preservedRole, // Keep the role we got from ROLE_ASSIGNED
            );

            print(
              '✅ My player updated - Role: ${_myPlayer!.role}, IsHost: ${_myPlayer!.isHost}',
            );

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

  @override
  void dispose() {
    _hunterRevengeTimer?.cancel();
    super.dispose();
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

  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;

    print('🚪 Leaving room: $_currentRoomId');

    try {
      // 1. Send WebSocket leave message BEFORE disconnecting
      if (_wsService.isConnected) {
        _wsService.sendLeaveRoom(_currentRoomId!);

        // 2. Wait a moment for message to be sent
        await Future.delayed(Duration(milliseconds: 200));
      }

      // 3. Now disconnect WebSocket
      disconnectFromRoom();

      print('✅ Successfully left room');
    } catch (e) {
      print('❌ Error leaving room: $e');
      // Still disconnect even if leave message failed
      disconnectFromRoom();
    }
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
  // Start game with retry logic for session creation issues
  Future<bool> startGame({int retryCount = 0, int maxRetries = 3}) async {
    if (_currentRoomId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.startGame(_currentRoomId!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print(
        '❌ Failed to start game (attempt ${retryCount + 1}/$maxRetries): $e',
      );

      String errorMsg = e.toString();

      // ✅ FIX: Detect session-not-found errors and retry
      bool isSessionError =
          errorMsg.contains('No active session') ||
          errorMsg.contains('WebSocket') ||
          errorMsg.contains('Session not found');

      if (isSessionError && retryCount < maxRetries) {
        print('🔄 Retrying start game in ${(retryCount + 1) * 500}ms...');

        // Exponential backoff: 500ms, 1000ms, 1500ms
        await Future.delayed(Duration(milliseconds: (retryCount + 1) * 500));

        return startGame(retryCount: retryCount + 1, maxRetries: maxRetries);
      }

      _error = isSessionError
          ? 'Connection not ready. Please ensure all players have joined.'
          : errorMsg.replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit night action (werewolf kill, seer check, doctor protect)
  Future<void> submitNightAction(String targetId) async {
    if (_currentRoomId == null || _myPlayer == null) {
      _error = 'Not in a game';
      notifyListeners();
      return;
    }

    if (_hasActedTonight) {
      _error = 'You have already acted tonight';
      notifyListeners();
      return;
    }

    try {
      // Determine action type based on role
      String action;
      switch (_myPlayer!.role?.toUpperCase()) {
        case 'WEREWOLF':
          action = 'WEREWOLF_KILL';
          break;
        case 'SEER':
          action = 'SEER_CHECK';
          break;
        case 'DOCTOR':
          action = 'DOCTOR_PROTECT';
          break;
        default:
          _error = 'Your role cannot perform night actions';
          notifyListeners();
          return;
      }

      print('🌙 Submitting night action: $action on $targetId');

      _wsService.sendNightAction(
        _currentRoomId!,
        _myPlayer!.id,
        targetId,
        action,
      );

      _selectedTargetId = targetId;
      _error = null;
      // ✅ Don't set _hasActedTonight here - let the callback do it
      notifyListeners();
    } catch (e) {
      print('❌ Error submitting night action: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Submit vote during voting phase
  Future<void> submitVote(String targetId) async {
    if (_currentRoomId == null || _myPlayer == null) {
      _error = 'Not in a game';
      notifyListeners();
      return;
    }

    if (_hasVoted) {
      _error = 'You have already voted';
      notifyListeners();
      return;
    }

    try {
      print('🗳️ Submitting vote for: $targetId');

      _wsService.sendVote(_currentRoomId!, _myPlayer!.id, targetId);

      _selectedTargetId = targetId;
      _hasVoted = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ Error submitting vote: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Select a target player (UI selection, not submitted yet)
  void selectTarget(String playerId) {
    _selectedTargetId = playerId;
    notifyListeners();
  }

  /// Clear selected target
  void clearTarget() {
    _selectedTargetId = null;
    notifyListeners();
  }

  /// Check if a player can be targeted
  bool canTarget(String playerId) {
    if (_myPlayer == null) return false;
    if (_myPlayer!.id == playerId) return false; // Can't target self

    final targetPlayer = _players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => Player(id: '', username: '', isHost: false),
    );

    if (targetPlayer.id.isEmpty) return false;
    if (!targetPlayer.isAlive) return false; // Can't target dead players

    return true;
  }

  /// Get action button text based on role and phase
  String getActionButtonText() {
    if (_myPlayer == null) return 'Wait...';

    if (_gameState?.isNightPhase == true) {
      if (_hasActedTonight) return 'Acted';

      switch (_myPlayer!.role?.toUpperCase()) {
        case 'WEREWOLF':
          return _selectedTargetId != null ? 'Attack' : 'Select Target';
        case 'SEER':
          return _selectedTargetId != null ? 'Investigate' : 'Select Target';
        case 'DOCTOR':
          return _selectedTargetId != null ? 'Protect' : 'Select Target';
        default:
          return 'Wait...';
      }
    } else if (_gameState?.isVotingPhase == true) {
      if (_hasVoted) return 'Voted';
      return _selectedTargetId != null ? 'Cast Vote' : 'Select Player';
    }

    return 'Wait...';
  }

  /// Check if action button should be enabled
  bool canSubmitAction() {
    if (_myPlayer == null || _gameState == null) return false;
    if (_selectedTargetId == null) return false;

    if (_gameState!.isNightPhase) {
      if (_hasActedTonight) return false;
      return _myPlayer!.role != null &&
          _myPlayer!.role!.toUpperCase() != 'VILLAGER';
    } else if (_gameState!.isVotingPhase) {
      return !_hasVoted;
    }

    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
