import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final String baseUrl = AppConstants.apiBaseUrl;

  String? _token;

  String get serverUrl {
    // AppConstants.apiBaseUrl is "https://werewolf-backend-jsji.onrender.com/api"
    // We need "https://werewolf-backend-jsji.onrender.com"
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  // Set auth token
  void setToken(String token) {
    _token = token;
    print('🔐 Token set: ${token.substring(0, 10)}...');
  }

  // ✅ Add getter to check if token exists
  bool get hasToken => _token != null && _token!.isNotEmpty;

  // ✅ Add method to log token status
  void debugTokenStatus() {
    if (_token == null) {
      print('❌ Token is NULL');
    } else if (_token!.isEmpty) {
      print('❌ Token is EMPTY');
    } else {
      print('✅ Token exists: ${_token!.substring(0, 10)}...');
    }
  }

  // Helper method for retrying failed requests
  Future<http.Response> _makeRequestWithRetry({
    required Future<http.Response> Function() request,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        print('📡 Attempt ${attempts + 1}/$maxRetries');
        final response = await request();

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response;
        }

        // If it's a client error (4xx), don't retry
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }

        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      } catch (e) {
        print('❌ Request failed: $e');
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Authentication
  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    print('🔵 Registering user: $username');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse(AppConstants.authRegister),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    print('🔵 Logging in user: $username');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse(AppConstants.authLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  // Rooms

  Future<Map<String, dynamic>> createRoom(
    String roomName,
    String createdBy, { // ✅ Changed from hostId
    int maxPlayers = 8,
  }) async {
    print('🔵 Creating room: $roomName');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse('$baseUrl/rooms'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'name': roomName,
              'createdBy': createdBy, // ✅ Changed from hostId
              'maxPlayers': maxPlayers,
            }),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create room');
    }
  }

  Future<List<dynamic>> getRooms() async {
    print('🔵 Getting rooms from: $baseUrl/rooms');

    final response = await _makeRequestWithRetry(
      request: () => http
          .get(
            Uri.parse('$baseUrl/rooms'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Backend returns List<Map> directly in data field
      return responseData['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<Map<String, dynamic>> getRoomDetails(String roomId) async {
    print('🔵 Getting room details: $baseUrl/rooms/$roomId');

    final response = await _makeRequestWithRetry(
      request: () => http
          .get(
            Uri.parse('$baseUrl/rooms/$roomId'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to get room details');
    }
  }

  Future<List<dynamic>> getRoomPlayers(String roomId) async {
    print('🔵 Getting room players: $baseUrl/rooms/$roomId/players');

    final response = await _makeRequestWithRetry(
      request: () => http
          .get(
            Uri.parse('$baseUrl/rooms/$roomId/players'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to get room players');
    }
  }

  Future<void> joinRoom(String roomId, String playerId) async {
    print('🔵 Joining room: $baseUrl/rooms/$roomId/join');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse('$baseUrl/rooms/$roomId/join'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({'playerId': playerId}),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to join room');
    }
  }

  Future<void> leaveRoom(String roomId, String playerId) async {
    print('🔵 Leaving room: $baseUrl/rooms/$roomId/leave');

    final response = await _makeRequestWithRetry(
      request: () => http
          .delete(
            Uri.parse('$baseUrl/rooms/$roomId/leave'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({'playerId': playerId}),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to leave room');
    }
  }

  // Game
  Future<void> startGame(String roomId) async {
    print('🔵 Starting game: $baseUrl/game/$roomId/start');
    
    // ✅ Add token validation before making request
    if (_token == null || _token!.isEmpty) {
      print('❌ ERROR: No authentication token available!');
      throw Exception('Not authenticated. Please log in again.');
    }
    
    print('🔐 Using token: ${_token!.substring(0, 10)}...');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse('$baseUrl/game/$roomId/start'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      // ✅ Extract actual error message from response
      String errorMessage = 'Failed to start game';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
        print('❌ Backend error: $errorMessage');
      } catch (e) {
        print('❌ Could not parse error response');
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> vote(String roomId, String voterId, String targetId) async {
    print('🔵 Casting vote: $baseUrl/game/$roomId/vote');

    final response = await _makeRequestWithRetry(
      request: () => http
          .post(
            Uri.parse('$baseUrl/game/$roomId/vote'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({'voterId': voterId, 'targetId': targetId}),
          )
          .timeout(Duration(seconds: 30)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cast vote');
    }
  }
}
