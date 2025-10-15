class AppConstants {
  // PRODUCTION - Use HTTPS for Render deployment
  static const String baseUrl = 'https://werewolf-backend-jsji.onrender.com';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String wsUrl = '$baseUrl/ws/game';
  
  // API Endpoints
  static const String authRegister = '$apiBaseUrl/auth/register';
  static const String authLogin = '$apiBaseUrl/auth/login';
  static const String rooms = '$apiBaseUrl/rooms';
  static const String game = '$apiBaseUrl/game';
  
  // Game Configuration
  static const int minPlayersToStart = 3;
  static const int maxPlayersPerRoom = 8;
  static const int nightPhaseDuration = 60;
  static const int dayPhaseDuration = 60;
  static const int votingPhaseDuration = 45;
  
  // Local Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 8.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 600);
  static const Duration longAnimation = Duration(seconds: 2);
  
  // Network
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}