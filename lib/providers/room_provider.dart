import 'package:flutter/foundation.dart';
import '../core/models/room.dart';
import '../core/models/player.dart';
import '../core/services/api_service.dart';

class RoomProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Room> _rooms = [];
  Room? _currentRoom;
  List<Player> _roomPlayers = [];
  String? _hostUsername;
  String? _currentPhase;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Room> get rooms => _rooms;
  Room? get currentRoom => _currentRoom;
  List<Player> get roomPlayers => _roomPlayers;
  String? get hostUsername => _hostUsername;
  String? get currentPhase => _currentPhase;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Player? get currentHost => _roomPlayers.firstWhere(
    (p) => p.isHost,
    orElse: () => Player(id: '', username: '', isHost: false),
  );

  bool isPlayerHost(String playerId) {
    return _roomPlayers.any((p) => p.id == playerId && p.isHost);
  }

  // ✅ Helper to check if user is room creator
  bool isCreator(String userId) {
    return _currentRoom?.createdBy == userId;
  }

  // Set token from AuthProvider
  void setToken(String token) {
    _apiService.setToken(token);
  }

  // Load available rooms from REST API
  Future<void> loadRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Loading rooms...');
      final roomsData = await _apiService.getRooms();
      _rooms = roomsData.map((data) => Room.fromJson(data)).toList();
      print('✅ Loaded ${_rooms.length} rooms');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Load rooms error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Updated createRoom - uses createdBy instead of hostId
  Future<Room?> createRoom(
    String roomName,
    String createdBy, {
    int maxPlayers = 8,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Creating room: $roomName for creator: $createdBy');
      final roomData = await _apiService.createRoom(
        roomName,
        createdBy, // ✅ Changed from hostId
        maxPlayers: maxPlayers,
      );
      final room = Room.fromJson(roomData);
      print('✅ Room created: ${room.id}');

      _currentRoom = room;
      _rooms.add(room);

      _isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      print('❌ Create room error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Join room (REST API - validation only, actual join via WebSocket)
  Future<bool> joinRoom(
    String roomId,
    String playerId,
    String playerName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Joining room: $roomId as player: $playerId');
      await _apiService.joinRoom(roomId, playerId);
      print('✅ Joined room successfully via REST API');

      // Update current room (will be overwritten by WebSocket updates)
      _currentRoom = _rooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => Room(
          id: roomId,
          name: 'Room',
          createdBy: playerId, // ✅ Changed from hostId
          currentPlayers: 1,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Join room error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Leave room
  Future<bool> leaveRoom(String roomId, String playerId) async {
    try {
      print('🔵 Leaving room via REST API: $roomId');

      // Optional: Keep the REST API call for logging/analytics
      // But don't rely on it for actual leaving
      await _apiService.leaveRoom(roomId, playerId);

      // ✅ DON'T update local state - WebSocket will handle it
      // Just clear the reference
      if (_currentRoom?.id == roomId) {
        _currentRoom = null;
        _roomPlayers = [];
      }

      return true;
    } catch (e) {
      print('❌ Leave room API error: $e');
      // Don't fail - WebSocket is the real source of truth
      return true;
    }
  }

  // Get room details
  Future<Room?> getRoomDetails(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Getting room details: $roomId');
      final roomData = await _apiService.getRoomDetails(roomId);
      final room = Room.fromJson(roomData);
      print('✅ Got room details: ${room.name}');

      _currentRoom = room;

      _isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      print('❌ Get room details error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get room players
  Future<List<Player>> getRoomPlayers(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Getting room players: $roomId');
      final playersData = await _apiService.getRoomPlayers(roomId);
      _roomPlayers = playersData.map((data) => Player.fromJson(data)).toList();
      print('✅ Got ${_roomPlayers.length} players');

      _isLoading = false;
      notifyListeners();
      return _roomPlayers;
    } catch (e) {
      print('❌ Get room players error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _roomPlayers = [];
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // ✅ Handle unified room state updates from WebSocket
  void handleRoomStateUpdate(Map<String, dynamic> data) {
    print('📥 Handling room state update');

    try {
      final roomId = data['roomId'] as String;
      final roomName = data['roomName'] as String;
      final playerCount = data['playerCount'] as int;
      final hostUsername = data['hostUsername'] as String?;
      final currentPhase = data['currentPhase'] as String?;

      // Update current room metadata
      if (_currentRoom?.id == roomId || _currentRoom == null) {
        _currentRoom = Room(
          id: roomId,
          name: roomName,
          createdBy: _currentRoom?.createdBy ?? '', // ✅ Changed from hostId
          maxPlayers: _currentRoom?.maxPlayers ?? 8,
          currentPlayers: playerCount,
          status: currentPhase ?? 'WAITING',
        );
      }

      _hostUsername = hostUsername;
      _currentPhase = currentPhase;

      // Update player list from the state update
      final playersData = data['players'] as List<dynamic>?;
      if (playersData != null) {
        _roomPlayers = playersData.map((p) {
          return Player(
            id: p['playerId'] as String,
            username: p['username'] as String,
            isHost: p['isHost'] as bool? ?? false,
            role: p['role'] as String?,
            // status: p['status'] as String?,
          );
        }).toList();
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error handling room state update: $e');
    }
  }

  // Add player to room (called from WebSocket events)
  void addPlayerToRoom(Player player) {
    if (!_roomPlayers.any((p) => p.id == player.id)) {
      _roomPlayers.add(player);
      notifyListeners();
    }
  }

  // Remove player from room (called from WebSocket events)
  void removePlayerFromRoom(String playerId) {
    _roomPlayers.removeWhere((p) => p.id == playerId);
    notifyListeners();
  }

  // Update room status
  void updateRoomStatus(String roomId, String status) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      _rooms[roomIndex] = Room(
        id: room.id,
        name: room.name,
        createdBy: room.createdBy, // ✅ Changed from hostId
        maxPlayers: room.maxPlayers,
        currentPlayers: room.currentPlayers,
        status: status,
      );
    }

    if (_currentRoom?.id == roomId) {
      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        createdBy: _currentRoom!.createdBy, // ✅ Changed from hostId
        maxPlayers: _currentRoom!.maxPlayers,
        currentPlayers: _currentRoom!.currentPlayers,
        status: status,
      );
    }

    notifyListeners();
  }

  // Set current room
  void setCurrentRoom(Room room) {
    _currentRoom = room;
    notifyListeners();
  }

  // Clear current room and players
  void clearCurrentRoom() {
    _currentRoom = null;
    _roomPlayers = [];
    _hostUsername = null;
    _currentPhase = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh rooms
  Future<void> refreshRooms() async {
    await loadRooms();
  }

  @override
  void dispose() {
    _rooms.clear();
    _roomPlayers.clear();
    _currentRoom = null;
    super.dispose();
  }
}
