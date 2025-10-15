import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../config/constants.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketService {
  // Use constant from AppConstants instead of hardcoding
  static String get wsUrl => AppConstants.wsUrl;
  
  StompClient? _client;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _currentRoomId;
  
  // Callbacks for different event types
  Function(Map<String, dynamic>)? onPlayerJoined;
  Function(Map<String, dynamic>)? onPlayerLeft;
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

  void connect(String roomId) {
    if (_client != null && _client!.isActive) {
      print('Already connected, disconnecting first...');
      disconnect();
    }

    _currentRoomId = roomId;
    _updateConnectionState(ConnectionState.connecting);

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) => _onConnect(frame, roomId),
        onDisconnect: (frame) => _onDisconnect(frame),
        onWebSocketError: (error) => _onWebSocketError(error),
        onStompError: (frame) => _onStompError(frame),
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onWebSocketDone: () => _onWebSocketDone(),
      ),
    );

    _client?.activate();
  }

  void _onConnect(StompFrame frame, String roomId) {
    print('✅ Connected to WebSocket for room: $roomId');
    _updateConnectionState(ConnectionState.connected);

    // Subscribe to room-specific events (player join/leave, game start)
    _client?.subscribe(
      destination: '/topic/room/$roomId',
      callback: (frame) => _handleRoomMessage(frame),
    );

    // Subscribe to game-specific events (game updates, phases, votes)
    _client?.subscribe(
      destination: '/topic/game/$roomId',
      callback: (frame) => _handleGameMessage(frame),
    );

    // Send join notification
    sendJoinRoom(roomId);
  }

  void _onDisconnect(StompFrame frame) {
    print('❌ Disconnected from WebSocket');
    _updateConnectionState(ConnectionState.disconnected);
  }

  void _onWebSocketError(dynamic error) {
    print('⚠️ WebSocket error: $error');
    _updateConnectionState(ConnectionState.error);
    onError?.call(error.toString());
  }

  void _onStompError(StompFrame frame) {
    print('⚠️ STOMP error: ${frame.body}');
    _updateConnectionState(ConnectionState.error);
    onError?.call(frame.body ?? 'Unknown STOMP error');
  }

  void _onWebSocketDone() {
    print('🔄 WebSocket connection closed, attempting reconnect...');
    _updateConnectionState(ConnectionState.reconnecting);
  }

  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    onConnectionStateChanged?.call(newState);
  }

  void _handleRoomMessage(StompFrame frame) {
    if (frame.body == null) return;

    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📩 Room message: $type');

      switch (type) {
        case 'PLAYER_JOINED':
          onPlayerJoined?.call(data);
          break;
        case 'PLAYER_LEFT':
          onPlayerLeft?.call(data);
          break;
        case 'GAME_STARTED':
          onGameStarted?.call(data);
          break;
        default:
          print('Unknown room message type: $type');
      }
    } catch (e) {
      print('Error parsing room message: $e');
      onError?.call('Failed to parse room message: $e');
    }
  }

  void _handleGameMessage(StompFrame frame) {
    if (frame.body == null) return;

    try {
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('🎮 Game message: $type');

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
          print('Unknown game message type: $type');
      }
    } catch (e) {
      print('Error parsing game message: $e');
      onError?.call('Failed to parse game message: $e');
    }
  }

  // Send messages to server
  void sendJoinRoom(String roomId) {
    if (!isConnected) {
      print('Cannot send message: not connected');
      return;
    }

    _client?.send(
      destination: '/app/game.join',
      body: jsonEncode({
        'roomId': roomId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  void sendVote(String roomId, String voterId, String targetId) {
    if (!isConnected) {
      print('Cannot send vote: not connected');
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

  void sendNightAction(String roomId, String actorId, String targetId, String action) {
    if (!isConnected) {
      print('Cannot send night action: not connected');
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

  void sendMessage(String destination, Map<String, dynamic> message) {
    if (!isConnected) {
      print('Cannot send message: not connected');
      return;
    }

    _client?.send(
      destination: destination,
      body: jsonEncode(message),
    );
  }

  void disconnect() {
    if (_client != null) {
      print('🔌 Disconnecting WebSocket...');
      _client?.deactivate();
      _client = null;
      _currentRoomId = null;
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  void dispose() {
    disconnect();
  }
}