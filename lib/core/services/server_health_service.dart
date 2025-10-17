import 'dart:async';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class ServerHealthService {
  static const int maxWarmupAttempts = 6; // 6 attempts = ~60 seconds
  static const Duration warmupDelay = Duration(seconds: 10);
  
  /// Check if server is awake and healthy
  static Future<bool> checkServerHealth() async {
    try {
      print('🔵 Checking server health...');
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/actuator/health'))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ Server is healthy');
        return true;
      }
      print('⚠️ Server returned: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Server health check failed: $e');
      return false;
    }
  }

  /// Wake up the server with retries
  static Future<bool> wakeUpServer({
    Function(int attempt, int maxAttempts)? onAttempt,
    Function(String message)? onStatusUpdate,
  }) async {
    print('═══════════════════════════════════════');
    print('🌅 WAKING UP SERVER (Render Free Tier)');
    print('═══════════════════════════════════════');
    
    for (int attempt = 1; attempt <= maxWarmupAttempts; attempt++) {
      onAttempt?.call(attempt, maxWarmupAttempts);
      
      final statusMessage = attempt == 1 
          ? 'Waking up server... (This may take 30-60 seconds)'
          : 'Still warming up... Attempt $attempt/$maxWarmupAttempts';
      
      onStatusUpdate?.call(statusMessage);
      print('📡 Warmup attempt $attempt/$maxWarmupAttempts');
      
      final isHealthy = await checkServerHealth();
      
      if (isHealthy) {
        onStatusUpdate?.call('Server is ready! 🎉');
        print('✅ Server warmup complete!');
        print('═══════════════════════════════════════');
        return true;
      }
      
      if (attempt < maxWarmupAttempts) {
        print('⏳ Waiting ${warmupDelay.inSeconds}s before next attempt...');
        await Future.delayed(warmupDelay);
      }
    }
    
    print('❌ Server warmup failed after $maxWarmupAttempts attempts');
    print('═══════════════════════════════════════');
    return false;
  }

  /// Quick ping to wake server without waiting
  static Future<void> pingServer() async {
    try {
      print('📡 Pinging server to wake it up...');
      http.get(Uri.parse('${AppConstants.baseUrl}/actuator/health'))
          .timeout(Duration(seconds: 2))
          .catchError((_) {}); // Fire and forget
    } catch (_) {
      // Ignore errors, this is just to trigger the wake-up
    }
  }
}