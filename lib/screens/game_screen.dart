import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameScreen extends StatefulWidget {
  final String roomId;
  
  const GameScreen({super.key, required this.roomId});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _phaseController;
  bool isNight = true;
  String myRole = 'VILLAGER'; // From game state
  List<Player> players = []; // From WebSocket
  int timeRemaining = 60;
  
  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _loadGameState();
  }

  void _loadGameState() {
    // TODO: Connect to WebSocket and listen for game updates
    setState(() {
      players = _mockPlayers();
    });
  }

  List<Player> _mockPlayers() {
    return [
      Player(id: '1', username: 'Alice', status: PlayerStatus.ALIVE),
      Player(id: '2', username: 'Bob', status: PlayerStatus.ALIVE),
      Player(id: '3', username: 'Charlie', status: PlayerStatus.DEAD),
      Player(id: '4', username: 'Diana', status: PlayerStatus.ALIVE),
      Player(id: '5', username: 'Eve', status: PlayerStatus.ALIVE),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: isNight ? _nightGradient : _dayGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              SizedBox(height: 16),
              _buildPhaseIndicator(),
              SizedBox(height: 24),
              Expanded(child: _buildPlayerCircle()),
              _buildActionPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // FIX: Safely handle room ID display
    final displayRoomId = widget.roomId.length > 8 
        ? widget.roomId.substring(0, 8) 
        : widget.roomId;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFFC0C0D8)),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'Room $displayRoomId',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 16,
                  color: Color(0xFFC0C0D8),
                ),
              ),
              Text(
                _getRoleText(),
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: _getRoleColor(),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFFC0C0D8)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? Color(0xFFC0C0D8) : Color(0xFFFFE4B5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNight ? Icons.nightlight_round : Icons.wb_sunny,
            color: isNight ? Color(0xFFC0C0D8) : Colors.orange,
            size: 28,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNight ? 'Night Phase' : 'Day Phase',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Color(0xFFC0C0D8) : Colors.white,
                ),
              ),
              Text(
                '$timeRemaining seconds',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 14,
                  color: isNight 
                    ? Color(0xFFC0C0D8).withOpacity(0.8) 
                    : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCircle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;
        return Stack(
          children: [
            Center(
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFC0C0D8).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            ...List.generate(players.length, (index) {
              final angle = (2 * math.pi * index) / players.length - math.pi / 2;
              final x = radius * math.cos(angle);
              final y = radius * math.sin(angle);
              
              return Positioned(
                left: constraints.maxWidth / 2 + x - 40,
                top: constraints.maxHeight / 2 + y - 40,
                child: _buildPlayerAvatar(players[index]),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPlayerAvatar(Player player) {
    final isDead = player.status == PlayerStatus.DEAD;
    
    return GestureDetector(
      onTap: () => _handlePlayerTap(player),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDead ? Color(0xFF424242) : Color(0xFF2E7D32),
              border: Border.all(
                color: isDead 
                  ? Color(0xFF757575) 
                  : Color(0xFFD4AF37),
                width: 3,
              ),
              boxShadow: isDead ? [] : [
                BoxShadow(
                  color: Color(0xFF2E7D32).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                player.username[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.username,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                color: isDead ? Color(0xFF757575) : Color(0xFFC0C0D8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    if (isNight && myRole == 'WEREWOLF') {
      return _buildNightActionPanel();
    } else if (!isNight) {
      return _buildVotePanel();
    }
    return SizedBox(height: 80);
  }

  Widget _buildVotePanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A0F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a player to vote',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 16,
              color: Color(0xFFC0C0D8),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Submit vote
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B0000),
              ),
              child: Text('Cast Vote'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightActionPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A0F2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🐺 Choose your target',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 16,
              color: Color(0xFF8B0000),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Submit night action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B0000),
              ),
              child: Text('Attack'),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayerTap(Player player) {
    if (player.status == PlayerStatus.DEAD) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0F2E),
        title: Text(
          player.username,
          style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFC0C0D8)),
        ),
        content: Text(
          isNight ? 'Target this player?' : 'Vote to eliminate this player?',
          style: TextStyle(fontFamily: 'Lora', color: Color(0xFFC0C0D8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFFC0C0D8))),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Submit action
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getRoleText() {
    switch (myRole) {
      case 'WEREWOLF': return '🐺 Werewolf';
      case 'SEER': return '🔮 Seer';
      default: return '👤 Villager';
    }
  }

  Color _getRoleColor() {
    switch (myRole) {
      case 'WEREWOLF': return Color(0xFF8B0000);
      case 'SEER': return Color(0xFFD4AF37);
      default: return Color(0xFF2E7D32);
    }
  }

  LinearGradient get _nightGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0A1E), Color(0xFF2D1B4E), Color(0xFF1A0F2E)],
  );

  LinearGradient get _dayGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF87CEEB), Color(0xFFFFE4B5), Color(0xFFFFDAB9)],
  );

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }
}

// Mock Player class (should match your models)
class Player {
  final String id;
  final String username;
  final PlayerStatus status;

  Player({
    required this.id,
    required this.username,
    required this.status,
  });
}

enum PlayerStatus { ALIVE, DEAD }