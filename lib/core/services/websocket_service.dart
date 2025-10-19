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

      if (type == 'ROLE_ASSIGNED') {
        onRoleAssigned?.call(data);
      }
    } catch (e) {
      print('❌ Error parsing role message: $e');
    }
  }

  void _handleRoomMessage(StompFrame frame) {
    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📩 Room message type: $type');

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
      }
    } catch (e) {
      print('❌ Error parsing game message: $e');
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
}
