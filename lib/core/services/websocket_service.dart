import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketService {
  StompClient? _client;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _currentRoomId;
  String? _currentPlayerId;
  String? _currentUsername;
  String? _currentConnectionUrl;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks
  Function(Map<String, dynamic>)? onRoomStateUpdate;
  Function(Map<String, dynamic>)? onPlayerJoined;
  Function(Map<String, dynamic>)? onPlayerLeft;
  Function(Map<String, dynamic>)? onHostChanged;
  Function(Map<String, dynamic>)? onGameStarted;
  Function(Map<String, dynamic>)? onGameUpdate;
  Function(Map<String, dynamic>)? onRoleAssigned;
  Function(Map<String, dynamic>)? onPhaseChange;
  Function(Map<String, dynamic>)? onVoteCast;
  Function(Map<String, dynamic>)? onPlayerDied;
  Function(ConnectionState)? onConnectionStateChanged;
  Function(String)? onError;
  Function(Map<String, dynamic>)? onActionConfirmed;
  Function(Map<String, dynamic>)? onSeerResult;
  Function(Map<String, dynamic>)? onWerewolfVote;
  Function(Map<String, dynamic>)? onVoteCountUpdate;
  Function(Map<String, dynamic>)? onNightResult;
  Function(Map<String, dynamic>)? onVoteResult;
  Function(Map<String, dynamic> data)? onHunterRevengeTriggered;
  Function(Map<String, dynamic> data)? onHunterRevengePrompt;
  Function(Map<String, dynamic> data)? onHunterRevengeExecuted;
  Function(Map<String, dynamic> data)? onHunterRevengeTimeout;

  ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ConnectionState.connected;

  void connect(
    String roomId,
    String playerId,
    String username,
    String connectionUrl,
  ) {
    print('═══════════════════════════════════════');
    print('🔵 WEBSOCKET CONNECTION ATTEMPT');
    print('═══════════════════════════════════════');
    print('Room ID: $roomId');
    print('Player ID: $playerId');
    print('Username: $username');
    print('Connection URL: $connectionUrl');

    if (_client != null && _connectionState == ConnectionState.connected) {
      print('⚠️ Already connected, skipping');
      return;
    }

    // Store connection details for reconnection
    _currentRoomId = roomId;
    _currentPlayerId = playerId;
    _currentUsername = username;
    _currentConnectionUrl = connectionUrl;

    // Build WebSocket URL - native WebSocket only, no SockJS
    String wsUrl;
    if (connectionUrl.startsWith('http://')) {
      wsUrl = '${connectionUrl.replaceFirst('http://', 'ws://')}/ws/game';
    } else if (connectionUrl.startsWith('https://')) {
      wsUrl = '${connectionUrl.replaceFirst('https://', 'wss://')}/ws/game';
    } else {
      wsUrl = 'wss://$connectionUrl/ws/game';
    }

    print('🔵 WebSocket URL: $wsUrl');
    print('═══════════════════════════════════════');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) => _onConnect(frame, roomId),
        onDisconnect: (frame) => _onDisconnect(),
        onWebSocketError: (error) => _onWebSocketError(error),
        onStompError: (frame) => _onStompError(frame),
        reconnectDelay: Duration(seconds: 5),
        heartbeatIncoming: Duration(seconds: 10),
        heartbeatOutgoing: Duration(seconds: 10),
        onWebSocketDone: () => _onWebSocketDone(),
        // ✅ ADD: Connection timeout
        connectionTimeout: Duration(seconds: 10),
      ),
    );

    _updateConnectionState(ConnectionState.connecting);
    _client?.activate();
  }

  void _onConnect(StompFrame frame, String roomId) {
    print('✅ WebSocket CONNECTED');
    _reconnectAttempts = 0; // Reset reconnect counter
    _updateConnectionState(ConnectionState.connected);

    // Subscribe to room updates
    print('📡 Subscribing to /topic/room/$roomId');
    _client?.subscribe(
      destination: '/topic/room/$roomId',
      callback: (frame) {
        if (frame.body != null) {
          _handleRoomMessage(frame);
        }
      },
    );

    // Subscribe to private role assignments
    _client?.subscribe(
      destination: '/user/queue/role',
      callback: (frame) {
        if (frame.body != null) {
          _handleRoleMessage(frame);
        }
      },
    );

    // Subscribe to game-specific events
    print('📡 Subscribing to /topic/game/$roomId');
    _client?.subscribe(
      destination: '/topic/game/$roomId',
      callback: (frame) {
        if (frame.body != null) {
          _handleGameMessage(frame);
        }
      },
    );

    _client?.subscribe(
      destination: '/user/queue/seer-result',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            print('🔮 Seer result received: ${data['targetName']}');
            onSeerResult?.call(data);
          } catch (e) {
            print('❌ Error parsing seer result: $e');
          }
        }
      },
    );

    // Subscribe to error queue
    _client?.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        if (frame.body != null) {
          _handleErrorMessage(frame);
        }
      },
    );
    _client?.subscribe(
      destination: '/user/queue/hunter-revenge',
      callback: (frame) {
        if (frame.body != null) {
          _handleHunterRevengeMessage(frame);
        }
      },
    );

    print('✅ Subscriptions complete');

    // Send join message
    if (_currentPlayerId != null && _currentUsername != null) {
      sendJoinRoom(roomId, _currentPlayerId!, _currentUsername!);
    }

    // Start heartbeat
    _startHeartbeat();
  }

  void _onDisconnect() {
    print('🔌 WebSocket DISCONNECTED');
    _updateConnectionState(ConnectionState.disconnected);
    _stopHeartbeat();
  }

  void _onWebSocketError(dynamic error) {
    print('❌ WebSocket error: $error');

    // Check if it's a 502 error (server sleeping)
    if (error.toString().contains('502')) {
      print('🌙 Server appears to be sleeping. Will retry...');
      _scheduleReconnect();
    } else {
      _updateConnectionState(ConnectionState.error);
      onError?.call(error.toString());
    }
  }

  void _onStompError(StompFrame frame) {
    print('❌ STOMP error: ${frame.body}');
    _updateConnectionState(ConnectionState.error);
    onError?.call(frame.body ?? 'Unknown STOMP error');
  }

  void _onWebSocketDone() {
    print('🔄 WebSocket connection closed');
    _scheduleReconnect();
  }

  // ✅ NEW: Smart reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnect attempts reached');
      _updateConnectionState(ConnectionState.error);
      onError?.call(
        'Failed to reconnect after $_maxReconnectAttempts attempts',
      );
      return;
    }

    _updateConnectionState(ConnectionState.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    print(
      '⏳ Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentRoomId != null &&
          _currentPlayerId != null &&
          _currentUsername != null &&
          _currentConnectionUrl != null) {
        print('🔄 Attempting reconnection...');
        disconnect(); // Clean up old connection
        connect(
          _currentRoomId!,
          _currentPlayerId!,
          _currentUsername!,
          _currentConnectionUrl!,
        );
      }
    });
  }

  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    onConnectionStateChanged?.call(newState);
  }

  void _handleRoleMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('🎭 Role message type: $type');

      if (type == 'ROLE_ASSIGNED') {
        onRoleAssigned?.call(data);
      } else if (type == 'SEER_RESULT') {
        // ✅ NEW: Handle seer investigation results
        onSeerResult?.call(data);
      }
    } catch (e) {
      print('❌ Error parsing role message: $e');
    }
  }

  void _handleRoomMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📨 Room message type: $type');

      switch (type) {
        case 'ROOM_STATE_UPDATE':
          onRoomStateUpdate?.call(data);
          break;
        case 'PLAYER_JOINED':
          onPlayerJoined?.call(data);
          break;
        case 'PLAYER_LEFT':
          onPlayerLeft?.call(data);
          break;
        case 'HOST_CHANGED':
          onHostChanged?.call(data);
          break;
        case 'GAME_STARTED':
          onGameStarted?.call(data);
          break;
        case 'PHASE_CHANGE':
          onPhaseChange?.call(data);
          break;
        case 'VOTE_CAST':
          onVoteCast?.call(data);
          break;
        case 'PLAYER_DIED':
          onPlayerDied?.call(data);
          break;
        case 'GAME_OVER':
          onGameUpdate?.call(data);
          break;
        // ✅ NEW: Add these cases
        case 'ACTION_CONFIRMED':
          onActionConfirmed?.call(data);
          break;
        case 'WEREWOLF_VOTE':
          onWerewolfVote?.call(data);
          break;
        case 'VOTE_COUNT_UPDATE':
          onVoteCountUpdate?.call(data);
          break;
        case 'NIGHT_RESULT':
          onNightResult?.call(data);
          break;
        case 'VOTE_RESULT':
          onVoteResult?.call(data);
          break;
        case 'ERROR':
          final message = data['message'] as String?;
          print('❌ Server error: $message');
          onError?.call(message ?? 'Unknown error');
          break;
        default:
          print('⚠️ Unknown message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing room message: $e');
    }
  }

  void _handleGameMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📨 Game message type: $type');

      switch (type) {
        case 'GAME_STARTED':
          print('🎮 GAME_STARTED message received!');
          onGameStarted?.call(data);
          break;
        case 'ROLE_ASSIGNED': // ✅ Handle in game topic now
          print('🎭 ROLE_ASSIGNED received in game topic');
          _handleRoleAssignment(data);
          break;
        case 'GAME_UPDATE':
          onGameUpdate?.call(data);
          break;
        case 'PHASE_CHANGE':
          onPhaseChange?.call(data);
          break;
        case 'VOTE_CAST':
          onVoteCast?.call(data);
          break;
        case 'PLAYER_DIED':
          onPlayerDied?.call(data);
          break;
        case 'ROOM_STATE_UPDATE': // ✅ Handle here too
          onRoomStateUpdate?.call(data);
          break;
        case 'HUNTER_REVENGE_TRIGGERED':
          onHunterRevengeTriggered?.call(data);
          break;

        case 'HUNTER_REVENGE_EXECUTED':
          onHunterRevengeExecuted?.call(data);
          break;

        case 'HUNTER_REVENGE_TIMEOUT':
          onHunterRevengeTimeout?.call(data);
          break;

        default:
          print('⚠️ Unknown game message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing game message: $e');
    }
  }

  void _handleHunterRevengeMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      if (type == 'HUNTER_REVENGE_PROMPT') {
        onHunterRevengePrompt?.call(data);
      }
    } catch (e) {
      print('❌ Error parsing hunter revenge message: $e');
    }
  }

  // ✅ New method to handle role assignment with filtering
  void _handleRoleAssignment(Map<String, dynamic> data) {
    final playerId = data['playerId'] as String?;

    // Only process if it's for this player
    if (playerId != null && playerId == _currentPlayerId) {
      print('🎭 Role assigned to ME: ${data['role']}');
      onRoleAssigned?.call(data);
    } else {
      print('🎭 Role assigned to another player (ignored)');
    }
  }

  void _handleErrorMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final message = data['message'] as String?;
      print('❌ Server error: $message');
      onError?.call(message ?? 'Unknown error');
    } catch (e) {
      print('❌ Error parsing error message: $e');
    }
  }

  void sendJoinRoom(String roomId, String playerId, String username) {
    if (!isConnected) {
      print('⚠️ Cannot send join: not connected');
      return;
    }

    print('📤 Sending join room message');
    _client?.send(
      destination: '/app/room/$roomId/join',
      body: jsonEncode({'playerId': playerId, 'username': username}),
    );
  }

  void sendLeaveRoom(String roomId) {
    if (!isConnected) return;
    _client?.send(destination: '/app/room/$roomId/leave');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_currentRoomId != null && isConnected) {
        _client?.send(destination: '/app/room/$_currentRoomId/heartbeat');
        print('💓 Heartbeat sent');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_client != null) {
      print('🔌 Disconnecting WebSocket...');
      _client?.deactivate();
      _client = null;
    }

    _updateConnectionState(ConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _currentRoomId = null;
    _currentPlayerId = null;
    _currentUsername = null;
    _currentConnectionUrl = null;
  }

  /// Send night action to server
  void sendNightAction(
    String roomId,
    String actorId,
    String targetId,
    String action,
  ) {
    if (!isConnected) {
      print('⚠️ Cannot send night action: not connected');
      return;
    }

    print('📤 Sending night action: $action by $actorId on $targetId');

    final payload = {
      'actorId': actorId,
      'targetId': targetId,
      'action': action,
    };

    _client?.send(
      destination: '/app/game/$roomId/action',
      body: jsonEncode(payload),
    );
  }

  /// Send vote to server
  void sendVote(String roomId, String voterId, String targetId) {
    if (!isConnected) {
      print('⚠️ Cannot send vote: not connected');
      return;
    }

    print('📤 Sending vote: $voterId → $targetId');

    final payload = {'voterId': voterId, 'targetId': targetId};

    _client?.send(
      destination: '/app/game/$roomId/vote',
      body: jsonEncode(payload),
    );
  }
}
