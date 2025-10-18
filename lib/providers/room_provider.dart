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

  // Create room via REST API
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

  // ✅ FIXED: Join room (REST API - maintains backward compatibility)
  Future<bool> joinRoom(String roomId, String playerId, String playerName) async {
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
          hostId: '',
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

  // ✅ FIXED: Leave room (maintains backward compatibility)
  Future<bool> leaveRoom(String roomId, String playerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Leaving room: $roomId as player: $playerId');
      await _apiService.leaveRoom(roomId, playerId);
      print('✅ Left room successfully via REST API');
      
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

  // ✅ FIXED: Get room details (maintains backward compatibility)
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

  // ✅ FIXED: Get room players (maintains backward compatibility)
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

  // ✅ NEW: Handle unified room state updates from WebSocket
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
          hostId: '', // Not used anymore
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
            isAlive: p['status'] == 'ALIVE',
            role: p['role'] as String?,
          );
        }).toList();
        
        print('✅ Updated ${_roomPlayers.length} players');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error handling room state update: $e');
      _error = 'Failed to update room state';
      notifyListeners();
    }
  }

  // Legacy callback support (for backward compatibility)
  void handlePlayerJoined(Map<String, dynamic> data) {
    print('👋 Player joined: ${data['username']}');
    
    final playerId = data['playerId'] as String;
    final username = data['username'] as String;
    final isHost = data['isHost'] as bool? ?? false;
    
    // Check if player already exists
    final existingIndex = _roomPlayers.indexWhere((p) => p.id == playerId);
    
    if (existingIndex != -1) {
      // ✅ FIXED: Use copyWith instead of mutating
      _roomPlayers[existingIndex] = _roomPlayers[existingIndex].copyWith(
        username: username,
        isHost: isHost,
      );
    } else {
      // Add new player
      _roomPlayers.add(Player(
        id: playerId,
        username: username,
        isHost: isHost,
        isAlive: true,
      ));
    }
    
    // Update current room player count
    if (_currentRoom != null) {
      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
        maxPlayers: _currentRoom!.maxPlayers,
        currentPlayers: _roomPlayers.length,
        status: _currentRoom!.status,
      );
    }
    
    notifyListeners();
  }

  void handlePlayerLeft(Map<String, dynamic> data) {
    print('👋 Player left: ${data['playerId']}');
    
    final playerId = data['playerId'] as String;
    _roomPlayers.removeWhere((p) => p.id == playerId);
    
    // Update current room player count
    if (_currentRoom != null) {
      _currentRoom = Room(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        hostId: _currentRoom!.hostId,
        maxPlayers: _currentRoom!.maxPlayers,
        currentPlayers: _roomPlayers.length,
        status: _currentRoom!.status,
      );
    }
    
    notifyListeners();
  }

  void handleHostChanged(Map<String, dynamic> data) {
    print('👑 Host changed to: ${data['newHostUsername']}');
    
    final newHostId = data['newHostId'] as String;
    final newHostUsername = data['newHostUsername'] as String;
    
    // ✅ FIXED: Create new Player instances instead of mutating
    _roomPlayers = _roomPlayers.map((player) {
      return player.copyWith(isHost: player.id == newHostId);
    }).toList();
    
    _hostUsername = newHostUsername;
    notifyListeners();
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