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
  Timer? _heartbeatTimer;

  // Callbacks for different event types
  Function(Map<String, dynamic>)? onRoomStateUpdate;  // ✅ New unified callback
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

    _currentRoomId = roomId;
    _currentPlayerId = playerId;
    _currentUsername = username;

    // Build WebSocket URL
    String wsUrl;
    if (connectionUrl.startsWith('http://')) {
      wsUrl = connectionUrl.replaceFirst('http://', 'ws://') + '/ws/game';
    } else if (connectionUrl.startsWith('https://')) {
      wsUrl = connectionUrl.replaceFirst('https://', 'wss://') + '/ws/game';
    } else {
      wsUrl = 'wss://' + connectionUrl + '/ws/game';
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
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onWebSocketDone: () => _onWebSocketDone(),
      ),
    );

    _updateConnectionState(ConnectionState.connecting);
    _client?.activate();
  }

  void _onConnect(StompFrame frame, String roomId) {
    print('✅ WebSocket CONNECTED');
    _updateConnectionState(ConnectionState.connected);

    // Subscribe to room updates (NEW unified topic)
    print('📡 Subscribing to /topic/room/$roomId');
    _client?.subscribe(
      destination: '/topic/room/$roomId',
      callback: (frame) {
        if (frame.body != null) {
          _handleRoomMessage(frame);
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

    // Subscribe to error queue
    _client?.subscribe(
      destination: '/user/queue/errors',
      callback: (frame) {
        if (frame.body != null) {
          _handleErrorMessage(frame);
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
    _updateConnectionState(ConnectionState.error);
    onError?.call(error.toString());
  }

  void _onStompError(StompFrame frame) {
    print('❌ STOMP error: ${frame.body}');
    _updateConnectionState(ConnectionState.error);
    onError?.call(frame.body ?? 'Unknown STOMP error');
  }

  void _onWebSocketDone() {
    print('🔄 WebSocket connection closed, reconnecting...');
    _updateConnectionState(ConnectionState.reconnecting);
  }

  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    onConnectionStateChanged?.call(newState);
  }

  void _handleRoomMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📩 Room message type: $type');

      switch (type) {
        case 'ROOM_STATE_UPDATE':  // ✅ NEW: Unified room state
          print('📊 Room state update received');
          onRoomStateUpdate?.call(data);
          break;
        case 'PLAYER_JOINED':
          print('👋 Player joined');
          onPlayerJoined?.call(data);
          break;
        case 'PLAYER_LEFT':
          print('👋 Player left');
          onPlayerLeft?.call(data);
          break;
        case 'HOST_CHANGED':
          print('👑 Host changed');
          onHostChanged?.call(data);
          break;
        case 'GAME_STARTED':
          print('🎮 Game started');
          onGameStarted?.call(data);
          break;
        default:
          print('⚠️ Unknown room message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing room message: $e');
      onError?.call('Failed to parse room message: $e');
    }
  }

  void _handleGameMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('🎮 Game message type: $type');

      switch (type) {
        case 'GAME_UPDATE':
          onGameUpdate?.call(data);
          break;
        case 'ROLE_ASSIGNED':
          onRoleAssigned?.call(data);
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
        default:
          print('⚠️ Unknown game message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing game message: $e');
      onError?.call('Failed to parse game message: $e');
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

  // Send join room message
  void sendJoinRoom(String roomId, String playerId, String username) {
    if (!isConnected) {
      print('⚠️ Cannot send join: not connected');
      return;
    }

    print('📤 Sending join room message');
    _client?.send(
      destination: '/app/room/$roomId/join',
      body: jsonEncode({
        'playerId': playerId,
        'username': username,
      }),
    );
  }

  // Send leave room message
  void sendLeaveRoom(String roomId) {
    if (!isConnected) {
      print('⚠️ Cannot send leave: not connected');
      return;
    }

    print('📤 Sending leave room message');
    _client?.send(
      destination: '/app/room/$roomId/leave',
    );
  }

  // Start game
  void sendStartGame(String roomId) {
    if (!isConnected) {
      print('⚠️ Cannot send start game: not connected');
      return;
    }

    print('📤 Sending start game message');
    _client?.send(
      destination: '/app/game.start',
      body: jsonEncode({'roomId': roomId}),
    );
  }

  // Cast vote
  void sendVote(String roomId, String voterId, String targetId) {
    if (!isConnected) {
      print('⚠️ Cannot send vote: not connected');
      return;
    }

    _client?.send(
      destination: '/app/game.vote',
      body: jsonEncode({
        'roomId': roomId,
        'voterId': voterId,
        'targetId': targetId,
      }),
    );
  }

  // Night action
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

    _client?.send(
      destination: '/app/game.nightAction',
      body: jsonEncode({
        'roomId': roomId,
        'actorId': actorId,
        'targetId': targetId,
        'action': action,
      }),
    );
  }

  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_currentRoomId != null && isConnected) {
        _client?.send(
          destination: '/app/room/$_currentRoomId/heartbeat',
        );
        print('💓 Heartbeat sent');
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Disconnect
  void disconnect() {
    _stopHeartbeat();
    if (_client != null) {
      print('🔌 Disconnecting WebSocket...');
      _client?.deactivate();
      _client = null;
    }
    _currentRoomId = null;
    _currentPlayerId = null;
    _currentUsername = null;
    _updateConnectionState(ConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
  }
}