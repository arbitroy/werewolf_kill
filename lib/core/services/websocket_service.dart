import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  static const String wsUrl = 'http://localhost:8080/ws/game';
  
  StompClient? _client;
  Function(Map<String, dynamic>)? onGameUpdate;

  void connect(String roomId) {
    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          print('Connected to WebSocket');
          
          // Subscribe to game updates
          _client?.subscribe(
            destination: '/topic/game/$roomId',
            callback: (frame) {
              if (frame.body != null && onGameUpdate != null) {
                final data = jsonDecode(frame.body!);
                onGameUpdate!(data);
              }
            },
          );
        },
        onWebSocketError: (error) => print('WebSocket error: $error'),
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
  }

  void sendMessage(String destination, Map<String, dynamic> message) {
    _client?.send(
      destination: destination,
      body: jsonEncode(message),
    );
  }
}