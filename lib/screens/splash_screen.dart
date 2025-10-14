import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    // Wait for animation to complete
    await Future.delayed(Duration(seconds: 3));

    if (mounted) {
      if (authProvider.isAuthenticated) {
        // User is logged in, go to lobby
        Navigator.pushReplacementNamed(
          context,
          '/lobby',
          arguments: {
            'userId': authProvider.currentUser!.id,
            'username': authProvider.currentUser!.username,
          },
        );
      } else {
        // User not logged in, go to login
        Navigator.pushReplacementNamed(context, '/');
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Moon icon
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC0C0D8),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFC0C0D8).withOpacity(0.5),
                              blurRadius: 40,
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
                      CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                ),
              );
            },
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