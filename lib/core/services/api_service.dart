import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';

class ApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  
  String? _token;
  bool _isWakingUp = false;

  void setToken(String token) {
    _token = token;
  }

  String? get token => _token;
  bool get isWakingUp => _isWakingUp;

  // Helper method to handle cold start retries
  Future<http.Response> _makeRequestWithRetry({
    required Future<http.Response> Function() request,
    int maxRetries = 2,
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      try {
        final response = await request();
        
        // If we get 502/503, server is waking up
        if (response.statusCode == 502 || response.statusCode == 503) {
          if (i < maxRetries) {
            _isWakingUp = true;
            print('⏳ Server is waking up... (${i + 1}/$maxRetries) Waiting 20 seconds...');
            await Future.delayed(Duration(seconds: 20));
            continue;
          }
          throw Exception('Server is still starting up. Please wait a moment and try again.');
        }
        
        _isWakingUp = false;
        return response;
      } catch (e) {
        if (i < maxRetries) {
          print('⚠️ Request failed, retrying... (${i + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 5));
          continue;
        }
        rethrow;
      }
    }
    
    throw Exception('Failed after $maxRetries retries');
  }

  // Auth
  Future<Map<String, dynamic>> register(String username, String password) async {
    print('🔵 Registering at: $baseUrl/auth/register');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 60)), // Longer timeout for cold start
    );

    print('📥 Register response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    print('🔵 Logging in at: $baseUrl/auth/login');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 60)), // Longer timeout for cold start
    );

    print('📥 Login response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  // Health check - useful to wake up server
  Future<bool> checkHealth() async {
    try {
      print('🔵 Checking server health...');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/actuator/health'),
      ).timeout(Duration(seconds: 60));
      
      print('📥 Health response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  // Rooms
  Future<Map<String, dynamic>> createRoom(String name, String hostId) async {
    print('🔵 Creating room at: $baseUrl/rooms');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'name': name,
          'hostId': hostId,
        }),
      ).timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create room');
    }
  }

  Future<List<dynamic>> getRooms() async {
    print('🔵 Getting rooms from: $baseUrl/rooms');
    
    final response = await _makeRequestWithRetry(
      request: () => http.get(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<void> joinRoom(String roomId, String playerId) async {
    print('🔵 Joining room: $baseUrl/rooms/$roomId/join');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/rooms/$roomId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'playerId': playerId,
        }),
      ).timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to join room');
    }
  }

  // Game
  Future<void> startGame(String roomId) async {
    print('🔵 Starting game: $baseUrl/game/$roomId/start');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/game/$roomId/start'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start game');
    }
  }

  Future<void> vote(String roomId, String voterId, String targetId) async {
    print('🔵 Casting vote: $baseUrl/game/$roomId/vote');
    
    final response = await _makeRequestWithRetry(
      request: () => http.post(
        Uri.parse('$baseUrl/game/$roomId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'voterId': voterId,
          'targetId': targetId,
        }),
      ).timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cast vote');
    }
  }
}