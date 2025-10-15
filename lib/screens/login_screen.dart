import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  bool _isLoading = false;

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
                            enabled: !_isLoading,
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
                            enabled: !_isLoading,
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
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFC0C0D8),
                                      ),
                                    )
                                  : Text('Enter Village'),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: _isLoading ? null : _handleRegister,
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

void _handleLogin() async {
  if (_usernameController.text.isEmpty) {
    _showError('Please enter a username');
    return;
  }
  
  if (_passwordController.text.isEmpty) {
    _showError('Please enter a password');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show cold start warning
    _showColdStartMessage();
    
    print('🔵 Attempting login...');
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      print('✅ Login successful!');
      Navigator.pushReplacementNamed(
        context,
        '/lobby',
        arguments: {
          'userId': authProvider.currentUser!.id,
          'username': authProvider.currentUser!.username,
        },
      );
    } else if (mounted) {
      _showError(authProvider.error ?? 'Login failed');
    }
  } catch (e) {
    print('❌ Login error: $e');
    if (mounted) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('502') || errorMsg.contains('503')) {
        _showError('Server is starting up. Please wait 30 seconds and try again.');
      } else {
        _showError('Login failed: $errorMsg');
      }
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

void _handleRegister() async {
  if (_usernameController.text.isEmpty) {
    _showError('Please enter a username');
    return;
  }
  
  if (_passwordController.text.isEmpty) {
    _showError('Please enter a password');
    return;
  }
  
  if (_passwordController.text.length < 6) {
    _showError('Password must be at least 6 characters');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show cold start warning
    _showColdStartMessage();
    
    print('🔵 Attempting registration...');
    final success = await authProvider.register(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      print('✅ Registration successful!');
      Navigator.pushReplacementNamed(
        context,
        '/lobby',
        arguments: {
          'userId': authProvider.currentUser!.id,
          'username': authProvider.currentUser!.username,
        },
      );
    } else if (mounted) {
      _showError(authProvider.error ?? 'Registration failed');
    }
  } catch (e) {
    print('❌ Registration error: $e');
    if (mounted) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('502') || errorMsg.contains('503') || errorMsg.contains('waking up')) {
        _showError('Server is starting up. This may take up to 50 seconds on first request.');
      } else {
        _showError('Registration failed: $errorMsg');
      }
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

void _showColdStartMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('First request may take 30-50s while server wakes up...'),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1E3A5F),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
    ),
  );
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Color(0xFF8B0000),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
    ),
  );
}
}