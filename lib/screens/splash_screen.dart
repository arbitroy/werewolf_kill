import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/services/server_health_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _statusMessage = 'Initializing...';
  int _warmupAttempt = 0;
  int _maxAttempts = 0;
  bool _isWarmingUp = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Step 1: Wake up the server first
    setState(() {
      _statusMessage = 'Connecting to server...';
      _isWarmingUp = true;
    });

    final serverReady = await ServerHealthService.wakeUpServer(
      onAttempt: (attempt, maxAttempts) {
        if (mounted) {
          setState(() {
            _warmupAttempt = attempt;
            _maxAttempts = maxAttempts;
          });
        }
      },
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
          });
        }
      },
    );

    if (!serverReady && mounted) {
      // Server didn't wake up, but let them try anyway
      setState(() {
        _statusMessage = 'Server may be slow. Continuing...';
      });
      await Future.delayed(Duration(seconds: 2));
    }

    // Step 2: Check auth status
    if (mounted) {
      setState(() {
        _statusMessage = 'Checking authentication...';
        _isWarmingUp = false;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Wait for minimum animation time
      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        if (authProvider.isAuthenticated) {
          Navigator.pushReplacementNamed(
            context,
            '/lobby',
            arguments: {
              'userId': authProvider.currentUser!.id,
              'username': authProvider.currentUser!.username,
            },
          );
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0A1E),
              Color(0xFF2D1B4E),
              Color(0xFF1A0F2E),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFD4AF37).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD4AF37).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      size: 80,
                      color: Color(0xFF2D1B4E),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Moonlight Village',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC0C0D8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Werewolf',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 20,
                      color: Color(0xFF8B0000),
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 48),
                  
                  // Loading indicator
                  CircularProgressIndicator(
                    color: Color(0xFFD4AF37),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Status message
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 14,
                        color: Color(0xFFC0C0D8).withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Show progress during warmup
                  if (_isWarmingUp && _maxAttempts > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Text(
                            'Attempt $_warmupAttempt/$_maxAttempts',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 12,
                              color: Color(0xFFD4AF37).withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Color(0xFF2D1B4E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _warmupAttempt / _maxAttempts,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Free tier server waking up...',
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 10,
                              color: Color(0xFFC0C0D8).withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}