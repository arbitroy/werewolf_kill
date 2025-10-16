import 'package:flutter/foundation.dart';
import '../core/models/room.dart';
import '../core/models/player.dart';
import '../core/services/api_service.dart';

class RoomProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Room> _rooms = [];
  Room? _currentRoom;
  List<Player> _roomPlayers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Room> get rooms => _rooms;
  Room? get currentRoom => _currentRoom;
  List<Player> get roomPlayers => _roomPlayers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set token from AuthProvider
  void setToken(String token) {
    _apiService.setToken(token);
  }

  // Load available rooms
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

  // Create room with optional max players
  Future<Room?> createRoom(String roomName, String hostId, {int maxPlayers = 8}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Creating room: $roomName for host: $hostId');
      final roomData = await _apiService.createRoom(
        roomName, 
        hostId,
        maxPlayers: maxPlayers,
      );
      final room = Room.fromJson(roomData);
      print('✅ Room created: ${room.id}');
      
      _currentRoom = room;
      _rooms.add(room);
      
      // Add host to room players
      _roomPlayers = [
        Player(
          id: hostId,
          username: 'Host', // This should come from auth provider
          isAlive: true,
          isHost: true,
        ),
      ];
      
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

  // Join room
  Future<bool> joinRoom(String roomId, String playerId, String playerName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Joining room: $roomId as player: $playerId');
      await _apiService.joinRoom(roomId, playerId);
      print('✅ Joined room successfully');
      
      // Update current room
      _currentRoom = _rooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => Room(
          id: roomId,
          name: 'Room',
          hostId: '',
          currentPlayers: 1,
        ),
      );
      
      // Increment player count locally
      if (_currentRoom != null) {
        _currentRoom = Room(
          id: _currentRoom!.id,
          name: _currentRoom!.name,
          hostId: _currentRoom!.hostId,
          maxPlayers: _currentRoom!.maxPlayers,
          currentPlayers: _currentRoom!.currentPlayers + 1,
          status: _currentRoom!.status,
        );
      }
      
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Leaving room: $roomId as player: $playerId');
      await _apiService.leaveRoom(roomId, playerId);
      print('✅ Left room successfully');
      
      // Clear current room if it's the one we left
      if (_currentRoom?.id == roomId) {
        _currentRoom = null;
        _roomPlayers = [];
      }
      
      // Update room in list
      final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        _rooms[roomIndex] = Room(
          id: room.id,
          name: room.name,
          hostId: room.hostId,
          maxPlayers: room.maxPlayers,
          currentPlayers: room.currentPlayers - 1,
          status: room.status,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Leave room error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
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

  // Update room player count (called from WebSocket events)
  void updateRoomPlayerCount(String roomId, int playerCount) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      _rooms[roomIndex] = Room(
        id: room.id,
        name: room.name,
        hostId: room.hostId,
        maxPlayers: room.maxPlayers,
        currentPlayers: playerCount,
        status: room.status,
      );
    }
    
    if (_currentRoom?.id == roomId) {
      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
        maxPlayers: _currentRoom!.maxPlayers,
        currentPlayers: playerCount,
        status: _currentRoom!.status,
      );
    }
    
    notifyListeners();
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
        hostId: room.hostId,
        maxPlayers: room.maxPlayers,
        currentPlayers: room.currentPlayers,
        status: status,
      );
    }
    
    if (_currentRoom?.id == roomId) {
      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
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

  // Clear current room
  void clearCurrentRoom() {
    _currentRoom = null;
    _roomPlayers = [];
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