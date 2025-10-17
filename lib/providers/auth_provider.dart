import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/user.dart';
import '../core/services/api_service.dart';
import '../config/constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.keyAuthToken);
      final userId = prefs.getString(AppConstants.keyUserId);
      final username = prefs.getString(AppConstants.keyUsername);

      if (_token != null && userId != null && username != null) {
        _currentUser = User(id: userId, username: username);
        _isAuthenticated = true;
        _apiService.setToken(_token!);
      }
    } catch (e) {
      print('Error initializing auth: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);

      _token = response['token'];
      _currentUser = User(
        id: response['userId'],
        username: response['username'],
      );
      _isAuthenticated = true;

      _apiService.setToken(_token!);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, _token!);
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString(AppConstants.keyUsername, _currentUser!.username);

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

  // Register
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(username, password);

      _token = response['token'];
      _currentUser = User(
        id: response['userId'],
        username: response['username'],
      );
      _isAuthenticated = true;
      _apiService.setToken(_token!);
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, _token!);
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString(AppConstants.keyUsername, _currentUser!.username);

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

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _isAuthenticated = false;

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUsername);

    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
