import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'screens/waiting_room_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/lobby': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return LobbyScreen(
            userId: args?['userId'] ?? 'temp-id',
            username: args?['username'] ?? 'Guest',
          );
        },
        '/game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return GameScreen(roomId: args['roomId']!);
        },
      },
    );
  }
}