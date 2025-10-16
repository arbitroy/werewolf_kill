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
  static String get wsUrl {
    // Debug: Print what URL we're actually using
    final url = AppConstants.wsUrl;

    // Ensure we're using the correct WebSocket scheme
    if (url.startsWith('https://')) {
      final wsUrl = url.replaceFirst('https://', 'wss://');
      return wsUrl;
    } else if (url.startsWith('http://')) {
      final wsUrl = url.replaceFirst('http://', 'ws://');
      return wsUrl;
    }

    return url;
  }

  StompClient? _client;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _currentRoomId;
  String? _currentPlayerId; // ADD THIS
  String? _currentUsername; // ADD THIS

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

  void connect(
    String roomId,
    String playerId,
    String username,
    String connectionUrl,
  ) {
    if (_client != null && _connectionState == ConnectionState.connected) {
      print('Already connected');
      return;
    }

    _currentRoomId = roomId;
    _currentPlayerId = playerId;
    _currentUsername = username;

    // Remove /api if present in the URL
    String cleanUrl = connectionUrl;
    if (cleanUrl.endsWith('/api')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 4);
    }

    // Parse the base URL correctly and add /ws/game endpoint
    String wsUrl;
    if (cleanUrl.startsWith('http://')) {
      wsUrl = cleanUrl.replaceFirst('http://', 'ws://') + '/ws/game';
    } else if (cleanUrl.startsWith('https://')) {
      wsUrl = cleanUrl.replaceFirst('https://', 'wss://') + '/ws/game';
    } else if (cleanUrl.startsWith('ws://') || cleanUrl.startsWith('wss://')) {
      wsUrl = cleanUrl + '/ws/game';
    } else {
      // Assume https for production
      wsUrl = 'wss://' + cleanUrl + '/ws/game';
    }

    print('🔵 Attempting WebSocket connection to: $wsUrl');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          _onConnect(frame, roomId);
          // Send join after subscriptions are set up
          if (_currentPlayerId != null && _currentUsername != null) {
            sendJoinRoom(roomId, _currentPlayerId!, _currentUsername!);
          }
        },
        onDisconnect: (frame) => _onDisconnect(frame),
        onWebSocketError: (error) => _onWebSocketError(error),
        onStompError: (frame) => _onStompError(frame),
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onWebSocketDone: () => _onWebSocketDone(),
        stompConnectHeaders: {},
        webSocketConnectHeaders: {},
      ),
    );

    _client?.activate();
  }

  // Helper method to get auth token if needed
  String? _getAuthToken() {
    // TODO: Implement getting auth token from storage or provider
    // For now, return null if not needed
    return null;
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

    // NOTE: sendJoinRoom is now called from the onConnect callback in connect()
    // to ensure it happens AFTER subscriptions are set up
  }

  void _onDisconnect(StompFrame frame) {
    print('❌ Disconnected from WebSocket');
    _updateConnectionState(ConnectionState.disconnected);
  }

  void _onWebSocketError(dynamic error) {
    print('⚠️ WebSocket error: $error');
    print('⚠️ Error type: ${error.runtimeType}');
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
    print('🔍 _handleRoomMessage - frame received');
    if (frame.body == null) {
      print('⚠️ Frame body is null!');
      return;
    }

    try {
      print('🔍 Frame body: ${frame.body}');
      final data = jsonDecode(frame.body!);
      final type = data['type'] as String?;

      print('📩 Room message type: $type');
      print('🔍 Full message data: $data');

      switch (type) {
        case 'PLAYER_JOINED':
          print('🔍 Calling onPlayerJoined callback with data: $data');
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
      print('❌ Error parsing room message: $e');
      print('❌ Frame body was: ${frame.body}');
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
  void sendJoinRoom(String roomId, String playerId, String username) {
    if (!isConnected) {
      print('Cannot send message: not connected');
      return;
    }

    print('🔵 Sending join room message for player: $username ($playerId)');

    _client?.send(
      destination: '/app/room/$roomId/join',
      body: jsonEncode({
        'roomId': roomId,
        'playerId': playerId,
        'username': username,
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

  void sendNightAction(
    String roomId,
    String actorId,
    String targetId,
    String action,
  ) {
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

    _client?.send(destination: destination, body: jsonEncode(message));
  }

  void disconnect() {
    if (_client != null) {
      print('🔌 Disconnecting WebSocket...');
      _client?.deactivate();
      _client = null;
      _currentRoomId = null;
      _currentPlayerId = null;
      _currentUsername = null;
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  void dispose() {
    disconnect();
  }
}
