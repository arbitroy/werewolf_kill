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

  // Load available rooms
  Future<void> loadRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final roomsData = await _apiService.getRooms();
      _rooms = roomsData.map((data) => Room.fromJson(data)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
      final roomData = await _apiService.createRoom(roomName, hostId);
      final room = Room.fromJson(roomData);
      
      _currentRoom = room;
      _rooms.add(room);
      
      _isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      _error = e.toString();
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
      await _apiService.joinRoom(roomId, playerId);
      
      // Update current room
      _currentRoom = _rooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => _currentRoom!,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      // TODO: Call API to leave room
      // await _apiService.leaveRoom(roomId, playerId);
      
      _currentRoom = null;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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