import 'package:flutter/foundation.dart';
import '../core/models/room.dart';
import '../core/services/api_service.dart';

class RoomProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Room> _rooms = [];
  Room? _currentRoom;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Room> get rooms => _rooms;
  Room? get currentRoom => _currentRoom;
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

  // Create room
  Future<Room?> createRoom(String roomName, String hostId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔵 Creating room: $roomName for host: $hostId');
      final roomData = await _apiService.createRoom(roomName, hostId);
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

  // Join room
  Future<bool> joinRoom(String roomId, String playerId) async {
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
        orElse: () => _currentRoom!,
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

  // Set current room
  void setCurrentRoom(Room room) {
    _currentRoom = room;
    notifyListeners();
  }

  // Clear current room
  void clearCurrentRoom() {
    _currentRoom = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}