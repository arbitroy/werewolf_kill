import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(WerewolfGame());
}

class WerewolfGame extends StatelessWidget {
  const WerewolfGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moonlight Village',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
