import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/result_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/room_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
      ],
      child: WerewolfGame(),
    ),
  );
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
        '/waiting': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WaitingRoomScreen(
            roomId: args['roomId'],
            roomName: args['roomName'],
            isHost: args['isHost'] ?? false,
          );
        },
        '/game': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return GameScreen(roomId: args['roomId']!);
        },
        '/result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultScreen(
            winner: args['winner'],
            players: args['players'],
          );
        },
      },
    );
  }
}