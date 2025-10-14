import 'package:flutter/foundation.dart';
import '../core/models/game_state.dart';
import '../core/models/player.dart';
import '../core/services/api_service.dart';
import '../core/services/websocket_service.dart';

class GameProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  
  GameState? _gameState;
  bool _isLoading = false;
  String? _error;
  String? _currentRoomId;
  Player? _myPlayer;

  // Getters
  GameState? get gameState => _gameState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Player? get myPlayer => _myPlayer;
  bool get isConnected => _wsService != null;

  // Connect to game via WebSocket
  void connectToGame(String roomId, String playerId) {
    _currentRoomId = roomId;
    
    _wsService.onGameUpdate = (data) {
      _handleGameUpdate(data);
    };
    
    _wsService.connect(roomId);
  }

  // Disconnect from game
  void disconnectFromGame() {
    _wsService.disconnect();
    _gameState = null;
    _currentRoomId = null;
    notifyListeners();
  }

  // Handle game updates from WebSocket
  void _handleGameUpdate(Map<String, dynamic> data) {
    try {
      _gameState = GameState.fromJson(data);
      
      // Update my player info
      if (_myPlayer != null) {
        _myPlayer = _gameState!.players.firstWhere(
          (p) => p.id == _myPlayer!.id,
          orElse: () => _myPlayer!,
        );
      }
      
      notifyListeners();
    } catch (e) {
      print('Error handling game update: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start game
  Future<bool> startGame(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.startGame(roomId);
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

  // Cast vote
  Future<bool> castVote(String roomId, String voterId, String targetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.vote(roomId, voterId, targetId);
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

  // Perform night action (werewolf kill, seer investigate)
  Future<bool> performNightAction(String roomId, String actorId, String targetId, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Call API for night action
      // await _apiService.nightAction(roomId, actorId, targetId, action);
      
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

  // Set my player
  void setMyPlayer(Player player) {
    _myPlayer = player;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}