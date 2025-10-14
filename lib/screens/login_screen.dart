import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _moonController;
  late Animation<double> _moonAnimation;

  @override
  void initState() {
    super.initState();
    _moonController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _moonAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _moonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _moonController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Moon
                  AnimatedBuilder(
                    animation: _moonAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _moonAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
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
                        size: 60,
                        color: Color(0xFF2D1B4E),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Moonlight Village',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Werewolf',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Color(0xFF8B0000),
                      letterSpacing: 4,
                    ),
                  ),
                  
                  SizedBox(height: 48),
                  
                  // Login Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: Color(0xFFC0C0D8)),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(
                                fontFamily: 'Lora',
                                color: Color(0xFFC0C0D8).withOpacity(0.7),
                              ),
                              prefixIcon: Icon(Icons.person, color: Color(0xFFC0C0D8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFC0C0D8).withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFD4AF37),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: Color(0xFFC0C0D8)),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontFamily: 'Lora',
                                color: Color(0xFFC0C0D8).withOpacity(0.7),
                              ),
                              prefixIcon: Icon(Icons.lock, color: Color(0xFFC0C0D8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFC0C0D8).withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFD4AF37),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              child: Text('Enter Village'),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: _handleRegister,
                            child: Text(
                              'Create New Account',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  void _handleLogin() {
    // TODO: Call AuthService
    print('Login: ${_usernameController.text}');
    Navigator.pushReplacementNamed(context, '/lobby');
  }

  void _handleRegister() {
    // TODO: Navigate to register screen
    print('Register');
  }
}