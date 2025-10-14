import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  String? _token;

  // Auth
  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['data']['token'];
      return data['data'];
    } else {
      throw Exception('Login failed');
    }
  }

  // Rooms
  Future<Map<String, dynamic>> createRoom(String name, String hostId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name,
        'hostId': hostId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to create room');
    }
  }

  Future<List<dynamic>> getRooms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load rooms');
    }
  }

  Future<void> joinRoom(String roomId, String playerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomId/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'playerId': playerId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join room');
    }
  }

  // Game
  Future<void> startGame(String roomId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/game/$roomId/start'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start game');
    }
  }

  Future<void> vote(String roomId, String voterId, String targetId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/game/$roomId/vote'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'voterId': voterId,
        'targetId': targetId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cast vote');
    }
  }
}
